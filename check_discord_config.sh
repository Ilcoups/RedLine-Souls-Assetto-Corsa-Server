#!/bin/bash
# Check Discord Configuration

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📢 DISCORD CONFIGURATION CHECK"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Load .env
if [ -f ".env" ]; then
    source .env
else
    echo "❌ .env file not found!"
    exit 1
fi

echo "1️⃣  MAIN WEBHOOK (Join/Leave Messages)"
if [ -n "$DISCORD_WEBHOOK" ]; then
    echo "   ✅ Configured"
    echo "   📍 Used by: unified_announcer.py"
    echo "   📝 Posts: Player joins, leaves, session summaries, checksum failures"
else
    echo "   ❌ NOT CONFIGURED"
fi
echo ""

echo "2️⃣  STATS WEBHOOK (#daily-statistic)"
if [ -n "$DISCORD_STATS_WEBHOOK" ]; then
    echo "   ✅ Configured"
    echo "   📍 Used by: player_stats.py"
    echo "   📝 Posts: Daily leaderboards (23:59 UTC), connection stats (23:50 UTC)"
    echo "   📊 NEW: Traffic poll results"
else
    echo "   ❌ NOT CONFIGURED"
fi
echo ""

echo "3️⃣  CHAT WEBHOOK (#chat-eu-1)"
if [ -n "$DISCORD_CHAT_WEBHOOK" ]; then
    echo "   ✅ Configured"
    echo "   📍 Used by: unified_announcer.py"
    echo "   📝 Posts: In-game chat messages from players"
else
    echo "   ❌ NOT CONFIGURED"
fi
echo ""

echo "4️⃣  AUDIT WEBHOOK (#servers - DiscordAuditPlugin)"
if [ -n "$DISCORD_AUDIT_WEBHOOK" ]; then
    echo "   ✅ Configured in .env"
    if [ -f "cfg/plugin_discord_audit_cfg.yml" ]; then
        echo "   ✅ Plugin config exists"
        if grep -q "AuditUrl:" cfg/plugin_discord_audit_cfg.yml; then
            echo "   ✅ Plugin configured"
        else
            echo "   ⚠️  Plugin config missing AuditUrl"
        fi
    else
        echo "   ⚠️  Plugin config file missing"
    fi
    echo "   📍 Used by: DiscordAuditPlugin"
    echo "   📝 Posts: Server connections, disconnections, status updates"
else
    echo "   ⚠️  NOT CONFIGURED (optional)"
fi
echo ""

echo "5️⃣  HUB DISCORD BOT (Server Status)"
if [ -f "hub/configuration.yml" ]; then
    if grep -q "DiscordBotToken:" hub/configuration.yml; then
        echo "   ✅ Bot token configured"
        if grep -q "DiscordServerStatus:" hub/configuration.yml; then
            echo "   ✅ Server status feature enabled"
            echo "   📍 Command: /server-status redline-tokyo"
            echo "   📝 Posts: Live server status (online/offline, player count, time)"
        else
            echo "   ⚠️  Server status not configured"
        fi
    else
        echo "   ❌ Bot token NOT configured"
    fi
else
    echo "   ❌ Hub config not found"
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

REQUIRED=0
CONFIGURED=0

# Check required
[ -n "$DISCORD_WEBHOOK" ] && CONFIGURED=$((CONFIGURED + 1))
[ -n "$DISCORD_STATS_WEBHOOK" ] && CONFIGURED=$((CONFIGURED + 1))
[ -n "$DISCORD_CHAT_WEBHOOK" ] && CONFIGURED=$((CONFIGURED + 1))
REQUIRED=3

echo "Required webhooks: $CONFIGURED/$REQUIRED configured"

if [ $CONFIGURED -eq $REQUIRED ]; then
    echo "✅ All required Discord integrations are configured!"
else
    echo "⚠️  Some required webhooks are missing"
fi

