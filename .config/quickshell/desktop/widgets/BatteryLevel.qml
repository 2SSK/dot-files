import QtQuick
import Quickshell.Services.UPower
import qs

// The laptop battery as a horizontal cell, by charge; a bolt on the charger (charging, full, or held
// at the charge limit); red at or below power.batteryLow (Battery warns then), blinking from 10%.
Readout {
	id: root

	readonly property UPowerDevice device: UPower.displayDevice
	readonly property bool present: device?.isLaptopBattery ?? false
	readonly property real percent: (device?.percentage ?? 0) <= 1 ? (device?.percentage ?? 0) * 100 : device.percentage
	readonly property bool charging: [UPowerDeviceState.Charging, UPowerDeviceState.FullyCharged, UPowerDeviceState.PendingCharge].includes(device?.state)
	readonly property bool low: !charging && percent <= Config.power.batteryLow

	visible: present
	// fa-battery: empty, quarter, half, three quarters, full; fa-bolt while charging
	glyph: Icons.g(charging ? "battery-charging" : ["battery", "battery-1", "battery-2", "battery-3", "battery-4"][Math.round(percent / 25)])
	label: charging ? "chr" : "bat"
	value: Math.round(percent) + "%"
	widest: "100%"
	tint: low ? Theme.error : charging ? Theme.success : Theme.fg

	// a blink once a second: one redraw each, not an animation's 60 a second
	Timer {
		interval: 1000
		repeat: true
		running: root.low && root.percent <= 10
		onTriggered: root.opacity = root.opacity < 1 ? 1 : 0.35
		onRunningChanged: if (!running) root.opacity = 1
	}
}
