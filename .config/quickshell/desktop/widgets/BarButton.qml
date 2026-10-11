import QtQuick
import qs

// A bar button, an icon in the accent colour while what it opens shows. With `page` a click opens
// or closes that control center page; otherwise `active` and clicked are the caller's.
Glyph {
	id: root

	property string page: ""
	property bool active: page !== "" && Panel.showing(page)
	property color idleColor: Theme.fg
	property int buttons: Qt.LeftButton
	signal clicked(var event)

	color: active ? Theme.primary : idleColor
	filled: active
	font.pixelSize: Theme.iconSize - 1
	font.weight: Font.Normal

	MouseArea {
		anchors.fill: parent
		anchors.margins: -6
		acceptedButtons: root.buttons
		cursorShape: Qt.PointingHandCursor
		onClicked: event => {
			if (root.page && event.button === Qt.LeftButton)
				Panel.toggleControl(root.page);
			else
				root.clicked(event);
		}
	}
}
