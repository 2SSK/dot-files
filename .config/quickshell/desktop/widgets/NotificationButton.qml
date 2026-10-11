import QtQuick
import qs
import qs.services

// The bell: a dot when something new arrived, struck through while Do Not Disturb is on. A click
// opens the control center's notifications, a right click toggles Do Not Disturb.
BarButton {
	glyph: Notifications.dnd ? Icons.g("bell-off") : Icons.g("bell")
	page: "notifications"
	idleColor: Notifications.dnd ? Theme.fgMuted : Theme.fg
	font.pixelSize: Theme.iconSize
	buttons: Qt.LeftButton | Qt.RightButton
	onClicked: Notifications.dnd = !Notifications.dnd // the right button (the left one opens the page)

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
}
