# git

Config: `~/.config/git/config` (tracked), with the commit template and global ignore
next to it. Diffs go through [delta](https://github.com/dandavison/delta) with syntax
highlighting in the terminal's ANSI colours, so they follow the central theme.

## Untracked, per machine

| File | Holds |
| --- | --- |
| `~/.config/git/local.gitconfig` | Default `[user]`, `credential.helper`, internal hosts |
| `~/.config/git/personal.gitconfig` | `[user]` for repos under `~/Code/` |
| `~/.config/git/work.gitconfig` | `[user]` for repos under `~/Work/` |

Missing files are ignored, so a fresh machine works before they exist.

## Highlights

- `pull.rebase`, `rebase.autoStash`, `rerere`, `merge.conflictstyle = zdiff3`
- `push.autoSetupRemote`: the first `git push` sets the upstream
- Short status with branch and stash; moved lines coloured in diffs
- `gh:user/repo` expands to GitHub over HTTPS; `ghp:` / `ghw:` to the personal and work
  SSH host aliases; `git fix-remote-personal` / `fix-remote-work` rewrite `origin`
- delta: `n` / `N` jump between files in `git diff` and `git log -p`
