pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// What the launcher picks from: apps ranked by match and launch count, emoji, files and themes.
// Use counts and recent emoji are kept in ~/.local/state/desktop/launcher.json.
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
		// not Waydroid's shortcut for each Android app (waydroid.<package>, rewritten every session):
		// they're opened from Waydroid itself, which stays listed
		const apps = Array.from(DesktopEntries.applications.values).filter(a => !a.noDisplay && !a.id.startsWith("waydroid."));
		const scored = apps.map(a => ({ app: a, rank: q ? rank(a, q) : 0, uses: uses[a.id] ?? 0 })).filter(s => s.rank >= 0);
		scored.sort((a, b) => a.rank - b.rank || b.uses - a.uses || a.app.name.localeCompare(b.app.name));
		return scored.map(s => s.app);
	}

	// A time between UTC and this machine's zone (IST here), for the top of the app results:
	// "2:00 ist", "2pm ist", "14:30 utc", "14:30z" or a bare "14:30" (read as UTC, as logs and servers
	// keep it), a log timestamp ("2026-11-02T08:30:00Z", "2026-11-02 08:30:00+05:30") or epoch seconds
	// or milliseconds. A bare time is today's in the zone it's in. null when it isn't a time.
	// { name: "02:00 IST → 20:30 UTC", detail, copy: what Enter copies }
	function convertTime(query: string): var {
		const q = query.trim().toLowerCase();
		const offset = -new Date().getTimezoneOffset(); // minutes east of UTC
		const zone = offset === 330 ? "IST" : "local";
		const utcWall = d => new Date(d.getTime() + d.getTimezoneOffset() * 60000); // UTC as a local wall clock
		const day = d => Qt.formatDateTime(d, "ddd dd MMM");
		let at = null, fromUtc = true, clock = true;
		let m;
		if ((m = q.match(/^(\d{1,2})(?::(\d{2}))?\s*(am|pm)?\s*(ist|utc|gmt|z|local)?$/)) && (m[2] !== undefined || m[3] || m[4])) {
			let h = +m[1];
			const min = +(m[2] ?? 0);
			if (m[3] ? h < 1 || h > 12 : h > 23)
				return null;
			if (min > 59)
				return null;
			if (m[3])
				h = h % 12 + (m[3] === "pm" ? 12 : 0);
			fromUtc = !m[4] || ["utc", "gmt", "z"].includes(m[4]);
			const now = new Date();
			if (fromUtc) {
				const today = utcWall(now);
				at = new Date(Date.UTC(today.getFullYear(), today.getMonth(), today.getDate(), h, min));
			} else {
				at = new Date(now.getFullYear(), now.getMonth(), now.getDate(), h, min);
			}
		} else if ((m = q.match(/^(\d{4}-\d{2}-\d{2})[t ](\d{2}:\d{2})(:\d{2}(?:\.\d+)?)?\s*(z|utc|[+-]\d{2}:?\d{2})?$/))) {
			const tz = !m[4] || m[4] === "z" || m[4] === "utc" ? "Z" : m[4].replace(/^([+-]\d{2})(\d{2})$/, "$1:$2");
			at = new Date(`${m[1]}T${m[2]}${m[3] ?? ":00"}${tz}`);
			fromUtc = tz === "Z";
			clock = false;
		} else if ((m = q.match(/^\d{10}(\d{3})?$/))) {
			at = new Date(m[1] ? +q : +q * 1000);
			clock = false;
		}
		if (!at || isNaN(at))
			return null;
		const local = Qt.formatDateTime(at, "hh:mm"), utc = Qt.formatDateTime(utcWall(at), "hh:mm");
		if (!clock) // a timestamp: both, in full
			return { convert: true, name: `${utc} UTC  ·  ${local} ${zone}`, detail: `${Qt.formatDateTime(utcWall(at), "ddd dd MMM yyyy")} UTC · Enter copies ${Qt.formatDateTime(at, "yyyy-MM-dd hh:mm")} ${zone}`, copy: Qt.formatDateTime(at, "yyyy-MM-dd hh:mm") + ` ${zone}` };
		const [from, to, toTime, toDay] = fromUtc ? [`${utc} UTC`, zone, local, day(at)] : [`${local} ${zone}`, "UTC", utc, day(utcWall(at))];
		return { convert: true, name: `${from}  →  ${toTime} ${to}`, detail: `${toDay} · Enter copies ${toTime}`, copy: toTime };
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
		Clipboard.copy({ kind: "text", text: glyph });
	}

	function findFiles(query: string): void {
		finder.running = false;
		finder.command = ["desktop", "file", "find", query.trim()];
		searching = true;
		finder.running = true;
	}

	// open, path or content
	function file(action: string, path: string): void {
		Quickshell.execDetached(["desktop", "file", action, path]);
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
