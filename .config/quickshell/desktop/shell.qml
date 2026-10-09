// The desktop shell (qs -c desktop): one bar per screen. Colours come from Theme (the desktop theme).
import Quickshell

ShellRoot {
	Variants {
		model: Quickshell.screens

		Bar {}
	}
}
