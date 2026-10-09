pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.widgets

// The bar's three parts as columns of widgets: arrows reorder a widget or move it to the next part,
// ✕ takes it off the bar, and the widgets not on it wait below to be added.
Column {
	id: root

	readonly property var parts: [
		{ key: "left", title: "Left" },
		{ key: "center", title: "Centre" },
		{ key: "right", title: "Right" }
	]
	readonly property var names: ({
			workspaces: "Workspaces",
			scratchpad: "Scratchpad",
			stats: "System monitor",
			clock: "Clock",
			tray: "Tray",
			brightness: "Brightness",
			volume: "Volume",
			recorder: "Screen recorder",
			battery: "Battery",
			notifications: "Notifications",
			controls: "Control center",
			wifi: "Wi-Fi",
			bluetooth: "Bluetooth",
			notes: "Notes",
			todo: "Todo",
			power: "Power menu",
			launcher: "Launcher"
		})
	readonly property var unused: Object.keys(names).filter(name => ![...Config.bar.left, ...Config.bar.center, ...Config.bar.right].includes(name))

	function list(part: string): var {
		return [...Config.bar[part]];
	}

	function set(part: string, widgets: var): void {
		Config.bar[part] = widgets;
		Config.save();
	}

	// within a part (step -1/+1) or into the neighbouring part (jump -1/+1)
	function shift(part: string, index: int, step: int): void {
		const widgets = list(part);
		const to = index + step;
		if (to < 0 || to >= widgets.length)
			return;
		[widgets[index], widgets[to]] = [widgets[to], widgets[index]];
		set(part, widgets);
	}

	function jump(part: string, index: int, direction: int): void {
		const keys = parts.map(p => p.key);
		const target = keys[keys.indexOf(part) + direction];
		if (!target)
			return;
		const from = list(part);
		const [name] = from.splice(index, 1);
		const to = list(target);
		direction > 0 ? to.unshift(name) : to.push(name);
		set(part, from);
		set(target, to);
	}

	function remove(part: string, index: int): void {
		const widgets = list(part);
		widgets.splice(index, 1);
		set(part, widgets);
	}

	width: parent?.width ?? 0
	spacing: 14

	Row {
		width: parent.width
		spacing: 10

		Repeater {
			model: root.parts

			delegate: Rectangle {
				id: column

				required property var modelData
				readonly property var widgets: Config.bar[modelData.key]

				width: (root.width - 20) / 3
				height: Math.max(160, chips.implicitHeight + 50)
				radius: 12
				color: Qt.alpha(Theme.surface, 0.55)

				Text {
					x: 14
					y: 12
					text: column.modelData.title
					color: Theme.fgMuted
					font.family: Theme.fontSans
					font.pixelSize: 12
					font.weight: Font.DemiBold
				}

				Column {
					id: chips

					x: 8
					y: 38
					width: parent.width - 16
					spacing: 6

					Repeater {
						model: column.widgets

						delegate: Rectangle {
							id: chip

							required property string modelData
							required property int index

							width: chips.width
							height: 34
							radius: 9
							color: hover.hovered ? Qt.alpha(Theme.overlay, 0.95) : Qt.alpha(Theme.overlay, 0.6)

							HoverHandler {
								id: hover
							}

							Text {
								anchors.left: parent.left
								anchors.leftMargin: 10
								anchors.right: tools.left
								anchors.verticalCenter: parent.verticalCenter
								text: root.names[chip.modelData] ?? chip.modelData
								elide: Text.ElideRight
								color: Theme.fg
								font.family: Theme.fontSans
								font.pixelSize: 13
							}

							Row {
								id: tools

								anchors.right: parent.right
								anchors.rightMargin: 4
								anchors.verticalCenter: parent.verticalCenter
								opacity: hover.hovered ? 1 : 0.35

								Repeater {
									model: [
										{ glyph: "\u{EAB5}", act: () => root.jump(column.modelData.key, chip.index, -1), show: column.modelData.key !== "left" },
										{ glyph: "\u{EAB7}", act: () => root.shift(column.modelData.key, chip.index, -1), show: chip.index > 0 },
										{ glyph: "\u{EAB4}", act: () => root.shift(column.modelData.key, chip.index, 1), show: chip.index < column.widgets.length - 1 },
										{ glyph: "\u{EAB6}", act: () => root.jump(column.modelData.key, chip.index, 1), show: column.modelData.key !== "right" },
										{ glyph: "\u{EA76}", act: () => root.remove(column.modelData.key, chip.index), show: true }
									]

									delegate: Glyph {
										id: tool

										required property var modelData

										width: 22
										height: 26
										visible: modelData.show
										text: modelData.glyph
										font.pixelSize: 13
										font.weight: Font.Normal
										color: toolHover.hovered ? Theme.primary : Theme.fg

										HoverHandler {
											id: toolHover
										}

										MouseArea {
											anchors.fill: parent
											cursorShape: Qt.PointingHandCursor
											onClicked: tool.modelData.act()
										}
									}
								}
							}
						}
					}
				}
			}
		}
	}

	Text {
		visible: root.unused.length > 0
		text: "Not on the bar: click to add at the right"
		color: Theme.fgMuted
		font.family: Theme.fontSans
		font.pixelSize: 12
	}

	Flow {
		width: parent.width
		spacing: 6

		Repeater {
			model: root.unused

			delegate: Rectangle {
				id: spare

				required property string modelData

				width: label.implicitWidth + 30
				height: 30
				radius: 15
				color: spareHover.hovered ? Theme.primary : Qt.alpha(Theme.overlay, 0.7)

				Text {
					id: label

					anchors.centerIn: parent
					text: "+  " + (root.names[spare.modelData] ?? spare.modelData)
					color: spareHover.hovered ? Theme.onPrimary : Theme.fg
					font.family: Theme.fontSans
					font.pixelSize: 12
					font.weight: Font.Medium
				}

				HoverHandler {
					id: spareHover
				}

				MouseArea {
					anchors.fill: parent
					cursorShape: Qt.PointingHandCursor
					onClicked: root.set("right", [...root.list("right"), spare.modelData])
				}
			}
		}
	}
}
