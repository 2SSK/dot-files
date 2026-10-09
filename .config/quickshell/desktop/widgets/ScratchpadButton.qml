import QtQuick
import qs
import qs.services

// The scratchpad, after the workspaces: its window count while it holds any; a click brings one up.
Item {
	readonly property bool present: Scratchpad.count > 0

	visible: present
	implicitWidth: line.implicitWidth
	implicitHeight: line.implicitHeight

	Line {
		id: line

		vertical: Config.vertical
		spacing: 4

		Glyph {
			text: Icons.g("stack")
			font.pixelSize: Theme.iconSize - 2
			font.weight: Font.Normal
			color: hover.containsMouse ? Theme.fg : Theme.fgMuted
		}

		Label {
			text: Scratchpad.count
			color: hover.containsMouse ? Theme.fg : Theme.fgMuted
			font.pixelSize: Theme.fontSize - 1
		}
	}

	MouseArea {
		id: hover

		anchors.fill: parent
		anchors.margins: -6
		hoverEnabled: true
		cursorShape: Qt.PointingHandCursor
		onClicked: Scratchpad.show()
	}
}
