#!/bin/bash

cat bashrc.additions >> ~/.bashrc

cp ./.gitmessage ~
cp ./.gitconfig ~

# powerline fonts for zsh agnoster theme
git clone https://github.com/powerline/fonts.git
cd fonts
./install.sh
cd .. && rm -rf fonts

# oh-my-zsh & plugins
wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh || true
zsh -c 'git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions'
zsh -c 'git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting'
cp ./.zshrc ~

mv ~/.zshrc ~/.zshrc.bak

sudo sh -c "$(wget -O- https://raw.githubusercontent.com/deluan/zsh-in-docker/master/zsh-in-docker.sh)" -- \
    -t agnoster

# remove newly created zshrc
rm -f ~/.zshrc
# restore saved zshrc
mv ~/.zshrc.bak ~/.zshrc
# update theme
sed -i '/^ZSH_THEME/c\ZSH_THEME="agnoster"' ~/.zshrc 

echo 'alias gp="git pull"' >> ~/.zshrc
echo 'alias gs="git status"' >> ~/.zshrc
echo 'alias gb="git branch"' >> ~/.zshrc
echo 'alias gc="git checkout"' >> ~/.zshrc
echo 'alias gbclean="git branch | grep -v \"develop.*\|master\|hotfix\|release\|main\" | xargs git branch -D"' >> ~/.zshrc

sudo chsh -s $(which zsh) $(whoami)