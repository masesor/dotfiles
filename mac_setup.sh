#!/bin/bash

set -e 
set -o pipefail

echo "🚀 Starting Mac setup..."

if ! command -v brew &> /dev/null; then
    echo "🍺 Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
else
    echo "✅ Homebrew already installed."
fi

brew update && brew upgrade

DEV_DIR=~/dev
DOTFILES_REPO="git@github.com:masesor/dotfiles.git"

mkdir -p "$DEV_DIR"

if [ ! -d "$DEV_DIR/dotfiles" ]; then
    echo "📂 Cloning dotfiles repository..."
    git clone "$DOTFILES_REPO" "$DEV_DIR/dotfiles"
else
    echo "✅ Dotfiles repository already cloned."
fi

echo "📦 Installing Brewfile packages..."
brew bundle --file="$DEV_DIR/dotfiles/Brewfile"

SETUP_SCRIPT="$DEV_DIR/dotfiles/setup.sh"
if [ -f "$SETUP_SCRIPT" ]; then
    echo "⚙️ Running setup.sh..."
    chmod +x "$SETUP_SCRIPT"
    "$SETUP_SCRIPT"
else
    echo "❌ setup.sh not found in $DEV_DIR/dotfiles"
fi

echo "🛒 Installing Mac App Store apps..."
brew install mas 

declare -A MAS_APPS=(
    ["HotspotShield VPN"]="771076721"
    ["PDFgear"]="6446202844"
    ["XCode"]="497799835"
    ["Unarchiver"]="425424353"
)

for APP in "${!MAS_APPS[@]}"; do
    APP_ID=${MAS_APPS[$APP]}
    if mas list | grep -q "$APP_ID"; then
        echo "✅ $APP is already installed."
    else
        echo "📲 Installing $APP..."
        mas install "$APP_ID"
    fi
done

echo "🎉 Mac setup complete! Restart your terminal to apply changes."