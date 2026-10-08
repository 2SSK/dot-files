"""theme_render.py: palette lint, rendering and golden output for every shipped variant.

Run: python3 -m unittest discover -s tests
Refresh goldens after an intended change: UPDATE_GOLDEN=1 python3 -m unittest discover -s tests
"""

import json
import os
import re
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / ".local/lib/desktop"))
import theme_render as tr  # noqa: E402

GOLDEN = REPO / "tests/golden/theme"
FAMILIES = sorted(p.stem for p in tr.THEMES.glob("*.toml"))


class Contrast(unittest.TestCase):
    def test_black_on_white_is_21(self):
        self.assertAlmostEqual(tr.contrast("#000000", "#ffffff"), 21.0, places=2)

    def test_same_colour_is_1(self):
        self.assertAlmostEqual(tr.contrast("#7aa2f7", "#7aa2f7"), 1.0)


class Lint(unittest.TestCase):
    def test_shipped_themes_pass(self):
        self.assertEqual(FAMILIES, ["catppuccin", "eink", "gruvbox", "rosepine", "tokyonight"])
        for family in FAMILIES:
            with self.subTest(family=family):
                self.assertEqual(tr.lint(tr.load(family)), [])

    def test_low_contrast_is_reported(self):
        theme = tr.load("tokyonight")
        theme["dark"]["ui"]["fg_muted"] = theme["dark"]["ui"]["bg"]
        problems = tr.lint(theme)
        self.assertEqual(len(problems), 1)
        self.assertIn("dark fg_muted", problems[0])

    def test_missing_role_is_reported(self):
        theme = tr.load("tokyonight")
        del theme["light"]["ui"]["accent"]
        self.assertTrue(any("light.ui missing accent" in p for p in tr.lint(theme)))


class Render(unittest.TestCase):
    def setUp(self):
        self.state = Path(tempfile.mkdtemp())

    def test_writes_state_files(self):
        tr.render("catppuccin", "light", self.state)
        self.assertEqual((self.state / "current").read_text(), "family=catppuccin\nmode=light\n")
        palette = json.loads((self.state / "palette.json").read_text())
        self.assertEqual(palette["meta"]["family"], "catppuccin")
        self.assertEqual(palette["mode"], "light")
        self.assertEqual(palette["ui"]["bg"], "#eff1f5")
        self.assertEqual(len(palette["ansi"]), 16)
        self.assertEqual(sorted(p.name for p in self.state.iterdir()),
                         ["cava", "current", "foot.ini", "git.conf", "i3.conf", "kitty.conf", "lazydocker", "lazygit.yml",
                          "nvim.lua", "opencode", "palette.json", "picom", "picom.conf", "pspg", "rmpc.ron", "silicon.tmTheme",
                          "st.Xresources", "tmux.conf", "vim.vim", "xsettingsd.conf"])

    def test_removes_outputs_of_dropped_targets(self):
        self.state.mkdir(parents=True, exist_ok=True)
        (self.state / "btop.theme").write_text("stale")
        tr.render("tokyonight", "dark", self.state)
        self.assertFalse((self.state / "btop.theme").exists())

    def test_nvim_gets_the_palette_as_base16(self):
        tr.render("rosepine", "light", self.state)
        nvim = (self.state / "nvim.lua").read_text()
        self.assertIn('background = "light"', nvim)
        self.assertIn('base00 = "#faf4ed"', nvim)  # rose-pine dawn bg
        self.assertNotIn("$", nvim)

    def test_silicon_gets_a_code_theme_from_the_palette(self):
        tr.render("gruvbox", "dark", self.state)
        theme = (self.state / "silicon.tmTheme").read_text()
        self.assertIn("<string>#282828</string>", theme)  # gruvbox dark bg
        self.assertIn("<string>comment</string>", theme)

    def test_vim_gets_a_transparent_colourscheme(self):
        tr.render("tokyonight", "dark", self.state)
        vim = (self.state / "vim.vim").read_text()
        self.assertIn("hi Normal       guifg=#c0caf5 guibg=NONE", vim)
        self.assertIn("hi LineNr       guifg=#3b4261 guibg=NONE", vim)

    def test_opencode_gets_a_transparent_theme(self):
        tr.render("gruvbox", "dark", self.state)
        theme = json.loads((self.state / "opencode/themes/desktop.json").read_text())
        self.assertEqual(theme["theme"]["background"], "none")
        self.assertEqual(theme["theme"]["text"], "#ebdbb2")

    def test_unknown_family_or_mode(self):
        with self.assertRaises(tr.ThemeError):
            tr.render("nope", "dark", self.state)
        with self.assertRaises(tr.ThemeError):
            tr.render("tokyonight", "dim", self.state)

    def test_golden_output(self):
        for family in FAMILIES:
            for mode in tr.MODES:
                with self.subTest(family=family, mode=mode):
                    state = Path(tempfile.mkdtemp())
                    tr.render(family, mode, state)
                    for name in tr.TARGETS:
                        got = (state / name).read_text()
                        golden = GOLDEN / f"{family}-{mode}" / name.replace("/", "-")
                        if os.environ.get("UPDATE_GOLDEN"):
                            golden.parent.mkdir(parents=True, exist_ok=True)
                            golden.write_text(got)
                        self.assertEqual(got, golden.read_text(), f"{golden} differs")
                        names = "|".join(tr.variables(tr.load(family), family, mode))
                        self.assertIsNone(re.search(rf"\$({names})\b", got), "unfilled template placeholder")


class Cli(unittest.TestCase):
    def run_cli(self, *args, **env):
        return subprocess.run([sys.executable, str(REPO / ".local/lib/desktop/theme_render.py"), *args],
                              capture_output=True, text=True, env={**os.environ, **env})

    def test_lint_exits_0(self):
        self.assertEqual(self.run_cli("lint").returncode, 0)

    def test_usage_exits_2(self):
        self.assertEqual(self.run_cli("bogus").returncode, 2)

    def test_render_to_xdg_state(self):
        state = tempfile.mkdtemp()
        result = self.run_cli("render", "gruvbox", "dark", XDG_STATE_HOME=state)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue((Path(state) / "desktop/theme/kitty.conf").is_file())


if __name__ == "__main__":
    unittest.main()
