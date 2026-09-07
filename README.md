## Setup

### Claude Code
- Install [Claude Code](https://code.claude.com/docs/en/quickstart)  
(browser interaction requires a paid subscription)

### Chrome extension
- Install [Claude in Chrome extension](https://chromewebstore.google.com/detail/claude/fcoeoabgfenejglbffodgkkbkcdhcgfn)  
(at the time of writing the extension does not support Brave browser, used with Edge)

### ntfy
Useful for getting notified on your cell phone after Claude finishes a long process.
- [Install Ntfy on computer](https://docs.ntfy.sh/install/)
- [Ntfy on Android/iOS](https://ntfy.sh/) 

## Workflow

### Scan LinkedIn job postings

- Start daily job posting scan in headless mode
```
cd your_project_dir
claude -p "/scan-jobs" --chrome --permission-mode auto
```
- Check created scan files in 'tracker' folder (e.g. linkedin-scan-2026-09-07-1058.md, indeed-scan-2026-09-01-1610.md)
- Analyze the scans and decide on what to apply for.

### Apply

- Start Claude Code with access to Chrome extension:
```
claude --chrome
```
- Start application process with `apply for your_job_url_on_linkedin_or_indeed`

### Mock interview

- Create project in Claude Chat
- Add job_description and match_notes documents for the specific application to the Claude project
- Add resume in markdown format to the Claude project
- Add details of the interviewer and link to his/her LinkedIn 
- Use voice mode for realistic experience
- Ask for debrief document in markdown after the mock interview to work on details.

### Real interview
- Record real interview using Windows snipping tool
- Convert recording from mp4 to mp3 by [ffmpeg](https://www.ffmpeg.org/download.html#build-windows) (see `Convert-Mp4ToMp3.ps1`)
- Remove parts with sensitive information if needed by editing the mp3, e.g. with [Audacity](https://www.audacityteam.org/)
- Transcribe the mp3 to markdown, e.g. with [NotebookLM/Gemini Notebook](https://notebook.google/)
- Add transcription to the same mock interview Claude project to refine and have more context for future rounds