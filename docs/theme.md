# Theme

One central theme drives every app. Selecting a theme renders it once into
`~/.local/state/desktop/theme/`, and everything reads from there.

```sh
desktop-theme list                          # families; * marks the current one
desktop-theme current                       # e.g. "tokyonight dark"
desktop-theme set catppuccin                # switch family, keep the mode
desktop-theme set gruvbox --mode light      # switch family and mode
desktop-theme mode toggle                   # dark ⇄ light (also: mode dark|light)
```

## Families

| Family | Dark | Light |
| --- | --- | --- |
| tokyonight *(default)* | night | day |
| catppuccin | mocha | latte |
| gruvbox | dark | light |
| rose-pine | main | dawn |

Palette values are copied from each project's official ports, with attribution in
`~/.local/share/desktop/themes/<family>.toml`. Every variant passes WCAG AA contrast
(text 4.5:1, muted text 3:1); the renderer refuses one that doesn't.

## How apps follow it

| App | How | When it updates |
| --- | --- | --- |
| kitty | `include` of the rendered `kitty.conf` | Live (SIGUSR1) |
| foot | `include` of the rendered `foot.ini` with dark and light variants | Mode live (SIGUSR1/2); family in new windows |
| starship, fzf, zsh autosuggestions, `ls`, bat, btop | The terminal's 16 ANSI colours | With the terminal |
| Quickshell, WM borders, GTK, Qt, nvim | `palette.json` and further templates | Coming in later stages |

## Files

| Path | Contents |
| --- | --- |
| `~/.local/share/desktop/themes/<family>.toml` | Source palettes: semantic UI roles and 16 ANSI colours per mode |
| `~/.local/share/desktop/templates/` | One template per rendered target |
| `~/.local/state/desktop/theme/current` | `family=` and `mode=` of the active theme |
| `~/.local/state/desktop/theme/palette.json` | Active variant for apps that read JSON |
| `~/.local/state/desktop/theme/kitty.conf`, `foot.ini` | Rendered terminal colours |

## Fonts

fontconfig maps `sans-serif` to **Inter** for interface text and `monospace` to
**JetBrainsMono Nerd Font** for terminals and code, with Noto Color Emoji as fallback.
