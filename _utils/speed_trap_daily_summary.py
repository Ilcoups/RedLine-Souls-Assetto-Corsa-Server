#!/usr/bin/env python3
"""
Speed Trap Daily Summary - Posts to Discord #daily-statistic channel
Reads violation data from the past 24 hours and posts summary
"""

import json
import os
import requests
from pathlib import Path
from datetime import datetime, timedelta
from collections import defaultdict
from typing import List, Tuple, Dict

# Configuration
STATS_FILE = Path("/home/acserver/server/_utils/speed_trap_stats.json")
DISCORD_STATS_WEBHOOK = os.getenv('DISCORD_STATS_WEBHOOK')

# Load .env manually (no python-dotenv dependency)
env_path = Path('/home/acserver/server/.env')
if env_path.exists():
    with open(env_path, 'r') as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#') and '=' in line:
                key, value = line.split('=', 1)
                if key == 'DISCORD_STATS_WEBHOOK':
                    DISCORD_STATS_WEBHOOK = value.strip().strip('"\'')


def load_violations_last_24h() -> List[Dict]:
    """Load violations from last 24 hours"""
    if not STATS_FILE.exists():
        return []
    
    with open(STATS_FILE, 'r') as f:
        data = json.load(f)
        all_violations = data.get('violations', [])
    
    # Filter last 24 hours
    cutoff = datetime.now() - timedelta(hours=24)
    recent = []
    
    for v in all_violations:
        try:
            timestamp = datetime.fromisoformat(v['timestamp'])
            if timestamp >= cutoff:
                recent.append(v)
        except (KeyError, ValueError):
            continue
    
    return recent


def aggregate_daily_stats(violations: List[Dict]) -> Dict:
    """Aggregate violations into daily statistics"""
    driver_stats = defaultdict(lambda: {
        'violations': 0,
        'total_over_limit': 0,
        'max_speed': 0,
        'cameras': set()
    })
    
    all_cameras = set()
    total_over_limit = 0
    max_single_speed = 0
    worst_violation = None
    
    for v in violations:
        driver = v.get('driver', 'Unknown')
        if driver == 'Unknown':
            continue
        
        try:
            speed = int(v.get('speed', '0'))
            over_limit = int(v.get('over_limit', '0'))
            camera = v.get('camera', 'Unknown')
            
            driver_stats[driver]['violations'] += 1
            driver_stats[driver]['total_over_limit'] += over_limit
            driver_stats[driver]['max_speed'] = max(driver_stats[driver]['max_speed'], speed)
            driver_stats[driver]['cameras'].add(camera)
            
            all_cameras.add(camera)
            total_over_limit += over_limit
            
            if speed > max_single_speed:
                max_single_speed = speed
                worst_violation = {
                    'driver': driver,
                    'speed': speed,
                    'over_limit': over_limit,
                    'camera': camera
                }
        except (ValueError, TypeError):
            continue
    
    # Convert to sorted list
    leaderboard = [
        (driver, stats['violations'], stats['total_over_limit'], stats['max_speed'], len(stats['cameras']))
        for driver, stats in driver_stats.items()
    ]
    
    leaderboard.sort(key=lambda x: (-x[1], -x[2], -x[3]))
    
    return {
        'leaderboard': leaderboard[:10],  # Top 10 for daily
        'total_violations': len(violations),
        'total_drivers': len(driver_stats),
        'total_cameras': len(all_cameras),
        'total_over_limit': total_over_limit,
        'worst_violation': worst_violation
    }


def build_discord_embed(stats: Dict) -> Dict:
    """Build Discord embed for daily summary"""
    today = datetime.now().strftime("%B %d, %Y")
    
    if stats['total_violations'] == 0:
        return {
            "title": f"🚨 Speed Trap Daily Summary - {today}",
            "description": "**No violations recorded today!**\n\n✅ *Everyone drove safely!*",
            "color": 0x00FF00,  # Green
            "footer": {"text": "RedLine Souls Speed Enforcement · Drive Safe"}
        }
    
    leaderboard = stats['leaderboard']
    worst = stats['worst_violation']
    
    # Build leaderboard section
    leaderboard_lines = ["**🏆 TOP 10 MOST RECKLESS DRIVERS**\n"]
    medals = {1: "🥇", 2: "🥈", 3: "🥉"}
    
    for rank, (driver, violations, total_over, max_speed, cameras) in enumerate(leaderboard, 1):
        medal = medals.get(rank, f"**{rank}.**")
        safe_name = driver.replace("*", r"\*").replace("_", r"\_")
        if len(safe_name) > 18:
            safe_name = safe_name[:15] + "..."
        
        avg_over = total_over // violations if violations > 0 else 0
        
        leaderboard_lines.append(
            f"{medal} {safe_name} · {violations} violations · Max: {max_speed} km/h"
        )
    
    # Build worst violation section
    worst_section = []
    if worst:
        worst_section.append("\n**⚠️ WORST VIOLATION OF THE DAY**")
        worst_section.append(
            f"**{worst['driver']}** caught at **{worst['speed']} km/h** "
            f"(+{worst['over_limit']} km/h over limit)\n"
            f"📸 Camera: {worst['camera']}"
        )
    
    # Build summary stats
    stats_section = [
        "\n**📊 DAILY STATISTICS**",
        f"• Total Violations: **{stats['total_violations']}**",
        f"• Reckless Drivers: **{stats['total_drivers']}**",
        f"• Active Cameras: **{stats['total_cameras']}**",
        f"• Total km/h Over Limit: **{stats['total_over_limit']:,}**",
        f"• Mock Fines Issued: **${stats['total_violations'] * 50:,}**"
    ]
    
    description = "\n".join(
        leaderboard_lines + 
        worst_section + 
        stats_section +
        ["\n*Keep it under the limit! 🚗💨*"]
    )
    
    return {
        "title": f"🚨 Speed Trap Daily Summary - {today}",
        "description": description,
        "color": 0xFF6B00,  # Orange warning
        "footer": {"text": "RedLine Souls Speed Enforcement · Drive Responsibly"}
    }


def post_to_discord(embed: Dict) -> bool:
    """Post embed to Discord webhook"""
    if not DISCORD_STATS_WEBHOOK:
        print("⚠️  DISCORD_STATS_WEBHOOK not configured")
        return False
    
    payload = {
        "username": "🚨 Speed Enforcement",
        "embeds": [embed]
    }
    
    try:
        response = requests.post(DISCORD_STATS_WEBHOOK, json=payload, timeout=10)
        if response.status_code in [200, 204]:
            return True
        else:
            print(f"❌ Discord returned {response.status_code}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error posting to Discord: {e}")
        return False


def main():
    """Main execution"""
    print("📊 Generating speed trap daily summary...")
    
    # Load violations
    violations = load_violations_last_24h()
    print(f"   Found {len(violations)} violations in last 24 hours")
    
    # Aggregate stats
    stats = aggregate_daily_stats(violations)
    print(f"   {stats['total_drivers']} drivers, {stats['total_cameras']} cameras")
    
    # Build embed
    embed = build_discord_embed(stats)
    
    # Post to Discord
    if post_to_discord(embed):
        print(f"✅ Posted speed trap summary to Discord")
        print(f"   {stats['total_violations']} violations, {stats['total_drivers']} reckless drivers")
        return 0
    else:
        print("❌ Failed to post to Discord")
        return 1


if __name__ == "__main__":
    exit(main())
