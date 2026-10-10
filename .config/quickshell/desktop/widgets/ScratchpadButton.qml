import QtQuick
import qs
import qs.services

// The scratchpad, after the workspaces: how many windows it holds, while it holds any; the accent
// while one of them is out on screen. A click brings one up (or puts it back).
Item {
	id: root

	readonly property bool present: WindowManager.scratchpad > 0
	readonly property bool out: WindowManager.scratchpadShown > 0

	visible: present
	implicitWidth: line.implicitWidth
	implicitHeight: line.implicitHeight

	Line {
		id: line

		vertical: Config.vertical
		spacing: 4

		Glyph {
			glyph: Icons.g("stack-2")
			font.pixelSize: Theme.iconSize - 2
			font.weight: Font.Normal
			color: root.out ? Theme.primary : hover.containsMouse ? Theme.fg : Theme.fgMuted
		}

		Label {

			font.family: Theme.fontBar
			text: WindowManager.scratchpad
			color: root.out ? Theme.primary : hover.containsMouse ? Theme.fg : Theme.fgMuted
			font.pixelSize: Theme.fontSize - 1
		}
	}

	MouseArea {
		id: hover

		anchors.fill: parent
		anchors.margins: -6
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: WindowManager.showScratchpad()
	}
}
