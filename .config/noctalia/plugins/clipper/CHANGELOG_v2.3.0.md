# Changelog v2.3.0

## Release Date
**2026-03-19**

## New Features

#### Fullscreen Mode
- New toggle in Settings → Features: **Fullscreen Mode**
- Expands the panel to fill the entire screen vertically and horizontally
- Clipboard panel (cliphist) stays anchored to the bottom
- PinCards and NoteCards remain fully accessible in fullscreen
- Panel width expands to full screen width (`screen.width`)
- Panel height expands to full screen height (`screen.height`)

#### Hide Panel Background
- New toggle in Settings → Features: **Hide Panel Background**
- Makes the SmartPanel background transparent — cards float over the desktop blur or wallpaper
- Clipboard panel (cliphist) and PinCards retain their own background for readability
- Clicking anywhere on the transparent background closes the panel (backdrop dismiss)
- Works best combined with Noctalia's background blur effect

#### Auto-Paste on Click
- New toggle in Settings → Auto-Paste: **Auto-Paste on Click**
- After selecting a clipboard item, the panel closes and the content is automatically pasted into the focused window
- Uses `wtype -M ctrl -M shift v` (Ctrl+Shift+V) — works in terminals and most applications
- **Requires `wtype`** — install with `sudo pacman -S wtype` (available in cachyos-extra-v3 / Arch AUR)
- Warning box appears in settings when `wtype` is not installed

#### Auto-Paste Right-Click Mode
- Sub-toggle: **Right-Click Only** (visible when Auto-Paste is enabled)
- When enabled: left-click copies to clipboard normally; right-click copies + pastes
- When disabled: left-click triggers auto-paste; right-click does nothing special
- Works on both clipboard list items and pinned items

#### Auto-Paste Delay Slider
- Slider: **Paste Delay (ms)** — range 100–1000 ms, step 50, default 300 ms
- Allows tuning the delay between panel close and paste trigger
- Increase if your compositor uses focus-follows-cursor (focus needs time to return to target window)

## Improvements

#### NSlider component fix
- Replaced standard Qt `Slider` component with Noctalia's `NValueSlider` widget
- Consistent look and feel with the rest of the settings UI

## i18n

#### 12 new translation keys added (all 17 languages)
- `settings.fullscreen-mode` / `settings.fullscreen-mode-desc`
- `settings.hide-panel-background` / `settings.hide-panel-background-desc`
- `settings.auto-paste-section`
- `settings.auto-paste` / `settings.auto-paste-desc`
- `settings.auto-paste-warning`
- `settings.auto-paste-rmb` / `settings.auto-paste-rmb-desc`
- `settings.auto-paste-delay` / `settings.auto-paste-delay-desc`

Full translations provided for: de, es, fr, pl. English fallback for all other languages.
Italian (`it.json`) — new language file added.

## Technical Notes

- `Panel.qml`: Added `panelBackgroundColor` property — allows plugin to override SmartPanel background color reactively
- `PluginPanelSlot.qml` (Noctalia core): Added forwarding of `panelBackgroundColor` from plugin instance to SmartPanel
- `Main.qml`: Added `wtypeAvailable` detection via `which wtype` on startup; `autoPasteTimer` + `autoPasteProc` with full cleanup in `Component.onDestruction`
- `ClipboardCard.qml`: Added `signal rightClicked`; both MouseAreas updated to handle `Qt.RightButton`

## Known Issues
- After adding a clipboard into ToDo plugin you can't check the complete box or remove that clipboard from ToDo
- Auto-Paste uses Ctrl+Shift+V which works in terminals; for GUI-only apps Ctrl+V would be sufficient — a "Terminal Mode" toggle may be added in a future release

## Upgrade Notes
- Plugin will automatically migrate settings — three new fields added to `settings.json`: `fullscreenMode`, `hidePanelBackground`, `autoPaste`, `autoPasteOnRightClick`, `autoPasteDelay`
- No user action required
- Existing pinned items and notecards are preserved
- `wtype` must be installed separately for Auto-Paste to function
