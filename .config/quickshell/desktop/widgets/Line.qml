import QtQuick

// Lays its children out along the bar: a row on a horizontal bar, a column on a vertical one. Its
// size counts only the visible children and the gaps between them (a Grid's own size kept a gap
// after the last one and left room for hidden ones, which pushed capsules' content off centre).
Item {
	id: root

	property bool vertical: false
	property real spacing: 0
	default property alias content: grid.data

	readonly property var shown: grid.visibleChildren.filter(c => c.width > 0 && c.height > 0)

	implicitWidth: vertical ? Math.max(0, ...shown.map(c => c.width)) : shown.reduce((sum, c) => sum + c.width, 0) + Math.max(0, shown.length - 1) * spacing
	implicitHeight: vertical ? shown.reduce((sum, c) => sum + c.height, 0) + Math.max(0, shown.length - 1) * spacing : Math.max(0, ...shown.map(c => c.height))

	Grid {
		id: grid

		rows: root.vertical ? 64 : 1
		columns: root.vertical ? 1 : 64
		spacing: root.spacing
		horizontalItemAlignment: Grid.AlignHCenter
		verticalItemAlignment: Grid.AlignVCenter
	}
}
