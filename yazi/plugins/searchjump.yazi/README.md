# searchjump.yazi

A Yazi plugin which the behavior consistent with flash.nvim in Neovim, allow search str to generate lable to jump.support chinese pinyin search,regular expression search.



## english search
https://gitee.com/DreamMaoMao/searchjump.yazi/assets/30348075/eec237c9-91be-4b6e-9db8-a84eb419cae5

## chiese pinyin search(first character of a word pinyin)
https://gitee.com/DreamMaoMao/searchjump.yazi/assets/30348075/8acf8316-c8d4-497d-af5a-7d85924c57a2

## regular expression search(set patterns in option `search_patterns`)
- for example:
```lua
search_patterns = {"%.e%d+","s%d+e%d+","%d+.1080p","第%d+集"}
```

https://gitee.com/DreamMaoMao/searchjump.yazi/assets/30348075/a68bd599-04c6-467a-a987-53a6684529af


> [!NOTE]
> The latest main branch of Yazi is required at the moment.


## Install

### Linux

```bash
git clone https://gitee.com/DreamMaoMao/searchjump.yazi.git ~/.config/yazi/plugins/searchjump.yazi
```

### Windows

With `Powershell` :

```powershell
if (!(Test-Path $env:APPDATA\yazi\config\plugins\)) {mkdir $env:APPDATA\yazi\config\plugins\}
git clone https://gitee.com/DreamMaoMao/searchjump.yazi.git $env:APPDATA\yazi\config\plugins\searchjump.yazi
```

## Usage

set shortcut key to toggle searchjump mode in `~/.config/yazi/keymap.toml`. for example set `i` to toggle searchjump mode

```toml
[[manager.prepend_keymap]]
on   = [ "i" ]
run = "plugin searchjump"
desc = "searchjump mode"


[[manager.prepend_keymap]]
on   = [ "i" ]
run = "plugin searchjump --args='autocd'"
desc = "searchjump mode(auto cd select folder)"
```

## opts setting (~/.config/yazi/init.lua)
```lua
require("searchjump"):setup {
	unmatch_fg = "#b2a496",
    match_str_fg = "#000000",
    match_str_bg = "#73AC3A",
    first_match_str_fg = "#000000",
    first_match_str_bg = "#73AC3A",
    lable_fg = "#EADFC8",
    lable_bg = "#BA603D",
    only_current = false, -- only search the current window
    show_search_in_statusbar = false,
    auto_exit_when_unmatch = false,
    enable_capital_lable = false,
    search_patterns = {}  -- demo:{"%.e%d+","s%d+e%d+"}
}
```

When you see some character singal lable in right of the entry.
Press the key of the character will jump to the corresponding entry.
if you want to search chiese,for example,search `你好`,you can press `n` or `nh`
 to search.


## It is worth noting

- the `<Space>` key is a special key when you are in sj mode,it will toggle search regular expression that set in search_patterns.

-  the re match is case insensitive whether you use uppercase or lowercase in your regular expression

- the `<Enter>` key will jump to the first match result or only result.

- the `<Backspace>` key will backout the last key you input.
