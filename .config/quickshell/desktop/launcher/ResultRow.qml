pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.services
import qs.widgets

// A row of the launcher's list: an app, a file (with open, attach and copy buttons while picked or
// hovered), or with a path search a folder, which a click opens a terminal in.
Item {
	id: row

	required property var modelData
	required property int index
	property bool selected
	signal moved // the pointer moved over it: select it
	signal picked(string action) // open (an app, or a file in its app), file, path or content
	readonly property bool app: typeof modelData !== "string"
	readonly property string path: typeof modelData === "string" ? modelData : ""
	readonly property bool folder: path.endsWith("/")
	readonly property string fileName: Format.fileName(path.replace(/\/$/, ""))
	readonly property string ext: fileName.includes(".") ? fileName.slice(fileName.lastIndexOf(".") + 1).toLowerCase() : ""
	readonly property string kind: folder ? "folder" : /^(png|jpe?g|webp|gif|svg)$/.test(ext) ? "photo" : ext === "pdf" ? "file-type-pdf" : /^(md|txt|org|rst|)$/.test(ext) ? "file-text" : "file-code"

	width: ListView.view.width
	height: 50

	PointerPick {
		id: rowHover

		onMoved: row.moved()
	}

	MouseArea {
		anchors.fill: parent
		cursorShape: Qt.PointingHandCursor
		onClicked: row.picked(row.app || row.folder ? "open" : "file")
	}

	IconImage {
		id: icon

		visible: row.app
		x: 12
		anchors.verticalCenter: parent.verticalCenter
		implicitSize: 30
		source: row.app ? Quickshell.iconPath(row.modelData.icon, "application-x-executable") : ""
		asynchronous: true
	}

	Glyph {
		visible: !row.app
		x: 16
		anchors.verticalCenter: parent.verticalCenter
		glyph: Icons.g(row.kind)
		font.pixelSize: 20
		color: Theme.primary
	}

	Column {
		x: 54
		anchors.verticalCenter: parent.verticalCenter
		width: parent.width - x - (tools.visible ? tools.width + 16 : 12)
		spacing: 1

		UiText {
			width: parent.width
			text: row.app ? row.modelData.name : row.fileName
			elide: Text.ElideRight
			font.weight: Font.Medium
		}

		UiText {
			width: parent.width
			visible: text !== ""
			text: row.app ? (row.modelData.genericName || row.modelData.comment || "") : Format.folder(row.path.replace(/\/$/, ""))
			elide: row.app ? Text.ElideRight : Text.ElideMiddle
			color: Theme.fgMuted
			font.pixelSize: Theme.textLabel
		}
	}

	Row {
		id: tools

		visible: !row.app && (rowHover.hovered || row.selected)
		anchors.right: parent.right
		anchors.rightMargin: 10
		anchors.verticalCenter: parent.verticalCenter
		spacing: 4

		Repeater {
			model: [
				{ glyph: "external-link", action: "open" },
				{ glyph: "paperclip", action: "file" },
				{ glyph: "link", action: "path" },
				{ glyph: "copy", action: "content" }
			]

			delegate: Rectangle {
				id: tool

				required property var modelData

				width: 30
				height: 30
				radius: 9
				color: toolHover.hovered ? Qt.alpha(Theme.fg, 0.12) : "transparent"

				Glyph {
					anchors.centerIn: parent
					glyph: Icons.g(tool.modelData.glyph)
					font.pixelSize: 15
				}

				HoverHandler {
					id: toolHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: row.picked(tool.modelData.action)
				}
			}
		}
	}
}
