pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// A day in hours: the timed events as blocks (half an hour unless they say how long), side by side
// where they overlap, a line at now on today, and a click on an empty spot asks to add one there (at
// that half hour). From 8:00 to 20:00, or wider to fit what's on.
Item {
	id: root

	property date day: new Date()
	property var entries: [] // the day's occurrences (Events.on), timed ones drawn
	readonly property int hourHeight: 44
	readonly property int gutter: 52
	readonly property var timed: entries.filter(e => e.time).map(e => {
		const start = Events.minutes(e.time);
		return Object.assign({}, e, { start, stop: e.end ? Events.minutes(e.end) : start + 30 });
	})
	readonly property int from: Math.min(8, ...timed.map(e => Math.floor(e.start / 60)))
	readonly property int to: Math.max(20, ...timed.map(e => Math.ceil(e.stop / 60)))
	// overlapping events take lanes side by side: each its lane, and how many lanes its cluster needs
	readonly property var placed: {
		const sorted = timed.slice().sort((a, b) => a.start - b.start);
		const out = [];
		let cluster = [], laneEnds = [], clusterEnd = -1;
		const close = () => cluster.forEach(p => p.lanes = laneEnds.length);
		for (const e of sorted) {
			if (e.start >= clusterEnd) {
				close();
				cluster = [];
				laneEnds = [];
			}
			let lane = laneEnds.findIndex(end => end <= e.start);
			if (lane < 0)
				lane = laneEnds.push(0) - 1;
			laneEnds[lane] = e.stop;
			const p = Object.assign({}, e, { lane, lanes: 1 });
			cluster.push(p);
			out.push(p);
			clusterEnd = Math.max(clusterEnd, e.stop);
		}
		close();
		return out;
	}

	signal emptyClicked(string hhmm)
	signal entryClicked(var entry)

	function yOf(minute: real): real {
		return (minute - from * 60) / 60 * hourHeight;
	}

	implicitHeight: (to - from) * hourHeight + 8

	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	// a click on empty time: that half hour
	MouseArea {
		anchors.fill: parent
		anchors.leftMargin: root.gutter
		cursorShape: Qt.PointingHandCursor
		onClicked: mouse => {
			const minute = Math.max(0, Math.floor((root.from * 60 + mouse.y / root.hourHeight * 60) / 30) * 30);
			root.emptyClicked(`${String(Math.floor(minute / 60)).padStart(2, "0")}:${String(minute % 60).padStart(2, "0")}`);
		}
	}

	Repeater {
		model: root.to - root.from + 1

		delegate: Item {
			required property int index

			y: index * root.hourHeight
			width: root.width
			height: 1

			UiText {
				width: root.gutter - 10
				anchors.verticalCenter: parent.verticalCenter
				horizontalAlignment: Text.AlignRight
				text: `${String(root.from + parent.index).padStart(2, "0")}:00`
				color: Theme.fgMuted
				font.family: Theme.fontMono
				font.pixelSize: Theme.textCaption
			}

			Rectangle {
				x: root.gutter
				width: root.width - root.gutter
				height: 1
				color: Qt.alpha(Theme.fg, 0.08)
			}
		}
	}

	Repeater {
		model: root.placed

		delegate: Rectangle {
			id: block

			required property var modelData
			readonly property real lane: (root.width - root.gutter - 4) / modelData.lanes

			x: root.gutter + 4 + modelData.lane * lane
			y: root.yOf(modelData.start) + 1
			width: lane - 4
			height: Math.max(22, root.yOf(modelData.stop) - root.yOf(modelData.start) - 2)
			radius: 8
			opacity: modelData.done ? 0.6 : 1
			color: blockHover.hovered ? Qt.alpha(Theme.primary, 0.32) : Qt.alpha(Theme.primary, 0.22)
			clip: true

			Rectangle {
				width: 3
				height: parent.height
				color: Theme.primary
			}

			Column {
				x: 10
				y: 4
				width: parent.width - 14

				UiText {
					width: parent.width
					text: block.modelData.text
					elide: Text.ElideRight
					font.weight: Font.DemiBold
					font.pixelSize: Theme.textLabel
				}

				UiText {
					visible: block.height > 38
					width: parent.width
					text: block.modelData.time + (block.modelData.end ? "–" + block.modelData.end : "") + (block.modelData.repeat ? " · " + Events.repeats[block.modelData.repeat] : "")
					elide: Text.ElideRight
					color: Theme.fgMuted
					font.pixelSize: Theme.textCaption
				}
			}

			HoverHandler {
				id: blockHover
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: root.entryClicked(block.modelData)
			}
		}
	}

	// now, on today
	Item {
		readonly property int minute: clock.date.getHours() * 60 + clock.date.getMinutes()

		visible: root.day.toDateString() === clock.date.toDateString() && minute >= root.from * 60 && minute <= root.to * 60
		y: root.yOf(minute)
		width: root.width
		height: 1

		Rectangle {
			x: root.gutter - 4
			anchors.verticalCenter: parent.verticalCenter
			width: 8
			height: 8
			radius: 4
			color: Theme.error
		}

		Rectangle {
			x: root.gutter
			width: root.width - root.gutter
			height: 2
			anchors.verticalCenter: parent.verticalCenter
			color: Theme.error
		}
	}
}
