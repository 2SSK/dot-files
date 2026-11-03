import QtQuick
import qs
import qs.services

// The bell, struck through while Do Not Disturb is on: on the island a dot when something new arrived,
// on the static bar how many (dim at none). A click opens the control center's notifications, a right
// click toggles Do Not Disturb.
Line {
	id: root

	readonly property bool count: !Config.island && !Config.vertical

	vertical: Config.vertical
	spacing: 6

	BarButton {
		glyph: Notifications.dnd ? Icons.g("bell-off") : Icons.g("bell")
		page: "notifications"
		idleColor: Notifications.dnd ? Theme.fgMuted : Theme.fg
		font.pixelSize: Theme.iconSize
		buttons: Qt.LeftButton | Qt.RightButton
		onClicked: Notifications.dnd = !Notifications.dnd // the right button (the left one opens the page)

		Rectangle {
			visible: !root.count && Notifications.unread > 0 && !Notifications.dnd
			anchors.right: parent.right
			anchors.top: parent.top
			anchors.topMargin: 1
			width: 7
			height: 7
			radius: 4
			color: Theme.primary
		}
	}

	Label {
		visible: root.count
		text: Notifications.unread
		color: Notifications.unread > 0 && !Notifications.dnd ? Theme.fg : Theme.fgMuted
		font.family: Theme.fontBar
		font.weight: Theme.barWeight
	}
}
