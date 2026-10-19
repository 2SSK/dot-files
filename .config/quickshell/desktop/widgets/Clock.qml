import QtQuick
import Quickshell
import qs
import "../Panchang.js" as Panchang

// "10:18 AM Fri, Oct 09"; a vertical bar shows hours over minutes. Hovered, the Hindu month and its
// season as Bihar counts them ("कुआर · शरद ऋतु", Panchang.js), in the same width. A click opens
// the calendar.
Label {
	id: root

	readonly property string time: Qt.formatDateTime(clock.date, Config.vertical ? "hh\nmm" : "hh:mm AP ddd, MMM dd")
	readonly property string season: Panchang.season(clock.date)

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
		id: timeWidth

		font: root.font
		text: root.time
	}

	TextMetrics {
		id: seasonWidth

		font: root.font
		text: root.season
	}

	text: hover.hovered && !Config.vertical ? season : time
	width: Config.vertical ? implicitWidth : Math.ceil(Math.max(timeWidth.advanceWidth, seasonWidth.advanceWidth))
	lineHeight: 0.9
	font.family: Theme.fontBar
	font.weight: Theme.barWeight
}
