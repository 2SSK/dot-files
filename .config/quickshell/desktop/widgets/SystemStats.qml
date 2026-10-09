import QtQuick
import qs
import qs.services

// CPU use, memory use and the CPU temperature (hidden without a sensor), as one group.
Line {
	id: root

	vertical: Config.vertical
	spacing: Config.vertical ? 6 : 9

	// a click opens the system monitor
	TapHandler {
		onTapped: Panel.toggleControl("system")
	}

	HoverHandler {
		cursorShape: Qt.PointingHandCursor
	}

	Readout {
		glyph: "\u{F029A}" // md-gauge
		label: "cpu"
		value: Math.round(Stats.cpu * 100) + "%"
		widest: "100%"
	}

	Readout {
		glyph: "\u{F061A}" // md-chip
		label: "mem"
		value: Math.round(Stats.mem * 100) + "%"
		widest: "100%"
	}

	Readout {
		visible: Stats.temp >= 0
		glyph: "\u{F0238}" // md-fire
		label: "tmp"
		value: Math.round(Stats.temp) + "°C"
		widest: "100°C"
		tint: Stats.temp >= 85 ? Theme.error : Theme.fg
	}
}
