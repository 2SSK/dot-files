pragma Singleton

import QtQuick
import Quickshell

// The shell's icons: Tabler, by the names noctalia uses where it has one, loaded from fonts/ beside the config, so nothing has
// to be installed. g(name) gives a glyph by its Tabler name (https://tabler.io/icons); Glyph draws
// it, filled where Tabler has a filled version and the Glyph asks for one. Adding an icon: its
// codepoint from Tabler's tabler-icons.css, below (and its -filled one, if any, in `filledCodes`).
Singleton {
	id: root

	readonly property string family: font.name
	readonly property var codes: ({
			"activity": 0xed23,
			"adjustments": 0xea03,
			"adjustments-horizontal": 0xec38,
			"alarm": 0xea04,
			"alarm-snooze": 0xf632,
			"app-window": 0xefe6,
			"apps": 0xebb6,
			"arrow-big-up-line": 0xefee,
			"arrows-shuffle": 0xf000,
			"battery": 0xea34,
			"battery-1": 0xea2f,
			"battery-2": 0xea30,
			"battery-3": 0xea31,
			"battery-4": 0xea32,
			"battery-charging": 0xea33,
			"bell": 0xea35,
			"bell-off": 0xece9,
			"bluetooth": 0xea37,
			"bluetooth-off": 0xeceb,
			"brightness-up": 0xeb7e,
			"calendar": 0xea53,
			"calendar-event": 0xea52,
			"camera": 0xea54,
			"check": 0xea5e,
			"checkbox": 0xeba6,
			"checklist": 0xf074,
			"chevron-down": 0xea5f,
			"chevron-left": 0xea60,
			"chevron-right": 0xea61,
			"clipboard": 0xea6f,
			"clock-hour-4": 0xf319,
			"code": 0xea77,
			"copy": 0xea7a,
			"cpu": 0xef8e,
			"crop": 0xea85,
			"device-desktop": 0xea89,
			"eye": 0xea9a,
			"eye-off": 0xecf0,
			"external-link": 0xea99,
			"file": 0xeaa4,
			"file-code": 0xebd0,
			"file-text": 0xeaa2,
			"file-type-pdf": 0xfb10,
			"flame": 0xec2c,
			"gauge": 0xeab1,
			"grip-vertical": 0xec01,
			"hash": 0xeabc,
			"history": 0xebea,
			"home": 0xeac1,
			"keyboard": 0xebd6,
			"layout-grid": 0xedba,
			"link": 0xeade,
			"lock": 0xeae2,
			"logout": 0xeba8,
			"microphone": 0xeaf0,
			"microphone-off": 0xed16,
			"mood-smile": 0xeaf7,
			"moon": 0xeaf8,
			"music": 0xeafc,
			"note": 0xeb6d,
			"notes": 0xeb6e,
			"palette": 0xeb01,
			"paperclip": 0xeb02,
			"photo": 0xeb0a,
			"pin": 0xec9c,
			"player-pause": 0xed45,
			"player-play": 0xed46,
			"player-skip-back": 0xed48,
			"player-skip-forward": 0xed49,
			"player-stop": 0xed4a,
			"plus": 0xeb0b,
			"power": 0xeb0d,
			"refresh": 0xeb13,
			"reload": 0xf3ae,
			"repeat": 0xeb72,
			"settings": 0xeb20,
			"stack-2": 0xeef7,
			"sun": 0xeb30,
			"trash": 0xeb41,
			"video": 0xed22,
			"volume": 0xeb51,
			"volume-2": 0xeb4f,
			"volume-3": 0xeb50,
			"volume-off": 0xf1c3,
			"wifi": 0xeb52,
			"wifi-off": 0xecfa,
			"x": 0xeb55,
			"zzz": 0xf228
		})
	// outline name -> its -filled version's codepoint, where that draws (some are empty in this font,
	// home and microphone among them)
	readonly property var filledCodes: ({
			"adjustments": 0xf6ec,
			"alarm": 0xf709,
			"alarm-snooze": 0xf70c,
			"app-window": 0xf71a,
			"apps": 0xf6f1,
			"arrow-big-up-line": 0xf6d0,
			"battery": 0xf668,
			"battery-1": 0xf71e,
			"battery-2": 0xf71f,
			"battery-3": 0xf720,
			"battery-4": 0xf721,
			"bell": 0xf669,
			"brightness-up": 0xfb24,
			"calendar": 0xfb27,
			"camera": 0xfa37,
			"clock-hour-4": 0xfe5f,
			"device-desktop": 0x1004a,
			"file": 0xf747,
			"gauge": 0xfc2c,
			"layout-grid": 0xfe1c,
			"lock": 0xfe15,
			"mood-smile": 0xf7f8,
			"moon": 0xf684,
			"photo": 0xfa4a,
			"pin": 0xf68d,
			"player-pause": 0xf690,
			"player-play": 0xf691,
			"player-skip-back": 0xf693,
			"player-skip-forward": 0xf694,
			"player-stop": 0xf695,
			"settings": 0xf69e,
			"stack-2": 0xfdd3,
			"sun": 0xf6a9,
			"trash": 0xf783
		})
	// outline glyph -> filled glyph
	readonly property var filledGlyphs: {
		const map = {};
		for (const name in filledCodes)
			map[String.fromCodePoint(codes[name])] = String.fromCodePoint(filledCodes[name]);
		return map;
	}

	function g(name: string): string {
		return codes[name] ? String.fromCodePoint(codes[name]) : "";
	}

	// the filled version of a glyph where Tabler has one, else the glyph itself
	function filled(glyph: string): string {
		return filledGlyphs[glyph] ?? glyph;
	}

	FontLoader {
		id: font

		source: Qt.resolvedUrl("fonts/tabler-icons.ttf")
	}
}
