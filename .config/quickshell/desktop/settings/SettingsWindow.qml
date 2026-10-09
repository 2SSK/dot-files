pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.I3
import Quickshell.Io
import qs
import qs.services
import qs.widgets

// The settings window: a sidebar of pages, each a column of settings that apply at once and are
// written to ~/.config/desktop/shell.json (in the repo). A real window, so i3 floats it (see
// look.conf) and the keyboard works. Escape or focusing another window closes it.
FloatingWindow {
	id: root

	property string page: "bar"
	property string family: ""
	property string mode: ""
	property var families: []

	readonly property var pages: [
		{ key: "bar", glyph: "\u{F10A9}", title: "Bar", flip: Config.position === "top" }, // md-dock-bottom, upside down for a top bar
		{ key: "appearance", glyph: "\u{EB5C}", title: "Appearance" },
		{ key: "notifications", glyph: "\u{EAA2}", title: "Notifications" },
		{ key: "levels", glyph: "\u{EACD}", title: "Levels" },
		{ key: "power", glyph: "\u{F0425}", title: "Power" }
	]

	function set(group: string, key: string, value: var): void {
		Config[group][key] = value;
		Config.save();
	}

	// another window taking the focus closes it
	I3IpcListener {
		subscriptions: ["window"]
		onIpcEvent: event => {
			const data = typeof event.data === "string" ? JSON.parse(event.data) : event.data;
			const name = data.container?.name ?? "";
			// a named window other than this one, once it has settled (its own mapping fires focus too)
			if (data.change === "focus" && name && name !== root.title && opened.elapsed() > 600)
				Panel.settingsOpen = false;
		}
	}

	ElapsedTimer {
		id: opened
	}

	title: "Desktop settings"
	implicitWidth: 920
	implicitHeight: 640
	minimumSize: Qt.size(760, 480)
	color: Theme.bg
	onVisibleChanged: if (!visible) Panel.settingsOpen = false

	// the themes, and which one is on
	Process {
		id: themes

		running: true
		command: ["theme", "list"]
		stdout: StdioCollector {
			onStreamFinished: root.families = text.split("\n").filter(line => line.trim()).map(line => line.replace("*", "").trim())
		}
	}

	Process {
		id: current

		running: true
		command: ["theme", "current"]
		stdout: StdioCollector {
			onStreamFinished: {
				const [family, mode] = text.trim().split(" ");
				root.family = family;
				root.mode = mode;
			}
		}
	}

	Process {
		id: apply

		onExited: current.running = true
	}

	function theme(args: var): void {
		apply.command = ["theme", ...args];
		apply.running = true;
	}

	Item {
		anchors.fill: parent
		focus: true
		Keys.onEscapePressed: Panel.settingsOpen = false
	}

	// sidebar
	Rectangle {
		id: sidebar

		width: 210
		height: parent.height
		color: Qt.alpha(Theme.surface, 0.5)

		Text {
			x: 22
			y: 22
			text: "Settings"
			color: Theme.fg
			font.family: Theme.fontSans
			font.pixelSize: 20
			font.weight: Font.DemiBold
		}

		Column {
			x: 12
			y: 70
			width: parent.width - 24
			spacing: 4

			Repeater {
				model: root.pages

				delegate: Rectangle {
					id: entry

					required property var modelData
					readonly property bool on: root.page === modelData.key

					width: parent.width
					height: 40
					radius: 10
					color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.fg, 0.07) : "transparent"

					Row {
						anchors.left: parent.left
						anchors.leftMargin: 14
						anchors.verticalCenter: parent.verticalCenter
						spacing: 12

						Glyph {
							width: 20
							rotation: entry.modelData.flip ? 180 : 0
							text: entry.modelData.glyph
							font.pixelSize: 16
							font.weight: Font.Normal
							color: entry.on ? Theme.onPrimary : Theme.fg
						}

						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: entry.modelData.title
							color: entry.on ? Theme.onPrimary : Theme.fg
							font.family: Theme.fontSans
							font.pixelSize: 14
							font.weight: Font.Medium
						}
					}

					HoverHandler {
						id: hover
					}

					MouseArea {
						anchors.fill: parent
						cursorShape: Qt.PointingHandCursor
						onClicked: root.page = entry.modelData.key
					}
				}
			}
		}

		Text {
			x: 22
			anchors.bottom: parent.bottom
			anchors.bottomMargin: 18
			width: parent.width - 44
			wrapMode: Text.Wrap
			text: "Saved to ~/.config/desktop/shell.json"
			color: Theme.fgMuted
			font.family: Theme.fontSans
			font.pixelSize: 11
		}
	}

	Flickable {
		id: content

		anchors.left: sidebar.right
		anchors.right: parent.right
		anchors.top: parent.top
		anchors.bottom: parent.bottom
		contentHeight: pageColumn.implicitHeight + 60
		clip: true
		boundsBehavior: Flickable.StopAtBounds

		Column {
			id: pageColumn

			x: 32
			y: 28
			width: content.width - 64
			spacing: 22

			Text {
				text: root.pages.find(p => p.key === root.page)?.title ?? ""
				color: Theme.fg
				font.family: Theme.fontSans
				font.pixelSize: 22
				font.weight: Font.DemiBold
			}

			// Bar
			Section {
				visible: root.page === "bar"
				title: "Look"

				SettingRow {
					label: "Style"
					hint: "Island floats as a pill; static fills the whole edge."
					Choice {
						options: [{ value: "island", label: "Island" }, { value: "static", label: "Static" }]
						value: Config.bar.style
						onPicked: value => root.set("bar", "style", value)
					}
				}

				SettingRow {
					label: "Capsules"
					hint: "Each widget in a soft capsule."
					Toggle {
						checked: Config.bar.capsules
						onToggled: checked => root.set("bar", "capsules", checked)
					}
				}

				SettingRow {
					label: "Position"
					hint: Config.wayland ? "" : "i3 docks bars only at the top or bottom."
					Choice {
						options: (Config.wayland ? ["top", "bottom", "left", "right"] : ["top", "bottom"]).map(p => ({ value: p, label: p[0].toUpperCase() + p.slice(1) }))
						value: Config.bar.position
						onPicked: value => root.set("bar", "position", value)
					}
				}

				SettingRow {
					label: "Height"
					Range {
						from: 26
						to: 48
						step: 1
						value: Config.bar.size
						format: v => Math.round(v) + " px"
						onMoved: value => root.set("bar", "size", Math.round(value))
					}
				}

				SettingRow {
					label: "Opacity"
					Range {
						from: 0.4
						to: 1
						step: 0.05
						value: Config.bar.opacity
						format: v => Math.round(v * 100) + " %"
						onMoved: value => root.set("bar", "opacity", value)
					}
				}

				SettingRow {
					visible: Config.island
					label: "Island width"
					hint: Config.bar.length > 0 ? "A fixed share of the screen edge." : "Follows the screen: more of a narrow one, less of a wide one."
					Row {
						spacing: 14

						Toggle {
							anchors.verticalCenter: parent.verticalCenter
							checked: Config.bar.length === 0
							onToggled: checked => root.set("bar", "length", checked ? 0 : 0.55)
						}

						Text {
							anchors.verticalCenter: parent.verticalCenter
							text: "Auto"
							color: Theme.fg
							font.family: Theme.fontSans
							font.pixelSize: 13
						}

						Range {
							visible: Config.bar.length > 0
							from: 0.3
							to: 0.95
							step: 0.05
							value: Config.bar.length
							format: v => Math.round(v * 100) + " %"
							onMoved: value => root.set("bar", "length", value)
						}
					}
				}
			}

			Section {
				visible: root.page === "bar"
				title: "Widgets"

				WidgetLayout {}
			}

			// Appearance
			Section {
				visible: root.page === "appearance"
				title: "Theme"

				SettingRow {
					label: "Mode"
					Choice {
						options: [{ value: "dark", label: "Dark" }, { value: "light", label: "Light" }]
						value: root.mode
						onPicked: value => root.theme(["mode", value])
					}
				}

				Flow {
					width: parent.width
					spacing: 8
					topPadding: 6

					Repeater {
						model: root.families

						delegate: Rectangle {
							id: swatch

							required property string modelData
							readonly property bool on: root.family === modelData

							width: 150
							height: 52
							radius: 12
							color: on ? Theme.primary : hover.hovered ? Qt.alpha(Theme.overlay, 0.95) : Qt.alpha(Theme.surface, 0.55)
							border.width: on ? 0 : 1
							border.color: Qt.alpha(Theme.border, 0.6)

							Text {
								anchors.centerIn: parent
								text: swatch.modelData
								color: swatch.on ? Theme.onPrimary : Theme.fg
								font.family: Theme.fontSans
								font.pixelSize: 14
								font.weight: Font.Medium
							}

							HoverHandler {
								id: hover
							}

							MouseArea {
								anchors.fill: parent
								cursorShape: Qt.PointingHandCursor
								onClicked: root.theme(["set", swatch.modelData])
							}
						}
					}
				}
			}

			// Notifications
			Section {
				visible: root.page === "notifications"
				title: "Popups"

				SettingRow {
					label: "Do Not Disturb"
					hint: "Only critical notifications pop up; all of them reach the history."
					Toggle {
						checked: Notifications.dnd
						onToggled: checked => Notifications.dnd = checked
					}
				}

				SettingRow {
					label: "Time on screen"
					hint: "How long a popup stays, unless the app asks for its own time."
					Range {
						from: 2000
						to: 15000
						step: 500
						value: Config.notifications.timeout
						format: v => (v / 1000).toFixed(1) + " s"
						onMoved: value => root.set("notifications", "timeout", Math.round(value))
					}
				}
			}

			// Levels
			Section {
				visible: root.page === "levels"
				title: "Volume and brightness"

				SettingRow {
					label: "Volume step"
					hint: "Per key press or scroll."
					Range {
						from: 1
						to: 20
						step: 1
						value: Config.audio.step
						format: v => Math.round(v) + " %"
						onMoved: value => root.set("audio", "step", Math.round(value))
					}
				}

				SettingRow {
					label: "Brightness step"
					Range {
						from: 1
						to: 20
						step: 1
						value: Config.brightness.step
						format: v => Math.round(v) + " %"
						onMoved: value => root.set("brightness", "step", Math.round(value))
					}
				}

				SettingRow {
					label: "Level card on screen"
					hint: "How long the card at the top right stays after a change."
					Range {
						from: 800
						to: 5000
						step: 100
						value: Config.osd.timeout
						format: v => (v / 1000).toFixed(1) + " s"
						onMoved: value => root.set("osd", "timeout", Math.round(value))
					}
				}
			}

			// Power
			Section {
				visible: root.page === "power"
				title: "Power menu"

				SettingRow {
					label: "Confirm"
					hint: "Log Out, Reboot and Shut Down need a second press."
					Toggle {
						checked: Config.power.confirm
						onToggled: checked => root.set("power", "confirm", checked)
					}
				}
			}
		}
	}
}
