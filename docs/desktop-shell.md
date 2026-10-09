# Desktop shell (Quickshell)

`qs -c desktop`, started by i3 (`.config/i3/conf.d/autostart.conf`). Sources: `.config/quickshell/desktop/`.
Colours come from the desktop theme (see [theme.md](theme.md)); settings from
`~/.config/desktop/shell.json`, stowed from the repo, which applies as soon as it's saved.

## Control center

A panel that drops out of the middle of the bar, in its colour: an icon sidebar of pages, a header with
the page's title, its buttons and ✕, then the page. The bar's widgets open their page:

| Page | Opened by | What's there |
| --- | --- | --- |
| Home | `$mod+c` | quick toggles (Wi-Fi, Bluetooth, Do Not Disturb, microphone, recording, bar), volume / mic / brightness, the media player |
| Calendar | the clock | a month; ‹ › and Today |
| System monitor | cpu / mem / temp | CPU, memory and temperature with two minutes of history, disk, uptime, load |
| Notifications | the bell, `$mod+n` | the history by day; Do Not Disturb and clear in the header |
| Wi-Fi | the Wi-Fi icon | networks by signal: connect (a password for new secured ones), disconnect, forget; scans while open |
| Bluetooth | the Bluetooth icon | devices: pair, connect, disconnect, forget, battery; the header scans |
| Todo | the checklist icon, `$mod+Shift+t` | tasks with a priority (H/M/L, a click on it changes it), sorted high to low, done ones last; kept in `~/.local/share/desktop/todo.json` |
| Notes | the notebook icon, `$mod+Shift+n` | notes of three kinds (text, checklist, code with Copy) with a colour tag; new, pin and delete in the header, search beside the list; kept in `~/.local/share/desktop/notes/` (a private folder) |

The gear opens the settings, the power icon the power menu. Escape, ✕, focusing another window or a
click anywhere else closes it. Wi-Fi needs NetworkManager, Bluetooth BlueZ; without them the pages
say so and their bar icons hide.

## Clipboard

`$mod+Shift+v` or the clipboard icon: the history of copied text, dropping out of the bar like the
control center. Type to search, ↑ ↓ to pick, Enter (or a click) copies it back and closes. On an
item: pin it, save it as a code note, or remove it. The history lives in memory only, so copied
passwords never reach the disk; pinned items are kept in `~/.local/state/desktop/clipboard/` (a
private folder).

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
| `$mod+F12` | start / stop screen recording (gpu-screen-recorder, into `~/Videos`) |
| `$mod+Shift+b` | hide / show the bar |
| `$mod+n` | notifications (control center) |
| `$mod+Shift+s` | settings |
| `$mod+c` | control center |
| `$mod+Shift+v` | clipboard history |
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

- **Lock** runs `loginctl lock-session`; xss-lock starts `desktop-lock`: i3lock-color over the
  blurred, dimmed wallpaper (cached in `~/.cache/desktop`), a clock and a small ring that lights up
  as you type. xss-lock also locks after X's idle timeout. The laptop keeps running.
- **Closing the lid** only locks, after `packages/system.sh lid` (logind `HandleLidSwitch=lock`),
  so work carries on with the lid shut. On battery it keeps draining.
- **Lock & Suspend** sleeps; xss-lock locks first.

## IPC

`qs -c desktop ipc call <target> <function>`: `audio up|down|mute|mic`, `brightness up|down`,
`bar toggle`, `recorder toggle`, `notifications toggle|dnd|clear`, `settings toggle`, `control toggle|open <page>|page <page>|close`, `clipboard toggle`, `power open|toggle|close|next|prev|activate|pick <n>`,
`theme reload`.
