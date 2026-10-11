pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// The clipboard entry picked, in full: the text, the picture or the files; under it what can be
// done with it: copy, pin, open (a picture, files), save as a note (text), remove.
Rectangle {
	id: preview

	property var entry: null
	signal copied // Copy: back on the clipboard (and the panel closes)

	radius: 14
	color: Qt.alpha(Theme.surface, 0.55)
	clip: true

	Row {
		id: head

		x: 16
		y: 12
		spacing: 8

		UiText {
			anchors.verticalCenter: parent.verticalCenter
			text: !preview.entry ? "" : preview.entry.kind === "image" ? "Image" : preview.entry.kind === "files" ? (preview.entry.paths.length === 1 ? "File" : `${preview.entry.paths.length} files`) : `Text · ${preview.entry.text.length} characters`
			color: Theme.fgMuted
			font.family: Theme.fontHeading
			font.pixelSize: Theme.textLabel
			font.weight: Font.DemiBold
		}
	}

	Item {
		x: 16
		y: head.y + head.height + 10
		width: parent.width - 32
		height: parent.height - y - actions.height - 24

		Flickable {
			anchors.fill: parent
			visible: preview.entry?.kind === "text"
			contentHeight: fullText.implicitHeight
			clip: true
			boundsBehavior: Flickable.StopAtBounds

			ScrollBoost {}

			UiText {
				id: fullText

				width: parent.width
				text: preview.entry?.kind === "text" ? preview.entry.text : ""
				textFormat: Text.PlainText
				wrapMode: Text.WrapAnywhere
				font.family: Theme.fontMono
				font.pixelSize: Theme.textLabel
			}
		}

		Image {
			anchors.fill: parent
			visible: preview.entry?.kind === "image"
			source: preview.entry?.kind === "image" ? "file://" + preview.entry.path : ""
			sourceSize.width: 1024
			fillMode: Image.PreserveAspectFit
			asynchronous: true
		}

		ListView {
			anchors.fill: parent
			visible: preview.entry?.kind === "files"
			model: preview.entry?.kind === "files" ? preview.entry.paths : []
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
					UiText {
						text: Format.fileName(parent.parent.modelData)
					}

					UiText {
						text: Format.folder(parent.parent.modelData)
						color: Theme.fgMuted
						font.pixelSize: Theme.textCaption
					}
				}
			}
		}
	}

	Row {
		id: actions

		visible: !!preview.entry
		x: 16
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 14
		spacing: 8

		Chip {
			glyph: Icons.g("copy")
			label: "Copy"
			on: true
			onClicked: preview.copied()
		}

		Chip {
			glyph: Icons.g("pin")
			label: preview.entry?.pinned ? "Unpin" : "Pin"
			onClicked: Clipboard.pin(preview.entry)
		}

		Chip {
			visible: preview.entry?.kind !== "text"
			glyph: Icons.g("external-link")
			label: "Open"
			onClicked: {
				Quickshell.execDetached(["desktop-file", "open", preview.entry.kind === "image" ? preview.entry.path : preview.entry.paths[0]]);
				Panel.clipboardOpen = false;
			}
		}

		Chip {
			visible: preview.entry?.kind === "text"
			glyph: Icons.g("notes")
			label: "Save as a note"
			onClicked: {
				Notes.addSnippet(preview.entry.text);
				Panel.clipboardOpen = false;
				Panel.controlPage = "notes";
				Panel.controlOpen = true;
			}
		}

		Chip {
			glyph: Icons.g("trash")
			label: "Remove"
			onClicked: Clipboard.remove(preview.entry)
		}
	}

	UiText {
		anchors.centerIn: parent
		visible: !preview.entry
		text: "Nothing selected."
		color: Theme.fgMuted
	}
}
