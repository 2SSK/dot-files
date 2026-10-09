import QtQuick
import qs

// An on/off switch; a click calls toggled(!checked).
Rectangle {
	id: root

	property bool checked
	signal toggled(bool checked)

	implicitWidth: 44
	implicitHeight: 24
	radius: 12
	color: checked ? Theme.primary : Qt.alpha(Theme.overlay, 0.9)

	Behavior on color {
		ColorAnimation {
			duration: 150
		}
	}

	Rectangle {
		width: 18
		height: 18
		radius: 9
		y: 3
		x: root.checked ? root.width - width - 3 : 3
		color: root.checked ? Theme.onPrimary : Theme.fg

		Behavior on x {
			NumberAnimation {
				duration: 160
				easing.type: Easing.OutCubic
			}
		}
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: root.toggled(!root.checked)
	}
}
