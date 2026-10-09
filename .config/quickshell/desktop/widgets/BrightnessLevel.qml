import QtQuick
import qs
import qs.services

// Screen brightness, where there's a backlight; scroll changes it.
Item {
	readonly property bool present: Brightness.available

	visible: present
	implicitWidth: readout.implicitWidth
	implicitHeight: readout.implicitHeight

	Readout {
		id: readout

		glyph: "󰃠"
		label: "brt"
		value: Math.round(Brightness.value * 100) + "%"
	}

	MouseArea {
		anchors.fill: parent
		onWheel: event => Brightness.change(event.angleDelta.y > 0 ? Config.brightness.step : -Config.brightness.step)
	}
}
