" desktop: the desktop theme's colours, built from its palette (~/.local/state/desktop/theme/
" palette.json) when loaded; transparent backgrounds. ~/.vimrc loads it, and again when the
" theme changes.
let s:file = (empty($XDG_STATE_HOME) ? $HOME . '/.local/state' : $XDG_STATE_HOME) . '/desktop/theme/palette.json'
let s:palette = json_decode(join(readfile(s:file), "\n"))
let s:colour = extend(copy(s:palette.ui), s:palette.ansi) " roles (fg, primary, ...) and c0-c15

execute 'set background=' . s:palette.mode
highlight clear
if exists('syntax_on') | syntax reset | endif
let g:colors_name = 'desktop'

" each group, its $role standing for that colour
for s:spec in [
\ 'Normal       guifg=$fg guibg=NONE',
\ 'NonText      guifg=$overlay guibg=NONE',
\ 'EndOfBuffer  guifg=$bg guibg=NONE',
\ 'LineNr       guifg=$overlay guibg=NONE',
\ 'CursorLineNr guifg=$primary guibg=NONE gui=bold',
\ 'SignColumn   guibg=NONE',
\ 'FoldColumn   guifg=$overlay guibg=NONE',
\ 'Folded       guifg=$fg_muted guibg=$surface',
\ 'CursorLine   guibg=$surface gui=NONE cterm=NONE',
\ 'CursorColumn guibg=$surface',
\ 'ColorColumn  guibg=$surface',
\ 'Visual       guibg=$selection',
\ 'Search       guifg=$on_primary guibg=$warning',
\ 'IncSearch    guifg=$on_primary guibg=$accent',
\ 'CurSearch    guifg=$on_primary guibg=$accent',
\ 'MatchParen   guifg=$accent guibg=NONE gui=bold',
\ 'VertSplit    guifg=$border guibg=NONE gui=NONE',
\ 'WinSeparator guifg=$border guibg=NONE',
\ 'StatusLine   guifg=$fg guibg=$surface gui=NONE',
\ 'StatusLineNC guifg=$fg_muted guibg=NONE gui=NONE',
\ 'TabLine      guifg=$fg_muted guibg=NONE gui=NONE',
\ 'TabLineFill  guibg=NONE gui=NONE',
\ 'TabLineSel   guifg=$primary guibg=NONE gui=bold',
\ 'Pmenu        guifg=$fg guibg=$surface',
\ 'PmenuSel     guifg=$on_primary guibg=$primary',
\ 'PmenuSbar    guibg=$surface',
\ 'PmenuThumb   guibg=$overlay',
\ 'WildMenu     guifg=$on_primary guibg=$primary',
\ 'Directory    guifg=$primary',
\ 'Title        guifg=$primary gui=bold',
\ 'ErrorMsg     guifg=$error guibg=NONE',
\ 'WarningMsg   guifg=$warning',
\ 'ModeMsg      guifg=$success gui=bold',
\ 'MoreMsg      guifg=$success',
\ 'Question     guifg=$primary',
\ 'SpecialKey   guifg=$overlay',
\ 'DiffAdd      guifg=$success guibg=NONE',
\ 'DiffChange   guifg=$warning guibg=NONE',
\ 'DiffDelete   guifg=$error guibg=NONE',
\ 'DiffText     guifg=$primary guibg=NONE gui=bold',
\ 'SpellBad     gui=undercurl guisp=$error',
\ 'SpellCap     gui=undercurl guisp=$warning',
\ 'Comment      guifg=$fg_muted gui=italic',
\ 'Constant     guifg=$accent',
\ 'String       guifg=$success',
\ 'Character    guifg=$success',
\ 'Number       guifg=$accent',
\ 'Boolean      guifg=$accent',
\ 'Identifier   guifg=$c6 gui=NONE',
\ 'Function     guifg=$primary',
\ 'Statement    guifg=$secondary gui=NONE',
\ 'Operator     guifg=$c6',
\ 'PreProc      guifg=$secondary',
\ 'Type         guifg=$warning gui=NONE',
\ 'Special      guifg=$c6',
\ 'Delimiter    guifg=$fg_muted',
\ 'Underlined   guifg=$primary gui=underline',
\ 'Error        guifg=$error guibg=NONE',
\ 'Todo         guifg=$on_primary guibg=$warning gui=bold'
\ ]
	execute 'highlight' substitute(s:spec, '\$\(\w\+\)', '\=s:colour[submatch(1)]', 'g')
endfor
