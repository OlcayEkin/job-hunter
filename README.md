# Job Hunter

A living job-search dashboard and automation setup for tracking QA Team Lead / Test Delivery
Manager opportunities in Turkey.

## Contents

| File | Purpose |
|---|---|
| `job-dashboard-2026-05-29.html`, `job-dashboard-2026-05-30.html` | Standalone HTML dashboards listing scored/prioritized job postings (LinkedIn, kariyer.net, Indeed, Glassdoor). Open directly in a browser. |
| `job_data.json` | Simpler application-pipeline tracker: company, role, status, next action, last contact. |
| `job-research/SKILL.md`, `job-research.skill` | A Claude Code skill that reads a resume, searches job boards, and updates the dashboard in place. `.skill` is the packaged (zipped) version of the same `SKILL.md`. |
| `.automation/update_dashboard.sh` | Headless runner script — re-reads the resume, searches job boards, rebuilds the dashboard, and emails a summary. |
| `.claude/settings.local.json` | Local Claude Code permission allowlist used while developing this repo. |

## Daily automation

`update_dashboard.sh` is scheduled to run every day at **13:00 (Europe/Istanbul)** via a macOS
`launchd` agent (`~/Library/LaunchAgents/com.olcay.jobdashboard.update.plist`, not included in this
repo since it's user/machine-specific). Each run:

1. Re-reads the resume for an up-to-date skills/experience profile.
2. Searches LinkedIn Jobs, Indeed Turkey, kariyer.net, and Glassdoor Turkey for current QA/Test
   Lead & Manager roles in Istanbul/Turkey.
3. Rebuilds the job table in `job-dashboard-2026-05-30.html` in place — only real, retrieved
   listings, no fabricated data.
4. Writes a short plain-text summary to `.automation/last_summary.txt`.
5. Emails the summary + the updated dashboard (as an attachment) via macOS Mail.app, and fires a
   local notification banner.

This automation is local to a single Mac — it depends on `launchd`, the local `claude` CLI, and a
configured Mail.app account, so it isn't reproducible as a cloud routine as-is.

## Notes

- The resume PDF used to drive the search/scoring is intentionally **not** committed to this
  (public) repo — see `.gitignore`.
- Job listings are only included when actually retrieved from a live search/fetch that run; blocked
  or unreachable sources (some boards return HTTP 403 to automated fetches) are noted rather than
  backfilled with guessed data.
