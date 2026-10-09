# Desktop shell (Quickshell)

`qs -c desktop`, started by i3 (`.config/i3/conf.d/autostart.conf`). Sources: `.config/quickshell/desktop/`.
Colours come from the desktop theme (see [theme.md](theme.md)); icons are Tabler, as noctalia's
(filled versions for active states; the font sits in `fonts/` beside the config, MIT licensed;
names in `Icons.qml`), apps' own icons come from the GTK icon theme (Tela Circle); settings from
`~/.config/desktop/shell.json`, stowed from the repo, which applies as soon as it's saved.

## Blur

picom blurs behind the shell, inside the shapes its windows take: the bar's pill, the level card,
the notification popups, and the control center and clipboard panels (their windows cover the
screen but take the panel's shape, so clicks beside a panel reach what's below it). Full-screen
windows that only catch clicks, like the power menu's, are left out.

## Control center

A panel that drops out of the middle of the bar, in its colour: an icon sidebar of pages, a header with
the page's title, its buttons and ✕, then the page. The bar's widgets open their page:

| Page | Opened by | What's there |
| --- | --- | --- |
| Home | `$mod+c` | quick toggles (Wi-Fi, Bluetooth, Do Not Disturb, microphone, recording, bar), volume / mic / brightness, the media player (any MPRIS player, browsers included; a switcher when several play; Space plays or pauses, ← → skip) |
| Calendar | the clock | two views, switched in the header. **Calendar**: a month (‹ ›; a dot under days with something on); a click picks a day, whose events, reminders and alarms show below; its + adds one to it. **Reminders & alarms**: one line to add an event, reminder or alarm on any day (click the kind to change it, the date chip for a small month, a time, the text, and for an alarm once / daily / weekdays), then the reminders coming up and every alarm with its switch. A reminder notifies when due; see Alarms. Kept in `~/.local/share/desktop/events.json` and `alarms.json` |
| System monitor | cpu / mem / temp | CPU, memory and temperature with two minutes of history, disk, uptime, load |
| Notifications | the bell, `$mod+n` | the history by day, Clear all; Do Not Disturb in the header |
| Wi-Fi | the Wi-Fi icon | networks by signal: connect (a password for new secured ones), disconnect, forget; scans while open |
| Bluetooth | the Bluetooth icon | devices: pair, connect, disconnect, forget, battery; the header scans |
| Todo | the checklist icon, `$mod+Shift+t` | tasks with a priority (H/M/L, a click on it changes it), grouped high to low, done ones last; drag a task (anywhere on it) to reorder it (among another priority's tasks it takes theirs); kept in `~/.local/share/desktop/todo.json` |
| Notes | the notebook icon, `$mod+Shift+n` | notes of three kinds (text, checklist, code with Copy) with a colour tag; new, pin and delete in the header, search beside the list; kept in `~/.local/share/desktop/notes/` (a private folder) |

The gear opens the settings, the power icon the power menu. Escape, ✕ or focusing another window
closes it. Wi-Fi needs NetworkManager, Bluetooth BlueZ; without them the pages
say so and their bar icons hide.

## Clipboard

`$mod+Shift+v` or the clipboard icon: the history of copied text, dropping out of the bar like the
control center. Type to search, ↑ ↓ to pick, Enter (or a click) copies it back and closes. On an
item: pin it, save it as a code note, or remove it. The history lives in memory only, so copied
passwords never reach the disk; pinned items are kept in `~/.local/state/desktop/clipboard/` (a
private folder).

## Launcher

One panel dropping out of the bar, with one search over four modes; Tab and Shift+Tab (or the chips)
switch them, the arrows move, Enter picks:

| Mode | Key | Enter |
| --- | --- | --- |
| Apps | `$mod+d` | launches it; the ones used most come first |
| Emoji | `$mod+;` | copies it; recent ones first, search by name or group (`heart`, `food`) |
| Files | `$mod+Shift+f` | opens it; **Ctrl+Enter** copies its full path (to paste into a chat), **Shift+Enter** its content (text as text, an image as an image, anything else as the file, so it pastes as an attachment); the row's buttons do the same. Without a search, the files changed this week, newest first |
| Themes | `$mod+Shift+y` | applies it and stays open, to try another; the sun/moon chip switches dark and light |

`desktop-file open|path|content <file>` does the file actions, `desktop-file find [query]` the
search (fd and fzf over `$HOME`, leaving out `.git`, caches and dependencies). Opening picks by type:
text and code in `$EDITOR` (nvim) inside `$TERMINAL` (kitty); web pages, PDFs and SVGs in a new tab
of the browser that's running (Brave, Firefox, Chromium, Chrome, LibreWolf, Vivaldi, Zen), else of
the default one; anything else in its default application. The emoji come from Unicode's list
(`~/.local/share/desktop/emoji.tsv`); use counts and recent emoji are kept in
`~/.local/state/desktop/launcher.json`.

## Screenshots and recording

| Key | |
| --- | --- |
| F12 | the capture panel (again closes it): Screenshot or Record × Region, Window, Screen. The arrows pick a tile, Enter does it; R, W, S take a screenshot straight away, with Shift they record. Only Region uses the mouse: drag a rectangle (Escape or a right click cancels). Window is the focused one. Screen with more than one monitor: a map of them as they're arranged, the panel's own screen picked; the arrows or 1–9 pick, Enter takes it, A takes all, Backspace goes back |
| `$mod+F12`, the camera in the bar | stops a recording, else opens the capture panel |

A screenshot is saved to `~/Pictures/Screenshots` and copied to the clipboard as an image, ready
to paste. A recording (gpu-screen-recorder, 60 fps, the system sound) goes to `~/Videos/Recordings`: a
region, the focused window, or one screen or all of them; while it runs the bar's camera turns red
and pulses on a red pill with the time (a click stops it), and the panel's Record row becomes Stop. `desktop-capture shot|record …` does the work (X11: slop, maim,
xclip; Wayland: slurp, grim, wl-copy, and a window records through the portal).

## Window switcher

Hold Ctrl and tap Tab: the open windows come up as rounded cards on a ring, most recently used
first, and each Tab turns the ring to bring the next one to the front (Ctrl+Shift+Tab or Ctrl+←
turn it back); cards further round shrink, fade and turn away. Let go of Ctrl to switch to the front
one; Escape cancels, a click picks one. A quick Ctrl+Tab goes straight back to the last window
without showing the ring. Ctrl+Tab is taken from apps (browser and terminal tabs) on i3.

The shell's popup can't take the keyboard on X11, so i3's mode "switcher" sends the keys over IPC;
i3 can't see Ctrl let go (it was pressed before the mode began), so the shell runs
`desktop-ctrl-release`, which asks X whether Ctrl is still held (nothing is grabbed). Cards show the
app's icon, the window's title, the app and workspace; X11 has no live window previews.

## Alarms

Set in the calendar (Reminders & alarms): a time, a label and how often; a once alarm rings on its
day. A ringing alarm plays the alarm sound (5 minutes at most) and shows a card under the bar:
**Stop** ends it (a repeating one rings again on its next day), **Snooze** silences it and rings
again in 5 minutes (the list shows "Snoozed" meanwhile).

## Wallpaper

`$mod+Shift+p`: the wallpapers, dropping out of the bar like the clipboard. Type to search by name,
↑ ↓ (or Tab) to move, Enter or a click sets one; the set one has a ring and a tick. The chip beside
the search picks rotation: never, every 5 minutes, hourly, daily or each boot; the shuffle button
sets one at random. The images come from `wallpaper.folders` (shell.json; the repo's and
`~/Wallpaper-Bank`).

`desktop-wallpaper set <image>` does the setting: it points `~/.local/state/desktop/wallpaper` at it
(the lock screen, sddm and GRUB use it too) and fades over to it. On X11 feh has no transitions, so
it shows three half-size blended frames (made in parallel with ImageMagick) before the full image;
on Wayland swww's fade when its daemon runs, else sway's background. `desktop-wallpaper restore`
draws the remembered one at login.

## Settings window

`$mod+Shift+s` (or `qs -c desktop ipc call settings toggle`): Bar (style, position, height,
opacity, island width, capsules, widgets dragged between the bar's parts), Appearance (theme and dark/light, through `theme`),
Notifications, Levels (volume/brightness steps, how long the level card stays) and Power; Escape
or focusing another window closes it. Changes
apply at once and are written to `shell.json`, through the stow link into the repo, so they show up
in `git diff`; Quickshell writes it with sorted keys and 4-space indents, as it's kept.

## Bar

| Setting (`bar.*`) | Values |
| --- | --- |
| `style` | `island` (a floating pill) or `static` (the whole edge, word labels and separators) |
| `position` | `top`, `bottom`; `left`/`right` on sway only (i3 docks only top or bottom, so X11 uses the top) |
| `size`, `opacity`, `length` | thickness in px, background opacity, the island's share of the edge (0: by the screen width, 80 % under 1500 px down to 42 % from 2200 px; never shorter than its content) |
| `left`, `center`, `right` | widgets: `launcher`, `workspaces`, `clock`, `stats`, `volume`, `brightness`, `battery`, `tray`, `recorder`, `notifications`, `scratchpad`, `controls`, `wifi`, `bluetooth`, `tools` (clipboard, todo, notes), `clipboard`, `notes`, `todo`, `power`; with `capsules` each sits in a capsule |

Workspaces are dots: the ones with windows and the one you're on (i3 and sway drop empty ones), the
current one a wide pill. After them, the scratchpad's window count while it holds any; a click brings
one up.
Hidden with `$mod+Shift+b`, the bar comes back over the windows while the pointer is at its edge.

## Keys (i3)

| Key | Does |
| --- | --- |
| F1 / F2 / F3, media keys | mute, volume down, volume up |
| F4 / F5, brightness keys | brightness down, up |
| F6, mic-mute key | microphone mute |
| `$mod+F12` | stop a recording, else the capture panel |
| F12 | capture panel: screenshots and recordings (F12 no longer reaches apps, e.g. browser dev tools) |
| `$mod+Shift+b` | hide / show the bar |
| `$mod+n` | notifications (control center) |
| `$mod+Shift+s` | settings |
| `$mod+c` | control center |
| `$mod+Shift+v` | clipboard history |
| `$mod+Shift+p` | wallpapers |
| `$mod+d`, `$mod+;`, `$mod+Shift+f`, `$mod+Shift+y` | the launcher: apps, emoji, files, themes |
| Ctrl+Tab (hold Ctrl) | window switcher |
| `$mod+Shift+t` / `$mod+Shift+n` | todo / notes |
| `$mod+p` | power menu (again, Escape or a click beside it closes): arrows or 1–5 pick, Enter runs |

Each change shows in a card at the top right; Caps Lock and Num Lock show there by themselves.

## Notifications

The shell is the notification daemon on i3. New ones pop up at the top right and leave after their
timeout (5 s unless the app sets one), not while hovered; critical ones stay until closed. A click
runs the app's default action; ✕ dismisses for good.

The bell shows a dot for unread ones. A click (or `$mod+n`) opens the control center's
Notifications tab: the history, newest first, filtered by All / Today / Yesterday / Older, with Do
Not Disturb and Clear. A right click on the bell toggles Do
Not Disturb: popups stop, except critical ones, and everything still reaches the history. The
history lasts until the shell restarts.

## Power menu

Lock, Log Out, Lock & Suspend, Reboot, Shut Down; Log Out, Reboot and Shut Down take a second
press while `power.confirm` is on. Nothing hibernates.

- **Lock** runs `loginctl lock-session`; on i3, xss-lock starts `desktop-lock`: i3lock-color over the
  blurred, dimmed wallpaper (cached in `~/.cache/desktop`), a clock and a small ring that lights up
  as you type. xss-lock also locks after X's idle timeout. The laptop keeps running.
- **Closing the lid** only locks, after `packages/system.sh lid` (logind `HandleLidSwitch=lock`),
  so work carries on with the lid shut. On battery it keeps draining.
- **Lock & Suspend** sleeps; xss-lock locks first.
- On sway the lock will be the shell's own (Wayland's session lock, a password field with PAM),
  coming with the sway version of the shell.

## IPC

`qs -c desktop ipc call <target> <function>`: `audio up|down|mute|mic`, `brightness up|down`,
`bar toggle`, `recorder toggle`, `notifications toggle|dnd|clear`, `settings toggle`, `control toggle|open <page>|page <page>|close`, `clipboard toggle`, `wallpaper toggle|shuffle`, `launcher toggle <apps|emoji|files|themes>|close`, `switcher next|prev|commit|cancel`, `capture toggle|shot <region|window|screen>|record <region|window|screen>|stop`, `alarm stop|snooze`, `power open|toggle|close|next|prev|activate|pick <n>`,
`theme reload`.
