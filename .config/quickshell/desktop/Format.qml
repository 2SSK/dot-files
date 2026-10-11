pragma Singleton

import QtQuick
import Quickshell

// How the shell writes times and paths: "5m" ago, a file's name, its folder with ~ for home, a
// recording's 1:05.
Singleton {
	readonly property string home: Quickshell.env("HOME")

	// <time> ms since the epoch, as now, 5m, 3h or 2d ago (against <now>, so a ticking caller updates)
	function ago(time: real, now: real): string {
		const s = Math.max(0, ((now || Date.now()) - time) / 1000);
		return s < 60 ? "now" : s < 3600 ? `${Math.floor(s / 60)}m` : s < 86400 ? `${Math.floor(s / 3600)}h` : `${Math.floor(s / 86400)}d`;
	}

	function fileName(path: string): string {
		return path.slice(path.lastIndexOf("/") + 1);
	}

	// the folder a path is in, ~ for home
	function folder(path: string): string {
		return path.slice(0, path.lastIndexOf("/")).replace(home, "~");
	}

	// seconds as m:ss
	function clock(seconds: int): string {
		return `${Math.floor(seconds / 60)}:${String(seconds % 60).padStart(2, "0")}`;
	}
}
