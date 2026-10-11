pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Services.Polkit
import qs
import qs.widgets

// The shell's password prompt for apps asking for admin rights (polkit: pkexec, Timeshift, ...),
// dropping out of the bar like the other panels.
HangingPanel {
	id: root

	required property PolkitAgent agent
	readonly property AuthFlow flow: agent.flow

	function cancel(): void {
		flow?.cancelAuthenticationRequest();
	}

	name: "authentication"
	open: Panel.authOpen
	panelWidth: Panel.sizes.auth.width
	panelHeight: Panel.sizes.auth.height
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

			UiText {
				anchors.verticalCenter: parent.verticalCenter
				text: "Authentication required"
				font.family: Theme.fontHeading
				font.pixelSize: Theme.px(17)
				font.weight: Font.DemiBold
			}
		}

		UiText {
			width: parent.width
			text: root.flow?.message ?? ""
			wrapMode: Text.Wrap
			maximumLineCount: 3
			elide: Text.ElideRight
			color: Theme.fgMuted
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

			UiText {
				anchors.verticalCenter: parent.verticalCenter
				width: parent.width - cancelChip.width - 12
				text: root.flow?.supplementaryMessage ?? ""
				elide: Text.ElideRight
				color: root.flow?.supplementaryIsError ? Theme.error : Theme.fgMuted
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
