"""Clean-code lint for the GDScript (see CODE_STYLE.md). Hard rules (exit 1):
  - every function typed (all arguments and the return type)
  - functions at most FUNC_HARD lines, files at most FILE_HARD lines, lines at most LINE_HARD characters
  - every script starts with a ## header saying what it is for
  - no print outside tests, no commented-out code, no TODO
  - no unused functions (a function whose name appears nowhere else in the project)
  - no bare decimal numbers in logic (name them as constants or put them in data/*.json)
Run: python3 -I tools/check_code.py"""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent / "game"
FUNC_HARD = 40
FUNC_SOFT = 30
FILE_HARD = 400
LINE_HARD = 120
FUNC_RE = re.compile(r"^(static )?func (\w+)\((.*)\)( -> [\w\[\]]+)?:\s*$")
CODE_COMMENT = re.compile(r"^\s*#\s*(var|func|if|for|return|print)\b")
DECIMAL = re.compile(r"(?<![\w.])(\d+\.\d+)(?![\w.])")
ALLOWED_DECIMALS = {"0.0", "1.0", "0.5", "2.0"}
ENGINE_CALLBACKS = {"_ready", "_process", "_physics_process", "_input", "_unhandled_input", "_draw", "_init",
                    "_enter_tree", "_exit_tree", "_notification", "_gui_input"}
DYNAMIC_PREFIXES = ("_stage_",)  # shots.gd calls "_stage_" + shot name


def _functions(lines: list[str]) -> list[tuple[str, int, int]]:
    out = []
    starts = [i for i, l in enumerate(lines) if FUNC_RE.match(_joined(lines, i)) and l.startswith(("func", "static"))]
    for k, s in enumerate(starts):
        end = starts[k + 1] if k + 1 < len(starts) else len(lines)
        body = [l for l in lines[s + 1:end] if l.strip() and l.startswith(("\t", " "))]
        out.append((FUNC_RE.match(_joined(lines, s)).group(2), s + 1, len(body)))
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
    while s.startswith(("func", "static func")) and not s.rstrip().endswith(":") and k + 1 < len(lines):
        k += 1
        s = s.rstrip() + " " + lines[k].strip()
    return s


def _code_part(line: str) -> str:
    """The line without its comment and string literals."""
    line = re.sub(r'"[^"]*"', '""', line)
    return line.split("#", 1)[0]


def check(path: Path) -> tuple[list[str], list[str]]:
    rel = path.relative_to(ROOT.parent)
    lines = path.read_text().splitlines()
    hard, soft = [], []
    if len(lines) > FILE_HARD:
        hard.append(f"{rel}: {len(lines)} lines (max {FILE_HARD})")
    if not any(l.startswith("##") for l in lines[:4]):
        hard.append(f"{rel}: no ## header saying what the script is for")
    in_constant = False
    depth = 0
    for i, raw in enumerate(lines, 1):
        code = _code_part(raw)
        if depth == 0:
            in_constant = raw.startswith(("const ", "static var ", "var ", "enum "))
        depth += sum(code.count(c) for c in "([{") - sum(code.count(c) for c in ")]}")
        if len(raw.expandtabs(4)) > LINE_HARD:
            hard.append(f"{rel}:{i}: line is {len(raw.expandtabs(4))} characters (max {LINE_HARD})")
        l = _joined(lines, i - 1)
        m = FUNC_RE.match(l)
        if l.startswith(("func", "static func")) and not m:
            hard.append(f"{rel}:{i}: function signature not understood")
        if m and not m.group(4):
            hard.append(f"{rel}:{i}: {m.group(2)} has no return type")
        if m and m.group(3).strip():
            for arg in _split_args(m.group(3)):
                if ":" not in arg:
                    hard.append(f"{rel}:{i}: argument '{arg.strip()}' of {m.group(2)} is untyped")
        if re.search(r"(?<![\w.])print\(", raw) and "tests" not in str(rel):
            hard.append(f"{rel}:{i}: print outside tests")
        if CODE_COMMENT.match(raw) or "TODO" in raw:
            hard.append(f"{rel}:{i}: commented-out code or TODO")
        if raw.startswith(("\t", " ")) and not in_constant and "tests" not in str(rel):
            for number in DECIMAL.findall(code):
                if number not in ALLOWED_DECIMALS:
                    hard.append(f"{rel}:{i}: bare number {number} (name it or move it to data)")
    for name, line, n in _functions(lines):
        if n > FUNC_HARD:
            hard.append(f"{rel}:{line}: {name} is {n} lines (max {FUNC_HARD})")
        elif n > FUNC_SOFT:
            soft.append(f"{rel}:{line}: {name} is {n} lines (aim for {FUNC_SOFT})")
    return hard, soft


def unused_functions(files: list[Path]) -> list[str]:
    texts = {p: p.read_text() for p in files}
    everything = "\n".join(texts.values())
    problems = []
    for path, text in texts.items():
        for name, line, _ in _functions(text.splitlines()):
            if name in ENGINE_CALLBACKS or name.startswith(DYNAMIC_PREFIXES):
                continue
            uses = len(re.findall(rf"\b{re.escape(name)}\b", everything))
            if uses <= 1:
                problems.append(f"{path.relative_to(ROOT.parent)}:{line}: {name} is never used")
    return problems


def main() -> None:
    files = sorted(ROOT.rglob("*.gd"))
    hard, soft = [], []
    for p in files:
        h, s = check(p)
        hard += h
        soft += s
    hard += unused_functions(files)
    for s in soft:
        print("CODE note:", s)
    for h in hard:
        print("CODE problem:", h)
    print("CODE PASS" if not hard else f"CODE FAIL ({len(hard)} problems)")
    sys.exit(1 if hard else 0)


if __name__ == "__main__":
    main()
