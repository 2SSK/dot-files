pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.UPower
import qs

// Battery warnings: an urgent notification when the charge falls to power.batteryLow (25% by
// default) while not charging, and again at 10%. Each fires once on the way down; plugging in, or
// charging back above, re-arms it.
Singleton {
	id: root

	readonly property UPowerDevice device: UPower.displayDevice
	readonly property bool present: device?.isLaptopBattery ?? false
	readonly property real percent: (device?.percentage ?? 0) <= 1 ? (device?.percentage ?? 0) * 100 : device.percentage
	readonly property bool charging: device?.state === UPowerDeviceState.Charging || device?.state === UPowerDeviceState.FullyCharged
	readonly property int threshold: Config.power.batteryLow
	property bool warned: false
	property bool warnedCritical: false

	function check(): void {
		if (!present)
			return;
		if (charging || percent > threshold + 1) {
			warned = false;
			warnedCritical = false;
			return;
		}
		if (percent <= 10 && !warnedCritical) {
			warnedCritical = warned = true;
			notify("Battery critically low", `${Math.round(percent)}% left: plug in now.`);
		} else if (percent <= threshold && !warned) {
			warned = true;
			notify("Battery low", `${Math.round(percent)}% left: plug in soon.`);
		}
	}

	function notify(title: string, body: string): void {
		Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", "critical", "-i", "battery-caution", title, body]);
	}

	onPercentChanged: check()
	onChargingChanged: check()
	onThresholdChanged: check()
	Component.onCompleted: check()
}
