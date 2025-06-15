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
brew bundle --file="$GITHUB_DIR/home/.Brewfile"

# ファイルリンク
stow -t $HOME -vR home mise zsh cargo

# mise install
mise install

# cargo install
cargo install --git https://github.com/itsjunetime/cargo-restore.git
cargo restore
