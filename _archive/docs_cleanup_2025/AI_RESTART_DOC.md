Restart helper and AI restart documentation
=======================================

Purpose
-------
This documents the new single-command restart helper `restart_all.sh` and explains how it avoids duplicate announcer instances, what it does for AI-related config reloads, and how to test after restarting.

Files added / changed
--------------------
- `restart_all.sh` — new helper script that: stops the user `unified-announcer.service` (if running), kills stray announcer/player/server processes, calls `stop_server.sh`, then `start_server.sh`, waits and reports process status.
- `start_server.sh` / `stop_server.sh` — left unchanged; `restart_all.sh` orchestrates them.

Why this helper
----------------
- You frequently requested one command to fully restart the server and helper processes without creating duplicate announcers or leaving zombie processes.
- `restart_all.sh` centralizes the steps you were running manually and prints a short verification summary.

How to use
----------
Run as the same user who owns the server (example user `acserver`):

```bash
cd /home/acserver/server
./restart_all.sh
```

What the helper does (summary)
------------------------------
1. Stops the user systemd unit `unified-announcer.service` to prevent systemd from starting a concurrent announcer while the start script runs.
2. Kills stray processes matching known helpers (announcer, player_stats, AssettoServer, python http.server 8082).
3. Calls `stop_server.sh` and waits briefly.
4. Calls `start_server.sh` to start the AssettoServer binary, announcer, player stats, and starts the audio HTTP server if missing.
5. Prints a short process list and whether the systemd unit is active.

AI-specific notes (why this helps for your AI changes)
---------------------------------------------------
- The server reads `cfg/extra_cfg.yml` on startup (AI settings are applied at server launch). Using `restart_all.sh` guarantees a full process restart so your AI configuration changes (TrafficDensity, AiPerPlayerTargetCount, Min/MaxAiSafetyDistanceMeters, LaneCountSpecificOverrides, etc.) are active.
- Avoid hot-reloading AI configuration unless you know your plugins support it — the safest path is a full restart.
- The helper avoids duplicate announcers which previously caused duplicate Discord messages (multiple announcer processes can post the same join/leave events).

Troubleshooting
---------------
- If you still see duplicate Discord messages:
  - Check for multiple announcer processes: `ps aux | grep unified_announcer.py`.
  - If present, search for systemd-managed unit vs start-script launcher conflict. If you want systemd to manage the announcer instead of the start script, do:

```bash
# Remove/disable announcer launch from start_server.sh (or comment it out)
systemctl --user enable --now unified-announcer.service
```

- If the audio HTTP server is not reachable from clients, verify it's running and reachable on port 8082 and firewall/NAT allows it. From server:

```bash
curl -I http://127.0.0.1:8082/audio/RedLineSoulsIntro.ogg
```

Testing checklist after restart
------------------------------
1. Run `./restart_all.sh`.
2. Confirm single instances:
   - `ps aux | egrep "AssettoServer|unified_announcer|player_stats|http.server"` should show one of each.
3. Join the server with a client that meets the REQUIREMENTS (CSP/CM versions) and verify AI density and behaviour match your `cfg/extra_cfg.yml` edits.
4. Check server logs for AI spawn messages and errors: `tail -f logs/log-$(date +%Y%m%d).txt` and `tail -f logs/server_console.log`.
5. If you changed traffic parameters, run a short play session (5–15 minutes) and watch for collisions/clipping and spawn/despawn logs.

Security note
-------------
- `restart_all.sh` does not commit secrets or change git state. Do not commit `.env` or private webhook URLs.

If you want me to
-----------------
- Move announcer control entirely to systemd (remove announcer launch from `start_server.sh` and enable the user unit).
- Add a `--dry-run` flag to `restart_all.sh` to preview actions without killing processes.
- Add a small `status.sh` that prints the server health and AI population counts (if an admin API exists).

Want me to apply any of those follow-ups? Reply with which one and I’ll implement it.
