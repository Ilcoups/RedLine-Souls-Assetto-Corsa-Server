#!/usr/bin/env python3
"""Quick script to check Hub overtake data and diagnose PB issue"""
import sqlite3
import sys

def check_hub_database():
    try:
        conn = sqlite3.connect('hub/Hub.db')
        c = conn.cursor()
        
        print("="*70)
        print("HUB OVERTAKE LEADERBOARD STATUS")
        print("="*70)
        
        # Check leaderboards
        c.execute("SELECT COUNT(*) FROM overtake_leaderboards")
        lb_count = c.fetchone()[0]
        print(f"\n📊 Leaderboards: {lb_count}")
        
        if lb_count > 0:
            c.execute("SELECT * FROM overtake_leaderboards")
            for row in c.fetchall():
                print(f"  → {row}")
        
        # Check entries  
        c.execute("SELECT COUNT(*) FROM overtake_leaderboard_entries")
        entry_count = c.fetchone()[0]
        print(f"\n🏆 Total Entries: {entry_count}")
        
        if entry_count > 0:
            print("\nTop 5 scores:")
            c.execute("""
                SELECT p.Name, e.Score, e.Rank 
                FROM overtake_leaderboard_entries e
                JOIN players p ON e.PlayerId = p.Id
                ORDER BY e.Score DESC
                LIMIT 5
            """)
            for name, score, rank in c.fetchall():
                print(f"  {rank}. {name}: {score} pts")
        else:
            print("\n⚠️  NO ENTRIES FOUND!")
            print("   → Hub database exists but has no overtake scores")
            print("   → Players need to complete overtake runs to populate data")
        
        conn.close()
        
        print("\n" + "="*70)
        print("DIAGNOSIS:")
        if entry_count == 0:
            print("❌ Hub has NO overtake data stored")
            print("   Solution: Players need to play overtake runs")
            print("   The PB system WILL work once data exists!")
        else:
            print("✅ Hub has overtake data!")
            print("   If PB still doesn't show, check Lua script logs")
        print("="*70)
        
    except Exception as e:
        print(f"❌ Error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    check_hub_database()
