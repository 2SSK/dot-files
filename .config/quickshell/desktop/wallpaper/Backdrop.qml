import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.services

// The wallpaper on sway, drawn on the background layer per screen, fading in over the old one.
// i3 has no such layer: feh draws it there.
PanelWindow {
	id: root

	required property ShellScreen modelData
	// the image shown last, or fading in; the other one is under it, then emptied
	property Image front: one

	function other(image: Image): Image {
		return image === one ? two : one;
	}

	// cut a running fade short: what it was fading in is simply shown
	function settle(): void {
		fade.stop();
		front.opacity = 1;
		other(front).source = "";
	}

	function show(path: string): void {
		if (fade.running)
			settle();
		const next = other(front);
		next.opacity = 0;
		next.z = 1;
		front.z = 0;
		front = next;
		next.source = path;
		if (next.status === Image.Ready) // already loaded (the same picture again)
			fade.restart();
	}

	screen: modelData
	anchors {
		top: true
		bottom: true
		left: true
		right: true
	}
	exclusionMode: ExclusionMode.Ignore
	WlrLayershell.layer: WlrLayer.Background
	WlrLayershell.namespace: "desktop-wallpaper"
	color: Theme.bg

	Connections {
		target: Wallpaper

		function onCurrentChanged(): void {
			root.show(Wallpaper.current);
		}
	}

	Component.onCompleted: if (Wallpaper.current) show(Wallpaper.current)

	component Picture: Image {
		anchors.fill: parent
		fillMode: Image.PreserveAspectCrop
		sourceSize: Qt.size(root.width, root.height) // decoded at the screen's size, not the file's
		asynchronous: true
		cache: false
		opacity: 0
		onStatusChanged: if (this === root.front && status === Image.Ready && opacity < 1) fade.restart()
	}

	Picture {
		id: one
	}

	Picture {
		id: two
	}

	NumberAnimation {
		id: fade

		target: root.front
		property: "opacity"
		to: 1
		duration: 800
		easing.type: Easing.InOutQuad
		onFinished: root.settle()
	}
}
