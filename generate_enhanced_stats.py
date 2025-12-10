#!/usr/bin/env python3
"""
Generate comprehensive website statistics with historical data
Includes daily activity tracking for charts
"""

import json
from datetime import datetime, timedelta
from collections import defaultdict
import os

def load_player_stats():
    """Load player statistics from JSON file"""
    with open('/home/acserver/server/player_stats.json', 'r') as f:
        return json.load(f)

def generate_activity_chart_data(stats):
    """Generate last 30 days activity data for charts"""
    all_time = stats.get('all_time', {})
    
    # Get last 30 days
    today = datetime.now().date()
    activity_by_day = defaultdict(lambda: {'players': set(), 'sessions': 0})
    
    for steam_id, player_data in all_time.items():
        last_seen_str = player_data.get('last_seen')
        if not last_seen_str:
            continue
            
        try:
            last_seen = datetime.fromisoformat(last_seen_str.replace('Z', '+00:00'))
            last_seen_date = last_seen.date()
            
            # Count activity for last 30 days
            if (today - last_seen_date).days <= 30:
                day_key = last_seen_date.isoformat()
                activity_by_day[day_key]['players'].add(steam_id)
                activity_by_day[day_key]['sessions'] += player_data.get('join_count', 0)
        except:
            continue
    
    # Create chart data
    chart_data = {
        'labels': [],
        'players': [],
        'sessions': []
    }
    
    for i in range(29, -1, -1):
        date = today - timedelta(days=i)
        date_key = date.isoformat()
        
        chart_data['labels'].append(date.strftime('%m/%d'))
        chart_data['players'].append(len(activity_by_day.get(date_key, {}).get('players', set())))
        chart_data['sessions'].append(activity_by_day.get(date_key, {}).get('sessions', 0))
    
    return chart_data

def generate_top_speeds(stats):
    """Get top 10 max speeds"""
    all_time = stats.get('all_time', {})
    
    speed_data = []
    for steam_id, player_data in all_time.items():
        max_speed = player_data.get('max_speed', 0)
        if max_speed > 0:
            speed_data.append({
                'name': player_data['name'],
                'speed': max_speed
            })
    
    # Sort by speed and get top 10
    speed_data.sort(key=lambda x: x['speed'], reverse=True)
    return speed_data[:10]

def generate_playtime_distribution(stats):
    """Get playtime distribution from Hub.db"""
    distribution = {
        '< 1h': 0,
        '1-5h': 0,
        '5-10h': 0,
        '10-20h': 0,
        '20+ h': 0
    }
    
    try:
        import sqlite3
        db_path = '/home/acserver/server/hub/Hub.db'
        
        if not os.path.exists(db_path):
            return distribution
            
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Get all durations
        cursor.execute("SELECT duration FROM overtake_n_leaderboard_entries WHERE overtake_n_leaderboard_id = 1")
        rows = cursor.fetchall()
        conn.close()
        
        for (duration,) in rows:
            playtime_hours = (duration or 0) / 3600
            
            if playtime_hours < 1:
                distribution['< 1h'] += 1
            elif playtime_hours < 5:
                distribution['1-5h'] += 1
            elif playtime_hours < 10:
                distribution['5-10h'] += 1
            elif playtime_hours < 20:
                distribution['10-20h'] += 1
            else:
                distribution['20+ h'] += 1
                
    except Exception as e:
        print(f"Error generating playtime distribution: {e}")
    
    return distribution

def generate_monthly_stats(stats):
    """Calculate monthly statistics"""
    all_time = stats.get('all_time', {})
    
    now = datetime.now()
    current_month_start = datetime(now.year, now.month, 1)
    
    monthly_players = []
    total_sessions = 0
    top_player = None
    top_player_sessions = 0
    total_playtime = 0
    
    for steam_id, player_data in all_time.items():
        last_seen_str = player_data.get('last_seen')
        if not last_seen_str:
            continue
            
        try:
            last_seen = datetime.fromisoformat(last_seen_str.replace('Z', '+00:00'))
            last_seen = last_seen.replace(tzinfo=None)
            current_month_start_naive = datetime(now.year, now.month, 1)
        except:
            continue
        
        if last_seen >= current_month_start_naive:
            monthly_players.append(player_data['name'])
        
        join_count = player_data.get('join_count', 0)
        total_sessions += join_count
        total_playtime += player_data.get('playtime', 0)
        
        if join_count > top_player_sessions:
            top_player_sessions = join_count
            top_player = player_data['name']
    
    avg_players = len(monthly_players) // 30 if len(monthly_players) > 0 else 0
    total_playtime_hours = round(total_playtime / 3600, 1)
    
    return {
        'monthly_joins': len(monthly_players),
        'total_sessions': total_sessions,
        'top_player': top_player,
        'top_player_sessions': top_player_sessions,
        'avg_players_per_day': max(1, avg_players),
        'total_playtime_hours': total_playtime_hours
    }

def generate_leaderboard(stats, limit=20):
    """Generate Overtake Championship leaderboard from Hub.db - matching Discord bot logic"""
    try:
        import sqlite3
        db_path = '/home/acserver/server/hub/Hub.db'
        
        if not os.path.exists(db_path):
            print(f"⚠ Warning: Hub.db not found at {db_path}")
            return []
            
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        # Query matching the Discord bot logic
        cursor.execute("""
            SELECT e.score, COALESCE(p.name, 'Player') AS player_name, 
                   COALESCE(c.model, 'Unknown Car'),
                   e.duration, e.updated_at
            FROM overtake_n_leaderboard_entries AS e
            LEFT JOIN players AS p ON p.player_id = e.player_id
            LEFT JOIN cars AS c ON e.car_id = c.car_id
            WHERE e.overtake_n_leaderboard_id = 1
            AND e.duration > 3600
            ORDER BY e.score DESC
            LIMIT ?
        """, (limit,))
        
        rows = cursor.fetchall()
        conn.close()
        
        leaderboard = []
        for score, name, car, duration, updated_at in rows:
            # Clean up car name
            clean_car = car.replace("_", " ").replace("ks ", "").replace("s3", "S3").replace("bc", "BC")
            clean_car = " ".join(word.capitalize() for word in clean_car.split())
            
            # Format duration (seconds to HH:MM:SS)
            hours, remainder = divmod(duration or 0, 3600)
            mins, secs = divmod(remainder, 60)
            if hours > 0:
                duration_str = f"{int(hours)}h {int(mins)}m"
            else:
                duration_str = f"{int(mins)}m {int(secs)}s"
            
            # Format date (YYYY-MM-DD HH:MM:SS -> DD MMM)
            try:
                dt = datetime.fromisoformat(updated_at.replace('Z', '+00:00'))
                date_str = dt.strftime("%d %b")
            except:
                date_str = "Unknown"
            
            leaderboard.append({
                'name': name,
                'score': int(score),
                'car': clean_car,
                'duration': duration_str,
                'date': date_str
            })
            
        return leaderboard
        
    except Exception as e:
        print(f"❌ Error fetching overtake leaderboard: {e}")
        return []
        


def generate_car_popularity(limit=5):
    """Generate car popularity stats from Hub.db"""
    try:
        import sqlite3
        db_path = '/home/acserver/server/hub/Hub.db'
        
        if not os.path.exists(db_path):
            return {}
            
        conn = sqlite3.connect(db_path)
        cursor = conn.cursor()
        
        cursor.execute("""
            SELECT COALESCE(c.model, 'Unknown') as car_model, COUNT(*) as count
            FROM overtake_n_leaderboard_entries e
            JOIN cars c ON e.car_id = c.car_id
            GROUP BY c.model
            ORDER BY count DESC
            LIMIT ?
        """, (limit,))
        
        rows = cursor.fetchall()
        conn.close()
        
        popularity = {}
        for car, count in rows:
            clean_car = car.replace("_", " ").replace("ks ", "").replace("s3", "S3").replace("bc", "BC")
            clean_car = " ".join(word.capitalize() for word in clean_car.split())
            popularity[clean_car] = count
            
        return popularity
    except:
        return {}

def generate_speed_trap_hall_of_shame(limit=5):
    """Get top speed trap violations"""
    try:
        stats_path = '/home/acserver/server/_utils/speed_trap_stats.json'
        if not os.path.exists(stats_path):
            return []
            
        with open(stats_path, 'r') as f:
            data = json.load(f)
            
        violations = data.get('violations', [])
        
        # Sort by speed (descending)
        # Speed is stored as string "300", need to convert to int
        violations.sort(key=lambda x: int(float(x.get('speed', 0))), reverse=True)
        
        top_violations = []
        for v in violations[:limit]:
            top_violations.append({
                'driver': v.get('driver', 'Unknown'),
                'speed': int(float(v.get('speed', 0))),
                'car': v.get('car', 'Unknown'), # Note: recover script didn't parse car, but future ones might
                'date': v.get('timestamp', '').split('T')[0]
            })
            
        return top_violations
    except Exception as e:
        print(f"Error generating hall of shame: {e}")
        return []

def main():
    """Main function to generate comprehensive website statistics"""
    print("Loading player statistics...")
    stats = load_player_stats()
    
    print("Calculating monthly stats...")
    monthly_stats = generate_monthly_stats(stats)
    
    print("Generating activity chart data...")
    activity_chart = generate_activity_chart_data(stats)
    
    print("Getting top speeds...")
    top_speeds = generate_top_speeds(stats)
    
    print("Calculating playtime distribution...")
    playtime_dist = generate_playtime_distribution(stats)
    
    print("Generating leaderboard...")
    leaderboard = generate_leaderboard(stats, limit=20)
    
    print("Generating car popularity...")
    car_popularity = generate_car_popularity()
    
    print("Generating speed trap hall of shame...")
    hall_of_shame = generate_speed_trap_hall_of_shame()
    
    # Prepare output
    output = {
        'generated_at': datetime.now().isoformat(),
        'monthly_stats': monthly_stats,
        'activity_chart': activity_chart,
        'top_speeds': top_speeds,
        'playtime_distribution': playtime_dist,
        'leaderboard': leaderboard,
        'car_popularity': car_popularity,
        'hall_of_shame': hall_of_shame
    }
    
    # Write to wwwroot
    output_path = '/home/acserver/server/wwwroot/enhanced_stats.json'
    with open(output_path, 'w') as f:
        json.dump(output, f, indent=2)
    
    print(f"\n✓ Generated comprehensive statistics:")
    print(f"  - Monthly players: {monthly_stats['monthly_joins']}")
    print(f"  - Leaderboard entries: {len(leaderboard)}")
    print(f"  - Car popularity: {len(car_popularity)} cars")
    print(f"  - Hall of Shame: {len(hall_of_shame)} entries")
    print(f"  - Saved to: {output_path}")

if __name__ == '__main__':
    main()
