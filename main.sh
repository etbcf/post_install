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
    @virtualization steam-devices fastfetch xclip

echo "🔄 Restarting Firefox..."
# Kill all running Firefox processes
pkill -x firefox || true

# Give it a moment to close cleanly
sleep 2

# Relaunch Firefox in the background
nohup firefox >/dev/null 2>&1 &
disown

echo "✅ Firefox restarted!"

echo "📦 Upgrading pip and instaling debugpy...."
pip install --upgrade pip
pip install debugpy

echo "📦 Installing Flatpak apps..."
flatpak install flathub -y \
    org.signal.Signal org.videolan.VLC com.bitwarden.desktop io.missioncenter.MissionCenter \
    com.valvesoftware.Steam com.mattjakeman.ExtensionManager com.github.neithern.g4music

echo "🔧 Opening AppIndicator support page in your browser..."
xdg-open "https://extensions.gnome.org/extension/615/appindicator-support/" >/dev/null 2>&1
echo "👉 Please install AppIndicator and then press ENTER to continue..."
read -r

echo "🔧 Opening Dash to Dock extension page in your browser..."
xdg-open "https://extensions.gnome.org/extension/307/dash-to-dock/" >/dev/null 2>&1
echo "👉 Please install Dash to Dock and then press ENTER to continue..."
read -r

echo "🔧 Opening Night Them Switcher extension page in your browser..."
xdg-open "https://extensions.gnome.org/extension/2236/night-theme-switcher/"
echo "👉 Please install Night Theme Switcher and then press ENTER to continue..."
read -r

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
git clone --depth 1 https://github.com/etbcf/post_install.git /tmp/post_install
mv /tmp/post_install/.vimrc "$HOME/.vimrc"
mkdir -p "$HOME/.config"
mv /tmp/post_install/nvim "$HOME/.config/nvim"
mv /tmp/post_install/.tmux.conf "$HOME/.tmux.conf"

echo "🔧 Adding TMUX attacher and some useful scripts to /usr/local/bin/..."
sudo install -m 755 /tmp/post_install/tat /usr/local/bin/tat
sudo install -m 755 /tmp/post_install/functions /usr/local/bin/functions

echo "source /usr/local/bin/functions" >>"$HOME/.bashrc"

echo "📧 Configuring Git..."
read -rp "Enter your Git email: " git_email
git_name=$(whoami)
cat >"$HOME/.gitconfig" <<EOF
[user]
    name = $git_name
    email = $git_email
[init]
    defaultBranch = main
EOF

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
curl -L -o /tmp/dropbox.rpm "https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2025.05.20-1.fc42.x86_64.rpm"
sudo dnf install -y /tmp/dropbox.rpm || {
    echo "❌ Dropbox installation failed"
    exit 1
}

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

echo "📦 Installing starship prompt..."
curl -sS https://starship.rs/install.sh | sh

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
cat <<EOF | sudo tee ~/.local/share/applications/thunderbird.desktop >/dev/null
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

echo "✅ Installation finished!"
echo "🔄 Reloading shell so changes take effect (Starship, fzf, etc.)..."
echo "🎉 All done! You may want to reboot now."
exec bash
