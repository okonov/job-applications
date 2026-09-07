# Job Search Workspace

Working directory for job applications. Designed to be self-sufficient: clone/copy this folder to another machine and Claude Code should be able to pick up where it left off from this file alone (plus one-time local setup in `claude/install-browser-tool.txt`).

## Folder layout

- `profile/` — `resume_your_name.md` (source of truth for resume content) and the matching `.pdf` for uploads.
- `companies/` — per-company research/notes.
- `templates/` — reusable templates (cover letters, etc.).
- `tracker/` — application tracking (currently being set up).
- `claude/install-browser-tool.txt` — one-time setup instructions for giving this Claude Code instance Playwright MCP (browser control) on a new machine.

## Candidate profile

Your title and targeted roles.

**Email:** you@gmail.com (personal).

Work history (see `profile/resume_your_name.md` for full bullet points and tech stacks):

- **Role_1**
- **Role_2**
- **To-Do**


Core stack: your-core-stack

**How to apply:** Use `profile/resume_your_name.md` as the source of truth to pre-fill job application forms (Workday, etc.). Always show the user the filled form for review before submitting — never submit an application without explicit confirmation.

## Workday applications: use `/workday-apply` skill

The Workday form-filling playbook lives in `.claude/skills/workday-apply/SKILL.md`.
