import QtQuick
import qs

// A button in the bar: an icon that turns the accent colour, filled, while what it opens shows. With
// `page`, a control center page: a click opens it there (again closes it), and it is active while
// that page shows; otherwise `active` and the clicked signal are the caller's. A click lands a few
// pixels around the icon too.
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
