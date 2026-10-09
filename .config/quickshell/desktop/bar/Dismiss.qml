import QtQuick
import Quickshell
import Quickshell.I3
import qs

// A transparent catcher over the focused screen with a hole where an open panel is: a click
// anywhere else (the desktop, the bar, another window) dismisses the panel. The hole keeps it out
// of the panel's way whatever their stacking order.
PopupWindow {
	id: root

	required property PanelWindow bar
	property bool open
	property rect hole // from the screen's origin
	signal dismissed

	anchor.window: bar
	anchor.rect.x: Config.position === "right" ? bar.width - implicitWidth : 0
	anchor.rect.y: Config.position === "bottom" ? bar.height - implicitHeight : 0
	implicitWidth: bar.screen.width
	implicitHeight: bar.screen.height
	visible: open && I3.focusedMonitor?.name === bar.screen?.name
	color: "transparent"
	mask: Region {
		width: root.width
		height: root.height

		Region {
			intersection: Intersection.Subtract
			x: root.hole.x
			y: root.hole.y
			width: root.hole.width
			height: root.hole.height
		}
	}

	MouseArea {
		anchors.fill: parent
		acceptedButtons: Qt.AllButtons
		onPressed: root.dismissed()
	}
}
