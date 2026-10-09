#!/usr/bin/env python3
"""Render a theme family/mode into ~/.local/state/desktop/theme (PRD §6.5).

usage: theme_render.py render <family> <dark|light>
       theme_render.py lint [family...]
       theme_render.py palettes

Standard library only. Every file under templates/ is a target, rendered to the same relative path.
A theme is rendered into a fresh directory next to the state path, which is a symlink swapped to it
in one step: readers see the old theme or the new one, never a mix.
"""

import fcntl
import hashlib
import json
import os
import shutil
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


class ThemeError(Exception):
    pass


def targets():
    """Every template, as a path relative to templates/ (also its output path)."""
    return sorted(str(p.relative_to(TEMPLATES)) for p in TEMPLATES.rglob("*") if p.is_file())


def load(family):
    path = THEMES / f"{family}.toml"
    if not path.is_file():
        known = ", ".join(sorted(p.stem for p in THEMES.glob("*.toml")))
        raise ThemeError(f"unknown theme '{family}' (known: {known})")
    with path.open("rb") as f:
        return tomllib.load(f)


def palettes():
    """Every family's name and its dark and light ui colours (the shell's theme picker)."""
    themes = []
    for path in sorted(THEMES.glob("*.toml")):
        theme = load(path.stem)
        themes.append({"family": path.stem, "name": theme["meta"]["name"],
                       **{mode: theme[mode]["ui"] for mode in ("dark", "light") if mode in theme}})
    return themes


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


def variables(theme, family, mode, state):
    dark = mode == "dark"
    values = {
        "family": family, "mode": mode,
        "state": str(state),  # absolute: qt5ct/qt6ct can't resolve ~ or relative paths
        "gtk_theme": "adw-gtk3-dark" if dark else "adw-gtk3",
        "color_scheme": "prefer-dark" if dark else "prefer-light",
        "icon_theme": f"Tela-circle-blue-{mode}",
    }
    for m in MODES:
        for key, colour in {**theme[m]["ui"], **theme[m]["ansi"]}.items():
            values[f"{m}_{key}"] = colour
            values[f"{m}_{key}_x"] = colour.lstrip("#")  # foot wants bare hex
            if m == mode:
                values[key] = colour
                values[f"{key}_x"] = colour.lstrip("#")
    return values


def fingerprint(family, mode, state):
    """Everything a render depends on; an unchanged fingerprint means an identical render."""
    h = hashlib.sha256(f"{family}\0{mode}\0{state}\0".encode())
    h.update(Path(__file__).read_bytes())  # the renderer itself
    h.update((THEMES / f"{family}.toml").read_bytes())
    for target in targets():
        h.update(f"\0{target}\0".encode())
        h.update((TEMPLATES / target).read_bytes())
    return h.hexdigest()


def render(family, mode, state):
    """Render into a new directory beside state, then point state (a symlink) at it. A request
    identical to the current render (same fingerprint) leaves it in place."""
    if mode not in MODES:
        raise ThemeError(f"unknown mode '{mode}' (dark or light)")
    theme = load(family)
    if problems := lint(theme):
        raise ThemeError(f"{family}: " + "; ".join(problems))

    state = Path(state)
    state.parent.mkdir(parents=True, exist_ok=True)
    with open(state.parent / f".{state.name}.lock", "w") as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)  # one render at a time
        digest = fingerprint(family, mode, state)
        if state.is_symlink() and (state / ".fingerprint").is_file() \
                and (state / ".fingerprint").read_text() == digest:
            return
        new = Path(tempfile.mkdtemp(dir=state.parent, prefix=f".{state.name}."))
        new.chmod(0o755)  # mkdtemp makes it private
        values = variables(theme, family, mode, state)
        for target in targets():
            out = new / target
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(Template((TEMPLATES / target).read_text()).substitute(values))
        palette = {"meta": theme["meta"], "mode": mode, "ui": theme[mode]["ui"], "ansi": theme[mode]["ansi"]}
        (new / "palette.json").write_text(json.dumps(palette, indent=2) + "\n")
        (new / "current").write_text(f"family={family}\nmode={mode}\n")
        (new / ".fingerprint").write_text(digest)

        if state.exists() and not state.is_symlink():  # a plain directory from before; the renderer owns it
            shutil.rmtree(state)
        link = state.parent / f".{state.name}.link"
        link.unlink(missing_ok=True)
        link.symlink_to(new.name)
        os.replace(link, state)  # the switch, atomic
        for old in state.parent.glob(f".{state.name}.*"):  # earlier renders, and leftovers of failed ones
            if old.is_dir() and not old.is_symlink() and old != new:
                shutil.rmtree(old)


def state_dir():
    base = os.environ.get("XDG_STATE_HOME") or Path.home() / ".local/state"
    return Path(base) / "desktop/theme"


def main(argv):
    try:
        if argv[:1] == ["render"] and len(argv) == 3:
            render(argv[1], argv[2], state_dir())
            return 0
        if argv == ["palettes"]:
            print(json.dumps(palettes()))
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
