# shellcheck shell=bash
# Shared logging for desktop-* commands: one logfmt line per event on stderr
# (stdout is reserved for the command's real output). Source, then use
# log_info / log_warn / log_error / die with [key=value ...] arguments.

# log <level> <event> [key=value ...] — level: debug | info | warn | error
# Quiet by default: only warn and error print. DESKTOP_LOG_LEVEL=info (or debug) shows more.
log() {
    if (( $# < 2 )); then
        printf 'log: usage: log <level> <event> [key=value ...]\n' >&2
        return 2
    fi

    local level="$1" event="$2"
    shift 2
    local -A rank=([debug]=0 [info]=1 [warn]=2 [error]=3)
    (( ${rank[$level]:-3} >= ${rank[${DESKTOP_LOG_LEVEL:-warn}]:-2} )) || return 0

    local line="level=$level event=$event"
    [[ -n ${DESKTOP_DISPLAY:-} ]] && line+=" backend=$DESKTOP_DISPLAY"
    [[ -n ${DESKTOP_WM:-} ]] && line+=" wm=$DESKTOP_WM"

    local kv
    for kv in "$@"; do
        line+=" $(_log_quote "$kv")"
    done

    printf '%s\n' "$line" >&2
}

log_info() { log info "$@"; }
log_warn() { log warn "$@"; }
log_error() { log error "$@"; }

# Exit codes: 0 ok · 1 failure · 2 usage · 3 unsupported
die() {
    log_error "$@"
    exit 1
}

# Quote key=value if the value contains spaces; escapes \ and " inside.
_log_quote() {
    local kv="$1"

    if [[ $kv != *=* || ${kv#*=} != *[[:space:]]* ]]; then
        printf '%s' "$kv"
        return 0
    fi

    local key="${kv%%=*}" value="${kv#*=}"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    printf '%s="%s"' "$key" "$value"
}
