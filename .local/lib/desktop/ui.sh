# shellcheck shell=bash
# Human-facing output for interactive desktop-* commands (logs go through log.sh).
# Colour only on a terminal, and never with NO_COLOR set.

if [[ -t 1 && -z ${NO_COLOR:-} ]]; then
	bold=$'\e[1m' dim=$'\e[2m' red=$'\e[31m' green=$'\e[32m' yellow=$'\e[33m' blue=$'\e[34m' cyan=$'\e[36m' reset=$'\e[0m'
else
	bold='' dim='' red='' green='' yellow='' blue='' cyan='' reset=''
fi
# shellcheck disable=SC2034 # used by the scripts that source this file
readonly bold dim red green yellow blue cyan reset

step() { printf '\n%s==>%s %s%s%s\n' "$blue" "$reset" "$bold" "$*" "$reset"; }
ok() { printf '  %s✓%s %s\n' "$green" "$reset" "$*"; }
warn() { printf '  %s!%s %s\n' "$yellow" "$reset" "$*"; }
bad() { printf '  %s✗%s %s\n' "$red" "$reset" "$*"; }
hint() { printf '    %s→ %s%s\n' "$dim" "$*" "$reset"; }
row() { printf '  %-16s %s\n' "$1" "$2"; }
fail() { printf '%serror:%s %s\n' "$red" "$reset" "$1" >&2 && exit "${2:-1}"; }
