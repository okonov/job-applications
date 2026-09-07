---
name: workday-apply
description: Fill out Workday job application forms using Playwright MCP browser automation. Use this skill whenever the user wants to apply to a job, fill a job application form, navigate to a Workday application URL (*.myworkdayjobs.com), or says things like "apply to this job", "fill out this application", "help me apply", "submit my application", or shares a Workday job link. Always invoke this skill rather than improvising — it contains hard-won lessons about Workday's quirky form behavior that prevent common mistakes.
---

Multi-step Workday forms (URLs like `*.myworkdayjobs.com/.../apply`) follow a consistent pattern. The notes below were learned filling real applications and capture non-obvious pitfalls.

## Pre-flight: browser setup

If `browser_navigate` fails with "Browser chrome-for-testing is not installed", run this first:
```
npx @playwright/mcp install-browser chrome-for-testing
```
One-time install, ~300MB, a couple of minutes. Do this proactively — treat it as a setup step, not a blocker. (If Playwright MCP itself isn't registered yet on this machine, see `claude/install-browser-tool.txt` first.)

## Step 1: Confirm scope before touching anything

Always ask before filling:
- **(a) Fill everything, stop at Review/submit for manual check** — default recommendation. Submitting is externally visible and hard to reverse.
- **(b) Fill and submit fully.**
- **(c) Just list required fields/questions, fill nothing.**

Also flag date ambiguity: if the resume's current-job end date equals today's date, ask whether the user is still employed there (→ check "I currently work here", leave end date blank) or employment genuinely ended then (→ fill the end date, leave the box unchecked). Never assume.

## Step 2: Check existing account state

The candidate's Workday profile (My Information, resume upload) may already be pre-filled from a prior session under their email. Check the "Application Progress" step list at the top of the form before assuming a blank form.

Resume and profile data lives in `profile/resume_your_name.md` — use it as the source of truth for all field values.

## Filling: patterns that work

### Repeating sections ("Add Another" — Professional Experience, Education, etc.)

Each "Add Another" click appends a new block and re-renders the page, invalidating all prior element refs.

Reliable sequence:
1. Click "Add Another" (or "Add").
2. Take a fresh `browser_snapshot` (scoped to the section container if possible) to get the new block's current refs.
3. Fill that one new block via `browser_fill_form`.
4. Repeat from step 1 for the next entry.

Never reuse refs from before the click. Never batch-fill blocks that don't exist yet.

### Date fields (From/To, MM/YYYY)

Each date is **two separate spinbutton inputs** — Month and Year — not a single text field. Fill them via explicit refs from a fresh snapshot. The generic `getByRole('spinbutton', { name: 'Month' })` selector is fragile; it only works because the just-added block is the only blank one at that moment. Prefer snapshot-derived refs.

### Field of Study / large combobox-style fields

Some fields render as a large alphabetical listbox with a "Type to search" textbox. Typing behaves like scroll-to-match, not filter — it may land on an unrelated alphabetical section rather than the desired option. After typing, take a snapshot to verify the list is actually filtered. If not, either scroll the full list or flag it for the user to complete by hand.

## After filling

Always show the user a summary of what was filled before they proceed to submit. Never submit without explicit user confirmation.
