pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs

// The default speaker and microphone, straight from PipeWire. Changes made here show in the OSD.
Singleton {
	id: root

	readonly property PwNode sink: Pipewire.defaultAudioSink
	readonly property PwNode source: Pipewire.defaultAudioSource
	readonly property real volume: sink?.audio?.volume ?? 0
	readonly property bool muted: sink?.audio?.muted ?? true
	readonly property bool micMuted: source?.audio?.muted ?? true

	function change(percent: int): void {
		const audio = sink?.audio;
		if (!audio)
			return;
		const volume = Math.max(0, Math.min(1, Math.round(audio.volume * 100 + percent) / 100));
		audio.muted = false;
		audio.volume = volume;
		Panel.osd("volume", volume, false);
	}

	function toggleMute(): void {
		const audio = sink?.audio;
		if (!audio)
			return;
		audio.muted = !audio.muted;
		Panel.osd("volume", audio.volume, audio.muted);
	}

	function toggleMic(): void {
		const audio = source?.audio;
		if (!audio)
			return;
		audio.muted = !audio.muted;
		Panel.osd("mic", audio.volume, audio.muted);
	}

	PwObjectTracker {
		objects: [root.sink, root.source].filter(node => node)
	}
}
