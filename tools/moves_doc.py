"""Write MOVES.md from game/data/moves.json, so the move table never drifts from the data.

Run: python3 -I tools/moves_doc.py   (rewrites MOVES.md at the repository root)"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATEGORIES = ["attack", "movement", "defensive", "buff", "debuff", "sense", "terrain"]
HEADER = """# Moves

Every move both creatures can learn. Generated from `game/data/moves.json` by `python3 -I tools/moves_doc.py`;
edit the JSON, not this file. Each creature takes four into a fight (LMB, RMB, Q, E), picked on the loadout
screen. **Baby** fights only allow moves marked Baby; **Grown** allows all of them. Every move has a visible
wind-up and a cooldown, and a counter (its tit for tat).
"""


def table(moves: dict, levels: dict, category: str) -> list[str]:
    baby = levels["baby"]
    lines = [f"\n## {category.capitalize()}\n", "| Move | Effect | Cost | Counter (tit for tat) | Min level | Cooldown |",
             "| --- | --- | --- | --- | --- | --- |"]
    for spec in moves.values():
        if spec["category"] != category:
            continue
        level = "Baby" if spec["min_level"] <= baby else "Grown"
        lines.append(f"| **{spec['name']}** | {spec['description']} | {spec['cost']} | {spec['tit_for_tat']} | "
                     f"{level} | {spec['cooldown']} s |")
    return lines


def main() -> None:
    data = json.loads((ROOT / "game/data/moves.json").read_text())
    lines = [HEADER]
    for category in CATEGORIES:
        lines += table(data["moves"], data["levels"], category)
    (ROOT / "MOVES.md").write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    main()
