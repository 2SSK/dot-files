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
	readonly property var types: [
		{ key: "text", glyph: Icons.g("note"), label: "Text" },
		{ key: "checklist", glyph: Icons.g("checkbox"), label: "Checklist" },
		{ key: "code", glyph: Icons.g("code"), label: "Code" }
	]
	readonly property var tags: ({ none: Theme.fgMuted, red: Theme.error, yellow: Theme.warning, green: Theme.success, blue: Theme.primary, purple: Theme.secondary })
	property string query: ""
	readonly property var shown: Notes.sorted.filter(n => !query || [n.title, n.body, ...(n.items ?? []).map(i => i.text)].join("\n").toLowerCase().includes(query.toLowerCase()))

	function glyph(type: string): string {
		return types.find(t => t.key === type)?.glyph ?? types[0].glyph;
	}

	function heading(note: var): string {
		return note.title || (note.type === "checklist" ? (note.items?.[0]?.text ?? "") : note.body.trim().split("\n")[0]) || "Untitled";
	}

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
					color: root.tags[entry.modelData.tag] ?? "transparent"
				}

				Glyph {
					id: kind

					x: 12
					anchors.verticalCenter: parent.verticalCenter
					glyph: root.glyph(entry.modelData.type)
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
						text: root.heading(entry.modelData)
						elide: Text.ElideRight
						color: Theme.fg
						font.family: Theme.fontSans
						font.pixelSize: 13
						font.weight: Font.Medium
					}

					Text {
						width: parent.width
						text: Qt.formatDateTime(new Date(entry.modelData.updated), new Date(entry.modelData.updated).toDateString() === new Date().toDateString() ? "hh:mm AP" : "d MMM")
						color: Theme.fgMuted
						font.family: Theme.fontSans
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
				font.pixelSize: 13
			}

			Row {
				spacing: 8

				Repeater {
					model: root.types

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

		Column {
			id: note

			readonly property var current: Notes.current
			readonly property string noteId: Notes.selected

			spacing: 12

			TextInput {
				id: titleField

				width: parent.width
				text: note.current.title
				color: Theme.fg
				selectionColor: Qt.alpha(Theme.primary, 0.4)
				font.family: Theme.fontSans
				font.pixelSize: 18
				font.weight: Font.DemiBold
				clip: true
				onTextEdited: Notes.update(note.noteId, { title: text })
				Component.onCompleted: if (!text) forceActiveFocus()
				// Enter (or Tab) goes on to the note itself
				Keys.onReturnPressed: body.item?.focusBody()
				Keys.onEnterPressed: body.item?.focusBody()
				KeyNavigation.tab: body.item

				Text {
					visible: titleField.text === ""
					text: "Title"
					color: Theme.fgMuted
					font: titleField.font
				}
			}

			// type and tag
			Row {
				spacing: 6

				Repeater {
					model: root.types

					delegate: Rectangle {
						id: typeChip

						required property var modelData
						readonly property bool on: note.current.type === modelData.key

						width: typeLabel.implicitWidth + 36
						height: 28
						radius: 14
						color: on ? Theme.primary : Qt.alpha(Theme.overlay, 0.8)

						Row {
							anchors.centerIn: parent
							spacing: 6

							Glyph {
								glyph: typeChip.modelData.glyph
								font.pixelSize: 12
								font.weight: Font.Normal
								color: typeChip.on ? Theme.primaryText : Theme.fg
							}

							Text {
								id: typeLabel

								text: typeChip.modelData.label
								color: typeChip.on ? Theme.primaryText : Theme.fg
								font.family: Theme.fontSans
								font.pixelSize: 12
								font.weight: Font.Medium
							}
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								// a text note's lines become checklist items, and back
								const change = { type: typeChip.modelData.key };
								if (change.type === "checklist" && note.current.type !== "checklist")
									change.items = note.current.body.split("\n").filter(l => l.trim()).map(text => ({ text, done: false }));
								if (change.type !== "checklist" && note.current.type === "checklist")
									change.body = (note.current.items ?? []).map(i => i.text).join("\n");
								Notes.update(note.noteId, change);
							}
						}
					}
				}

				Item {
					width: 10
					height: 1
				}

				Repeater {
					model: Object.keys(root.tags)

					delegate: Rectangle {
						id: tagDot

						required property string modelData
						readonly property bool on: (note.current.tag ?? "none") === modelData

						anchors.verticalCenter: parent.verticalCenter
						width: 18
						height: 18
						radius: 9
						color: modelData === "none" ? "transparent" : root.tags[modelData]
						border.width: on ? 2 : (modelData === "none" ? 1 : 0)
						border.color: on ? Theme.fg : Theme.fgMuted

						MouseArea {
							anchors.fill: parent
							anchors.margins: -3
							cursorShape: Qt.PointingHandCursor
							onClicked: Notes.update(note.noteId, { tag: tagDot.modelData })
						}
					}
				}
			}

			Loader {
				id: body

				width: parent.width
				height: parent.parent.height - titleField.height - 28 - 24
				sourceComponent: note.current.type === "checklist" ? checklistEditor : note.current.type === "code" ? codeEditor : textEditor
			}

			Component {
				id: textEditor

				Flickable {
					id: textFlick

					function focusBody(): void {
						prose.forceActiveFocus();
						prose.cursorPosition = prose.length;
					}

					contentHeight: prose.height
					clip: true
					boundsBehavior: Flickable.StopAtBounds

					// as tall as the area, so a click anywhere in it lands in the text
					TextEdit {
						id: prose

						width: parent.width
						height: Math.max(implicitHeight, textFlick.height)
						text: note.current.body
						wrapMode: TextEdit.Wrap
						color: Theme.fg
						selectionColor: Qt.alpha(Theme.primary, 0.4)
						font.family: Theme.fontSans
						font.pixelSize: 14
						onTextChanged: if (activeFocus) Notes.update(note.noteId, { body: text })
						Component.onCompleted: if (note.current.title) forceActiveFocus()

						Text {
							visible: prose.length === 0
							text: "Write something…"
							color: Theme.fgMuted
							font: prose.font
						}
					}
				}
			}

			Component {
				id: codeEditor

				Rectangle {
					function focusBody(): void {
						snippet.forceActiveFocus();
						snippet.cursorPosition = snippet.length;
					}

					radius: 10
					color: Qt.alpha(Theme.bg, 0.7)
					border.width: 1
					border.color: Qt.alpha(Theme.border, 0.8)

					Flickable {
						id: codeFlick

						anchors.fill: parent
						anchors.margins: 12
						contentHeight: snippet.height
						clip: true
						boundsBehavior: Flickable.StopAtBounds

						TextEdit {
							id: snippet

							width: parent.width
							height: Math.max(implicitHeight, codeFlick.height)
							text: note.current.body
							wrapMode: TextEdit.WrapAnywhere
							color: Theme.fg
							selectionColor: Qt.alpha(Theme.primary, 0.4)
							font.family: Theme.fontMono
							font.pixelSize: 13
							onTextChanged: if (activeFocus) Notes.update(note.noteId, { body: text })
							Component.onCompleted: if (note.current.title) forceActiveFocus()

							Text {
								visible: snippet.length === 0
								text: "Paste a command, a connection string…"
								color: Theme.fgMuted
								font: snippet.font
							}
						}
					}

					// copy the whole snippet
					Rectangle {
						anchors.right: parent.right
						anchors.top: parent.top
						anchors.margins: 8
						width: copyLabel.implicitWidth + 20
						height: 26
						radius: 13
						color: copyHover.hovered ? Theme.primary : Qt.alpha(Theme.overlay, 0.95)

						Text {
							id: copyLabel

							property bool copied: false

							anchors.centerIn: parent
							text: copied ? "Copied" : "Copy"
							color: copyHover.hovered ? Theme.primaryText : Theme.fg
							font.family: Theme.fontSans
							font.pixelSize: 12
							font.weight: Font.Medium

							Timer {
								id: copiedTimer

								interval: 1500
								onTriggered: copyLabel.copied = false
							}
						}

						HoverHandler {
							id: copyHover
						}

						MouseArea {
							anchors.fill: parent
							cursorShape: Qt.PointingHandCursor
							onClicked: {
								Quickshell.clipboardText = note.current.body;
								copyLabel.copied = true;
								copiedTimer.restart();
							}
						}
					}
				}
			}

			Component {
				id: checklistEditor

				Column {
					function focusBody(): void {
						adder.focusField();
					}

					spacing: 6

					Repeater {
						model: note.current.items ?? []

						delegate: Rectangle {
							id: line

							required property var modelData
							required property int index

							width: parent.width
							height: 38
							radius: 9
							color: lineHover.hovered ? Qt.alpha(Theme.overlay, 0.8) : "transparent"

							HoverHandler {
								id: lineHover
							}

							Rectangle {
								id: tick

								x: 8
								anchors.verticalCenter: parent.verticalCenter
								width: 18
								height: 18
								radius: 5
								color: line.modelData.done ? Theme.primary : "transparent"
								border.width: line.modelData.done ? 0 : 2
								border.color: Theme.fgMuted

								Glyph {
									anchors.centerIn: parent
									visible: line.modelData.done
									glyph: Icons.g("check")
									font.pixelSize: 11
									color: Theme.primaryText
								}

								MouseArea {
									anchors.fill: parent
									anchors.margins: -6
									cursorShape: Qt.PointingHandCursor
									onClicked: Notes.update(note.noteId, { items: note.current.items.map((item, i) => i === line.index ? { text: item.text, done: !item.done } : item) })
								}
							}

							Text {
								anchors.left: tick.right
								anchors.leftMargin: 10
								anchors.right: drop.left
								anchors.verticalCenter: parent.verticalCenter
								text: line.modelData.text
								elide: Text.ElideRight
								font.strikeout: line.modelData.done
								color: line.modelData.done ? Theme.fgMuted : Theme.fg
								font.family: Theme.fontSans
								font.pixelSize: 14
							}

							Glyph {
								id: drop

								anchors.right: parent.right
								anchors.rightMargin: 10
								anchors.verticalCenter: parent.verticalCenter
								opacity: lineHover.hovered ? 1 : 0
								glyph: Icons.g("x")
								font.pixelSize: 13
								font.weight: Font.Normal
								color: Theme.fgMuted

								MouseArea {
									anchors.fill: parent
									anchors.margins: -6
									cursorShape: Qt.PointingHandCursor
									onClicked: Notes.update(note.noteId, { items: note.current.items.filter((_, i) => i !== line.index) })
								}
							}
						}
					}

					TextField {
						id: adder

						width: parent.width
						placeholder: "Add an item and press Enter"
						Component.onCompleted: if (note.current.title) focusField()
						onAccepted: value => {
							if (!value.trim())
								return;
							Notes.update(note.noteId, { items: [...(note.current.items ?? []), { text: value.trim(), done: false }] });
							text = "";
						}
					}
				}
			}
		}
	}
}
