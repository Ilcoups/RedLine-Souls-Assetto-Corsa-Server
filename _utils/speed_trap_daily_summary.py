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


def load_violations_all_time() -> List[Dict]:
    """Load ALL violations (all-time leaderboard)"""
    if not STATS_FILE.exists():
        return []
    
    with open(STATS_FILE, 'r') as f:
        data = json.load(f)
        all_violations = data.get('violations', [])
    
    return all_violations


def aggregate_all_time_stats(violations: List[Dict]) -> Dict:
    """Aggregate violations into all-time statistics"""
    driver_stats = defaultdict(lambda: {
        'violations': 0,
        'total_over_limit': 0,
        'max_speed': 0,
        'cameras': set(),
        'first_violation': None,
        'last_violation': None
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
            timestamp = v.get('timestamp', '')
            
            driver_stats[driver]['violations'] += 1
            driver_stats[driver]['total_over_limit'] += over_limit
            driver_stats[driver]['max_speed'] = max(driver_stats[driver]['max_speed'], speed)
            driver_stats[driver]['cameras'].add(camera)
            
            # Track first and last violation
            if not driver_stats[driver]['first_violation']:
                driver_stats[driver]['first_violation'] = timestamp
            driver_stats[driver]['last_violation'] = timestamp
            
            all_cameras.add(camera)
            total_over_limit += over_limit
            
            if speed > max_single_speed:
                max_single_speed = speed
                worst_violation = {
                    'driver': driver,
                    'speed': speed,
                    'over_limit': over_limit,
                    'camera': camera,
                    'timestamp': timestamp
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
        'leaderboard': leaderboard[:10],  # Top 10
        'total_violations': len(violations),
        'total_drivers': len(driver_stats),
        'total_cameras': len(all_cameras),
        'total_over_limit': total_over_limit,
        'worst_violation': worst_violation
    }


def build_discord_embed(stats: Dict) -> Dict:
    """Build Discord embed for all-time leaderboard"""
    
    if stats['total_violations'] == 0:
        return {
            "title": "🚨 Speed Trap Leaderboard",
            "description": "**No violations recorded yet!**\n\n✅ *All clean records so far!*",
            "color": 0x00FF00,  # Green
            "footer": {"text": "RedLine Souls Speed Enforcement · Drive Safe"}
        }
    
    leaderboard = stats['leaderboard']
    worst = stats['worst_violation']
    
    # Build leaderboard section
    leaderboard_lines = ["**🏆 ALL-TIME MOST RECKLESS DRIVERS**\n"]
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
        worst_section.append("\n**⚠️ WORST VIOLATION EVER**")
        worst_section.append(
            f"**{worst['driver']}** caught at **{worst['speed']} km/h** "
            f"(+{worst['over_limit']} km/h over limit)\n"
            f"📸 Camera: {worst['camera']}"
        )
    
    # Build summary stats
    stats_section = [
        "\n**📊 ALL-TIME STATISTICS**",
        f"• Total Violations: **{stats['total_violations']:,}**",
        f"• Reckless Drivers: **{stats['total_drivers']}**",
        f"• Active Cameras: **{stats['total_cameras']}**",
        f"• Total km/h Over Limit: **{stats['total_over_limit']:,}**",
        f"• Mock Fines Issued: **${stats['total_violations'] * 50:,}**"
    ]
    
    description = "\n".join(
        leaderboard_lines + 
        worst_section + 
        stats_section +
        ["\n*Updated continuously · Keep it under the limit! 🚗💨*"]
    )
    
    return {
        "title": "🚨 Speed Trap Leaderboard - RedLine Souls",
        "description": description,
        "color": 0xFF6B00,  # Orange warning
        "footer": {"text": f"RedLine Souls Speed Enforcement · Last updated: {datetime.now().strftime('%b %d, %H:%M UTC')}"}
    }


MSG_ID_FILE = Path(__file__).parent / "speed_trap_msg.json"

def post_to_discord(embed: Dict) -> bool:
    """Post or edit embed to Discord webhook"""
    if not DISCORD_STATS_WEBHOOK:
        print("⚠️  DISCORD_STATS_WEBHOOK not configured")
        return False
    
    payload = {
        "username": "🚨 Speed Enforcement",
        "embeds": [embed]
    }
    
    # Try to edit existing message first
    message_id = None
    if MSG_ID_FILE.exists():
        try:
            with open(MSG_ID_FILE, 'r') as f:
                data = json.load(f)
                message_id = data.get('id')
        except:
            pass
            
    if message_id:
        # Construct edit URL: webhook_url/messages/message_id
        # Ensure webhook URL doesn't have query params for this part
        base_url = DISCORD_STATS_WEBHOOK.split('?')[0]
        edit_url = f"{base_url}/messages/{message_id}"
        
        try:
            response = requests.patch(edit_url, json=payload, timeout=10)
            if response.status_code in [200, 204]:
                print(f"✅ Updated existing Discord message ({message_id})")
                return True
            elif response.status_code == 404:
                print("ℹ️  Previous message not found, creating new one...")
            else:
                print(f"⚠️  Edit failed ({response.status_code}), creating new one...")
        except Exception as e:
            print(f"⚠️  Edit error: {e}")
            
    # Create new message if edit failed or no ID
    try:
        # Add wait=true to get message ID back
        post_url = DISCORD_STATS_WEBHOOK
        if '?' in post_url:
            post_url += "&wait=true"
        else:
            post_url += "?wait=true"
            
        response = requests.post(post_url, json=payload, timeout=10)
        if response.status_code in [200, 204]:
            try:
                data = response.json()
                new_id = data.get('id')
                if new_id:
                    with open(MSG_ID_FILE, 'w') as f:
                        json.dump({'id': new_id, 'timestamp': datetime.now().isoformat()}, f)
                    print(f"✅ Posted new Discord message ({new_id})")
            except:
                print("✅ Posted to Discord (could not save ID)")
            return True
        else:
            print(f"❌ Discord returned {response.status_code}: {response.text}")
            return False
    except Exception as e:
        print(f"❌ Error posting to Discord: {e}")
        return False


def main():
    """Main execution"""
    print("📊 Generating speed trap leaderboard...")
    
    # Load ALL violations (all-time)
    violations = load_violations_all_time()
    print(f"   Found {len(violations)} total violations")
    
    # Aggregate stats
    stats = aggregate_all_time_stats(violations)
    print(f"   {stats['total_drivers']} drivers, {stats['total_cameras']} cameras")
    
    # Build embed
    embed = build_discord_embed(stats)
    
    # Post to Discord
    if post_to_discord(embed):
        print(f"✅ Posted speed trap leaderboard to Discord")
        print(f"   {stats['total_violations']} total violations, {stats['total_drivers']} reckless drivers")
        return 0
    else:
        print("❌ Failed to post to Discord")
        return 1


if __name__ == "__main__":
    exit(main())
