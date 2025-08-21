#!/usr/bin/env bash
# File: $HOME/post_install/dash-to-dock-launch.sh
# Give xecutable permission: chmod +x dash-to-dock-launch.sh

# Run the configuration
"$HOME/post_install/dash-to-dock-config.sh"

# Remove autostart entry so it only runs once
rm -f "$HOME/.config/autostart/dash-to-dock-config.desktop"
