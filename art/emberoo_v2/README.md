# Emberoo v2 hero sheets (Art direction v2)

PixelLab-generated, cleaned by script: every pixel is Apollo (0 off-palette pixels in
every sheet), outline `#090A14`, stray pixels removed, gauntlet cracks recoloured to
bright `#E8C170` / `#DE9E41` so they read on the dark grade-B ground. No rim light.
In the game: `data/hero_forms/` (one `HeroForm` per stage) points at these folders; `HeroFormSwitch` swaps them when the Awakening stage changes.

| Folder | Stage (Awakening) | Look | Canvas (each frame) | Baseline row | Body height |
|---|---|---|---|---|---|
| `stage1/` | stage 1 (Awakening 0, lv 0) | cloth hand-wraps with a faint ember glow | 64×64 | 58 | ~35 px |
| `stage2/` | Emberoo (stage 1, lv 10) | obsidian gauntlets, glowing cracks | 64×64 | 58 | ~46 px |
| `stage3/` | final (stage 2, lv 25) | flame mane, red sash, magma gauntlets | 96×96 | 82 | ~63 px |

- **Anchor:** within a stage, every frame has the same canvas; the feet stand on the
  baseline row (0-based y, the lowest opaque row of a grounded frame); the idle pose's
  bounding box is centred horizontally and action frames are registered to it on the
  head and chest, so the body doesn't slide when the action changes. So an `AnimatedSprite2D` with
  `centered = true` needs `offset.y = -(baseline - canvas/2) - 1` to put the feet on the node
  (stage 1/2: `-27`, stage 3: `-35`). Airborne hop/dodge frames lift off the baseline; their
  height is baked in, so don't add a second arc in code (or only a small one). Hop: feet
  6 px then 11 px off the ground on stages 1–2, 8 px then 15 px on stage 3 (frames 1, 2).
- **Naming:** `emberoo_<view>_<action>_sheet.png`, a horizontal strip of equal square frames,
  exactly like `art/emberoo/`. Views: `front`, `frontdiag`, `side`, `backdiag`, `back`;
  all face right/down-right; the left side is the mirror (as now).
- **Frames per action** (the old counts):

| Action | Frames | Content |
|---|---|---|
| idle | 4 | breathing: base, chest down 1 px, base, chest down 1 px |
| blink | 4 | idle with eyes shut, frame-for-frame (back view: same as idle, no eyes visible) |
| jab | 4 | 0 anticipation (cocked), **1–2 fist fully out (held 2 frames)**, 3 recovery |
| jab2 | 4 | same timing, the other fist; the tail, sash and mane stay on their side (not a mirror of the sheet) |
| uppercut | 5 | 0 crouch, 1 rising, **2–3 fist up (held 2 frames)**, 4 recovery |
| dodge | 3 | 0 crouch, 1 backstep in the air, 2 landing |
| hop | 4 | 0 crouch, 1 take-off (stretched), 2 air (legs tucked), 3 landing; the idle pose, so no drift |

  Note for integration: the fist is out from **frame 1** in jab/jab2 (frame 2 in the old
  sheets): the jab is `[0.10, 0.06, 0.10, 0.14]` with the hit as frame 1 starts.

## What exists

All 7 actions in all 5 views for every stage: 35 sheets per stage, 105 in total. No
missing sheets (the `CreatureAnimator` fallbacks `jab2` → `jab`, `uppercut` → `jab` are no
longer needed for these sheets).

## How the frames were made (v2b pass)
- **Stage 1 front jab / jab2**: the fist punches toward the camera (a big foreshortened
  wrapped fist in front of the chest), right fist for jab, left fist for jab2; the tail
  stays on the right. Drawn by script on the idle, not generated.
- **jab2 in stage 1 back, stage 2 front/back, stage 3 front**: the jab with the upper body mirrored about
  the body axis while the legs, tail and sash keep their side. **Stage 3 back jab2** is the
  right fist driven forward-up (away from the camera), taken from the back uppercut's rising
  frame, because the stage 3 back torso is too asymmetric to mirror.
- **Hops (all stages, all views)**: built from the idle pose (crouch, stretch, tuck,
  landing) and lifted, so ears, mane and gauntlets never drift.
- **Stage 3 jabs (side, frontdiag, backdiag) and jab2**: regenerated on a wider canvas,
  so the fists are no longer clipped flat.
- **Stage 3 uppercut**: no flame arc or dust any more (effects are added in code). Front:
  arc removed from the old frames by script; frontdiag, side, backdiag, back: regenerated
  without effects.
- Effect flecks are removed from every generated frame. The stage 3 red sash is unchanged.

## Known quirks
- Stage 1 front jab fist is a small drawn blob (stage 1 is only ~35 px tall); it reads
  as a punch toward the camera, but it's simple.
- Stage 1 backdiag/back uppercut and backdiag jab2: generated poses; in the fist-up frames
  the head tilts up and the ears are smaller than in idle. The raised back-uppercut fist was
  recoloured to the grey wrap.
- Stage 3 front jab/jab2: in the fist-out frames the flame mane is hidden behind the big
  fist (the frames come from the earlier generation).
- Stage 3 back jab is still a hook-like punch to the left of the picture; back jab2 punches
  forward-up with the right fist.
- Stage 2 side jab: the generator dropped the gauntlet on the extended fist; the idle
  gauntlet was stamped back over it. Stage 2 side jab2's cream belly was recoloured to fur.
