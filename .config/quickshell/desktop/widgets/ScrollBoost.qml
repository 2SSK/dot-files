import QtQuick
import qs

// Faster, smooth wheel and touchpad scrolling for the Flickable it sits in: X sends few, coarse steps
// (desktop-input slows them for apps), so the shell's lists go further per step and ease to each stop.
WheelHandler {
	id: root

	property real step: 110 // px per wheel step
	// a Flickable hands what's declared in it to its content item: the view is that item's parent then
	readonly property var view: parent && parent.contentY !== undefined ? parent : parent?.parent

	acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
	target: null
	onWheel: event => {
		const dy = event.pixelDelta.y !== 0 ? event.pixelDelta.y * 2 : event.angleDelta.y / 120 * step;
		const top = view.originY;
		const bottom = view.originY + Math.max(0, view.contentHeight - view.height);
		const from = glide.running ? glide.to : view.contentY;
		// whole pixels: text in a view stopped between two blurs (a touchpad step is fractional)
		const to = Math.round(Math.max(top, Math.min(bottom, from - dy)));
		// already at that end (or nothing to scroll): the view around this one scrolls instead
		if (to === from) {
			event.accepted = false;
			return;
		}
		glide.to = to;
		glide.restart();
		event.accepted = true;
	}

	// a drag or flick ends where it ends: onto a whole pixel too
	property Connections snap: Connections {
		target: root.view

		function onMovementEnded(): void {
			root.view.contentY = Math.round(root.view.contentY);
		}
	}

	property NumberAnimation glide: NumberAnimation {
		target: root.view
		property: "contentY"
		duration: Theme.quick
		easing.type: Theme.curve
	}
}
