#!/usr/bin/env bash

gnome-extensions enable dash-to-dock@micxgx.gmail.com

# --- Posição e centralização ---
gsettings set org.gnome.shell.extensions.dash-to-dock dock-position 'BOTTOM'
gsettings set org.gnome.shell.extensions.dash-to-dock dock-fixed true
gsettings set org.gnome.shell.extensions.dash-to-dock extend-height false

# --- Aparência ---
gsettings set org.gnome.shell.extensions.dash-to-dock dash-max-icon-size 32
gsettings set org.gnome.shell.extensions.dash-to-dock transparency-mode 'FIXED'
gsettings set org.gnome.shell.extensions.dash-to-dock background-opacity 0.0
gsettings set org.gnome.shell.extensions.dash-to-dock custom-theme-shrink true

# --- Indicadores e comportamento ---
gsettings set org.gnome.shell.extensions.dash-to-dock running-indicator-style 'DASHES'
gsettings set org.gnome.shell.extensions.dash-to-dock autohide false

# Remove the autostart entry so it doesn't run again
AUTOSTART_FILE="$HOME/.config/autostart/dash-to-dock-config.desktop"
if [ -f "$AUTOSTART_FILE" ]; then
    rm -f "$AUTOSTART_FILE"
    echo "✅ Autostart entry removed. Script will not run on next login."
fi

echo "🎉 All done!"
