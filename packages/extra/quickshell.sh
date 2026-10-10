#!/usr/bin/env bash
# Quickshell (the desktop shell) on Fedora: the errornointernet COPR, the same release as Arch's
# package (install.sh --check makes sure Fedora's Qt is new enough: 6.9+).
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
version=0.3.2
[[ $(quickshell --version 2>/dev/null) == *"$version"* ]] && exit 0

sudo dnf install -y dnf5-plugins >/dev/null 2>&1 || sudo dnf install -y dnf-plugins-core
sudo dnf copr enable -y errornointernet/quickshell
sudo dnf install -y quickshell
log_info installed name=quickshell version="$version"
