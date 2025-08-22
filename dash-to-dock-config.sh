#!/usr/bin/env bash

set -euo pipefail

configure_dash_to_dock() {
    echo "🔧 Configuring Dash-to-Dock extension..."

    # Enable the extension
    gnome-extensions enable dash-to-dock@micxgx.gmail.com

    # --- Position & centering ---
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
    gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
    gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false

    # --- Appearance ---
    gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
    gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
    gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.0
    gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true

    # --- Indicators & behavior ---
    gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DASHES'
    gsettings set org.gnome.shell.extensions.dash-to-dock autohide false

    # Remove autostart entry so it doesn't run again
    local AUTOSTART_FILE="$HOME/.config/autostart/dash-to-dock-config.desktop"
    if [ -f "$AUTOSTART_FILE" ]; then
        rm -f "$AUTOSTART_FILE"
        echo "✅ Autostart entry removed. Script will not run on next login."
    fi

    echo "🎉 Dash-to-Dock configuration complete!"
}

# Call function if running standalone
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    configure_dash_to_dock
fi
