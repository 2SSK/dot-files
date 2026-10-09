import QtQuick
import Quickshell

// The top bar of one screen: workspaces on the left, the clock in the middle. It floats 8 px from
// the screen edges; picom rounds its corners and gives it a shadow.
PanelWindow {
	id: bar

	required property ShellScreen modelData

	screen: modelData
	anchors {
		top: true
		left: true
		right: true
	}
	margins {
		top: 8
		left: 8
		right: 8
	}
	implicitHeight: 32
	color: Qt.alpha(Theme.surface, 0.92)

	Workspaces {
		screen: bar.modelData
		anchors.left: parent.left
		anchors.leftMargin: 6
		anchors.verticalCenter: parent.verticalCenter
	}

	Clock {
		anchors.centerIn: parent
	}
}
