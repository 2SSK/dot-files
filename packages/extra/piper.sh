#!/usr/bin/env bash
# Piper (offline neural text-to-speech, for voiceover): the pinned PyPI release as a uv tool in
# ~/.local, on Python 3.12 (its onnxruntime has wheels there). Voices download on first use.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=1.8.0
[[ $(uv tool list 2>/dev/null) == *"piper-tts v$version"* ]] && exit 0
uv tool install --quiet --python 3.12 "piper-tts==$version"
log_info installed name=piper version="$version"
