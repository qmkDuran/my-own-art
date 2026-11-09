# Roadmap

> Read this first when starting a new session. Claude doesn't remember past sessions.
> Rule when lost: find the current milestone below and do the smallest next task.

## Milestone 1: Vertical slice (current)
Goal: one fun zone (Ruins Edge, about 5 min) with real art, a full Stage 1 build, a boss and Emberoo's first Awakening.

| Item | Status |
|---|---|
| Emberoo stage 1 art in 5 views (idle, blink, hop, jab x2, dodge, uppercut) | ✅ |
| Combat feel: jab chain, input buffer, move-cancel, Shift to stand still, forgiving hitboxes | ✅ |
| Enemies: Toxlop (swarm), Warden (summoner), Zephoot (wind, ranged), Gruntite (stone, charger) | ✅ |
| XP motes, levelling (start at level 0, curve to cap 50), crits, damage numbers | ✅ |
| Heat resource + skills: Flame Uppercut (E), Spinning Hook (jab, jab, spin), Searing Jab burn | ✅ |
| Ember Tree: radial tree, exact before → after numbers, stats panel, icon set, tree-gated skills | ✅ |
| HUD (Last Epoch style, trainer in the bar), Monogram font, HUD juice | ✅ |
| First zone: Ruins Edge (own tileset, 7 areas), zone entrance hop | ✅ |
| Bruiser branch + remaining Stage 1 nodes (Ash Guard on W, Counter Punch, Unshakable, Wildfire, Ember Hop) | 🔄 in progress |
| Mini-boss: Warden Captain in the Final Arena | 🔄 in progress |
| Save system | 🔄 in progress |
| Awakening (replaces evolution): level 10 Awakening I "Blue Flame" (recolour, blue fire, +3 health/+1 jab, opens tree Stage 2), Awakening II planned at 25, awakening moment, saved, F4 debug | ✅ |
| Enemy pathfinding (they get stuck on walls) | ⬜ |
| Zone travel (ZoneExit / ZoneEntry, fade, entry = checkpoint, saved zone) and story flags (saved) | ✅ |
| Arrival fight: Hometown Outskirts (Warden raid, barricade opens), the game's start | ✅ first pass |
| Hub: Hometown (town tileset, NPCs with dialogue, Tinkerer gives the Link Rod: C gated until then) | ✅ first pass |
| Zone 2 Mirelight Fen (own tileset, loop, 3 pockets, shard, Dredge Foreman mini-event) | ✅ first pass |
| Zone 3 Shockwire Quarry (own tileset, loop, 2 pockets, shard, Bull Pit with a placeholder boss) | ✅ first pass |
| Real mid-act boss for the Bull Pit (replaces the elite-Gruntite "Quarry Bull") | ⬜ |
| Trainer final design (waiting on user references) | ⬜ |
| Music and sound (waiting on user's packs) | ⬜ |

## Where we left off (2026-11-08)
- Huge session: the slice is mostly built. See the table above.
- Decisions today: 480x270 resolution, no night lighting, no capture device or collars (implanted chips),
  8 elements (Fire, Toxic, Wind, Stone, Tide, Frost, Spark, Bloom), 6 acts of about 1-1.5h, Last Epoch-light story.
- Next: finish the in-progress rows, then pathfinding.
- 2026-11-09: the user chose **Awakening** over evolution art (see DESIGN.md, Build system). Evolution art is parked.
  The Stage 2 ring now opens at Awakening I, but its skill nodes (Meteor Fist, Blur Step, Molten Armour) are not built yet.

- 2026-11-09: zones 2 (Mirelight Fen) and 3 (Shockwire Quarry) built from scratch with their own tilesets (see DESIGN.md, Zones). Next for them: playtest the timing and XP (target level ~9 after the quarry), a real mid-act boss, zone 4.

- 2026-11-09: the arrival and the hub are in: a new game lands in the Hometown Outskirts mid-raid, then the hub (Hometown) with the Tinkerer, Elder Bram, Pip, the gate guard and a merchant; zones link through ZoneExit/ZoneEntry (Outskirts ↔ Hometown ↔ Ruins Edge ↔ zone 2). Next for them: the intro (home world and the portal) before the outskirts, more hub life (the trainer shown in town, shops?), sound.

## Later milestones (rough)
2. Act 1 (demo, about 1-1.5h): more zones, a hub town with NPCs, a light story
3. Intro (home world) and starter choice, once there are 3 playable Glimra
4. Demo for Steam (store page, wishlists)
