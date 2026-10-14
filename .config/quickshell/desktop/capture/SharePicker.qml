pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.widgets

// The capture panel asking what to share (a call, a meeting): the screens, then the windows most
// recent first; a click or Enter shares it.
Item {
	id: chooser

	property int selected: 0
	signal pointed(int index) // the pointer moved onto a row

	UiText {
		id: head

		text: "Share what?"
		font.family: Theme.fontHeading
		font.weight: Font.DemiBold
	}

	ListView {
		id: list

		anchors.top: head.bottom
		anchors.topMargin: 10
		width: parent.width
		height: parent.height - head.height - 10
		clip: true
		spacing: 2
		model: Share.sources
		currentIndex: chooser.selected
		highlightMoveDuration: Theme.quick
		boundsBehavior: Flickable.StopAtBounds

		delegate: Rectangle {
			id: row

			required property var modelData
			required property int index
			readonly property bool chosen: chooser.selected === index

			width: ListView.view.width
			height: 46
			radius: 12
			color: chosen ? Qt.alpha(Theme.primary, 0.16) : "transparent"

			Behavior on color {
				ColorAnimation {
					duration: Theme.quick
					easing.type: Theme.curve
				}
			}

			PointerPick {
				onMoved: chooser.pointed(row.index)
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: Share.take(row.modelData.line)
			}

			IconImage {
				visible: row.modelData.icon !== ""
				x: 10
				anchors.verticalCenter: parent.verticalCenter
				implicitSize: 26
				source: visible ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
				asynchronous: true
			}

			// a screen, or a window the shell doesn't know (no app icon)
			Glyph {
				visible: row.modelData.icon === ""
				x: 13
				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g(row.modelData.screen ? "device-desktop" : "app-window")
				font.pixelSize: 20
				color: Theme.primary
			}

			Column {
				x: 48
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width - x - 12
				spacing: 1

				UiText {
					width: parent.width
					text: row.modelData.screen ? `Screen  ${row.modelData.name}` : row.modelData.name
					elide: Text.ElideRight
					font.weight: Font.Medium
				}

				UiText {
					width: parent.width
					visible: text !== ""
					text: row.modelData.detail
					elide: Text.ElideRight
					color: Theme.fgMuted
					font.pixelSize: Theme.textLabel
				}
			}
		}
	}
}
