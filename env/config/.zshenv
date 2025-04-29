VIM="nvim"

DEV_ENV=$HOME/dev

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export GIT_EDITOR=$VIM
export DEV_ENV_HOME="$HOME/dev"

dev_env() {

}

bindkey -s ^f "tmux-sessionizer\n"

catr() {
    tail -n "+$1" $3 | head -n "$(($2 - $1 + 1))"
}

cat1Line() {
    cat $1 | tr -d "\n"
}

h() {
  print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac --height "50%" | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

bd() {              
  local selected_branches
  selected_branches=$(
    git branch --list | \
      sed 's/^\* //' | \
      fzf --multi --preview 'git log --oneline --graph --decorate --branches={}' --height "50%"
  )

  if [[ -n "$selected_branches" ]]; then
    echo "You are about to delete the following branches:"
    echo "$selected_branches"
    read -q "reply?Are you sure you want to delete these branches? (y/N) "
    echo
    if [[ "$reply" == "y" || "$reply" == "Y" ]]; then
      echo "$selected_branches" | xargs -I {} git branch -D {}
      echo "Branches deleted."
    else
      echo "Branch deletion cancelled."
    fi
  else
    echo "No branches selected." 
  fi
}

addToPath() {
    if [[ "$PATH" != *"$1"* ]]; then
        export PATH=$PATH:$1
    fi
}

addToPathFront() {
    if [[ ! -z "$2" ]] || [[ "$PATH" != *"$1"* ]]; then
        export PATH=$1:$PATH
    fi
}

addToPathFront $HOME/.local/.npm-global/bin
addToPathFront $HOME/.local/apps
addToPathFront $HOME/.local/scripts
addToPathFront $HOME/.local/bin
addToPathFront $HOME/.local/npm/bin
addToPathFront $HOME/.local/n/bin/
addToPathFront $HOME/.local/apps/
addToPathFront $DEV_ENV_HOME/dotfiles/tools




