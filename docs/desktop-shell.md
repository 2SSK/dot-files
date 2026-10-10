# Desktop shell (Quickshell)

`qs -c desktop`, started by sway (`.config/sway/desktop/startup.conf`) and i3 (`.config/i3/conf.d/autostart.conf`). Sources: `.config/quickshell/desktop/`.
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

`$mod+Shift+c` or the clipboard icon: the history of what you copied (text, images and files,
pinned ones first) on the left, the selected one in full on the right: the text, the picture, the
files. Type to search, ↑ ↓ to pick. Enter (or a double click) puts it back on the clipboard and
pastes it into the window you were in (Ctrl+Shift+V in a terminal, Ctrl+V elsewhere); Shift+Enter
or Copy only puts it back. Either way it goes back as what it was and the panel closes: an image pastes as an image (into Claude Code, opencode, a chat), files paste as
attachments. Pin, Open (images, files), Save as a note (text) and Remove sit under the preview;
Clear empties the history (pins stay).

`desktop-clipboard watch` reports each copy (X11: XFixes, no polling; Wayland: `wl-paste --watch`).
Text stays in memory and images in `$XDG_RUNTIME_DIR` (RAM, gone at logout; the newest 30 kept), so
copied passwords and screenshots never reach the disk, and a password manager's copies are left
out. Pinned entries are kept in `~/.local/state/desktop/clipboard/` (a private folder; a pinned
image is copied there). Region and window screenshots (F12) land in it like any copy.
## Sway

The same shell runs on sway: `~/.config/sway/config` includes `desktop.conf`, with the same keys as i3. It reuses i3's keys, workspaces,
window rules, colours and resize mode as they are, sway's variables (swayfx's corners, shadows and
blur), outputs and input; `sway/desktop/` adds what only sway needs: what starts with the session,
and swayfx's touches for the shell. What differs underneath:

| | i3 (X11) | sway (Wayland) |
| --- | --- | --- |
| Panels | a floating window as big as the screen | a layer surface over the screen with the keyboard |
| Lock screen | i3lock-color (`desktop-lock`) | the shell's own (Quickshell's session lock, PAM `lock/pam/lock`) |
| Idle | X's timers (`desktop-idle apply`) and xss-lock | swayidle, run by the shell with the same settings |
| Alt+Tab ends | `desktop-key-release alt` watches X | the ring holds the keyboard and sees Alt let go |
| Clipboard history | Qt's clipboard signal | `wl-paste --watch` |
| Wallpaper | feh | swaybg (`swaymsg output * bg`), or swww's fade when it runs |
| Screens, touchpad | `desktop-displays`, `desktop-input` | sway's `outputs` and `input` |

## Launcher

One panel dropping out of the bar, with one search over four modes; Tab and Shift+Tab (or the chips)
switch them, the arrows move, Enter picks:

| Mode | Key | Enter |
| --- | --- | --- |
| Apps | `$mod+d` | launches it; the ones used most come first |
| Emoji | `$mod+;` | copies it; recent ones first, search by name or group (`heart`, `food`) |
| Files | `$mod+Shift+f` | **Enter** (or a click) copies the file itself (its `file://` URI as `text/uri-list` alone, as a file manager copies), so Ctrl+V in Teams, WhatsApp or a mail attaches it; **Ctrl+Enter** opens it; **Shift+Enter** copies its full path; **Ctrl+Shift+Enter** its content (text as text, an image as an image); the row's buttons do the same. Without a search, the files changed this week, newest first |
| Themes | `$mod+Shift+y` | applies it and stays open, to try another; the sun/moon chip switches dark and light |

`desktop-file open|file|path|content <file>` does the file actions (`wl-copy-exact` puts a file on the Wayland clipboard as `text/uri-list` alone; `wl-copy` would add text), `desktop-file find [query]` the
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

## Screens (i3)

`desktop-displays` arranges screens as sway's outputs config does: the laptop panel at the left,
each connected external screen to the right of the one before at its preferred mode; an unplugged
screen is turned off, and the wallpaper is drawn again across them. i3 starts it in `watch` mode,
which listens for plug and unplug events (`udevadm monitor`) and arranges again. Workspaces 2, 3, 9
and 10 live on the external screen (HDMI-1, else DP-1), the rest on the panel, as on sway; with no
external screen they all stay on the panel. The bar and its panels follow onto each screen; the
capture panel's Screen choice shows a map of them.

## Touchpad (i3)

`desktop-input`, run when i3 starts or reloads, sets the touchpad up as sway's input config does:
tap to click (one finger left, two right, three middle), tap and drag, natural two-finger scrolling,
click with fingers, no touchpad while typing, middle-click emulation. Scrolling on X is twice as fast
as on Wayland by default, so it's slowed: one scroll step per 45 pixels of finger movement
(`DESKTOP_SCROLL_DISTANCE`, 10–50; X's default is 15). Displays use no scaling, as on sway.

picom is started by i3 alone (the package's XDG autostart entry is hidden in
`~/.config/autostart/picom.desktop`: two at login raced, and ours fell back to the flickering
xrender backend); if it ever falls back, why is in `$XDG_RUNTIME_DIR/picom.log`.

## Window switcher

Hold Alt and tap Tab: the open windows come up as rounded cards on a ring, most recently used
first, and each Tab turns the ring to bring the next one to the front (Alt+Shift+Tab or Alt+←
turn it back); cards further round shrink, fade and turn away. Let go of Alt to switch to the front
one; Escape cancels, a click picks one. A quick Alt+Tab goes straight back to the last window
without showing the ring.

The shell's popup can't take the keyboard on X11, so i3's mode "switcher" sends the keys over IPC;
i3 can't see Alt let go (it was pressed before the mode began), so the shell runs
`desktop-key-release alt`, which asks X whether Alt is still held (nothing is grabbed). Cards show the
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

The login screen and the boot menu follow the wallpaper too. They can't read the home folder, so
`packages/system.sh sddm` and `grub` give you their background files (sddm's in
`/var/lib/desktop/sddm`, GRUB's `background.jpg` in its theme folder), and every wallpaper change
redraws them without sudo: sddm shows it as it is, GRUB blurred and dimmed in the theme's
background colour (so `theme set` redraws GRUB's too). `desktop-wallpaper screens` redraws both by
hand.

## Settings window

`$mod+Shift+s` (or `qs -c desktop ipc call settings toggle`): Bar (style, position, height,
opacity, island width, capsules, widgets dragged between the bar's parts), Appearance (theme and dark/light, through `theme`),
Notifications, Levels (volume/brightness steps, how long the level card stays) and Power; Escape
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
once. `desktop-timeshift list|create|delete` does the work.

`packages/system.sh timeshift` also sets what is kept: 3 daily snapshots, 1 weekly, and (with
`timeshift-autosnap`) the last 3 taken before a pacman upgrade. `packages/system.sh subvolumes`
makes the VM disks, `/var/lib/docker` and `~/.cache` btrfs subvolumes of their own, which
snapshots leave out (they change all day); the originals are kept beside them until you remove
them. `packages/cleanup.sh packages|docker|caches|all` makes room: the packages in
`packages/remove.txt` and orphans (never one the repo's lists install), unused Docker images,
build cache and unnamed volumes (never containers: a stopped one may hold a database's data), and old package caches.

## When idle

Settings → Power → **When idle**: the screen dims after 4 minutes alone (any key or movement brings
it back), locks after 5 and switches off after 10; each can be Never. On i3, `desktop-idle apply`
sets X's screensaver and DPMS timers to them; xss-lock runs `desktop-idle dim` when the screensaver
starts and locks when its cycle ends. Video players and browsers playing video hold the screensaver
off themselves. Locking keeps the laptop running; nothing suspends on its own.

## Night light

A warmer screen, through gammastep (X11 and Wayland alike): the control center's **Night light**
tile turns it on or off, Settings → Appearance sets how warm (3000–6000 K, 4000 K by default) and
an optional schedule (on by itself from 19:00 to 07:00 by default; switching it off during those
hours keeps it off until they end). It fades in and back out. `nightlight toggle` over IPC.

## Password prompts (polkit)

The shell is the session's polkit agent on i3: when an app asks for admin rights (pkexec,
Timeshift, a package manager's GUI), a small panel drops from the bar with what's asked and a
password field; Escape or Cancel declines, a wrong password shakes it and asks again.
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
| `$mod+Shift+c` | clipboard history |
| `$mod+Shift+v` | reload i3 (or sway) |
| `$mod+Shift+p` | wallpapers |
| `$mod+d`, `$mod+;`, `$mod+Shift+f`, `$mod+Shift+y` | the launcher: apps, emoji, files, themes |
| Alt+Tab (hold Alt) | window switcher |
| `$mod+Shift+/` (Super+?) | every key binding, in words (Settings → Keys) |
| `$mod+Escape` | keys to the VM (or anything nested) until pressed again; the bar shows "VM keys" |
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
`bar toggle`, `recorder toggle`, `notifications toggle|dnd|clear`, `settings toggle|page <bar|appearance|notifications|levels|power|timeshift|keys>`, `control toggle|open <page>|page <page>|close`, `clipboard toggle`, `wallpaper toggle|shuffle`, `launcher toggle <apps|emoji|files|themes>|close`, `switcher next|prev|commit|cancel|list`, `nightlight toggle`, `capture toggle|shot <region|window|screen>|record <region|window|screen>|stop`, `alarm stop|snooze`, `power open|toggle|close|next|prev|activate|pick <n>`,
`theme reload`.
