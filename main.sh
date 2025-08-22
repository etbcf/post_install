#!/usr/bin/env bash

set -euo pipefail

# Global variables
FONT_DIR="$HOME/.fonts"
FIRACODE_DIR="$FONT_DIR/FiraCode"
FIRACODE_ZIP="/tmp/FiraCode.zip"
FIRACODE_TMP="/tmp/FiraCode-extract"
FIRST_RUN_FLAG="$HOME/.local/.post_install_first_run"
EXTENSIONS_DIR="$HOME/.local"
TMP_DIR="/tmp/post_install"

main() {
    system_update
    enable_repos
    install_essentials
    install_flatpaks
    check_firefox_first_run
    check_gnome_extensions
    install_firacode_font
    enable_firewall
    install_nvm_node
    install_vim_plug
    clone_dotfiles
    install_tmux_helpers
    configure_git
    install_vscode
    install_dropbox
    install_starship
    set_wallpaper
    install_thunderbird
    configure_dash_to_dock
    echo "✅ Post-installation complete!"
}

# --- System and repos ---
system_update() {
    echo "📦 Updating system..."
    sudo dnf upgrade --refresh -y
    echo "✅ System updated!"
}

enable_repos() {
    echo "🔧 Enabling RPM Fusion and openh264 repos..."
    sudo dnf install -y \
        "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
        "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
    sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
}

install_essentials() {
    echo "🧰 Installing essential tools..."
    sudo dnf install -y neovim vim-enhanced tmux git python3-pip libappindicator \
        fzf uv ruff the_silver_searcher trash-cli gnome-tweaks python3-gpg \
        @virtualization steam-devices fastfetch xclip gnome-shell-extension-dash-to-dock
    pip install --upgrade pip debugpy
}

install_flatpaks() {
    echo "📦 Installing Flatpak apps..."
    flatpak install flathub -y \
        org.signal.Signal org.videolan.VLC com.bitwarden.desktop io.missioncenter.MissionCenter \
        com.valvesoftware.Steam com.mattjakeman.ExtensionManager com.github.neithern.g4music
}

# --- First run Firefox ---
check_firefox_first_run() {
    if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
        if pgrep -x "firefox" >/dev/null; then
            echo "🔄 Closing Firefox for update..."
            pkill -x "firefox"
            sleep 2
        fi
        touch "$FIRST_RUN_FLAG"
    fi
}

# --- GNOME extensions ---
check_gnome_extensions() {
    install_gnome_extension "appindicatorsupport" "appindicatorsupport@rgcjonas.gmail.com" "https://extensions.gnome.org/extension/615/appindicator-support/"
    install_gnome_extension "night-theme-switcher" "nightthemeswitcher@romainvigier.fr" "https://extensions.gnome.org/extension/2236/night-theme-switcher/"
}

install_gnome_extension() {
    local EXT_NAME="$1" EXT_UUID="$2" EXT_URL="$3"
    local FLAG_FILE="$EXTENSIONS_DIR/.${EXT_NAME}_installed"

    if [[ -f "$FLAG_FILE" ]] || gnome-extensions list | grep -q "$EXT_UUID"; then
        echo "✅ $EXT_NAME already installed, skipping."
        touch "$FLAG_FILE"
        return
    fi

    echo "🔧 Opening $EXT_NAME extension page..."
    xdg-open "$EXT_URL" >/dev/null 2>&1
    echo "👉 Install $EXT_NAME and press ENTER to continue..."
    read -r
    touch "$FLAG_FILE"
}

# --- Fonts ---
install_firacode_font() {
    if [[ -d "$FIRACODE_DIR" && -n "$(find "$FIRACODE_DIR" -name '*.ttf' -print -quit)" ]]; then
        echo "✅ FiraCode Nerd Font already installed."
        return
    fi

    echo "🔣 Installing FiraCode Nerd Font..."
    mkdir -p "$FIRACODE_DIR" "$FIRACODE_TMP"
    curl -L -o "$FIRACODE_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
    unzip -q "$FIRACODE_ZIP" -d "$FIRACODE_TMP"
    mv "$FIRACODE_TMP"/* "$FIRACODE_DIR"/
    fc-cache -f "$FIRACODE_DIR" >/dev/null
    rm -rf "$FIRACODE_ZIP" "$FIRACODE_TMP"
    echo "✅ FiraCode Nerd Font installed."
}

# --- Firewall ---
enable_firewall() {
    echo "🔒 Enabling firewall..."
    sudo systemctl enable --now firewalld
}

# --- Node.js via NVM ---
install_nvm_node() {
    echo "⬇️ Installing Node.js via NVM..."
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
    nvm install --lts
}

# --- Vim plug ---
install_vim_plug() {
    echo "🔌 Installing vim-plug for Vim..."
    curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

# --- Dotfiles ---
clone_dotfiles() {
    echo "📥 Cloning dotfiles..."
    [ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
    git clone --depth 1 https://github.com/etbcf/post_install.git "$TMP_DIR"

    echo "🔧 Installing dotfiles..."
    [ ! -f "$HOME/.vimrc" ] && mv "$TMP_DIR/.vimrc" "$HOME/.vimrc" || echo "⚠️ Skipping .vimrc"
    [ ! -d "$HOME/.config/nvim" ] && mkdir -p "$HOME/.config" && mv "$TMP_DIR/nvim" "$HOME/.config/nvim" || echo "⚠️ Skipping nvim config"
    [ ! -f "$HOME/.tmux.conf" ] && mv "$TMP_DIR/.tmux.conf" "$HOME/.tmux.conf" || echo "⚠️ Skipping .tmux.conf"
}

# --- TMUX helpers ---
install_tmux_helpers() {
    echo "🔧 Moving TMUX helper scripts..."
    for file in tat functions; do
        if [[ -f "$TMP_DIR/$file" && ! -f "/usr/local/bin/$file" ]]; then
            sudo mv "$TMP_DIR/$file" /usr/local/bin/
            sudo chmod +x /usr/local/bin/$file
            sudo chown root:root /usr/local/bin/$file
            echo "✅ Moved $file"
        fi
    done
}

# --- Git config ---
configure_git() {
    if [[ ! -f "$HOME/.gitconfig" ]]; then
        read -rp "Enter your Git email: " git_email
        git_name=$(whoami)
        cat >"$HOME/.gitconfig" <<EOF
[user]
    name = $git_name
    email = $git_email
[init]
    defaultBranch = main
EOF
        echo "✅ Git configured!"
    else
        echo "⚠️ Skipping Git config"
    fi
}

# --- Visual Studio Code ---
install_vscode() {
    echo "💻 Installing Visual Studio Code..."
    cat <<EOF | sudo tee /etc/yum.repos.d/vscode.repo >/dev/null
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF
    sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
    sudo dnf install -y code
}

# --- Dropbox ---
install_dropbox() {
    echo "📥 Installing Dropbox..."

    if rpm -q nautilus-dropbox >/dev/null 2>&1; then
        echo "⚠️ Skipping Dropbox (already installed)"
        return
    fi

    # Download latest rpm
    curl -L -o /tmp/dropbox.rpm \
        "https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2025.05.20-1.fc42.x86_64.rpm"

    # Install and launch setup
    if sudo dnf install -y /tmp/dropbox.rpm; then
        echo "✅ Dropbox installed!"
        echo "▶️ Launching Dropbox — a browser window should open for login..."
        dropbox start -i >/dev/null 2>&1 &

        echo "👉 Please log in through the browser, and then press ENTER to continue..."
        read -r

        echo "🛑 Killing Dropbox to finalize setup..."
        pkill dropbox || true
        sleep 2

        echo "🔄 Restarting Dropbox..."
        dropbox start -i >/dev/null 2>&1 &

        echo "👉 Please connect through the browser, and then press ENTER to continue..."
        read -r
    else
        echo "❌ Dropbox installation failed"
    fi
}

# --- Starship ---
install_starship() {
    if command -v starship >/dev/null 2>&1; then
        echo "⚠️ Starship already installed"
        return
    fi
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    grep -qxF 'eval "$(starship init bash)"' "$HOME/.bashrc" || echo 'eval "$(starship init bash)"' >>"$HOME/.bashrc"
}

# --- GNOME wallpaper ---
set_wallpaper() {
    LIGHT_WALLPAPER="/usr/share/backgrounds/gnome/blobs-l.svg"
    DARK_WALLPAPER="/usr/share/backgrounds/gnome/blobs-d.svg"
    if [ -f "$LIGHT_WALLPAPER" ] && [ -f "$DARK_WALLPAPER" ]; then
        gsettings set org.gnome.desktop.background picture-uri "file://$LIGHT_WALLPAPER"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$DARK_WALLPAPER"
        echo "✅ Wallpaper set"
    fi
}

# --- Thunderbird ---
install_thunderbird() {
    if [ -d "/opt/thunderbird" ]; then
        echo "⚠️ Thunderbird already installed"
        return
    fi
    TB_URL="https://download.mozilla.org/?product=thunderbird-142.0-SSL&os=linux64&lang=pt-PT"
    TB_TAR="/tmp/thunderbird-142.0.tar.xz"
    curl -L -o "$TB_TAR" "$TB_URL"
    sudo tar -xJf "$TB_TAR" -C /opt
    rm -f "$TB_TAR"
    mkdir -p "$HOME/.local/share/applications"
    cat <<EOF >"$HOME/.local/share/applications/thunderbird.desktop"
[Desktop Entry]
Name=Thunderbird
Exec=/opt/thunderbird/thunderbird
Icon=/opt/thunderbird/chrome/icons/default/default128.png
Type=Application
Categories=Network;Email;
StartupNotify=true
MimeType=x-scheme-handler/mailto;
EOF
    /opt/thunderbird/thunderbird >/dev/null 2>&1 &
}

# --- Dash-to-Dock autostart ---
configure_dash_to_dock() {
    AUTOSTART_DIR="$HOME/.config/autostart"
    AUTOSTART_FILE="$AUTOSTART_DIR/dash-to-dock-config.desktop"
    mkdir -p "$AUTOSTART_DIR"
    if [[ -f "$AUTOSTART_FILE" ]]; then
        echo "⚠️ Dash-to-Dock autostart exists"
    else
        cat >"$AUTOSTART_FILE" <<EOF
[Desktop Entry]
Type=Application
Exec=$HOME/post_install/dash-to-dock-launch.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Dash-to-Dock Config
Comment=Runs the dash-to-dock configuration script once at login
EOF
        echo "✅ Dash-to-Dock autostart configured. Log out and back in for changes to take effect."
    fi
}

main "$@"
