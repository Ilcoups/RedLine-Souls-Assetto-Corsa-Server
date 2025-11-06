# 🏁 RedLine Souls - Overtake Tracker (Player Installation)

## What is this?

Automatically track your overtakes on the server! The system detects when you pass other players and posts an hourly leaderboard to Discord showing the top overtakers.

**No mods required!** Uses CSP's built-in Lua scripting that you already have.

## Installation (5 minutes)

### Step 1: Download the Script

Download this file: [`overtake_tracker.lua`](https://github.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server/blob/main/csp_scripts/overtake_tracker.lua)

### Step 2: Install to AC

1. Open File Explorer
2. Navigate to: `Documents\Assetto Corsa\cfg\lua\online\`
   - If `lua` or `online` folders don't exist, create them
3. Copy `overtake_tracker.lua` into the `online` folder

**Full path should be**: `Documents\Assetto Corsa\cfg\lua\online\overtake_tracker.lua`

### Step 3: Restart Assetto Corsa

If AC is running, close and restart it completely.

### Step 4: Join Server & Test

1. Join RedLine Souls server
2. Drive normally and overtake another player (NOT AI traffic)
3. Your overtakes are automatically tracked!

## How to Verify It's Working

### Check AC Console Log

1. After overtaking someone, press `Home` key (opens AC console)
2. Look for messages like:
   ```
   RedLine Souls Overtake Tracker initialized
   Overtook PlayerName @ 123.4 km/h
   ```

### Check Discord

Hourly leaderboards post to the stats channel showing top overtakers.

## Rules

- **Minimum speed**: 80 km/h
- **Only real players**: AI traffic doesn't count
- **Cooldown**: 3 seconds before same car counts again
- **Distance**: Must fully pass (7m ahead)

## Troubleshooting

**"I don't see the script working"**
- Check file path: `Documents\Assetto Corsa\cfg\lua\online\overtake_tracker.lua`
- Make sure CSP is enabled and up to date (0.2.0+)
- Restart AC completely after installing

**"I overtook someone but didn't get credit"**
- Speed must be > 80 km/h
- Must be a real player, not AI traffic
- Check AC console log for confirmation message

**"Where's the leaderboard?"**
- Posts to Discord every hour (on the hour)
- Need at least 1 overtake recorded to appear

## Uninstalling

Delete: `Documents\Assetto Corsa\cfg\lua\online\overtake_tracker.lua`

---

**Questions?** Ask in Discord: https://discord.gg/YJJEGAhf
