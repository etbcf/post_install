#!/usr/bin/env bash

set -euo pipefail

echo "📦 Updating system..."
sudo dnf upgrade --refresh -y
echo "✅ System updated!"

echo "🔧 Enabling RPM Fusion repos..."
sudo dnf install -y \
    "https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
    "https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

echo "🔧 Enabling openh264 repo..."
sudo dnf config-manager setopt fedora-cisco-openh264.enabled=1

echo "🧰 Installing essential tools..."
sudo dnf install -y neovim vim-enhanced tmux git python3-pip libappindicator \
    fzf uv ruff the_silver_searcher trash-cli gnome-tweaks python3-gpg \
    @virtualization steam-devices fastfetch xclip gnome-shell-extension-dash-to-dock

echo "📦 Upgrading pip and instaling debugpy...."
pip install --upgrade pip
pip install debugpy

echo "📦 Installing Flatpak apps..."
flatpak install flathub -y \
    org.signal.Signal org.videolan.VLC com.bitwarden.desktop io.missioncenter.MissionCenter \
    com.valvesoftware.Steam com.mattjakeman.ExtensionManager com.github.neithern.g4music

# --- First run flags ---
FIRST_RUN_FLAG="$HOME/.local/.post_install_first_run"
EXTENSIONS_DIR="$HOME/.local"

# --- Function to handle Firefox update on first run ---
update_firefox_first_run() {
    if [[ ! -f "$FIRST_RUN_FLAG" ]]; then
        if pgrep -x "firefox" >/dev/null; then
            echo "🔄 Closing Firefox for update..."
            pkill -x "firefox"
            sleep 2 # Give it a moment to close
        fi
        # Mark first run done
        touch "$FIRST_RUN_FLAG"
    fi
}

# --- Function to check GNOME extensions ---
check_gnome_extension() {
    local EXT_NAME="$1"
    local EXT_UUID="$2"
    local EXT_URL="$3"
    local FLAG_FILE="$EXTENSIONS_DIR/.${EXT_NAME}_installed"

    # Skip if extension already installed
    if [[ -f "$FLAG_FILE" ]]; then
        echo "✅ $EXT_NAME already installed, skipping."
        return
    fi

    # Check if extension is actually installed
    if gnome-extensions list | grep -q "$EXT_UUID"; then
        echo "✅ $EXT_NAME installed."
        touch "$FLAG_FILE"
        return
    fi

    # Open extension page for user to install
    echo "🔧 Opening $EXT_NAME extension page in your browser..."
    xdg-open "$EXT_URL" >/dev/null 2>&1

    echo "👉 Please install $EXT_NAME and press ENTER to continue..."
    read -r

    # Mark as installed so next run skips
    touch "$FLAG_FILE"
}

# --- Run Firefox update check ---
update_firefox_first_run

# --- Check GNOME extensions ---
check_gnome_extension "appindicatorsupport" "appindicatorsupport@rgcjonas.gmail.com" \
    "https://extensions.gnome.org/extension/615/appindicator-support/"

check_gnome_extension "night-theme-switcher" "nightthemeswitcher@romainvigier.fr" \
    "https://extensions.gnome.org/extension/2236/night-theme-switcher/"

echo "🔧 Enabling fzf keybindings..."
grep -qxF 'eval "$(fzf --bash)"' "$HOME/.bashrc" || echo 'eval "$(fzf --bash)"' >>"$HOME/.bashrc"

echo "🔧 Enabling custom functions (mkcd, mkgit, mkclone)..."
# Ensure ~/.bashrc exists
[ -f "$HOME/.bashrc" ] || touch "$HOME/.bashrc"

# Add source line only once
grep -qxF 'source /usr/local/bin/functions' "$HOME/.bashrc" || echo 'source /usr/local/bin/functions' >>"$HOME/.bashrc"

echo "🔣 Installing FiraCode Nerd Font..."
mkdir -p ~/.fonts
curl -L -o /tmp/FiraCode.zip https://github.com/ryanoasis/nerd-fonts/releases/latest/download/FiraCode.zip
unzip -o /tmp/FiraCode.zip -d ~/.fonts
fc-cache -fv
rm /tmp/FiraCode.zip

echo "🔒 Enabling firewall..."
sudo systemctl enable --now firewalld

echo "⬇️ Installing Node.js via NVM..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.3/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"
nvm install --lts

echo "🔌 Installing vim-plug for Vim..."
curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

echo "📥 Cloning dotfiles..."
TMP_DIR="/tmp/post_install"
[ -d "$TMP_DIR" ] && rm -rf "$TMP_DIR"
git clone --depth 1 https://github.com/etbcf/post_install.git "$TMP_DIR"

echo "🔧 Installing dotfiles..."

# .vimrc
if [ ! -f "$HOME/.vimrc" ]; then
    mv "$TMP_DIR/.vimrc" "$HOME/.vimrc"
else
    echo "⚠️  Skipping .vimrc (already exists)"
fi

# nvim config
if [ ! -d "$HOME/.config/nvim" ]; then
    mkdir -p "$HOME/.config"
    mv "$TMP_DIR/nvim" "$HOME/.config/nvim"
else
    echo "⚠️  Skipping nvim config (already exists)"
fi

# .tmux.conf
if [ ! -f "$HOME/.tmux.conf" ]; then
    mv "$TMP_DIR/.tmux.conf" "$HOME/.tmux.conf"
else
    echo "⚠️  Skipping .tmux.conf (already exists)"
fi

# --- TMUX attacher and functions ---
echo "🔧 Moving TMUX attacher and helper scripts to /usr/local/bin..."

for file in tat functions; do
    if [[ -f "$TMP_DIR/$file" ]]; then
        if [[ ! -f "/usr/local/bin/$file" ]]; then
            sudo mv "$TMP_DIR/$file" /usr/local/bin/
            sudo chmod +x /usr/local/bin/$file
            sudo chown root:root /usr/local/bin/$file
            echo "✅ Moved $file to /usr/local/bin"
        else
            echo "⚠️  Skipping $file (already exists in /usr/local/bin)"
        fi
    fi
done

echo "📧 Configuring Git..."
if [ ! -f "$HOME/.gitconfig" ]; then
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
    echo "⚠️  Skipping Git config (.gitconfig already exists)"
fi

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

echo "📥 Installing Dropbox..."
if rpm -q nautilus-dropbox >/dev/null 2>&1; then
    echo "⚠️  Skipping Dropbox (already installed)"
else
    curl -L -o /tmp/dropbox.rpm "https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2025.05.20-1.fc42.x86_64.rpm"
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
fi

echo "📦 Installing starship prompt..."
if command -v starship >/dev/null 2>&1; then
    echo "⚠️  Skipping Starship (already installed)"
else
    curl -sS https://starship.rs/install.sh | sh -s -- -y
    echo "✅ Starship installed!"
fi

# Ensure ~/.bashrc exists
[ -f "$HOME/.bashrc" ] || touch "$HOME/.bashrc"

# Add Starship init only once
grep -qxF 'eval "$(starship init bash)"' "$HOME/.bashrc" || echo 'eval "$(starship init bash)"' >>"$HOME/.bashrc"

echo "🖼️ Setting GNOME default wallpaper..."
LIGHT_WALLPAPER="/usr/share/backgrounds/gnome/blobs-l.svg"
DARK_WALLPAPER="/usr/share/backgrounds/gnome/blobs-d.svg"

if [ -f "$LIGHT_WALLPAPER" ] && [ -f "$DARK_WALLPAPER" ]; then
    gsettings set org.gnome.desktop.background picture-uri "file://$LIGHT_WALLPAPER"
    gsettings set org.gnome.desktop.background picture-uri-dark "file://$DARK_WALLPAPER"
    echo "✅ Wallpaper set to GNOME blobs"
else
    echo "⚠️ GNOME wallpapers not found in /usr/share/backgrounds/gnome/"
fi

echo "✅ Dropbox installed and running!"

echo "📧 Installing Thunderbird..."

# Path check (Thunderbird already installed?)
if [ -d "/opt/thunderbird" ] || [ -f "$HOME/.local/share/applications/thunderbird.desktop" ]; then
    echo "⚠️  Skipping Thunderbird (already installed)"
else
    # Defining vars
    TB_URL="https://download.mozilla.org/?product=thunderbird-142.0-SSL&os=linux64&lang=pt-PT"
    TB_TAR="/tmp/thunderbird-142.0.tar.xz"

    # Download Thunderbird tarball
    curl -L -o "$TB_TAR" "$TB_URL"

    # Extract to /opt
    sudo tar -xJf "$TB_TAR" -C /opt

    # Clean up
    rm -f "$TB_TAR"

    # Create desktop entry (user-level)
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

    echo "✅ Thunderbird installed!!!"

    echo "▶️ Launching Thunderbird for initial setup..."
    /opt/thunderbird/thunderbird >/dev/null 2>&1 &

    echo "👉 Please log in to your Thunderbird account(s)."
    echo "👉 When you are finished, press ENTER to continue..."
    read -r
fi

echo "✅ Thunderbird installed!!!"

# Path to the autostart entry
AUTOSTART_DIR="$HOME/.config/autostart"
mkdir -p "$AUTOSTART_DIR"

cat >"$AUTOSTART_DIR/dash-to-dock-config.desktop" <<EOF
[Desktop Entry]
Type=Application
Exec=$HOME/post_install/dash-to-dock-launch.sh
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
Name=Dash-to-Dock Config
Comment=Runs the dash-to-dock configuration script once at login
EOF

echo "✅ Dash-to-Dock configuration will run automatically at next login."
echo "👉 Please log out and log back in."
