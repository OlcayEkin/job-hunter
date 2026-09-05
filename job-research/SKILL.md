---
name: job-research
description: >
  Searches for new job openings matching the user's resume and updates a living HTML job dashboard.
  Use this skill whenever the user asks to: find jobs, search for job openings, update the job
  dashboard, run the job search, look for QA or tech roles in Turkey, or check what's new on
  kariyer.net / LinkedIn / Indeed. Also trigger if the user says anything like "find me jobs",
  "what jobs are out there", "update the dashboard", "run the job hunt", or "search for new
  postings". This skill maintains a single cumulative dashboard file — it never creates a new
  one, only appends to the existing one.
---

# Job Research & Dashboard Update Skill

You are acting as an AI recruiter, job-search strategist, and career analyst. Your job is to find
fresh job openings that match the user's profile and append them to their existing HTML dashboard —
keeping it as a single living document that grows richer with each run.

---

## Step 1 — Read the resume

Find the PDF resume in the user's job folder (look for `*.pdf` in the workspace folder, or use the
path the user mentioned). Extract it with `pdfplumber` in a bash shell. Parse out:

- **Experience level** (years, seniority)
- **Core skills** (languages, frameworks, tools)
- **Domain experience** (industries, platforms)
- **Best-fit roles** (infer from titles and responsibilities)

You need this to write targeted search queries and assign fit scores later.

---

## Step 2 — Locate the existing dashboard

Look for a `job-dashboard-*.html` file in the workspace folder. If there are several, use the most
recently modified one. Do **not** create a new file; the goal is to keep adding to the same
document so the user has a complete history.

Extract the list of companies + job titles already in the dashboard so you can skip duplicates
in Step 3.

---

## Step 3 — Search for new job postings

Search across these sources, focusing on postings from the **last 7 days** (3 days preferred):

- **kariyer.net** — fetch listing pages directly with `web_fetch` (e.g.
  `https://www.kariyer.net/is-ilanlari/yazilim+test+muhendisi`,
  `https://www.kariyer.net/is-ilanlari/test+otomasyon+muhendisi`)
- **LinkedIn** — web search with `site:linkedin.com/jobs` queries
- **BuiltIn / Indeed** — web search for Turkey / remote roles
- **Company career pages** — well-known Turkish tech companies (Trendyol, Insider, Commencis,
  Getir, Etiya, Egemsoft, Baykar, Mobilişim, Optiim, Anadolu Sigorta, Turkcell, etc.)

**Location constraint:** Turkey only — Istanbul, Ankara, Izmir, or Remote. No roles outside Turkey.

Use the user's extracted skills to build specific search queries. Adapt queries to the actual
resume — for a QA/automation background, try things like:
- `site:kariyer.net "test otomasyon" İstanbul Haziran 2026`
- `QA automation engineer Turkey remote job June 2026`
- `kariyer.net yazılım test mühendisi uzaktan 2026`

For each candidate posting verify it is:
- Not already listed in the existing dashboard (check company + title)
- Posted within the last 7 days
- Located in Turkey or is a remote role open to Turkey

Aim for at least 5 new postings per run; stop when you have 10+ genuinely new ones.

---

## Step 4 — Score and categorise each job

For every new posting assign:

| Field | Guidance |
|---|---|
| **Fit Score (0–100)** | 90+ = near-perfect skill match; 70–89 = good match with minor gaps; 50–69 = stretch |
| **Priority** | High (80+), Medium (65–79), Stretch (<65) |
| **Key Skills** | 4–6 tags drawn from the job description |
| **Exp Required** | e.g. "Senior (5+ yrs)" |
| **Salary** | Include if stated; otherwise "Not listed" |

Be honest about fit — do not inflate scores to make the dashboard look better.

---

## Step 5 — Update the dashboard HTML

Edit the existing dashboard file in place. Make these targeted changes:

### Header chips
Increment **Run number** by 1, update **date** to today, increment **Jobs Found** by the count
of new listings, update **High Match / Medium Match / Stretch** counts accordingly.

### New section banner
Before the new rows, insert a section-header row:

```html
<tr class="section-header-row">
  <td colspan="11" class="sh-high" style="border-color:var(--accent) !important;color:var(--accent)">
    🆕 NEW ADDITIONS — [Date] (Run [N])
  </td>
</tr>
```

### New job rows
Insert one `<tr>` per new job, following the exact HTML pattern of existing rows. Match the CSS
class conventions already in the file:

- **Date freshness:** `date-new` (≤3 days), `date-week` (4–7 days), `date-old` (older)
- **Score classes:** `score-90`/`bar-90` for 90+, `score-80`/`bar-80` for 80–89,
  `score-70`/`bar-70` for 70–79, `score-60`/`bar-60` for 60–69
- **Priority badges:** `priority-high`, `priority-medium`, `priority-stretch`
- **Source badges:** `source-builtin`, `source-linkedin`, `source-careers` (kariyer.net / company pages)

Number rows sequentially continuing from the last existing row number.

### Footer
Update the "Last Updated" date and run note in the footer line.

**Do not touch any existing rows, CSS, profile section, or resume tips.**

---

## Step 6 — Present the updated file

After saving, present the updated dashboard file to the user. Give a brief summary: how many new
jobs were added, which categories they fall into, and any standout finds worth highlighting.

---

## Dashboard column reference (in order)

Row number · Job Title (linked to apply URL) · Company name + 1–2 line overview · Location chip ·
Posted date chip · Experience required · Key skills tags · Salary · Source badge · Fit score bar ·
Priority badge

---

## Key rules

- **One file only.** Never create a new dashboard file. Always update the existing one.
- **No duplicates.** Skip any company + title already present in the dashboard.
- **Turkey only.** Reject postings outside Turkey or remote roles restricted to other regions.
- **Recency first.** Prefer ≤3 days old; accept up to 7 days if needed to reach 5+ new listings.
- **Honest scoring.** Score based on actual skill overlap with the resume, not wishful thinking.
- **Never fabricate.** Only include jobs actually retrieved from a real search/fetch result in
  this run — no invented salaries, descriptions, or posting URLs. If a source (Indeed, kariyer.net,
  Glassdoor, etc.) blocks the fetch, say so in the filter notice / footer instead of making up data.
- **Surgical HTML edits.** Use targeted `Edit` calls rather than rewriting the whole file.
  Verify balanced tags after each edit.

---

## Daily automation (macOS launchd + Gmail SMTP)

This workflow is wired up to run unattended every day at **13:00 local time (Europe/Istanbul)** and
email the result. If the user asks to set this up again, re-check, or replicate it elsewhere, this
is the exact setup already deployed — **read this whole section before changing anything**, it
documents two real production bugs that ate a debugging session each.

**Files (all under `~/.job-hunter-automation/`, deliberately NOT under `~/Desktop`):**
- `update_dashboard.sh` — the runner script. It calls the local `claude` CLI in headless mode
  (`claude -p "<prompt>" --allowedTools "Read,Write,Edit,Bash,WebSearch,WebFetch"`) with a prompt
  that: re-reads the resume PDF (still on Desktop), searches LinkedIn/Indeed/kariyer.net/Glassdoor/
  Empatik HR for fresh QA Lead/Manager roles in Turkey, rebuilds the dashboard table in
  `~/Desktop/job-hunter/job-dashboard-2026-05-30.html` in place, and writes a short plain-text
  summary (5–10 lines, no markdown) to `last_summary.txt`. It then emails the summary + dashboard
  via `send_email.py`, with a `send_failure_notification` fallback (macOS banner + failure email)
  if the `claude` step or the email step itself fails.
- `send_email.py` — sends mail via **Gmail SMTP** (`smtp.gmail.com:587`, STARTTLS) using Python's
  stdlib `smtplib`/`email` — no Mail.app, no AppleScript. Reads credentials from `gmail.env`.
  Usage: `send_email.py <subject> <body_text_file> [attachment_path]`.
- `gmail.env` — `chmod 600`, holds `GMAIL_ADDRESS=olcayekinn@gmail.com` and a Gmail **App Password**
  (`GMAIL_APP_PASSWORD=...`, from myaccount.google.com/apppasswords). Never commit this file or
  print its contents; it lives outside the git repo on purpose.
- `last_summary.txt`, `email_body.txt`, `failure_body.txt` — per-run scratch files.
- `update.log`, `launchd.out.log`, `launchd.err.log` — run logs, useful for debugging a missed or
  failed run.
- `~/Library/LaunchAgents/com.olcay.jobdashboard.update.plist` — the launchd job.
  `ProgramArguments` is **just the script path** (`["/Users/olcayekin/.job-hunter-automation/update_dashboard.sh"]`),
  relying on its `#!/bin/zsh` shebang — do not wrap it in `["/bin/zsh", "-lc", "path"]`, see bug #2
  below. `StartCalendarInterval` Hour 13 / Minute 0, `RunAtLoad` false. Load/reload with:
  `launchctl unload ~/Library/LaunchAgents/com.olcay.jobdashboard.update.plist 2>/dev/null; launchctl load ~/Library/LaunchAgents/com.olcay.jobdashboard.update.plist`.
  To test immediately instead of waiting for 13:00: `launchctl kickstart -p gui/$(id -u)/com.olcay.jobdashboard.update`
  (real launchd invocation — do NOT use `env -i ... zsh -lc script` to "simulate" it, that strips
  keychain/session context the real GUI-domain agent has and produces misleading failures, e.g. a
  fake "Not logged in · Please run /login" from `claude`).

**Two bugs already found and fixed here — don't reintroduce them:**

1. **PATH.** launchd runs agents with a minimal `PATH=/usr/bin:/bin:/usr/sbin:/sbin` — it does not
   include `~/.local/bin` (where `claude` lives) or `/opt/homebrew/bin` (brew/gh). The script
   hardcodes `export PATH="$HOME/.local/bin:/opt/homebrew/bin:/usr/local/bin:$PATH"` at the top.
   Symptom without this fix: `command not found: claude`, exit 127.

2. **iCloud Desktop & Documents sync.** The user has `FXICloudDriveDesktop=1`, so `~/Desktop` is
   backed by Apple's FileProvider framework. launchd's plain `zsh` process lacks the entitlement to
   materialize files through that provider, so trying to `exec` a script that lives under
   `~/Desktop` fails with a misleading `zsh: can't open input file: <path>` — even though the exact
   same file opens fine when run manually from an interactive terminal (which does have the needed
   entitlement/session context). This is why the runner script and its logs live in
   `~/.job-hunter-automation/` instead of `~/Desktop/job-hunter/.automation/`. Only the *runner
   script* needed to move — the dashboard HTML/resume can stay on Desktop, since those are read/
   written by the `claude` subprocess, not launchd's zsh directly, and that path has worked fine.
   **If this error ever reappears for a new script, suspect this before anything else** — it looks
   exactly like a permissions or syntax problem but isn't.

**Caveats to keep in mind:**
- launchd only fires while the Mac is awake, logged in, and not asleep at 13:00 — it does not
  catch up missed runs.
- The Gmail App Password must stay valid; if the user changes their Google account password or
  revokes app passwords, `send_email.py` will fail (the failure-notification path should still fire
  a macOS banner, but the failure *email* itself would also fail in that scenario — the banner is
  the only guaranteed signal at that point).
- This is a **local**, not a cloud, routine — it depends on this specific Mac. It cannot be
  replicated via a `RemoteTrigger`/cloud routine because the dashboard files live outside git and
  the cloud sandbox can't reach this filesystem, this Mac's keychain, or `~/.job-hunter-automation/`.
