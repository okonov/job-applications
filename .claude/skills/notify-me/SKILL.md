---
name: notify-me
description: Push a notification to the user's phone/desktop via ntfy when the user explicitly asks to be notified — e.g. when the current Claude session stops, finishes a long task, or when Claude is waiting on the user's input to continue. Trigger on phrases like "notify me when done", "ping me", "let me know when you need my input", "notify me if you're stuck waiting", "text me when this finishes". Do not trigger for generic status updates the user didn't ask to be pushed externally — only fire when the user has asked for an out-of-band notification.
---

Send a one-line push notification through `ntfy` so the user finds out even if they're away from the terminal.

## When to fire

- The user explicitly asked to be notified (this session or a standing instruction) about one of:
  - The session/task stopping or finishing (successfully or not)
  - Claude blocking on a question, confirmation, or other input from the user before it can continue
- Don't fire for routine progress updates the user never asked to have pushed — this is for the two cases above only.

## How to send

Run this exact command, substituting a short, specific `$message`. Pick the form matching whichever tool you use — they are not interchangeable, each is native syntax for its own shell:

Via the **PowerShell** tool:
```powershell
& "C:\Users\Dmitry\.local\bin\ntfy.exe" publish topic_123 "$message" *> $null
```
(The leading `&` call operator is required — without it PowerShell throws "Unexpected token" trying to parse a quoted path followed by arguments as an expression. The path must be the literal hardcoded string, not `$env:USERPROFILE\...` — a variable in command-name position makes PowerShell's permission checker treat it as a "dynamic expression it cannot statically validate," which forces an explicit-approval prompt on every single run regardless of any allow-list rule.)

Via the **Bash** tool:
```bash
"$USERPROFILE/.local/bin/ntfy.exe" publish topic_123 "$message" > /dev/null 2>&1
```

Compose `$message` from the actual task context — one short line, specific enough that the user knows what it's about without opening the terminal. Examples:

- `"Claude finished the resume rewrite for the Acme posting"`
- `"Waiting on your review before submitting the Workday application"`
- `"Session stopped: job scan complete, 3 new postings shortlisted"`
- `"Claude needs your input to pick between two cover letter drafts"`

Avoid generic messages like "Task done" or "Claude is waiting" — always name what the task actually was.

The command redirects all output to null, so it's silent — after running it, just continue (or end the turn) as normal; there's no need to tell the user you sent a push notification unless it fails.
