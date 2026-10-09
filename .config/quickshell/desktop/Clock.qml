import QtQuick
import Quickshell

// Date and time, e.g. "Thu 09 Oct  14:32", updated on the minute.
Text {
	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	text: Qt.formatDateTime(clock.date, "ddd dd MMM  HH:mm")
	color: Theme.fg
	font.family: Theme.fontSans
	font.pixelSize: 13
	font.weight: Font.Medium
}
