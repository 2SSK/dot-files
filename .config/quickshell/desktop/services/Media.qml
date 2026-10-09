pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

// The media player to show: the one playing, else the first there is.
Singleton {
	id: root

	readonly property MprisPlayer player: Mpris.players.values.find(p => p.isPlaying) ?? Mpris.players.values[0] ?? null

	// players report their position only when asked
	Timer {
		interval: 1000
		running: root.player?.isPlaying ?? false
		repeat: true
		onTriggered: root.player.positionChanged()
	}
}
