---
name: indeed-apply
description: Fill out Indeed job application forms (Indeed's own "Apply with Indeed" / Smart Apply flow at smartapply.indeed.com, reached from a ca.indeed.com/viewjob?jk=... posting) using the Chrome extension. Use whenever the user wants to apply to an Indeed job posting, shares an indeed.com job link and asks to apply, or says things like "apply to this job on Indeed". Distinct from `linkedin-apply` (LinkedIn posting triage) and `workday-apply` (Workday-hosted forms via Playwright) — this skill is specifically for Indeed's own application flow. Always invoke this skill for Indeed applications rather than improvising: it contains hard-won lessons about Indeed's reCAPTCHA behavior and the record-keeping that must happen after every submission.
---

Fills Indeed's own multi-step Smart Apply form. Scope: fill what's fillable, never submit without explicit confirmation, and — non-negotiably — leave a paper trail in `tracker/status-flow.md` and `companies/<Company>/` for every application, whether Claude or the user completes the final submit.

## Step 0: Confirm scope before touching anything

Always confirm with the user up front:
- **(a) Fill everything, stop before final submit for manual review** — default, matches CLAUDE.md's never-submit-without-confirmation rule.
- **(b) Fill and submit fully** — only if the user explicitly says so.
- **(c) Just list required fields/questions, fill nothing.**

## Step 1: Load context

Read `profile/data_dmitry_okonov.md` for contact details (email, phone, address — always use the plain `okonov.d@gmail.com`, never the `+claude` tracking alias) and `profile/resume_dmitry_okonov.md` for background/fit judgments. Check `tracker/status-flow.md` for whether this posting or company already has a row — surface it if so, the same way `linkedin-apply` does.

## Step 2: Open the apply flow

Navigate to the posting (`https://ca.indeed.com/viewjob?jk=<jk>`), find and click "Apply with Indeed". This hands off to `smartapply.indeed.com/beta/indeedapply/form/...` — a multi-step wizard with a progress bar. Steps observed so far, in order: **Contact info** → **Location** → (further steps vary by posting: resume, work experience, screening questions, review). Treat this as the general shape, not a fixed list — read each step's heading and fill what's on it.

### Known step: Contact info

First/last name and email are usually pre-filled from the user's Indeed account. Fill phone number (`604-339-7720`, Canada +1) if blank.

### Known step: Add your location

- Postal code: `V3N 4R8`
- City, province/territory: may default to a **stale value from the Indeed account profile** (seen once as "Vancouver, BC") — correct it to `Burnaby, BC` to match the real address.
- Street address (marked "Not shown to employers"): `9521 Cardston Crt, Apt 2206`

### The reCAPTCHA gotcha (found 2026-09-01, ProCharted application)

Indeed's Smart Apply pages run an invisible reCAPTCHA v3 badge. Symptom: clicking "Continue" does nothing — no error shown, and **zero network requests fire** (verify with `read_network_requests` if this happens). This is bot-detection silently blocking the automated click, not a validation problem with the filled fields.

**Do not try to work around this** — no repeated rapid clicking, no scripting around the reCAPTCHA token, no synthetic-event tricks. That crosses into bypassing bot detection, which is off-limits regardless of how legitimate the underlying application is. Instead:

1. Fill every field on the current step yourself.
2. Tell the user the step is ready and ask them to click "Continue" themselves (a real click from them clears it).
3. Once they confirm, pick back up filling the next step, and repeat if the gate reappears on a later step.

## Step 3: Save the job description and match notes — every time

**This must happen for every Indeed application, regardless of who completes the final submit.** Work out the company's folder name under `companies/` (Title_Case, underscores for spaces; check case-insensitively for an existing folder first — e.g. this posting may already have notes if it came out of an `indeed-job-scan` run, in which case update rather than duplicate).

Write two files into `companies/<Company>/` (skip/update rather than re-create if they already exist from a prior scan or check):
- `job_description.md` — title, company, location, comp, source URL (`https://ca.indeed.com/viewjob?jk=<jk>`), apply route, and the full job description text.
- `match_notes.md` — Strengths / Gaps / Open questions, grounded in specifics actually read from `profile/resume_dmitry_okonov.md` and the JD — same depth and honesty as the `linkedin-apply` skill's match notes (see existing files under `companies/` for the expected shape and tone, e.g. `companies/Toast/match_notes.md`).

## Step 4: Update tracker/status-flow.md — every time

Add or update a row: `Date | Company | Role | Job URL | Status | Notes`.

- **Job URL column:** `[Indeed](https://ca.indeed.com/viewjob?jk=<jk>)` — bare `jk`, no extra query params.
- **Status:** `Applied` once the user has clicked through past any reCAPTCHA-gated step and either submitted or is clearly finishing it themselves; `Considering`/`Skipped` otherwise.
- **Notes column stays application-process-only** — same discipline as `linkedin-apply`: the ATS/route ("Indeed's own Smart Apply flow"), what Claude filled vs. what the user handled (name any reCAPTCHA hand-off explicitly), the salary figure if one was entered, screening answers given, what was left blank for the user, who completed final submission, and any confirmation captured. Strengths/gaps/comp-comparisons belong in `match_notes.md`, not here. End the Notes cell with `JD and match notes in companies/<Company>/.`

Do Steps 3 and 4 automatically as part of finishing the application — don't wait to be asked, and don't skip them because the user hasn't explicitly said "update the tracker" (that's implicit in "apply to this job").
