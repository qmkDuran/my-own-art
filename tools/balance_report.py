"""Turns tamer balance rows (tools/tamer_balance.sh) into tables in TAMER_NOTES.md.

Usage: balance_report.py ROWS.jsonl LABEL NOTES.md
Writes, between <!-- balance:LABEL:start --> and <!-- balance:LABEL:end -->: each creature's win rate per tier
(as your side, against every other species in every arena), its Normal win rate per arena, the Normal matchup
grid (both directions of a pair pooled: A's wins as the bot plus A's wins as the opponent), and the outliers
against the targets (Normal 40-60%, Hard 25-45%, no single matchup or arena over 70% or under 30% at Normal).
"""
import json
import sys
from collections import defaultdict

NORMAL = (0.40, 0.60)
HARD = (0.25, 0.45)
CELL = (0.30, 0.70)


def name(s):
    return s.replace("_", " ").title().replace("Tas ", "Tasmanian ").replace("Aye Aye", "Aye-aye")


def rate(wins, n):
    return wins / n if n else 0.0


def pct(x):
    return "%d%%" % round(x * 100)


def main(rows_path, label, notes_path):
    rows = [json.loads(l) for l in open(rows_path) if l.strip()]
    kinds = sorted({r["you"] for r in rows})
    arenas = sorted({r["arena"] for r in rows})
    tiers = [t for t in ("easy", "normal", "hard") if any(r["tier"] == t for r in rows)]
    win = lambda r: 1 if r["result"] == "win" else 0
    by_tier = defaultdict(lambda: [0, 0, 0.0])
    by_arena = defaultdict(lambda: [0, 0])
    pair = defaultdict(lambda: [0, 0])
    for r in rows:
        bt = by_tier[(r["you"], r["tier"])]
        bt[0] += win(r); bt[1] += 1; bt[2] += r["time"]
        if r["tier"] == "normal":
            ba = by_arena[(r["you"], r["arena"])]
            ba[0] += win(r); ba[1] += 1
            pair[(r["you"], r["foe"])][0] += win(r); pair[(r["you"], r["foe"])][1] += 1
            lost = 1 if r["result"] == "loss" else 0
            pair[(r["foe"], r["you"])][0] += lost; pair[(r["foe"], r["you"])][1] += 1
    out = ["<!-- balance:%s:start -->" % label, "",
           "**%s** (%d fights; bot at Normal vs the AI at each tier, level 10, 1v1, 40 s cap, every ordered pair in every arena)." % (label, len(rows)),
           "", "| Creature | " + " | ".join(t.capitalize() + " (win / avg s)" for t in tiers) + " | " + " | ".join(a.capitalize() for a in arenas) + " |",
           "|---" * (1 + len(tiers) + len(arenas)) + "|"]
    flags = []
    for k in kinds:
        cells = []
        for t in tiers:
            w, n, s = by_tier[(k, t)]
            cells.append("%s / %.0f" % (pct(rate(w, n)), s / n if n else 0))
            lo, hi = NORMAL if t == "normal" else HARD if t == "hard" else (0, 1)
            if not lo <= rate(w, n) <= hi:
                flags.append("%s %s at %s" % (name(k), pct(rate(w, n)), t.capitalize()))
        for a in arenas:
            w, n = by_arena[(k, a)]
            cells.append(pct(rate(w, n)))
            if not CELL[0] <= rate(w, n) <= CELL[1]:
                flags.append("%s %s in the %s" % (name(k), pct(rate(w, n)), a))
        out.append("| %s | %s |" % (name(k), " | ".join(cells)))
    out += ["", "Normal matchups (row's win rate against the column, both directions pooled):", "",
            "| vs | " + " | ".join(name(k) for k in kinds) + " |", "|---" * (1 + len(kinds)) + "|"]
    for a in kinds:
        cells = []
        for b in kinds:
            if a == b:
                cells.append("-")
                continue
            w, n = pair[(a, b)]
            cells.append(pct(rate(w, n)))
            if a < b and not CELL[0] <= rate(w, n) <= CELL[1]:
                flags.append("%s vs %s %s" % (name(a), name(b), pct(rate(w, n))))
        out.append("| %s | %s |" % (name(a), " | ".join(cells)))
    out += ["", "Outside the targets: " + ("none" if not flags else "; ".join(flags)) + ".", "", "<!-- balance:%s:end -->" % label]
    text = open(notes_path).read()
    start, end = "<!-- balance:%s:start -->" % label, "<!-- balance:%s:end -->" % label
    block = "\n".join(out)
    if start in text and end in text:
        text = text[:text.index(start)] + block + text[text.index(end) + len(end):]
    else:
        text = text.rstrip("\n") + "\n\n" + block + "\n"
    open(notes_path, "w").write(text)
    print(block)


if __name__ == "__main__":
    main(*sys.argv[1:4])
