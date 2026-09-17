#!/usr/bin/env bash
# status.sh — what's installed, locally or on a remote.
#
#   status.sh [--host u@h]
#
# Locally a component counts as installed only when every one of its targets
# is a symlink of ours (plus its check_ hook, if any) — a foreign file at the
# same path shows as partial, not installed. Remote configs are copies, so
# there existence is all that can be checked.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

HOST=""
while [ $# -gt 0 ]; do
    case "$1" in
        --host)   shift; HOST="${1:-}" ;;
        --host=*) HOST="${1#--host=}" ;;
        *)        die "Unknown option: $1" ;;
    esac
    shift
done

installed() { printf "  ${GREEN}[installed]${NC} %s\n" "$*"; }
partial()   { printf "  ${YELLOW}[partial]${NC}   %s\n" "$*"; }
missing()   { printf "  ${RED}[missing]${NC}   %s\n" "$*"; }

# ── Remote ───────────────────────────────────────────────────────────────────
# One ssh round trip: the lists are handed to a remote sh as two arguments.
# ssh joins its arguments into one command line that the far shell re-splits,
# so they're single-quoted into the string (neither list can contain a quote).

if [ -n "$HOST" ]; then
    spec=""   # "comp=~/path ~/path;comp=…" — every deployable component and its targets
    for comp in $COMPONENTS; do
        in_list "$comp" "${LOCAL_ONLY[@]}" && continue
        paths=""
        while read -r src; do [ -n "$src" ] && paths+=" $(target_of "$src")"; done < <(sources_of "$comp")
        [ "$comp" = git ]  && paths+=' ~/.gitconfig.dotfiles'
        [ "$comp" = bash ] && paths+=' ~/.bashrc'   # checked for the wiring block, not existence
        spec+="$comp=$paths;"
    done
    printf "${BOLD}Status: $HOST${NC}\n"
    ssh -q "$HOST" "sh -s -- '${TOOL_NAMES[*]}' '$spec'" <<'REMOTE'
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; BOLD='\033[1m'; NC='\033[0m'
C="${XDG_CONFIG_HOME:-$HOME/.config}"
printf "\n${BOLD}Configs:${NC}\n"
printf '%s\n' "$2" | tr ';' '\n' | while IFS='=' read -r comp paths; do
    [ -n "$comp" ] || continue
    have=0; n=0
    for p in $paths; do
        n=$((n + 1))
        case "$p" in "~/.config/"*) p="$C/${p#\~/.config/}" ;; *) p="$HOME/${p#\~/}" ;; esac   # \~ : no tilde expansion in the pattern
        case "$p" in
            */.bashrc) grep -q "# BEGIN DOTFILES" "$p" 2>/dev/null && have=$((have + 1)) ;;
            *)         [ -e "$p" ] && have=$((have + 1)) ;;
        esac
    done
    if   [ "$have" -eq "$n" ]; then printf "  ${GREEN}[installed]${NC} %s\n" "$comp"
    elif [ "$have" -eq 0 ];    then printf "  ${RED}[missing]${NC}   %s\n" "$comp"
    else printf "  ${YELLOW}[partial]${NC}   %s  (%s of %s)\n" "$comp" "$have" "$n"; fi
done
printf "\n${BOLD}Tools (~/.local/bin):${NC}\n"
for t in $1; do
    if [ -x "$HOME/.local/bin/$t" ]; then printf "  ${GREEN}[installed]${NC} %s\n" "$t"
    else printf "  ${RED}[missing]${NC}   %s\n" "$t"; fi
done
REMOTE
    exit 0
fi

# ── Local ────────────────────────────────────────────────────────────────────

check_bash()    { run_on_target "$BASH_CHECK"; }
check_git()     { run_on_target "p=\"$DOTFILES/git/dot-gitconfig\"" "$GIT_CHECK"; }
check_joshuto() { [ -f "$CONFIG_HOME/joshuto-hsplit/joshuto.toml" ]; }
check_lazyvim() { [ -d "$CONFIG_HOME/lazyvim" ]; }

printf "${BOLD}Configs:${NC}\n"
for comp in $COMPONENTS; do
    have=0; n=0
    while read -r src; do
        [ -n "$src" ] || continue
        dest=$(local_path "$(target_of "$src")"); n=$((n + 1))
        ours "$dest" && [ -e "$dest" ] && have=$((have + 1))   # ours, and not dangling
    done < <(sources_of "$comp")
    if declare -f "check_$comp" >/dev/null; then n=$((n + 1)); "check_$comp" && have=$((have + 1)); fi
    note=""; in_list "$comp" "${ALL_LOCAL[@]}" || note="  (opt-in)"
    if [ "$have" -eq "$n" ]; then installed "$comp$note"
    elif [ "$have" -eq 0 ];   then missing "$comp$note"
    else partial "$comp  ($have of $n linked)$note"; fi
done

printf "\n${BOLD}Tools (~/.local/bin):${NC}\n"
for t in "${TOOL_NAMES[@]}"; do
    [ -x "$HOME/.local/bin/$t" ] && installed "$t" || missing "$t"
done

printf "\n"
if [ -d "$VENDOR_DIR" ]; then
    count=0; for t in "${TOOL_NAMES[@]}"; do vendored "$t" && count=$((count + 1)); done
    printf "${BOLD}Vendor cache:${NC} %d of %d tools in vendor/linux-$ARCH/\n" "$count" "${#TOOL_NAMES[@]}"
else
    printf "${BOLD}Vendor cache:${NC} empty — run 'make vendor'\n"
fi
