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
    install_virtualization
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
    echo "📦 Checking for system updates..."
    if sudo dnf check-update >/dev/null 2>&1; then
        echo "⚠️ System already up to date"
    else
        echo "📦 Updates found! Upgrading system..."
        sudo dnf upgrade -y
        echo "✅ System updated"
    fi
}

# --- Enable RPM Fusion and openh264 repos ---
enable_repos() {
    echo "🔧 Enabling RPM Fusion and openh264 repos..."

    if rpm -q rpmfusion-free-release rpmfusion-nonfree-release >/dev/null 2>&1; then
        echo "⚠️ RPM Fusion already enabled"
    else
        sudo dnf install -y \
            "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
            "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"
        echo "✅ RPM Fusion enabled"
    fi

    if dnf repolist enabled | grep -q "fedora-cisco-openh264"; then
        echo "⚠️ openh264 repo already enabled"
    else
        sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1
        echo "✅ openh264 repo enabled"
    fi
}

# --- Essential Tools ---
install_essentials() {
    echo "🧰 Installing essential tools..."
    PACKAGES=(
        neovim vim-enhanced tmux git python3-pip libappindicator
        fzf uv ruff the_silver_searcher trash-cli gnome-tweaks python3-gpg
        steam-devices fastfetch xclip gnome-shell-extension-dash-to-dock
        distrobox
    )

    TO_INSTALL=()
    for pkg in "${PACKAGES[@]}"; do
        if rpm -q "$pkg" >/dev/null 2>&1; then
            echo "⚠️ $pkg already installed"
        else
            TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        echo "📦 Installing missing packages/groups: ${TO_INSTALL[*]}"
        sudo dnf install -y "${TO_INSTALL[@]}"
    else
        echo "✅ All essential packages already installed"
    fi
}

# --- Virtualization ---
install_virtualization() {
    VIRT_PKGS=(
        virt-install
        libvirt-daemon-config-network
        libvirt-daemon-kvm
        qemu-kvm
        virt-manager
        virt-viewer
    )

    TO_INSTALL=()
    for pkg in "${VIRT_PKGS[@]}"; do
        if rpm -q "$pkg" >/dev/null 2>&1; then
            echo "⚠️ $pkg already installed"
        else
            TO_INSTALL+=("$pkg")
        fi
    done

    if [ ${#TO_INSTALL[@]} -gt 0 ]; then
        echo "📦 Installing missing virtualization packages: ${TO_INSTALL[*]}"
        sudo dnf install -y "${TO_INSTALL[@]}"
    else
        echo "✅ All virtualization packages already installed"
    fi

    # Python tools
    echo "🐍 Ensuring pip + debugpy..."
    NEED_PYTOOLS=()
    python3 -m pip show pip >/dev/null 2>&1 || NEED_PYTOOLS+=("pip")
    python3 -m pip show debugpy >/dev/null 2>&1 || NEED_PYTOOLS+=("debugpy")
    if [ ${#NEED_PYTOOLS[@]} -gt 0 ]; then
        echo "📦 Installing Python tools: ${NEED_PYTOOLS[*]}"
        python3 -m pip install --user --upgrade "${NEED_PYTOOLS[@]}"
    else
        echo "⚠️ pip + debugpy already installed"
    fi

    # libvirtd service
    if ! systemctl is-active --quiet libvirtd; then
        echo "🔧 Enabling and starting libvirtd service..."
        sudo systemctl enable --now libvirtd
    else
        echo "⚠️ libvirtd service already running"
    fi

    # libvirt default network
    if virsh net-info default >/dev/null 2>&1; then
        if virsh net-info default | grep -q "Active: yes"; then
            echo "⚠️ Default libvirt network already active"
        else
            echo "🔧 Starting default libvirt network..."
            sudo virsh net-start default
            sudo virsh net-autostart default
            echo "✅ Default libvirt network started"
        fi
    else
        echo "⚠️ Default libvirt network not defined"
    fi

}

# --- Flatpak Apps ---
install_flatpaks() {
    echo "📦 Installing Flatpak apps..."
    APPS=(
        org.signal.Signal
        org.videolan.VLC
        com.bitwarden.desktop
        io.missioncenter.MissionCenter
        com.valvesoftware.Steam
        com.mattjakeman.ExtensionManager
        com.github.neithern.g4music
    )

    for app in "${APPS[@]}"; do
        if flatpak info "$app" >/dev/null 2>&1; then
            echo "⚠️ $app already installed"
        else
            echo "⬇️ Installing $app..."
            flatpak install -y flathub "$app"
        fi
    done
}

# --- Firefox first run ---
check_firefox_first_run() {
    if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
        if pgrep -x "firefox" >/dev/null; then
            echo "🔄 Closing Firefox for update..."
            pkill -x "firefox"
            sleep 2
        fi
        touch "$FIRST_RUN_FLAG"
        echo "✅ Firefox first-run setup complete"
    else
        echo "⚠️ Firefox already initialized"
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
        echo "⚠️ $EXT_NAME already installed, skipping."
        touch "$FLAG_FILE"
        return
    fi

    echo "🔧 Opening $EXT_NAME extension page..."
    xdg-open "$EXT_URL" >/dev/null 2>&1
    echo "👉 Install $EXT_NAME and press ENTER to continue..."
    read -r
    touch "$FLAG_FILE"
    echo "✅ $EXT_NAME installed"
}

# --- Fonts ---
install_firacode_font() {
    if [[ -d "$FIRACODE_DIR" && -n "$(find "$FIRACODE_DIR" -name '*.ttf' -print -quit)" ]]; then
        echo "⚠️ FiraCode Nerd Font already installed"
        return
    fi
    echo "🔣 Installing FiraCode Nerd Font..."
    mkdir -p "$FIRACODE_DIR" "$FIRACODE_TMP"
    curl -L -o "$FIRACODE_ZIP" https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
    unzip -q "$FIRACODE_ZIP" -d "$FIRACODE_TMP"
    mv "$FIRACODE_TMP"/* "$FIRACODE_DIR"/
    fc-cache -f "$FIRACODE_DIR" >/dev/null
    rm -rf "$FIRACODE_ZIP" "$FIRACODE_TMP"
    echo "✅ FiraCode Nerd Font installed"
}

# --- Firewall ---
enable_firewall() {
    if systemctl is-active --quiet firewalld; then
        echo "⚠️ Firewall already enabled and running"
    else
        echo "🔒 Enabling and starting firewall..."
        sudo systemctl enable --now firewalld
    fi
}

# --- Node.js via NVM ---
install_nvm_node() {
    if [ -d "$HOME/.nvm" ]; then
        echo "⚠️ NVM already installed"
    else
        echo "⬇️ Installing NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
        echo "✅ NVM installed"
    fi

    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

    if nvm ls --no-colors | grep -q "lts/*"; then
        echo "⚠️ Node.js LTS already installed"
    else
        echo "⬇️ Installing latest Node.js LTS..."
        nvm install --lts
        echo "✅ Node.js LTS installed"
    fi
}

# --- Vim plug ---
install_vim_plug() {
    if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
        echo "⚠️ vim-plug already installed"
    else
        echo "🔌 Installing vim-plug for Vim..."
        curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        echo "✅ vim-plug installed"
    fi
}

# --- Dotfiles ---
clone_dotfiles() {
    DOTFILES_REPO="https://github.com/etbcf/post_install.git"
    TMP_DIR="/tmp/post_install"

    if [ -f "$HOME/.vimrc" ] && [ -d "$HOME/.config/nvim" ] && [ -f "$HOME/.tmux.conf" ]; then
        echo "⚠️ Dotfiles already installed, skipping."
        return
    fi

    echo "📥 Cloning dotfiles repo..."
    rm -rf "$TMP_DIR"
    git clone --depth 1 "$DOTFILES_REPO" "$TMP_DIR"

    if [ ! -f "$HOME/.vimrc" ]; then
        mv "$TMP_DIR/.vimrc" "$HOME/.vimrc"
        echo "✅ Installed .vimrc"
    else
        echo "⚠️ Skipping .vimrc"
    fi

    if [ ! -d "$HOME/.config/nvim" ]; then
        mkdir -p "$HOME/.config"
        mv "$TMP_DIR/nvim" "$HOME/.config/nvim"
        echo "✅ Installed Neovim config"
    else
        echo "⚠️ Skipping nvim config"
    fi

    if [ ! -f "$HOME/.tmux.conf" ]; then
        mv "$TMP_DIR/.tmux.conf" "$HOME/.tmux.conf"
        echo "✅ Installed .tmux.conf"
    else
        echo "⚠️ Skipping .tmux.conf"
    fi
}

# --- TMUX helpers ---
install_tmux_helpers() {
    for file in tat functions; do
        if [[ -f "$TMP_DIR/$file" && ! -f "/usr/local/bin/$file" ]]; then
            sudo mv "$TMP_DIR/$file" /usr/local/bin/
            sudo chmod +x /usr/local/bin/$file
            sudo chown root:root /usr/local/bin/$file
            echo "✅ Moved $file"
        else
            echo "⚠️ $file already installed in /usr/local/bin"
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
    if rpm -q code >/dev/null 2>&1; then
        echo "⚠️ Visual Studio Code already installed"
        return
    fi

    echo "💻 Installing Visual Studio Code..."
    if [ ! -f /etc/yum.repos.d/vscode.repo ]; then
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
    fi
    sudo dnf install -y code
    echo "✅ Visual Studio Code installed"
}

# --- Dropbox ---
install_dropbox() {
    if rpm -q nautilus-dropbox >/dev/null 2>&1; then
        echo "⚠️ Dropbox already installed"
        return
    fi

    echo "📥 Installing Dropbox..."
    curl -L -o /tmp/dropbox.rpm \
        "https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2025.05.20-1.fc42.x86_64.rpm"
    sudo dnf install -y /tmp/dropbox.rpm
    echo "✅ Dropbox installed"
}

# --- Starship ---
install_starship() {
    if command -v starship >/dev/null 2>&1; then
        echo "⚠️ Starship already installed"
        return
    fi
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    grep -qxF 'eval "$(starship init bash)"' "$HOME/.bashrc" || echo 'eval "$(starship init bash)"' >>"$HOME/.bashrc"
    echo "✅ Starship installed"
}

# --- GNOME wallpaper ---
set_wallpaper() {
    LIGHT_WALLPAPER="/usr/share/backgrounds/gnome/blobs-l.svg"
    DARK_WALLPAPER="/usr/share/backgrounds/gnome/blobs-d.svg"
    if [ -f "$LIGHT_WALLPAPER" ] && [ -f "$DARK_WALLPAPER" ]; then
        gsettings set org.gnome.desktop.background picture-uri "file://$LIGHT_WALLPAPER"
        gsettings set org.gnome.desktop.background picture-uri-dark "file://$DARK_WALLPAPER"
        echo "✅ Wallpaper set"
    else
        echo "⚠️ Wallpaper files missing"
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
    echo "✅ Thunderbird installed"
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
        echo "✅ Dash-to-Dock autostart configured"
    fi
}

main "$@"
