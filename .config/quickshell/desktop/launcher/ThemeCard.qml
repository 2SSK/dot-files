pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.widgets

// A theme in the launcher's grid: a small window in its colours (a bar with its accents, its name),
// a tick on the one applied.
Rectangle {
	id: card

	property var colours: ({}) // the theme's ui colours, in the mode shown
	property string name
	property bool applied
	property bool selected
	property bool hovered

	radius: 14
	color: card.colours.bg ?? "transparent"
	border.width: card.applied ? 3 : card.selected ? 2 : 1
	border.color: card.applied ? Theme.primary : card.selected ? Qt.alpha(Theme.fg, 0.6) : Qt.alpha(Theme.border, 0.8)
	scale: card.hovered ? 1.03 : 1

	Behavior on scale {
		NumberAnimation {
			duration: Theme.quick
			easing.type: Theme.curve
		}
	}

	Rectangle {
		x: 10
		y: 10
		width: parent.width - 20
		height: 14
		radius: 7
		color: card.colours.surface ?? "transparent"

		Row {
			anchors.verticalCenter: parent.verticalCenter
			x: 6
			spacing: 4

			Repeater {
				model: ["primary", "secondary", "accent", "success", "error"]

				delegate: Rectangle {
					required property string modelData

					width: 6
					height: 6
					radius: 3
					color: card.colours[modelData] ?? "transparent"
				}
			}
		}
	}

	UiText {
		x: 12
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 10
		text: card.name
		color: card.colours.fg ?? Theme.fg
		font.family: Theme.fontHeading
		font.weight: Font.DemiBold
	}

	Rectangle {
		anchors.right: parent.right
		anchors.bottom: parent.bottom
		anchors.margins: 10
		width: 20
		height: 20
		radius: 10
		color: card.colours.primary ?? "transparent"
		scale: card.applied ? 1 : 0

		Behavior on scale {
			NumberAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Glyph {
			anchors.centerIn: parent
			glyph: Icons.g("check")
			font.pixelSize: 12
			color: card.colours.on_primary ?? Theme.primaryText
		}
	}
}
