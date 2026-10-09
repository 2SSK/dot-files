pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.widgets

// The bar's three parts as columns of widgets. Drag a widget to reorder it or move it to another
// part; drag it out of the columns (or click ✕) to take it off the bar; drag one of the spare
// widgets below into a column to add it.
Item {
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
			tools: "Clipboard, todo, notes",
			clipboard: "Clipboard",
			notes: "Notes",
			todo: "Todo",
			power: "Power menu",
			launcher: "Launcher"
		})
	readonly property var unused: Object.keys(names).filter(name => ![...Config.bar.left, ...Config.bar.center, ...Config.bar.right].includes(name))
	readonly property int chipHeight: 34
	readonly property int chipGap: 6

	// the widget being dragged: its name, the part it came from ("" for a spare one) and its place
	property string dragName: ""
	property string dragFrom: ""
	property int dragIndex: -1
	property point dragAt
	// where it would land
	property string dropPart: ""
	property int dropIndex: -1

	function set(part: string, widgets: var): void {
		Config.bar[part] = widgets;
		Config.save();
	}

	function remove(part: string, index: int): void {
		const widgets = [...Config.bar[part]];
		widgets.splice(index, 1);
		set(part, widgets);
	}

	// the part and the place in it under a point (in this item's coordinates)
	function target(point: point): var {
		for (let i = 0; i < columns.count; i++) {
			const column = columns.itemAt(i);
			const p = column.mapFromItem(root, point.x, point.y);
			if (p.x >= 0 && p.x <= column.width && p.y >= 0 && p.y <= column.height) {
				const count = Config.bar[parts[i].key].length;
				return { part: parts[i].key, index: Math.max(0, Math.min(count, Math.round((p.y - 38) / (chipHeight + chipGap)))) };
			}
		}
		return { part: "", index: -1 };
	}

	function startDrag(name: string, from: string, index: int, point: point): void {
		dragName = name;
		dragFrom = from;
		dragIndex = index;
		moveDrag(point);
	}

	function moveDrag(point: point): void {
		dragAt = point;
		const t = target(point);
		dropPart = t.part;
		dropIndex = t.index;
	}

	function endDrag(): void {
		if (dragName) {
			const from = dragFrom ? [...Config.bar[dragFrom]] : null;
			if (from)
				from.splice(dragIndex, 1);
			if (dropPart) {
				const to = dropPart === dragFrom ? from : [...Config.bar[dropPart]];
				// a move further down its own part shifts by the one taken out
				const index = dropPart === dragFrom && dropIndex > dragIndex ? dropIndex - 1 : dropIndex;
				to.splice(index, 0, dragName);
				if (from && dropPart !== dragFrom)
					set(dragFrom, from);
				set(dropPart, to);
			} else if (from) {
				set(dragFrom, from); // dropped outside: off the bar
			}
		}
		dragName = "";
		dragFrom = "";
		dropPart = "";
	}

	width: parent?.width ?? 0
	implicitHeight: content.implicitHeight

	Column {
		id: content

		width: parent.width
		spacing: 14

		Row {
			width: parent.width
			spacing: 10

			Repeater {
				id: columns

				model: root.parts

				delegate: Rectangle {
					id: column

					required property var modelData
					readonly property var widgets: Config.bar[modelData.key]
					readonly property bool hot: root.dragName !== "" && root.dropPart === modelData.key

					width: (root.width - 20) / 3
					height: Math.max(200, 50 + (widgets.length + 1) * (root.chipHeight + root.chipGap))
					radius: 12
					color: Qt.alpha(Theme.surface, 0.55)
					border.width: hot ? 1 : 0
					border.color: Theme.primary

					Text {
						x: 14
						y: 12
						text: column.modelData.title
						color: Theme.fgMuted
						font.family: Theme.fontSans
						font.pixelSize: 12
						font.weight: Font.DemiBold
					}

					// where the dragged widget would go
					Rectangle {
						visible: column.hot
						x: 8
						y: 38 + root.dropIndex * (root.chipHeight + root.chipGap) - root.chipGap / 2 - 1
						width: parent.width - 16
						height: 2
						radius: 1
						color: Theme.primary
					}

					Repeater {
						model: column.widgets

						delegate: Rectangle {
							id: chip

							required property string modelData
							required property int index
							readonly property bool dragged: root.dragName === modelData && root.dragFrom === column.modelData.key

							x: 8
							y: 38 + index * (root.chipHeight + root.chipGap)
							width: column.width - 16
							height: root.chipHeight
							radius: 9
							opacity: dragged ? 0.35 : 1
							color: grip.containsMouse ? Qt.alpha(Theme.overlay, 0.95) : Qt.alpha(Theme.overlay, 0.6)

							Glyph {
								id: handle

								x: 8
								anchors.verticalCenter: parent.verticalCenter
								glyph: Icons.g("grip-vertical")
								font.pixelSize: 14
								font.weight: Font.Normal
								color: Theme.fgMuted
							}

							Text {
								anchors.left: handle.right
								anchors.leftMargin: 6
								anchors.right: close.left
								anchors.verticalCenter: parent.verticalCenter
								text: root.names[chip.modelData] ?? chip.modelData
								elide: Text.ElideRight
								color: Theme.fg
								font.family: Theme.fontSans
								font.pixelSize: 13
							}

							MouseArea {
								id: grip

								anchors.fill: parent
								hoverEnabled: true
								preventStealing: true // not a scroll of the page
								cursorShape: root.dragName ? Qt.ClosedHandCursor : Qt.OpenHandCursor
								onPressed: event => root.startDrag(chip.modelData, column.modelData.key, chip.index, mapToItem(root, event.x, event.y))
								onPositionChanged: event => { if (pressed) root.moveDrag(mapToItem(root, event.x, event.y)); }
								onReleased: root.endDrag()
							}

							Glyph {
								id: close

								anchors.right: parent.right
								anchors.rightMargin: 10
								anchors.verticalCenter: parent.verticalCenter
								opacity: grip.containsMouse ? 1 : 0.3
								glyph: Icons.g("x")
								font.pixelSize: 13
								font.weight: Font.Normal
								color: closeArea.containsMouse ? Theme.error : Theme.fg

								MouseArea {
									id: closeArea

									anchors.fill: parent
									anchors.margins: -6
									hoverEnabled: true
									cursorShape: Qt.PointingHandCursor
									onClicked: root.remove(column.modelData.key, chip.index)
								}
							}
						}
					}
				}
			}
		}

		Text {
			visible: root.unused.length > 0
			text: "Not on the bar: drag one into a column"
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

					width: label.implicitWidth + 28
					height: 30
					radius: 15
					opacity: root.dragName === modelData && !root.dragFrom ? 0.35 : 1
					color: spareArea.containsMouse ? Qt.alpha(Theme.overlay, 0.95) : Qt.alpha(Theme.overlay, 0.6)

					Text {
						id: label

						anchors.centerIn: parent
						text: root.names[spare.modelData] ?? spare.modelData
						color: Theme.fg
						font.family: Theme.fontSans
						font.pixelSize: 12
						font.weight: Font.Medium
					}

					MouseArea {
						id: spareArea

						anchors.fill: parent
						hoverEnabled: true
						preventStealing: true
						cursorShape: Qt.OpenHandCursor
						onPressed: event => root.startDrag(spare.modelData, "", -1, mapToItem(root, event.x, event.y))
						onPositionChanged: event => { if (pressed) root.moveDrag(mapToItem(root, event.x, event.y)); }
						onReleased: root.endDrag()
					}
				}
			}
		}
	}

	// the dragged widget, under the pointer
	Rectangle {
		visible: root.dragName !== ""
		z: 10
		x: root.dragAt.x - width / 2
		y: root.dragAt.y - height / 2
		width: ghostLabel.implicitWidth + 30
		height: root.chipHeight
		radius: 9
		color: Theme.primary

		Text {
			id: ghostLabel

			anchors.centerIn: parent
			text: root.names[root.dragName] ?? root.dragName
			color: Theme.onPrimary
			font.family: Theme.fontSans
			font.pixelSize: 13
			font.weight: Font.Medium
		}
	}
}
