import QtQuick
import Quickshell.Services.Mpris
import qs
import qs.services
import qs.widgets

// The current player: cover, title, artist, progress, and previous / play-pause / next; with more
// than one player, their names on top to switch between them.
Rectangle {
	id: root

	readonly property MprisPlayer player: Media.player

	function time(seconds: real): string {
		const s = Math.max(0, Math.floor(seconds));
		return `${Math.floor(s / 60)}:${String(s % 60).padStart(2, "0")}`;
	}

	height: 116 + (switcher.visible ? 40 : 0)
	radius: 16
	color: Qt.alpha(Theme.surface, 0.8)

	Text {
		visible: !root.player
		anchors.centerIn: parent
		text: "Nothing playing"
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 13
	}

	// the players, when there are several
	Row {
		id: switcher

		visible: Media.players.length > 1
		x: 14
		y: 12
		spacing: 6

		Repeater {
			model: Media.players

			delegate: Rectangle {
				id: chip

				required property var modelData
				readonly property bool on: Media.player === modelData

				width: chipLabel.implicitWidth + (modelData.isPlaying ? 38 : 22)
				height: 26
				radius: 13
				color: on ? Theme.primary : chipHover.hovered ? Qt.alpha(Theme.fg, 0.1) : Qt.alpha(Theme.overlay, 0.8)

				Row {
					anchors.centerIn: parent
					spacing: 5

					Glyph {
						anchors.verticalCenter: parent.verticalCenter
						visible: chip.modelData.isPlaying
						glyph: Icons.g("music")
						font.pixelSize: 11
						color: chip.on ? Theme.onPrimary : Theme.primary
					}

					Text {
						id: chipLabel

						anchors.verticalCenter: parent.verticalCenter
						text: Media.name(chip.modelData)
						color: chip.on ? Theme.onPrimary : Theme.fg
						font.family: Theme.fontSans
						font.pixelSize: 12
						font.weight: Font.Medium
					}
				}

				HoverHandler {
					id: chipHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: Media.chosen = chip.modelData.dbusName
				}
			}
		}
	}

	Rectangle {
		id: cover

		visible: root.player !== null
		x: 14
		y: (switcher.visible ? 40 : 0) + (116 - height) / 2
		width: 88
		height: 88
		radius: 12
		color: Qt.alpha(Theme.primary, 0.14)
		clip: true

		Glyph {
			anchors.centerIn: parent
			visible: art.status !== Image.Ready
			glyph: Icons.g("music")
			font.pixelSize: 30
			color: Theme.primary
		}

		Image {
			id: art

			anchors.fill: parent
			source: root.player?.trackArtUrl ?? ""
			fillMode: Image.PreserveAspectCrop
			asynchronous: true
		}
	}

	Column {
		visible: root.player !== null
		anchors.left: cover.right
		anchors.leftMargin: 14
		anchors.right: parent.right
		anchors.rightMargin: 14
		anchors.verticalCenter: cover.verticalCenter
		spacing: 6

		Text {
			width: parent.width
			text: root.player?.trackTitle || root.player?.identity || ""
			elide: Text.ElideRight
			color: Theme.fg
			font.family: Theme.fontSans
			font.pixelSize: 14
			font.weight: Font.DemiBold
		}

		Text {
			width: parent.width
			text: root.player?.trackArtist ?? ""
			elide: Text.ElideRight
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.pixelSize: 12
		}

		// progress, where the player reports it
		Rectangle {
			visible: root.player?.lengthSupported ?? false
			width: parent.width
			height: 4
			radius: 2
			color: Qt.alpha(Theme.overlay, 0.9)

			Rectangle {
				width: root.player?.length > 0 ? parent.width * Math.min(1, root.player.position / root.player.length) : 0
				height: parent.height
				radius: 2
				color: Theme.primary
			}
		}

		Item {
			width: parent.width
			height: 30

			Label {
				anchors.left: parent.left
				anchors.verticalCenter: parent.verticalCenter
				visible: root.player?.lengthSupported ?? false
				text: `${root.time(root.player?.position ?? 0)} / ${root.time(root.player?.length ?? 0)}`
				color: Theme.fgMuted
				font.pixelSize: 11
				font.weight: Font.Medium
			}

			Row {
				anchors.right: parent.right
				anchors.verticalCenter: parent.verticalCenter
				spacing: 4

				Repeater {
					model: [
						{ glyph: Icons.g("player-skip-back"), enabled: root.player?.canGoPrevious ?? false, act: () => root.player.previous() },
						{ glyph: root.player?.isPlaying ? Icons.g("player-pause") : Icons.g("player-play"), enabled: root.player?.canTogglePlaying ?? false, act: () => root.player.togglePlaying(), main: true },
						{ glyph: Icons.g("player-skip-forward"), enabled: root.player?.canGoNext ?? false, act: () => root.player.next() }
					]

					delegate: Rectangle {
						id: button

						required property var modelData

						width: modelData.main ? 34 : 30
						height: width
						radius: width / 2
						opacity: modelData.enabled ? 1 : 0.4
						color: modelData.main ? Theme.primary : buttonHover.hovered ? Qt.alpha(Theme.fg, 0.1) : "transparent"

						Glyph {
							anchors.centerIn: parent
							glyph: button.modelData.glyph
							filled: true
							font.pixelSize: 16
							font.weight: Font.Normal
							color: button.modelData.main ? Theme.onPrimary : Theme.fg
						}

						HoverHandler {
							id: buttonHover
						}

						MouseArea {
							anchors.fill: parent
							enabled: button.modelData.enabled
							cursorShape: Qt.PointingHandCursor
							onClicked: button.modelData.act()
						}
					}
				}
			}
		}
	}
}
