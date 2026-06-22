#!/usr/bin/env bash
# preview_file.sh — joshuto preview pane renderer.
#
# joshuto does not preview files itself; it runs this script for the selected
# file and pipes stdout into the preview pane. It is invoked as:
#   preview_file.sh --path <FILE> --preview-width <N> --preview-height <N> ...
#
# Style note (matches the rest of the repo): prefer the vendored modern tools
# (bat, 7z) when they're on PATH, fall back to coreutils everywhere else, so
# the same script works on a bare server with nothing installed.

set -o noclobber -o noglob -o nounset

FILE_PATH=""
PREVIEW_WIDTH=80
PREVIEW_HEIGHT=40

while [ "$#" -gt 0 ]; do
    case "$1" in
        --path)           shift; FILE_PATH="${1:-}" ;;
        --preview-width)  shift; PREVIEW_WIDTH="${1:-80}" ;;
        --preview-height) shift; PREVIEW_HEIGHT="${1:-40}" ;;
        --x-coord|--y-coord) shift ;;  # accepted, unused
    esac
    shift || break
done

[ -n "$FILE_PATH" ] && [ -r "$FILE_PATH" ] || exit 1

mimetype="$(file --dereference --brief --mime-type -- "$FILE_PATH" 2>/dev/null || echo application/octet-stream)"

case "$mimetype" in
    # ── Text & source code ────────────────────────────────────────────────────
    text/* | */xml | */json | */javascript | */x-shellscript)
        if command -v bat >/dev/null 2>&1; then
            bat --color=always --style=plain --paging=never \
                --terminal-width="$PREVIEW_WIDTH" --line-range=":$PREVIEW_HEIGHT" \
                -- "$FILE_PATH" && exit 0
        fi
        head -n "$PREVIEW_HEIGHT" -- "$FILE_PATH"
        exit 0
        ;;

    # ── Archives: list contents ───────────────────────────────────────────────
    application/zip | application/x-tar | application/gzip | \
    application/x-bzip2 | application/x-7z-compressed | application/x-xz)
        if command -v 7z >/dev/null 2>&1; then
            7z l -- "$FILE_PATH" | head -n "$PREVIEW_HEIGHT" && exit 0
        elif command -v tar >/dev/null 2>&1; then
            tar tf "$FILE_PATH" 2>/dev/null | head -n "$PREVIEW_HEIGHT" && exit 0
        fi
        ;;

    # ── Images / binaries: metadata only ──────────────────────────────────────
    image/*)
        echo "$mimetype"
        file --dereference --brief -- "$FILE_PATH"
        exit 0
        ;;
esac

# ── Fallback: type line + a hex/text peek ─────────────────────────────────────
file --dereference --brief -- "$FILE_PATH"
echo "----"
head -c 512 -- "$FILE_PATH" | cat -v | fold -w "$PREVIEW_WIDTH" | head -n "$PREVIEW_HEIGHT"
exit 0
