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

# Extract collisions
grep -E "Collision between" "$LOG_FILE" > "$OUT_DIR/collisions-${DATE_ARG}.tmp" || true

# Calculate statistics
TOTAL_CONNECTIONS=$(wc -l < "$TMP_CONNECTS" | tr -d ' ')
TOTAL_DISCONNECTS=$(wc -l < "$TMP_DISCONNECTS" | tr -d ' ')
TOTAL_COLLISIONS=$(wc -l < "$OUT_DIR/collisions-${DATE_ARG}.tmp" | tr -d ' ')

# Extract unique players (by Steam ID)
grep -oE "\(76561[0-9]+," "$TMP_CONNECTS" | sed 's/[(),]//g' | sort -u > "$TMP_UNIQUE_PLAYERS" || true
UNIQUE_PLAYERS=$(wc -l < "$TMP_UNIQUE_PLAYERS" | tr -d ' ')

# Extract player names and session counts
awk -F'\\[INF\\] ' '{print $2}' "$TMP_CONNECTS" | \
  sed -E 's/ \(76561[0-9]+,.*//' | \
  sort | uniq -c | sort -rn > "$OUT_DIR/player_sessions-${DATE_ARG}.txt" || true

# Get top 3 most active players
TOP_PLAYER_1=$(head -n1 "$OUT_DIR/player_sessions-${DATE_ARG}.txt" 2>/dev/null | awk '{$1=""; print substr($0,2)}' | sed 's/^ *//' || echo "None")
TOP_PLAYER_2=$(head -n2 "$OUT_DIR/player_sessions-${DATE_ARG}.txt" 2>/dev/null | tail -n1 | awk '{$1=""; print substr($0,2)}' | sed 's/^ *//' || echo "")
TOP_PLAYER_3=$(head -n3 "$OUT_DIR/player_sessions-${DATE_ARG}.txt" 2>/dev/null | tail -n1 | awk '{$1=""; print substr($0,2)}' | sed 's/^ *//' || echo "")
TOP_SESSIONS_1=$(head -n1 "$OUT_DIR/player_sessions-${DATE_ARG}.txt" 2>/dev/null | awk '{print $1}' || echo "0")
TOP_SESSIONS_2=$(head -n2 "$OUT_DIR/player_sessions-${DATE_ARG}.txt" 2>/dev/null | tail -n1 | awk '{print $1}' || echo "0")
TOP_SESSIONS_3=$(head -n3 "$OUT_DIR/player_sessions-${DATE_ARG}.txt" 2>/dev/null | tail -n1 | awk '{print $1}' || echo "0")

# Hourly connection activity
awk '{print substr($1,1,13)}' "$TMP_CONNECTS" | sort | uniq -c | sort -rn > "$OUT_DIR/hourly_connections-${DATE_ARG}.txt" || true

# Most popular cars
grep -oE "\([a-z_0-9]+-[0-9_a-zA-Z]+/" "$TMP_CONNECTS" | sed 's/[()]//g' | sed 's/-.*$//' | \
  sort | uniq -c | sort -rn | head -5 > "$OUT_DIR/top_cars-${DATE_ARG}.txt" || true
TOP_CAR=$(head -n1 "$OUT_DIR/top_cars-${DATE_ARG}.txt" 2>/dev/null | awk '{$1=""; print substr($0,2)}' | sed 's/^ *//' | sed 's/_/ /g' || echo "Unknown")
TOP_CAR_COUNT=$(head -n1 "$OUT_DIR/top_cars-${DATE_ARG}.txt" 2>/dev/null | awk '{print $1}' || echo "0")

# Most crashes player
awk -F"Collision between " '{print $2}' "$OUT_DIR/collisions-${DATE_ARG}.tmp" 2>/dev/null | \
  sed 's/ and.*//' | sed 's/ ([0-9]*)$//' | \
  grep -v "Traffic" | sort | uniq -c | sort -rn | head -5 > "$OUT_DIR/crash_kings-${DATE_ARG}.txt" || true
CRASH_KING=$(head -n1 "$OUT_DIR/crash_kings-${DATE_ARG}.txt" 2>/dev/null | awk '{$1=""; print substr($0,2)}' | sed 's/^ *//' || echo "No crashes")
CRASH_COUNT=$(head -n1 "$OUT_DIR/crash_kings-${DATE_ARG}.txt" 2>/dev/null | awk '{print $1}' || echo "0")

# Biggest crash (highest speed collision)
BIGGEST_CRASH=$(grep -oE "rel. speed [0-9]+km/h" "$OUT_DIR/collisions-${DATE_ARG}.tmp" 2>/dev/null | \
  sed 's/rel. speed //' | sed 's/km\/h//' | sort -n | tail -n1 || echo "0")

# Calculate average sessions per player
if [ "$UNIQUE_PLAYERS" -gt 0 ]; then
  AVG_SESSIONS=$(echo "scale=1; $TOTAL_CONNECTIONS / $UNIQUE_PLAYERS" | bc 2>/dev/null || echo "N/A")
else
  AVG_SESSIONS="N/A"
fi

# Calculate total playtime estimate (rough: connections * 15min average)
if [ "$TOTAL_CONNECTIONS" -gt 0 ]; then
  TOTAL_PLAYTIME_HOURS=$(echo "scale=1; ($TOTAL_CONNECTIONS * 15) / 60" | bc 2>/dev/null || echo "0")
else
  TOTAL_PLAYTIME_HOURS="0"
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
    PEAK_HOUR=$(echo "$PEAK_HOUR_RAW" | sed -E 's/T/ /' | sed -E 's/([0-9]{2}):00$/\1:00h/')
  else
    PEAK_HOUR="No activity"
  fi
  
  # Determine engagement emoji based on unique players
  if [ "$UNIQUE_PLAYERS" -ge 15 ]; then
    ENGAGEMENT_EMOJI="🔥"
  elif [ "$UNIQUE_PLAYERS" -ge 8 ]; then
    ENGAGEMENT_EMOJI="✨"
  elif [ "$UNIQUE_PLAYERS" -ge 3 ]; then
    ENGAGEMENT_EMOJI="👍"
  else
    ENGAGEMENT_EMOJI="😴"
  fi
  
  # Build leaderboard text
  if [ -n "$TOP_PLAYER_1" ] && [ "$TOP_PLAYER_1" != "None" ]; then
    LEADERBOARD="🥇 **${TOP_PLAYER_1}** - ${TOP_SESSIONS_1} sessions"
    if [ -n "$TOP_PLAYER_2" ]; then
      LEADERBOARD="${LEADERBOARD}\n🥈 **${TOP_PLAYER_2}** - ${TOP_SESSIONS_2} sessions"
    fi
    if [ -n "$TOP_PLAYER_3" ]; then
      LEADERBOARD="${LEADERBOARD}\n🥉 **${TOP_PLAYER_3}** - ${TOP_SESSIONS_3} sessions"
    fi
  else
    LEADERBOARD="No players today"
  fi
  
  # Build Discord embed with all the cool stats
  read -r -d '' DISCORD_MESSAGE <<'EOF' || true
{
  "embeds": [{
    "title": "EMOJI_PH REDLINE SOULS - Daily Server Report",
    "description": "**📅 DATE_PLACEHOLDER**\n\n> *The streets were ACTIVITY_DESC_PH today...*",
    "color": COLOR_PH,
    "fields": [
      {
        "name": "📊 Connection Stats",
        "value": "```yaml\nTotal Connections:   CONNECTIONS_PH\nUnique Players:      UNIQUE_PH\nAvg Sessions/Player: AVG_SESSIONS_PH\nEst. Total Playtime: PLAYTIME_PH hours```",
        "inline": false
      },
      {
        "name": "🏆 Most Active Drivers",
        "value": "LEADERBOARD_PH",
        "inline": true
      },
      {
        "name": "🚗 Popular Rides",
        "value": "**TOP_CAR_PH** ×CAR_COUNT_PH\n\n*Most picked car today*",
        "inline": true
      },
      {
        "name": "💥 Crash Statistics",
        "value": "```\nTotal Incidents:  COLLISIONS_PH\nCrash King:       CRASH_KING_PH (CRASH_COUNT_PHx)\nBiggest Impact:   BIGGEST_CRASH_PH km/h```",
        "inline": false
      },
      {
        "name": "⏰ Peak Activity",
        "value": "**PEAK_HOUR_PH** with **PEAK_CONN_PH** connections",
        "inline": false
      }
    ],
    "footer": {
      "text": "RedLine Souls • Tokyo Expressway • Stats reset daily at midnight"
    },
    "timestamp": "TIMESTAMP_PH"
  }]
}
EOF

  # Determine activity description
  if [ "$UNIQUE_PLAYERS" -ge 15 ]; then
    ACTIVITY_DESC="absolutely packed"
    COLOR="15844367"  # Red/orange
  elif [ "$UNIQUE_PLAYERS" -ge 8 ]; then
    ACTIVITY_DESC="nicely busy"
    COLOR="3447003"   # Blue
  elif [ "$UNIQUE_PLAYERS" -ge 3 ]; then
    ACTIVITY_DESC="cruising along"
    COLOR="3066993"   # Lighter blue
  else
    ACTIVITY_DESC="quiet"
    COLOR="10070709"  # Grey
  fi

  # Replace all placeholders
  DISCORD_MESSAGE="${DISCORD_MESSAGE//EMOJI_PH/$ENGAGEMENT_EMOJI}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//DATE_PLACEHOLDER/$DISPLAY_DATE}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//ACTIVITY_DESC_PH/$ACTIVITY_DESC}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//COLOR_PH/$COLOR}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//CONNECTIONS_PH/$TOTAL_CONNECTIONS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//UNIQUE_PH/$UNIQUE_PLAYERS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//AVG_SESSIONS_PH/$AVG_SESSIONS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//PLAYTIME_PH/$TOTAL_PLAYTIME_HOURS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//LEADERBOARD_PH/$LEADERBOARD}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//TOP_CAR_PH/$TOP_CAR}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//CAR_COUNT_PH/$TOP_CAR_COUNT}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//COLLISIONS_PH/$TOTAL_COLLISIONS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//CRASH_KING_PH/$CRASH_KING}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//CRASH_COUNT_PH/$CRASH_COUNT}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//BIGGEST_CRASH_PH/$BIGGEST_CRASH}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//PEAK_HOUR_PH/$PEAK_HOUR}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//PEAK_CONN_PH/$PEAK_CONNECTIONS}"
  DISCORD_MESSAGE="${DISCORD_MESSAGE//TIMESTAMP_PH/$(date -u +%Y-%m-%dT%H:%M:%S.000Z)}"

  curl -sS -X POST -H "Content-Type: application/json" -d "$DISCORD_MESSAGE" "$DISCORD_WEBHOOK" >/dev/null 2>&1 || true
  echo "Posted enhanced daily statistics to Discord webhook"
fi

exit 0
