import QtQuick
import Quickshell
import qs
import qs.services

// Speaker volume, and a red mic when the microphone is muted. Scroll changes the volume, a click
// mutes, a right click opens the mixer.
Item {
	implicitWidth: line.implicitWidth
	implicitHeight: line.implicitHeight

	Line {
		id: line

		vertical: Config.vertical
		spacing: 6

		Readout {
			glyph: Icons.g(Audio.muted ? "volume-off" : Audio.volume < 0.5 ? "volume-2" : "volume")
			label: "vol"
			value: Audio.muted ? "mute" : Math.round(Audio.volume * 100) + "%"
			tint: Audio.muted ? Theme.fgMuted : Theme.fg
		}

		Glyph {
			visible: Audio.micMuted
			glyph: Icons.g("microphone-off")
			color: Theme.error
		}
	}

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor
		onClicked: event => event.button === Qt.RightButton ? Quickshell.execDetached(["pavucontrol"]) : Audio.toggleMute()
		onWheel: event => Audio.change(event.angleDelta.y > 0 ? Config.audio.step : -Config.audio.step)
	}
}
