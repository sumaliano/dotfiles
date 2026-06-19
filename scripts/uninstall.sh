#!/usr/bin/env bash
# uninstall.sh — Remove dotfile symlinks or vendor tools, locally or remotely
#
# Usage:
#   ./scripts/uninstall.sh                           # remove all dotfile symlinks locally
#   ./scripts/uninstall.sh --tool nvim               # remove vendor tool locally
#   ./scripts/uninstall.sh --tool all                # remove all vendor tools locally
#   ./scripts/uninstall.sh --host u@h --tool nvim    # remove vendor tool on remote
#   ./scripts/uninstall.sh --host u@h --tool all     # remove all vendor tools on remote

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW=$(command -v stow 2>/dev/null || true)
HOST=""
TOOLS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --host)    shift; HOST="${1:-}" ;;
        --host=*)  HOST="${1#--host=}" ;;
        --tool)    shift; TOOLS="${1:-}" ;;
        --tool=*)  TOOLS="${1#--tool=}" ;;
        *) printf "Unknown option: %s\n" "$1" >&2; exit 1 ;;
    esac
    shift
done

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
ok()   { printf "  ${GREEN}[ok]${NC}   %s\n" "$*"; }
warn() { printf "  ${YELLOW}[warn]${NC} %s\n" "$*"; }
info() { printf "\n${BOLD}==> %s${NC}\n" "$*"; }
die()  { printf "${RED}Error:${NC} %s\n" "$*" >&2; exit 1; }

# ── Config map ────────────────────────────────────────────────────────────────

declare -A TOOL_CONFIG=(
    [nvim]="~/.config/nvim"
    [vim]="~/.vimrc ~/.vim"
    [tmux]="~/.tmux.conf"
    [joshuto]="~/.config/joshuto"
    [git]="~/.gitignore_global ~/.gitconfig.dotfiles"
    [inputrc]="~/.inputrc"
    [bash]="~/.bashrc_ext ~/.dir_colors"
)

# ── Remote mode ───────────────────────────────────────────────────────────────

if [ -n "$HOST" ]; then
    [ -n "$TOOLS" ] || die "Remote clean requires --tool (e.g. --tool nvim or --tool all)"
    command -v ssh &>/dev/null || die "ssh is required"

    # Expand 'all' from the local vendor directory
    if [ "$TOOLS" = "all" ]; then
        vendor_dir="$DOTFILES/vendor/linux-$(uname -m)"
        [ -d "$vendor_dir" ] || die "vendor/linux-$(uname -m)/ not found — run 'make vendor' first"
        TOOLS=$(ls "$vendor_dir" | tr '\n' ',' | sed 's/,$//')
        [ -n "$TOOLS" ] || die "vendor/linux-$(uname -m)/ is empty"
    fi

    IFS=',' read -ra tool_list <<< "$TOOLS"
    for tool in "${tool_list[@]}"; do
        tool="${tool// /}"
        info "Removing $tool from $HOST"

        # Build removal command using remote-side ~ (not local $HOME)
        paths="~/.local/bin/$tool"
        for p in ${TOOL_CONFIG[$tool]:-}; do
            paths="$paths $p"
        done

        # shellcheck disable=SC2029
        ssh "$HOST" "rm -rf $paths && echo '  removed: $paths'"

        # bash also injects a source block into ~/.bashrc — strip it
        if [ "$tool" = "bash" ]; then
            ssh "$HOST" "sed -i '/# BEGIN DOTFILES/,/# END DOTFILES/d' ~/.bashrc 2>/dev/null || true"
            ok "unwired ~/.bashrc"
        fi

        # git layers itself in via [include] — drop only our include entry
        if [ "$tool" = "git" ]; then
            ssh "$HOST" bash <<'EOF'
inc="$HOME/.gitconfig.dotfiles"
re="^$(printf '%s' "$inc" | sed 's/[.[*^$\\]/\\&/g')\$"
git config --global --unset-all include.path "$re" 2>/dev/null || true
EOF
            ok "removed dotfiles include from ~/.gitconfig"
        fi
    done

    printf "\n${GREEN}Done!${NC}\n"
    exit 0
fi

# ── Local tool mode ───────────────────────────────────────────────────────────

if [ -n "$TOOLS" ]; then
    # Expand 'all' from the vendor directory
    if [ "$TOOLS" = "all" ]; then
        vendor_dir="$DOTFILES/vendor/linux-$(uname -m)"
        [ -d "$vendor_dir" ] || die "vendor/linux-$(uname -m)/ not found — run 'make vendor' first"
        TOOLS=$(ls "$vendor_dir" | tr '\n' ',' | sed 's/,$//')
        [ -n "$TOOLS" ] || die "vendor/linux-$(uname -m)/ is empty"
    fi

    IFS=',' read -ra tool_list <<< "$TOOLS"
    for tool in "${tool_list[@]}"; do
        tool="${tool// /}"
        info "Removing: $tool"

        bin="$HOME/.local/bin/$tool"
        if [ -f "$bin" ]; then
            rm -f "$bin"
            ok "$tool  ←  ~/.local/bin/$tool"
        else
            warn "$tool not found in ~/.local/bin/"
        fi

        for dest in ${TOOL_CONFIG[$tool]:-}; do
            dest="${dest/#\~/$HOME}"
            if [ -e "$dest" ] || [ -L "$dest" ]; then
                rm -rf "$dest"
                ok "config  ←  $dest"
            fi
        done

        # bash also injects a source block into ~/.bashrc — strip it
        if [ "$tool" = "bash" ]; then
            sed -i '/# BEGIN DOTFILES/,/# END DOTFILES/d' "$HOME/.bashrc" 2>/dev/null || true
            ok "unwired ~/.bashrc"
        fi

        # git layers itself in via [include] — drop only our include entry
        if [ "$tool" = "git" ]; then
            gitfrag="$DOTFILES/git/dot-gitconfig"
            gre="^$(printf '%s' "$gitfrag" | sed 's/[.[*^$\\]/\\&/g')\$"
            git config --global --unset-all include.path "$gre" 2>/dev/null || true
            ok "removed dotfiles include from ~/.gitconfig"
        fi
    done

    printf "\n${GREEN}Done!${NC}\n"
    exit 0
fi

# ── Local dotfiles mode (default) ─────────────────────────────────────────────

info "Removing dotfile symlinks"

if [ -n "$STOW" ]; then
    stow --dotfiles -D -t "$HOME" -d "$DOTFILES" \
        bash vim nvim tmux git fonts inputrc joshuto 2>/dev/null || true
    ok "Removed stow links"
else
    for f in .dir_colors .vimrc .tmux.conf .gitignore_global .inputrc \
              .vim ".config/nvim" ".config/joshuto" ".local/share/fonts"; do
        if [ -L "$HOME/$f" ]; then
            rm -f "$HOME/$f"
            ok "Removed $f"
        fi
    done
fi

# Utils: remove only the symlinks we own in ~/.local/bin/
for src in "$DOTFILES/utils/dot-bin"/*; do
    [ -f "$src" ] || continue
    name=$(basename "$src")
    target="$HOME/.local/bin/$name"
    if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
        rm -f "$target"
        ok "Removed $name"
    fi
done

sed -i '/# BEGIN DOTFILES/,/# END DOTFILES/d' "$HOME/.bashrc" 2>/dev/null || true
ok "Cleaned ~/.bashrc"

# Remove our [include] from ~/.gitconfig — leave the user's own config intact
gitfrag="$DOTFILES/git/dot-gitconfig"
if git config --global --get-all include.path 2>/dev/null | grep -qxF "$gitfrag"; then
    gre="^$(printf '%s' "$gitfrag" | sed 's/[.[*^$\\]/\\&/g')\$"
    git config --global --unset-all include.path "$gre" 2>/dev/null || true
    ok "Removed dotfiles include from ~/.gitconfig"
fi

printf "\n${GREEN}Done!${NC}\n"
