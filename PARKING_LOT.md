# Parking Lot

Good ideas that don't belong in the current milestone. Check here when a milestone is done.

## Enemies
- **Elite monsters (PoE-style rarity):** e.g. an alpha Toxlop with more health and a faster tongue, one per wave (recoloured/scaled art).
- **Panic summon:** Wardens summon reinforcements instantly when first hit.
- **Berserk overload:** when a Handler dies, remaining bound creatures go berserk (faster, more aggressive, uncoordinated). Needs a clear visual (chip sparks, red flash).
- **Freeing creatures** as a story reward (e.g. rescuing them at a camp), not as a combat shortcut.

- **Poison status** on the hyena bite (after the slice, with the status-effect system).
- **Type chart** (element strengths/weaknesses): only once there are many elements.
- **Tick** and **vulture** enemies.
- **Hyena** as a bigger enemy (e.g. 24×24 canvas, same pixel scale); references in the session scratchpad.

## Emberoo polish
- Redraw side `jab2` (currently reads more like a low body hook).

## Controls & visuals
- **8-direction sprites** (add front-diagonal and back-diagonal views; ~1.7× art). Movement/aim already work at any angle.
- **Gamepad aiming** with the right stick (attacks currently aim at the mouse).

## Trainer
- ~~Trainer walks with Emberoo~~ (built). Still to do: trainer walk/diagonal animations; future story beat where the AI God learns to see the trainer.
- How (and whether) to show the trainer during play: undecided. The HUD portrait was tried and removed; for now Aid tonics are thrown in from off-screen.
- Trainer customisation screen built (scenes/ui/trainer_customizer.tscn); hook into new-game flow later.

## Later systems
- **Creature Log screen (bestiary).** A screen listing every species met (CreatureLog already records them): portrait, name, element, what it does (attacks and status effects, e.g. "tongue lash poisons"), and tips. Unmet species show as silhouettes. Needs per-species text in the creature data (e.g. alongside `CreatureInfo`).
- Capture = new class: surviving creatures freely join you as new playable classes (after 3–4 classes exist).

## Controls
- **Key rebinding:** a Controls screen where players remap every action (saved to user settings). Defaults stay as they are now. The HUD key labels already read from the input map, so they'll follow.
- **Smart move-attack:** while holding left-click to move, auto-jab an enemy that blocks the path within reach (offered, not yet approved).

## Art
- **Emberoo evolution art (done in Art direction v2).** The PixelLab forms in `art/emberoo_v2/` are now the Awakening stages (see DESIGN.md); the notes below are kept from the earlier attempts. About 7 attempts so far (hand-drawn, ChatGPT concept, PixelLab, a hybrid cleanup, chibi, grown-from-base); none hit the bar. What we learned:
  - the original 16px Emberoo is the style anchor (it reads as a kangaroo);
  - HGSS follower bodies are about 14x19, 17x24 and 25x25 with about 14 colours, with one bold signature shape per stage;
  - keep the kangaroo identity first;
  - avoid boxy rectangles: taper the waist, round the shapes, give the pose attitude.
  Options: community critique (r/PixelArt), the user's own skill growing, or a commission once the game earns. Gameplay can use a placeholder until then.
