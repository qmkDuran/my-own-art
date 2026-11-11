"""Clean-code lint for the GDScript (see CODE_STYLE.md): every function typed (arguments and return), functions
short, files focused, no print outside tests, no commented-out code or TODOs, every script documented (## header).
Run: python3 -I tools/check_code.py   (exit 1 on any problem; long functions over the soft limit are listed)"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "game"
FUNC_HARD = 40
FUNC_SOFT = 30
FILE_HARD = 400
FUNC_RE = re.compile(r"^(static )?func (\w+)\((.*)\)( -> [\w\[\]]+)?:\s*$")
CODE_COMMENT = re.compile(r"^\s*#\s*(var|func|if|for|return|print)\b")


def _functions(lines: list[str]) -> list[tuple[str, int, int]]:
    out = []
    starts = [i for i, l in enumerate(lines) if FUNC_RE.match(l)]
    for k, s in enumerate(starts):
        end = starts[k + 1] if k + 1 < len(starts) else len(lines)
        body = [l for l in lines[s + 1:end] if l.strip() and not l.startswith(("func", "static", "const", "var", "class", "##", "signal"))]
        out.append((FUNC_RE.match(lines[s]).group(2), s + 1, len(body)))
    return out


def _split_args(s: str) -> list[str]:
    """Arguments split on top-level commas (default values may contain calls)."""
    out, depth, cur = [], 0, ""
    for ch in s:
        depth += ch in "([{"
        depth -= ch in ")]}"
        if ch == "," and depth == 0:
            out.append(cur)
            cur = ""
        else:
            cur += ch
    return out + [cur]


def _joined(lines: list[str], i: int) -> str:
    """A signature that wraps onto following lines, joined into one."""
    s = lines[i]
    k = i
    while not s.rstrip().endswith(":") and k + 1 < len(lines):
        k += 1
        s = s.rstrip() + " " + lines[k].strip()
    return s


def check(path: Path) -> tuple[list[str], list[str]]:
    rel = path.relative_to(ROOT.parent)
    lines = path.read_text().splitlines()
    hard, soft = [], []
    if len(lines) > FILE_HARD:
        hard.append(f"{rel}: {len(lines)} lines (max {FILE_HARD})")
    if not any(l.startswith("##") for l in lines[:6]):
        hard.append(f"{rel}: no ## header saying what the script is for")
    for i, raw in enumerate(lines, 1):
        l = _joined(lines, i - 1) if raw.startswith(("func", "static func")) else raw
        m = FUNC_RE.match(l)
        if l.startswith(("func", "static func")) and not m:
            hard.append(f"{rel}:{i}: function signature not understood")
        if m and not m.group(4):
            hard.append(f"{rel}:{i}: {m.group(2)} has no return type")
        if m and m.group(3).strip():
            for arg in _split_args(m.group(3)):
                if ":" not in arg:
                    hard.append(f"{rel}:{i}: argument '{arg.strip()}' of {m.group(2)} is untyped")
        if re.search(r"(?<![\w.])print\(", l) and "tests" not in str(rel):
            hard.append(f"{rel}:{i}: print outside tests")
        if CODE_COMMENT.match(l) or "TODO" in l:
            hard.append(f"{rel}:{i}: commented-out code or TODO")
    for name, line, n in _functions(lines):
        if n > FUNC_HARD:
            hard.append(f"{rel}:{line}: {name} is {n} lines (max {FUNC_HARD})")
        elif n > FUNC_SOFT:
            soft.append(f"{rel}:{line}: {name} is {n} lines (aim for {FUNC_SOFT})")
    return hard, soft


def main() -> None:
    hard, soft = [], []
    for p in sorted(ROOT.rglob("*.gd")):
        h, s = check(p)
        hard += h
        soft += s
    for s in soft:
        print("CODE note:", s)
    for h in hard:
        print("CODE problem:", h)
    print("CODE PASS" if not hard else f"CODE FAIL ({len(hard)} problems)")
    sys.exit(1 if hard else 0)


if __name__ == "__main__":
    main()
