# Music

```sh
music          # pick a folder in ~/Music, it plays shuffled and the player opens
music 90s      # play a folder straight away
```

[mpd](https://www.musicpd.org) plays through PipeWire as a systemd user service, so music
keeps playing after you quit the player. [rmpc](https://mierak.github.io/rmpc/) is the
player, laid out after Seth Phaeno's [video](https://www.youtube.com/watch?v=iGW0EpsUb7E):
five tabs, the queue beside the album art, and yazi-style folder browsing (`h`/`l`). Colours
come from the desktop theme (applied the next time it starts). `mpc` controls mpd from the shell and
[mpd-mpris](https://github.com/natsukagami/mpd-mpris) hands it to media keys, `playerctl`
and the bar.

A folder is a playlist: drop music into `~/Music/<name>/` and it appears in the picker.

## rmpc keys

| Key | Action |
| --- | --- |
| `1`–`5` / `F` | Queue (with album art), Playlists, Library, Artists, Search / Search |
| `Tab` / `Shift+Tab` | Next / previous tab |
| `p` / `s` | Play or pause / stop |
| `>` / `<` | Next / previous track |
| `f` / `b` | Seek forward / back |
| `.` / `,` | Volume up / down |
| `z` `x` `c` `v` | Toggle repeat, random, consume, single |
| `j` `k`, `h` `l` | Move down / up, leave / enter a folder |
| `gg` / `G`, `Ctrl+d` / `Ctrl+b` / `Ctrl+f` | Top / bottom, half page down / page up / page down |
| `/` then `n` / `N` | Find in the list, next / previous match |
| `Enter` | Play the track (Queue) or open the item |
| `a` / `A` | Add the item / everything shown to the queue |
| `Space` | Select; `J` / `K` move the selection |
| `d` / `D` | Remove from the queue / clear the queue |
| `X` / `C` | Shuffle the queue / jump to the playing track |
| `R` | Add random songs |
| `Ctrl+s` `s` | Save the queue as a playlist |
| `Ctrl+z` | Menu for the item (e.g. add a track to a playlist) |
| `Ctrl+u` | Refresh the library after adding music |
| `?` | All keys |
| `q` | Quit (mpd keeps playing) |

## Files

| Path | Contents |
| --- | --- |
| `~/.config/mpd/mpd.conf` | Library `~/Music`, PipeWire output |
| `~/.local/state/mpd/` | Database, playback state |
| `~/.config/rmpc/config.ron` | Tabs and keys |
| `~/.local/state/desktop/theme/rmpc.ron` | Colours, rendered from the palette |

## Spotify

The Spotify app (AUR `spotify`) starts without ads from every launcher: `~/.local/share/applications/spotify.desktop`
preloads [spotify-adblock](https://github.com/abba23/spotify-adblock), which blocks the ad servers
without patching Spotify, so updates don't break it (unlike spicetify, which `packages/cleanup.sh`
removes). Its block and allow lists are in `/etc/spotify-adblock/config.toml`.
