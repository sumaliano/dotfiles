# Dotfiles

Minimal, portable shell and editor configurations for **Bash**, **Vim**, and **Neovim**.

## Features

- **Bash**: Enhanced prompt with git integration
- **Neovim**: Plugin-free config with LSP, Git integration, fzf navigation
- **Portability**: Graceful degradation on minimal systems, auto-detect modern tools
- **No bloat**: Single files, no plugins (except nvim LSP)

## Quick Start

```bash
git clone https://github.com/username/dotfiles ~/dotfiles
cd ~/dotfiles

# Install to home directory
./install.sh

# Or install selectively
./install.sh vim bash tmux
```

## What's Included

### Config Files
- `_gitconfig` - Git aliases and settings
- `_tmuxrc` - Tmux configuration
- `_inputrc` - Readline settings
- `_dir_colors` - LS color scheme

## Compatibility

- **Bash 3.2+** (minimal systems), **4.0+** recommended
- **Vim 7.x+** (core), **8.0+** (persistent undo)
- **Neovim 0.8+** (LSP requires 0.9+)
- **Graceful degradation**: Older versions work fine, just with fewer features

## LSP Setup (Neovim)

Auto-detects installed servers. To enable:

```bash
# Python
pip install pyright

# Bash
npm install -g bash-language-server

# Rust
rustup component add rust-analyzer

# C/C++
sudo apt install clangd  # or your package manager

# Java
# Download from https://github.com/eclipse-jdtls/eclipse.jdt.ls
# Put `jdtls` binary in PATH
```

Check status with `:lua print(vim.lsp.get_log_path())` or press `<leader>li`.

## Customization

### Bash
Edit `_bashrc` directly. Local overrides go in `~/.bashrc.local`.

### Vim
Edit `_vimrc`. Sections are fold-marked for easy navigation.

### Neovim
Edit `_config/nvim/init_minimal.lua`. All settings in one file.
