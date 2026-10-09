pragma Singleton

import QtQuick
import Quickshell

// The shell's icons: Phosphor (Light, and Fill for active states), loaded from fonts/ beside the
// config, so nothing has to be installed. g(name) gives a glyph by its Phosphor name; Glyph draws it.
// Names: https://phosphoricons.com. Adding one: its codepoint from Phosphor's style.css, below.
Singleton {
	id: root

	readonly property string light: lightFont.name
	readonly property string fill: fillFont.name
	readonly property var codes: ({
			"app-window": 0xe5da,
			"arrow-clockwise": 0xe036,
			"arrow-fat-line-up": 0xe522,
			"arrows-clockwise": 0xe094,
			"battery-charging": 0xe0ba,
			"battery-empty": 0xe0be,
			"battery-full": 0xe0c0,
			"battery-high": 0xe0c2,
			"battery-low": 0xe0c4,
			"battery-medium": 0xe0c6,
			"bell": 0xe0ce,
			"bell-ringing": 0xe5e8,
			"bell-slash": 0xe0d4,
			"bluetooth": 0xe0da,
			"bluetooth-slash": 0xe0de,
			"calendar-blank": 0xe10a,
			"caret-left": 0xe138,
			"caret-right": 0xe13a,
			"check": 0xe182,
			"check-square": 0xe186,
			"clipboard-text": 0xe198,
			"code": 0xe1bc,
			"cpu": 0xe610,
			"dots-six-vertical": 0xeae2,
			"faders": 0xe228,
			"gear-six": 0xe272,
			"hash": 0xe2a2,
			"house": 0xe2c2,
			"list-checks": 0xeadc,
			"lock": 0xe2fa,
			"magnifying-glass": 0xe30c,
			"memory": 0xe9c4,
			"microphone": 0xe326,
			"microphone-slash": 0xe328,
			"moon": 0xe330,
			"music-notes": 0xe340,
			"note": 0xe348,
			"note-pencil": 0xe34c,
			"notebook": 0xe34e,
			"palette": 0xe6c8,
			"pause": 0xe39e,
			"play": 0xe3d0,
			"plus": 0xe3d4,
			"power": 0xe3da,
			"pulse": 0xe000,
			"push-pin": 0xe3e2,
			"sign-out": 0xe42a,
			"skip-back": 0xe5a4,
			"skip-forward": 0xe5a6,
			"sliders-horizontal": 0xe434,
			"speaker-high": 0xe44a,
			"speaker-low": 0xe44c,
			"speaker-none": 0xe44e,
			"speaker-slash": 0xe45a,
			"squares-four": 0xe464,
			"stack": 0xe466,
			"sun": 0xe472,
			"thermometer-simple": 0xe5cc,
			"trash": 0xe4a6,
			"video-camera": 0xe4da,
			"wifi-high": 0xe4ea,
			"wifi-slash": 0xe4f2,
			"x": 0xe4f6
		})

	function g(name: string): string {
		return codes[name] ? String.fromCodePoint(codes[name]) : "";
	}

	FontLoader {
		id: lightFont

		source: Qt.resolvedUrl("fonts/Phosphor-Light.ttf")
	}

	FontLoader {
		id: fillFont

		source: Qt.resolvedUrl("fonts/Phosphor-Fill.ttf")
	}
}
