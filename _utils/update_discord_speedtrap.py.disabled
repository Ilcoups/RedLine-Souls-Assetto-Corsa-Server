#!/usr/bin/env python3
"""
Speed Trap Discord Leaderboard Updater
Reads violation data and updates Discord leaderboard message
"""

import json
import urllib.request
import urllib.error
from pathlib import Path
from typing import List, Tuple, Dict
from datetime import datetime, timedelta
from collections import defaultdict

# Configuration
STATS_FILE = Path("/home/acserver/server/_utils/speed_trap_stats.json")
CONFIG_FILE = Path("/home/acserver/server/hub/configuration.yml")

# Discord message to update (you'll need to set these)
DISCORD_CHANNEL_ID = "1436335034868170754"  # Same channel as overtake leaderboard
DISCORD_MESSAGE_ID = None  # Will be set manually or via config
DISCORD_BOT_TOKEN = None  # Loaded from config


def _load_discord_config():
    """Load Discord bot token from Hub configuration"""
    global DISCORD_BOT_TOKEN
    try:
        with open(CONFIG_FILE, 'r') as f:
            for line in f:
                if 'BotToken:' in line:
                    DISCORD_BOT_TOKEN = line.split('BotToken:')[1].strip().strip('"\'')
                    break
    except Exception as e:
        raise RuntimeError(f"Failed to load Discord config: {e}")


def _load_violations() -> List[Dict]:
    """Load violations from stats file"""
    if not STATS_FILE.exists():
        return []
    
    with open(STATS_FILE, 'r') as f:
        data = json.load(f)
        return data.get('violations', [])


def _aggregate_leaderboard(violations: List[Dict]) -> List[Tuple[str, int, int, int]]:
    """
    Aggregate violations into leaderboard format
    Returns: List of (driver_name, total_violations, total_over_limit, max_speed)
    """
    driver_stats = defaultdict(lambda: {
        'violations': 0,
        'total_over_limit': 0,
        'max_speed': 0
    })
    
    for v in violations:
        driver = v.get('driver', 'Unknown')
        if driver == 'Unknown':
            continue
            
        try:
            speed = int(v.get('speed', '0'))
            over_limit = int(v.get('over_limit', '0'))
            
            driver_stats[driver]['violations'] += 1
            driver_stats[driver]['total_over_limit'] += over_limit
            driver_stats[driver]['max_speed'] = max(driver_stats[driver]['max_speed'], speed)
        except (ValueError, TypeError):
            continue
    
    # Convert to sorted list
    leaderboard = [
        (driver, stats['violations'], stats['total_over_limit'], stats['max_speed'])
        for driver, stats in driver_stats.items()
    ]
    
    # Sort by total violations (most reckless first)
    leaderboard.sort(key=lambda x: (-x[1], -x[2], -x[3]))
    
    return leaderboard[:15]  # Top 15


def _build_embed_description(leaderboard: List[Tuple[str, int, int, int]], total_violations: int) -> str:
    """Build the Discord embed description"""
    from datetime import datetime, timezone
    
    now = datetime.now(timezone.utc).strftime("%b %d, %Y • %H:%M UTC")
    
    if not leaderboard:
        return f"""
# 🚨 SPEED TRAP LEADERBOARD

**0 VIOLATIONS** ┃ **0 DRIVERS**
*Last updated: {now}*

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

*No violations recorded yet. Drive safe!* ✅
"""
    
    lines = [
        "",
        "# 🚨 SPEED TRAP LEADERBOARD",
        "",
        f"**{total_violations} VIOLATIONS** ┃ **{len(leaderboard)} RECKLESS DRIVERS**",
        f"*Last updated: {now}*",
        "",
        "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━",
    ]
    
    medals = {1: "🥇", 2: "🥈", 3: "🥉"}
    
    for rank, (driver, violations, total_over, max_speed) in enumerate(leaderboard, 1):
        # Clean up driver name
        safe_name = driver.replace("*", r"\*").replace("_", r"\_")
        if len(safe_name) > 20:
            safe_name = safe_name[:17] + "..."
        
        # Calculate average speeding
        avg_over = total_over // violations if violations > 0 else 0
        
        if rank <= 3:
            # Top 3 - Most reckless drivers
            medal = medals[rank]
            leader_violations = leaderboard[0][1]
            percentage = int((violations / leader_violations) * 100) if rank > 1 else 100
            
            lines.append("")
            lines.append(f"## {medal} #{rank} · {safe_name}")
            lines.append(f"> 🚨 **{violations}** violations ({percentage}%)")
            lines.append(f"> ⚡ Max: **{max_speed} km/h** · Avg over: **+{avg_over} km/h**")
            lines.append(f"> 💸 Total fines: **${violations * 50:,}**")
            
        elif rank == 4:
            lines.append("")
            lines.append("─────────────────────────────────")
            lines.append("")
            lines.append(
                f"**{rank}.** {safe_name} · **{violations}** violations · Max: {max_speed} km/h"
            )
        else:
            lines.append(
                f"**{rank}.** {safe_name} · **{violations}** violations · Max: {max_speed} km/h"
            )
    
    lines.extend([
        "",
        "─────────────────────────────────",
        "",
        "*Most reckless drivers · Updates every 60s · Drive safe!* 🚗💨"
    ])
    
    description = "\n".join(lines)
    if len(description) > 4000:
        raise RuntimeError("Generated Discord embed exceeds 4096 characters")
    return description


def _patch_discord_message(channel_id: str, message_id: str, description: str):
    """Update Discord message via PATCH"""
    url = f"https://discord.com/api/v10/channels/{channel_id}/messages/{message_id}"
    
    embed = {
        "title": "🚨 Speed Enforcement Statistics",
        "description": description,
        "color": 0xFF0000,  # Red color for warnings
        "footer": {
            "text": "RedLine Souls Speed Enforcement • Drive Responsibly"
        }
    }
    
    payload = json.dumps({"embeds": [embed]}).encode('utf-8')
    
    headers = {
        'Authorization': f'Bot {DISCORD_BOT_TOKEN}',
        'Content-Type': 'application/json',
        'User-Agent': 'RedLineSouls-SpeedTrap/1.0'
    }
    
    req = urllib.request.Request(url, data=payload, headers=headers, method='PATCH')
    
    try:
        with urllib.request.urlopen(req, timeout=10) as response:
            if response.status == 200:
                return True
            else:
                raise RuntimeError(f"Discord API returned {response.status}")
    except urllib.error.HTTPError as e:
        raise RuntimeError(f"HTTP Error: {e.code} - {e.read().decode()}")


def main():
    """Main execution"""
    # Load config
    _load_discord_config()
    
    if not DISCORD_BOT_TOKEN:
        print("❌ Discord bot token not found in configuration")
        return 1
    
    # For now, check if message ID is set via env or config
    # You'll need to create the initial Discord message and put its ID here
    message_id = "PLACEHOLDER_MESSAGE_ID"  # TODO: Set this
    
    if message_id == "PLACEHOLDER_MESSAGE_ID":
        print("⚠️  Please create a Discord message for the speed trap leaderboard first")
        print("   Then set DISCORD_MESSAGE_ID in this script")
        return 0
    
    # Load violations
    violations = _load_violations()
    total_violations = len(violations)
    
    # Build leaderboard
    leaderboard = _aggregate_leaderboard(violations)
    
    # Build embed
    description = _build_embed_description(leaderboard, total_violations)
    
    # Update Discord
    _patch_discord_message(DISCORD_CHANNEL_ID, message_id, description)
    
    print(f"✓ Updated Discord speed trap leaderboard with {len(leaderboard)} drivers ({total_violations} violations)")
    return 0


if __name__ == "__main__":
    exit(main())
