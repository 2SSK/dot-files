pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What the launcher picks from. Apps: the desktop entries, ranked by how well the name matches and
// how often each was launched. Emoji: the list in ~/.local/share/desktop/emoji.tsv (from Unicode),
// recent ones first. Files: desktop-file find. Themes: theme list --json. Use counts and recent
// emoji are kept in ~/.local/state/desktop/launcher.json.
Singleton {
	id: root

	property var emoji: [] // { char, name, group }
	property var files: [] // full paths
	property bool searching: false
	property var themes: [] // { family, name, dark: {...}, light: {...} }

	function rank(entry: var, q: string): int {
		const name = entry.name.toLowerCase();
		if (name.startsWith(q))
			return 0;
		if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q)))
			return 1;
		if (name.includes(q))
			return 2;
		const rest = [entry.genericName, entry.comment, entry.id, ...(entry.keywords ?? [])].join(" ").toLowerCase();
		return rest.includes(q) ? 3 : -1;
	}

	function findApps(query: string): var {
		const q = query.trim().toLowerCase();
		const uses = adapter.apps;
		const apps = Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay);
		const scored = apps.map(a => ({ app: a, rank: q ? rank(a, q) : 0, uses: uses[a.id] ?? 0 })).filter(s => s.rank >= 0);
		scored.sort((a, b) => a.rank - b.rank || b.uses - a.uses || a.app.name.localeCompare(b.app.name));
		return scored.map(s => s.app);
	}

	function launch(app: var): void {
		const uses = Object.assign({}, adapter.apps);
		uses[app.id] = (uses[app.id] ?? 0) + 1;
		adapter.apps = uses;
		state.writeAdapter();
		app.execute();
	}

	function findEmoji(query: string): var {
		const words = query.trim().toLowerCase().split(/\s+/).filter(w => w);
		if (!words.length) {
			const recent = adapter.emoji.map(c => emoji.find(e => e.char === c)).filter(e => e);
			return [...recent, ...emoji.filter(e => !adapter.emoji.includes(e.char))];
		}
		return emoji.filter(e => words.every(w => e.name.includes(w) || e.group.toLowerCase().includes(w)));
	}

	function pickEmoji(glyph: string): void { // not "char": a reserved word to Qt 6.8's parser
		adapter.emoji = [glyph, ...adapter.emoji.filter(c => c !== glyph)].slice(0, 24);
		state.writeAdapter();
		Quickshell.execDetached(["sh", "-c", 'if [ -n "$WAYLAND_DISPLAY" ]; then wl-copy -- "$1"; else printf %s "$1" | xclip -selection clipboard -t UTF8_STRING; fi', "sh", glyph]);
	}

	function findFiles(query: string): void {
		finder.running = false;
		finder.command = ["desktop-file", "find", query.trim()];
		searching = true;
		finder.running = true;
	}

	// open, path or content
	function file(action: string, path: string): void {
		Quickshell.execDetached(["desktop-file", action, path]);
	}

	function loadThemes(): void {
		themeList.running = true;
	}

	Process {
		id: finder

		stdout: StdioCollector {
			onStreamFinished: {
				root.files = text.split("\n").filter(f => f);
				root.searching = false;
			}
		}
	}

	Process {
		id: themeList

		command: ["theme", "list", "--json"]
		stdout: StdioCollector {
			onStreamFinished: {
				try {
					root.themes = JSON.parse(text);
				} catch (e) {
					root.themes = [];
				}
			}
		}
	}

	FileView {
		path: (Quickshell.env("XDG_DATA_HOME") || Quickshell.env("HOME") + "/.local/share") + "/desktop/emoji.tsv"
		printErrors: false
		onLoaded: root.emoji = text().split("\n").filter(l => l && !l.startsWith("#")).map(l => {
			const [glyph, name, group] = l.split("\t");
			return { char: glyph, name, group };
		})
	}

	FileView {
		id: state

		path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/desktop/launcher.json"
		blockLoading: true
		printErrors: false

		JsonAdapter {
			id: adapter

			property var apps: ({})
			property var emoji: []
		}
	}
}
