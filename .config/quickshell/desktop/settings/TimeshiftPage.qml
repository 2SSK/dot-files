pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.control
import qs.services
import qs.widgets

// Timeshift: the system's snapshots, newest first, each with its kind (on demand, boot, hourly,
// daily, weekly, monthly) and comment; a snapshot now, with a comment; delete one (a second press
// confirms). Making and deleting ask for the password; restoring is Timeshift's own app's job.
Column {
	id: root

	readonly property var kinds: ({ O: "On demand", B: "Boot", H: "Hourly", D: "Daily", W: "Weekly", M: "Monthly" })
	property string armed: "" // the snapshot waiting for its confirming press

	function when(name: string): string {
		const [d, t] = name.split("_");
		const date = new Date(`${d}T${t.replace(/-/g, ":")}`);
		return Qt.formatDateTime(date, new Date().getFullYear() === date.getFullYear() ? "ddd d MMM, hh:mm AP" : "d MMM yyyy, hh:mm AP");
	}

	spacing: 18
	Component.onCompleted: Timeshift.refresh(false)

	Section {
		title: "New snapshot"

		Row {
			width: parent.width
			spacing: 8

			TextField {
				id: comment

				width: parent.width - snap.width - 8
				placeholder: "A comment (what it's before), and Enter"
				onAccepted: value => {
					Timeshift.create(value);
					comment.text = "";
				}
			}

			Chip {
				id: snap

				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g("history")
				label: "Snapshot now"
				on: Timeshift.state !== "working"
				onClicked: {
					Timeshift.create(comment.text);
					comment.text = "";
				}
			}
		}

		Text {
			visible: Timeshift.state === "working"
			topPadding: 6
			text: Timeshift.working + " (Timeshift asks for your password first)"
			color: Theme.primary
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: 12
		}
	}

	Section {
		title: Timeshift.info.mode ? `Snapshots  ·  ${Timeshift.info.mode}  ·  ${Timeshift.info.free}` : "Snapshots"

		// without the passwordless list: how to get it, or list once with the password
		Column {
			visible: Timeshift.state === "rule" || Timeshift.state === "error"
			width: parent.width
			spacing: 10

			Text {
				width: parent.width
				wrapMode: Text.Wrap
				text: Timeshift.state === "rule" ? "Listing snapshots needs root. Run packages/system.sh timeshift once to allow just the list without a password, or show it now with your password." : "Couldn't read the snapshots."
				color: Theme.fgMuted
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.pixelSize: 13
			}

			Chip {
				label: "Show snapshots"
				glyph: Icons.g("lock")
				onClicked: Timeshift.refresh(true)
			}
		}

		Text {
			visible: Timeshift.state === "loading"
			text: "Reading the snapshots…"
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: 13
		}

		Text {
			visible: Timeshift.state === "" && Timeshift.snapshots.length === 0
			text: "No snapshots yet."
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.pixelSize: 13
		}

		Repeater {
			model: Timeshift.snapshots

			delegate: Rectangle {
				id: snapshot

				required property var modelData
				readonly property bool armed: root.armed === modelData.name

				width: root.width
				height: 52
				radius: 12
				color: hover.hovered ? Qt.alpha(Theme.overlay, 0.9) : Qt.alpha(Theme.surface, 0.8)

				HoverHandler {
					id: hover

					onHoveredChanged: if (!hovered && snapshot.armed) root.armed = ""
				}

				Column {
					x: 16
					anchors.verticalCenter: parent.verticalCenter
					spacing: 2

					Text {
						text: root.when(snapshot.modelData.name)
						color: Theme.fg
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: 14
						font.weight: Font.Medium
					}

					Text {
						text: [snapshot.modelData.tags.split("").filter(t => root.kinds[t]).map(t => root.kinds[t]).join(", "), snapshot.modelData.comment].filter(s => s).join("  ·  ")
						color: Theme.fgMuted
						font.family: Theme.fontSans
						font.hintingPreference: Theme.hinting
						font.pixelSize: 12
					}
				}

				Chip {
					anchors.right: parent.right
					anchors.rightMargin: 10
					anchors.verticalCenter: parent.verticalCenter
					visible: hover.hovered || snapshot.armed
					glyph: Icons.g("trash")
					label: snapshot.armed ? "Delete?" : ""
					on: snapshot.armed
					onClicked: {
						if (snapshot.armed) {
							root.armed = "";
							Timeshift.remove(snapshot.modelData.name);
						} else {
							root.armed = snapshot.modelData.name;
						}
					}
				}
			}
		}
	}

	Section {
		title: "Restore"

		Row {
			spacing: 8

			Chip {
				glyph: Icons.g("external-link")
				label: "Open Timeshift to restore"
				onClicked: Timeshift.openApp()
			}

			Chip {
				glyph: Icons.g("refresh")
				label: "Refresh"
				onClicked: Timeshift.refresh(Timeshift.state === "rule")
			}
		}
	}
}
