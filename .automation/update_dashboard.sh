#!/bin/zsh
set -euo pipefail

JOB_DIR="/Users/olcayekin/Desktop/job-hunter"
LOG_FILE="$JOB_DIR/.automation/update.log"
TARGET_FILE="job-dashboard-2026-05-30.html"
SUMMARY_FILE="$JOB_DIR/.automation/last_summary.txt"
TODAY="$(date +%Y-%m-%d)"

echo "---- $(date) ----" >> "$LOG_FILE"

cd "$JOB_DIR"

echo "(no summary written this run)" > "$SUMMARY_FILE"

PROMPT="Read Olcay Ekin - Resume.pdf in this folder to refresh your understanding of his QA Team Lead / Test Delivery Manager profile. Then search the web (LinkedIn Jobs, Indeed Turkey, kariyer.net, Glassdoor Turkey, and any other reputable Turkish/EU IT job board you can reach) for current QA Lead / QA Manager / Test Lead / Test Manager / Test Automation Lead openings in Istanbul and Turkey. Rebuild the table in $TARGET_FILE using the same HTML/CSS structure already in that file, replacing the job listings with what you find today. Only include jobs you actually retrieved from a real search result this run — never invent salaries, descriptions, or URLs. Update the header date, meta-chip counts, filter-notice text, and footer timestamp to today's date. Keep the Profile Analysis section as-is unless the resume changed. Then write a short plain-text summary (5-10 lines max, no markdown) of what changed today — new postings found, postings removed, any sources that were blocked/unreachable, and the current HIGH/MEDIUM/STRETCH counts — to the file $SUMMARY_FILE (overwrite it). If the web searches fail or return nothing new, still write a summary saying so, and do not overwrite $TARGET_FILE with empty/placeholder content."

claude -p "$PROMPT" --allowedTools "Read,Write,Edit,Bash,WebSearch,WebFetch" >> "$LOG_FILE" 2>&1

SUMMARY_BODY="$(cat "$SUMMARY_FILE" | sed 's/\\/\\\\/g; s/"/\\"/g')"

osascript <<EOF
tell application "Mail"
    set newMsg to make new outgoing message with properties {subject:"Job Hunter Dashboard - $TODAY", content:"$SUMMARY_BODY

Full dashboard attached.", visible:false}
    tell newMsg
        make new to recipient with properties {address:"olcayekinn@gmail.com"}
        make new attachment with properties {file name:(POSIX file "$JOB_DIR/$TARGET_FILE")} at after the last paragraph
    end tell
    send newMsg
end tell
EOF

osascript -e "display notification \"Job dashboard updated for $TODAY, email sent\" with title \"Job Hunter Dashboard\" sound name \"Glass\""

echo "---- done $(date) ----" >> "$LOG_FILE"
