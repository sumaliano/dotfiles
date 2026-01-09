#!/usr/bin/env bash
#
# Dotfiles installer
# Extends system configuration, doesn't replace it
# Works on minimal systems without admin access
#

set -euo pipefail

# Colors (with fallback for dumb terminals)
if [[ -t 1 ]] && [[ "${TERM:-dumb}" != "dumb" ]]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    BLUE='\033[0;34m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
else
    RED='' GREEN='' BLUE='' YELLOW='' NC=''
fi

info() { echo -e "${BLUE}==>${NC} $*"; }
success() { echo -e "${GREEN}[ok]${NC} $*"; }
warning() { echo -e "${YELLOW}[warn]${NC} $*"; }
error() { echo -e "${RED}[err]${NC} $*" >&2; }

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DRY_RUN=0
VERBOSE=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [COMPONENTS...]

Dotfiles installer - extends system config, doesn't replace it.

Options:
    -n, --dry-run    Show what would be done without doing it
    -v, --verbose    Show detailed output
    -u, --uninstall  Remove dotfiles symlinks
    -h, --help       Show this help

Components (default: all):
    bash     Bash extensions (appends to ~/.bashrc)
    vim      Vim configuration
    neovim   Neovim configuration
    tmux     Tmux configuration
    git      Git config template
    utils    Utility scripts (~/.bin)
    inputrc  Readline configuration
    all      Install everything (default)

Examples:
    $(basename "$0")              # Install all components
    $(basename "$0") bash tmux    # Install only bash and tmux
    $(basename "$0") -n           # Dry run, show what would happen
    $(basename "$0") -u           # Uninstall (remove symlinks)
EOF
    exit 0
}

# Parse arguments
COMPONENTS=()
UNINSTALL=0

while [[ $# -gt 0 ]]; do
    case $1 in
        -n|--dry-run) DRY_RUN=1; shift ;;
        -v|--verbose) VERBOSE=1; shift ;;
        -u|--uninstall) UNINSTALL=1; shift ;;
        -h|--help) usage ;;
        -*) error "Unknown option: $1"; usage ;;
        *) COMPONENTS+=("$1"); shift ;;
    esac
done

# Default to all if no components specified
[[ ${#COMPONENTS[@]} -eq 0 ]] && COMPONENTS=(all)

should_install() {
    local component="$1"
    [[ " ${COMPONENTS[*]} " =~ " all " ]] || [[ " ${COMPONENTS[*]} " =~ " $component " ]]
}

run() {
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [dry-run] $*"
    else
        [[ $VERBOSE -eq 1 ]] && echo "  $*"
        "$@"
    fi
}

backup_and_link() {
    local src="$1"
    local dest="$2"

    # Remove existing symlink
    if [[ -L "$dest" ]]; then
        run rm -f "$dest"
    # Backup existing file/dir
    elif [[ -e "$dest" ]]; then
        run mv "$dest" "${dest}.backup.$(date +%Y%m%d)"
        warning "Backed up existing $dest"
    fi

    run ln -sf "$src" "$dest"
}

# ============================================================================
# Bash Configuration
# ============================================================================

install_bash() {
    info "Setting up bash extensions..."

    # Check if already installed
    if grep -q "# Dotfiles extensions" ~/.bashrc 2>/dev/null; then
        success "Bash extensions already installed"
        return 0
    fi

    # Append to system bashrc (extends, doesn't replace)
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [dry-run] Append dotfiles source to ~/.bashrc"
    else
        cat >> ~/.bashrc <<EOF

# Dotfiles extensions
[ -f "$DOTFILES_DIR/_bashrc" ] && source "$DOTFILES_DIR/_bashrc"
EOF
    fi

    success "Bash extensions added to ~/.bashrc"
}

uninstall_bash() {
    info "Removing bash extensions..."
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [dry-run] Remove dotfiles block from ~/.bashrc"
    else
        # Remove the dotfiles block from bashrc
        sed -i '/# Dotfiles extensions/,/source.*dotfiles\/_bashrc/d' ~/.bashrc 2>/dev/null || true
    fi
    success "Bash extensions removed"
}

# ============================================================================
# Vim Configuration
# ============================================================================

install_vim() {
    info "Setting up vim..."

    backup_and_link "$DOTFILES_DIR/_vimrc" ~/.vimrc
    [[ -d "$DOTFILES_DIR/_vim" ]] && backup_and_link "$DOTFILES_DIR/_vim" ~/.vim

    # Create directories for undo/backup/swap
    run mkdir -p ~/.vim/{undo,backup,swap}

    success "Vim configured"
}

uninstall_vim() {
    info "Removing vim config..."
    [[ -L ~/.vimrc ]] && run rm -f ~/.vimrc
    [[ -L ~/.vim ]] && run rm -f ~/.vim
    success "Vim config removed"
}

# ============================================================================
# Neovim Configuration
# ============================================================================

install_neovim() {
    info "Setting up neovim..."

    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    run mkdir -p "$config_dir"

    if [[ -d "$DOTFILES_DIR/_config/nvim" ]]; then
        backup_and_link "$DOTFILES_DIR/_config/nvim" "$config_dir/nvim"
        success "Neovim configured"
    else
        warning "Neovim config not found, skipping"
    fi
}

uninstall_neovim() {
    info "Removing neovim config..."
    local config_dir="${XDG_CONFIG_HOME:-$HOME/.config}"
    [[ -L "$config_dir/nvim" ]] && run rm -f "$config_dir/nvim"
    success "Neovim config removed"
}

# ============================================================================
# Tmux Configuration
# ============================================================================

install_tmux() {
    info "Setting up tmux..."
    backup_and_link "$DOTFILES_DIR/_tmuxrc" ~/.tmux.conf
    success "Tmux configured"
}

uninstall_tmux() {
    info "Removing tmux config..."
    [[ -L ~/.tmux.conf ]] && run rm -f ~/.tmux.conf
    success "Tmux config removed"
}

# ============================================================================
# Git Configuration
# ============================================================================

install_git() {
    info "Setting up git config..."

    if [[ -f ~/.gitconfig ]] && ! grep -q "# Dotfiles template" ~/.gitconfig 2>/dev/null; then
        warning "~/.gitconfig exists, not overwriting (copy manually from $DOTFILES_DIR/_gitconfig)"
        return 0
    fi

    # Copy (not symlink) so user can customize
    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [dry-run] Copy _gitconfig to ~/.gitconfig"
    else
        cp "$DOTFILES_DIR/_gitconfig" ~/.gitconfig
        echo "# Dotfiles template - customize [user] section" >> ~/.gitconfig
    fi

    success "Git config installed (edit ~/.gitconfig to set name/email)"
}

uninstall_git() {
    info "Git config is a copy, not a symlink. Remove manually if needed."
}

# ============================================================================
# Inputrc Configuration
# ============================================================================

install_inputrc() {
    info "Setting up inputrc..."
    if [[ -f "$DOTFILES_DIR/_inputrc" ]]; then
        backup_and_link "$DOTFILES_DIR/_inputrc" ~/.inputrc
        success "Inputrc configured"
    else
        warning "Inputrc not found, skipping"
    fi
}

uninstall_inputrc() {
    info "Removing inputrc..."
    [[ -L ~/.inputrc ]] && run rm -f ~/.inputrc
    success "Inputrc removed"
}

# ============================================================================
# Utilities
# ============================================================================

install_utils() {
    info "Setting up utilities..."

    if [[ -d "$DOTFILES_DIR/_bin" ]]; then
        backup_and_link "$DOTFILES_DIR/_bin" ~/.bin
        # Make scripts executable
        run chmod +x "$DOTFILES_DIR/_bin"/* 2>/dev/null || true
        success "Utilities installed to ~/.bin"
    else
        warning "No _bin directory found"
    fi
}

uninstall_utils() {
    info "Removing utilities..."
    [[ -L ~/.bin ]] && run rm -f ~/.bin
    success "Utilities removed"
}

# ============================================================================
# Local Config Template
# ============================================================================

create_local() {
    info "Creating local config template..."

    if [[ -f ~/.bashrc.local ]]; then
        success "~/.bashrc.local already exists"
        return 0
    fi

    if [[ $DRY_RUN -eq 1 ]]; then
        echo "  [dry-run] Create ~/.bashrc.local template"
    else
        cat > ~/.bashrc.local <<'EOF'
# Local machine-specific bash configuration
# This file is not tracked by git

# Example: Custom PATH
# export PATH="$HOME/mybin:$PATH"

# Example: Environment variables
# export EDITOR=vim
# export BROWSER=firefox

# Example: Local aliases
# alias myproject='cd ~/code/project'

# Example: Directory bookmarks (use with mark/jump/marks)
# mark work
# mark docs
EOF
        chmod 600 ~/.bashrc.local
    fi

    success "Created ~/.bashrc.local (edit for local settings)"
}

# ============================================================================
# Main Installation
# ============================================================================

do_install() {
    echo
    info "Dotfiles Installer"
    [[ $DRY_RUN -eq 1 ]] && warning "DRY RUN - no changes will be made"
    echo

    # Install selected components
    should_install bash && install_bash
    should_install vim && install_vim
    should_install neovim && install_neovim
    should_install tmux && install_tmux
    should_install git && install_git
    should_install inputrc && install_inputrc
    should_install utils && install_utils

    # Always create local config template
    should_install bash && create_local

    echo
    success "Installation complete!"
    echo
    info "Next steps:"
    echo "  1. Restart shell or run: source ~/.bashrc"
    echo "  2. Edit ~/.bashrc.local for machine-specific settings"
    echo "  3. Edit ~/.gitconfig to set your name and email"
    echo
}

do_uninstall() {
    echo
    info "Dotfiles Uninstaller"
    [[ $DRY_RUN -eq 1 ]] && warning "DRY RUN - no changes will be made"
    echo

    should_install bash && uninstall_bash
    should_install vim && uninstall_vim
    should_install neovim && uninstall_neovim
    should_install tmux && uninstall_tmux
    should_install git && uninstall_git
    should_install inputrc && uninstall_inputrc
    should_install utils && uninstall_utils

    echo
    success "Uninstall complete!"
    echo
}

main() {
    if [[ $UNINSTALL -eq 1 ]]; then
        do_uninstall
    else
        do_install
    fi
}

main
