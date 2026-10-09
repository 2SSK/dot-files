import QtQuick
import qs

// Clipboard history, todo and notes as one group (one capsule).
Line {
	vertical: Config.vertical
	spacing: 12

	ClipboardButton {}

	TodoButton {}

	NotesButton {}
}
