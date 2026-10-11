import QtQuick

// A hover that counts only once the pointer really moves over its item: a list that opens under a
// still pointer keeps its keyboard pick, rather than jumping to whatever row lies under it. moved()
// is the cue to select the item.
HoverHandler {
	property point from
	signal moved

	onHoveredChanged: from = point.position
	onPointChanged: if (hovered && Math.abs(point.position.x - from.x) + Math.abs(point.position.y - from.y) > 3) moved()
}
