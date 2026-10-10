pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// Notes: a searchable list (pinned first, then the latest) beside the note being edited. A note is
// text, a checklist or code, with a colour tag; the header makes a new one, pins or deletes it.
// Kept on this machine only (see Notes).
Item {
	id: root

	readonly property string title: "Notes"
	readonly property var actions: [
		{ glyph: Icons.g("plus"), on: false, act: () => Notes.create("text", "", "") },
		{ glyph: Notes.current?.pinned ? Icons.g("pin") : Icons.g("pin"), on: Notes.current?.pinned ?? false, act: () => Notes.update(Notes.selected, { pinned: !Notes.current.pinned }), show: Notes.current !== null },
		{ glyph: Icons.g("trash"), on: false, act: () => Notes.remove(Notes.selected), show: Notes.current !== null }
	]
	property string query: ""
	readonly property var shown: Notes.sorted.filter(n => !query || [n.title, n.body, ...(n.items ?? []).map(i => i.text)].join("\n").toLowerCase().includes(query.toLowerCase()))

	implicitHeight: 540

	// the list
	Column {
		id: side

		width: 230
		height: parent.height
		spacing: 8

		TextField {
			id: search

			width: parent.width
			placeholder: "Search notes"
			onTextChanged: root.query = text
		}

		ListView {
			width: parent.width
			height: parent.height - search.height - 8
			clip: true
			spacing: 6
			model: root.shown
			boundsBehavior: Flickable.StopAtBounds

			delegate: Rectangle {
				id: entry

				required property var modelData
				readonly property bool on: Notes.selected === modelData.id

				width: ListView.view.width
				height: 54
				radius: 11
				color: on ? Qt.alpha(Theme.primary, 0.18) : hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)
				border.width: on ? 1 : 0
				border.color: Qt.alpha(Theme.primary, 0.6)

				HoverHandler {
					id: hover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: Notes.selected = entry.modelData.id
				}

				Rectangle {
					x: 0
					y: 10
					width: 3
					height: parent.height - 20
					radius: 2
					visible: entry.modelData.tag && entry.modelData.tag !== "none"
					color: Notes.tags[entry.modelData.tag] ?? "transparent"
				}

				Glyph {
					id: kind

					x: 12
					anchors.verticalCenter: parent.verticalCenter
					glyph: Notes.glyph(entry.modelData.type)
					font.pixelSize: 15
					font.weight: Font.Normal
					color: entry.on ? Theme.primary : Theme.fgMuted
				}

				Column {
					anchors.left: kind.right
					anchors.leftMargin: 10
					anchors.right: pin.left
					anchors.rightMargin: 6
					anchors.verticalCenter: parent.verticalCenter
					spacing: 2

					Text {
						width: parent.width
						text: Notes.heading(entry.modelData)
						elide: Text.ElideRight
						color: Theme.fg
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: 13
						font.weight: Font.Medium
					}

					Text {
						width: parent.width
						text: Qt.formatDateTime(new Date(entry.modelData.updated), new Date(entry.modelData.updated).toDateString() === new Date().toDateString() ? "hh:mm AP" : "d MMM")
						color: Theme.fgMuted
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: 11
					}
				}

				Glyph {
					id: pin

					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.verticalCenter: parent.verticalCenter
					visible: entry.modelData.pinned
					filled: true
					glyph: Icons.g("pin")
					font.pixelSize: 13
					color: Theme.primary
				}
			}
		}

		Text {
			visible: root.shown.length === 0
			width: parent.width
			horizontalAlignment: Text.AlignHCenter
			text: root.query ? "Nothing matches." : "No notes yet."
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: 12
		}
	}

	// the note
	Rectangle {
		anchors.left: side.right
		anchors.leftMargin: 12
		anchors.right: parent.right
		height: parent.height
		radius: 14
		color: Qt.alpha(Theme.surface, 0.6)

		// nothing chosen: start one
		Column {
			anchors.centerIn: parent
			visible: Notes.current === null
			spacing: 12

			Text {
				anchors.horizontalCenter: parent.horizontalCenter
				text: "A new note"
				color: Theme.fgMuted
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.pixelSize: 13
			}

			Row {
				spacing: 8

				Repeater {
					model: Notes.types

					delegate: Rectangle {
						id: starter

						required property var modelData

						width: 96
						height: 70
						radius: 12
						color: starterHover.hovered ? Qt.alpha(Theme.primary, 0.18) : Qt.alpha(Theme.overlay, 0.8)

						Column {
							anchors.centerIn: parent
							spacing: 6

							Glyph {
								anchors.horizontalCenter: parent.horizontalCenter
								glyph: starter.modelData.glyph
								font.pixelSize: 18
								font.weight: Font.Normal
								color: Theme.fg
							}

							Text {
								anchors.horizontalCenter: parent.horizontalCenter
								text: starter.modelData.label
								color: Theme.fg
								font.family: Theme.fontSans
								font.hintingPreference: Theme.hinting
								font.pixelSize: 12
							}
						}

						HoverHandler {
							id: starterHover
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: Notes.create(starter.modelData.key, "", "")
						}
					}
				}
			}
		}

		// rebuilt for each note and type, so typing never echoes back into the editor
		Loader {
			anchors.fill: parent
			anchors.margins: 16
			active: Notes.current !== null
			sourceComponent: editor
			property string key: `${Notes.selected}/${Notes.current?.type}`
			onKeyChanged: if (active) { active = false; active = true; }
		}
	}

	Component {
		id: editor

		NoteEditor {}
	}
}
