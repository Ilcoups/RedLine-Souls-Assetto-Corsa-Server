# 🍯 Advanced Honeypot System - Setup Complete!

## What I Created

A **smart honeypot webhook server** that:
- ✅ Pretends to be a real Discord webhook
- ✅ Captures attacker IP, user agent, location, etc.
- ✅ Logs everything privately for you
- ✅ Posts FUNNY sanitized alerts to your Discord (no private data exposed)
- ✅ Looks real so attacker doesn't know they're caught!

---

## How It Works

### 1. Attacker Tries to Use "Leaked" Webhook

They find the fake webhook in your GitHub repo and try to post a message.

### 2. Honeypot Captures Everything

**Privately logged** (only you can see):
- IP address
- Country/region (approximate location)
- User agent (what software they're using)
- Full request headers
- What message they tried to send
- Timestamp

**Saved to**: `/home/acserver/server/logs/honeypot_data.json`

### 3. Funny Message Posted to Discord

**Public announcement** (sanitized, NO IP or sensitive data):
```
🍯 Security Honeypot Triggered!
Someone just tried to use an old deactivated webhook. Nice try, script kiddie! 😂

🌍 Approximate Location: Germany
🕒 Time: 14:32:15 UTC
📊 Total Attempts: 1
```

### 4. You Have Evidence

If needed, you have full logs with IP addresses stored privately.

---

## Setup Instructions

### Step 1: Get Your Server IP

Run this to get your public IP:
```bash
curl ifconfig.me
```

### Step 2: Update OLD_WEBHOOK_BACKUP.md

Replace the fake webhook with your honeypot server URL.

**File**: `_archive/docs_cleanup_2025/OLD_WEBHOOK_BACKUP.md`

**Change line 7** from:
```
https://discord.com/api/webhooks/FAKE_1111111111111111/FAKE_aaaa...
```

**To**:
```
http://YOUR_SERVER_IP:8084/webhooks/YOUR_FAKE_WEBHOOK_ID/YOUR_FAKE_WEBHOOK_TOKEN
```

**Important**: Use the REAL old leaked webhook ID/token so it looks authentic!

### Step 3: Verify Honeypot is Running

```bash
ps aux | grep honeypot_webhook_server
netstat -tlnp | grep 8084
```

Should show honeypot listening on port 8084.

### Step 4: Test It! (Optional)

Test the honeypot yourself:
```bash
curl -X POST http://YOUR_SERVER_IP:8084/webhooks/test/test \
  -H "Content-Type: application/json" \
  -d '{"content":"Test message"}'
```

You should see:
1. Log entry in `logs/honeypot_catches.log`
2. Funny message in your Discord channel
3. Data saved to `logs/honeypot_data.json`

---

## Example Captured Data

**Private log** (`honeypot_data.json`):
```json
{
  "timestamp": "2025-11-25T08:15:32.123456",
  "ip": "123.456.789.012",
  "location": "Germany (Bavaria)",
  "user_agent": "python-requests/2.28.0",
  "attempt_number": 1,
  "body": "{\"content\":\"hacked!\"}",
  "parsed_body": {
    "content": "hacked!"
  }
}
```

**Public Discord alert** (sanitized):
```
🍯 Security Honeypot Triggered!
🎣 Got 'Em! Hook, line, and sinker! Someone took the bait. Our honeypot works! 🐝

🌍 Approximate Location: Germany
🕒 Time: 08:15:32 UTC
📊 Total Attempts: 1
```

---

## Funny Messages

The system randomly chooses from 8 funny messages:
- "Nice try, script kiddie! 😂"
- "Better luck next time! 🎭"
- "Hook, line, and sinker! 🐝"
- "Amateur hour! 🕵️"
- "Thanks for testing our security! 🍰"
- And more!

---

## Security & Privacy

✅ **Legal**: Honeypots are legal security measures  
✅ **Privacy**: Only YOU can see the IP addresses (stored locally)  
✅ **Public**: Only generalized location posted to Discord  
✅ **Evidence**: Full logs if you need them  
✅ **Deceptive**: Pretends to be real webhook so attacker doesn't know

---

## Monitoring

**View catches**:
```bash
# See all attempts
cat /home/acserver/server/logs/honeypot_data.json | jq

# See log
tail -f /home/acserver/server/logs/honeypot_catches.log

# Count attempts
cat /home/acserver/server/logs/honeypot_data.json | jq 'length'
```

**Check if running**:
```bash
ps aux | grep honeypot_webhook_server
```

**Restart if needed**:
```bash
pkill -f honeypot_webhook_server
nohup python3 -u honeypot_webhook_server.py > logs/honeypot_server.log 2>&1 &
```

---

## What You Need to Do

1. Get your server's public IP
2. Update `OLD_WEBHOOK_BACKUP.md` with: `http://YOUR_IP:8084/webhooks/[OLD_LEAKED_ID]/[OLD_LEAKED_TOKEN]`
3. Wait for attacker to try it!

That's it! The honeypot is ready to catch them! 🍯
