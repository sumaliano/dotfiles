#!/usr/bin/env bash
# bootstrap.sh — download the portable binaries into vendor/linux-<arch>/.
#
#   bootstrap.sh [name ...]      no name = every tool in lib.sh's TOOLS table
#   FORCE=1 bootstrap.sh nvim    re-download one that's already there
#
# Run once on any internet-connected machine, then 'make tool …' installs
# from the cache, locally or over SSH. GITHUB_TOKEN raises the API rate limit.

set -uo pipefail
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

command -v curl >/dev/null || die "curl is required"
command -v tar  >/dev/null || die "tar is required"

NAMES=("$@")
[ ${#NAMES[@]} -gt 0 ] || NAMES=("${TOOL_NAMES[@]}")
for n in "${NAMES[@]}"; do is_tool "$n" || die "Unknown tool '$n'. Available: ${TOOL_NAMES[*]}"; done

mkdir -p "$VENDOR_DIR"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT

# Download URL of the newest release asset whose name contains $pattern.
# /releases/latest first; then the last few releases, which catches projects
# that only publish pre-releases.
gh_latest() {
    local repo=$1 pattern=$2 auth=() url page
    [ -z "${GITHUB_TOKEN:-}" ] || auth=(-H "Authorization: token $GITHUB_TOKEN")
    for page in "releases/latest" "releases?per_page=10"; do
        url=$(curl -fsSL "${auth[@]}" "https://api.github.com/repos/$repo/$page" 2>/dev/null \
              | grep -o '"browser_download_url": *"[^"]*' | grep -o 'https://.*' | grep -F "$pattern" | head -1)
        [ -z "$url" ] || { printf '%s' "$url"; return 0; }
    done
    return 1
}

# Download and unpack an asset once per run (yazi and ya share one zip); the
# unpacked directory lands in $UNPACKED. A bare binary is saved under $2.
declare -A CACHE
unpack() {
    local url=$1 bin=$2 dir
    UNPACKED="${CACHE[$url]:-}"
    [ -z "$UNPACKED" ] || return 0
    dir=$(mktemp -d -p "$TMP"); mkdir "$dir/x"
    printf "  fetching %s ...\r" "${url##*/}"
    case "$url" in
        *.zip)         command -v unzip >/dev/null || { printf "\r\033[K"; fail "unzip is required for $url"; return 1; }
                       curl -fsSL -o "$dir/a" "$url" && unzip -q "$dir/a" -d "$dir/x" ;;
        *.tar*|*.tgz)  curl -fsSL -o "$dir/a" "$url" && tar -xf "$dir/a" -C "$dir/x" ;;
        *)             curl -fsSL -o "$dir/x/$bin" "$url" ;;
    esac || { printf "\r\033[K"; return 1; }
    printf "\r\033[K"
    UNPACKED="$dir/x"; CACHE[$url]="$UNPACKED"
}

fetch() {
    local name=$1 repo=$2 pattern=$3 bin=${4:-$1} url found
    if vendored "$name" && [ "${FORCE:-}" != 1 ] && [ "${FORCE:-}" != true ]; then
        skip "$name (present — FORCE=1 to refresh)"; return
    fi
    url=$(gh_latest "$repo" "$pattern") || { fail "$name: no release asset matching '$pattern' (pattern changed, or GitHub rate limit — set GITHUB_TOKEN)"; return; }
    unpack "$url" "$bin" || { fail "$name: download or unpack failed — $url"; return; }
    found=$(find "$UNPACKED" -type f -name "$bin" | head -1)
    [ -n "$found" ] || { fail "$name: no '$bin' inside $url"; return; }
    cp "$found" "$VENDOR_DIR/$name" && chmod +x "$VENDOR_DIR/$name" || { fail "$name: copy failed"; return; }
    if [ "$name" = nvim ]; then
        # The binary alone is useless: share/nvim/runtime is VIMRUNTIME and
        # lib/nvim/parser holds the treesitter grammars matching the bundled
        # queries (without them: "Invalid field name" errors on open).
        local rt pr
        rt=$(find "$UNPACKED" -type d -path '*/share/nvim/runtime' | head -1)
        pr=$(find "$UNPACKED" -type d -path '*/lib/nvim/parser'    | head -1)
        [ -n "$rt" ] && [ -n "$pr" ] || { fail "nvim: runtime/ or parser/ missing from the tarball"; return; }
        rm -rf "$VENDOR_DIR/nvim-runtime" "$VENDOR_DIR/nvim-parsers"
        cp -r "$rt" "$VENDOR_DIR/nvim-runtime" && cp -r "$pr" "$VENDOR_DIR/nvim-parsers"
    fi
    ok "$name  ←  ${url##*/}"
}

info "Fetching portable binaries → vendor/linux-$ARCH/"
for row in "${TOOLS[@]}"; do
    in_list "${row%% *}" "${NAMES[@]}" || continue
    # shellcheck disable=SC2086  # the row is whitespace-separated columns
    fetch $row
done

printf "\n${GREEN}Done.${NC} 'make tool' installs from the cache; add HOST=user@host to push to a remote.\n"
