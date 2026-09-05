# Job Hunter

A living job-search dashboard and automation setup for tracking QA Team Lead / Test Delivery
Manager opportunities in Turkey.

## Contents

| File | Purpose |
|---|---|
| `job-dashboard-2026-05-29.html`, `job-dashboard-2026-05-30.html` | Standalone HTML dashboards listing scored/prioritized job postings (LinkedIn, kariyer.net, Indeed, Glassdoor). Open directly in a browser. |
| `job_data.json` | Simpler application-pipeline tracker: company, role, status, next action, last contact. |
| `job-research/SKILL.md`, `job-research.skill` | A Claude Code skill that reads a resume, searches job boards, and updates the dashboard in place. `.skill` is the packaged (zipped) version of the same `SKILL.md`. Also documents the daily automation setup below in full detail (including two real bugs already hit and fixed). |
| `.claude/settings.local.json` | Local Claude Code permission allowlist used while developing this repo. |

## Daily automation

The runner script and its logs live **outside this repo**, at `~/.job-hunter-automation/` on the
user's Mac (not under `~/Desktop`, and not committed here — see why below). It's scheduled to run
every day at **13:00 (Europe/Istanbul)** via a macOS `launchd` agent
(`~/Library/LaunchAgents/com.olcay.jobdashboard.update.plist`, user/machine-specific, not in this
repo). Each run:

1. Re-reads the resume for an up-to-date skills/experience profile.
2. Searches LinkedIn Jobs, Indeed Turkey, kariyer.net, Glassdoor Turkey, and Empatik HR for current
   QA/Test Lead & Manager roles (plus project-based/fixed-term placements) in Istanbul/Turkey.
3. Rebuilds the job table in `job-dashboard-2026-05-30.html` in place — only real, retrieved
   listings, no fabricated data.
4. Writes a short plain-text summary of what changed.
5. Emails the summary + the updated dashboard (as an attachment) via **Gmail SMTP** (a Python
   script using stdlib `smtplib`, no Mail.app/AppleScript), and fires a local notification banner.
   A failure at either the search/rebuild step or the email step itself sends a separate failure
   notification instead of failing silently.

This automation is local to a single Mac — it depends on `launchd`, the local `claude` CLI, and a
Gmail App Password stored outside this repo, so it isn't reproducible as a cloud routine as-is.

**Why the runner script lives outside this repo/outside Desktop:** the user has iCloud Desktop &
Documents sync enabled, which backs `~/Desktop` with Apple's FileProvider framework. launchd's
plain `zsh` lacks the entitlement to materialize files through that provider, so a script placed
under `~/Desktop` fails to even start when launchd invokes it (a misleading
`zsh: can't open input file` error) — even though it runs fine manually from a terminal. Moving
just the runner script to `~/.job-hunter-automation/` fixed it; the dashboard HTML itself is fine
staying on Desktop since it's read/written by the `claude` subprocess, not launchd's `zsh` directly.

## Notes

- The resume PDF used to drive the search/scoring is intentionally **not** committed to this
  (public) repo — see `.gitignore`.
- Job listings are only included when actually retrieved from a live search/fetch that run; blocked
  or unreachable sources (some boards return HTTP 403 to automated fetches) are noted rather than
  backfilled with guessed data.
