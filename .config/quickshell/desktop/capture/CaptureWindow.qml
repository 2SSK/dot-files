pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.control
import qs.services
import qs.widgets

// Capture, dropping out of the bar (a HangingPanel): a screenshot or a recording of a region (drag
// a rectangle; the only thing done with the mouse), the focused window, or a screen. Keys: the
// arrows pick a tile and Enter does it; R, W, S take a screenshot straight away, with Shift they
// record. Choosing a screen: the arrows or 1–9 pick one, A all of them, Enter takes it, Escape or
// Backspace goes back. A screenshot is saved and copied to the clipboard. With more than one monitor, Screen
// shows a small map of them to pick one (or all). While recording, Record becomes Stop.
HangingPanel {
	id: root

	property string asking: Panel.captureAsk // "shot" or "record": which screen?
	readonly property var modes: [
		{ mode: "region", label: "Region", glyph: "crop", key: Qt.Key_R },
		{ mode: "window", label: "Window", glyph: "app-window", key: Qt.Key_W },
		{ mode: "screen", label: "Screen", glyph: "device-desktop", key: Qt.Key_S }
	]
	property int seconds: 0
	property int selected: 0 // 0–2 screenshot, 3–5 record
	property int monitor: 0 // the screen picked when asking which
	readonly property var sortedScreens: [...Quickshell.screens].sort((a, b) => a.x - b.x || a.y - b.y)

	function pick(kind: string, mode: string): void {
		if (mode === "screen" && Quickshell.screens.length > 1)
			asking = kind;
		else
			Capture.take(kind, mode, null);
	}

	name: "capture"
	open: Panel.captureOpen
	panelWidth: Panel.captureWidth
	panelHeight: Panel.captureHeight
	onDismissed: Panel.captureOpen = false
	// the screen picked to begin with: the one this panel is on
	onAskingChanged: monitor = Math.max(0, sortedScreens.findIndex(s => s.name === screen.name))
	Component.onCompleted: monitor = Math.max(0, sortedScreens.findIndex(s => s.name === screen.name))
	onKeyPressed: event => {
		const k = event.key;
		if (asking) {
			const n = sortedScreens.length;
			if (k === Qt.Key_Left || k === Qt.Key_Up)
				monitor = (monitor + n - 1) % n;
			else if (k === Qt.Key_Right || k === Qt.Key_Down || k === Qt.Key_Tab)
				monitor = (monitor + 1) % n;
			else if (k >= Qt.Key_1 && k <= Qt.Key_9 && k - Qt.Key_1 < n)
				Capture.take(asking, "screen", sortedScreens[k - Qt.Key_1]);
			else if (k === Qt.Key_A)
				Capture.take(asking, "screen", null);
			else if (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)
				Capture.take(asking, "screen", sortedScreens[monitor]);
			else if (k === Qt.Key_Backspace)
				asking = "";
			else
				return;
			event.accepted = true;
			return;
		}
		if (!asking && (k === Qt.Key_Left || k === Qt.Key_Right)) {
			selected = Math.floor(selected / 3) * 3 + (selected % 3 + (k === Qt.Key_Left ? 2 : 1)) % 3;
			event.accepted = true;
			return;
		}
		if (!asking && (k === Qt.Key_Up || k === Qt.Key_Down)) {
			selected = (selected + 3) % 6;
			event.accepted = true;
			return;
		}
		if (!asking && (k === Qt.Key_Return || k === Qt.Key_Enter || k === Qt.Key_Space)) {
			if (selected >= 3 && Recorder.recording) {
				Recorder.stop();
				Panel.captureOpen = false;
			} else {
				pick(selected < 3 ? "shot" : "record", modes[selected % 3].mode);
			}
			event.accepted = true;
			return;
		}
		const m = modes.find(m => m.key === event.key);
		if (!m || asking)
			return;
		const record = event.modifiers & Qt.ShiftModifier;
		if (record && Recorder.recording)
			Recorder.stop();
		else
			pick(record ? "record" : "shot", m.mode);
		event.accepted = true;
	}

	Timer {
		running: Recorder.recording
		interval: 1000
		repeat: true
		triggeredOnStart: true
		onTriggered: root.seconds = Math.floor((Date.now() - Recorder.started.getTime()) / 1000)
	}

	component Tile: Rectangle {
		id: tile

		property string glyph
		property string label
		property bool danger: false
		property bool chosen: false // picked with the arrows
		signal clicked

		height: 78
		radius: 16
		color: danger ? (tileHover.hovered || chosen ? Qt.lighter(Theme.error, 1.1) : Theme.error) : tileHover.hovered || chosen ? Qt.alpha(Theme.primary, 0.16) : Qt.alpha(Theme.surface, 0.8)
		border.width: (tileHover.hovered || chosen) && !danger ? 1 : 0
		border.color: Qt.alpha(Theme.primary, 0.6)

		Behavior on color {
			ColorAnimation {
				duration: 120
			}
		}

		Column {
			anchors.centerIn: parent
			spacing: 6

			Glyph {
				anchors.horizontalCenter: parent.horizontalCenter
				glyph: Icons.g(tile.glyph)
				font.pixelSize: 22
				color: tile.danger ? Theme.primaryText : tileHover.hovered || tile.chosen ? Theme.primary : Theme.fg
				filled: tile.danger
			}

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: tile.label
				color: tile.danger ? Theme.primaryText : Theme.fg
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.pixelSize: 13
				font.weight: Font.Medium
			}
		}

		HoverHandler {
			id: tileHover
		}

		MouseArea {
			anchors.fill: parent
			cursorShape: Qt.PointingHandCursor
			onClicked: tile.clicked()
		}
	}

	component Heading: Row {
		property string glyph
		property string label

		spacing: 8

		Glyph {
			anchors.verticalCenter: parent.verticalCenter
			glyph: Icons.g(parent.glyph)
			font.pixelSize: 15
			color: Theme.primary
		}

		Text {
			anchors.verticalCenter: parent.verticalCenter
			text: parent.label
			color: Theme.fg
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: 14
			font.weight: Font.DemiBold
		}
	}

	// --- screenshot and record ---

	Column {
		visible: !root.asking
		x: 16
		y: 16
		width: parent.width - 32
		spacing: 10

		Heading {
			glyph: "camera"
			label: "Screenshot"
		}

		Row {
			width: parent.width
			spacing: 8

			Repeater {
				model: root.modes

				delegate: Tile {
					required property var modelData
					required property int index

					width: (parent.width - 16) / 3
					glyph: modelData.glyph
					label: modelData.label
					chosen: root.selected === index
					onClicked: root.pick("shot", modelData.mode)
				}
			}
		}

		Item {
			width: 1
			height: 4
		}

		Heading {
			glyph: "video"
			label: "Record"
		}

		Row {
			visible: !Recorder.recording
			width: parent.width
			spacing: 8

			Repeater {
				model: root.modes

				delegate: Tile {
					required property var modelData
					required property int index

					width: (parent.width - 16) / 3
					glyph: modelData.glyph
					label: modelData.label
					chosen: root.selected === index + 3
					onClicked: root.pick("record", modelData.mode)
				}
			}
		}

		Tile {
			visible: Recorder.recording
			width: parent.width
			danger: true
			chosen: root.selected >= 3
			glyph: "player-stop"
			label: `Stop recording  ·  ${Math.floor(root.seconds / 60)}:${String(root.seconds % 60).padStart(2, "0")}`
			onClicked: {
				Recorder.stop();
				Panel.captureOpen = false;
			}
		}
	}

	// --- which screen: a map of the monitors as they're arranged ---

	Item {
		id: chooser

		readonly property var screens: Quickshell.screens
		readonly property real minX: Math.min(...screens.map(s => s.x))
		readonly property real minY: Math.min(...screens.map(s => s.y))
		readonly property real spanW: Math.max(...screens.map(s => s.x + s.width)) - minX
		readonly property real spanH: Math.max(...screens.map(s => s.y + s.height)) - minY
		readonly property real k: Math.min((width - 8) / spanW, (map.height - 8) / spanH)

		visible: root.asking !== ""
		x: 16
		y: 16
		width: parent.width - 32
		height: parent.height - 52

		Row {
			id: head

			spacing: 8

			Rectangle {
				width: 30
				height: 30
				radius: 10
				color: backHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.surface, 0.8)

				Glyph {
					anchors.centerIn: parent
					glyph: Icons.g("chevron-left")
					font.pixelSize: 15
				}

				HoverHandler {
					id: backHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: root.asking = ""
				}
			}

			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: root.asking === "record" ? "Record which screen?" : "Screenshot which screen?"
				color: Theme.fg
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.pixelSize: 14
				font.weight: Font.DemiBold
			}
		}

		Chip {
			anchors.right: parent.right
			anchors.verticalCenter: head.verticalCenter
			label: "All screens  (A)"
			onClicked: Capture.take(root.asking, "screen", null)
		}

		Item {
			id: map

			anchors.top: head.bottom
			anchors.topMargin: 14
			width: parent.width
			height: parent.height - head.height - 14

			Repeater {
				model: root.sortedScreens

				delegate: Rectangle {
					id: monitor

					required property var modelData
					required property int index

					x: (map.width - chooser.spanW * chooser.k) / 2 + (modelData.x - chooser.minX) * chooser.k + 4
					y: (map.height - chooser.spanH * chooser.k) / 2 + (modelData.y - chooser.minY) * chooser.k + 4
					width: modelData.width * chooser.k - 8
					height: modelData.height * chooser.k - 8
					radius: 14
					readonly property bool chosen: monitorHover.hovered || root.monitor === index

					color: chosen ? Qt.alpha(Theme.primary, 0.2) : Qt.alpha(Theme.surface, 0.85)
					border.width: chosen ? 2 : 1
					border.color: chosen ? Theme.primary : Qt.alpha(Theme.border, 0.9)

					Behavior on color {
						ColorAnimation {
							duration: 120
						}
					}

					Column {
						anchors.centerIn: parent
						spacing: 4

						Glyph {
							anchors.horizontalCenter: parent.horizontalCenter
							glyph: Icons.g("device-desktop")
							font.pixelSize: 20
							color: monitor.chosen ? Theme.primary : Theme.fg
						}

						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: `${monitor.index + 1}  ${monitor.modelData.name}`
							color: Theme.fg
							font.family: Theme.fontSans
							font.hintingPreference: Theme.hinting
							font.pixelSize: 13
							font.weight: Font.DemiBold
						}

						Text {
							anchors.horizontalCenter: parent.horizontalCenter
							text: `${monitor.modelData.width}×${monitor.modelData.height}`
							color: Theme.fgMuted
							font.family: Theme.fontSans
							font.hintingPreference: Theme.hinting
							font.pixelSize: 11
						}
					}

					HoverHandler {
						id: monitorHover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: Capture.take(root.asking, "screen", monitor.modelData)
					}
				}
			}
		}
	}

	// what the keys do
	Text {
		x: 16
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 10
		text: root.asking ? "←→ or 1–9 pick · Enter takes it · A all screens · Backspace back" : "←→↑↓ pick · Enter does it · R W S screenshot · Shift+R W S record"
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.hintingPreference: Theme.hinting
		font.pixelSize: 11
	}
}
