# dotfiles

macOS 用の個人 dotfiles です。GNU Stow でホームディレクトリへ symlink し、
Homebrew と mise で開発環境を揃えます。

## Setup

```sh
curl -fsSL https://raw.githubusercontent.com/tesso57/dotfiles/main/install.sh | bash
```

`install.sh` は以下を実行します。

- Homebrew の用意
- `tesso57/dotfiles` の clone/update
- `home/.Brewfile` の `brew bundle`
- `sync.sh` による symlink 更新
- `mise install`
- private tool の install/update
- agent skill の同期

## Daily Update

```sh
git pull
./sync.sh
brew bundle -v --file=./home/.Brewfile
mise install
bin/bin/install-gopls-router
```

## Neovim

Neovim の Go LSP は private repository の `gopls-router` を使います。

- installer: `bin/bin/install-gopls-router`
- source repo: `tesso57/gopls-router`
- managed clone: `~/.local/share/gopls-router/repo`
- binary: `~/.local/bin/gopls-router`
- shared config: `nvim/.config/nvim/lua/config/gopls_router.lua`

Install or update manually:

```sh
bin/bin/install-gopls-router
```

The Neovim config uses `require("config.gopls_router").server()` from
`nvim/.config/nvim/lua/plugins/lsp.lua`.

## LazyVim

For LazyVim, copy the example plugin spec:

```sh
cp docs/lazyvim-gopls-router.lua ~/.config/nvim/lua/plugins/gopls-router.lua
```

It expects the shared module at:

```text
~/.config/nvim/lua/config/gopls_router.lua
```

If this repo is installed through `sync.sh`, that module is already symlinked.
