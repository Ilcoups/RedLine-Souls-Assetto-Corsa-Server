# 🗺️ Teleport System - RedLine Souls Server

## Overview

The server now has **157 teleport locations** across the entire Shuto Revival Project map! Players can instantly teleport to famous locations, parking areas, toll gates, and key points on all routes.

**Credit**: Teleport coordinates by [Gaulven](https://discord.gaulven.com/) for SRP 0.9.3 (Version 1, Nov 25 2024)

## How to Use Teleports

### In-Game Access

1. **Open Chat** (Default: T key)
2. **Type**: `/teleport` or `/tp`
3. **Browse locations** organized by category
4. **Click** on desired location or type the number

### Quick Access Categories

The teleports are organized into logical groups:

#### 🏁 Popular Spots
- **Shibaura PA** (5 spots) - Famous parking area on C1
- **Tatsumi PA** (4 spots) - Popular meeting point
- **Heiwajima PA** (North 3, South 4) - Large service areas
- **Daishi PA** (3 spots) - Kawasaki area
- **Shibuya Scramble Crossing** (2 spots) - Iconic intersection
- **Shibuya Station Taxi Stand** (4 spots)
- **Shinjuku Station Taxi Stand** (2 spots)
- **Dogenzaka Parking Lot** (3 spots) - Shibuya mountain area

#### 🔵 C1 Inner Loop (Clockwise)
- Daikancho Toll Gate (2 spots)
- Kandabashi Junction (2 spots)
- Nihonbashi (2 spots)
- Hakozaki
- Shinba Bridge (2 spots)
- Mannen Bridge (2 spots)
- Hamarikyu
- Kasumigaseki Tunnel (2 spots)
- Near Shibaura PA (2 spots)
- Roppongi (2 spots)

#### 🔴 C1 Outer Loop (Counter-clockwise)
- All same locations as Inner, opposite direction
- Perfect for battles and time attacks

#### 🛣️ Major Routes

**Route 11** - Daiba
- East/West Toll Gates

**Route 3** - Shibuya Connection
- East/West Takagicho Toll Gates
- C1 Onramp

**Route 4** - Shinjuku/Yoyogi
- East/West at C1
- Yoyogi PA
- Gaien Exit

**Route 6** - Hakozaki Junction

**Route 9** - Kiba/Shiomi
- North/South Kiba Toll Gates (4 spots)
- Shiomi (2 spots)
- Hakozaki Junction

**Route B** (Bayshore/Wangan)
- Daikoku Junction (2 spots)
- Rainbow Bridge Ramp (2 spots)
- Haneda Airport areas (4 spots)
- Kawasaki Port (2 spots)
- Oi PA (2 spots)
- Hokuburitsu Bridge (2 spots)
- Shiokaze Park (2 spots)

**Route K1** (Kanagawa Route 1)
- 30+ locations from Tokyo to Yokohama!
- Heiwajima, Haneda, Kawasaki, Tsurumi Bridge
- Namamugi Junction, Daikoku area
- Yokohama Minatomirai, Kinko Junction

**Route K3** - Shin-Yamashita Toll Gate

**Route K5** - Daikoku Junction North

**Route Y** (Yurikamome)
- Shiodome Toll Gates (2 spots)
- Maintenance Area (2 spots)
- Tunnel sections (4 spots)
- Shimbashi Turn

#### 🏎️ Special Locations
- **Belt Inner - Flying Start** - Perfect for top speed runs!
- **Ota Stadium** - Route B
- **Shirauobashi Toll Gate** (4 spots - East/West, 2 lanes each)

## Usage Tips

### For Racing
- **Start Line Teleports**: Use toll gates or specific junctions
- **Chase Practice**: Teleport ahead of friends, wait for them
- **Route Learning**: Jump between sections to learn layout

### For Photography
- **Scenic Spots**: Rainbow Bridge, Daikoku PA, Shibuya Crossing
- **Elevated Views**: Various PA locations
- **Tunnel Shots**: Route Y, Hanazonobashi, Kasumigaseki

### For Cruising
- **Meet Friends**: "Meet at Daikoku!" now takes 5 seconds
- **Quick Repositioning**: Lost? Teleport to a known location
- **Explore**: Check out areas you've never visited

## Server Configuration

The teleport system is configured in:
- **File**: `/home/acserver/server/cfg/csp_extra_options.ini`
- **Section**: `[TELEPORT_DESTINATIONS]`
- **Format**: CSP standard teleport format

### Technical Details

Each teleport point includes:
- **Position**: X, Y, Z coordinates
- **Heading**: Direction you'll face (0-360 degrees)
- **Group**: Category for organization
- **Number**: Lane/spot number at that location

## Customization

Want to add your own spots? Edit `cfg/csp_extra_options.ini`:

```ini
POINT_XXX= 1
POINT_XXX_POS= X,Y,Z
POINT_XXX_HEADING= ANGLE
POINT_XXX_GROUP= Your Category Name
```

**Note**: Server restart required after changes to `csp_extra_options.ini`

## Client Requirements

- **Content Manager** v0.8.2594+
- **Custom Shaders Patch** v0.2.0+
- **Shuto Revival Project** v0.9.3

## Credits

- **Teleport Data**: [Gaulven](https://discord.gaulven.com/)
- **Implementation**: RedLine Souls Server Team
- **Map**: Shuto Revival Project Team

---

**Enjoy exploring Tokyo's highways! 🏙️🏁**
