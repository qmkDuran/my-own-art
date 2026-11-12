"""Summarise a playtest session log (playtest/sessions/*.json) to see where the bot was dumb.

Run: python3 -I tools/analyze_session.py [LOG.json]   (no argument: the newest log in playtest/sessions)
Prints the outcome, how the fight went (moves, hits, ambushes, hiding), how the bot spent its time and what it
decided, and a list of suspicious moments (long fruitless searches, flip-flopping decisions, ambushes it walked
into, a player it never found)."""
from __future__ import annotations

import json
import sys
from collections import Counter
from pathlib import Path

SESSIONS = Path(__file__).resolve().parent.parent / "playtest" / "sessions"
LONG_SEARCH = 15.0
FLIP_WINDOW = 5.0
FLIP_COUNT = 5


def load(path: Path) -> dict:
    return json.loads(path.read_text())


def state_spans(events: list[dict], duration: float) -> list[tuple[str, float, float]]:
    """(state, start, end) for every bot state in order."""
    changes = [e for e in events if e["kind"] == "bot_state"]
    spans = []
    for k, change in enumerate(changes):
        end = changes[k + 1]["t"] if k + 1 < len(changes) else duration
        spans.append((change["state"], change["t"], end))
    return spans


def hidden_time(events: list[dict], duration: float) -> float:
    total, since = 0.0, None
    for e in events:
        if e["kind"] == "hide" and since is None:
            since = e["t"]
        elif e["kind"] == "leave_cover" and since is not None:
            total += e["t"] - since
            since = None
    return total + (duration - since if since is not None else 0.0)


def suspicious(log: dict, spans: list[tuple[str, float, float]]) -> list[str]:
    notes = []
    for state, start, end in spans:
        if state == "search" and end - start > LONG_SEARCH:
            notes.append(f"searched for {end - start:.0f}s from {start:.0f}s without finding the player")
    times = [d["t"] for d in log["decisions"]]
    for k in range(len(times) - FLIP_COUNT):
        if times[k + FLIP_COUNT] - times[k] < FLIP_WINDOW:
            notes.append(f"flip-flopped between plans around {times[k]:.0f}s")
            break
    for e in log["events"]:
        if e["kind"] == "hit" and e["on"] == "bot" and e["ambush"]:
            notes.append(f"walked into an ambush at {e['t']:.0f}s ({e['move']}, -{e['damage']})")
    hides = [e for e in log["events"] if e["kind"] == "hide"]
    if hides and not any(s == "search" for s, _, _ in spans):
        notes.append("the player hid but the bot never searched")
    return notes


def summarise(log: dict) -> str:
    events, duration = log["events"], log["duration"]
    spans = state_spans(events, duration)
    moves = Counter((e["by"], e["move"]) for e in events if e["kind"] == "move")
    hits = [e for e in events if e["kind"] == "hit"]
    state_time = Counter()
    for state, start, end in spans:
        state_time[state] += end - start
    lines = [f"outcome {log['outcome']}  duration {duration:.0f}s  difficulty {log.get('difficulty', '?')}",
             f"final life: player {log['final_life']['player']:.0f}  bot {log['final_life']['bot']:.0f}",
             f"player hid {sum(1 for e in events if e['kind'] == 'hide')} times, {hidden_time(events, duration):.0f}s",
             "moves: " + ", ".join(f"{by} {move} x{n}" for (by, move), n in sorted(moves.items()))]
    for side in ("player", "bot"):
        mine = [h for h in hits if h["by"] == side]
        lines.append(f"{side} hits: {len(mine)} ({sum(h['ambush'] for h in mine)} ambush), "
                     f"{sum(h['damage'] for h in mine):.0f} damage")
    lines.append("bot time: " + ", ".join(f"{s} {t:.0f}s" for s, t in state_time.most_common()))
    lines.append("bot decisions: " + ", ".join(f"{o} x{n}" for o, n in
                                               Counter(d["option"] for d in log["decisions"]).most_common()))
    notes = suspicious(log, spans)
    lines += ["suspicious:"] + [f"  - {n}" for n in notes] if notes else ["suspicious: nothing obvious"]
    return "\n".join(lines)


def main() -> None:
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])
    else:
        logs = sorted(SESSIONS.glob("*.json"))
        if not logs:
            sys.exit("no session logs in " + str(SESSIONS))
        path = logs[-1]
    print(f"SESSION {path.name}")
    print(summarise(load(path)))


if __name__ == "__main__":
    main()
