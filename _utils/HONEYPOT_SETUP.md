# 🍯 Honeypot Detection System - Setup Guide

## What is the Honeypot?

A honeypot is a **fake Discord webhook** that we intentionally "leak" in archived docs. 

If the attacker tries to use it, we'll know they're actively trying to exploit your server!

---

## Current Status

**Honeypot Type**: Fake webhook in documentation  
**Detection Method**: Check Discord channel for unauthorized messages  
**Effectiveness**: ⚠️ Medium (attacker must try to use it)

---

## How to Set Up REAL Honeypot (Recommended)

### Step 1: Create Private Discord Channel

1. In your Discord server, create a new channel
2. Name it something like `#honeypot-security` or `#alerts`
3. **Make it private** - only you can see it
4. This is where we'll catch the attacker!

### Step 2: Create Webhook

1. In that private channel: Settings → Integrations → Webhooks
2. Click "New Webhook"
3. Name it: `Security Honeypot` or similar
4. Copy the webhook URL

### Step 3: Add to .env

Add this line to your `/home/acserver/server/.env`:

```bash
HONEYPOT_WEBHOOK="https://discord.com/api/webhooks/YOUR_HONEYPOT_WEBHOOK_URL_HERE"
```

### Step 4: Plant the Bait

Update `/home/acserver/server/_archive/docs_cleanup_2025/OLD_WEBHOOK_BACKUP.md`:

Replace the fake webhook with your REAL honeypot webhook URL:

```markdown
## Speed Trap Webhook (OLD - Deactivated)
https://discord.com/api/webhooks/YOUR_REAL_HONEYPOT_URL_HERE
```

**This makes it look like an old "backup" that the attacker might try to use!**

### Step 5: Monitor

Run daily:
```bash
cd /home/acserver/server
python3 _utils/monitor_honeypot.py
```

Or check your private Discord channel - if ANY message appears there, the attacker tried to use the leaked webhook!

---

## Current Fake Honeypot

**Location**: `_archive/docs_cleanup_2025/OLD_WEBHOOK_BACKUP.md`  
**Fake Webhook**: `https://discord.com/api/webhooks/FAKE_1111111111111111/FAKE_aaa...`

**Status**: 
- ✅ Won't detect if attacker tries to POST to it (webhook doesn't exist)
- ❌ Only returns 400/404 errors (not useful for detection)

**Recommendation**: Replace with REAL honeypot webhook (see above)

---

## How It Works

1. **Attacker finds** "old backup" in your GitHub repo
2. **Attacker tries** to post message using the webhook
3. **Message appears** in your private Discord channel
4. **You get alerted** that attacker is active!

---

## Security Notes

✅ **Safe**: The honeypot webhook posts to YOUR private channel only
✅ **Secure**: Only you can see the honeypot channel  
✅ **Isolated**: Honeypot doesn't affect any real systems
✅ **Effective**: Catches attacker red-handed!

❌ **Don't use** a webhook that posts to public channels
❌ **Don't share** the honeypot channel with anyone

---

## Alternative: File-Based Honeypot

If you don't want to create a Discord webhook, you can detect file access instead:

```python
# Create a "canary" file with fake credentials
echo "API_KEY=fake_key_12345" > /tmp/canary_credentials.txt

# Monitor if it's accessed
stat /tmp/canary_credentials.txt
```

But this only works if attacker has server access (which they don't).

---

## Summary

**Current Setup**: Fake webhook (limited detection)  
**Recommended**: Real honeypot webhook in private channel  
**Effort**: 5 minutes to set up  
**Benefit**: Know immediately if attacker is active

Want me to help you set up a real honeypot? Just create the webhook and give me the URL!
