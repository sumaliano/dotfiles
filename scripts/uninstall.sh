#!/usr/bin/env bash
# uninstall.sh — Remove dotfile configs or vendor binaries, locally or remotely
#
# Mirrors install.sh / deploy.sh: one axis is what (configs vs binaries), the
# other is where (local vs --host remote).
#
# Usage:
#   ./scripts/uninstall.sh --configs --tool nvim            # remove nvim config locally
#   ./scripts/uninstall.sh --bins    --tool nvim            # remove nvim binary locally
#   ./scripts/uninstall.sh --configs --tool all             # remove all configs locally
#   ./scripts/uninstall.sh --bins    --host u@h --tool nvim # remove nvim binary on remote

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STOW=$(command -v stow 2>/dev/null || true)
HOST=""
TOOLS=""
MODE=""   # configs | bins

while [ $# -gt 0 ]; do
    case "$1" in
        --configs) MODE="configs" ;;
        --bins)    MODE="bins" ;;
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

[ -n "$MODE" ] || die "internal: pass --configs or --bins"

# Config destinations, keyed by component. Paths use remote-style ~ so the same
# map drives both local (after $HOME expansion) and remote (ssh-side) removal.
declare -A CONFIG_PATHS=(
    [bash]="~/.bashrc_ext ~/.dir_colors"
    [vim]="~/.vimrc ~/.vim"
    [nvim]="~/.config/nvim"
    [tmux]="~/.tmux.conf"
    [git]="~/.gitignore_global ~/.gitconfig.dotfiles"
    [inputrc]="~/.inputrc"
    [joshuto]="~/.config/joshuto"
    [yazi]="~/.config/yazi"
    [fonts]="~/.local/share/fonts"
)

# What "all" means, per mode and location.
CONFIG_ALL_LOCAL="bash vim nvim tmux git utils fonts inputrc joshuto yazi"
CONFIG_ALL_REMOTE="bash git inputrc nvim vim tmux joshuto yazi"

vendor_all() {
    local vd="$DOTFILES/vendor/linux-$(uname -m)"
    [ -d "$vd" ] || die "vendor/linux-$(uname -m)/ not found — run 'make vendor' first"
    local list; list=$(ls "$vd" | tr '\n' ' ')
    [ -n "$list" ] || die "vendor/linux-$(uname -m)/ is empty"
    printf '%s' "$list"
}

# ── Resolve the name list ─────────────────────────────────────────────────────

if [ -z "$TOOLS" ] || [ "$TOOLS" = "all" ]; then
    if [ "$MODE" = "bins" ]; then
        names=$(vendor_all)
    elif [ -n "$HOST" ]; then
        names="$CONFIG_ALL_REMOTE"
    else
        names="$CONFIG_ALL_LOCAL"
    fi
else
    names="${TOOLS//,/ }"
fi

# ── Binary removal ────────────────────────────────────────────────────────────

remove_bin() {
    local tool="$1"
    if [ -n "$HOST" ]; then
        ssh "$HOST" "rm -f ~/.local/bin/$tool" && ok "$tool  ←  ~/.local/bin/$tool (on $HOST)"
    elif [ -f "$HOME/.local/bin/$tool" ]; then
        rm -f "$HOME/.local/bin/$tool"; ok "$tool  ←  ~/.local/bin/$tool"
    else
        warn "$tool not found in ~/.local/bin/"
    fi
}

# ── Config removal ────────────────────────────────────────────────────────────

# utils are individual symlinks we own in ~/.local/bin — remove just those.
remove_utils_local() {
    for src in "$DOTFILES/utils/dot-bin"/*; do
        [ -f "$src" ] || continue
        local target="$HOME/.local/bin/$(basename "$src")"
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$src" ]; then
            rm -f "$target"; ok "config  ←  $target"
        fi
    done
}

remove_config_local() {
    local comp="$1"
    case "$comp" in
        utils) remove_utils_local; return ;;
    esac
    for dest in ${CONFIG_PATHS[$comp]:-}; do
        dest="${dest/#\~/$HOME}"
        if [ -e "$dest" ] || [ -L "$dest" ]; then
            rm -rf "$dest"; ok "config  ←  $dest"
        fi
    done
    if [ "$comp" = "bash" ]; then
        sed -i '/# BEGIN DOTFILES/,/# END DOTFILES/d' "$HOME/.bashrc" 2>/dev/null || true
        ok "unwired ~/.bashrc"
    fi
    if [ "$comp" = "git" ]; then
        local frag="$DOTFILES/git/dot-gitconfig"
        local re="^$(printf '%s' "$frag" | sed 's/[.[*^$\\]/\\&/g')\$"
        git config --global --unset-all include.path "$re" 2>/dev/null || true
        ok "removed dotfiles include from ~/.gitconfig"
    fi
}

remove_config_remote() {
    local comp="$1"
    local paths="${CONFIG_PATHS[$comp]:-}"
    if [ -n "$paths" ]; then
        # shellcheck disable=SC2029
        ssh "$HOST" "rm -rf $paths && echo '  removed: $paths'"
    fi
    if [ "$comp" = "bash" ]; then
        ssh "$HOST" "sed -i '/# BEGIN DOTFILES/,/# END DOTFILES/d' ~/.bashrc 2>/dev/null || true"
        ok "unwired ~/.bashrc"
    fi
    if [ "$comp" = "git" ]; then
        ssh "$HOST" bash <<'EOF'
inc="$HOME/.gitconfig.dotfiles"
re="^$(printf '%s' "$inc" | sed 's/[.[*^$\\]/\\&/g')\$"
git config --global --unset-all include.path "$re" 2>/dev/null || true
EOF
        ok "removed dotfiles include from ~/.gitconfig"
    fi
}

# ── Drive it ──────────────────────────────────────────────────────────────────

[ -n "$HOST" ] && command -v ssh &>/dev/null || [ -z "$HOST" ] || die "ssh is required"

# Fast path for local "remove all configs" via stow's own de-link.
if [ "$MODE" = "configs" ] && [ -z "$HOST" ] && [ -n "$STOW" ] \
   && { [ -z "$TOOLS" ] || [ "$TOOLS" = "all" ]; }; then
    info "Removing all dotfile configs"
    stow --dotfiles -D -t "$HOME" -d "$DOTFILES" \
        bash vim nvim tmux git fonts inputrc joshuto yazi 2>/dev/null || true
    remove_utils_local
    remove_config_local bash   # unwire ~/.bashrc
    remove_config_local git    # drop [include]
    printf "\n${GREEN}Done!${NC}\n"
    exit 0
fi

for name in $names; do
    name="${name// /}"
    [ -n "$name" ] || continue
    if [ "$MODE" = "bins" ]; then
        info "Removing binary: $name${HOST:+ (on $HOST)}"
        remove_bin "$name"
    else
        info "Removing config: $name${HOST:+ (on $HOST)}"
        if [ -n "$HOST" ]; then remove_config_remote "$name"; else remove_config_local "$name"; fi
    fi
done

printf "\n${GREEN}Done!${NC}\n"
