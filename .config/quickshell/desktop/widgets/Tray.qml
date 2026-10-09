pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs

// Tray icons: a click activates the app, a right click opens its menu.
Line {
	readonly property bool present: SystemTray.items.values.length > 0

	visible: present
	vertical: Config.vertical
	spacing: 8

	Repeater {
		model: SystemTray.items

		delegate: Item {
			id: entry

			required property SystemTrayItem modelData

			implicitWidth: Theme.fontSize + 2
			implicitHeight: Theme.fontSize + 2

			IconImage {
				anchors.fill: parent
				source: entry.modelData.icon
			}

			QsMenuAnchor {
				id: menu

				menu: entry.modelData.menu
				anchor.item: entry
			}

			MouseArea {
				anchors.fill: parent
				acceptedButtons: Qt.LeftButton | Qt.RightButton
				cursorShape: Qt.PointingHandCursor
				onClicked: event => {
					if (event.button === Qt.LeftButton && !entry.modelData.onlyMenu)
						entry.modelData.activate();
					else if (entry.modelData.hasMenu)
						menu.open();
				}
			}
		}
	}
}
