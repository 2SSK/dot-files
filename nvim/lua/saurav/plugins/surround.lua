return {
  "kylechui/nvim-surround",
  event = { "BufReadPre", "BufNewFile" },
  version = "*", -- Use for stability; omit to use `main` branch for the latest features
  config = true,
}

--     Old text                    Command         New text
-- --------------------------------------------------------------------------------
--     surr*ound_words             ysiw)           (surround_words)
--     *make strings               ys$"            "make strings"
--     delete ar*ound me!        ds]             delete around me!
--     remove <b>HTML t*ags</b>    dst             remove HTML tags
--     "change quot*es"            cs'"            "change quotes"
--     <h1>or tag* types</h1>        csth1<CR>       <h1>or tag types</h1>
--     functi*on calls     dsf             function calls
