"""The one Monster Tamer palette (64 colours). Every sprite, tile and UI colour comes from here; check_art.py
enforces it and build_art.py mirrors it to game/data/palette.json for the game code.

Ramps run dark -> light. WITHER maps every living colour to its drained twin (used for the withered world)."""
from __future__ import annotations

PALETTE: dict[str, str] = {
    # ink and neutrals (warm plum greys, never pure black)
    "ink": "#241c2e", "ink2": "#3a2f47", "dusk": "#54496a", "mist": "#8a819c", "fog": "#bdb6c8",
    "paper": "#f3ead8", "cream": "#fff8e8",
    # greens
    "leaf0": "#1c3d34", "leaf1": "#2a5c3f", "leaf2": "#3f8048", "leaf3": "#69a952", "leaf4": "#9fcc63",
    "leaf5": "#d2e88e",
    # earth and wood
    "bark0": "#352325", "bark1": "#55362e", "bark2": "#7c5139", "bark3": "#a6744a", "sand1": "#c99e64",
    "sand2": "#e2c48a", "sand3": "#f2e1b0",
    # water and sky
    "deep0": "#1f2d57", "deep1": "#2a4c86", "water2": "#3a7bb5", "water3": "#5fadd6", "water4": "#9fdcea",
    "sky": "#d4f1f2",
    # fire and sun
    "ember0": "#5e1f2d", "ember1": "#9c3530", "ember2": "#d05a35", "ember3": "#ec9145", "ember4": "#f6c35e",
    "sun": "#fbe79a",
    # flowers
    "rose0": "#6e2a4c", "rose1": "#ab4469", "rose2": "#de758f", "rose3": "#f4b0b8",
    # violet
    "plum0": "#3a2b5c", "plum1": "#56418a", "plum2": "#7f66b8", "plum3": "#b5a1e0",
    # stone
    "stone0": "#373848", "stone1": "#545869", "stone2": "#7d8296", "stone3": "#aeb3c2", "stone4": "#d8dce4",
    # teal
    "teal0": "#1b4a4e", "teal1": "#2b7470", "teal2": "#4aa596", "teal3": "#8fd8bf",
    # skin
    "skin0": "#7a4434", "skin1": "#b8714f", "skin2": "#e1a07b", "skin3": "#f6cfa9",
    # withered: dry olive-greys and cracked mud
    "dry0": "#3e3a33", "dry1": "#5f584a", "dry2": "#847b66", "dry3": "#aaa086", "dry4": "#cbc3a9",
    "mud0": "#4a3c33", "mud1": "#6a5747",
}

RAMPS: dict[str, list[str]] = {
    "ink": ["ink", "ink2", "dusk", "mist", "fog", "paper", "cream"],
    "leaf": ["leaf0", "leaf1", "leaf2", "leaf3", "leaf4", "leaf5"],
    "bark": ["bark0", "bark1", "bark2", "bark3", "sand1", "sand2", "sand3"],
    "water": ["deep0", "deep1", "water2", "water3", "water4", "sky"],
    "ember": ["ember0", "ember1", "ember2", "ember3", "ember4", "sun"],
    "rose": ["rose0", "rose1", "rose2", "rose3"],
    "plum": ["plum0", "plum1", "plum2", "plum3"],
    "stone": ["stone0", "stone1", "stone2", "stone3", "stone4"],
    "teal": ["teal0", "teal1", "teal2", "teal3"],
    "skin": ["skin0", "skin1", "skin2", "skin3"],
    "dry": ["dry0", "dry1", "dry2", "dry3", "dry4"],
}

# The drained twin of every living colour: greens to olive-grey, water to mud, petals and fire to dust.
WITHER: dict[str, str] = {
    "leaf0": "dry0", "leaf1": "dry1", "leaf2": "dry1", "leaf3": "dry2", "leaf4": "dry3", "leaf5": "dry4",
    "deep0": "mud0", "deep1": "mud0", "water2": "mud1", "water3": "dry2", "water4": "dry3", "sky": "dry4",
    "ember1": "bark1", "ember2": "bark2", "ember3": "dry2", "ember4": "dry3", "sun": "dry4",
    "rose0": "bark1", "rose1": "dry1", "rose2": "dry2", "rose3": "dry3",
    "plum1": "dry1", "plum2": "dry2", "plum3": "dry3",
    "teal0": "dry0", "teal1": "dry1", "teal2": "dry2", "teal3": "dry3",
    "sand1": "dry2", "sand2": "dry3", "sand3": "dry4",
}


def rgb(name: str) -> tuple[int, int, int, int]:
    """A palette colour as RGBA."""
    h = PALETTE[name]
    return int(h[1:3], 16), int(h[3:5], 16), int(h[5:7], 16), 255


def allowed_rgb() -> set[tuple[int, int, int]]:
    """Every palette colour as an RGB triple (for the art check)."""
    return {rgb(n)[:3] for n in PALETTE}
