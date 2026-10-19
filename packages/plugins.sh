#!/usr/bin/env bash
# Clone or update plugins to their pinned tag or commit. Offline and a no-op when already current.
set -euo pipefail

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source-path=SCRIPTDIR/.. source=.local/lib/desktop/log.sh
source "$here/../.local/lib/desktop/log.sh"

# sync <dest> <repo> <ref> [build]: ref is a release tag or a full commit hash
sync() {
	local dest="$HOME/$1" repo=$2 ref=$3 build=${4:-}
	local pinned="$dest/.git/desktop-ref" stamp="$dest/.git/desktop-built" # ref checked out / built

	if [[ -e $dest && ! -d $dest/.git ]]; then
		die not_a_clone path="$dest" msg='move it away and re-run'
	fi
	if [[ $(cat "$pinned" 2>/dev/null) != "$ref" ]]; then
		if [[ ! -d $dest/.git ]]; then
			git init -q "$dest"
			git -C "$dest" remote add origin "$repo"
		fi
		git -C "$dest" fetch -q --depth 1 origin "$ref"
		git -C "$dest" -c advice.detachedHead=false checkout -q --force FETCH_HEAD
		git -C "$dest" submodule -q update --init --recursive --depth 1
		echo "$ref" >"$pinned"
		log_info synced path="$dest" ref="$ref"
	fi

	if [[ -n $build && $(cat "$stamp" 2>/dev/null) != "$ref" ]]; then
		(cd "$dest" && bash -c "$build") >/dev/null
		echo "$ref" >"$stamp"
		log_info built path="$dest" ref="$ref"
	fi
}

# VSCodium (where it's installed): its extensions pinned in vscodium.txt, and the Desktop colour
# theme, a local extension whose theme file is the one `theme` renders (a window reload shows a switch)
vscodium() {
	command -v codium >/dev/null || return 0
	local have id version dir
	have="$(codium --list-extensions --show-versions 2>/dev/null || true)"
	while read -r id version; do
		[[ -z $id || $id == \#* ]] && continue
		grep -qixF "$id@$version" <<<"$have" && continue
		codium --install-extension "$id@$version" --force >/dev/null 2>&1 </dev/null
		log_info installed extension="$id" version="$version"
	done <"${VSCODIUM_EXTENSIONS:-$here/vscodium.txt}"
	if ! grep -qixF desktop.desktop-theme@1.0.0 <<<"$have"; then
		local vsix
		vsix="$(mktemp -d)/desktop-theme.vsix"
		python3 - "$here/../.local/share/desktop/vscodium-theme/package.json" "$vsix" <<'PY'
import sys, zipfile
manifest = """<?xml version="1.0" encoding="utf-8"?>
<PackageManifest Version="2.0.0" xmlns="http://schemas.microsoft.com/developer/vsx-schema/2011">
<Metadata><Identity Language="en-US" Id="desktop-theme" Version="1.0.0" Publisher="desktop"/>
<DisplayName>Desktop</DisplayName><Description>The desktop theme</Description></Metadata>
<Installation><InstallationTarget Id="Microsoft.VisualStudio.Code"/></Installation><Dependencies/>
<Assets><Asset Type="Microsoft.VisualStudio.Code.Manifest" Path="extension/package.json" Addressable="true"/></Assets>
</PackageManifest>"""
types = """<?xml version="1.0" encoding="utf-8"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
<Default Extension=".json" ContentType="application/json"/><Default Extension=".vsixmanifest" ContentType="text/xml"/>
</Types>"""
with zipfile.ZipFile(sys.argv[2], "w") as z:
    z.writestr("extension.vsixmanifest", manifest)
    z.writestr("[Content_Types].xml", types)
    z.write(sys.argv[1], "extension/package.json")
    z.writestr("extension/themes/desktop-color-theme.json", '{"name": "Desktop", "colors": {}}')
PY
		codium --install-extension "$vsix" --force >/dev/null 2>&1 </dev/null
		rm -rf "$(dirname "$vsix")"
		log_info installed extension=desktop.desktop-theme
	fi
	for dir in "$HOME"/.vscode-oss/extensions/desktop.desktop-theme-1.0.0*/themes; do
		[[ -d $dir ]] && ln -sfn "${XDG_STATE_HOME:-$HOME/.local/state}/desktop/theme/vscodium/desktop-color-theme.json" "$dir/desktop-color-theme.json"
	done
	return 0
}

list="${1:-$here/plugins.txt}"
while read -r dest repo ref build; do
	[[ -z $dest || $dest == \#* ]] && continue
	sync "$dest" "$repo" "$ref" "$build" </dev/null
done <"$list"
[[ -n ${1:-} && -z ${VSCODIUM_EXTENSIONS:-} ]] || vscodium # a list given: only its plugins (tests)
