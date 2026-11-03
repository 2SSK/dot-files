import QtQuick
import qs
import qs.services

// The laptop battery as a horizontal cell, by charge; a bolt on the charger (charging, full, or held
// at the charge limit); red at or below power.batteryLow (Battery warns then); steady, never blinking.
Readout {
	id: root

	// what the battery service reads (UPower's display device), so the two never disagree
	readonly property bool present: Battery.present
	readonly property real percent: Battery.percent
	readonly property bool charging: Battery.charging
	readonly property bool low: !charging && percent <= Config.power.batteryLow

	visible: present
	// fa-battery: empty, quarter, half, three quarters, full; fa-bolt while charging
	glyph: Icons.g(charging ? "battery-charging" : ["battery", "battery-1", "battery-2", "battery-3", "battery-4"][Math.round(percent / 25)])
	value: Math.round(percent) + "%"
	widest: "100%"
	tint: low ? Theme.error : charging ? Theme.success : Theme.fg
}
