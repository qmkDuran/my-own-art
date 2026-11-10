#!/usr/bin/env python3
"""Layout logic check for every zone in data/zones/ (no engine needed: numpy, scipy, Pillow).

    python3 tests/layout_check.py            # all zones; exit code 1 on any FAIL
    python3 tests/layout_check.py store -v   # one zone, list every room / door / placement

It rebuilds each zone's collision the way the engine does (solid tiles from data/tiles.json,
entity "solid" rectangles, building footprints from data/art.json) for every story state, then
moves a player-sized box (18x10 px, like Player) through it on a 4 px grid and checks:

  leaks       interiors: no walkable path from a spawn to the void outside the walls; the street:
              no path off the map except at the zone's declared "open_edges".
  doors       every doorway / door tile sits in a wall (wall on both sides, floor in front);
              blocking a doorway must separate two rooms (otherwise you could walk around it);
              every "door" interaction is on a door tile (interiors) or at a building's front
              wall (exterior) and can be reached.
  walls       interior wall tiles form one connected structure (no segment ending mid-room).
  rooms       no floor area of a tile or more that nobody can reach (furniture blocking it).
  overlaps    no two solid things overlap; no furniture sunk into a wall; furniture stands on floor.
  reach       every interaction (examine, talk, pickup, door) can be used from a walkable spot.
  placement   every non-solid prop says what it rests on ("on": a host entity id, "wall",
              "floor" for rugs/mats/decals, "ground" outdoors); loose things on the floor need a
              story reason ("story": "...") and pickups may not lie on the floor without one. A
              host must contain the prop's anchor and be present whenever the prop is.
  exterior    fences/hedges end against something solid; vehicles stand on road/driveway;
              driveways reach the road; each building door has a paved path to the sidewalk.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

import numpy as np
from PIL import Image
from scipy import ndimage

ROOT = Path(__file__).resolve().parent.parent
TILE = 32
RES = 4                      # grid resolution in px
PLAYER_W, PLAYER_H = 18, 10  # Player body: 18x10, bottom at the feet
INTERACTOR_R, INTERACT_REACH, INTERACTOR_LIFT = 20.0, 22.0, 12.0

# Story states each zone is checked in (flags set; everything else unset).
STATES = [
    {},
    {"C1_ERRAND": True},
    {"C1_ERRAND": True, "took_card": True, "C1_LAST_WORDS": True},
    {"C1_ERRAND": True, "wade_hostile": True},
    {"vanished": True},
    {"vanished": True, "wade_gone": True, "wade_defeated": True},
    {"vanished": True, "biscuit_hostile": True},
    {"vanished": True, "C1_BISCUIT": "befriended", "street_looter_defeated": True},
    {"vanished": True, "C1_DAWN": True},
]

TILES = json.loads((ROOT / "data/tiles.json").read_text())
ART = json.loads((ROOT / "data/art.json").read_text())
_size_cache: dict = {}


# --- helpers ---------------------------------------------------------------------------------

def art_entry(art_id: str) -> dict:
    raw = ART.get(art_id, {})
    if "extends" in raw:
        merged = dict(art_entry(raw["extends"]))
        merged.update({k: v for k, v in raw.items() if k != "extends"})
        return merged
    return raw


def art_size(art_id: str) -> tuple[int, int] | None:
    if art_id in _size_cache:
        return _size_cache[art_id]
    entry = art_entry(art_id)
    path = ROOT / entry.get("path", "res://-").replace("res://", "")
    size = None
    if path.is_file():
        w, h = Image.open(path).size
        fx = entry.get("fx")
        size = (w // int(fx["frames"]), h) if fx else (w, h)
    _size_cache[art_id] = size
    return size


def check_condition(cond, flags: dict) -> bool:
    if cond is None:
        return True
    if isinstance(cond, list):
        return all(check_condition(c, flags) for c in cond)
    text = str(cond).strip()
    if "|" in text:
        return any(check_condition(o, flags) for o in text.split("|"))
    if "&" in text:
        return all(check_condition(a, flags) for a in text.split("&"))
    for op in ("==", "!="):
        if op in text:
            name, value = (p.strip() for p in text.split(op, 1))
            equal = str(flags.get(name, "")) == value
            return equal if op == "==" else not equal
    negate = text.startswith("!")
    name = text[1:] if negate else text
    if name.startswith("has:"):
        value = False
    else:
        value = bool(flags.get(name, False))
    return not value if negate else value


def entity_condition(e: dict):
    conds = [e.get("if")] if e.get("if") is not None else []
    if e.get("kind") == "enemy" and "defeat_flag" in e:
        conds.append("!" + e["defeat_flag"])
    return conds or None


def position(e: dict) -> tuple[float, float]:
    p = e.get("pos", [0, 0])
    off = e.get("offset", [0, 0])
    return (float(p[0]) + 0.5) * TILE + float(off[0]), (float(p[1]) + 0.5) * TILE + float(off[1])


def sprite_rect(e: dict):
    """(x, y, w, h) of the entity's sprite in world px, or None."""
    art = e.get("art")
    if not art or e.get("kind") in ("npc", "enemy"):
        return None
    size = art_size(art)
    if size is None:
        return None
    x, y = position(e)
    w, h = size
    fx = art_entry(art).get("fx")
    if fx:
        ox, oy = fx.get("origin", [w / 2, h])
        return (x - ox, y - oy, w, h)
    if e.get("anchor") == "center":
        return (x - w / 2, y - h / 2, w, h)
    return (x - gd_round(w / 2), y - h, w, h)


def gd_round(v: float) -> float:
    """Godot's roundf: halves round away from zero (Python's round() rounds halves to even)."""
    return float(np.floor(abs(v) + 0.5) * (1 if v >= 0 else -1))


def solid_rects(e: dict) -> list:
    """World-space solid rectangles (x, y, w, h) exactly as EntityFactory builds them."""
    x, y = position(e)
    kind = e.get("kind", "prop")
    rects = []
    if kind == "npc":
        w, h = e.get("solid", [18, 10])
        return [(x - w / 2, y - h, w, h)]
    if kind in ("enemy", "trigger", "spawn", "light"):
        return []
    solid = e.get("solid")
    flip = e.get("flip", False)

    def image_rect(r):
        size = art_size(e.get("art", ""))
        if size is None:
            return None
        iw, ih = size
        left = r[0] - gd_round(iw / 2)
        if flip:
            left = -left - r[2]
        return (x + left, y + r[1] - ih, r[2], r[3])

    if solid == "art":
        entry = art_entry(e.get("art", ""))
        for r in [entry.get("footprint")] + list(entry.get("solid_extra", [])):
            if r:
                rr = image_rect(r)
                if rr:
                    rects.append(rr)
    elif isinstance(solid, list):
        w, h = solid
        ox, oy = e.get("solid_offset", [0, 0])
        rects.append((x + ox - w / 2, y + oy - h, w, h))
    for r in e.get("solid_rects", []):
        rr = image_rect(r)
        if rr:
            rects.append(rr)
    return rects


def interaction_point(e: dict):
    data = e.get("interact")
    if not data:
        return None
    x, y = position(e)
    off = data.get("offset", [0, -8])
    return (x + off[0], y + off[1], float(data.get("radius", 18.0)))


def overlap(a, b) -> float:
    w = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
    h = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
    return max(0.0, w) * max(0.0, h)


def depth(a, b) -> float:
    w = min(a[0] + a[2], b[0] + b[2]) - max(a[0], b[0])
    h = min(a[1] + a[3], b[1] + b[3]) - max(a[1], b[1])
    return min(w, h) if w > 0 and h > 0 else 0.0


def point_in(px, py, r, margin=0.0) -> bool:
    return r[0] - margin <= px <= r[0] + r[2] + margin and r[1] - margin <= py <= r[1] + r[3] + margin


# --- zone model ----------------------------------------------------------------------------

class Zone:
    def __init__(self, zone_id: str):
        self.id = zone_id
        self.data = json.loads((ROOT / f"data/zones/{zone_id}.json").read_text())
        legend = self.data.get("legend", {})
        rows = self.data.get("map", [])
        self.w = max(len(r) for r in rows)
        self.h = len(rows)
        self.cells = [[legend.get(r[x], "") if x < len(r) else "" for x in range(self.w)] for r in rows]
        self.interior = bool(self.data.get("interior", False))
        self.entities = self.data.get("entities", [])
        self.by_id = {e["id"]: e for e in self.entities if "id" in e}

    def tile(self, x: int, y: int) -> str:
        if 0 <= x < self.w and 0 <= y < self.h:
            return self.cells[y][x]
        return ""

    def tdef(self, x: int, y: int) -> dict:
        return TILES.get(self.tile(x, y), {})

    def walkable_tile(self, x: int, y: int) -> bool:
        t = self.tile(x, y)
        return bool(t) and not TILES.get(t, {}).get("solid", False)

    def face_level(self, x: int, y: int) -> int:
        t = self.tdef(x, y)
        if "face_art" not in t:
            return 0
        if self.walkable_tile(x, y + 1):
            return 1
        if "face_tall" in t and "face_art" in self.tdef(x, y + 1) and self.walkable_tile(x, y + 2):
            return 2
        return 0

    def active(self, flags: dict) -> list:
        out = []
        for e in self.entities:
            if check_condition(entity_condition(e), flags):
                out.append(e)
        return out


class Report:
    def __init__(self, verbose: bool):
        self.fails: list[str] = []
        self.notes: list[str] = []
        self.verbose = verbose

    def fail(self, msg: str) -> None:
        # "zone {state}: text" -> one line per text, listing the states it happens in
        import re
        m = re.match(r"^(\S+) (\{[^}]*\}): (.*)$", msg)
        if m:
            key = f"{m.group(1)}: {m.group(3)}"
            for i, f in enumerate(self.fails):
                if f.startswith(key + "  [in "):
                    if m.group(2) not in f:
                        self.fails[i] = f[:-1] + " " + m.group(2) + "]"
                    return
            if key in self.fails:
                return
            self.fails.append(f"{key}  [in {m.group(2)}]")
        elif msg not in self.fails:
            self.fails.append(msg)

    def note(self, msg: str) -> None:
        if msg not in self.notes:
            self.notes.append(msg)


# --- grid ------------------------------------------------------------------------------------

def build_grid(z: Zone, active: list):
    W, H = z.w * TILE // RES, z.h * TILE // RES
    blocked = np.zeros((H, W), bool)
    void = np.zeros((H, W), bool)
    doorway = np.zeros((H, W), bool)
    k = TILE // RES
    for y in range(z.h):
        for x in range(z.w):
            t = z.tile(x, y)
            d = TILES.get(t, {})
            sl = np.s_[y * k:(y + 1) * k, x * k:(x + 1) * k]
            if not t:
                void[sl] = True
            elif d.get("solid"):
                blocked[sl] = True
            if d.get("doorway"):
                doorway[sl] = True
    for e in active:
        for r in solid_rects(e):
            x0, y0 = int(np.floor(r[0] / RES)), int(np.floor(r[1] / RES))
            x1, y1 = int(np.ceil((r[0] + r[2]) / RES)), int(np.ceil((r[1] + r[3]) / RES))
            blocked[max(0, y0):max(0, y1), max(0, x0):max(0, x1)] = True
    # configuration space: feet position p is free if the 18x10 body above it hits nothing
    kw, kh = int(np.ceil(PLAYER_W / RES)), int(np.ceil(PLAYER_H / RES))
    hit = ndimage.maximum_filter(blocked.astype(np.uint8), size=(kh, kw), origin=(kh // 2, 0), mode="constant", cval=0) > 0
    edge = np.zeros_like(blocked)
    edge[:, : kw // 2 + 1] = edge[:, -(kw // 2 + 1):] = True
    edge[: kh, :] = True
    edge[-1:, :] = True
    free = ~hit & ~edge
    return free, blocked, void, doorway


def label_from(free: np.ndarray, seeds: list):
    labels, _ = ndimage.label(free)
    keep = {labels[int(sy // RES), int(sx // RES)] for sx, sy in seeds
            if 0 <= int(sy // RES) < free.shape[0] and 0 <= int(sx // RES) < free.shape[1]}
    keep.discard(0)
    return labels, keep


def spawns(z: Zone) -> list:
    return [position(e) for e in z.entities if e.get("kind") == "spawn"]


# --- checks --------------------------------------------------------------------------------

def check_zone(z: Zone, rep: Report) -> None:
    check_static(z, rep)
    for flags in STATES:
        active = z.active(flags)
        tag = "{" + ",".join(f for f in flags) + "}"
        free, blocked, void, doorway = build_grid(z, active)
        seeds = spawns(z)
        labels, reach = label_from(free, seeds)
        reachable = np.isin(labels, list(reach))
        for sx, sy in seeds:
            if labels[int(sy // RES), int(sx // RES)] == 0:
                rep.fail(f"{z.id} {tag}: spawn at {sx / TILE:.1f},{sy / TILE:.1f} is inside something solid")
        if len(reach) > 1:
            rep.fail(f"{z.id} {tag}: the spawn points are cut off from each other (something blocks the way)")
        check_leaks(z, rep, tag, reachable, void)
        if z.interior:
            check_rooms(z, rep, tag, free, doorway, reachable, void)
        check_overlaps(z, rep, tag, active)
        check_reach(z, rep, tag, active, reachable)
        check_placement(z, rep, tag, active, flags)
        if not z.interior:
            check_exterior(z, rep, tag, active, blocked)


def check_static(z: Zone, rep: Report) -> None:
    # doors / doorways embedded in walls
    seen = set()
    for y in range(z.h):
        for x in range(z.w):
            d = z.tdef(x, y)
            if not (d.get("door") or d.get("doorway")) or (x, y) in seen:
                continue
            # group contiguous door cells
            group, stack = [], [(x, y)]
            while stack:
                cx, cy = stack.pop()
                if (cx, cy) in seen:
                    continue
                cd = z.tdef(cx, cy)
                if not (cd.get("door") or cd.get("doorway")):
                    continue
                seen.add((cx, cy))
                group.append((cx, cy))
                stack += [(cx + 1, cy), (cx - 1, cy), (cx, cy + 1), (cx, cy - 1)]
            xs = [g[0] for g in group]
            ys = [g[1] for g in group]
            x0, x1, y0, y1 = min(xs), max(xs), min(ys), max(ys)
            is_wall = lambda tx, ty: bool(z.tdef(tx, ty).get("wall"))
            horiz = all(is_wall(x0 - 1, yy) and is_wall(x1 + 1, yy) for yy in range(y0, y1 + 1))
            vert = all(is_wall(xx, y0 - 1) and is_wall(xx, y1 + 1) for xx in range(x0, x1 + 1))
            name = "door" if any(z.tdef(*g).get("door") for g in group) else "doorway"
            where = f"{x0},{y0}" + (f"-{x1},{y1}" if (x1, y1) != (x0, y0) else "")
            if not (horiz or vert):
                rep.fail(f"{z.id}: {name} at {where} is not set into a wall (needs wall on both sides)")
            else:
                if horiz:
                    sides = [(xx, y0 - 1) for xx in range(x0, x1 + 1)] + [(xx, y1 + 1) for xx in range(x0, x1 + 1)]
                else:
                    sides = [(x0 - 1, yy) for yy in range(y0, y1 + 1)] + [(x1 + 1, yy) for yy in range(y0, y1 + 1)]
                inner = [s for s in sides if z.walkable_tile(*s)]
                if not inner:
                    rep.fail(f"{z.id}: {name} at {where} opens onto no floor")
                if name == "doorway" and len({(s[0] - x0 if horiz else s[1] - y0) < 0 for s in inner}) < 2 and len(inner) < len(sides):
                    rep.fail(f"{z.id}: doorway at {where} has floor on one side only")
            if name == "door":
                pts = [interaction_point(e) for e in z.entities if (e.get("interact") or {}).get("type") == "door"]
                near = [p for p in pts if p and any(abs(p[0] - (gx + 0.5) * TILE) <= TILE and abs(p[1] - (gy + 0.5) * TILE) <= TILE for gx, gy in group)]
                if not near:
                    rep.fail(f"{z.id}: door tile at {where} has no door interaction (a door that leads nowhere)")
            rep.note(f"{z.id}: {name} at {where} set in {'horizontal' if horiz else 'vertical'} wall")
    # door interactions must be on a door tile (interior) or a building front (exterior)
    for e in z.entities:
        data = e.get("interact") or {}
        if data.get("type") != "door":
            continue
        px, py, _ = interaction_point(e)
        if z.interior:
            tx, ty = int(px // TILE), int(py // TILE)
            ok = any(z.tdef(tx + dx, ty + dy).get("door") for dx in (-1, 0, 1) for dy in (-1, 0, 1))
            if not ok:
                rep.fail(f"{z.id}: door '{e.get('id')}' is not at a door tile (floating door)")
        else:
            fp = [r for r in solid_rects(e)] if e.get("building") else []
            if not fp:
                rep.fail(f"{z.id}: door '{e.get('id')}' is not on a building (needs \"building\": true and a footprint)")
            elif not any(r[0] <= px <= r[0] + r[2] and r[1] + r[3] - 4 <= py <= r[1] + r[3] + 40 for r in fp):
                rep.fail(f"{z.id}: door '{e.get('id')}' is not at its building's front wall")
    # view-only doors (a door you look through, never use) must be on a wall face
    for e in z.entities:
        if e.get("door_kind") == "view":
            x, y = position(e)
            if not any(z.face_level(int(x // TILE), int((y - d) // TILE)) for d in (1, 4)):
                rep.fail(f"{z.id}: view-only door '{e.get('id')}' is not on a wall face")
    # interior walls form one structure
    if z.interior:
        wall = np.array([[bool(z.tdef(x, y).get("wall") or z.tdef(x, y).get("door")) for x in range(z.w)] for y in range(z.h)])
        lab, n = ndimage.label(wall)
        if n > 1:
            sizes = ndimage.sum(wall, lab, range(1, n + 1))
            for i, s in enumerate(sizes, 1):
                if s < max(sizes):
                    ys, xs = np.nonzero(lab == i)
                    rep.fail(f"{z.id}: wall segment at {xs.min()},{ys.min()} is not connected to the other walls (ends in mid-air)")


def check_leaks(z: Zone, rep: Report, tag: str, reachable: np.ndarray, void: np.ndarray) -> None:
    if z.interior:
        hit = reachable & void
        if hit.any():
            ys, xs = np.nonzero(hit)
            rep.fail(f"{z.id} {tag}: interior leaks: you can walk out through a gap near tile {xs[0] * RES / TILE:.1f},{ys[0] * RES / TILE:.1f}")
        return
    H, W = reachable.shape
    border = np.zeros_like(reachable)
    m = 4
    border[:m, :] = border[-m:, :] = border[:, :m] = border[:, -m:] = True
    allowed = np.zeros_like(reachable)
    for edge in z.data.get("open_edges", []):
        x, y, w, h = edge["rect"]
        allowed[int(y * TILE / RES):int((y + h) * TILE / RES), int(x * TILE / RES):int((x + w) * TILE / RES)] = True
    hit = reachable & border & ~allowed
    if hit.any():
        ys, xs = np.nonzero(hit)
        rep.fail(f"{z.id} {tag}: you can walk to the map edge near tile {xs[0] * RES / TILE:.1f},{ys[0] * RES / TILE:.1f} (nothing closes it)")


def check_rooms(z: Zone, rep: Report, tag: str, free, doorway, reachable, void) -> None:
    closed = free & ~doorway & ~void
    lab, n = ndimage.label(closed)
    # doorway groups must separate different rooms
    dl, dn = ndimage.label(doorway)
    for i in range(1, dn + 1):
        cells = ndimage.binary_dilation(dl == i, iterations=3) & ~doorway
        rooms = set(np.unique(lab[cells])) - {0}
        if len(rooms) < 2:
            ys, xs = np.nonzero(dl == i)
            if rooms:
                rep.fail(f"{z.id} {tag}: doorway near tile {xs.min() * RES / TILE:.0f},{ys.min() * RES / TILE:.0f} can be walked around (both sides are the same room)")
            else:
                rep.fail(f"{z.id} {tag}: doorway near tile {xs.min() * RES / TILE:.0f},{ys.min() * RES / TILE:.0f} is blocked on both sides")
    # unreachable floor pockets a tile or bigger
    floor = np.zeros_like(free)
    k = TILE // RES
    for y in range(z.h):
        for x in range(z.w):
            if z.walkable_tile(x, y):
                floor[y * k:(y + 1) * k, x * k:(x + 1) * k] = True
    orphan = free & floor & ~reachable
    ol, on = ndimage.label(orphan)
    for i in range(1, on + 1):
        area = (ol == i).sum() * RES * RES
        if area >= TILE * TILE:
            ys, xs = np.nonzero(ol == i)
            rep.fail(f"{z.id} {tag}: floor area near tile {xs.mean() * RES / TILE:.1f},{ys.mean() * RES / TILE:.1f} ({area // (TILE * TILE)} tiles) cannot be reached")
    rep.note(f"{z.id} {tag}: {n} rooms/areas separated by doorways")


def check_overlaps(z: Zone, rep: Report, tag: str, active: list) -> None:
    solids = [(e, r) for e in active for r in solid_rects(e)]
    for i in range(len(solids)):
        for j in range(i + 1, len(solids)):
            (a, ra), (b, rb) = solids[i], solids[j]
            if a is b or (a.get("fence") and b.get("fence")):
                continue   # fence modules join by overlapping a little
            if overlap(ra, rb) > 0.5:
                rep.fail(f"{z.id} {tag}: solid '{a.get('id', a.get('art'))}' overlaps '{b.get('id', b.get('art'))}'")
    for e, r in solids:
        if e.get("kind") == "npc":
            continue
        x0, y0 = int(r[0] // TILE), int(r[1] // TILE)
        x1, y1 = int((r[0] + r[2] - 0.01) // TILE), int((r[1] + r[3] - 0.01) // TILE)
        for ty in range(y0, y1 + 1):
            for tx in range(x0, x1 + 1):
                if z.tdef(tx, ty).get("solid") and depth(r, (tx * TILE, ty * TILE, TILE, TILE)) > 2:
                    rep.fail(f"{z.id} {tag}: '{e.get('id', e.get('art'))}' is sunk into the wall at tile {tx},{ty}")
        # furniture stands on floor (its feet are on a walkable tile)
        fx, fy = r[0] + r[2] / 2, r[1] + r[3] - 1
        if not e.get("building") and not z.walkable_tile(int(fx // TILE), int(fy // TILE)):
            rep.fail(f"{z.id} {tag}: '{e.get('id', e.get('art'))}' does not stand on the floor (tile {int(fx // TILE)},{int(fy // TILE)})")


def check_reach(z: Zone, rep: Report, tag: str, active: list, reachable: np.ndarray) -> None:
    ys, xs = np.nonzero(reachable)
    if len(xs) == 0:
        return
    fx, fy = xs * RES + RES / 2, ys * RES + RES / 2
    dirs = [(np.cos(a), np.sin(a)) for a in np.linspace(0, 2 * np.pi, 8, endpoint=False)]
    for e in active:
        if e.get("kind") in ("trigger", "enemy"):
            continue
        p = interaction_point(e)
        if not p:
            continue
        px, py, r = p
        near = (np.abs(fx - px) < 80) & (np.abs(fy - py) < 80)
        ok = False
        for dx, dy in dirs:
            cx, cy = fx[near] + dx * INTERACT_REACH, fy[near] - INTERACTOR_LIFT + dy * INTERACT_REACH
            if (np.hypot(cx - px, cy - py) < INTERACTOR_R + r - 2).any():
                ok = True
                break
        if not ok:
            rep.fail(f"{z.id} {tag}: interaction '{e.get('id', e.get('art'))}' cannot be reached from anywhere you can stand")


FLOOR_OK = {"floor"}


def check_placement(z: Zone, rep: Report, tag: str, active: list, flags: dict) -> None:
    ids_active = {e.get("id") for e in active}
    for e in active:
        kind = e.get("kind", "prop")
        if kind != "prop" or not e.get("art"):
            continue
        name = e.get("id", e.get("art"))
        pickup = (e.get("interact") or {}).get("type") == "pickup"
        solid = bool(solid_rects(e))
        on = e.get("on")
        if solid and not pickup:
            continue
        if on is None:
            rep.fail(f"{z.id}: prop '{name}' does not say what it rests on (\"on\")")
            continue
        x, y = position(e)
        if on in ("floor", "ground"):
            decal = e.get("floor", False) or e.get("anchor") == "center"
            if (pickup or not decal) and not e.get("story"):
                rep.fail(f"{z.id}: '{name}' lies loose on the {on} with no story reason (put it on furniture/a shelf, or give \"story\")")
            tx, ty = int(x // TILE), int((y - 1) // TILE)
            if not z.walkable_tile(tx, ty):
                rep.fail(f"{z.id}: '{name}' is on the {on} but its spot (tile {tx},{ty}) is not floor")
        elif on == "wall":
            tx = int(x // TILE)
            if not any(z.face_level(tx, int((y - d) // TILE)) for d in (1, 6, 12)):
                rep.fail(f"{z.id}: '{name}' should hang on a wall but tile {tx},{int((y - 1) // TILE)} is no wall face")
        elif on == "above":
            pass   # ceiling fixtures
        else:
            host = z.by_id.get(on)
            if host is None:
                rep.fail(f"{z.id}: '{name}' rests on unknown entity '{on}'")
                continue
            if on not in ids_active:
                rep.fail(f"{z.id} {tag}: '{name}' is present but its support '{on}' is not (floating)")
                continue
            hr = sprite_rect(host) or (solid_rects(host) or [None])[0]
            if hr is None or not point_in(x, y, hr, 1.0):
                rep.fail(f"{z.id}: '{name}' is supposed to rest on '{on}' but is not on it")


def check_exterior(z: Zone, rep: Report, tag: str, active: list, blocked: np.ndarray) -> None:
    # fences / hedges end against something
    fence_rects = [r for e in active if e.get("fence") for r in solid_rects(e)]
    other = [(e, r) for e in active if not e.get("fence") for r in solid_rects(e)]
    runs: list[list] = []
    for r in fence_rects:
        merged = None
        for run in runs:
            if any(abs(r[1] - q[1]) < 2 and (abs(r[0] - (q[0] + q[2])) < 1.5 or abs(q[0] - (r[0] + r[2])) < 1.5) or
                   abs(r[0] - q[0]) < 2 and (abs(r[1] - (q[1] + q[3])) < 1.5 or abs(q[1] - (r[1] + r[3])) < 1.5) or overlap(r, q) > 0
                   for q in run):
                if merged is None:
                    run.append(r)
                    merged = run
                else:
                    merged.extend(run)
                    run.clear()
        if merged is None:
            runs.append([r])
        runs = [run for run in runs if run]
    W, H = z.w * TILE, z.h * TILE

    open_rects = [tuple(v * TILE for v in edge["rect"]) for edge in z.data.get("open_edges", [])]

    def anchored(px, py) -> bool:
        if px <= 2 or py <= 2 or px >= W - 2 or py >= H - 2:
            return True
        if any(point_in(px, py, r, 4.0) for r in open_rects):
            return True
        if z.tdef(int(px // TILE), int(py // TILE)).get("solid"):
            return True
        return any(point_in(px, py, r, 1.0) for _, r in other) or any(point_in(px, py, r, 1.0) for r in fence_rects if not any(r is q for q in current))

    for current in runs:
        x0 = min(r[0] for r in current)
        x1 = max(r[0] + r[2] for r in current)
        y0 = min(r[1] for r in current)
        y1 = max(r[1] + r[3] for r in current)
        if x1 - x0 >= y1 - y0:
            ends = [(x0 - 1.5, (y0 + y1) / 2), (x1 + 1.5, (y0 + y1) / 2)]
        else:
            ends = [((x0 + x1) / 2, y0 - 1.5), ((x0 + x1) / 2, y1 + 1.5)]
        for px, py in ends:
            if not anchored(px, py):
                rep.fail(f"{z.id} {tag}: fence/hedge run {x0 / TILE:.1f},{y0 / TILE:.1f}-{x1 / TILE:.1f},{y1 / TILE:.1f} ends in mid-air at {px / TILE:.1f},{py / TILE:.1f}")
    # vehicles on road / driveway
    for e in active:
        if not e.get("vehicle"):
            continue
        for r in solid_rects(e):
            pts = [(r[0] + r[2] * fx, r[1] + r[3] * fy) for fx in (0.1, 0.5, 0.9) for fy in (0.2, 0.8)]
            bad = [p for p in pts if not z.tdef(int(p[0] // TILE), int(p[1] // TILE)).get("vehicle_ok")]
            if bad:
                rep.fail(f"{z.id} {tag}: vehicle '{e.get('id', e.get('art'))}' is not on a road or driveway (at tile {bad[0][0] // TILE:.0f},{bad[0][1] // TILE:.0f})")
    # driveways reach the road
    dmask = np.array([[bool(z.tdef(x, y).get("driveway")) for x in range(z.w)] for y in range(z.h)])
    lab, n = ndimage.label(dmask)
    for i in range(1, n + 1):
        ys, xs = np.nonzero(lab == i)
        touches = any(z.tdef(x + dx, y + dy).get("road") for x, y in zip(xs, ys) for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)))
        if not touches:
            rep.fail(f"{z.id}: driveway at {xs.min()},{ys.min()} does not connect to the road")
    # building doors have a paved path to the sidewalk
    for e in active:
        if not e.get("building") or (e.get("interact") or {}).get("type") != "door":
            continue
        px, py, _ = interaction_point(e)
        start = (int(px // TILE), int((py + 40) // TILE))
        seen, stack, found = set(), [start], False
        while stack and not found:
            c = stack.pop()
            if c in seen:
                continue
            seen.add(c)
            d = z.tdef(*c)
            if d.get("sidewalk"):
                found = True
                break
            if d.get("paved") or c == start:
                stack += [(c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)]
        if not found:
            rep.fail(f"{z.id}: the door of '{e.get('id')}' has no paved path to the sidewalk")


def self_test() -> int:
    """Breaks the house on purpose and makes sure each problem is caught."""
    import copy
    base = Zone("house")
    cases = []

    def case(name, mutate, expect):
        z = copy.deepcopy(base)
        mutate(z)
        z.by_id = {e["id"]: e for e in z.entities if "id" in e}
        rep = Report(False)
        check_zone(z, rep)
        hit = any(expect in f for f in rep.fails)
        cases.append((name, hit))

    def wall_gap(z):          # knock a hole in the outer wall next to the front door
        z.cells[20][5] = ""
    def bypass(z):            # a second opening in the kitchen wall makes the kitchen doorway pointless
        for y in (9, 10, 11):
            z.cells[y][22] = "floor_wood"
    def floating_door(z):     # move the front door interaction into the middle of the room
        z.by_id["front_door"]["pos"] = [10, 15]
    def overlap_furniture(z): # push the couch into the TV
        z.by_id["l_couch"]["pos"] = [9, 12]
        z.by_id["l_couch"].pop("offset", None)
    def loose_pickup(z):      # drop the phone pickup on the floor with no reason
        z.by_id["h_phone"]["on"] = "floor"
    def mid_air_wall(z):      # a wall stub standing alone in the living room
        z.cells[15][20] = "wall_living"
    def blocked_room(z):      # a bookcase across the bedroom doorway
        z.entities.append({"id": "blocker", "art": "bookshelf", "pos": [4, 12], "offset": [0, 4], "solid": [60, 30]})

    case("gap in the outer wall", wall_gap, "leaks")
    case("doorway you can walk around", bypass, "walked around")
    case("door floating in a room", floating_door, "floating door")
    case("overlapping furniture", overlap_furniture, "overlaps")
    case("pickup lying loose on the floor", loose_pickup, "loose on the floor")
    case("wall ending in mid-air", mid_air_wall, "mid-air")
    case("furniture blocking a doorway", blocked_room, "cut off")
    ok = True
    for name, hit in cases:
        print(f"[layout] self-test {'caught' if hit else 'MISSED'}: {name}")
        ok &= hit
    print("SELF-TEST PASS" if ok else "SELF-TEST FAIL")
    return 0 if ok else 1


def main() -> int:
    if "--self-test" in sys.argv:
        return self_test()
    args = [a for a in sys.argv[1:] if not a.startswith("-")]
    verbose = "-v" in sys.argv
    zone_ids = args or sorted(p.stem for p in (ROOT / "data/zones").glob("*.json"))
    total = 0
    for zid in zone_ids:
        z = Zone(zid)
        rep = Report(verbose)
        check_zone(z, rep)
        status = "PASS" if not rep.fails else f"FAIL ({len(rep.fails)})"
        print(f"[layout] {zid}: {status}")
        for f in rep.fails:
            print(f"[layout]   FAIL {f}")
        if verbose:
            for n in rep.notes:
                print(f"[layout]   note {n}")
        total += len(rep.fails)
    print("LAYOUT PASS" if total == 0 else f"LAYOUT FAIL: {total} problem(s)")
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
