import QtQuick
import Quickshell
import qs

// Date and time; a vertical bar shows hours over minutes.
Glyph {
	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	text: Qt.formatDateTime(clock.date, Config.vertical ? "HH\nmm" : "ddd dd MMM  HH:mm")
	lineHeight: 0.9
}
