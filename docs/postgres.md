# Postgres clients

psql and pgcli, both with results in [pspg](https://github.com/okbob/pspg), a pager for tables
whose colours come from the desktop theme.

| Path | Purpose |
| --- | --- |
| `~/.psqlrc` | Quiet start, unicode borders, `⟨NULL⟩`, timing, coloured prompt, history without duplicates |
| `~/.config/pgcli/config` | vi mode, psql-style multi-line, unicode tables, pspg, warnings before destructive queries |
| `~/.local/state/desktop/theme/pspg/` | pspg settings and theme (`PSPG_CONF`, rendered by `theme`) |
| `~/.local/state/pgcli/` | pgcli history and log |

## Connecting

```bash
psql demo                                   # local socket, your user
psql -h host -p 5432 -U user dbname
pgcli postgres://user@host:5432/dbname
```

### To a VM

From inside the VM both work as above. From the laptop, forward the port over SSH (in the
background; "Connection refused" on the local port means no tunnel is running):

```bash
ssh -fN -L 5433:localhost:5432 user@<vm-ip>
pgcli postgres://user@localhost:5433/dbname
pkill -f 'L 5433:localhost'    # close the tunnel
```

Through the tunnel Postgres sees a TCP connection, so the role needs a password
(`ALTER ROLE user PASSWORD '…'`); socket logins inside the VM don't.

## Keys

| psql | |
| --- | --- |
| `\e` | Edit the query in nvim; save and quit runs it |
| `\x` | Toggle expanded rows (auto by default) |
| `\dt`, `\d table`, `\l`, `\dn` | Tables, a table's columns, databases, schemas |

| pgcli | |
| --- | --- |
| `Esc` / `i` | vi normal / insert mode |
| `Tab` | Completion (tables, columns, keywords, aware of the query) |
| `F2` / `F3` / `F4` | Smart completion / multi-line / vi mode on or off |
| `\e` | Edit the query in nvim |

| pspg | |
| --- | --- |
| `h/j/k/l`, arrows | Move; `g` / `G` first / last row |
| `PgUp` / `PgDn`, `Space` | Page |
| `/` / `?`, `n` / `N` | Search forward / backward, next / previous match |
| `0`–`4` | Freeze the first columns while scrolling sideways |
| `F9` | Menu (save, copy, themes) |
| `q` | Quit back to the prompt |
