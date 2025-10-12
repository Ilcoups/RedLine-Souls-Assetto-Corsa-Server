# RedLine Souls - Assetto Corsa Server 🏎️Steam Linux Runtime 3.0 (sniper)

================================

High-speed AI traffic server on Shuto Revival Project with beautiful weather and dynamic day/night cycles.

This container-based release of the Steam Runtime is used for native

## 🌟 Server FeaturesLinux games, and for Proton 8.0+.



- **Dynamic AI Traffic**: Up to 200 AI cars that scale with player count (12 cars per player)For general information please see

- **Beautiful Weather Only**: Clear skies, few clouds, and scattered clouds - no rain or fog<https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/container-runtime.md>

- **Fast Day/Night Cycles**: 8x time multiplier with frequent golden hoursand

- **Real Tokyo Time**: Authentic Asia/Tokyo timezone with smooth weather transitions<https://gitlab.steamos.cloud/steamrt/steamrt/-/blob/steamrt/sniper/README.md>

- **WeatherFX**: CSP-powered smooth weather and lighting transitions

- **Free Roam**: 24-hour practice sessions with loop mode - join anytime!Release notes

-------------

## 📋 Server Configuration

Please see

### Track & Location<https://gitlab.steamos.cloud/steamrt/steamrt/-/wikis/Sniper-release-notes>

- **Track**: Shuto Revival Project Beta

- **Spawn Point**: Heiwajima PA (North Pit)Known issues

- **Time Zone**: Asia/Tokyo------------

- **Session**: 24-hour practice (loops automatically)

Please see

### AI Traffic Settings<https://github.com/ValveSoftware/steam-runtime/blob/master/doc/steamlinuxruntime-known-issues.md>

- **Max AI Cars**: 200 total

- **Per Player**: 12 AI carsReporting bugs

- **Traffic Speed**: 80-144 km/h (faster in right lanes)--------------

- **Lane Behavior**: Smart obstacle detection, ignores parked cars

- **Spawn Distance**: 150m from playerPlease see

<https://github.com/ValveSoftware/steam-runtime/blob/master/doc/reporting-steamlinuxruntime-bugs.md>

### Weather System

- **Plugin**: RandomWeatherPlugin (automatic cycling)Development and debugging

- **Duration**: 30-60 minutes per weather type-------------------------

- **Weather Types**:

  - Clear (22°C ambient)The runtime's behaviour can be changed by running the Steam client with

  - Few Clouds (24°C ambient)environment variables set.

  - Scattered Clouds (26°C ambient)

- **No Rain/Fog**: Perfect conditions guaranteed!`STEAM_LINUX_RUNTIME_LOG=1` will enable logging. Log files appear in

`SteamLinuxRuntime_sniper/var/slr-*.log`, with filenames containing the app ID.

### Time Settings`slr-latest.log` is a symbolic link to whichever one was created most

- **Time Multiplier**: 8x speedrecently.

- **Start Time**: 14:00 (2 PM)

- **Day/Night Cycle**: ~3 hours real-time`STEAM_LINUX_RUNTIME_VERBOSE=1` produces more detailed log output,

- **Golden Hour**: Every ~1.5 hourseither to a log file (if `STEAM_LINUX_RUNTIME_LOG=1` is also used) or to

the same place as `steam` output (otherwise).

## 🚀 Quick Start

`PRESSURE_VESSEL_SHELL=instead` runs an interactive shell in the

### Prerequisitescontainer instead of running the game.

- AssettoServer 0.0.54+ ([Download](https://assettoserver.org/))

- Shuto Revival Project Beta trackPlease see

- .NET 8.0 SDK (for development/plugins)<https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/distro-assumptions.md>

- Content Manager (recommended for clients)for details of assumptions made about the host operating system, and some

- CSP 0.1.76+ (for WeatherFX)advice on debugging the container runtime on new Linux distributions.



### InstallationGame developers who are interested in targeting this environment should

check the SDK documentation <https://gitlab.steamos.cloud/steamrt/sniper/sdk>

1. **Clone this repository**:and general information for game developers

   ```bash<https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/slr-for-game-developers.md>.

   git clone https://github.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server.git

   cd RedLine-Souls-Assetto-Corsa-ServerLicensing and copyright

   ```-----------------------



2. **Install AssettoServer**:The Steam Runtime contains many third-party software packages under

   - Download from [assettoserver.org](https://assettoserver.org/)various open-source licenses.

   - Extract to server directory

   - Install required content (SRP track, cars)For full source code, please see the version-numbered subdirectory of

<https://repo.steampowered.com/steamrt-images-sniper/snapshots/>

3. **Configure Credentials**:corresponding to the version numbers listed in VERSIONS.txt.

   ```bash
   # Create admin password in cfg/server_cfg.ini
   # Edit cfg/extra_cfg.yml with your Discord link if desired
   ```

4. **Start the Server**:
   ```bash
   chmod +x *.sh
   ./start_server.sh
   ```

## 🛠️ Management Scripts

### `start_server.sh`
Starts the server in background with logging
```bash
./start_server.sh
```

### `stop_server.sh`
Gracefully stops the running server
```bash
./stop_server.sh
```

### `server_status.sh`
Check if server is running and view recent logs
```bash
./server_status.sh
```

### `view_logs.sh`
Tail live server logs
```bash
./view_logs.sh
```

## 📁 Important Files

### Configuration Files
- `cfg/server_cfg.ini` - Core server settings (sessions, weather, track)
- `cfg/extra_cfg.yml` - AssettoServer advanced config (AI traffic, plugins)
- `cfg/entry_list.ini` - Player slots (53 max clients)
- `cfg/data_track_params.ini` - Track timezone and coordinates

### Management
- `admins.txt` - Server admin Steam IDs (create manually)
- `blacklist.txt` - Banned players (create manually)
- `whitelist.txt` - Whitelist mode (optional)

## 🎮 Client Requirements

### Minimum
- Assetto Corsa + Content Manager
- Custom Shaders Patch 0.1.76+
- Shuto Revival Project Beta track
- Cars listed in server (Ferrari, BMW, Alfa Romeo, etc.)

### Recommended
- CSP 0.1.80+ for best WeatherFX
- Sol weather mod (optional, not required)
- Traffic-capable system (12 AI cars per player)

## ⚙️ Customization

### Adjust Traffic Density
Edit `cfg/extra_cfg.yml`:
```yaml
AiParams:
  AiPerPlayerTargetCount: 12  # Cars per player
  MaxAiTargetCount: 200       # Total AI limit
```

### Change Weather Duration
Edit `cfg/extra_cfg.yml`:
```yaml
RandomWeatherPlugin:
  MinWeatherDurationMinutes: 30
  MaxWeatherDurationMinutes: 60
```

### Modify Time Speed
Edit `cfg/server_cfg.ini`:
```ini
TIME_MULT=8  # 1x = real-time, 8x = fast day/night
```

## 🔧 Troubleshooting

### AI Traffic Not Spawning
- Check `MaxPlayerDistanceToAiSplineMeters` is set to 150+ in `extra_cfg.yml`
- Ensure players are near the track spline (not far off-road)

### Weather Not Changing
- Verify RandomWeatherPlugin is listed in `EnablePlugins` section
- Check logs for "Random weather transitioning to..." messages
- Ensure WeatherFX is enabled

### Server Won't Start
- Check `logs/server_console.log` for errors
- Verify YAML syntax in `extra_cfg.yml` (indentation matters!)
- Ensure all required content is installed

## 📚 Documentation

- [Server Management Guide](SERVER_MANAGEMENT.md)
- [Automatic Weather System](AUTOMATIC_WEATHER_WORKING.md)
- [Beautiful Weather Configuration](BEAUTIFUL_WEATHER_GUIDE.md)

## 🤝 Contributing

This is my personal server configuration shared with the community! Feel free to:
- Fork this repository
- Adapt settings for your own server
- Submit improvements via pull requests
- Share your experiences in issues/discussions

## 📝 License

Server configuration files are provided as-is for community use. AssettoServer and Assetto Corsa are subject to their respective licenses.

## 🔗 Links

- [AssettoServer Documentation](https://assettoserver.org/)
- [Shuto Revival Project](https://discord.gg/shutokorevivalproject)
- [Community Discord](https://discord.gg/YJJEGAhf)

## 🙏 Credits

- **AssettoServer** - By compujuckel and contributors
- **Shuto Revival Project** - Track by SRP Team
- **Random Weather Plugin** - Official AssettoServer plugin
- Server configuration and setup by the community

---

**Note**: This repository contains only configuration files. You need to download AssettoServer, track content, and car mods separately.

Enjoy the drive! 🏁
