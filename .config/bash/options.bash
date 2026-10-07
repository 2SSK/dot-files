# shellcheck shell=bash
shopt -s autocd cdspell checkwinsize globstar histappend

HISTFILE="$XDG_STATE_HOME/bash/history"
HISTSIZE=50000
HISTFILESIZE=50000
HISTCONTROL=ignoreboth:erasedups
HISTTIMEFORMAT='%F %T '
[[ -d ${HISTFILE%/*} ]] || mkdir -p "${HISTFILE%/*}"
