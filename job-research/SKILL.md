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
- **Surgical HTML edits.** Use targeted `Edit` calls rather than rewriting the whole file.
  Verify balanced tags after each edit.
