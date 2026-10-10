import QtQuick
import qs

// A button that is an icon: round by default (set radius for a rounded square); `on` fills it with
// the accent and the icon with its filled version; a hover tints it. The control center's header
// and sidebar, the media controls, the calendar's add button and the level sliders' icons.
Rectangle {
	id: root

	property string glyph
	property int size: 34
	property int glyphSize: 16
	property bool on
	property bool filled: on
	property bool bordered // a hairline while off
	property color idle: "transparent" // the fill while off and not hovered
	property real hoverAlpha: 0.1
	property color glyphColor: on ? Theme.primaryText : Theme.fg
	signal clicked

	implicitWidth: size
	implicitHeight: size
	radius: size / 2
	color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.fg, hoverAlpha) : idle
	border.width: bordered && !on ? 1 : 0
	border.color: Qt.alpha(Theme.border, 0.7)

	Glyph {
		anchors.centerIn: parent
		glyph: root.glyph
		filled: root.filled
		font.pixelSize: root.glyphSize
		font.weight: Font.Normal
		color: root.glyphColor
	}

	HoverHandler {
		id: hover
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.clicked()
	}
}
