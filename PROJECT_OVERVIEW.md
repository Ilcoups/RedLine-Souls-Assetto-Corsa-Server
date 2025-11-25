# RedLine Souls Server - Project Overview

This document provides a comprehensive explanation of how the RedLine Souls Assetto Corsa server works, based on the current codebase.

## 🏗️ Architecture Overview

The server is built on top of **AssettoServer** (a modded server binary) and enhanced with a suite of custom Python scripts that manage traffic, statistics, and Discord integration.

### Core Components

1.  **Game Server (`AssettoServer`)**: The main binary that hosts the race.
2.  **The Hub (`AssettoServer.Hub`)**: A central process that manages data persistence (SQLite `Hub.db`) and likely facilitates plugin communication.
3.  **Management Scripts**: Shell scripts (`start_server.sh`, `restart_all.sh`) that orchestrate the startup of all components.

---

## 🧠 The "Brain" (Custom Python Scripts)

The server's intelligence is distributed across three main Python scripts running alongside the game server.

### 1. Dynamic Traffic Manager (`dynamic_traffic.py`)
*The "Dungeon Master" for AI traffic.*

*   **Traffic Rotation**: Changes traffic patterns every 6 hours (Night, Morning, Afternoon, Evening) without restarting the server.
    *   **Night (00-06)**: Light traffic, slower speeds.
    *   **Morning (06-12)**: Dense traffic, aggressive rush hour.
    *   **Afternoon (12-18)**: Balanced flow.
    *   **Evening (18-24)**: Aggressive "attack" mode.
*   **Auto-Scaling**: Monitors player count every 5 minutes. As more real players join, it reduces AI traffic to maintain performance (e.g., 30% reduction at 21+ players).
*   **Health Monitor**: Checks CPU/RAM usage every minute. If the server is stressed (CPU > 85%), it triggers an **Emergency Traffic Reduction** to prevent lag.
*   **Democracy**: Analyzes player votes (from `unified_announcer.py`) to suggest tuning adjustments for traffic density/speed.

### 2. Unified Announcer (`unified_announcer.py`)
*The "Voice" of the server.*

*   **Discord Events**: Posts rich embeds to Discord when players join, leave, or complete a session.
    *   *Feature*: It edits the original "Join" message when a player leaves to add their session stats (playtime, car used), keeping the Discord channel clean.
*   **In-Game Chat**: Bridges messages between the server and external tools via a UDP plugin.
*   **Traffic Polls**: Automatically asks players for feedback (`/1` to `/5`) at specific milestones (10m, 30m, 90m, 3h).
*   **Audio Triggers**: Sends hidden commands (`SPAWN_AUDIO|steam_id`) to clients to trigger custom sound effects (served by the Audio Server).

### 3. Player Stats Tracker (`player_stats.py`)
*The "Scorekeeper".*

*   **Tracking**: Records collisions, max speeds, playtime, and join streaks for every player.
*   **Daily Leaderboards**: Generates a fun, detailed daily report for Discord at midnight UTC.
    *   **Categories**: "Street Legends" (Playtime), "Speed Demons" (Max Speed), "Cleanest Drivers" (Fewest crashes/hr), and "Wall Hunters" (Most crashes).
*   **Persistence**: Saves all data to `player_stats.json`.

---

## 🔌 Integrations & Services

### Discord Integration
The server interacts with Discord in three ways:
1.  **Event Logging**: `unified_announcer.py` posts joins/leaves to a webhook.
2.  **Daily Stats**: `player_stats.py` posts the daily leaderboard to a webhook.
3.  **Live Overtake Leaderboard**: `_utils/update_discord_overtake_manual.py` runs every minute (via systemd) to update a specific Discord message with the top 15 overtake scores from `Hub.db`.

### Audio Server
A simple HTTP server runs on port **8082** (serving `wwwroot`). This hosts audio files and potentially CSP scripts that clients download to hear custom sound effects triggered by the announcer.

### Systemd Services
Background tasks are managed by Linux systemd:
*   `unified-announcer.service`: Keeps the announcer script running.
*   `discord-leaderboard-updater.timer`: Triggers the overtake leaderboard update every minute.

---

## 🚀 Startup Flow (`start_server.sh`)

When you run `./start_server.sh`:
1.  **Hub Check**: Checks if `AssettoServer.Hub` is running; starts it if not.
2.  **Cleanup**: Kills any old server/stats processes (but leaves the Hub alive).
3.  **Server Start**: Launches `./AssettoServer`.
4.  **Service Check**: Verifies `unified-announcer` is running.
5.  **Stats Start**: Launches `player_stats.py`.
6.  **Audio Start**: Launches the Python HTTP server on port 8082.

## 📂 Key File Locations

*   **Config**: `cfg/server_cfg.ini`, `cfg/extra_cfg.yml` (Traffic presets)
*   **Scripts**: `unified_announcer.py`, `player_stats.py`, `dynamic_traffic.py`
*   **Logs**: `logs/` (Server logs), `stats_tracker.log`, `dynamic_traffic.log`
*   **Data**: `player_stats.json`, `traffic_votes.json`, `hub/Hub.db`
