if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# zsh history
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt share_history
setopt hist_ignore_dups
setopt hist_ignore_all_dups
setopt hist_ignore_space
setopt hist_reduce_blanks

setopt print_eight_bit

# fzf history
function fzf-select-history() {
    BUFFER=$(history -n -r 1 | fzf --query "$LBUFFER" --reverse)
    CURSOR=$#BUFFER
    zle reset-prompt
}
zle -N fzf-select-history
bindkey '^r' fzf-select-history


function fzf-cd() {
    zi
}

fda() {
  local dir
  dir=$(find ${1:-.} -type d 2>/dev/null | fzf +m) && cd "$dir"
}

cls_cont() {
  docker container rm -f $(docker container ls -aq)
}

cls_img() {
  docker image rm -f $(docker images -q)
}

setopt noflowcontrol
zle -N fzf-cd
bindkey '^q' fzf-cd


source ~/.zsh_secrets

source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh

eval "$(/opt/homebrew/bin/brew shellenv)"
antidote load ~/.zsh_plugins.txt
eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"

alias ll="eza -lauUh --icons=auto --hyperlink"
alias ls="eza"
alias cd="z"

# source ~/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
