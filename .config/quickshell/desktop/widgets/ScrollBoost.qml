import QtQuick

// Faster, smooth wheel and touchpad scrolling for the Flickable (ListView, GridView) it sits in:
// X sends few, coarse steps (desktop-input slows them for apps), so the shell's own lists go
// further per step, easing to each stop instead of jumping.
WheelHandler {
	id: root

	property real step: 110 // px per wheel step
	readonly property Flickable view: parent

	acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
	target: null
	onWheel: event => {
		const dy = event.pixelDelta.y !== 0 ? event.pixelDelta.y * 2 : event.angleDelta.y / 120 * step;
		const top = view.originY;
		const bottom = view.originY + Math.max(0, view.contentHeight - view.height);
		const from = glide.running ? glide.to : view.contentY;
		glide.to = Math.max(top, Math.min(bottom, from - dy));
		glide.restart();
		event.accepted = true;
	}

	property NumberAnimation glide: NumberAnimation {
		target: root.view
		property: "contentY"
		duration: 140
		easing.type: Easing.OutCubic
	}
}
