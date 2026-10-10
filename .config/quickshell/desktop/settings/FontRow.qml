pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.control
import qs.widgets

// A font setting: the row shows the font in use, written in it; a click opens the installed fonts
// below (each in its own face), searchable, and picking one sets it. mono: only monospaced-looking
// families (by name: mono, code, console, term), for code.
Column {
	id: root

	property string label
	property string hint
	property string value
	property bool mono
	property bool open
	signal picked(string family)

	readonly property var families: Qt.fontFamilies().filter(f => !mono || /mono|code|console|term|courier|fixed/i.test(f))
	readonly property var shown: families.filter(f => f.toLowerCase().includes(search.text.toLowerCase()))

	width: parent?.width ?? 0
	spacing: 6

	SettingRow {
		label: root.label
		hint: root.hint

		Rectangle {
			width: Math.min(260, name.implicitWidth + 44)
			height: 34
			radius: 10
			color: root.open ? Qt.alpha(Theme.primary, 0.18) : hover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.overlay, 0.7)

			Behavior on color {
				ColorAnimation {
					duration: 140
				}
			}

			Text {
				id: name

				x: 14
				width: parent.width - 40
				anchors.verticalCenter: parent.verticalCenter
				text: root.value
				elide: Text.ElideRight
				color: Theme.fg
				font.family: root.value
				font.hintingPreference: Theme.hinting
				font.pixelSize: Theme.textBody
				font.weight: Theme.textWeight
			}

			Glyph {
				anchors.right: parent.right
				anchors.rightMargin: 10
				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g("chevron-down")
				rotation: root.open ? 180 : 0
				font.pixelSize: 14
				color: Theme.fgMuted

				Behavior on rotation {
					NumberAnimation {
						duration: 160
						easing.type: Easing.OutCubic
					}
				}
			}

			HoverHandler {
				id: hover
			}

			MouseArea {
				anchors.fill: parent
				cursorShape: Qt.PointingHandCursor
				onClicked: {
					root.open = !root.open;
					if (root.open)
						search.focusField();
				}
			}
		}
	}

	// the fonts, while open
	Rectangle {
		visible: root.open
		width: parent.width
		height: 300
		radius: 12
		color: Qt.alpha(Theme.surface, 0.55)

		TextField {
			id: search

			x: 10
			y: 10
			width: parent.width - 20
			placeholder: `Search ${root.families.length} fonts`
			onKeyPressed: event => {
				if (event.key === Qt.Key_Escape) {
					root.open = false;
					event.accepted = true;
				}
			}
			onAccepted: if (root.shown.length > 0) root.choose(root.shown[0])
		}

		ListView {
			id: list

			ScrollBoost {}

			x: 6
			anchors.top: search.bottom
			anchors.topMargin: 8
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 6
			width: parent.width - 12
			clip: true
			model: root.shown
			boundsBehavior: Flickable.StopAtBounds

			delegate: Rectangle {
				id: entry

				required property string modelData
				readonly property bool on: modelData === root.value

				width: ListView.view.width
				height: 40
				radius: 9
				color: on ? Qt.alpha(Theme.primary, 0.18) : entryHover.hovered ? Qt.alpha(Theme.fg, 0.08) : "transparent"

				Text {
					x: 12
					width: parent.width - 24
					anchors.verticalCenter: parent.verticalCenter
					text: entry.modelData
					elide: Text.ElideRight
					color: entry.on ? Theme.primary : Theme.fg
					font.family: entry.modelData
					font.hintingPreference: Theme.hinting
					font.pixelSize: Theme.textBody
				}

				HoverHandler {
					id: entryHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: root.choose(entry.modelData)
				}
			}
		}
	}

	function choose(family: string): void {
		open = false;
		search.text = "";
		picked(family);
	}
}
