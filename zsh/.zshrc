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

repo() {
	cd `git rev-parse --show-toplevel`
}

cls_branch() {
  git fetch --prune && git branch -vv | grep ': gone]' | awk '{print $1}' | xargs -r git branch -d
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
eval "$(task --completion zsh)"
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

# path

export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export GPG_TTY=$(tty)

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Added by Antigravity
export PATH="$HOME/.antigravity/antigravity/bin:$PATH"
# The following lines have been added by Docker Desktop to enable Docker CLI completions.
export PATH="$HOME/.docker/bin:$PATH"

fpath=("$HOME/.docker/completions" $fpath)
autoload -Uz compinit
compinit
# End of Docker CLI completions

# pnpm
export PNPM_HOME="/Users/shinozakitakumi/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end

# gh skill install hook → auto-append to ~/Documents/repos/tesso57/dotfiles/skills.json
# Tracks new (repo, name[, version]) entries when you run `gh skill install <repo> <name>`.
# Skips when the install is unusual (--from-local, --dir, interactive without args, etc.)
# or when the entry is already in the manifest.
gh() {
  if [[ "$1" == "skill" && "$2" == "install" ]]; then
    command gh "$@" || return
    _sync_skills_record "${@:3}"
    return
  fi
  command gh "$@"
}

_sync_skills_record() {
  local manifest="$HOME/Documents/repos/tesso57/dotfiles/skills.json"
  [[ -f "$manifest" ]] || return 0
  command -v jq >/dev/null 2>&1 || return 0

  local repo="" skill="" version=""
  local args=("$@") arg i=1
  while (( i <= ${#args} )); do
    arg="${args[i]}"
    case "$arg" in
      --from-local|--dir|--dir=*)
        return 0  # custom location — do not track
        ;;
      --agent|--scope|--pin)
        (( i += 2 ))
        continue
        ;;
      --agent=*|--scope=*|--pin=*|--force|--allow-hidden-dirs|--upstream)
        ;;
      *)
        if [[ -z "$repo" ]]; then
          repo="$arg"
        elif [[ -z "$skill" ]]; then
          skill="$arg"
        fi
        ;;
    esac
    (( i++ ))
  done
  [[ -z "$repo" || -z "$skill" ]] && return 0

  if [[ "$skill" == *@* ]]; then
    version="${skill##*@}"
    skill="${skill%@*}"
  fi
  skill="${skill##*/}"  # strip generic/, personal/ namespace prefix

  if jq -e --arg r "$repo" --arg n "$skill" \
      '.skills | any(.repo == $r and .name == $n)' "$manifest" >/dev/null; then
    return 0
  fi

  local entry tmp
  if [[ -n "$version" ]]; then
    entry=$(jq -n --arg r "$repo" --arg n "$skill" --arg v "$version" \
      '{repo: $r, name: $n, version: $v}')
  else
    entry=$(jq -n --arg r "$repo" --arg n "$skill" '{repo: $r, name: $n}')
  fi
  tmp="$(mktemp)" || return 0
  if jq --argjson e "$entry" '.skills += [$e]' "$manifest" > "$tmp"; then
    mv "$tmp" "$manifest"
    echo "skills.json: tracked $repo $skill${version:+@$version}"
  else
    rm -f "$tmp"
  fi
}
