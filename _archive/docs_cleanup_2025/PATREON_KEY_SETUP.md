# 🔑 Patreon Plugin License Key Setup

## ⚠️ Issue Detected

The PatreonOvertakePlugin requires a license key to work.

**Error from logs:**
```
No Patreon Key found. Visit https://patreon.assettoserver.org to get your key
```

## 📝 How to Get Your Key

### Step 1: Get Your License Key

1. Visit: **https://patreon.assettoserver.org**
2. Log in with your Patreon account
3. Your license key will be displayed on the page
4. Copy the key (it looks like a long string of characters)

### Step 2: Add Key to Server

The key needs to be added to the server configuration. There are two methods:

#### Method A: Configuration File (Recommended)

Create or edit the file `.patreon` in your server directory:

```bash
cd ~/server
nano .patreon
```

Paste your key and save (Ctrl+X, Y, Enter)

#### Method B: Environment Variable

Add to your `.env` file:

```bash
echo 'PATREON_KEY="your-license-key-here"' >> .env
```

### Step 3: Restart Server

```bash
./stop_server.sh
./start_server.sh
```

### Step 4: Verify Plugin Loaded

Check logs for successful loading:

```bash
tail -f logs/log-$(date +%Y%m%d).txt | grep -i "patreon\|overtake"
```

You should see:
```
[INF] Loaded plugin PatreonOvertakePlugin
```

## 📋 Current Plugin Status

**Installed Patreon Plugins:**
- ✅ PatreonOvertakePlugin (overtake tracking & leaderboards)
- ✅ PatreonRaceChallengePlugin (race challenges)
- ✅ PatreonSafetyRatingPlugin (safety rating system)
- ✅ PatreonSpeedTrapPlugin (speed traps)
- ✅ PatreonTimingPlugin (timing systems)
- ✅ PatreonAnalyticsPlugin (server analytics)
- ✅ PatreonChatRolesPlugin (chat roles)
- ✅ PatreonReservedSlotsPlugin (VIP slots)
- ✅ PatreonHubPlugin (management hub)
- ✅ PatreonTwitchChatPlugin (Twitch integration)

**Enabled in extra_cfg.yml:**
- ✅ PatreonOvertakePlugin

**Configuration Created:**
- ✅ cfg/plugin_patreon_overtake_cfg.yml
- ✅ Discord webhook: DISCORD_STATS_WEBHOOK
- ✅ Daily summaries: 23:59
- ✅ Weekly summaries: Sunday 23:59

## 🎯 Next Steps

1. **Get your Patreon key** from https://patreon.assettoserver.org
2. **Add key** to `.patreon` file or `.env`
3. **Restart server**
4. **Test overtakes** in-game
5. **Check Discord** for leaderboard posts

## ⚙️ Configuration Options

Current settings in `cfg/plugin_patreon_overtake_cfg.yml`:
- Minimum speed: 50 km/h
- Proximity time: 3 seconds
- Top players shown: 10
- Daily summary: Enabled (23:59)
- Weekly summary: Enabled (Sunday 23:59)
- Clean/Risky overtakes: Tracked
- CSP popups: Enabled

Edit the config file to customize these settings!

## 🔍 Troubleshooting

### "No Patreon Key found"
- Make sure key is in `.patreon` file or `.env`
- Key should be on first line, no quotes needed in `.patreon`
- Server needs internet access to verify key

### "Patreon Key invalid"
- Check if your subscription is still active
- Try regenerating key on patreon.assettoserver.org
- Contact Patreon support if issue persists

### Plugin not loading
- Check `EnablePlugins` in extra_cfg.yml includes `PatreonOvertakePlugin`
- Verify files exist in `plugins/PatreonOvertakePlugin/`
- Check logs for specific error messages

---

**Need the key?** → https://patreon.assettoserver.org
