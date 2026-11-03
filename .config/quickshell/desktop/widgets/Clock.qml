import QtQuick
import Quickshell
import qs
import qs.services

// "07:01 UTC · 12:31 PM Mon, Nov 02": UTC on the left, muted (servers and logs keep it; the static bar
// only, the island keeps to the time here), then the time here and the date; a vertical bar shows
// hours over minutes. Shortly before a timed event (the calendar's nextUp minutes) it names it
// instead of the date, in the accent: "· Standup in 12 min". A click opens the calendar.
Label {
	id: root

	readonly property var next: Events.nextUp
	readonly property int minutes: next ? Math.max(1, Math.ceil((next.at - clock.date) / 60000)) : 0
	readonly property string what: next ? (next.event.text.length > 28 ? next.event.text.slice(0, 27) + "…" : next.event.text) : ""
	// the same moment on a UTC wall clock (formatDateTime only speaks local time)
	readonly property date utc: new Date(clock.date.getTime() + clock.date.getTimezoneOffset() * 60000)

	function escaped(text: string): string {
		return text.replace(/&/g, "&amp;").replace(/</g, "&lt;");
	}

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

	textFormat: Config.vertical ? Text.PlainText : Text.StyledText
	text: Config.vertical ? Qt.formatDateTime(clock.date, "hh\nmm") : (Config.island ? "" : `<font color="${Theme.fgMuted}">${Qt.formatDateTime(utc, "hh:mm")} UTC</font>&nbsp;&nbsp;·&nbsp;&nbsp;`) + (next ? `${Qt.formatDateTime(clock.date, "hh:mm AP")}&nbsp;&nbsp;<font color="${Theme.primary}">·&nbsp;&nbsp;${escaped(what)} in ${minutes} min</font>` : Qt.formatDateTime(clock.date, "hh:mm AP ddd, MMM dd"))
	lineHeight: 0.9
	font.family: Theme.fontBar
	font.weight: Theme.barWeight
}
