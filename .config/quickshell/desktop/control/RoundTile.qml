import QtQuick
import qs
import qs.widgets

// A quick toggle on the home page: a card with a round icon that fills with the accent when it's on.
// Wide: the icon beside its name and state. Small (wide: false): the icon over a short name.
Rectangle {
	id: root

	property string glyph
	property string label
	property string detail
	property bool on
	property bool wide: true
	property bool available: true
	signal clicked

	implicitHeight: wide ? 58 : 64
	radius: Theme.radiusCard + 4
	color: hover.hovered && available ? Qt.alpha(Theme.surface, 0.85) : Qt.alpha(Theme.surface, 0.62)
	opacity: available ? 1 : 0.5
	scale: press.pressed ? 0.97 : 1

	Behavior on color {
		enabled: !Theme.switching
		ColorAnimation {
			duration: Theme.quick
		}
	}

	Behavior on scale {
		NumberAnimation {
			duration: Theme.quick
			easing.type: Theme.curve
		}
	}

	Rectangle {
		id: round

		x: 12
		y: root.wide ? (root.height - height) / 2 : 10
		width: root.wide ? 32 : 28
		height: width
		radius: width / 2
		color: root.on ? Theme.primary : Qt.alpha(Theme.fg, 0.12)

		Behavior on color {
			enabled: !Theme.switching
			ColorAnimation {
				duration: Theme.normal
				easing.type: Theme.curve
			}
		}

		Glyph {
			anchors.centerIn: parent
			glyph: root.glyph
			color: root.on ? Theme.primaryText : Theme.fg
			font.pixelSize: 16
		}
	}

	Column {
		visible: root.wide
		anchors.left: round.right
		anchors.leftMargin: 10
		anchors.right: parent.right
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		spacing: 1

		UiText {
			width: parent.width
			text: root.label
			elide: Text.ElideRight
			font.weight: Font.DemiBold
			font.pixelSize: Theme.textLabel
		}

		UiText {
			width: parent.width
			visible: text !== ""
			text: root.detail
			elide: Text.ElideRight
			color: Theme.fgMuted
			font.pixelSize: Theme.textCaption
		}
	}

	UiText {
		visible: !root.wide
		x: 12
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 8
		width: parent.width - 20
		text: root.label
		elide: Text.ElideRight
		font.weight: Font.Medium
		font.pixelSize: Theme.textCaption
	}

	HoverHandler {
		id: hover
	}

	MouseArea {
		id: press

		anchors.fill: parent
		enabled: root.available
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
