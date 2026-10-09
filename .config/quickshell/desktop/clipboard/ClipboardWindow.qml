pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs
import qs.control
import qs.services
import qs.widgets

// The clipboard, dropping out of the bar (a HangingPanel): the history on the left (text, images
// and files; pinned first), what's selected in full on the right (the text, the picture, the
// files). Type to search; ↑ ↓ pick; Enter copies it back as what it was and closes (an image
// pastes as an image, files as attachments). Under the preview: copy, pin, open (images, files) or
// save as a note (text), remove.
HangingPanel {
	id: root

	readonly property var entries: {
		const q = search.text.toLowerCase();
		const pinned = Clipboard.pins.map(p => Object.assign({ pinned: true }, p));
		const recent = Clipboard.history.filter(h => !Clipboard.isPinned(h)).map(h => Object.assign({ pinned: false }, h));
		return [...pinned, ...recent].filter(e => !q || root.words(e).toLowerCase().includes(q));
	}
	property int current: 0
	readonly property var entry: entries[current] ?? null

	function words(e: var): string {
		return e.kind === "text" ? e.text : e.kind === "files" ? e.paths.join(" ") : "image picture screenshot";
	}

	function name(path: string): string {
		return path.slice(path.lastIndexOf("/") + 1);
	}

	function title(e: var): string {
		if (e.kind === "image")
			return "Image";
		if (e.kind === "files")
			return e.paths.length === 1 ? name(e.paths[0]) : `${name(e.paths[0])} and ${e.paths.length - 1} more`;
		return e.text.trim().split("\n")[0];
	}

	function ago(time: real): string {
		const s = (Date.now() - time) / 1000;
		return s < 60 ? "now" : s < 3600 ? `${Math.floor(s / 60)}m` : s < 86400 ? `${Math.floor(s / 3600)}h` : `${Math.floor(s / 86400)}d`;
	}

	function choose(): void {
		if (!entry)
			return;
		Clipboard.copy(entry);
		Panel.clipboardOpen = false;
	}

	name: "clipboard"
	open: Panel.clipboardOpen
	panelWidth: Panel.clipboardWidth
	panelHeight: Panel.clipboardHeight
	onDismissed: Panel.clipboardOpen = false
	onEntriesChanged: current = Math.min(current, Math.max(0, entries.length - 1))

	// --- the list ---

	Item {
		id: left

		x: 16
		y: 16
		width: 360
		height: parent.height - 32

		TextField {
			id: search

			width: parent.width
			placeholder: "Search the clipboard"
			Component.onCompleted: focusField()
			onAccepted: root.choose()
			onTextChanged: root.current = 0
			Keys.onUpPressed: root.current = Math.max(0, root.current - 1)
			Keys.onDownPressed: root.current = Math.min(root.entries.length - 1, root.current + 1)
		}

		ListView {
			id: list

			y: search.height + 12
			width: parent.width
			height: parent.height - y
			clip: true
			spacing: 4
			model: root.entries
			currentIndex: root.current
			boundsBehavior: Flickable.StopAtBounds
			highlightMoveDuration: 0
			highlightResizeDuration: 0

			ScrollBoost {}

			delegate: Rectangle {
				id: row

				required property var modelData
				required property int index
				readonly property bool on: root.current === index

				width: ListView.view.width
				height: 54
				radius: 11
				color: on ? Qt.alpha(Theme.primary, 0.16) : hover.hovered ? Qt.alpha(Theme.overlay, 0.8) : "transparent"
				border.width: on ? 1 : 0
				border.color: Qt.alpha(Theme.primary, 0.5)

				HoverHandler {
					id: hover

					// the row under the pointer once it moves (not one that opened under a still pointer)
					property point from
					onHoveredChanged: from = point.position
					onPointChanged: if (hovered && Math.abs(point.position.x - from.x) + Math.abs(point.position.y - from.y) > 3) root.current = row.index
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: root.current = row.index
					onDoubleClicked: root.choose()
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

					Text {
						width: parent.width
						text: root.title(row.modelData)
						elide: Text.ElideRight
						maximumLineCount: 1
						textFormat: Text.PlainText
						color: Theme.fg
						font.family: row.modelData.kind === "text" ? Theme.fontMono : Theme.fontSans
						font.pixelSize: 13
					}

					Text {
						width: parent.width
						text: (row.modelData.pinned ? "Pinned · " : "") + (row.modelData.kind === "files" ? `${row.modelData.paths.length} file${row.modelData.paths.length > 1 ? "s" : ""} · ` : row.modelData.kind === "image" ? "Image · " : "") + root.ago(row.modelData.time)
						color: row.modelData.pinned ? Theme.primary : Theme.fgMuted
						font.family: Theme.fontSans
						font.pixelSize: 11
					}
				}
			}
		}

		Text {
			anchors.centerIn: list
			visible: root.entries.length === 0
			width: list.width - 40
			horizontalAlignment: Text.AlignHCenter
			wrapMode: Text.Wrap
			text: search.text ? "Nothing matches." : "Copy something (text, an image, a file): it shows up here."
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.pixelSize: 13
		}
	}

	// --- the preview ---

	Rectangle {
		id: preview

		anchors.left: left.right
		anchors.leftMargin: 14
		anchors.right: parent.right
		anchors.rightMargin: 16
		y: 16
		height: parent.height - 32
		radius: 14
		color: Qt.alpha(Theme.surface, 0.55)
		clip: true

		Row {
			id: head

			x: 16
			y: 12
			spacing: 8

			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: !root.entry ? "" : root.entry.kind === "image" ? "Image" : root.entry.kind === "files" ? (root.entry.paths.length === 1 ? "File" : `${root.entry.paths.length} files`) : `Text · ${root.entry.text.length} characters`
				color: Theme.fgMuted
				font.family: Theme.fontSans
				font.pixelSize: 12
				font.weight: Font.DemiBold
			}
		}

		// what it is, in full
		Item {
			x: 16
			y: head.y + head.height + 10
			width: parent.width - 32
			height: parent.height - y - actions.height - 24

			Flickable {
				anchors.fill: parent
				visible: root.entry?.kind === "text"
				contentHeight: fullText.implicitHeight
				clip: true
				boundsBehavior: Flickable.StopAtBounds

				ScrollBoost {}

				Text {
					id: fullText

					width: parent.width
					text: root.entry?.kind === "text" ? root.entry.text : ""
					textFormat: Text.PlainText
					wrapMode: Text.WrapAnywhere
					color: Theme.fg
					font.family: Theme.fontMono
					font.pixelSize: 12
				}
			}

			Image {
				anchors.fill: parent
				visible: root.entry?.kind === "image"
				source: root.entry?.kind === "image" ? "file://" + root.entry.path : ""
				sourceSize.width: 1024
				fillMode: Image.PreserveAspectFit
				asynchronous: true
			}

			ListView {
				anchors.fill: parent
				visible: root.entry?.kind === "files"
				model: root.entry?.kind === "files" ? root.entry.paths : []
				spacing: 6
				clip: true

				delegate: Row {
					required property string modelData

					spacing: 10

					Glyph {
						anchors.verticalCenter: parent.verticalCenter
						glyph: Icons.g("file")
						font.pixelSize: 16
						color: Theme.primary
					}

					Column {
						Text {
							text: root.name(parent.parent.modelData)
							color: Theme.fg
							font.family: Theme.fontSans
							font.pixelSize: 13
						}

						Text {
							text: parent.parent.modelData.slice(0, parent.parent.modelData.lastIndexOf("/")).replace(Quickshell.env("HOME"), "~")
							color: Theme.fgMuted
							font.family: Theme.fontSans
							font.pixelSize: 11
						}
					}
				}
			}
		}

		// what can be done with it
		Row {
			id: actions

			visible: !!root.entry
			x: 16
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 14
			spacing: 8

			Chip {
				glyph: Icons.g("copy")
				label: "Copy"
				on: true
				onClicked: root.choose()
			}

			Chip {
				glyph: Icons.g("pin")
				label: root.entry?.pinned ? "Unpin" : "Pin"
				onClicked: Clipboard.pin(root.entry)
			}

			Chip {
				visible: root.entry?.kind !== "text"
				glyph: Icons.g("external-link")
				label: "Open"
				onClicked: {
					Quickshell.execDetached(["desktop-file", "open", root.entry.kind === "image" ? root.entry.path : root.entry.paths[0]]);
					Panel.clipboardOpen = false;
				}
			}

			Chip {
				visible: root.entry?.kind === "text"
				glyph: Icons.g("notes")
				label: "Save as a note"
				onClicked: {
					Notes.addSnippet(root.entry.text);
					Panel.clipboardOpen = false;
					Panel.controlPage = "notes";
					Panel.controlOpen = true;
				}
			}

			Chip {
				glyph: Icons.g("trash")
				label: "Remove"
				onClicked: Clipboard.remove(root.entry)
			}
		}

		Text {
			anchors.centerIn: parent
			visible: !root.entry
			text: "Nothing selected."
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.pixelSize: 13
		}
	}

	// clear the history (pins stay): top right, beside the preview's title
	Chip {
		anchors.right: preview.right
		anchors.rightMargin: 12
		y: preview.y + 8
		visible: Clipboard.history.length > 0
		glyph: Icons.g("trash")
		label: "Clear"
		onClicked: Clipboard.clear()
	}
}
