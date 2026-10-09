import QtQuick
import Quickshell.Services.UPower
import qs

// The laptop battery: green while charging, red and blinking when low.
Readout {
	id: root

	readonly property UPowerDevice device: UPower.displayDevice
	readonly property bool present: device?.isLaptopBattery ?? false
	readonly property real percent: (device?.percentage ?? 0) <= 1 ? (device?.percentage ?? 0) * 100 : device.percentage
	readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
	readonly property bool low: !charging && percent <= 20

	visible: present
	glyph: charging ? "󰂄" : ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"][Math.min(10, Math.floor(percent / 10))]
	label: charging ? "chr" : "bat"
	value: Math.round(percent) + "%"
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
