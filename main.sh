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
    @virtualization steam-devices fastfetch

echo "📦 Installing Flatpak apps..."
flatpak install flathub -y \
    org.signal.Signal org.videolan.VLC com.bitwarden.desktop io.missioncenter.MissionCenter \
    com.valvesoftware.Steam com.mattjakeman.ExtensionManager com.github.neithern.g4music

echo "🔧 Enabling fzf keybindings..."
grep -qxF 'eval "$(fzf --bash)"' "$HOME/.bashrc" || echo 'eval "$(fzf --bash)"' >>"$HOME/.bashrc"

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
git clone --depth 1 https://github.com/etbcf/post_install.git /tmp/post-install
mv /tmp/post-install/.vimrc "$HOME/.vimrc"
mkdir -p "$HOME/.config"
mv /tmp/post-install/nvim "$HOME/.config/nvim"
mv /tmp/post-install/.tmux.conf "$HOME/.tmux.conf"

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

echo "🔧 Enabling AppIndicator / KStatusNotifierItem support..."
sudo dnf install -y gnome-shell-extension-appindicator
gnome-extensions enable appindicator-support@rgcjonas.gmail.com || true

echo "📥 Installing Dropbox..."
curl -L -o /tmp/dropbox.rpm "https://www.dropbox.com/download?dl=packages/fedora/nautilus-dropbox-2025.05.20-1.fc42.x86_64.rpm"
sudo dnf install -y /tmp/dropbox.rpm || {
    echo "❌ Dropbox installation failed"
    exit 1
}

echo "▶️ Launching Dropbox — a browser window should open for login..."
dropbox start -i >/dev/null 2>&1 &

echo "👉 Please log in through the browser, then press ENTER to continue..."
read

echo "🛑 Killing Dropbox to finalize setup..."
pkill dropbox || true
sleep 2

echo "🔄 Restarting Dropbox..."
dropbox start

echo "✅ Dropbox installed and running!"

echo "🎉 All done! You may want to reboot now."
