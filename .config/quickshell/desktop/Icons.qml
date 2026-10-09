pragma Singleton

import QtQuick
import Quickshell

// The shell's icons: Tabler (as noctalia's), loaded from fonts/ beside the config, so nothing has
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
			"app-window": 0xefe6,
			"arrow-big-up-line": 0xefee,
			"battery": 0xea34,
			"battery-1": 0xea2f,
			"battery-2": 0xea30,
			"battery-3": 0xea31,
			"battery-4": 0xea32,
			"battery-charging": 0xea33,
			"bell": 0xea35,
			"bell-off": 0xece9,
			"bell-ringing": 0xed07,
			"bluetooth": 0xea37,
			"bluetooth-off": 0xeceb,
			"brightness-half": 0xee1a,
			"calendar": 0xea53,
			"check": 0xea5e,
			"checkbox": 0xeba6,
			"chevron-left": 0xea60,
			"chevron-right": 0xea61,
			"clipboard-text": 0xf089,
			"code": 0xea77,
			"cpu": 0xef8e,
			"database": 0xea88,
			"grip-vertical": 0xec01,
			"hash": 0xeabc,
			"home": 0xeac1,
			"layout-grid": 0xedba,
			"list-check": 0xeb6a,
			"lock": 0xeae2,
			"logout": 0xeba8,
			"microphone": 0xeaf0,
			"microphone-off": 0xed16,
			"moon": 0xeaf8,
			"music": 0xeafc,
			"note": 0xeb6d,
			"notebook": 0xeb96,
			"palette": 0xeb01,
			"pencil": 0xeb04,
			"pin": 0xec9c,
			"player-pause": 0xed45,
			"player-play": 0xed46,
			"player-skip-back": 0xed48,
			"player-skip-forward": 0xed49,
			"plus": 0xeb0b,
			"power": 0xeb0d,
			"refresh": 0xeb13,
			"reload": 0xf3ae,
			"search": 0xeb1c,
			"settings": 0xeb20,
			"stack-2": 0xeef7,
			"temperature": 0xeb38,
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
	// outline name -> its -filled version's codepoint
	readonly property var filledCodes: ({
			"adjustments": 0xf6ec,
			"app-window": 0xf71a,
			"arrow-big-up-line": 0xf6d0,
			"battery": 0xf668,
			"battery-1": 0xf71e,
			"battery-2": 0xf71f,
			"battery-3": 0xf720,
			"battery-4": 0xf721,
			"bell": 0xf669,
			"bell-ringing": 0xf725,
			"calendar": 0xfb27,
			"home": 0xfe2b,
			"layout-grid": 0xfe1c,
			"lock": 0xfe15,
			"microphone": 0xfe0f,
			"moon": 0xf684,
			"pin": 0xf68d,
			"player-pause": 0xf690,
			"player-play": 0xf691,
			"player-skip-back": 0xf693,
			"player-skip-forward": 0xf694,
			"settings": 0xf69e,
			"stack-2": 0xfdd3,
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
