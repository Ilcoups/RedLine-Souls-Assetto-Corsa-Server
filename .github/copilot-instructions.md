# GitHub Copilot Instructions for RedLine Souls Server

## 📋 Project Context

This is the **RedLine Souls** Assetto Corsa multiplayer server running on Linux.

**CRITICAL**: Always read `CLAUDE.md` first - it contains complete technical documentation for AI assistants.

## 🎯 Quick Reference

### Project Type
- AssettoServer-based multiplayer racing server
- Python Discord integration + statistics tracking
- AI traffic management on Shuto Revival Project (Tokyo expressway)

### Key Files to Know
- `CLAUDE.md` - **READ THIS FIRST** - Complete AI assistant documentation
- `README.md` - User-friendly documentation (don't change without asking)
- `.env` - Credentials (NEVER commit, use `.env.example` as template)
- `cfg/extra_cfg.yml` - AI traffic, weather, plugins configuration
- `unified_announcer.py` - Discord integration (systemd managed)
- `player_stats.py` - Statistics tracking and leaderboards

### Technical Constraints
- **User**: `acserver` (NOT root, no sudo access)
- **Platform**: Linux (Ubuntu/Debian)
- **Python**: Use built-in modules when possible (no easy pip install)
- **Services**: unified-announcer runs via systemd user service

### Critical Rules
1. ❌ NEVER commit `.env` or `cfg/server_cfg.ini` (contain secrets)
2. ✅ ALWAYS use environment variables for credentials
3. ✅ ALWAYS add `?wait=true` to Discord webhook POSTs (for message editing)
4. ✅ ALWAYS restart server after AI traffic config changes
5. ✅ Keep `README.md` user-friendly (technical details go in `CLAUDE.md`)

### Common Tasks

**Modify AI Traffic:**
```bash
# Edit cfg/extra_cfg.yml → AiParams section
./stop_server.sh && ./start_server.sh
```

**Restart Discord Announcer:**
```bash
systemctl --user restart unified-announcer.service
journalctl --user -u unified-announcer.service -f  # view logs
```

**Test Discord Integration:**
```bash
python3 unified_announcer.py --test-join "TestPlayer" "76561199999999999" "ferrari_f40"
```

**Archive Old Logs:**
```bash
./archive_old_logs.sh  # Compresses logs >7 days old
```

### Design Patterns

**Environment Variable Loading:**
```python
# Both Python scripts use custom fallback (no python-dotenv dependency)
env_path = Path('/home/acserver/server/.env')
# Parse: k, v = line.split('=', 1)
```

**Discord Message Editing:**
```python
# Must append ?wait=true to get message ID
webhook_url += '?wait=true'
response = requests.post(webhook_url, json=data)
message_id = response.json().get('id')  # Store for later edit
```

**Log Monitoring:**
```python
# Tail-follow pattern with position tracking
last_position = 0
f.seek(last_position)
new_lines = f.readlines()
last_position = f.tell()
```

### When Suggesting Changes

1. **Check CLAUDE.md first** for context on why things are implemented certain ways
2. **Respect file structure** - Python scripts in root, docs in `_docs/`, utils in `_utils/`
3. **Test locally** - Provide test commands for user to verify changes
4. **Consider systemd** - unified-announcer is managed by systemd, not start_server.sh
5. **Commit hygiene** - Check git status before committing, exclude temp files

### Help Priorities

1. **Understanding codebase** → Point to CLAUDE.md relevant section
2. **AI traffic issues** → Check `cfg/extra_cfg.yml` → `AiParams` section
3. **Discord not working** → Check `.env` variables, webhook `?wait=true`, systemd status
4. **Server not starting** → Check logs, YAML syntax, permissions
5. **Want to add feature** → Follow existing patterns, maintain consistency

### Documentation Strategy

- **README.md** - For humans (simple, friendly, don't over-explain)
- **CLAUDE.md** - For AI assistants (technical deep-dive, design decisions)
- **Code comments** - Why, not what (code shows what)
- **Commit messages** - Descriptive with bullet points for changes

---

**Remember**: This is a hobby project maintained by someone who uses AI assistance. Keep suggestions practical, test commands included, and respect the existing architecture.

For full technical details, architecture, common issues, and best practices → **Read `CLAUDE.md`**
