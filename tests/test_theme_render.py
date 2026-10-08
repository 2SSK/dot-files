"""theme_render.py: palette lint, rendering, the atomic switch, and golden output.

Goldens hold one variant (tokyonight dark) of every template; every other variant must render too.
Run: python3 -m unittest discover -s tests
Refresh goldens after an intended change: UPDATE_GOLDEN=1 python3 -m unittest discover -s tests
"""

import json
import os
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / ".local/lib/desktop"))
import theme_render as tr  # noqa: E402

GOLDEN = REPO / "tests/golden/theme/tokyonight-dark"
FAMILIES = sorted(p.stem for p in tr.THEMES.glob("*.toml"))


class Contrast(unittest.TestCase):
    def test_black_on_white_is_21(self):
        self.assertAlmostEqual(tr.contrast("#000000", "#ffffff"), 21.0, places=2)

    def test_same_colour_is_1(self):
        self.assertAlmostEqual(tr.contrast("#7aa2f7", "#7aa2f7"), 1.0)


class Lint(unittest.TestCase):
    def test_shipped_themes_pass(self):
        self.assertEqual(FAMILIES, ["catppuccin", "eink", "gruvbox", "kanagawa", "kesari", "nord", "rosepine",
                                    "tokyonight"])
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
        self.state = Path(tempfile.mkdtemp()) / "theme"

    def test_writes_state_files(self):
        tr.render("catppuccin", "light", self.state)
        self.assertEqual((self.state / "current").read_text(), "family=catppuccin\nmode=light\n")
        palette = json.loads((self.state / "palette.json").read_text())
        self.assertEqual(palette["meta"]["family"], "catppuccin")
        self.assertEqual(palette["mode"], "light")
        self.assertEqual(palette["ui"]["bg"], "#eff1f5")
        self.assertEqual(len(palette["ansi"]), 16)
        # every template (top-level name), the palette and the marker; nothing else
        expected = {t.split("/")[0] for t in tr.targets()} | {"palette.json", "current", ".fingerprint"}
        self.assertEqual(sorted(p.name for p in self.state.iterdir()), sorted(expected))

    def test_templates_dir_is_the_target_list(self):
        self.assertIn("kitty.conf", tr.targets())
        self.assertIn("pspg/.pspg_theme_desktop", tr.targets())  # hidden and nested files count too
        self.assertEqual(len(tr.targets()), sum(1 for p in tr.TEMPLATES.rglob("*") if p.is_file()))

    def test_switch_is_one_symlink_swap_and_old_renders_go(self):
        tr.render("tokyonight", "dark", self.state)
        first = self.state.resolve()
        (self.state / "btop.theme").write_text("stale")  # an output no template makes any more
        tr.render("gruvbox", "light", self.state)
        self.assertTrue(self.state.is_symlink())
        self.assertNotEqual(self.state.resolve(), first)
        self.assertFalse(first.exists())
        self.assertFalse((self.state / "btop.theme").exists())
        siblings = [p.name for p in self.state.parent.iterdir() if p.is_dir() and not p.is_symlink()]
        self.assertEqual(siblings, [self.state.resolve().name])  # only the live render remains

    def test_an_unchanged_request_keeps_the_current_render(self):
        tr.render("rosepine", "dark", self.state)
        live = self.state.resolve()
        tr.render("rosepine", "dark", self.state)
        self.assertEqual(self.state.resolve(), live)  # nothing re-rendered
        tr.render("rosepine", "light", self.state)
        self.assertNotEqual(self.state.resolve(), live)

    def test_a_plain_state_directory_from_before_is_replaced(self):
        self.state.mkdir(parents=True)
        (self.state / "kitty.conf").write_text("old")
        tr.render("tokyonight", "dark", self.state)
        self.assertTrue(self.state.is_symlink())
        self.assertNotEqual((self.state / "kitty.conf").read_text(), "old")

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
        tr.render("tokyonight", "dark", self.state)
        for name in tr.targets():
            with self.subTest(target=name):
                got = (self.state / name).read_text().replace(str(self.state), "<state>")
                golden = GOLDEN / name.replace("/", "-")
                if os.environ.get("UPDATE_GOLDEN"):
                    golden.parent.mkdir(parents=True, exist_ok=True)
                    golden.write_text(got)
                self.assertEqual(got, golden.read_text(), f"{golden} differs")
        stale = {p.name for p in GOLDEN.iterdir()} - {t.replace("/", "-") for t in tr.targets()}
        self.assertEqual(stale, set(), "goldens of templates that no longer exist")

    def test_every_variant_renders(self):
        for family in FAMILIES:
            for mode in tr.MODES:
                with self.subTest(family=family, mode=mode):
                    tr.render(family, mode, self.state)  # a missing placeholder raises KeyError
                    self.assertEqual((self.state / "current").read_text(), f"family={family}\nmode={mode}\n")


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
        self.assertTrue((Path(state) / "desktop/theme").is_symlink())


if __name__ == "__main__":
    unittest.main()
