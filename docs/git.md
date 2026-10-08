# git

Config: `~/.config/git/config` (tracked), with the commit template and global ignore next
to it. Colours for git and for [delta](https://github.com/dandavison/delta), which renders
diffs, come from the desktop theme (`~/.local/state/desktop/theme/git.conf`).

Identity and anything machine-specific (`[user]`, `credential.helper`, internal hosts) go
in the untracked `~/.config/git/local.gitconfig`; git works before it exists.

## Highlights

- `pull.rebase`, `rebase.autoStash`, `rerere`, `merge.conflictstyle = zdiff3`
- `push.autoSetupRemote`: the first `git push` sets the upstream
- Short status with branch and stash; moved lines coloured in diffs
- Commit template lists the conventional types (`feat`, `fix`, `docs`, …)
- delta: line numbers; `n` / `N` jump between files in `git diff` and `git log -p`
