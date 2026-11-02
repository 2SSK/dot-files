import QtQuick
import Quickshell
import qs
import qs.services

// "10:18 AM Fri, Oct 09"; a vertical bar shows hours over minutes. Shortly before a timed event (the
// calendar's nextUp minutes) it names it instead of the date: "10:18 AM · Standup in 12 min", in the
// accent. Hovered, UTC in its place (servers and logs keep it): "04:48 UTC Fri, Oct 09", in the accent,
// the width kept so the bar doesn't shift. A click opens the calendar.
Label {
	id: root

	readonly property var next: Events.nextUp
	readonly property int minutes: next ? Math.max(1, Math.ceil((next.at - clock.date) / 60000)) : 0
	readonly property string what: next ? (next.event.text.length > 28 ? next.event.text.slice(0, 27) + "…" : next.event.text) : ""
	// the same moment on a UTC wall clock (formatDateTime only speaks local time)
	readonly property date utc: new Date(clock.date.getTime() + clock.date.getTimezoneOffset() * 60000)
	readonly property string local: Config.vertical ? Qt.formatDateTime(clock.date, "hh\nmm") : next ? `${Qt.formatDateTime(clock.date, "hh:mm AP")}  ·  ${what} in ${minutes} min` : Qt.formatDateTime(clock.date, "hh:mm AP ddd, MMM dd")
	readonly property string universal: Qt.formatDateTime(utc, Config.vertical ? "hh\nmm" : "hh:mm 'UTC' ddd, MMM dd")

	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	HoverHandler {
		id: hover
	}

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		cursorShape: Qt.PointingHandCursor
		onClicked: Panel.toggleControl("calendar")
	}

	TextMetrics {
		id: localWidth

		font: root.font
		text: root.local
	}

	TextMetrics {
		id: utcWidth

		font: root.font
		text: root.universal
	}

	text: hover.hovered ? universal : local
	color: hover.hovered || next ? Theme.primary : Theme.fg
	width: Config.vertical ? implicitWidth : Math.ceil(Math.max(localWidth.advanceWidth, utcWidth.advanceWidth))
	horizontalAlignment: Text.AlignHCenter
	lineHeight: 0.9
	font.family: Theme.fontBar
	font.weight: Theme.barWeight
}
