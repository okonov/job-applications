---
description: Run the LinkedIn and Indeed job scans in parallel, then notify the user when both are done.
---

Run both of these in a single message with two parallel Agent tool calls (not sequential):

1. `Agent` with `subagent_type: "linkedin-job-scan"` — no extra args needed, use the agent's default search.
2. `Agent` with `subagent_type: "indeed-job-scan"` — no extra args needed, use the agent's default search.

Wait for both to finish. Then invoke the `notify-me` skill to push a notification to the user summarizing the outcome: how many new shortlisted candidates each scan found and the paths to the two new files written under `tracker/`. If a scan failed or found nothing, say so in the notification instead of a count.
