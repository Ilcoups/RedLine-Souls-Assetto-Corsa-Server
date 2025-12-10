# Credentials Setup

When returning to this project, replace these placeholders with your actual credentials:

## Files to Update

### 1. `presets/SERVER_00/server_cfg.ini`
```ini
ADMIN_PASSWORD=YOUR_ADMIN_PASSWORD_HERE
```

### 2. `hub/configuration.yml`
```yaml
DiscordBotToken: YOUR_DISCORD_BOT_TOKEN_HERE
Keys:
- Key: YOUR_HUB_KEY_HERE
```

### 3. `cfg/extra_cfg.yml`
```yaml
Key: YOUR_HUB_KEY_HERE
```

### 4. `cfg/plugin_discord_audit_cfg.yml`
```yaml
AuditUrl: https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
```

### 5. `speed_trap_proxy.conf.old_leaked`
```
REAL_DISCORD_WEBHOOK=https://discord.com/api/webhooks/YOUR_WEBHOOK_ID/YOUR_WEBHOOK_TOKEN
```

### 6. `_utils/update_discord_overtake_manual.py`
```python
CHANNEL_ID = "YOUR_DISCORD_CHANNEL_ID"
MESSAGE_ID = "YOUR_DISCORD_MESSAGE_ID"
```

### 7. `_utils/recover_discord_data.py`
```python
CHANNEL_ID = "YOUR_DISCORD_CHANNEL_ID"
BOT_TOKEN = "YOUR_DISCORD_BOT_TOKEN"
```

### 8. `_utils/speed_trap_msg.json`
```json
{"id": "YOUR_DISCORD_MESSAGE_ID", "timestamp": ""}
```

## Generate New Hub Key

Run this to generate a new hub key:
```bash
openssl rand -base64 32
```

Use the same key in both `hub/configuration.yml` and `cfg/extra_cfg.yml`.
