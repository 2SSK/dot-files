pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.widgets

// The note being edited (Notes → NotesPage, beside the list): its title, type and colour tag, then
// the text, the code (with a copy button) or the checklist. The body is kept once typing pauses.
Column {
	id: note

	readonly property var current: Notes.current
	readonly property string noteId: Notes.selected
	property string pendingId: ""
	property string pendingBody: ""

	// the body is kept once typing pauses, not at every key: each keep re-sorts the notes
	// and redraws the list. Switching notes or closing keeps what's pending at once.
	function typed(body: string): void {
		pendingId = noteId;
		pendingBody = body;
		keep.restart();
	}

	function flush(): void {
		if (keep.running) {
			keep.stop();
			Notes.update(pendingId, { body: pendingBody });
		}
	}

	onNoteIdChanged: flush()
	Component.onDestruction: flush()

	spacing: 12

	Timer {
		id: keep

		interval: 400
		onTriggered: Notes.update(note.pendingId, { body: note.pendingBody })
	}

	TextInput {
		id: titleField

		width: parent.width
		text: note.current.title
		color: Theme.fg
		selectionColor: Qt.alpha(Theme.primary, 0.4)
		font.family: Theme.fontHeading
		font.hintingPreference: Theme.hinting
		font.pixelSize: Theme.px(18)
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
			model: Notes.types

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
						font.hintingPreference: Theme.hinting
						font.pixelSize: Theme.textLabel
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
			model: Object.keys(Notes.tags)

			delegate: Rectangle {
				id: tagDot

				required property string modelData
				readonly property bool on: (note.current.tag ?? "none") === modelData

				anchors.verticalCenter: parent.verticalCenter
				width: 18
				height: 18
				radius: 9
				color: modelData === "none" ? "transparent" : Notes.tags[modelData]
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
				font.hintingPreference: Theme.hinting
				font.weight: Theme.textWeight
				font.pixelSize: Theme.textBody
				onTextChanged: if (activeFocus) note.typed(text)
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
					font.hintingPreference: Theme.hinting
					font.weight: Theme.textWeight
					font.pixelSize: Theme.textBody
					onTextChanged: if (activeFocus) note.typed(text)
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
					font.hintingPreference: Theme.hinting
					font.pixelSize: Theme.textLabel
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
						font.hintingPreference: Theme.hinting
						font.weight: Theme.textWeight
						font.pixelSize: Theme.textBody
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
