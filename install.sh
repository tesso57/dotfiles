#!/usr/bin/env bash
set -euo pipefail

GITHUB_DIR="$HOME/Documents/repos/tesso57/dotfiles"

# install brew
if ! command -v brew &>/dev/null; then
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    echo "restart your terminal"
    exit 1
fi

# レポジトリ用のディレクトリを作成
mkdir -pv "$GITHUB_DIR"

# レポジトリをクローンまたはプル
if [ -d "$GITHUB_DIR/.git" ]; then
    cd "$GITHUB_DIR"
    git pull
else
    cd "$(dirname "$GITHUB_DIR")"
    git clone git@github.com:tesso57/dotfiles.git
fi

cd "$GITHUB_DIR"

# brew bundle
brew bundle -v --file="$GITHUB_DIR/home/.Brewfile"

# ファイルリンク
"$GITHUB_DIR/sync.sh"

# mise install
mise install

# install agent skills declared in skills.json
if command -v gh >/dev/null 2>&1 && gh auth status &>/dev/null; then
    "$GITHUB_DIR/bin/bin/sync-skills"
else
    echo "skip sync-skills: run 'gh auth login' then '$GITHUB_DIR/bin/bin/sync-skills'"
fi
