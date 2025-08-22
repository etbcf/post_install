#!/usr/bin/env bash
# File: $HOME/post_install/dash-to-dock-launch.sh
# Make executable: chmod +x dash-to-dock-launch.sh

set -euo pipefail

DASH_TO_DOCK_CONFIG="$HOME/post_install/dash-to-dock-config.sh"
AUTOSTART_FILE="$HOME/.config/autostart/dash-to-dock-config.desktop"

# Check if the config script exists
if [[ -f "$DASH_TO_DOCK_CONFIG" ]]; then
    echo "🔧 Running Dash-to-Dock configuration..."
    bash "$DASH_TO_DOCK_CONFIG"
else
    echo "❌ Configuration script not found: $DASH_TO_DOCK_CONFIG"
    exit 1
fi

# Remove autostart entry so it only runs once
if [[ -f "$AUTOSTART_FILE" ]]; then
    rm -f "$AUTOSTART_FILE"
    echo "✅ Autostart entry removed. Dash-to-Dock launcher will not run again."
fi
