---
name: job-apply
description: Open a LinkedIn job posting (a linkedin.com/jobs/... link), expand the full "About the job" description behind LinkedIn's "...see more" truncation, and compare it against the candidate's resume (profile/resume_your_name.md) to assess fit. Uses the Claude Chrome/Edge extension for browser automation. Invoke this skill whenever the user shares a LinkedIn job URL, or asks things like "can you check this job out", "is this a good fit for me", "look at this posting", "what do you think of this role", or pastes a linkedin.com link with little other comment — even if they don't explicitly say "use job-apply" or "apply". This is the research/triage step that runs *before* any actual application: it reads the posting and discusses fit, but never fills out forms or submits anything (once a match is confirmed and the user wants to actually apply, that's a separate step — e.g. the `workday-apply` skill if the application turns out to run on Workday).
---

Reads a LinkedIn job posting, checks it against the candidate's resume, and discusses the fit with the user. Scope ends there — no cover letters, no form-filling, no submitting. Those are separate, explicit follow-up requests.

## Why the fetch step is delegated

Fetching a LinkedIn posting involves screenshots, several JavaScript extraction attempts, and raw page-text dumps — useful in the moment but not worth keeping around afterward. Step 1 below spawns a fresh subagent to do the browser work and hand back a compact, structured report, so that noise never lands in the main conversation. Everything after Step 1 runs in the main thread as before.

## Pre-flight: choose browser tool

Detect which browser automation is available so you know what to tell the subagent to use.

Call `mcp__claude-in-chrome__tabs_context_mcp` (load it first via `ToolSearch` with query `"select:mcp__claude-in-chrome__tabs_context_mcp"` if deferred). If it succeeds, the Chrome/Edge extension is connected — use it.

If it fails or the tools aren't available: check whether Playwright MCP tools (`browser_navigate`, `browser_snapshot`, etc.) are available. If so, ask the user:

> "The Chrome/Edge extension isn't reachable. I can fall back to Playwright MCP — should I go ahead with that instead?"

Only proceed with Playwright if the user confirms. If neither is available, explain the situation and stop.

> **Important:** Do NOT use the Playwright fallback silently — always confirm with the user first.

---

## Step 1: Fetch the posting (delegated to a subagent)

Spawn a fresh subagent (`Agent` tool, default/general-purpose type — no need for `fork`, since this doesn't need your conversation history) to do all the browser work. This keeps screenshots, JS extraction attempts, and raw page dumps out of your context; you only get back the digested result below.

Fill in the URL and the browser tool chosen in pre-flight, and use this as the subagent prompt:

```
Fetch and extract a LinkedIn job posting. You have no prior context — everything you need is below.

URL: <the linkedin.com/jobs/... URL>

Browser tool: <"Chrome/Edge extension (mcp__claude-in-chrome__*)" or "Playwright MCP">

If using the Chrome extension, load tools first via ToolSearch with query:
"select:mcp__claude-in-chrome__tabs_context_mcp,mcp__claude-in-chrome__navigate,mcp__claude-in-chrome__computer,mcp__claude-in-chrome__read_page,mcp__claude-in-chrome__tabs_create_mcp,mcp__claude-in-chrome__javascript_tool,mcp__claude-in-chrome__find,mcp__claude-in-chrome__tabs_close_mcp"

Steps:
1. Open the URL in a new tab. If LinkedIn shows a login wall (/authwall redirect), stop immediately and report STATUS: AUTHWALL — do not try to work around it.
2. Before reading the description, verify the posting is still applyable — postings often sit on LinkedIn long after a role has closed:
   - Find the "Apply" button/link. Note whether it shows an external-link icon (redirects off LinkedIn) or is "Easy Apply" (stays on LinkedIn).
   - Click it. If a new tab opens, check where it landed: a broken/misconfigured page, generic error/404, or a company careers page that no longer lists this specific role means the posting is stale/closed (STATUS: DEAD). A page that clearly is the application form/listing for this specific role means it's still live.
   - If Easy Apply (stays on LinkedIn), don't start filling anything — just confirm the flow opens without error, then back out. Never fill forms or submit anything.
   - If genuinely ambiguous (e.g. external site requires login to tell), don't guess — report STATUS: AMBIGUOUS with a note explaining why.
   - Close any extra tab you opened for this check and return to the original posting tab.
3. If still live, expand and read the full "About the job" section. Do NOT click the "...more"/"see more" link directly — on LinkedIn it sometimes navigates away instead of expanding in place. Instead use JavaScript:

   const btns = Array.from(document.querySelectorAll('button')).filter(b =>
     b.innerText.toLowerCase().includes('more') || b.innerText.toLowerCase().includes('see more'));
   if (btns.length) { btns[0].click(); return 'expanded'; }
   return 'no button found';

   Then pull the full text:

   const text = document.body.innerText;
   const idx = text.indexOf('About the job');
   return idx >= 0 ? text.substring(idx, idx + 8000) : text.substring(0, 5000);

   If still truncated at 8000 chars, repeat with a higher offset or target a later heading (e.g. 'You Will:', 'You Have:', 'Requirements').
4. Capture: job title, company name, location, employment type/seniority, and posted date.
5. Close any tabs you opened along the way, other than the original posting tab.

Report back in exactly this format (plain text, no extra commentary):

STATUS: LIVE | DEAD | AUTHWALL | AMBIGUOUS
TITLE: <title or blank>
COMPANY: <company or blank>
LOCATION: <location or blank>
TYPE: <employment type/seniority or blank>
POSTED: <posted date or blank>
APPLY_LINK: external | easy-apply | unknown
NOTES: <one line — why DEAD/AMBIGUOUS, or blank if LIVE>
DESCRIPTION:
<full "About the job" text, or blank if not LIVE>
```

If Playwright is the chosen tool, adjust the instructions: use `browser_navigate` instead of extension navigation, `browser_snapshot` instead of `javascript_tool`/`read_page`, and find the "see more" element by its visible text in the snapshot (not hardcoded CSS selectors — LinkedIn's class names are obfuscated and change often), then click and re-snapshot. If `browser_navigate` fails with "Browser chrome-for-testing is not installed", run `npx @playwright/mcp install-browser chrome-for-testing` (one-time, ~300MB); if Playwright MCP itself isn't registered, see `claude/install-browser-tool.txt`.

**Handling the report:**

- **STATUS: DEAD** — stop here, don't proceed to Steps 2-3 below. Tell the user right away so they're not waiting on an analysis of a closed posting, and offer to log it in the tracker as skipped/closed (Step 6) if they want a record.
- **STATUS: AUTHWALL** — tell the user LinkedIn is asking for login, ask them to log in in the browser, then confirm when done. Re-run Step 1 with the same URL once they confirm.
- **STATUS: AMBIGUOUS** — relay the subagent's note and ask the user to check manually rather than guessing.
- **STATUS: LIVE** — proceed to Step 2 using the returned TITLE/COMPANY/LOCATION/TYPE/POSTED/DESCRIPTION.

---

## Step 2: Compare against the resume

Read `profile/resume_your_name.md` — it's the source of truth for the candidate's background. Also read `profile/data_your_name.md` for contact details (email, phone, address) to use when filling application forms — always use the email from that file, not any other address. Compare against the posting and form a view on:

- **Strengths** — requirements the resume clearly covers, pointing at *which* role/bullet backs it up.
- **Gaps** — requirements the resume doesn't obviously cover, or covers thinly.
- **Open questions** — anything genuinely ambiguous (unclear seniority, vague tech stack, onsite requirements, visa sponsorship language, comp mismatch) worth flagging.

Read for substance, not just keyword overlap — seniority level, domain (backend vs. full-stack vs. infra), team/org signals, and dealbreakers matter more than whether a buzzword appears in both documents.

---

## Step 3: Check tracker for prior contact

Read `tracker/status-flow.md` and check whether this posting (by URL) or this company already has a row. If it does, surface that immediately — show the existing status and notes — so the user can decide whether to re-evaluate or skip.

---

## Step 4: Save notes

Work out the company's folder name following the convention under `companies/` (Title_Case, underscores for spaces). Check case-insensitively for an existing folder before creating a new one.

Write two files into `companies/<Company>/`:
- `job_description.md` — title, company, location, source URL, date checked, and the full expanded description text (the subagent's DESCRIPTION field).
- `match_notes.md` — the strengths / gaps / open-questions writeup.

If either file already exists, append a dated section rather than overwriting.

---

## Step 5: Discuss fit with the user

Present a short, structured summary — **Strengths**, **Gaps**, **Open questions** — then ask how they'd like to proceed (tailor the resume, draft a cover letter, go ahead and apply, or skip). Stop there; don't start drafting or opening forms unless the user explicitly asks.

---

## Step 6: Update tracker/status-flow.md

Once the user decides, add or update a row in `tracker/status-flow.md`. The file uses a markdown table: `Date | Company | Role | Job URL | Status | Notes`.

- Create the file with the header row if it doesn't exist yet.
- Update in place if the company/URL already has a row; don't duplicate.
- **Job URL column:** always use a markdown link, never a bare URL — e.g. `[LinkedIn](https://www.linkedin.com/jobs/view/...)` for LinkedIn postings, or `[JobBoard](url)` for other sources (Workday, Greenhouse, company site, etc.).
- **Status values:** `Considering`, `Applied`, `Skipped`, `Interviewing`, `Offer`, `Rejected`
- **Notes:** one-line reason for the decision.

Do this automatically after the user's decision — don't wait to be asked.
