#!/usr/bin/env python3
"""Render a theme family/mode into ~/.local/state/desktop/theme (PRD §6.5).

usage: theme_render.py render <family> <dark|light>
       theme_render.py lint [family...]

Standard library only. Every output is written atomically, so readers never see a partial file.
"""

import json
import os
import sys
import tempfile
import tomllib
from pathlib import Path
from string import Template

SHARE = Path(__file__).resolve().parents[2] / "share/desktop"
THEMES = SHARE / "themes"
TEMPLATES = SHARE / "templates"
MODES = ("dark", "light")
ROLES = ("bg", "bg_alt", "surface", "overlay", "fg", "fg_muted", "primary", "on_primary", "secondary",
         "accent", "success", "warning", "error", "border", "border_active", "selection")
ANSI = tuple(f"c{i}" for i in range(16))
# Templates rendered from the active variant; foot.ini gets both variants (live mode switch)
TARGETS = ("kitty.conf", "foot.ini")


class ThemeError(Exception):
    pass


def load(family):
    path = THEMES / f"{family}.toml"
    if not path.is_file():
        known = ", ".join(sorted(p.stem for p in THEMES.glob("*.toml")))
        raise ThemeError(f"unknown theme '{family}' (known: {known})")
    with path.open("rb") as f:
        return tomllib.load(f)


def contrast(a, b):
    """WCAG 2 contrast ratio of two #rrggbb colours."""
    def luminance(hex_colour):
        channels = [int(hex_colour[i:i + 2], 16) / 255 for i in (1, 3, 5)]
        r, g, b = (c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in channels)
        return 0.2126 * r + 0.7152 * g + 0.0722 * b
    hi, lo = sorted((luminance(a), luminance(b)), reverse=True)
    return (hi + 0.05) / (lo + 0.05)


def lint(theme):
    """Problems with a loaded theme: missing keys, or text contrast below WCAG AA."""
    problems = []
    for mode in MODES:
        for table, keys in (("ui", ROLES), ("ansi", ANSI)):
            missing = [k for k in keys if k not in theme.get(mode, {}).get(table, {})]
            if missing:
                problems.append(f"{mode}.{table} missing {', '.join(missing)}")
        if problems:
            continue
        ui = theme[mode]["ui"]
        for role, minimum in (("fg", 4.5), ("fg_muted", 3.0)):
            ratio = contrast(ui[role], ui["bg"])
            if ratio < minimum:
                problems.append(f"{mode} {role}/bg contrast {ratio:.2f} < {minimum}")
    return problems


def variables(theme, family, mode):
    values = {"family": family, "mode": mode}
    for m in MODES:
        for key, colour in {**theme[m]["ui"], **theme[m]["ansi"]}.items():
            values[f"{m}_{key}"] = colour
            values[f"{m}_{key}_x"] = colour.lstrip("#")  # foot wants bare hex
            if m == mode:
                values[key] = colour
                values[f"{key}_x"] = colour.lstrip("#")
    return values


def write_atomic(path, text):
    fd, tmp = tempfile.mkstemp(dir=path.parent, prefix=f".{path.name}.")
    with os.fdopen(fd, "w") as f:
        f.write(text)
    os.replace(tmp, path)


def render(family, mode, state):
    if mode not in MODES:
        raise ThemeError(f"unknown mode '{mode}' (dark or light)")
    theme = load(family)
    if problems := lint(theme):
        raise ThemeError(f"{family}: " + "; ".join(problems))

    state.mkdir(parents=True, exist_ok=True)
    values = variables(theme, family, mode)
    for target in TARGETS:
        write_atomic(state / target, Template((TEMPLATES / target).read_text()).substitute(values))
    palette = {"meta": theme["meta"], "mode": mode, "ui": theme[mode]["ui"], "ansi": theme[mode]["ansi"]}
    write_atomic(state / "palette.json", json.dumps(palette, indent=2) + "\n")
    write_atomic(state / "current", f"family={family}\nmode={mode}\n")  # last: marks the render complete


def state_dir():
    base = os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state"
    return Path(base) / "desktop/theme"


def main(argv):
    try:
        if argv[:1] == ["render"] and len(argv) == 3:
            render(argv[1], argv[2], state_dir())
            return 0
        if argv[:1] == ["lint"]:
            families = argv[1:] or sorted(p.stem for p in THEMES.glob("*.toml"))
            failed = False
            for family in families:
                for problem in lint(load(family)):
                    print(f"{family}: {problem}", file=sys.stderr)
                    failed = True
            return 1 if failed else 0
    except ThemeError as e:
        print(f"error: {e}", file=sys.stderr)
        return 1
    print(__doc__.split("\n\n")[1], file=sys.stderr)
    return 2


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
