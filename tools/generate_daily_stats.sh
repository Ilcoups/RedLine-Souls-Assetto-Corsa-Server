#!/usr/bin/env bash
# generate_daily_stats.sh
# Extract connection statistics from server logs for a given date (default: yesterday)

set -euo pipefail

TZ="Europe/Amsterdam"
# Default to yesterday since script runs at midnight
YESTERDAY=$(TZ=$TZ date -d "yesterday" +%Y%m%d 2>/dev/null || TZ=$TZ date -v-1d +%Y%m%d)
DATE_ARG="${1:-$YESTERDAY}"
LOG_DIR="$(dirname "$0")/../logs"
OUT_DIR="$LOG_DIR/stats"
mkdir -p "$OUT_DIR"

LOG_FILE="$LOG_DIR/log-${DATE_ARG}.txt"
if [ ! -f "$LOG_FILE" ]; then
  # Fallback: use the latest available log file if the requested date is missing
  LATEST_LOG=$(ls -1 "$LOG_DIR"/log-*.txt 2>/dev/null | tail -n 1 || true)
  if [ -n "$LATEST_LOG" ] && [ -f "$LATEST_LOG" ]; then
    echo "Requested log $LOG_FILE not found; falling back to latest available log: $LATEST_LOG" >&2
    LOG_FILE="$LATEST_LOG"
    # Derive DATE_ARG from the filename (log-YYYYMMDD.txt)
    BASENAME=$(basename "$LOG_FILE")
    DATE_ARG=$(echo "$BASENAME" | sed -E 's/^log-([0-9]{8})\.txt$/\1/')
  else
    echo "Log file not found: $LOG_FILE and no fallback logs available" >&2
    exit 2
  fi
fi

OUT_FILE="$OUT_DIR/stats-${DATE_ARG}.txt"
TMP_CONNECTS="$OUT_DIR/connects-${DATE_ARG}.tmp"
TMP_DISCONNECTS="$OUT_DIR/disconnects-${DATE_ARG}.tmp"
TMP_UNIQUE_PLAYERS="$OUT_DIR/unique_players-${DATE_ARG}.tmp"

echo "Generating connection stats for date $DATE_ARG from $LOG_FILE -> $OUT_FILE"

# Extract successful connections
grep -E "has connected" "$LOG_FILE" > "$TMP_CONNECTS" || true

# Extract disconnections
grep -E "has disconnected" "$LOG_FILE" > "$TMP_DISCONNECTS" || true

# Calculate statistics
TOTAL_CONNECTIONS=$(wc -l < "$TMP_CONNECTS" | tr -d ' ')
TOTAL_DISCONNECTS=$(wc -l < "$TMP_DISCONNECTS" | tr -d ' ')

# Extract unique players (by Steam ID)
grep -oE "\(76561[0-9]+," "$TMP_CONNECTS" | sed 's/[(),]//g' | sort -u > "$TMP_UNIQUE_PLAYERS" || true
UNIQUE_PLAYERS=$(wc -l < "$TMP_UNIQUE_PLAYERS" | tr -d ' ')

# Extract player names and session counts
awk -F'\\[INF\\] ' '{print $2}' "$TMP_CONNECTS" | \
  sed -E 's/ \(76561[0-9]+,.*//' | \
  sort | uniq -c | sort -rn > "$OUT_DIR/player_sessions-${DATE_ARG}.txt" || true

# Hourly connection activity
awk '{print substr($1,1,13)}' "$TMP_CONNECTS" | sort | uniq -c | sort -rn > "$OUT_DIR/hourly_connections-${DATE_ARG}.txt" || true

# Calculate average session time (rough estimate based on connects/disconnects)
if [ "$TOTAL_DISCONNECTS" -gt 0 ]; then
  AVG_SESSIONS=$(echo "scale=1; $TOTAL_CONNECTIONS / $UNIQUE_PLAYERS" | bc 2>/dev/null || echo "N/A")
else
  AVG_SESSIONS="N/A"
fi

cat > "$OUT_FILE" <<EOF
RedLine Souls - Connection Stats for ${DATE_ARG} (TZ=${TZ})
Generated: $(TZ=$TZ date)

=== CONNECTION SUMMARY ===
Total Connections:        ${TOTAL_CONNECTIONS}
Total Disconnections:     ${TOTAL_DISCONNECTS}
Unique Players:           ${UNIQUE_PLAYERS}
Avg Sessions per Player:  ${AVG_SESSIONS}

Player Sessions (most active):
---
$(head -n 20 "$OUT_DIR/player_sessions-${DATE_ARG}.txt" 2>/dev/null || true)

Hourly Connection Activity (busiest hours first):
---
$(cat "$OUT_DIR/hourly_connections-${DATE_ARG}.txt" 2>/dev/null || true)

Recent Connections (last 50):
---
$(tail -n 50 "$TMP_CONNECTS" 2>/dev/null | awk -F'\\[INF\\] ' '{print $1" "$2}' || true)

EOF

echo "Stats written to $OUT_FILE"

# Post connection statistics to Discord
if [ -n "${DISCORD_WEBHOOK:-}" ]; then
  # Format date nicely
  DISPLAY_DATE=$(echo "$DATE_ARG" | sed -E 's/([0-9]{4})([0-9]{2})([0-9]{2})/\3\/\2\/\1/')
  
  # Build Discord embed
  read -r -d '' DISCORD_MESSAGE <<'EOF' || true
{
  "embeds": [{
    "title": "🎮 REDLINE SOULS - Daily Server Statistics",
    "description": "**Connection Report for DATE_PLACEHOLDER**",
    "color": 3447003,
    "fields": [
      {
        "name": "📊 Connection Overview",
        "value": "```\n╔════════════════════════════════════╗\n║  Total Connections:  CONNECTIONS_PH║\n║  Unique Players:     UNIQUE_PH     ║\n║  Total Sessions:     SESSIONS_PH   ║\n╚════════════════════════════════════╝\n```",
        "inline": false
      },
      {
        "name": "📈 Activity Metrics",
        "value": "```\nAvg Sessions/Player: AVG_SESSIONS_PH\nPeak Activity:       PEAK_HOUR_PH\n```",
        "inline": false
      }
    ],
    "footer": {
      "text": "Stats generated from server logs • Europe/Amsterdam timezone"
    },
    "timestamp": "TIMESTAMP_PH"
  }]
}
EOF

  # Find peak hour
  PEAK_HOUR=$(head -n1 "$OUT_DIR/hourly_connections-${DATE_ARG}.txt" 2>/dev/null | awk '{print $2}' | sed -E 's/T/ /' || echo "N/A")
  if [ "$PEAK_HOUR" = "N/A" ]; then
    PEAK_HOUR="No activity"
  fi

  # Replace placeholders
  DISCORD_MESSAGE="${DISCORD_MESSAGE//DATE_PLACEHOLDER/$DISPLAY_DATE}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//CONNECTIONS_PH/$(printf '%15s' $TOTAL_CONNECTIONS)}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//UNIQUE_PH/$(printf '%15s' $UNIQUE_PLAYERS)}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//SESSIONS_PH/$(printf '%15s' $TOTAL_DISCONNECTS)}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//AVG_SESSIONS_PH/$(printf '%-10s' $AVG_SESSIONS)}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//PEAK_HOUR_PH/$(printf '%-10s' "$PEAK_HOUR")}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//TIMESTAMP_PH/$(date -u +%Y-%m-%dT%H:%M:%S.000Z)}"

  curl -sS -X POST -H "Content-Type: application/json" -d "$DISCORD_MESSAGE" "$DISCORD_WEBHOOK" >/dev/null 2>&1 || true
  echo "Posted connection statistics to Discord webhook"
fi

exit 0
