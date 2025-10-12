# RedLine Souls - Assetto Corsa Server 🏎️# RedLine Souls - Assetto Corsa Server 🏎️Steam Linux Runtime 3.0 (sniper)



High-speed AI traffic server on Shuto Revival Project with beautiful weather and dynamic day/night cycles.================================



## 🌟 Server FeaturesHigh-speed AI traffic server on Shuto Revival Project with beautiful weather and dynamic day/night cycles.



- **Dynamic AI Traffic**: Up to 200 AI cars that scale with player count (12 cars per player)This container-based release of the Steam Runtime is used for native

- **Beautiful Weather Only**: Clear skies, few clouds, and scattered clouds - no rain or fog

- **Fast Day/Night Cycles**: 8x time multiplier with frequent golden hours## 🌟 Server FeaturesLinux games, and for Proton 8.0+.

- **Real Tokyo Time**: Authentic Asia/Tokyo timezone with smooth weather transitions

- **WeatherFX**: CSP-powered smooth weather and lighting transitions

- **Free Roam**: 24-hour practice sessions with loop mode - join anytime!

- **Dynamic AI Traffic**: Up to 200 AI cars that scale with player count (12 cars per player)For general information please see

## 📋 Server Configuration

- **Beautiful Weather Only**: Clear skies, few clouds, and scattered clouds - no rain or fog<https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/container-runtime.md>

### Track & Location

- **Track**: Shuto Revival Project Beta- **Fast Day/Night Cycles**: 8x time multiplier with frequent golden hoursand

- **Spawn Point**: Heiwajima PA (North Pit)

- **Time Zone**: Asia/Tokyo- **Real Tokyo Time**: Authentic Asia/Tokyo timezone with smooth weather transitions<https://gitlab.steamos.cloud/steamrt/steamrt/-/blob/steamrt/sniper/README.md>

- **Session**: 24-hour practice (loops automatically)

- **WeatherFX**: CSP-powered smooth weather and lighting transitions

### AI Traffic Settings

- **Max AI Cars**: 200 total- **Free Roam**: 24-hour practice sessions with loop mode - join anytime!Release notes

- **Per Player**: 12 AI cars

- **Traffic Speed**: 80-144 km/h (faster in right lanes)-------------

- **Lane Behavior**: Smart obstacle detection, ignores parked cars

- **Spawn Distance**: 150m from player## 📋 Server Configuration



### Weather SystemPlease see

- **Plugin**: RandomWeatherPlugin (automatic cycling)

- **Duration**: 30-60 minutes per weather type### Track & Location<https://gitlab.steamos.cloud/steamrt/steamrt/-/wikis/Sniper-release-notes>

- **Weather Types**:

  - Clear (22°C ambient)- **Track**: Shuto Revival Project Beta

  - Few Clouds (24°C ambient)

  - Scattered Clouds (26°C ambient)- **Spawn Point**: Heiwajima PA (North Pit)Known issues

- **No Rain/Fog**: Perfect conditions guaranteed!

- **Time Zone**: Asia/Tokyo------------

### Time Settings

- **Time Multiplier**: 8x speed- **Session**: 24-hour practice (loops automatically)

- **Start Time**: 14:00 (2 PM)

- **Day/Night Cycle**: ~3 hours real-timePlease see

- **Golden Hour**: Every ~1.5 hours

### AI Traffic Settings<https://github.com/ValveSoftware/steam-runtime/blob/master/doc/steamlinuxruntime-known-issues.md>

## 🚀 Quick Start

- **Max AI Cars**: 200 total

### Prerequisites

- AssettoServer 0.0.54+ ([Download](https://assettoserver.org/))- **Per Player**: 12 AI carsReporting bugs

- Shuto Revival Project Beta track

- .NET 8.0 SDK (for development/plugins)- **Traffic Speed**: 80-144 km/h (faster in right lanes)--------------

- Content Manager (recommended for clients)

- CSP 0.1.76+ (for WeatherFX)- **Lane Behavior**: Smart obstacle detection, ignores parked cars



### Installation- **Spawn Distance**: 150m from playerPlease see



1. **Clone this repository**:<https://github.com/ValveSoftware/steam-runtime/blob/master/doc/reporting-steamlinuxruntime-bugs.md>

   ```bash

   git clone https://github.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server.git### Weather System

   cd RedLine-Souls-Assetto-Corsa-Server

   ```- **Plugin**: RandomWeatherPlugin (automatic cycling)Development and debugging



2. **Install AssettoServer**:- **Duration**: 30-60 minutes per weather type-------------------------

   - Download from [assettoserver.org](https://assettoserver.org/)

   - Extract to server directory- **Weather Types**:

   - Install required content (SRP track, cars)

  - Clear (22°C ambient)The runtime's behaviour can be changed by running the Steam client with

3. **Configure Credentials**:

   ```bash  - Few Clouds (24°C ambient)environment variables set.

   # Copy the template and set your admin password

   cp cfg/server_cfg.ini.template cfg/server_cfg.ini  - Scattered Clouds (26°C ambient)

   # Edit ADMIN_PASSWORD in cfg/server_cfg.ini

   # Optionally edit cfg/extra_cfg.yml with your Discord link- **No Rain/Fog**: Perfect conditions guaranteed!`STEAM_LINUX_RUNTIME_LOG=1` will enable logging. Log files appear in

   ```

`SteamLinuxRuntime_sniper/var/slr-*.log`, with filenames containing the app ID.

4. **Start the Server**:

   ```bash### Time Settings`slr-latest.log` is a symbolic link to whichever one was created most

   chmod +x *.sh

   ./start_server.sh- **Time Multiplier**: 8x speedrecently.

   ```

- **Start Time**: 14:00 (2 PM)

## 🛠️ Management Scripts

- **Day/Night Cycle**: ~3 hours real-time`STEAM_LINUX_RUNTIME_VERBOSE=1` produces more detailed log output,

### `start_server.sh`

Starts the server in background with logging- **Golden Hour**: Every ~1.5 hourseither to a log file (if `STEAM_LINUX_RUNTIME_LOG=1` is also used) or to

```bash

./start_server.shthe same place as `steam` output (otherwise).

```

## 🚀 Quick Start

### `stop_server.sh`

Gracefully stops the running server`PRESSURE_VESSEL_SHELL=instead` runs an interactive shell in the

```bash

./stop_server.sh### Prerequisitescontainer instead of running the game.

```

- AssettoServer 0.0.54+ ([Download](https://assettoserver.org/))

### `server_status.sh`

Check if server is running and view recent logs- Shuto Revival Project Beta trackPlease see

```bash

./server_status.sh- .NET 8.0 SDK (for development/plugins)<https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/distro-assumptions.md>

```

- Content Manager (recommended for clients)for details of assumptions made about the host operating system, and some

### `view_logs.sh`

Tail live server logs- CSP 0.1.76+ (for WeatherFX)advice on debugging the container runtime on new Linux distributions.

```bash

./view_logs.sh

```

### InstallationGame developers who are interested in targeting this environment should

## 📁 Important Files

check the SDK documentation <https://gitlab.steamos.cloud/steamrt/sniper/sdk>

### Configuration Files

- `cfg/server_cfg.ini.template` - Template for core server settings (copy to server_cfg.ini)1. **Clone this repository**:and general information for game developers

- `cfg/extra_cfg.yml` - AssettoServer advanced config (AI traffic, plugins)

- `cfg/entry_list.ini` - Player slots (53 max clients)   ```bash<https://gitlab.steamos.cloud/steamrt/steam-runtime-tools/-/blob/main/docs/slr-for-game-developers.md>.

- `cfg/data_track_params.ini` - Track timezone and coordinates

   git clone https://github.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server.git

### Management

- `admins.txt` - Server admin Steam IDs (create manually)   cd RedLine-Souls-Assetto-Corsa-ServerLicensing and copyright

- `blacklist.txt` - Banned players (create manually)

- `whitelist.txt` - Whitelist mode (optional)   ```-----------------------



## 🎮 Client Requirements



### Minimum2. **Install AssettoServer**:The Steam Runtime contains many third-party software packages under

- Assetto Corsa + Content Manager

- Custom Shaders Patch 0.1.76+   - Download from [assettoserver.org](https://assettoserver.org/)various open-source licenses.

- Shuto Revival Project Beta track

- Cars listed in server (Ferrari, BMW, Alfa Romeo, etc.)   - Extract to server directory



### Recommended   - Install required content (SRP track, cars)For full source code, please see the version-numbered subdirectory of

- CSP 0.1.80+ for best WeatherFX

- Sol weather mod (optional, not required)<https://repo.steampowered.com/steamrt-images-sniper/snapshots/>

- Traffic-capable system (12 AI cars per player)

3. **Configure Credentials**:corresponding to the version numbers listed in VERSIONS.txt.

## ⚙️ Customization

   ```bash

### Adjust Traffic Density   # Create admin password in cfg/server_cfg.ini

Edit `cfg/extra_cfg.yml`:   # Edit cfg/extra_cfg.yml with your Discord link if desired

```yaml   ```

AiParams:

  AiPerPlayerTargetCount: 12  # Cars per player4. **Start the Server**:

  MaxAiTargetCount: 200       # Total AI limit   ```bash

```   chmod +x *.sh

   ./start_server.sh

### Change Weather Duration   ```

Edit `cfg/extra_cfg.yml`:

```yaml## 🛠️ Management Scripts

RandomWeatherPlugin:

  MinWeatherDurationMinutes: 30### `start_server.sh`

  MaxWeatherDurationMinutes: 60Starts the server in background with logging

``````bash

./start_server.sh

### Modify Time Speed```

Edit `cfg/server_cfg.ini`:

```ini### `stop_server.sh`

TIME_MULT=8  # 1x = real-time, 8x = fast day/nightGracefully stops the running server

``````bash

./stop_server.sh

## 🔧 Troubleshooting```



### AI Traffic Not Spawning### `server_status.sh`

- Check `MaxPlayerDistanceToAiSplineMeters` is set to 150+ in `extra_cfg.yml`Check if server is running and view recent logs

- Ensure players are near the track spline (not far off-road)```bash

./server_status.sh

### Weather Not Changing```

- Verify RandomWeatherPlugin is listed in `EnablePlugins` section

- Check logs for "Random weather transitioning to..." messages### `view_logs.sh`

- Ensure WeatherFX is enabledTail live server logs

```bash

### Server Won't Start./view_logs.sh

- Check `logs/server_console.log` for errors```

- Verify YAML syntax in `extra_cfg.yml` (indentation matters!)

- Ensure all required content is installed## 📁 Important Files



## 📚 Documentation### Configuration Files

- `cfg/server_cfg.ini` - Core server settings (sessions, weather, track)

- [Server Management Guide](SERVER_MANAGEMENT.md)- `cfg/extra_cfg.yml` - AssettoServer advanced config (AI traffic, plugins)

- [Automatic Weather System](AUTOMATIC_WEATHER_WORKING.md)- `cfg/entry_list.ini` - Player slots (53 max clients)

- [Beautiful Weather Configuration](BEAUTIFUL_WEATHER_GUIDE.md)- `cfg/data_track_params.ini` - Track timezone and coordinates



## 🤝 Contributing### Management

- `admins.txt` - Server admin Steam IDs (create manually)

This is my personal server configuration shared with the community! Feel free to:- `blacklist.txt` - Banned players (create manually)

- Fork this repository- `whitelist.txt` - Whitelist mode (optional)

- Adapt settings for your own server

- Submit improvements via pull requests## 🎮 Client Requirements

- Share your experiences in issues/discussions

### Minimum

## 📝 License- Assetto Corsa + Content Manager

- Custom Shaders Patch 0.1.76+

Server configuration files are provided as-is for community use. AssettoServer and Assetto Corsa are subject to their respective licenses.- Shuto Revival Project Beta track

- Cars listed in server (Ferrari, BMW, Alfa Romeo, etc.)

## 🔗 Links

### Recommended

- [AssettoServer Documentation](https://assettoserver.org/)- CSP 0.1.80+ for best WeatherFX

- [Shuto Revival Project](https://discord.gg/shutokorevivalproject)- Sol weather mod (optional, not required)

- [Community Discord](https://discord.gg/YJJEGAhf)- Traffic-capable system (12 AI cars per player)



## 🙏 Credits## ⚙️ Customization



- **AssettoServer** - By compujuckel and contributors### Adjust Traffic Density

- **Shuto Revival Project** - Track by SRP TeamEdit `cfg/extra_cfg.yml`:

- **Random Weather Plugin** - Official AssettoServer plugin```yaml

- Server configuration and setup by the communityAiParams:

  AiPerPlayerTargetCount: 12  # Cars per player

---  MaxAiTargetCount: 200       # Total AI limit

```

**Note**: This repository contains only configuration files. You need to download AssettoServer, track content, and car mods separately.

### Change Weather Duration

Enjoy the drive! 🏁Edit `cfg/extra_cfg.yml`:

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

---

<sub>Special thanks to @gaulven for the late-night debugging sessions and helping bring this project to life. Your patience and expertise made all the difference. 🙏</sub>
