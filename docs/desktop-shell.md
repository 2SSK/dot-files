# Desktop shell (Quickshell)

`qs -c desktop`, started by sway (`.config/sway/desktop/startup.conf`). Sources: `.config/quickshell/desktop/`. i3 runs
without it, a minimal session of polybar, rofi and dunst with the same keys: see [i3.md](i3.md).
Colours come from the desktop theme (see [theme.md](theme.md)); icons are Tabler
(filled versions for active states; the font sits in `fonts/` beside the config, MIT licensed;
names in `Icons.qml`), apps' own icons come from the GTK icon theme (Tela Circle); settings from
`~/.config/desktop/shell.json`, stowed from the repo, which applies as soon as it's saved.

## Blur

SwayFX rounds, shadows and blurs behind translucent windows (`.config/sway/effects.conf`).

## Control center

A panel that drops out of the middle of the bar, in its colour: the island widens, then it unfolds. At
the top a row of six page tabs (a highlight slides to the one open) with the page's buttons, Settings
and Power beside it, then the page. The bar's widgets open their page; from the keyboard,
**Ctrl+Tab** / **Ctrl+Shift+Tab** (or Ctrl+PgDn / PgUp) turn the tabs and **Alt+1…6** jump to one.
Todo and Notes have no tab: their keys open them, with a ‹ back to Home (Notes widens the panel for
its list beside the editor).

| Page | Opened by | What's there |
| --- | --- | --- |
| Home | `$mod+c` | Wi-Fi, Bluetooth and Airplane mode in one card (a name opens its page); Do Not Disturb and screen recording; Night light, keep awake, microphone and dark mode as round tiles; the display and sound as thick bars (the output and input to pick); the power profile; the media player (any MPRIS player, browsers included; a switcher when several play; Space plays or pauses, ← → skip); the date and battery |
| Calendar | the clock | two views, switched in the header. **Calendar**: a month (‹ ›; a dot under days with something on); a click picks a day, whose events, reminders and alarms show below; its + adds one to it. **Reminders & alarms**: one line to add an event, reminder or alarm on any day (click the kind to change it, the date chip for a small month, a time, the text, and for an alarm once / daily / weekdays), then the reminders coming up and every alarm with its switch. A reminder notifies when due; see Alarms. Kept in `~/.local/share/desktop/events.json` and `alarms.json` |
| System monitor | cpu / mem / temp | CPU, memory and temperature with two minutes of history, disk, uptime, load |
| Notifications | the bell, `$mod+n` | the history by day, Clear all; Do Not Disturb in the header |
| Wi-Fi | the Wi-Fi icon | networks by signal: connect (a password for new secured ones), disconnect, forget; scans while open |
| Bluetooth | the Bluetooth icon | devices: pair, connect, disconnect, forget, battery; the header scans. Paired devices are kept trusted (so they reconnect by themselves); one that can't connect, keeps dropping or can't pair says so and offers Re-pair (forget, pair again, connect). If that fails too, clear the device's own Bluetooth profile (ZMK: `&bt BT_CLR`) and Pair |
| Todo | `$mod+Shift+t` | tasks with a priority (H/M/L, a click on it changes it), grouped high to low, done ones last; drag a task (anywhere on it) to reorder it (among another priority's tasks it takes theirs); kept in `~/.local/share/desktop/todo.json` |
| Notes | `$mod+Shift+n` | notes of three kinds (text, checklist, code with Copy) with a colour tag; new, pin and delete in the header, search beside the list; kept in `~/.local/share/desktop/notes/` (a private folder) |

The gear opens the settings, the power icon the power menu. Escape or focusing another window
closes it. Wi-Fi needs NetworkManager, Bluetooth BlueZ; without them the pages
say so and their bar icons hide.

## Clipboard

`$mod+Shift+c` or the clipboard icon: the history of what you copied (text, images and files,
pinned ones first) on the left, the selected one in full on the right: the text, the picture, the
files. Type to search, ↑ ↓ to pick. Enter (or a double click) puts it back on the clipboard and
pastes it into the window you were in (Ctrl+Shift+V in a terminal, Ctrl+V elsewhere); Shift+Enter
or Copy only puts it back. Either way it goes back as what it was and the panel closes: an image pastes as an image (into Claude Code, opencode, a chat), files paste as
attachments. Pin, Open (images, files), Save as a note (text) and Remove sit under the preview;
Clear empties the history (pins stay).

`desktop clipboard watch` reports each copy (X11: XFixes, no polling; Wayland: `wl-paste --watch`).
Text stays in memory and images in `$XDG_RUNTIME_DIR` (RAM, gone at logout; the newest 30 kept), so
copied passwords and screenshots never reach the disk, and a password manager's copies are left
out. Pinned entries are kept in `~/.local/state/desktop/clipboard/` (a private folder; a pinned
image is copied there). Region and window screenshots (F12) land in it like any copy.
## Sway

`~/.config/sway/config` includes `desktop.conf`. It reuses i3's keys, workspaces, window rules,
colours and resize mode as they are, with sway's variables (swayfx's corners, shadows and blur),
outputs and input; `sway/desktop/` adds what only sway needs: what starts with the session, and
swayfx's touches for the shell. The keys reach the shell as `$shell <target> <function>` (its IPC);
on i3 the same keys reach `desktop i3` instead ([i3.md](i3.md)).

## Launcher

One panel dropping out of the bar, with one search over four modes; Tab and Shift+Tab (or the chips)
switch them, the arrows (or Ctrl+N / Ctrl+P) move, Enter picks:

| Mode | Key | Enter |
| --- | --- | --- |
| Apps | `$mod+d` | launches it; the ones used most come first. A time (`2:00 ist`, `14:30 utc`, a log timestamp) shows converted, and a sum (`12*4`, `3 x 4`, `2^10`, `15% of 80`, `200 + 10%`, `sqrt(2)`) worked out, above the apps: Enter copies the answer |
| Emoji | `$mod+;` | copies it; recent ones first, search by name or group (`heart`, `food`) |
| Files | `$mod+Shift+f` | **Enter** (or a click) copies the file itself (its `file://` URI as `text/uri-list` alone, as a file manager copies), so Ctrl+V in Teams, WhatsApp or a mail attaches it; **Ctrl+Enter** opens it; **Shift+Enter** copies its full path; **Ctrl+Shift+Enter** its content (text as text, an image as an image); the row's buttons do the same. Without a search, the files changed this week, newest first |
| Themes | `$mod+Shift+y` | applies it and stays open, to try another; the sun/moon chip switches dark and light |

`desktop file open|file|path|content <file>` does the file actions (`copy-exact` puts a file on the Wayland clipboard as `text/uri-list` alone; `wl-copy` would add text), `desktop file find [query]` the
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
| Ctrl+F12 / Shift+F12 | without the panel: drag a region / the whole screen you're on, saved and copied at once |
| `T` in the capture panel | drag over text on screen: it's read and copied as text, the image not kept |
| `C` in the capture panel | click a pixel: its colour is copied as `#rrggbb` and shown (`desktop capture colour`) |

A screenshot is saved to `~/Pictures/Screenshots` and copied to the clipboard as an image, ready
to paste. A recording (gpu-screen-recorder, 60 fps, the system sound and the microphone on one track; Settings → Sound turns the microphone off) goes to `~/Videos/Recordings`: a
region, the focused window, or one screen or all of them; while it runs a small red dot sits beside
the bar's clock (a click on the clock stops it), and the panel's Record row becomes Stop. `desktop capture shot|record …` does the work (X11: slop, maim,
xclip; Wayland: slurp, grim, wl-copy, and a window records through the portal).

Copying text (`desktop capture text`) reads the region offline with Tesseract, English only by
default. Normal text comes out well; check code and commands, since indentation can be lost and
look-alikes such as `0`/`O` and `1`/`l` get confused.

Screen sharing (Teams, Meet, OBS, and a window recording) goes through xdg-desktop-portal-wlr, which
asks the capture panel what to share: the screens, then the open windows most recent first, with their
app and workspace. The arrows or 1–9 pick, Enter or a click shares it, Escape declines.
`desktop share-pick` is the portal's picker (`.config/xdg-desktop-portal-wlr/config`); without the
shell running it shares the first screen.

## Window switcher

Hold Alt and tap Tab: the open windows come up as rounded cards on a ring, most recently used
first, and each Tab turns the ring to bring the next one to the front (Alt+Shift+Tab or Alt+←
turn it back); cards further round shrink, fade and turn away. Let go of Alt to switch to the front
one; Escape cancels, a click picks one. A quick Alt+Tab goes straight back to the last window
without showing the ring.

Cards show the app's icon, the window's title, the app and workspace.

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
`~/Wallpaper-Bank`), from the current theme's folder when it has some (`~/Wallpaper-Bank/nord/`).

Each boot's wallpaper is picked as the system shuts down, not at login: a user service
(`desktop-wallpaper-next`) runs `desktop wallpaper next-boot`, which sets the next one and redraws the
login screen's background. So the login screen and the desktop start on it, with no change after
you log in. A logout keeps the wallpaper; only a shutdown or reboot picks a new one.

`desktop wallpaper set <image>` does the setting: it points `~/.local/state/desktop/wallpaper` at it
(the lock screen and sddm use it too) and fades over to it. On X11 feh has no transitions, so
it shows three half-size blended frames (made in parallel with ImageMagick) before the full image;
on Wayland awww draws it, cross-fading over 0.8 s (its daemon holds one frame per screen: about
13 MB, where the shell drawing it took 50). `desktop wallpaper restore` draws the remembered one at
login, without a fade, starting awww's daemon on sway.

The login screen follows the wallpaper too. It can't read the home folder, so
`packages/system.sh sddm` gives you its background file (in `/var/lib/desktop/sddm`), and every
wallpaper change redraws it without sudo. `desktop wallpaper screens` redraws it by hand.

### Live wallpapers (sway)

Videos and GIFs in the same folders (`~/Wallpaper-Bank/animated/`) show under **All** with a
**Live** badge (a video as a still frame, made once with ffmpeg and cached). A click plays it over
the still wallpaper; a click on it again, or on a still one, stops it. Nothing switches it on or off
by itself: it plays until you stop it, across logins too, and pauses while the screen is
locked, the laptop is on battery or a window is fullscreen (a video, a game). The still one stays set beneath it, so the lock screen, login screen and theme colours
don't change. Rotation never touches it.

`desktop wallpaper live <file>|off|pause|resume` does it: mpvpaper (AUR), muted, looped, hardware
decoding, over every screen, paused and resumed over mpv's control socket. It costs battery the whole
time it plays, more for a 4K file on a 1080p screen: `ffmpeg -i in.mp4 -vf scale=-2:1080 -an out.mp4`
makes it lighter. i3 has no live wallpapers.

## Settings window

`$mod+Shift+s` (or `qs -c desktop ipc call settings toggle`): Bar (style, capsules, position,
height, opacity; picking a style also sets its capsules), Appearance (theme and dark/light, through `theme`),
Notifications, Levels (volume/brightness steps, how long a level shows in the clock's place) and Power; Escape
or focusing another window closes it. Changes
apply at once and are written to `shell.json`, through the stow link into the repo, so they show up
in `git diff`; Quickshell writes it with sorted keys and 4-space indents, as it's kept.

The **Keys** page lists every key binding in words, read from i3's own key config (so it can't
drift from what the keys do), grouped and searchable, with the keys inside the shell's panels at
the end. `$mod+Shift+/` opens it.


The **Timeshift** page lists the system's snapshots (newest first, with their kind and comment),
makes one now with a comment, and deletes one (a second press confirms); restoring opens Timeshift
itself. Listing needs root: `packages/system.sh timeshift` allows exactly `timeshift --list
--scripted` without a password (`/etc/sudoers.d/90-desktop-timeshift`, after the installer's rules); without it the page asks
once. `desktop timeshift list|create|delete` does the work.

`packages/system.sh timeshift` also sets what is kept: 3 daily snapshots, 1 weekly, and (with
`timeshift-autosnap`) the last 3 taken before a pacman upgrade. `packages/system.sh subvolumes`
makes the VM disks, `/var/lib/docker` and `~/.cache` btrfs subvolumes of their own, which
snapshots leave out (they change all day); the originals are kept beside them until you remove
them. `packages/cleanup.sh packages|docker|caches|all` makes room: the packages in
`packages/remove.txt` and orphans (never one the repo's lists install), unused Docker images,
build cache and unnamed volumes (never containers: a stopped one may hold a database's data), and old package caches.

## When idle

Settings → Power → **When idle**: the screen dims after 4 minutes alone (any key or movement brings
it back), locks after 5 and switches off after 10; each can be Never. swayidle, run by the shell, keeps them
(i3 reads the same minutes at login: [i3.md](i3.md)). Video players and browsers playing video hold the screensaver
off themselves. Locking keeps the laptop running; nothing suspends on its own.

## Night light

A warmer screen, through gammastep (X11 and Wayland alike): the control center's **Night light**
tile turns it on or off, Settings → Appearance sets how warm (3000–6000 K, 4000 K by default) and
an optional schedule (on by itself from 19:00 to 07:00 by default; switching it off during those
hours keeps it off until they end). It fades in and back out. `nightlight toggle` over IPC.

## Password prompts (polkit)

The shell is the session's polkit agent on sway (on i3 it's polkit-gnome): when an app asks for admin rights (pkexec,
Timeshift, a package manager's GUI), a small panel drops from the bar with what's asked and a
password field; Escape or Cancel declines, a wrong password shakes it and asks again.
## Bar

| Setting (`bar.*`) | Values |
| --- | --- |
| `style` | `island` (a floating pill, as wide as what it holds) or `static` (the whole edge: status, workspace chips, clock) |
| `capsules` | island: each part in a round pill; static: each widget in a soft chip |
| `position` | `top`, `bottom`; `left`/`right` on sway only (i3 docks only top or bottom, so X11 uses the top) |
| `size`, `opacity` | thickness in px, background opacity |
| `left`, `center`, `right` | widgets: `launcher`, `workspaces`, `clock`, `stats`, `volume`, `brightness`, `battery`, `tray`, `recorder`, `notifications`, `scratchpad`, `controls`, `wifi`, `bluetooth`, `tools` (clipboard, todo, notes), `clipboard`, `notes`, `todo`, `power`. The island follows these lists; the static bar puts the status first, the workspaces in the middle and the clock last. Edited here only: Settings doesn't move them |

On the island, workspaces are dots: the ones with windows and the one you're on (i3 and sway drop
empty ones), the current one a wide pill. The static bar shows its screen's five as Roman-numeral
chips (VI–X on the laptop while a monitor has I–V), an accent sliding to the current one. After them, the scratchpad's window count while it holds any; a click shows or
hides it. The scratchpad is one floating workspace (`desktop scratch`): `$mod+Shift+Return` adds the
window to a tabbed, centred group, `$mod+minus` shows or hides the whole group, and inside it the usual
keys tab, split and focus.
Hidden with `$mod+Shift+b`, the bar comes back over the windows while the pointer is at its edge.

## Keys

| Key | Does |
| --- | --- |
| F1 / F2 / F3, media keys | mute, volume down, volume up |
| F4 / F5, brightness keys | brightness down, up |
| F6, mic-mute key | microphone mute |
| `$mod+F12` | stop a recording, else the capture panel |
| F12 | capture panel: screenshots and recordings (F12 no longer reaches apps, e.g. browser dev tools) |
| Ctrl+F12 | screenshot of a dragged region, no panel |
| Shift+F12 | screenshot of the screen you're on, no panel |
| `$mod+Shift+z` | zoom into the screen, as Tsoding's boomer does: the wheel zooms, a drag pans, Ctrl lights round the pointer, Esc quits (woomer on sway, boomer on i3: `desktop zoom`) |
| `$mod+Shift+b` | hide / show the bar |
| `$mod+n` | notifications (control center) |
| `$mod+Shift+s` | settings |
| `$mod+c` | control center |
| `$mod+Shift+c` | clipboard history |
| `$mod+Shift+v` | reload i3 (or sway) |
| `$mod+Shift+p` | wallpapers |
| `$mod+d`, `$mod+;`, `$mod+Shift+f`, `$mod+Shift+y` | the launcher: apps, emoji, files, themes |
| Alt+Tab (hold Alt) | window switcher |
| `$mod+Shift+/` (Super+?) | every key binding, in words (Settings → Keys) |
| `$mod+Escape` | keys to the VM (or anything nested) until pressed again; the bar shows "VM keys" |
| `$mod+Shift+t` / `$mod+Shift+n` | todo / notes (on i3: rofi menus, [notes.md](notes.md)) |
| `$mod+p` | power menu (again, Escape or a click beside it closes): arrows or 1–5 pick, Enter runs |

Each change shows in a card at the top right; Caps Lock and Num Lock show there by themselves.

## Notifications

The shell is the notification daemon on sway (dunst is i3's). New ones pop up at the top right and leave after their
timeout (5 s unless the app sets one), not while hovered; critical ones stay until closed. A click
runs the app's default action; ✕ dismisses for good.

The bell shows a dot for unread ones. A click (or `$mod+n`) opens the control center's
Notifications tab: the history, newest first, filtered by All / Today / Yesterday / Older, with Do
Not Disturb and Clear. A right click on the bell toggles Do
Not Disturb: popups stop, except critical ones, and everything still reaches the history. The
history lasts until the shell restarts.

## Power menu

A panel like the control center: the island widens and a row of tiles unfolds from it. Lock, Log Out,
Lock & Suspend, Reboot, Shut Down; Log Out, Reboot and Shut Down take a second press while
`power.confirm` is on. Nothing hibernates.

- **Lock** runs `loginctl lock-session`; on i3, xss-lock starts `desktop lock`: i3lock-color over the
  blurred, dimmed wallpaper (cached in `~/.cache/desktop`), a clock and a small ring that lights up
  as you type. xss-lock also locks after X's idle timeout. The laptop keeps running.
- **Closing the lid** only locks, after `packages/system.sh lid` (logind `HandleLidSwitch=lock`),
  so work carries on with the lid shut. On battery it keeps draining.
- **Lock & Suspend** sleeps; xss-lock locks first.
- On sway the lock will be the shell's own (Wayland's session lock, a password field with PAM),
  coming with the sway version of the shell.

## IPC

`qs -c desktop ipc call <target> <function>`: `audio up|down|mute|mic`, `brightness up|down`,
`bar toggle`, `recorder toggle`, `notifications toggle|dnd|clear`, `settings toggle|page <bar|appearance|notifications|levels|power|timeshift|keys>`, `control toggle|open <page>|page <page>|close`, `clipboard toggle`, `wallpaper toggle|shuffle`, `launcher toggle <apps|emoji|files|themes>|close`, `switcher next|prev|commit|cancel|list`, `nightlight toggle`, `capture toggle|shot <region|window|screen>|record <region|window|screen>|stop`, `share pick <dir>` (desktop share-pick), `alarm stop|snooze`, `power open|toggle|close|next|prev|activate|pick <n>`,
`theme reload`.
