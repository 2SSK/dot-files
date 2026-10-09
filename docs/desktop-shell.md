# Desktop shell (Quickshell)

`qs -c desktop`, started by i3 (`.config/i3/conf.d/autostart.conf`). Sources: `.config/quickshell/desktop/`.
Colours come from the desktop theme (see [theme.md](theme.md)); settings from
`~/.config/desktop/shell.json`, stowed from the repo, which applies as soon as it's saved.

## Bar

| Setting (`bar.*`) | Values |
| --- | --- |
| `style` | `island` (a floating pill) or `static` (the whole edge, word labels and separators) |
| `position` | `top`, `bottom`; `left`/`right` on sway only (i3 docks only top or bottom, so X11 uses the top) |
| `size`, `opacity`, `length` | thickness in px, background opacity, the island's share of the edge (0 fits its content) |
| `left`, `center`, `right` | widgets: `launcher`, `workspaces`, `clock`, `stats`, `volume`, `brightness`, `battery`, `tray`, `recorder`, `power` |

Workspaces are dots: 1–5 always, the shown one a wide pill, used ones bright, empty ones faint.
Hidden with `$mod+Shift+b`, the bar comes back over the windows while the pointer is at its edge.

## Keys (i3)

| Key | Does |
| --- | --- |
| F1 / F2 / F3, media keys | mute, volume down, volume up |
| F4 / F5, brightness keys | brightness down, up |
| F6, mic-mute key | microphone mute |
| `$mod+F12` | start / stop screen recording (gpu-screen-recorder, into `~/Videos`) |
| `$mod+Shift+b` | hide / show the bar |
| `$mod+Escape` | power menu: arrows or 1–5 pick, Enter runs, Escape closes |

Each change shows in a card at the top right; Caps Lock and Num Lock show there by themselves.

## Power menu

Lock, Log Out, Lock & Suspend, Reboot, Shut Down; Log Out, Reboot and Shut Down take a second
press while `power.confirm` is on. Nothing hibernates.

- **Lock** runs `loginctl lock-session`; xss-lock starts `desktop-lock` (i3lock-color, blurred,
  in the theme). The laptop keeps running.
- **Closing the lid** only locks, after `packages/system.sh lid` (logind `HandleLidSwitch=lock`),
  so work carries on with the lid shut. On battery it keeps draining.
- **Lock & Suspend** sleeps; xss-lock locks first.

## IPC

`qs -c desktop ipc call <target> <function>`: `audio up|down|mute|mic`, `brightness up|down`,
`bar toggle`, `recorder toggle`, `power open|toggle|close|next|prev|activate|pick <n>`,
`theme reload`.
