import QtQuick
import Quickshell
import qs
import qs.services

// "10:18 AM Fri, Oct 09"; a vertical bar shows hours over minutes. Shortly before a timed event (the
// calendar's nextUp minutes) it names it instead of the date: "10:18 AM · Standup in 12 min", in the
// accent. A click opens the calendar.
Label {
	id: root

	readonly property var next: Events.nextUp
	readonly property int minutes: next ? Math.max(1, Math.ceil((next.at - clock.date) / 60000)) : 0
	readonly property string what: next ? (next.event.text.length > 28 ? next.event.text.slice(0, 27) + "…" : next.event.text) : ""

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

	text: Config.vertical ? Qt.formatDateTime(clock.date, "hh\nmm") : next ? `${Qt.formatDateTime(clock.date, "hh:mm AP")}  ·  ${what} in ${minutes} min` : Qt.formatDateTime(clock.date, "hh:mm AP ddd, MMM dd")
	color: next ? Theme.primary : Theme.fg
	lineHeight: 0.9
	font.family: Theme.fontBar
	font.weight: Theme.barWeight
}
