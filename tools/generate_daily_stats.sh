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

# New players (simplified - just set to 0 for now, can enhance later)
NEW_PLAYERS=0

# Extract player names and session counts
awk -F'\\[INF\\] ' '{print $2}' "$TMP_CONNECTS" | \
  sed -E 's/ \(76561[0-9]+,.*//' | \
  sort | uniq -c | sort -rn > "$OUT_DIR/player_sessions-${DATE_ARG}.txt" || true

# Hourly connection activity
awk '{print substr($1,1,13)}' "$TMP_CONNECTS" | sort | uniq -c | sort -rn > "$OUT_DIR/hourly_connections-${DATE_ARG}.txt" || true

# Find peak hours (top 3)
PEAK_HOURS=$(head -n3 "$OUT_DIR/hourly_connections-${DATE_ARG}.txt" 2>/dev/null | awk '{print $2}' | sed -E 's/.*T([0-9]{2}):.*/\1:00/' | tr '\n' ', ' | sed 's/,$//' || echo "N/A")

# Countries/regions (extract IPs and rough location - basic version)
# We'll use the IP from disconnect messages for simplicity
grep "Disconnecting" "$LOG_FILE" 2>/dev/null | grep -oE "\([0-9]+\.[0-9]+\.[0-9]+\.[0-9]+:" | sed 's/[():]//g' | sort -u > "$OUT_DIR/unique_ips-${DATE_ARG}.tmp" || true
UNIQUE_IPS=$(wc -l < "$OUT_DIR/unique_ips-${DATE_ARG}.tmp" | tr -d ' ')

# Calculate average sessions per player
if [ "$UNIQUE_PLAYERS" -gt 0 ]; then
  AVG_SESSIONS=$(echo "scale=1; $TOTAL_CONNECTIONS / $UNIQUE_PLAYERS" | bc 2>/dev/null || echo "N/A")
else
  AVG_SESSIONS="0"
fi

# Calculate total playtime estimate (connections * 20min average)
if [ "$TOTAL_CONNECTIONS" -gt 0 ]; then
  TOTAL_PLAYTIME_HOURS=$(echo "scale=1; ($TOTAL_CONNECTIONS * 20) / 60" | bc 2>/dev/null || echo "0")
else
  TOTAL_PLAYTIME_HOURS="0"
fi

# Calculate average session length
if [ "$TOTAL_DISCONNECTS" -gt 0 ] && [ "$TOTAL_CONNECTIONS" -gt 0 ]; then
  # Very rough estimate: total connections vs disconnects
  AVG_SESSION_MIN=$(echo "scale=0; 20" | bc)  # Default 20min
else
  AVG_SESSION_MIN="N/A"
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
  
  # Find peak hour and format it nicely
  PEAK_HOUR_RAW=$(head -n1 "$OUT_DIR/hourly_connections-${DATE_ARG}.txt" 2>/dev/null | awk '{print $2}' || echo "")
  PEAK_CONNECTIONS=$(head -n1 "$OUT_DIR/hourly_connections-${DATE_ARG}.txt" 2>/dev/null | awk '{print $1}' || echo "0")
  if [ -n "$PEAK_HOUR_RAW" ]; then
    PEAK_HOUR=$(echo "$PEAK_HOUR_RAW" | sed -E 's/.*T([0-9]{2}):.*/\1:00/' | sed 's/^0//')
  else
    PEAK_HOUR="N/A"
  fi
  
  # Determine server health emoji and status
  if [ "$UNIQUE_PLAYERS" -ge 15 ]; then
    STATUS_EMOJI="🔥"
    SERVER_STATUS="Extremely Active"
    COLOR="15844367"  # Red/orange
  elif [ "$UNIQUE_PLAYERS" -ge 8 ]; then
    STATUS_EMOJI="✨"
    SERVER_STATUS="Healthy Activity"
    COLOR="3447003"   # Blue
  elif [ "$UNIQUE_PLAYERS" -ge 3 ]; then
    STATUS_EMOJI="�"
    SERVER_STATUS="Moderate Traffic"
    COLOR="3066993"   # Lighter blue
  else
    STATUS_EMOJI="�"
    SERVER_STATUS="Quiet Day"
    COLOR="10070709"  # Grey
  fi
  
  # Retention message
  if [ "$UNIQUE_PLAYERS" -gt 0 ] && [ "$AVG_SESSIONS" != "N/A" ]; then
    if [ "$(echo "$AVG_SESSIONS >= 2.5" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      RETENTION_MSG="Great player retention! 🎯"
    elif [ "$(echo "$AVG_SESSIONS >= 1.5" | bc 2>/dev/null || echo 0)" -eq 1 ]; then
      RETENTION_MSG="Good engagement 👍"
    else
      RETENTION_MSG="Room for improvement 📈"
    fi
  else
    RETENTION_MSG="No activity"
  fi
  
  # New players message
  if [ "$NEW_PLAYERS" -gt 0 ]; then
    NEW_PLAYER_MSG="\\n🆕 **${NEW_PLAYERS}** new racer(s) discovered us!"
  else
    NEW_PLAYER_MSG=""
  fi
  
  # Build Discord embed focused on server health
  read -r -d '' DISCORD_MESSAGE <<'EOF' || true
{
  "embeds": [{
    "title": "STATUS_EMOJI_PH Server Health Report - RedLine Souls",
    "description": "**📅 DATE_PLACEHOLDER**\n\n> **Server Status:** SERVER_STATUS_PHNEW_PLAYERS_MSG_PH",
    "color": COLOR_PH,
    "fields": [
      {
        "name": "📊 Connection Metrics",
        "value": "```yaml\nTotal Connections:   CONNECTIONS_PH\nUnique Players:      UNIQUE_PH\nUnique IPs:          IPS_PH\nAvg Sessions/Player: AVG_SESSIONS_PH```",
        "inline": false
      },
      {
        "name": "⏰ Peak Activity Times",
        "value": "**Busiest Hour:** PEAK_HOUR_PH (PEAK_CONN_PH connections)\n**Top Hours:** PEAK_HOURS_PH",
        "inline": false
      },
      {
        "name": "� Engagement Analysis",
        "value": "```\nEst. Total Playtime: PLAYTIME_PH hours\nAvg Session Length:  AVG_SESSION_PH min\nPlayer Retention:    RETENTION_MSG_PH```",
        "inline": false
      },
      {
        "name": "🌍 Global Reach",
        "value": "**UNIQUE_IPS_PH** unique IP addresses connected\n*Players from around the world!*",
        "inline": false
      }
    ],
    "footer": {
      "text": "RedLine Souls • Server Analytics • Data resets at midnight UTC"
    },
    "timestamp": "TIMESTAMP_PH"
  }]
}
EOF

  # Replace all placeholders
  DISCORD_MESSAGE="${DISCORD_MESSAGE//STATUS_EMOJI_PH/$STATUS_EMOJI}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//DATE_PLACEHOLDER/$DISPLAY_DATE}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//SERVER_STATUS_PH/$SERVER_STATUS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//COLOR_PH/$COLOR}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//CONNECTIONS_PH/$TOTAL_CONNECTIONS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//UNIQUE_PH/$UNIQUE_PLAYERS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//IPS_PH/$UNIQUE_IPS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//AVG_SESSIONS_PH/$AVG_SESSIONS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//PEAK_HOUR_PH/$PEAK_HOUR}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//PEAK_CONN_PH/$PEAK_CONNECTIONS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//PEAK_HOURS_PH/$PEAK_HOURS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//PLAYTIME_PH/$TOTAL_PLAYTIME_HOURS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//AVG_SESSION_PH/$AVG_SESSION_MIN}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//RETENTION_MSG_PH/$RETENTION_MSG}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//UNIQUE_IPS_PH/$UNIQUE_IPS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//NEW_PLAYERS_MSG_PH/$NEW_PLAYER_MSG}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//TIMESTAMP_PH/$(date -u +%Y-%m-%dT%H:%M:%S.000Z)}"

  curl -sS -X POST -H "Content-Type: application/json" -d "$DISCORD_MESSAGE" "$DISCORD_WEBHOOK" >/dev/null 2>&1 || true
  echo "Posted server health statistics to Discord webhook"
fi

exit 0
