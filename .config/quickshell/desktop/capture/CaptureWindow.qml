pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Capture, a HangingPanel: a screenshot or recording of a region, the focused window or a screen.
// R, W, S act at once (with Shift they record); a screenshot is saved and copied to the clipboard.
HangingPanel {
	id: root

	property string asking: Panel.captureAsk // "shot" or "record": which screen?
	readonly property var modes: [
		{ mode: "region", label: "Region", glyph: "crop", key: Qt.Key_R },
		{ mode: "window", label: "Window", glyph: "app-window", key: Qt.Key_W },
		{ mode: "screen", label: "Screen", glyph: "device-desktop", key: Qt.Key_S }
	]
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
	panelWidth: Panel.sizes.capture.width
	panelHeight: Panel.sizes.capture.height
	onDismissed: Panel.captureOpen = false
	onAskingChanged: monitor = Math.max(0, sortedScreens.findIndex(s => s.name === screen.name))
	onOpened: monitor = Math.max(0, sortedScreens.findIndex(s => s.name === screen.name))
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
			else if (k === Qt.Key_Backspace || k === Qt.Key_Escape)
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

		UiText {
			anchors.verticalCenter: parent.verticalCenter
			text: parent.label
			font.family: Theme.fontHeading
			font.weight: Font.DemiBold
		}
	}


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

				delegate: CaptureTile {
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

				delegate: CaptureTile {
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

		CaptureTile {
			visible: Recorder.recording
			width: parent.width
			danger: true
			chosen: root.selected >= 3
			glyph: "player-stop"
			label: `Stop recording  ·  ${Format.clock(Recorder.seconds)}`
			onClicked: {
				Recorder.stop();
				Panel.captureOpen = false;
			}
		}
	}


	ScreenPicker {
		visible: root.asking !== ""
		x: 16
		y: 16
		width: parent.width - 32
		height: parent.height - 52
		asking: root.asking
		screens: root.sortedScreens
		monitor: root.monitor
		onBack: root.asking = ""
		onTake: screen => Capture.take(root.asking, "screen", screen)
	}

	UiText {
		x: 16
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 10
		text: root.asking ? "←→ or 1–9 pick · Enter takes it · A all screens · Esc back" : "←→↑↓ pick · Enter does it · R W S screenshot · Shift+R W S record"
		color: Theme.fgMuted
		font.pixelSize: Theme.textCaption
	}
}
