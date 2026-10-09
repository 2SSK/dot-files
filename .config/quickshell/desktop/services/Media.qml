pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media players (MPRIS: music apps, browsers playing video or audio, mpv, …). `player` is the
// one chosen in the media card, else the one playing, else the first.
Singleton {
	id: root

	readonly property var players: Array.from(Mpris.players.values)
	property string chosen: "" // a player's dbusName
	readonly property MprisPlayer player: players.find(p => p.dbusName === chosen) ?? players.find(p => p.isPlaying) ?? players[0] ?? null

	function name(p: MprisPlayer): string {
		return p?.identity || p?.dbusName?.replace("org.mpris.MediaPlayer2.", "").split(".")[0] || "Player";
	}

	// players report their position only when asked
	Timer {
		interval: 1000
		running: root.player?.isPlaying ?? false
		repeat: true
		onTriggered: root.player.positionChanged()
	}
}
