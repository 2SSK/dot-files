import QtQuick
import Quickshell
import qs
import qs.services

// Screen recording: a click opens the capture panel; while recording the camera turns red and pulses
// on a soft red pill with the time, and a click stops it.
Item {
	id: root

	property int seconds: 0

	implicitWidth: line.implicitWidth
	implicitHeight: line.implicitHeight

	Timer {
		interval: 1000
		running: Recorder.recording
		repeat: true
		triggeredOnStart: true
		onTriggered: root.seconds = Math.floor((Date.now() - Recorder.started.getTime()) / 1000)
	}

	// recording: a soft red pill behind the camera and the clock
	Rectangle {
		anchors.fill: parent
		anchors.margins: -5
		anchors.leftMargin: -8
		anchors.rightMargin: -8
		radius: height / 2
		color: Qt.alpha(Theme.error, 0.18)
		border.width: 1
		border.color: Qt.alpha(Theme.error, 0.5)
		opacity: Recorder.recording ? 1 : 0

		Behavior on opacity {
			NumberAnimation {
				duration: 200
			}
		}
	}

	Line {
		id: line

		vertical: Config.vertical
		spacing: Recorder.recording ? 6 : 0 // no gap for the hidden timer, so the camera sits centred

		Glyph {
			id: dot

			glyph: Icons.g("video")
			filled: Recorder.recording
			color: Recorder.recording ? Theme.error : Theme.fg
			font.pixelSize: Theme.iconSize

			SequentialAnimation on opacity {
				running: Recorder.recording
				loops: Animation.Infinite
				onStopped: dot.opacity = 1

				NumberAnimation {
					to: 0.4
					duration: 700
				}

				NumberAnimation {
					to: 1
					duration: 700
				}
			}
		}

		Label {

			font.family: Theme.fontBar
			visible: Recorder.recording
			text: `${Math.floor(root.seconds / 60)}:${String(root.seconds % 60).padStart(2, "0")}`
			color: Theme.error
			font.pixelSize: Config.vertical ? Theme.fontSize - 3 : Theme.fontSize
		}
	}

	MouseArea {
		anchors.fill: parent
		anchors.margins: -4
		cursorShape: Qt.PointingHandCursor
		onClicked: Recorder.toggle()
	}
}
