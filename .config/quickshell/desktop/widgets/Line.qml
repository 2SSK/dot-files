import QtQuick

// Lays its children out along the bar: a row on a horizontal bar, a column on a vertical one.
Grid {
	property bool vertical: false

	rows: vertical ? 64 : 1
	columns: vertical ? 1 : 64
	horizontalItemAlignment: Grid.AlignHCenter
	verticalItemAlignment: Grid.AlignVCenter
}
