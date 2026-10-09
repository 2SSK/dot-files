import QtQuick
import qs
import qs.services

// CPU and memory use.
Line {
	vertical: Config.vertical
	spacing: Config.vertical ? 8 : 14

	Readout {
		glyph: "\uf4bc" // nf-oct-cpu
		label: "cpu"
		value: Math.round(Stats.cpu * 100) + "%"
	}

	Readout {
		glyph: "\uefc5" // nf-fa-memory
		label: "mem"
		value: Stats.memUsed.toFixed(1) + "G"
	}
}
