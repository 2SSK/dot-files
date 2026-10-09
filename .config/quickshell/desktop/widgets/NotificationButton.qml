import QtQuick
import qs
import qs.services

// The bell: a dot when something new arrived, struck through while Do Not Disturb is on. A click
// opens the notification centre, a right click toggles Do Not Disturb.
Glyph {
	text: Notifications.dnd ? "\u{EC08}" : "\u{EAA2}" // cod-bell-slash, cod-bell
	color: Panel.centerOpen ? Theme.primary : Notifications.dnd ? Theme.fgMuted : Theme.fg
	font.pixelSize: Theme.iconSize

	Rectangle {
		visible: Notifications.unread > 0 && !Notifications.dnd
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.topMargin: 1
		width: 7
		height: 7
		radius: 4
		color: Theme.primary
	}

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		acceptedButtons: Qt.LeftButton | Qt.RightButton
		cursorShape: Qt.PointingHandCursor
		onClicked: event => event.button === Qt.RightButton ? Notifications.dnd = !Notifications.dnd : Panel.toggleCenter()
	}
}
