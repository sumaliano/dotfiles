#!/usr/bin/env bash
# deploy.sh — Deploy vendor binaries + their configs to a remote server
#
# Usage:
#   ./scripts/deploy.sh user@host --tool nvim
#   ./scripts/deploy.sh user@host --tool nvim,fzf,bat

set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# ── Helpers ───────────────────────────────────────────────────────────────────

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
info() { printf "\n${BOLD}==> %s${NC}\n" "$*"; }
ok()   { printf "  ${GREEN}[ok]${NC}   %s\n" "$*"; }
warn() { printf "  ${YELLOW}[warn]${NC} %s\n" "$*"; }
die()  { printf "${RED}Error:${NC} %s\n" "$*" >&2; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────

REMOTE="${1:-}"
shift || true

TOOLS=""

while [ $# -gt 0 ]; do
    case "$1" in
        --tool)
            shift; [ $# -gt 0 ] || die "--tool requires a value (e.g. --tool nvim)"
            TOOLS="$1" ;;
        --tool=*) TOOLS="${1#*=}" ;;
        *) printf "Unknown option: %s\n" "$1" >&2; exit 1 ;;
    esac
    shift
done

[ -z "$REMOTE" ] && die "Usage: $(basename "$0") [user@]host --tool name[,name]"
[ -z "$TOOLS"  ] && die "Specify at least one tool: --tool nvim  or  --tool nvim,fzf,bat"
command -v rsync &>/dev/null || die "rsync is required"
command -v ssh   &>/dev/null || die "ssh is required"

# ── Config map: tool → "source|remote_dest" pairs ────────────────────────────

declare -A TOOL_CONFIG=(
    [nvim]="nvim/dot-config/nvim|~/.config/nvim"
    [vim]="vim/dot-vimrc|~/.vimrc vim/dot-vim|~/.vim"
    [tmux]="tmux/dot-tmux.conf|~/.tmux.conf"
)

# ── Connect ───────────────────────────────────────────────────────────────────

info "Connecting to $REMOTE..."
REMOTE_ARCH=$(ssh "$REMOTE" uname -m 2>/dev/null) || die "Cannot connect to $REMOTE"
[ -z "$REMOTE_ARCH" ] && die "Could not detect remote architecture"
ok "Connected  (arch: linux-$REMOTE_ARCH)"

VENDOR_DIR="$DOTFILES/vendor/linux-$REMOTE_ARCH"
ssh "$REMOTE" 'mkdir -p ~/.local/bin'

# ── Deploy each tool ──────────────────────────────────────────────────────────

# Expand 'all' to every binary present in the vendor directory
if [ "$TOOLS" = "all" ]; then
    [ -d "$VENDOR_DIR" ] || die "vendor/linux-$REMOTE_ARCH/ not found — run 'make vendor' first"
    TOOLS=$(ls "$VENDOR_DIR" | tr '\n' ',' | sed 's/,$//')
    [ -n "$TOOLS" ] || die "vendor/linux-$REMOTE_ARCH/ is empty — run 'make vendor' first"
fi

IFS=',' read -ra tool_list <<< "$TOOLS"
for tool in "${tool_list[@]}"; do
    tool="${tool// /}"
    info "Deploying: $tool"

    # Binary
    src="$VENDOR_DIR/$tool"
    if [ -f "$src" ]; then
        rsync -az --chmod=ugo+x "$src" "$REMOTE:~/.local/bin/$tool"
        ok "$tool  →  ~/.local/bin/$tool"
    else
        warn "Binary not in vendor/linux-$REMOTE_ARCH/ — run 'make vendor' first"
    fi

    # Config
    mapping="${TOOL_CONFIG[$tool]:-}"
    for pair in $mapping; do
        local_src="$DOTFILES/${pair%%|*}"
        remote_dest="${pair##*|}"
        if [ -e "$local_src" ]; then
            ssh "$REMOTE" "mkdir -p \"\$(dirname $remote_dest)\""
            rsync -az "$local_src" "$REMOTE:$remote_dest"
            ok "config  →  $remote_dest"
        fi
    done
done

printf "\n${GREEN}${BOLD}Done!${NC}\n\n"
