#!/bin/bash
# AssettoServer Stop Script

pkill -f AssettoServer

if [ $? -eq 0 ]; then
    echo "AssettoServer stopped successfully"
else
    echo "No AssettoServer process found"
fi
