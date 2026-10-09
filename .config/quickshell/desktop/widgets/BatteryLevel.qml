import QtQuick
import Quickshell.Services.UPower
import qs

// The laptop battery as a horizontal cell, by charge; a bolt while charging; red at or below
// power.batteryLow (Battery warns then), blinking from 10%.
Readout {
	id: root

	readonly property UPowerDevice device: UPower.displayDevice
	readonly property bool present: device?.isLaptopBattery ?? false
	readonly property real percent: (device?.percentage ?? 0) <= 1 ? (device?.percentage ?? 0) * 100 : device.percentage
	readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
	readonly property bool low: !charging && percent <= Config.power.batteryLow

	visible: present
	// fa-battery: empty, quarter, half, three quarters, full; fa-bolt while charging
	glyph: Icons.g(charging ? "battery-charging" : ["battery", "battery-1", "battery-2", "battery-3", "battery-4"][Math.round(percent / 25)])
	label: charging ? "chr" : "bat"
	value: Math.round(percent) + "%"
	widest: "100%"
	tint: low ? Theme.error : charging ? Theme.success : Theme.fg

	SequentialAnimation on opacity {
		running: root.low && root.percent <= 10
		loops: Animation.Infinite
		onStopped: root.opacity = 1

		NumberAnimation {
			to: 0.35
			duration: 500
		}

		NumberAnimation {
			to: 1
			duration: 500
		}
	}
}
