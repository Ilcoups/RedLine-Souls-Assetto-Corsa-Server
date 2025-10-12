#!/bin/bash
# Manual Weather Changer
# Usage: ./change_weather.sh [0-3]

if [ -z "$1" ]; then
    echo "Current weather types:"
    echo "  0 = Clear Sky ☀️"
    echo "  1 = Heavy Clouds ☁️"
    echo "  2 = Partly Cloudy 🌤️"
    echo "  3 = Heavy Fog 🌫️"
    echo ""
    echo "Usage: ./change_weather.sh [0-3]"
    echo "Example: ./change_weather.sh 2"
    exit 1
fi

WEATHER=$1

if [ $WEATHER -lt 0 ] || [ $WEATHER -gt 3 ]; then
    echo "❌ Invalid weather type! Use 0-3"
    exit 1
fi

echo "🌤️ Changing weather to type $WEATHER..."

# This would require restarting the server or using admin commands
# For now, just show the instruction
echo ""
echo "To apply weather change, you need to:"
echo "1. Join the server as admin"
echo "2. Use CSP admin commands to change weather"
echo "OR"
echo "3. Players can vote for weather change in-game"
echo ""
echo "Weather types available:"
echo "  /weather 0 = Clear"
echo "  /weather 1 = Cloudy" 
echo "  /weather 2 = Partly Cloudy"
echo "  /weather 3 = Fog"
