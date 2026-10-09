import QtQuick
import Quickshell
import qs
import qs.services

// Screen recording: a click starts it; while recording the camera turns red, pulses and shows the time.
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

	Line {
		id: line

		vertical: Config.vertical
		spacing: 6

		Glyph {
			id: dot

			text: Icons.g("video-camera")
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
