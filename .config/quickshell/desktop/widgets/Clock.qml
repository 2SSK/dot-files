import QtQuick
import Quickshell
import qs
import qs.services

// The clock, and what just happened in its place: a level (volume, mic, brightness) or Caps/Num Lock
// for osd.timeout, a recording's time, or a timed event coming up (calendar.nextUp minutes before).
// Static: "07:01 UTC · 12:31 PM Mon, Nov 02", the event or the recording in place of the date, a
// level as icon, track and number. Island: the 24-hour time in a slot of one fixed size, everything
// else swapped in inside it, a level as its icon and a short track. A side bar stacks hours over
// minutes, a level filling its pill from the bottom. A click opens the calendar, or stops a recording.
Item {
	id: root

	readonly property bool vertical: Config.vertical
	readonly property bool island: Config.island
	// the island's clock fills its capsule (Section leaves it no padding)
	readonly property bool flush: island
	readonly property real thick: Config.bar.size - 2 * Theme.barInset

	readonly property bool osd: Panel.osdShown
	readonly property string kind: Panel.osdKind
	readonly property bool level: kind !== "caps" && kind !== "num"
	readonly property bool muted: Panel.osdMuted
	readonly property bool recording: Recorder.recording
	readonly property var next: Events.nextUp
	readonly property int minutes: next ? Math.max(1, Math.ceil((next.at - clock.date) / 60000)) : 0
	readonly property string what: next ? (next.event.text.length > 28 ? next.event.text.slice(0, 27) + "…" : next.event.text) : ""
	// the same moment on a UTC wall clock (formatDateTime only speaks local time)
	readonly property date utc: new Date(clock.date.getTime() + clock.date.getTimezoneOffset() * 60000)
	// what the pill shows on the island and a side bar: the newest news first
	readonly property string showing: osd ? "osd" : recording ? "rec" : next ? "event" : "time"

	readonly property string osdGlyph: ({
			volume: muted ? Icons.g("volume-off") : Panel.osdValue < 0.5 ? Icons.g("volume-2") : Icons.g("volume"),
			mic: muted ? Icons.g("microphone-off") : Icons.g("microphone"),
			brightness: Icons.g("brightness-up"),
			caps: Icons.g("arrow-big-up-line"),
			num: Icons.g("hash")
		})[kind] ?? ""
	readonly property color osdTint: muted ? Theme.fgMuted : Theme.fg

	function escaped(text: string): string {
		return text.replace(/&/g, "&amp;").replace(/</g, "&lt;");
	}

	// the island's pill fits any of its contents, so it never changes size for them
	implicitWidth: vertical ? thick : island ? Math.max(widest.width + (Config.bar.capsules ? 48 : 20), recordingTime.implicitWidth + (Config.bar.capsules ? 40 : 12)) : Math.max(wide.implicitWidth, wideLevel.implicitWidth)
	implicitHeight: vertical ? stackedTime.implicitHeight + 16 : island ? thick : Math.max(wide.implicitHeight, wideLevel.implicitHeight)

	SystemClock {
		id: clock

		precision: SystemClock.Minutes
	}

	TextMetrics {
		id: widest

		font: stackedTime.font
		text: "00:00"
	}

	MouseArea {
		anchors.fill: parent
		anchors.margins: root.flush ? 0 : -6
		cursorShape: Qt.PointingHandCursor
		onClicked: root.recording ? Recorder.toggle() : Panel.toggleControl("calendar")
	}

	// a level fills a side bar's pill from the bottom
	Rectangle {
		readonly property real value: root.osd && root.level && !root.muted ? Math.min(1, Panel.osdValue) : 0

		visible: root.vertical
		anchors.left: parent.left
		anchors.bottom: parent.bottom
		width: root.vertical ? parent.width : Math.max(parent.height, parent.width * value)
		height: root.vertical ? Math.max(parent.width, parent.height * value) : parent.height
		radius: Math.min(width, height) / 2
		color: Qt.alpha(Theme.primary, 0.3)
		opacity: root.osd && root.level && value > 0 ? 1 : 0

		Behavior on width {
			NumberAnimation {
				duration: Theme.quick
				easing.type: Theme.curve
			}
		}

		Behavior on height {
			NumberAnimation {
				duration: Theme.quick
				easing.type: Theme.curve
			}
		}

		Behavior on opacity {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}
	}

	// one of the layers below at a time, the others faded out a few pixels down
	component Layer: Item {
		property bool on

		anchors.centerIn: parent
		width: childrenRect.width
		height: childrenRect.height
		opacity: on ? 1 : 0
		anchors.verticalCenterOffset: on ? 0 : 5

		Behavior on opacity {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Behavior on anchors.verticalCenterOffset {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}
	}

	component BarText: Label {
		font.family: Theme.fontBar
		font.weight: Theme.barWeight
		font.pixelSize: root.vertical ? Theme.fontSize - 3 : Theme.fontSize
		lineHeight: 0.9
	}

	// ---- static, along the bar: the whole line, or a level with its track

	Layer {
		visible: !root.island && !root.vertical
		on: !root.osd

		BarText {
			id: wide

			textFormat: Text.StyledText
			readonly property string dot: `<font color="${Theme.fgMuted}">&nbsp;·&nbsp;</font>`
			readonly property string tail: root.recording ? `<font color="${Theme.error}">● ${Format.clock(Recorder.seconds)}</font>` : root.next ? `<font color="${Theme.primary}">${root.escaped(root.what)} in ${root.minutes} min</font>` : `<font color="${Theme.fgMuted}">${Qt.formatDateTime(clock.date, "ddd, MMM dd")}</font>`
			text: `<font color="${Theme.fgMuted}">${Qt.formatDateTime(root.utc, "hh:mm")} UTC</font>${dot}${Qt.formatDateTime(clock.date, "h:mm AP")}&nbsp;${tail}`
		}
	}

	Layer {
		visible: !root.island && !root.vertical
		on: root.osd

		Row {
			id: wideLevel

			spacing: 10

			Glyph {
				anchors.verticalCenter: parent.verticalCenter
				glyph: root.osdGlyph
				color: root.osdTint
			}

			Rectangle {
				visible: root.level
				anchors.verticalCenter: parent.verticalCenter
				width: 96
				height: 4
				radius: 2
				color: Qt.alpha(Theme.overlay, 0.9)

				Rectangle {
					width: parent.width * (root.muted ? 0 : Math.min(1, Panel.osdValue))
					height: parent.height
					radius: parent.radius
					color: root.muted ? Theme.fgMuted : Theme.primary

					Behavior on width {
						NumberAnimation {
							duration: Theme.normal
							easing.type: Theme.curve
						}
					}
				}
			}

			BarText {
				visible: !root.level
				anchors.verticalCenter: parent.verticalCenter
				text: `${root.kind === "caps" ? "Caps Lock" : "Num Lock"} ${root.muted ? "off" : "on"}`
				color: root.osdTint
			}

			BarText {
				id: wideValue

				visible: root.level
				anchors.verticalCenter: parent.verticalCenter
				width: wideNumber.width
				horizontalAlignment: Text.AlignRight
				text: root.muted ? "off" : Math.round(Panel.osdValue * 100) + "%"
				color: root.osdTint

				TextMetrics {
					id: wideNumber

					font: wideValue.font
					text: "100%"
				}
			}
		}
	}

	// ---- the island's pill and a side bar's: one thing at a time

	Layer {
		visible: root.island || root.vertical
		on: root.showing === "time"

		BarText {
			id: stackedTime

			text: Qt.formatDateTime(clock.date, root.vertical ? "HH\nmm" : "HH:mm")
		}
	}

	Layer {
		visible: root.island || root.vertical
		on: root.showing === "rec"

		Row {
			spacing: 7

			Rectangle {
				visible: !root.vertical
				anchors.verticalCenter: parent.verticalCenter
				width: 9
				height: 9
				radius: 4.5
				color: Theme.error
			}

			BarText {
				id: recordingTime

				// a side bar: minutes over seconds
				text: root.vertical ? Format.clock(Recorder.seconds).replace(":", "\n") : Format.clock(Recorder.seconds)
				color: Theme.error
			}
		}
	}

	Layer {
		visible: root.island || root.vertical
		on: root.showing === "event"

		Grid {
			columns: root.vertical ? 1 : 2
			spacing: root.vertical ? 2 : 6
			horizontalItemAlignment: Grid.AlignHCenter
			verticalItemAlignment: Grid.AlignVCenter

			Glyph {
				glyph: Icons.g("calendar")
				color: Theme.primary
				font.pixelSize: Theme.iconSize - 2
			}

			BarText {
				text: `${root.minutes}m`
				color: Theme.primary
			}
		}
	}

	// the island: the level's icon and a short track that eases to the new value
	Layer {
		visible: root.island && !root.vertical
		on: root.showing === "osd"

		Row {
			spacing: 8

			Glyph {
				anchors.verticalCenter: parent.verticalCenter
				glyph: root.osdGlyph
				color: root.osdTint
				font.pixelSize: Theme.iconSize - 2
			}

			Rectangle {
				visible: root.level
				anchors.verticalCenter: parent.verticalCenter
				width: 36
				height: 4
				radius: 2
				color: Qt.alpha(Theme.overlay, 0.9)

				Rectangle {
					width: parent.width * (root.muted ? 0 : Math.min(1, Panel.osdValue))
					height: parent.height
					radius: parent.radius
					color: root.muted ? Theme.fgMuted : Theme.primary

					Behavior on width {
						NumberAnimation {
							duration: Theme.normal
							easing.type: Theme.curve
						}
					}
				}
			}

			BarText {
				visible: !root.level
				anchors.verticalCenter: parent.verticalCenter
				text: root.muted ? "off" : "on"
				color: root.osdTint
			}
		}
	}

	// a side bar: the icon over the number
	Layer {
		visible: root.vertical
		on: root.showing === "osd"

		Grid {
			columns: root.vertical ? 1 : 2
			spacing: root.vertical ? 2 : 6
			horizontalItemAlignment: Grid.AlignHCenter
			verticalItemAlignment: Grid.AlignVCenter

			Glyph {
				glyph: root.osdGlyph
				color: root.osdTint
				font.pixelSize: Theme.iconSize - 2
			}

			BarText {
				text: root.level ? (root.muted ? "off" : Math.round(Panel.osdValue * 100)) : (root.muted ? "off" : "on")
				color: root.osdTint
			}
		}
	}
}
