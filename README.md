# dot-files

Work happens on the `rewrite` branch (worktree `~/dev/dot-files-rewrite`), tested in the VM first (`vm/`, git-ignored). The live desktop runs `main` from `~/dot-files`, stowed into `~`. The two stay in step: with `git config core.hooksPath .githooks`, each commit on `rewrite` fast-forwards `main` there, drops links to deleted files and restows (`.githooks/post-commit`; if `main` has diverged or a local change is in the way, it says so and leaves `main` alone).

```sh
cd ~/dot-files
stow .      # link into ~ (.stowrc sets --target=~ --no-folding)
stow -R .   # restow after adding or removing files
stow -D .   # unstow
```
