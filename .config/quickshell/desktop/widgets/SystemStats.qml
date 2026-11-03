pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services

// CPU, memory and temperature, only while one runs hot (Stats.cpuHot and the rest): in warning
// colours, red for the heat. On the island the hottest takes the end capsule's place instead
// (BarContent), so this shows nothing there. A click opens the system page.
Line {
	id: root

	readonly property bool present: !Config.island && Stats.hot !== ""
	readonly property bool chip: Config.bar.capsules
	// the capsule's colour (Section); the text turns dark on it
	readonly property color capsule: Stats.tempHot ? Theme.error : Theme.warning

	visible: present
	vertical: Config.vertical
	spacing: Config.vertical ? 6 : 12

	TapHandler {
		onTapped: Panel.toggleControl("system")
	}

	HoverHandler {
		cursorShape: Qt.PointingHandCursor
	}

	Repeater {
		model: [
			{ on: Stats.cpuHot, glyph: "gauge", value: Math.round(Stats.cpu * 100) + "%", crit: false },
			{ on: Stats.memHot, glyph: "cpu", value: Math.round(Stats.mem * 100) + "%", crit: false },
			{ on: Stats.tempHot, glyph: "flame", value: Math.round(Stats.temp) + (Config.vertical ? "°" : "°C"), crit: true }
		].filter(s => s.on)

		delegate: Readout {
			required property var modelData

			glyph: Icons.g(modelData.glyph)
			value: modelData.value
			widest: "88%"
			tint: root.chip ? Theme.bg : modelData.crit ? Theme.error : Theme.warning
		}
	}
}
