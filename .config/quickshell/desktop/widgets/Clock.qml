import QtQuick
import Quickshell
import qs

// "10:18 AM Fri, Oct 09"; a vertical bar shows hours over minutes. A click opens the calendar.
Label {
	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleControl("calendar")
	}

	text: Qt.formatDateTime(clock.date, Config.vertical ? "hh\nmm" : "hh:mm AP ddd, MMM dd")
	lineHeight: 0.9
	font.family: Theme.fontBar
	font.weight: Theme.barWeight
}
