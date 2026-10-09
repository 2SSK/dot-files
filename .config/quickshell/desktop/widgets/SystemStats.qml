import QtQuick
import qs
import qs.services

// CPU use, memory use and the CPU temperature (hidden without a sensor).
Line {
	vertical: Config.vertical
	spacing: Config.vertical ? 8 : 12

	Readout {
		glyph: "\u{F029A}" // md-gauge
		label: "cpu"
		value: Math.round(Stats.cpu * 100) + "%"
	}

	Readout {
		glyph: "\u{F061A}" // md-chip
		label: "mem"
		value: Math.round(Stats.mem * 100) + "%"
	}

	Readout {
		visible: Stats.temp >= 0
		glyph: "\u{F0238}" // md-fire
		label: "tmp"
		value: Math.round(Stats.temp) + "°C"
		tint: Stats.temp >= 85 ? Theme.error : Theme.fg
	}
}
