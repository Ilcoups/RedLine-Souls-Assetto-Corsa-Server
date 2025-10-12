# 🌤️ Voting Weather System - User Guide

## How It Works

Your server now has **automatic weather changes with player voting**!

### Timeline:
1. **Every 30 minutes**: Weather can change
2. **5 minutes before change**: Voting opens
3. **Players vote** for their preferred weather
4. **If nobody votes**: Random weather is chosen automatically
5. **3-minute smooth transition** to new weather

---

## 🗳️ For Players

### How to Vote:

When voting starts, you'll see a message in chat like:
```
Vote for next weather! Type in chat:
/vote 0 - Clear ☀️
/vote 1 - Cloudy ☁️
/vote 2 - Partly Cloudy 🌤️
/vote 3 - Fog 🌫️
```

### Voting Commands:
- `/vote 0` or `/v 0` = Vote for Clear
- `/vote 1` or `/v 1` = Vote for Cloudy
- `/vote 2` or `/v 2` = Vote for Partly Cloudy
- `/vote 3` or `/v 3` = Vote for Fog

### When Does It Happen?
- Voting opens **5 minutes before** weather change
- You have **5 minutes to vote**
- Most voted weather wins!
- If tied, random selection between tied options
- If nobody votes, automatic random weather

---

## 📊 Weather Types

| ID | Weather | Temp | Wind | Auto Chance |
|----|---------|------|------|-------------|
| 0 | Clear ☀️ | 18°C | Light | 35% |
| 1 | Cloudy ☁️ | 15°C | Strong | 30% |
| 2 | Partly Cloudy 🌤️ | 22°C | Moderate | 30% |
| 3 | Fog 🌫️ | 12°C | Calm | 5% |

---

## ⚙️ Server Settings

**Weather Duration:** 30 minutes per weather  
**Voting Duration:** 5 minutes before change  
**Transition Time:** 3 minutes smooth change  
**Auto Selection:** Weighted random (Clear most common, Fog rare)  
**Repeat Prevention:** Same weather won't repeat back-to-back

---

## 🎮 Example Session

**7:00 PM** - Weather: Clear ☀️
- Players cruising in sunshine

**7:25 PM** - Voting opens!
- Chat: "Vote for next weather!"
- Player 1: `/vote 1` (Cloudy)
- Player 2: `/vote 1` (Cloudy)
- Player 3: `/vote 3` (Fog)

**7:30 PM** - Weather change begins
- Cloudy wins (2 votes)
- 3-minute smooth transition
- Sky gradually becomes overcast

**7:33 PM** - New weather active
- Weather: Cloudy ☁️
- Temperature drops to 15°C
- Wind picks up to 5-15 km/h

**8:00 PM** - Next cycle...

---

## 🔧 Admin Controls

Admins can force weather change anytime:
- `/weather 0-3` or `/w 0-3` = Instant weather change

This overrides voting and starts the next cycle from that weather.

---

## 💡 Tips

✅ **Vote early** - First 5 minutes of voting window  
✅ **Coordinate** - Ask friends to vote for same weather  
✅ **Variety** - System prevents same weather twice in a row  
✅ **Automatic** - Even if nobody votes, weather still changes  
✅ **Smooth** - 3-minute transitions prevent jarring changes  

---

## 📋 No Vote Behavior

If **nobody votes**, the system randomly picks based on these chances:
- 35% chance: Clear ☀️
- 30% chance: Cloudy ☁️
- 30% chance: Partly Cloudy 🌤️
- 5% chance: Fog 🌫️ (rare surprise!)

This keeps the server dynamic even when players are busy racing!

---

## 🎯 Perfect For:

✅ **Democratic weather** - Players choose atmosphere  
✅ **Always changing** - Never boring  
✅ **Surprises** - Random fog keeps it interesting  
✅ **Racing variety** - Different conditions to master  
✅ **Realistic** - Smooth transitions like real weather  

---

Enjoy your dynamic weather system! 🌦️

Last Updated: October 12, 2025
