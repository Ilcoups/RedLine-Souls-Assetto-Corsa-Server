# Installing AssettoServer Patreon Plugins

## Step 1: Download on Your Local Machine

1. Go to Patreon post with the plugin downloads
2. Click on: **assetto-server-patreon-v0.0.39-linux-x64.zip**
3. Save to your computer

## Step 2: Upload to Server

Choose one method:

### Method A: Using VS Code (Recommended)

1. In VS Code, open the Explorer panel (left sidebar)
2. Right-click on `/home/acserver/server/` folder
3. Select "Upload..."
4. Choose the downloaded `.zip` file
5. Wait for upload to complete

### Method B: Using SCP (Command Line)

From your **local machine** terminal:

```bash
scp /path/to/assetto-server-patreon-v0.0.39-linux-x64.zip acserver@YOUR_SERVER_IP:~/server/
```

### Method C: Direct Download on Server (if you have the direct link)

```bash
cd ~/server
wget "PATREON_DIRECT_DOWNLOAD_URL" -O patreon-plugins.zip
```

## Step 3: Extract on Server

Once uploaded, run in VS Code terminal:

```bash
cd ~/server
unzip assetto-server-patreon-v0.0.39-linux-x64.zip
```

## Step 4: Install Plugins

The zip should contain a `plugins/` folder. Copy to your server:

```bash
# Check what's in the zip
unzip -l assetto-server-patreon-v0.0.39-linux-x64.zip

# Extract (this will place files in correct locations)
unzip -o assetto-server-patreon-v0.0.39-linux-x64.zip
```

## Step 5: Enable Plugins

Edit `cfg/extra_cfg.yml` and add to `EnablePlugins` section:

```yaml
EnablePlugins:
- RandomWeatherPlugin
- PatreonOvertakeLeaderboardPlugin  # Add this
- PatreonRaceChallengePlugin        # Optional
- PatreonClientSecurityPlugin       # Optional
```

## Step 6: Configure Plugin

Create plugin config if needed (check `plugins/` folder for examples).

## Step 7: Restart Server

```bash
./stop_server.sh
./start_server.sh
```

## Step 8: Verify

Check logs for plugin loading:

```bash
tail -f logs/log-$(date +%Y%m%d).txt | grep -i "patreon\|overtake"
```

---

## Troubleshooting

### "Plugin not found" Error
- Make sure files are in `plugins/` folder
- Check file permissions: `ls -la plugins/`
- Files should be executable: `chmod +x plugins/*.dll`

### License/Key Issues
- Patreon plugins require internet connection for license verification
- Check logs for "Patreon Key status" messages
- Contact plugin developer if key issues persist

### Wrong Architecture Downloaded
- Check your system: `uname -m`
  - `x86_64` = use x64 version
  - `aarch64` = use arm64 version

---

## What Plugins Are Included?

- **PatreonOvertakeLeaderboardPlugin** - Track overtakes, display leaderboards
- **PatreonRaceChallengePlugin** - Race challenges with health bars
- **PatreonClientSecurityPlugin** - Enhanced anti-cheat
- **PatreonHub** - Management interface (separate download)

---

**Need help?** Check the logs or ask in AssettoServer Discord/Patreon posts!
