pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs
import qs.control
import qs.services
import qs.widgets

// Settings → About: this machine and this desktop (AboutInfo reads them ahead, so the page shows at
// once, and again behind it each time it opens). A click on a line copies it; Copy all copies them all
// (for a bug report).
Column {
	id: page

	spacing: 24
	onVisibleChanged: if (visible) AboutInfo.refresh()

	readonly property var facts: AboutInfo.facts // [{ section, label, value }]

	function copy(text: string): void {
		Quickshell.execDetached(["sh", "-c", 'printf %s "$1" | desktop clipboard copy text', "sh", text]);
	}

	Repeater {
		model: ["System", "Desktop"]

		delegate: Section {
			id: group

			required property string modelData

			title: modelData

			Repeater {
				model: page.facts.filter(f => f.section === group.modelData)

				delegate: SettingRow {
					id: fact

					required property var modelData

					label: modelData.label
					hint: modelData.value

					Glyph {
						glyph: Icons.g("copy")
						color: factHover.hovered ? Theme.fg : Qt.alpha(Theme.fgMuted, 0.6)
						font.pixelSize: 14
					}

					HoverHandler {
						id: factHover

						parent: fact
					}

					MouseArea {
						parent: fact
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: page.copy(fact.modelData.value)
					}
				}
			}
		}
	}

	SmallButton {
		visible: page.facts.length > 0
		text: "Copy all"
		onClicked: page.copy(page.facts.map(f => `${f.label}: ${f.value}`).join("\n"))
	}
}
