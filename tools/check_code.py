"""Clean-code lint for the GDScript (see CODE_STYLE.md): every function and argument typed, functions short
(soft 30 / hard 40 lines), files focused (max 400 lines), a ## header on every script, no print outside tests,
no commented-out code or TODO, no bare colour literals outside the palette code.
Run: python3 -I tools/check_code.py   (exit 1 on any hard problem; soft ones are listed as notes)"""
from __future__ import annotations

import re
import sys
from pathlib import Path

GAME = Path(__file__).resolve().parent.parent / "game"
FUNC_SOFT, FUNC_HARD, FILE_HARD = 30, 40, 400
SIG = re.compile(r"^(static )?func (\w+)\((.*)\)\s*(->\s*[\w\[\], ]+)?:\s*$")
DEAD_CODE = re.compile(r"^\s*#\s*(var|func|if|for|return|print|await)\b")
HEX_COLOUR = re.compile(r"Color\(\"#|Color8\(|Color\(0\.\d+, 0\.\d+")


def signature(lines: list[str], i: int) -> str:
    """A signature that wraps over several lines, joined."""
    s, k = lines[i], i
    while not s.rstrip().endswith(":") and k + 1 < len(lines):
        k += 1
        s = s.rstrip() + " " + lines[k].strip()
    return s


def split_args(text: str) -> list[str]:
    out, depth, cur = [], 0, ""
    for ch in text:
        depth += ch in "([{"
        depth -= ch in ")]}"
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    return [a for a in out + [cur] if a.strip()]


def function_lengths(lines: list[str]) -> list[tuple[str, int, int]]:
    starts = [i for i, l in enumerate(lines) if l.startswith(("func ", "static func "))]
    out = []
    for n, s in enumerate(starts):
        end = starts[n + 1] if n + 1 < len(starts) else len(lines)
        body = [l for l in lines[s + 1:end] if l.startswith(("\t", "    ")) and l.strip() and not l.strip().startswith("#")]
        name = re.match(r"(static )?func (\w+)", lines[s]).group(2)
        out.append((name, s + 1, len(body)))
    return out


def check(path: Path) -> tuple[list[str], list[str]]:
    rel = path.relative_to(GAME)
    lines = path.read_text().splitlines()
    hard: list[str] = []
    soft: list[str] = []
    is_test = rel.parts[0] == "tests"
    if len(lines) > FILE_HARD:
        hard.append(f"{rel}: {len(lines)} lines (max {FILE_HARD})")
    if not any(l.startswith("##") for l in lines[:5]):
        hard.append(f"{rel}: no ## header saying what the script is for")
    for i, line in enumerate(lines):
        where = f"{rel}:{i + 1}"
        if line.startswith(("func ", "static func ")):
            m = SIG.match(signature(lines, i))
            if not m:
                hard.append(f"{where}: signature not understood")
                continue
            if not m.group(4):
                hard.append(f"{where}: {m.group(2)} has no return type")
            for arg in split_args(m.group(3)):
                if ":" not in arg.split("=")[0]:
                    hard.append(f"{where}: argument '{arg.strip()}' of {m.group(2)} is untyped")
        if re.search(r"(?<![\w.])print\(", line) and not is_test:
            hard.append(f"{where}: print outside tests")
        if DEAD_CODE.match(line) or "TODO" in line:
            hard.append(f"{where}: commented-out code or TODO")
        if HEX_COLOUR.search(line):
            hard.append(f"{where}: colour literal (use the palette: UiKit.c / Db.color)")
    for name, at, n in function_lengths(lines):
        if n > FUNC_HARD:
            hard.append(f"{rel}:{at}: {name} is {n} lines (max {FUNC_HARD})")
        elif n > FUNC_SOFT:
            soft.append(f"{rel}:{at}: {name} is {n} lines (aim for {FUNC_SOFT})")
    return hard, soft


def main() -> int:
    files = sorted(GAME.rglob("*.gd"))
    hard: list[str] = []
    soft: list[str] = []
    for f in files:
        h, s = check(f)
        hard += h
        soft += s
    for p in hard:
        print("CODE", p)
    for p in soft:
        print("CODE note", p)
    print(f"CODE {'PASS' if not hard else 'FAIL'}: {len(files)} scripts, {len(hard)} problems, {len(soft)} notes")
    return 1 if hard else 0


if __name__ == "__main__":
    sys.exit(main())
