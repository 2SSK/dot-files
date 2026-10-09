import QtQuick
import Quickshell
import qs

// "10:18 AM Fri, Oct 09"; a vertical bar shows hours over minutes.
Label {
	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	text: Qt.formatDateTime(clock.date, Config.vertical ? "hh\nmm" : "h:mm AP ddd, MMM dd")
	lineHeight: 0.9
	font.weight: Font.Medium
}
