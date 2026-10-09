#!/usr/bin/env bash

## Fuzzy-find a file under $HOME and put it on the clipboard as a *file*
## (text/uri-list), so Ctrl+V in Teams / Slack / a mail client attaches it
## instead of pasting its path.
##
##   Enter         copy the file
##   Alt+o         open with the default application
##   Alt+p         copy the path as plain text
##
## Matching is done by fzf itself (`fzf --filter`, so its full syntax works:
## 'exact ^start end$ !not a | b) when the rofi-blocks plugin is installed —
## it is what lets rofi hand every keystroke to an external program. Without
## it rofi's own fuzzy matcher is used, and Shift+Enter marks several rows.

set -u

# Options
root="$HOME"
# Folder names (or paths relative to $root) left out of the list.
excludes=(.git node_modules .cache .venv go/pkg Android/Sdk Library/pnpm snapd nltk_data)
# Files changed within this window are listed first, newest on top.
recent='7d'
# Rows fzf hands back to rofi per keystroke.
max_results=200

theme="$HOME/.config/rofi/extensions/filesearch.rasi"
# nf-fa-search. The trailing space is room for the icon: it is wider than one
# cell of the mono font, and rofi clips the prompt to the cells it occupies.
prompt=$'\xef\x80\x82 '
hint="<b>Enter</b> copy file · <b>Alt+o</b> open · <b>Alt+p</b> copy path"

# fd CMD
fd_cmd() {
    local args=(--type f --no-ignore --strip-cwd-prefix=always --base-directory "$root") name
    for name in "${excludes[@]}"; do
        args+=(--exclude "$name")
    done
    fd "${args[@]}" "$@"
}

# Paths relative to $root: the recently changed ones by mtime, then the rest.
list_files() {
    {
        fd_cmd --changed-within "$recent" --print0 |
            (cd "$root" && xargs -0 -r stat --printf '%Y\t%n\n' --) |
            sort -rn | cut -f2-
        fd_cmd
    } | awk '!seen[$0]++'
}

# Rofi CMD: options both front ends share.
rofi_cmd() {
    rofi -theme "$theme" \
        -ellipsize-mode middle \
        -kb-custom-1 "Alt+o" \
        -kb-custom-2 "Alt+p" \
        "$@"
}

# file:// URI for an absolute path: every byte outside the unreserved set is
# percent-encoded, which is also right for the UTF-8 bytes of a non-ASCII name.
file_uri() {
    local LC_ALL=C path="$1" out="" char code i
    for ((i = 0; i < ${#path}; i++)); do
        char="${path:i:1}"
        case "$char" in
            [a-zA-Z0-9/._~-]) out+="$char" ;;
            *)
                printf -v code '%d' "'$char"
                ((code < 0)) && ((code += 256))
                printf -v char '%%%02X' "$code"
                out+="$char"
                ;;
        esac
    done
    printf 'file://%s' "$out"
}

# One URI per line, CRLF-terminated (RFC 2483), offered as text/uri-list:
# the type a browser or Electron app reads on paste to attach the files.
#
# Offered as that type alone, the way a file copy looks on Windows. wl-copy
# cannot: for a text/* type it also offers the same bytes as text/plain, and
# the clipboard then holds a file and a line of text at once. wl-copy-exact
# (~/.local/bin) can; wl-copy is the fallback if it fails.
copy_files() {
    local path uris=""
    for path in "$@"; do
        uris+="$(file_uri "$path")"$'\r\n'
    done
    printf '%s' "$uris" | wl-copy-exact text/uri-list ||
        printf '%s' "$uris" | wl-copy --type text/uri-list
}

copy_paths() {
    local IFS=$'\n'
    printf '%s' "$*" | wl-copy
}

open_files() {
    local path
    for path in "$@"; do
        xdg-open "$path" > /dev/null 2>&1 &
    done
}

notify() {
    notify-send -a "File Search" -i "$1" "$2" "$3"
}

# "name" for one file, "N files" for several.
describe() {
    if (($# == 1)); then
        basename -- "$1"
    else
        printf '%d files' "$#"
    fi
}

# act <copy|open|path> <relative path>...
act() {
    local action="$1" path files=()
    shift
    for path in "$@"; do
        [[ -e "$root/$path" ]] && files+=("$root/$path")
    done
    if ((${#files[@]} == 0)); then
        notify dialog-error "File not found" "$*"
        return 1
    fi

    case "$action" in
        copy)
            copy_files "${files[@]}"
            notify edit-copy "File copied" "$(describe "${files[@]}") — paste to attach"
            ;;
        open)
            open_files "${files[@]}"
            ;;
        path)
            copy_paths "${files[@]}"
            notify edit-copy "Path copied" "$(describe "${files[@]}")"
            ;;
    esac
}

# ── front end 1: rofi-blocks, fzf does the matching ──────────────────────────

has_blocks() {
    [[ -e /usr/lib/rofi/blocks.so || -e "${ROFI_PLUGIN_PATH:-/nonexistent}/blocks.so" ]]
}

# The rows for one query, as the JSON line rofi-blocks reads. An empty query
# shows the head of the list, which is the recently changed files.
blocks_emit() {
    local list="$1" query="$2"
    if [[ -z "$query" ]]; then
        head -n "$max_results" "$list"
    else
        fzf --filter "$query" --scheme=path < "$list" | head -n "$max_results"
    fi | jq -Rnc '{lines: [inputs]}'
}

# Run by rofi-blocks (`-blocks-wrap`): stdout is JSON for rofi, stdin is one
# event per line in the format set below — NAME<TAB>value. rofi closes when
# this process exits.
blocks_main() {
    local list name value active=""
    list="$(mktemp)"
    # shellcheck disable=SC2064  # expand now: $list is local to this function
    trap "rm -f '$list'" EXIT

    jq -nc --arg prompt "$prompt" --arg message "$hint" '{
        "input action": "send",
        "event format": "{{name_enum}}\t{{value}}",
        prompt: $prompt,
        message: $message
    }'
    list_files > "$list"
    blocks_emit "$list" ""

    while IFS=$'\t' read -r name value; do
        case "$name" in
            INPUT_CHANGE) blocks_emit "$list" "$value" ;;
            # Sent just before CUSTOM_KEY: the row the key was pressed on.
            ACTIVE_ENTRY) active="$value" ;;
            SELECT_ENTRY)
                act copy "$value"
                return
                ;;
            CUSTOM_KEY)
                case "$value" in
                    1) act open "$active" ;;
                    2) act path "$active" ;;
                esac
                return
                ;;
        esac
    done
}

run_blocks() {
    local self
    self="$(realpath -- "${BASH_SOURCE[0]}")"
    rofi_cmd -modi blocks -show blocks -blocks-wrap "$(printf '%q --blocks' "$self")"
}

# ── front end 2: plain dmenu, rofi's own fuzzy matcher ───────────────────────

run_dmenu() {
    local selection code line paths=()

    selection="$(list_files | rofi_cmd -dmenu -i -no-custom -multi-select \
        -p "$prompt" \
        -matching fuzzy -sort -sorting-method fzf \
        -mesg "$hint · <b>Shift+Enter</b> mark")"
    code=$?
    [[ -n "$selection" ]] || return 0

    while IFS= read -r line; do
        paths+=("$line")
    done <<< "$selection"

    case "$code" in
        0) act copy "${paths[@]}" ;;
        10) act open "${paths[@]}" ;;
        11) act path "${paths[@]}" ;;
    esac
}

main() {
    if [[ "${1:-}" == "--blocks" ]]; then
        blocks_main
    elif has_blocks; then
        run_blocks
    else
        run_dmenu
    fi
}

# Actions
if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    main "$@"
fi
