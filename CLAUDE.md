# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a dotfiles repository for macOS configuration management using:
- **GNU Stow** for symlink management
- **Homebrew** for package management
- **Mise** for runtime version management
- **Zsh** with Antidote plugin manager
- **Starship** for shell prompt

## Common Commands

### Installation and Setup
```bash
# Initial setup (includes Homebrew installation)
curl -fsSL https://raw.githubusercontent.com/tesso57/dotfiles/main/install.sh | bash

# Update symlinks after changes
./sync.sh

# Install/update packages from Brewfile
brew bundle -v --file=./home/.Brewfile

# Install mise-managed tools
mise install
```

### Development Commands
```bash
# Search through files (using ripgrep)
rg "pattern"

# Run gemini AI model
gemini -p "prompt"
```

## Repository Structure

The repository uses GNU Stow for managing dotfiles:

- **`home/`** - Contains `.Brewfile` with all Homebrew packages and VS Code extensions
- **`zsh/`** - Zsh configuration files (`.zshrc`, `.zsh_plugins.txt`)
- **`vim/`** - Vim configuration (`.vimrc`)
- **`mise/`** - Mise runtime configuration
- **`starship/`** - Starship prompt configuration
- **`claude/`** - Claude AI settings and custom commands
- **`bin/`** - Custom shell scripts

The `sync.sh` script uses Stow to create symlinks from these directories to the home directory.

## Key Configuration Files

- **`install.sh`** - Main installation script that clones repo, installs Homebrew, runs bundle, and sets up symlinks
- **`sync.sh`** - Creates/updates symlinks using GNU Stow
- **`home/.Brewfile`** - Declares all Homebrew packages, casks, and VS Code extensions
- **`zsh/.zshrc`** - Main Zsh configuration with custom functions and keybindings
- **`mise/.config/mise/config.toml`** - Manages tool versions (Node.js, Go, Python, Rust, etc.)
- **`claude/.claude/settings.json`** - Claude AI permissions and hooks configuration

## Custom Functions and Aliases

Key functions defined in `.zshrc`:
- `fzf-select-history` - Interactive history search with fzf
- `fzf-cd` - Directory navigation with zoxide
- `fda` - Find and cd to directories with fzf
- `cls_cont` / `cls_img` - Docker cleanup commands
- `gw` - Git worktree helper
- `rpout` - Export repository files to markdown format

## Claude AI Integration

The repository includes Claude AI configurations:
- Custom commands in `claude/.claude/commands/`
- Permissions for various tools (npm, git, go, etc.)
- Notification hooks using macOS notifications
- Integration with o3 MCP for advanced searches