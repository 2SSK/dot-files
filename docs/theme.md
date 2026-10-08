# Theme

One central theme drives every app. Selecting a theme renders it once into
`~/.local/state/desktop/theme/`, and everything reads from there.

```sh
theme list                          # families; * marks the current one
theme current                       # e.g. "tokyonight dark"
theme set catppuccin                # switch family, keep the mode
theme set gruvbox --mode light      # switch family and mode
theme mode toggle                   # dark ⇄ light (also: mode dark|light)
```

## Families

| Family | Dark | Light |
| --- | --- | --- |
| tokyonight *(default)* | night | day |
| catppuccin | mocha | latte |
| gruvbox | dark | light |
| rosepine | main | dawn |
| eink | near-white ink on charcoal | near-black ink on warm paper; for black-and-white wallpapers |
| kanagawa | wave | lotus |
| kesari | inspired by Rajput art; a miniature at night: indigo ink, gold leaf, vermilion, peacock | Indian watercolour on handmade paper |

Palette values are copied from each project's official ports, with attribution in
`~/.local/share/desktop/themes/<family>.toml`. Every variant passes WCAG AA contrast
(text 4.5:1, muted text 3:1); the renderer refuses one that doesn't.

## How apps follow it

| App | How | When it updates |
| --- | --- | --- |
| kitty | `include` of the rendered `kitty.conf` | Live (SIGUSR1) |
| foot | `include` of the rendered `foot.ini` with dark and light variants | Mode live (SIGUSR1/2); family in new windows |
| st | `~/.Xresources` includes the rendered `st.Xresources`; `xrdb -merge` + SIGUSR1 (reload patch) | Live on X11 |
| tmux | `source-file` of the rendered `tmux.conf` | Live (re-sourced) |
| git, delta | `[include]` of the rendered `git.conf` | Next command |
| lazygit | `LG_CONFIG_FILE` merges the rendered `lazygit.yml` | Next start |
| lazydocker | `lazydocker` alias sets `CONFIG_DIR` to the rendered `lazydocker/` | Next start |
| starship, fzf, zsh autosuggestions, `ls`, bat, btop, yazi, fastfetch, pgcli | The terminal's 16 ANSI colours | With the terminal |
| cava | `cava` alias loads the rendered config (gradient from the ANSI colours) | Live (SIGUSR2) |
| i3 window borders | `include` of the rendered `i3.conf` | Live (`i3-msg reload`) |
| picom (i3): shadow colours | Started with the rendered `picom.conf` | Live (SIGUSR1) |
| GTK theme, icons, cursor, fonts | X11: xsettingsd reads the rendered `xsettingsd.conf`; Wayland: `gsettings` (org.gnome.desktop.interface). adw-gtk3, Tela-circle-blue dark/light, Bibata-Modern-Ice, Inter / JetBrains Mono | Live |
| GTK 3 | adw-gtk3 (dark or light) with its named colours from the rendered `gtk-3.0.css` (`~/.config/gtk-3.0/gtk.css` links to it) | Dark/light live; colours on app restart |
| GTK 4 / libadwaita | libadwaita's CSS variables in the rendered `gtk-4.0.css` (`~/.config/gtk-4.0/gtk.css` links to it); `gsettings` color-scheme | Dark/light live; colours on app restart |
| Qt 5 / Qt 6 | `QT_QPA_PLATFORMTHEME=qt5ct` (qt6ct answers to it too); `~/.config/qt{5,6}ct/qt{5,6}ct.conf` link to rendered configs: Fusion, the rendered `qt-colors.conf`, Tela icons, Inter | On app restart |
| Quickshell, sway borders | `palette.json` and further templates | Coming in later stages |

## How a switch works

`theme` renders every file in `~/.local/share/desktop/templates/` into a fresh directory, then swaps
`~/.local/state/desktop/theme` (a symlink) to it in one step, so apps see the old theme or the new
one, never a mix. A request identical to the current theme (same palette, templates and mode) keeps
the current render. Then every app in the table at the top of `~/.local/bin/theme` reloads, all at
once; apps that only read a fixed path under `~/.config` get a link to their rendered file.

**Adding an app:** a template in `templates/`, and a row in that table (rendered file, link or `-`,
reload command or `-`).

## Files

| Path | Contents |
| --- | --- |
| `~/.local/share/desktop/themes/<family>.toml` | Source palettes: semantic UI roles and 16 ANSI colours per mode |
| `~/.local/share/desktop/templates/` | One template per rendered target |
| `~/.local/state/desktop/theme/current` | `family=` and `mode=` of the active theme |
| `~/.local/state/desktop/theme/palette.json` | Active variant for apps that read JSON |
| `~/.local/state/desktop/theme/` `kitty.conf`, `foot.ini`, `i3.conf`, `picom.conf`, `xsettingsd.conf`, `st.Xresources`, `cava`, `tmux.conf`, `git.conf`, `lazygit.yml`, `lazydocker/`, `pspg/`, `rmpc.ron`, `nvim.lua`, `vim.vim`, `silicon.tmTheme` | Rendered configs |

## Fonts

fontconfig maps `sans-serif` to **Inter** for interface text and `monospace` to
**JetBrainsMono Nerd Font** for terminals and code, with Noto Color Emoji as fallback.

## Terminals

kitty is the main terminal on both sessions. The backups are foot on Wayland and st on X11;
st is built from the pinned 0.9.3 release with the
[xresources-with-reload-signal](https://st.suckless.org/patches/xresources-with-reload-signal/)
patch (`packages/extra/st.sh`), and reads its font, padding and colours from `~/.Xresources`.

## Boot menu (GRUB)

`packages/system.sh grub` (sudo) installs a minimal GRUB theme built from the active palette:
the theme's background colour, a centred column of entries in Inter, the selected one on a
rounded pill, and one hint line with the countdown. It sets `GRUB_THEME` and graphical output
in `/etc/default/grub` (the original is kept as `grub.pre-desktop`; a serial console is left
alone) and regenerates `grub.cfg` (`grub-mkconfig`, `update-grub` or `grub2-mkconfig`).
GRUB can't follow the theme live: run it again after `theme set` to update the colours.

## GTK and Qt

`theme` links the fixed paths GTK and qt5ct/qt6ct read to the rendered files. An existing file there
that isn't one of these links is moved to `~/.local/state/desktop/backup/theme/` first, never deleted.
Don't save settings from the qt5ct/qt6ct windows: they would write into the rendered file, and the
next `theme` overwrites it. Change the templates instead.
