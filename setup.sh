#!/bin/bash

set -e
set -o pipefail

echo "Setting up configurations..."

# Append bashrc additions
cat bashrc.additions >> ~/.bashrc

# Copy essential dotfiles
cp .gitmessage ~
cp .gitconfig ~

# Install Powerline fonts for Zsh Agnoster theme
if [ ! -d fonts ]; then
    git clone --depth=1 https://github.com/powerline/fonts.git
    cd fonts
    ./install.sh
    cd .. && rm -rf fonts
else
    echo "Powerline fonts already installed."
fi

# Install Oh My Zsh and plugins
if [ ! -d ~/.oh-my-zsh ]; then
    echo "Installing Oh My Zsh..."
    wget -qO- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh | zsh || true
else
    echo "Oh My Zsh already installed."
fi

# Install Zsh plugins
ZSH_CUSTOM=${ZSH_CUSTOM:-~/.oh-my-zsh/custom}
mkdir -p "$ZSH_CUSTOM/plugins"

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Backup existing .zshrc
if [ -f ~/.zshrc ]; then
    mv ~/.zshrc ~/.zshrc.bak
fi

# Install Zsh-in-Docker with Agnoster theme
sudo sh -c "$(wget -O- https://raw.githubusercontent.com/deluan/zsh-in-docker/master/zsh-in-docker.sh)" -- -t agnoster

# Restore .zshrc backup
if [ -f ~/.zshrc.bak ]; then
    mv ~/.zshrc.bak ~/.zshrc
fi

# Set theme to Agnoster in .zshrc
sed -i '/^ZSH_THEME/c\ZSH_THEME="agnoster"' ~/.zshrc

# Install Zsh Autocomplete
if [ ! -d ~/zsh-autocomplete ]; then
    git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git ~/zsh-autocomplete
fi

# Add Zsh autocomplete configuration
if ! grep -q "zsh-autocomplete" ~/.zshrc; then
    echo 'source ~/zsh-autocomplete/zsh-autocomplete.plugin.zsh' >> ~/.zshrc
    echo "skip_global_compinit=1" >> ~/.zshenv
fi

wget https://github.com/dandavison/delta/releases/download/0.18.2/git-delta_0.18.2_arm64.deb
sudo dpkg -i git-delta_0.18.2_arm64.deb
rm git-delta_0.18.2_arm64.deb

pnpm install --global git-checkout-interactive

cp -R neovim ~/.config/nvim

# Git aliases
cat <<EOF >> ~/.zshrc

# Git Aliases
alias gp="git pull"
alias gs="git status"
alias gb="git branch"
alias gc="git checkout"
alias gbclean="git branch | grep -v \"develop.*\|master\|hotfix\|release\|main\" | xargs git branch -D"

# AWS & Kafka Aliases
alias saml="saml2aws login -a dev -p dev --session-duration=38800"
alias kafka-sink-monitor="~/dotfiles/kafka-sink-monitor.sh"
alias kafka-sink-avg-lag="~/dotfiles/kafka-sink-avg-lag.sh"
alias kafka-sink-task="~/dotfiles/kafka-sink-task.sh"
alias kafka-clear-topic="~/dotfiles/kafka-clear-topic.sh"
alias awslogin="aws sso login --sso-session sso"

EOF

# Git global config
git config --global core.ignorecase false
git config --global core.pager "delta"
git config --global alias.lg "log --pretty='%C(red)%h%Creset%C(yellow)%d%Creset %s %C(cyan)(%ar)%Creset'"
git config --global alias.new "lg master..HEAD"
git config --global alias.missing "lg HEAD..master"
git config --global rebase.autosquash true
git config --global rebase.autoStash true
git config --global rerere.enabled true

# Change default shell to Zsh
if [ "$(basename "$SHELL")" != "zsh" ]; then
    echo "Changing default shell to Zsh..."
    sudo chsh -s "$(which zsh)" "$(whoami)"
fi

### **Setup Tmux Configuration**
echo "Setting up Tmux configuration..."
cat <<EOF > ~/.tmux.conf
# Split panes using | and -
bind | split-window -h
bind - split-window -v
unbind '"'
unbind %

set -g mouse on

# List of plugins
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'
set -g @continuum-restore 'on'

# Initialize TMUX plugin manager
run '~/.tmux/plugins/tpm/tpm'
EOF

# Install TPM (Tmux Plugin Manager)
if [ ! -d ~/.tmux/plugins/tpm ]; then
    git clone --depth=1 https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

echo "Setup complete! Restart your terminal or run 'exec zsh' to apply changes."
