# dot-files (v2)

Fresh start: only the stock i3 config so far. Everything else gets written and tested here, in the test VM first (`vm/`, git-ignored).

```sh
cd ~/Dotfiles
stow .      # link into ~ (.stowrc sets --target=~ --no-folding)
stow -R .   # restow after adding or removing files
stow -D .   # unstow
```
