# dot-files

Work happens on `main` in `~/dot-files`, stowed into `~`, tested in the VM first (`vm/`, git-ignored) for anything that could break a session. With `git config core.hooksPath .githooks`, each commit drops links to deleted files and restows (`.githooks/post-commit`).

```sh
cd ~/dot-files
stow .      # link into ~ (.stowrc sets --target=~ --no-folding)
stow -R .   # restow after adding or removing files
stow -D .   # unstow
```
