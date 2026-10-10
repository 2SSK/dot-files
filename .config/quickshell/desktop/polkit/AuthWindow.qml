pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import qs
import qs.control
import qs.widgets

// The shell's password prompt for apps asking for admin rights (polkit: pkexec, Timeshift, ...),
// dropping out of the bar like the other panels. What is asked, the password (Enter), Cancel or
// Escape; a wrong password shakes it and says so, and it asks again.
HangingPanel {
	id: root

	required property PolkitAgent agent
	readonly property AuthFlow flow: agent.flow

	function cancel(): void {
		flow?.cancelAuthenticationRequest();
	}

	name: "authentication"
	open: Panel.authOpen
	panelWidth: 480
	panelHeight: 250
	onDismissed: cancel()
	Component.onCompleted: password.focusField()

	Column {
		x: 24
		y: 22
		width: parent.width - 48
		spacing: 14

		Row {
			spacing: 12

			Glyph {
				anchors.verticalCenter: parent.verticalCenter
				glyph: Icons.g("lock")
				filled: true
				font.pixelSize: 22
				color: Theme.primary
			}

			Text {
				anchors.verticalCenter: parent.verticalCenter
				text: "Authentication required"
				color: Theme.fg
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.pixelSize: Theme.px(17)
				font.weight: Font.DemiBold
			}
		}

		Text {
			width: parent.width
			text: root.flow?.message ?? ""
			wrapMode: Text.Wrap
			maximumLineCount: 3
			elide: Text.ElideRight
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.hintingPreference: Theme.hinting
			font.weight: Theme.textWeight
			font.pixelSize: Theme.textBody
		}

		TextField {
			id: password

			width: parent.width
			password: !(root.flow?.responseVisible ?? false)
			placeholder: (root.flow?.inputPrompt ?? "").replace(/:\s*$/, "") || "Password"
			onAccepted: value => {
				root.flow?.submit(value);
				password.text = "";
			}

			SequentialAnimation on x {
				id: shake

				running: false
				loops: 2
				NumberAnimation { to: -8; duration: 45 }
				NumberAnimation { to: 8; duration: 90 }
				NumberAnimation { to: 0; duration: 45 }
			}
		}

		Item {
			width: parent.width
			height: 34

			Text {
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width - cancelChip.width - 12
				text: root.flow?.supplementaryMessage ?? ""
				elide: Text.ElideRight
				color: root.flow?.supplementaryIsError ? Theme.error : Theme.fgMuted
				font.family: Theme.fontSans
				font.hintingPreference: Theme.hinting
				font.weight: Theme.textWeight
				font.pixelSize: Theme.textLabel
			}

			Chip {
				id: cancelChip

				anchors.right: parent.right
				label: "Cancel"
				onClicked: root.cancel()
			}
		}
	}

	Connections {
		target: root.flow

		function onAuthenticationFailed(): void {
			shake.start();
			password.focusField();
		}
	}
}
