# Emberoo v2 hero sheets (Art direction v2)

PixelLab-generated, cleaned by script: every pixel is Apollo (0 off-palette pixels in
every sheet), outline `#090A14`, stray pixels removed, gauntlet cracks recoloured to
bright `#E8C170` / `#DE9E41` so they read on the dark grade-B ground. No rim light.
In the game: `data/hero_forms/` (one `HeroForm` per stage) points at these folders; `HeroFormSwitch` swaps them when the Awakening stage changes.

| Folder | Stage (Awakening) | Look | Canvas (each frame) | Baseline row | Body height |
|---|---|---|---|---|---|
| `stage1/` | joey (stage 0, lv 0) | cloth hand-wraps with a faint ember glow | 64×64 | 58 | ~35 px |
| `stage2/` | Emberoo (stage 1, lv 10) | obsidian gauntlets, glowing cracks | 64×64 | 58 | ~46 px |
| `stage3/` | final (stage 2, lv 25) | flame mane, red sash, magma gauntlets | 96×96 | 82 | ~63 px |

- **Anchor:** within a stage, every frame has the same canvas; the feet stand on the
  baseline row (0-based y, the lowest opaque row of a grounded frame); the idle pose's
  bounding box is centred horizontally and action frames are registered to it on the
  head and chest, so the body doesn't slide when the action changes. So an `AnimatedSprite2D` with
  `centered = true` needs `offset.y = -(baseline - canvas/2) - 1` to put the feet on the node
  (stage 1/2: `-27`, stage 3: `-35`). Airborne hop/dodge frames lift off the baseline; their
  height is baked in, so don't add a second arc in code (or only a small one).
- **Naming:** `emberoo_<view>_<action>_sheet.png`, a horizontal strip of equal square frames,
  exactly like `art/emberoo/`. Views: `front`, `frontdiag`, `side`, `backdiag`, `back`;
  all face right/down-right; the left side is the mirror (as now).
- **Frames per action** (the old counts):

| Action | Frames | Content |
|---|---|---|
| idle | 4 | breathing: base, chest down 1 px, base, chest down 1 px |
| blink | 4 | idle with eyes shut, frame-for-frame (back view: same as idle, no eyes visible) |
| jab | 4 | 0 anticipation (cocked), **1–2 fist fully out (held 2 frames)**, 3 recovery |
| jab2 | 4 | same timing, the other fist (front/back views: the jab mirrored) |
| uppercut | 5 | 0 crouch, 1 rising, **2–3 fist up (held 2 frames)**, 4 recovery |
| dodge | 3 | 0 crouch, 1 backstep in the air, 2 landing |
| hop | 4 | 0 crouch, 1 take-off, 2 air, 3 landing |

  Note for integration: the fist is out from **frame 1** in jab/jab2 (frame 2 in the old
  sheets): the jab is `[0.10, 0.06, 0.10, 0.14]` with the hit as frame 1 starts.

## What exists

| | stage1 | stage2 | stage3 |
|---|---|---|---|
| idle, blink, jab, hop, dodge | all 5 views | all 5 views | all 5 views |
| jab2 | front, back (mirrored jab) | all 5 views | front, back (mirrored jab) |
| uppercut | front, frontdiag, side | all 5 views | front, frontdiag, side |

Missing sheets fall back to the jab sheet (`stand_in_sheet` in `CreatureAnimator.ANIMATION_SETTINGS`), with their own timings.
Stage 2 is complete (35 sheets); stages 1 and 3 have 30 each.

## Known quirks
- Generated poses drift a little from the idle design between actions (e.g. stage 2 side
  jab2 shows the cream belly that the side idle doesn't; stage 1 backdiag jab/hop turn the
  head toward the camera).
- Stage 3 uppercut fist-up frames have a flame arc baked in, and the stage 3 side, frontdiag
  and backdiag jab fists are flat at the tip (the generator's canvas clipped them; closed
  with an outline).
- Stage 2 side jab: the generator dropped the gauntlet on the extended fist; the idle
  gauntlet was stamped back over it.
