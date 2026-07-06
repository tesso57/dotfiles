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
- agent skill の同期

## Daily Update

```sh
git pull
./sync.sh
brew bundle -v --file=./home/.Brewfile
mise install
```

Neovim tools managed by Mason are installed when Neovim starts. To force a
rebuild of `gopls-router`, run this inside Neovim:

```vim
:MasonUninstall gopls-router
:MasonInstall gopls-router
```

## Neovim

Neovim の Go LSP は private repository の `gopls-router` を使います。

- Mason package: `gopls-router`
- source repo: `tesso57/gopls-router`
- primary binary: `~/.local/share/nvim/mason/bin/gopls-router`
- shared config: `nvim/.config/nvim/lua/config/gopls_router.lua`

The flow is:

1. lazy.nvim clones the private `gopls-router` repository as
   `gopls-router-mason-registry`.
2. Mason loads `lua:gopls_router_mason_registry.index` from that repository.
3. `mason-tool-installer` installs the `gopls-router` package.
4. `config.gopls_router` starts Mason's `gopls-router` binary for `gopls`.

Neovim loads the private `gopls-router` repository as a lazy.nvim dependency.
That repository provides the Mason Lua registry, and `mason-tool-installer`
installs the `gopls-router` binary into Mason's bin directory.

Install or rebuild it manually from Neovim:

```vim
:MasonInstall gopls-router
:MasonToolsInstall
```

The private repo must be reachable by git. By default the config uses:

```text
git@github.com:tesso57/gopls-router.git
```

Override it with `GOPLS_ROUTER_REPO_URL` if needed.

Fallback manual install:

```sh
bin/bin/install-gopls-router
```

The Neovim config uses `require("config.gopls_router").server()` from
`nvim/.config/nvim/lua/plugins/lsp.lua`.

If `:checkhealth vim.lsp` shows two `gopls` clients, check their root
directories. A project root plus `~/.local/share/mise/installs/go/.../src`
usually means a Go toolchain source buffer was opened. The config avoids
starting `gopls-router` for `GOROOT/src` files, so restart Neovim or run
`:LspRestart gopls` after updating.

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
