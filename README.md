# RedLine Souls - Assetto Corsa Server 🏎️

High-speed AI traffic server on Shuto Revival Project with beautiful weather and dynamic day/night cycles.

## 🌟 Server Features

- **Dynamic AI Traffic**: Up to 200 AI cars that scale with player count (12 cars per player).
- **Beautiful Weather Only**: Clear skies, few clouds, and scattered clouds - no rain or fog.
- **Fast Day/Night Cycles**: 8x time multiplier with frequent golden hours.
- **Real Tokyo Time**: Authentic Asia/Tokyo timezone with smooth weather transitions.
- **WeatherFX**: CSP-powered smooth weather and lighting transitions.
- **Free Roam**: 24-hour practice sessions with loop mode - join anytime!

## 📋 Server Configuration

### Track & Location

- **Track**: Shuto Revival Project Beta.
- **Spawn Point**: Heiwajima PA (North Pit).
- **Time Zone**: Asia/Tokyo.
- **Session**: 24-hour practice (loops automatically).

### AI Traffic Settings

- **Max AI Cars**: 200 total.
- **Per Player**: 12 AI cars.
- **Traffic Speed**: 80-144 km/h (faster in right lanes).
- **Lane Behavior**: Smart obstacle detection, ignores parked cars.
- **Spawn Distance**: 150m from player.

### Weather System

- **Plugin**: RandomWeatherPlugin (automatic cycling).
- **Duration**: 30-60 minutes per weather type.
- **Weather Types**:
  - Clear (22°C ambient).
  - Few Clouds (24°C ambient).
  - Scattered Clouds (26°C ambient).
- **No Rain/Fog**: Perfect conditions guaranteed!

### Time Settings

- **Time Multiplier**: 8x speed.
- **Start Time**: 14:00 (2 PM).
- **Day/Night Cycle**: ~3 hours real-time.
- **Golden Hour**: Every ~1.5 hours.

## 🚀 Quick Start

### Prerequisites

- AssettoServer 0.0.54+ ([Download](https://assettoserver.org/)).
- Shuto Revival Project Beta track.
- .NET 8.0 SDK (for development/plugins).
- Content Manager (recommended for clients).
- CSP 0.1.76+ (for WeatherFX).

### Installation

1. **Clone this repository**:

    ```bash
    git clone https://github.com/Ilcoups/RedLine-Souls-Assetto-Corsa-Server.git
    cd RedLine-Souls-Assetto-Corsa-Server
    ```

2. **Install AssettoServer**:
    - Download from [assettoserver.org](https://assettoserver.org/).
    - Extract to server directory.
    - Install required content (SRP track, cars).

3. **Configure Credentials**:

    ```bash
    # Copy the template and set your admin password
    cp cfg/server_cfg.ini.template cfg/server_cfg.ini
    # Edit ADMIN_PASSWORD in cfg/server_cfg.ini
    # Optionally edit cfg/extra_cfg.yml with your Discord link
    ```

4. **Start the Server**:

    ```bash
    chmod +x *.sh
    ./start_server.sh
    ```

## 🛠️ Management Scripts

- **`start_server.sh`**: Starts the server in background with logging.
- **`stop_server.sh`**: Gracefully stops the running server.
- **`server_status.sh`**: Check if server is running and view recent logs.
- **`view_logs.sh`**: Tail live server logs.

## 📁 Important Files

### Configuration Files

- `cfg/server_cfg.ini.template` - Template for core server settings (copy to server_cfg.ini).
- `cfg/extra_cfg.yml` - AssettoServer advanced config (AI traffic, plugins).
- `cfg/entry_list.ini` - Player slots (53 max clients).
- `cfg/data_track_params.ini` - Track timezone and coordinates.
- `admins.txt` - Server admin Steam IDs (create manually).
- `blacklist.txt` - Banned players (create manually).
- `whitelist.txt` - Whitelist mode (optional).

## 🎮 Client Requirements

### Minimum

- Assetto Corsa + Content Manager.
- Custom Shaders Patch 0.1.76+.
- Shuto Revival Project Beta track.
- Cars listed in server (Ferrari, BMW, Alfa Romeo, etc.).

### Recommended

- CSP 0.1.80+ for best WeatherFX.
- Sol weather mod (optional, not required).
- Traffic-capable system (12 AI cars per player).

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

- Check `MaxPlayerDistanceToAiSplineMeters` is set to 150+ in `extra_cfg.yml`.
- Ensure players are near the track spline (not far off-road).

### Weather Not Changing

- Verify RandomWeatherPlugin is listed in `EnablePlugins` section.
- Check logs for "Random weather transitioning to..." messages.
- Ensure WeatherFX is enabled.

### Server Won't Start

- Check `logs/server_console.log` for errors.
- Verify YAML syntax in `extra_cfg.yml` (indentation matters!).
- Ensure all required content is installed.

## 📚 Documentation

- [Server Management Guide](SERVER_MANAGEMENT.md).
- [Automatic Weather System](AUTOMATIC_WEATHER_WORKING.md).
- [Beautiful Weather Configuration](BEAUTIFUL_WEATHER_GUIDE.md).

## 🤝 Contributing

This is my personal server configuration shared with the community! Feel free to:
- Fork this repository.
- Adapt settings for your own server.
- Submit improvements via pull requests.
- Share your experiences in issues/discussions.

## 📝 License

Server configuration files are provided as-is for community use. AssettoServer and Assetto Corsa are subject to their respective licenses.

## 🔗 Links

- [AssettoServer Documentation](https://assettoserver.org/).
- [Shuto Revival Project](https://discord.gg/shutokorevivalproject).
- [Community Discord](https://discord.gg/YJJEGAhf).

## 🙏 Credits

- **AssettoServer** - By compujuckel and contributors.
- **Shuto Revival Project** - Track by SRP Team.
- **Random Weather Plugin** - Official AssettoServer plugin.
- Server configuration and setup by the community.

---

**Note**: This repository contains only configuration files. You need to download AssettoServer, track content, and car mods separately.

Enjoy the drive! 🏁

---

<sub>Special thanks to @gaulven for the late-night debugging sessions and helping bring this project to life. Your patience and expertise made all the difference. 🙏</sub>.
