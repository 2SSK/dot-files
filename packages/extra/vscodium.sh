#!/usr/bin/env bash
# VSCodium on Fedora: its own RPM repository (the one VSCodium's docs give), the signing key checked
# against its sha256 before rpm trusts it. Arch has vscodium-bin in the AUR.
set -euo pipefail
# shellcheck source-path=SCRIPTDIR source=lib.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib.sh"
command -v codium >/dev/null && exit 0
key="$(fetch https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg dbdfd9af3b83b72a24c89160ce7638418142e2cf4736ab53e5061e10070f13c1)"
sudo rpmkeys --import "$key"
printf '%s\n' '[gitlab.com_paulcarroty_vscodium_repo]' 'name=VSCodium' \
	'baseurl=https://download.vscodium.com/rpms/' 'enabled=1' 'gpgcheck=1' 'repo_gpgcheck=1' \
	'gpgkey=https://gitlab.com/paulcarroty/vscodium-deb-rpm-repo/-/raw/master/pub.gpg' 'metadata_expire=1h' |
	sudo tee /etc/yum.repos.d/vscodium.repo >/dev/null
sudo dnf install -y codium
log_info installed name=vscodium
