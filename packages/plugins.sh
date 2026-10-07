#!/usr/bin/env bash
# Clone or update shell plugins to their pinned tags. Offline and a no-op when already current.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/log.sh
source "$here/../.local/lib/desktop/log.sh"

# sync <dest> <repo> <tag> [build]
sync() {
	local dest="$HOME/$1" repo=$2 tag=$3 build=${4:-}
	local stamp="$dest/.git/desktop-built" # records the tag whose build succeeded

	if [[ -e $dest && ! -d $dest/.git ]]; then
		die not_a_clone path="$dest" msg='move it away and re-run'
	fi
	if [[ ! -d $dest ]]; then
		git -c advice.detachedHead=false clone -q --depth 1 --branch "$tag" --recurse-submodules --shallow-submodules "$repo" "$dest"
		log_info cloned path="$dest" tag="$tag"
	elif [[ $(git -C "$dest" rev-parse HEAD) != $(git -C "$dest" rev-parse -q --verify "refs/tags/$tag^{commit}" || true) ]]; then
		git -C "$dest" fetch -q --depth 1 origin "+refs/tags/$tag:refs/tags/$tag"
		git -C "$dest" -c advice.detachedHead=false checkout -q "$tag"
		git -C "$dest" submodule -q update --init --recursive --depth 1
		log_info updated path="$dest" tag="$tag"
	fi

	if [[ -n $build && $(cat "$stamp" 2>/dev/null) != "$tag" ]]; then
		(cd "$dest" && bash -c "$build") >/dev/null
		echo "$tag" >"$stamp"
		log_info built path="$dest" tag="$tag"
	fi
}

list="${1:-$here/plugins.txt}"
while read -r dest repo tag build; do
	[[ -z $dest || $dest == \#* ]] && continue
	sync "$dest" "$repo" "$tag" "$build" </dev/null
done <"$list"
