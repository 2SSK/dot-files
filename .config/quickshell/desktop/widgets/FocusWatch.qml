import QtQuick
import Quickshell
import qs.services

// i3's and sway's window events for one of our windows, by title: arrived() once the window manager
// has it, focusLost() when another window takes the focus after its own mapping (which fires one too).
Scope {
	id: root

	required property string title
	property bool active: true
	signal arrived
	signal focusLost

	ElapsedTimer {
		id: opened
	}

	Connections {
		target: WindowManager
		enabled: root.active

		function onWindowEvent(data: var): void {
			const name = data.container?.name ?? "";
			if (data.change === "new" && name === root.title)
				root.arrived();
			else if (data.change === "focus" && name && name !== root.title && opened.elapsed() > 600)
				root.focusLost();
		}
	}
}
