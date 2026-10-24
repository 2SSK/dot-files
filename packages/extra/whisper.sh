#!/usr/bin/env bash
# whisper-ctranslate2 (offline speech-to-text, for captions): Whisper's models on CPU through
# CTranslate2, writing .srt; the pinned PyPI release as a uv tool in ~/.local, on Python 3.12.
# Models download on first use.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.5.8
[[ $(uv tool list 2>/dev/null) == *"whisper-ctranslate2 v$version"* ]] && exit 0
uv tool install --quiet --python 3.12 "whisper-ctranslate2==$version"
log_info installed name=whisper-ctranslate2 version="$version"
