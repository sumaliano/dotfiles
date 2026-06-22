#!/usr/bin/env bash
# install.sh — Link dotfile components (stow when available, manual fallback otherwise)
# Usage: ./scripts/install.sh [component ...]   (no args = all)

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW=$(command -v stow 2>/dev/null || true)

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { printf "\n${BOLD}==> %s${NC}\n" "$*"; }
ok()   { printf "  ${GREEN}[ok]${NC}   %s\n" "$*"; }
warn() { printf "  ${YELLOW}[warn]${NC} %s\n" "$*"; }

# Create a symlink, backing up any pre-existing file/dir at the destination
link_file() {
    local src="$1" dest="$2"
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -e "$dest" ]; then
        local bak; bak="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up $(basename "$dest") → $bak"
        mv "$dest" "$bak"
    fi
    mkdir -p "$(dirname "$dest")"
    ln -sfn "$src" "$dest"
    ok "$(basename "$dest")"
}

# Use stow if available; otherwise call the link_<pkg> fallback for that package
stow_pkg() {
    local pkg="$1"
    if [ -n "$STOW" ]; then
        stow --dotfiles -t "$HOME" -d "$DOTFILES" "$pkg"
        ok "stow $pkg"
    else
        "link_$pkg"
    fi
}

# ── Manual link fallbacks (used only when stow is absent) ──────────────────
# Each function replicates what stow --dotfiles would do for that package.

link_bash()    { link_file "$DOTFILES/bash/dot-dir_colors"             "$HOME/.dir_colors"; }
link_vim()     {
    link_file "$DOTFILES/vim/dot-vimrc" "$HOME/.vimrc"
    link_file "$DOTFILES/vim/dot-vim"   "$HOME/.vim"
}
link_nvim()    { link_file "$DOTFILES/nvim/dot-config/nvim"            "$HOME/.config/nvim"; }
link_tmux()    { link_file "$DOTFILES/tmux/dot-tmux.conf"              "$HOME/.tmux.conf"; }
link_git()     { link_file "$DOTFILES/git/dot-gitignore_global"        "$HOME/.gitignore_global"; }
link_utils() {
    local dest_dir="$HOME/.local/bin"
    mkdir -p "$dest_dir"
    for src in "$DOTFILES/utils/dot-bin"/*; do
        [ -f "$src" ] || continue
        link_file "$src" "$dest_dir/$(basename "$src")"
    done
}
link_fonts()   { link_file "$DOTFILES/fonts/dot-local/share/fonts"     "$HOME/.local/share/fonts"; }
link_inputrc() { link_file "$DOTFILES/inputrc/dot-inputrc"             "$HOME/.inputrc"; }
link_joshuto() { link_file "$DOTFILES/joshuto/dot-config/joshuto"      "$HOME/.config/joshuto"; }
link_yazi()    { link_file "$DOTFILES/yazi/dot-config/yazi"            "$HOME/.config/yazi"; }

# ── Component installers ────────────────────────────────────────────────────

install_bash() {
    info "Bash"
    stow_pkg bash
    if ! grep -q "# BEGIN DOTFILES" "$HOME/.bashrc" 2>/dev/null; then
        printf '\n# BEGIN DOTFILES\n[ -f "%s/bash/dot-bashrc_ext" ] && source "%s/bash/dot-bashrc_ext"\n# END DOTFILES\n' \
            "$DOTFILES" "$DOTFILES" >> "$HOME/.bashrc"
        ok "Wired into ~/.bashrc"
    else
        ok "~/.bashrc already configured"
    fi
    if [ ! -f "$HOME/.bashrc.local" ]; then
        printf '# Local machine-specific overrides\n# This file is ignored by git\n' > "$HOME/.bashrc.local"
        ok "Created ~/.bashrc.local"
    fi
}

install_vim() {
    info "Vim"
    mkdir -p "$DOTFILES/vim/dot-vim/undo" "$DOTFILES/vim/dot-vim/backup" "$DOTFILES/vim/dot-vim/swap"
    stow_pkg vim
}

install_neovim() {
    info "Neovim"
    stow_pkg nvim
}

install_tmux() {
    info "Tmux"
    stow_pkg tmux
}

install_git() {
    info "Git"
    # Link only the global ignore file. We deliberately do NOT stow the whole
    # git package — that would symlink ~/.gitconfig into the repo. Instead we
    # layer our shared config in via [include], preserving the user's own
    # ~/.gitconfig (identity, credentials, machine-specific settings).
    link_git

    # Safety: if a previous install symlinked ~/.gitconfig into this repo,
    # de-link it so `git config` below doesn't write through into the repo file.
    if [ -L "$HOME/.gitconfig" ] && readlink "$HOME/.gitconfig" | grep -q "$DOTFILES"; then
        rm "$HOME/.gitconfig"
    fi

    local target="$DOTFILES/git/dot-gitconfig"
    if git config --global --get-all include.path 2>/dev/null | grep -qxF "$target"; then
        ok "~/.gitconfig already includes dotfiles config"
    else
        git config --global --add include.path "$target"
        ok "Wired dotfiles config into ~/.gitconfig (via [include])"
    fi
}

install_utils() {
    info "Utils"
    chmod +x "$DOTFILES/utils/dot-bin/"* 2>/dev/null || true
    link_utils
}

install_fonts() {
    info "Fonts"
    stow_pkg fonts
    if command -v fc-cache &>/dev/null; then
        fc-cache -f
        ok "Font cache refreshed"
    fi
}

install_inputrc() {
    info "Inputrc"
    stow_pkg inputrc
}

install_joshuto() {
    info "Joshuto"
    stow_pkg joshuto
}

install_yazi() {
    info "Yazi"
    stow_pkg yazi
}

# ── Vendor tool install ──────────────────────────────────────────────────────
# Maps tool name → dotfile component (runs install_<component> for config).
# CONFIG_ONLY tools have no vendor binary — system binary is assumed present.

declare -A TOOL_COMPONENT=(
    [nvim]="neovim"
    [vim]="vim"
    [tmux]="tmux"
    [joshuto]="joshuto"
    [yazi]="yazi"
)

install_tool() {
    local tool="$1"
    local arch; arch=$(uname -m)
    local src="$DOTFILES/vendor/linux-$arch/$tool"

    info "Tool: $tool"

    # Binary
    if [ -f "$src" ]; then
        mkdir -p "$HOME/.local/bin"
        cp "$src" "$HOME/.local/bin/$tool"
        chmod +x "$HOME/.local/bin/$tool"
        ok "$tool  →  ~/.local/bin/$tool"
        warn "Run 'hash -r' (or open a new terminal) to refresh the shell's command cache"
    else
        warn "Binary not found in vendor/linux-$arch/ — run 'make vendor' first"
    fi

    # Config — reuse the existing component installer when one exists
    local component="${TOOL_COMPONENT[$tool]:-}"
    if [ -n "$component" ] && declare -f "install_$component" &>/dev/null; then
        "install_$component"
    fi
}

# ── Entry point ─────────────────────────────────────────────────────────────

ALL=(bash vim neovim tmux git utils fonts inputrc joshuto yazi)

# --tool <name>[,name] installs vendor binaries + their configs locally
if [ "${1:-}" = "--tool" ]; then
    shift
    [ $# -gt 0 ] || { printf "${RED}Error:${NC} --tool requires a name (e.g. --tool nvim)\n" >&2; exit 1; }
    arg="$1"

    # Expand 'all' to every binary present in the local vendor directory
    if [ "$arg" = "all" ]; then
        vendor_dir="$DOTFILES/vendor/linux-$(uname -m)"
        [ -d "$vendor_dir" ] || { printf "${RED}Error:${NC} vendor/linux-$(uname -m)/ not found — run 'make vendor'\n" >&2; exit 1; }
        arg=$(ls "$vendor_dir" | tr '\n' ',' | sed 's/,$//')
        [ -n "$arg" ] || { printf "${RED}Error:${NC} vendor/linux-$(uname -m)/ is empty — run 'make vendor'\n" >&2; exit 1; }
    fi

    IFS=',' read -ra tools <<< "$arg"
    for t in "${tools[@]}"; do
        install_tool "${t// /}"
    done
    printf "\n${GREEN}Done!${NC}\n"
    exit 0
fi

# No args — or the explicit keyword 'all' — means every config component.
if [ $# -eq 0 ] || { [ $# -eq 1 ] && [ "$1" = "all" ]; }; then
    targets=("${ALL[@]}")
else
    targets=("$@")
fi

for t in "${targets[@]}"; do
    # User-facing name → internal component function (e.g. nvim → neovim)
    comp="$t"; [ "$t" = "nvim" ] && comp="neovim"
    if declare -f "install_$comp" &>/dev/null; then
        "install_$comp"
    else
        printf "${RED}Error:${NC} Unknown component '%s'\n" "$t" >&2
        printf "Available: bash vim nvim tmux git utils fonts inputrc joshuto yazi\n" >&2
        exit 1
    fi
done

printf "\n${GREEN}Done!${NC}\n"
