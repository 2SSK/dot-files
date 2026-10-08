# Music

[mpd](https://www.musicpd.org) plays `~/Music` through PipeWire as a systemd user
service, so music keeps playing after the terminal closes. [rmpc](https://mierak.github.io/rmpc/)
is the interface (`music`), laid out after Seth Phaeno's
[video](https://www.youtube.com/watch?v=iGW0EpsUb7E); `mpc` controls mpd from the shell and
[mpd-mpris](https://github.com/natsukagami/mpd-mpris) hands it to media keys, `playerctl`
and the bar. rmpc's colours come from the desktop theme (applied the next time it starts).

## Playlists

```sh
mkplaylist 90s            # save ~/Music/90s as the playlist "90s"
music                     # 2 → Playlists, select 90s, a adds it to the queue
mpc load 90s && mpc random on && mpc play   # or straight from the shell
```

Folders also show up in the Library tab, so any folder can be queued directly.

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
| `~/.local/share/mpd/playlists/` | Saved playlists (`.m3u`) |
| `~/.local/state/mpd/` | Database, playback state |
| `~/.config/rmpc/config.ron` | Tabs and keys |
| `~/.local/state/desktop/theme/rmpc.ron` | Colours, rendered from the palette |
