#!/usr/bin/env bash
# status.sh — Show installation status locally or on a remote server
#
# Usage:
#   ./scripts/status.sh
#   ./scripts/status.sh --host user@server

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOST=""

while [ $# -gt 0 ]; do
    case "$1" in
        --host)   shift; HOST="${1:-}" ;;
        --host=*) HOST="${1#--host=}" ;;
        *) printf "Unknown option: %s\n" "$1" >&2; exit 1 ;;
    esac
    shift
done

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
installed() { printf "  ${GREEN}[installed]${NC} %s\n" "$*"; }
missing()   { printf "  ${RED}[missing]  ${NC} %s\n" "$*"; }

# ── Remote ────────────────────────────────────────────────────────────────────

if [ -n "$HOST" ]; then
    printf "${BOLD}Status: $HOST${NC}\n\n"
    # Self-contained: no remote scripts needed
    ssh "$HOST" bash <<'REMOTE'
GREEN='\033[0;32m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
ok()      { printf "  ${GREEN}[installed]${NC} %s\n" "$*"; }
missing() { printf "  ${RED}[missing]  ${NC} %s\n" "$*"; }

printf "${BOLD}Vendor tools (~/.local/bin/):${NC}\n"
for tool in nvim vim tmux fzf fd bat rg eza delta btop yazi ya joshuto; do
    [ -f "$HOME/.local/bin/$tool" ] && ok "$tool" || missing "$tool"
done

printf "\n${BOLD}Dotfiles:${NC}\n"
[ -d "$HOME/dotfiles" ] \
    && ok      "repo  (~/dotfiles/)" \
    || missing "repo  (~/dotfiles/)"
grep -q "# BEGIN DOTFILES" "$HOME/.bashrc" 2>/dev/null \
    && ok      "bashrc wired" \
    || missing "bashrc wired"
REMOTE
    exit 0
fi

# ── Local ─────────────────────────────────────────────────────────────────────

KNOWN_TOOLS=(nvim vim tmux fzf fd bat rg eza delta btop yazi ya joshuto)

printf "${BOLD}Vendor tools (~/.local/bin/):${NC}\n"
for tool in "${KNOWN_TOOLS[@]}"; do
    [ -f "$HOME/.local/bin/$tool" ] && installed "$tool" || missing "$tool"
done

printf "\n${BOLD}Dotfiles:${NC}\n"
grep -q "# BEGIN DOTFILES" "$HOME/.bashrc" 2>/dev/null \
    && installed "Bash"    || missing "Bash"
[ -e "$HOME/.vimrc" ] \
    && installed "Vim"     || missing "Vim"
[ -e "$HOME/.config/nvim/init.lua" ] \
    && installed "Neovim"  || missing "Neovim"
[ -e "$HOME/.tmux.conf" ] \
    && installed "Tmux"    || missing "Tmux"
[ -e "$HOME/.gitignore_global" ] \
    && installed "Git"     || missing "Git"
find "$HOME/.local/bin" -maxdepth 1 -type l -lname "*/dotfiles/utils/dot-bin/*" 2>/dev/null | grep -q . \
    && installed "Utils"   || missing "Utils"
[ -e "$HOME/.local/share/fonts/Terminus" ] \
    && installed "Fonts"   || missing "Fonts"
[ -e "$HOME/.inputrc" ] \
    && installed "Inputrc" || missing "Inputrc"

printf "\n"

VENDOR_DIR="$DOTFILES/vendor/linux-$(uname -m)"
if [ -d "$VENDOR_DIR" ]; then
    count=$(ls "$VENDOR_DIR" 2>/dev/null | wc -l)
    printf "${BOLD}Vendor cache:${NC} %d of %d binaries in vendor/linux-$(uname -m)/\n" \
        "$count" "${#KNOWN_TOOLS[@]}"
else
    printf "  ${YELLOW}[empty]${NC}   vendor/linux-$(uname -m)/ — run 'make vendor'\n"
fi
