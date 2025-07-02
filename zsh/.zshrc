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

gw() {
	git worktree add -b $1 ./.git/worktree/${1//\//_} develop
}

rpout() {
  git ls-files | while read -r f; do
    MIME_TYPE=$(file -b --mime-type "$f")
    
    if [[ $MIME_TYPE == text/* ]]; then
      # テキストファイルの場合
      ext="${f##*.}"
      echo "### \`$f\`"
      echo "\`\`\`${ext}"
      cat "$f"
      echo
      echo "\`\`\`"
      echo
    else
      # バイナリファイルの場合
      echo "### \`$f\`"
      echo "[SKIPPING BINARY FILE ($MIME_TYPE)]"
      echo
    fi
  done
}

setopt noflowcontrol
zle -N fzf-cd

if [ ! -f "~/.zsh_secrets" ]; then
  touch ~/.zsh_secrets
fi

source ~/.zsh_secrets

source /opt/homebrew/opt/antidote/share/antidote/antidote.zsh

eval "$(/opt/homebrew/bin/brew shellenv)"
antidote load
eval "$(zoxide init zsh)"
eval "$(mise activate zsh)"
eval "$(starship init zsh)"

bindkey '^q' fzf-cd
bindkey '^r' fzf-select-history

# transient prompt
precmd_functions=(zvm_init "${(@)precmd_functions:#zvm_init}")
precmd_functions+=(set-long-prompt)

set-long-prompt() {
    PROMPT=$(starship prompt)
    RPROMPT=""
}

set-short-prompt() {
    PROMPT="$(STARSHIP_KEYMAP=${KEYMAP:-viins} starship module character)"
    RPROMPT=""
    zle .reset-prompt 2>/dev/null
}

zle-keymap-select() {
    set-short-prompt
}
zle -N zle-keymap-select

zle-line-finish() {
    set-short-prompt
}
zle -N zle-line-finish

trap 'set-short-prompt; return 130' INT

# zvm_after_init setup
zvm_after_init_commands+=('
  # Override zle-keymap-select for vi mode indication
  function zle-keymap-select() {
    if [[ ${KEYMAP} == vicmd ]] ||
       [[ $1 = "block" ]]; then
      echo -ne "\e[1 q"
      STARSHIP_KEYMAP=vicmd
    elif [[ ${KEYMAP} == main ]] ||
         [[ ${KEYMAP} == viins ]] ||
         [[ ${KEYMAP} = "" ]] ||
         [[ $1 = "beam" ]]; then
      echo -ne "\e[5 q"
      STARSHIP_KEYMAP=viins
    fi
    set-short-prompt
  }
  zle -N zle-keymap-select

  # Ensure vi mode is set
  zle-line-init() {
    zle -K viins
    echo -ne "\e[5 q"
  }
  zle -N zle-line-init
  
  # Re-register zle-line-finish after zvm init
  zle -N zle-line-finish
')

# alias

alias ll="eza -lauUh --icons=auto --hyperlink"
alias ls="eza"
alias cat="bat"

alias claude="~/.claude/local/claude"

# path

export PATH="$HOME/bin:$PATH"