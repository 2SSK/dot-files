pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Widgets
import qs
import qs.services
import qs.widgets

// An entry of the clipboard's history: a thumbnail for a picture (an icon for text or files), its
// headline, and pinned, how many files, how long ago.
Rectangle {
	id: row

	required property var modelData
	required property int index
	property bool selected // the one Enter copies
	readonly property bool on: selected
	property string headline // its first line, a file's name, or "Image"
	signal moved // the pointer moved over it: select it
	signal picked // clicked: select it
	signal activated // double-clicked: copy it and paste it

	width: ListView.view.width
	height: 54
	radius: 11
	color: on ? Qt.alpha(Theme.primary, 0.16) : hover.hovered ? Qt.alpha(Theme.overlay, 0.8) : "transparent"
	border.width: on ? 1 : 0
	border.color: Qt.alpha(Theme.primary, 0.5)

	PointerPick {
		id: hover

		onMoved: row.moved()
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: row.picked()
		onDoubleClicked: row.activated()
	}

	// a thumbnail for a picture, else an icon for its kind
	Item {
		id: lead

		x: 10
		anchors.verticalCenter: parent.verticalCenter
		width: 40
		height: 40

		ClippingRectangle {
			visible: row.modelData.kind === "image"
			anchors.fill: parent
			radius: 8
			color: Qt.alpha(Theme.surface, 0.8)

			Image {
				anchors.fill: parent
				source: row.modelData.kind === "image" ? "file://" + row.modelData.path : ""
				sourceSize.width: 80
				fillMode: Image.PreserveAspectCrop
				asynchronous: true
			}
		}

		Glyph {
			visible: row.modelData.kind !== "image"
			anchors.centerIn: parent
			glyph: Icons.g(row.modelData.kind === "files" ? "paperclip" : "file-text")
			font.pixelSize: 18
			color: row.on ? Theme.primary : Theme.fgMuted
		}
	}

	Column {
		anchors.left: lead.right
		anchors.leftMargin: 10
		anchors.right: parent.right
		anchors.rightMargin: 12
		anchors.verticalCenter: parent.verticalCenter
		spacing: 3

		UiText {
			width: parent.width
			text: row.headline
			elide: Text.ElideRight
			maximumLineCount: 1
			textFormat: Text.PlainText
			font.family: row.modelData.kind === "text" ? Theme.fontMono : Theme.fontSans
		}

		UiText {
			width: parent.width
			text: (row.modelData.pinned ? "Pinned · " : "") + (row.modelData.kind === "files" ? `${row.modelData.paths.length} file${row.modelData.paths.length > 1 ? "s" : ""} · ` : row.modelData.kind === "image" ? "Image · " : "") + Format.ago(row.modelData.time)
			color: row.modelData.pinned ? Theme.primary : Theme.fgMuted
			font.pixelSize: Theme.textCaption
		}
	}
}
