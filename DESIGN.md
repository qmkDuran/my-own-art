# Design Doc

> The project's memory. Claude doesn't remember past sessions, so decisions live here.
> New idea? Check it against this doc first. If it doesn't fit the current milestone, it goes in a parking lot.

## Hook
An ARPG where your starter creature is your class. You're a trainer who sends a creature into the world through a **spirit link** and **fights as it**, with deep skill trees and gems that change how its attacks work.

## Story frame
- **Spirit link:** the trainer stays safe in the hub and guides the creature through a mental bond. This explains why the player directly controls the creature.
- In the field, the trainer is part of the HUD: they stand in the skill bar (between W and E), watching Emberoo from behind during fights, and turn to face the camera after a few calm seconds. They shout each skill command (small tick lines). In towns they appear fully.

## Story premise
- **Glimra** (*GLIM-rah*) is the name for the creatures: beings that carry a living light inside them (it "glimmers"). Emberoo is a Glimra.
- **Two worlds:**
  - **The home world** (our own original world, never a real franchise's): bright and hopeful; people and Glimra live as partners.
  - **The portal world** (dark): the trainer and Emberoo fall through a portal into it. Here Glimra have been hunted almost to extinction; humans drain their light to power and feed their **AI God**.
- **Two words for the same creatures:** the trainer calls them **Glimra**; the Wardens call them **"stock"**. (e.g. *"Fresh stock. Drain it."* vs *"He's not stock. He's my Glimra."*)
- Warden visors are tuned to see Glimra light; the trainer has no light of their own, so the visors can't see them (supports the parked "trainer walks with you" idea).
- A few Glimra survive, hiding in the wild; later they could **freely join you** as new classes (no capture).
- Humans are the threat. **Your trainer is the exception.**
- **Names to avoid:** *Lumari* (a funded studio's creature-collector game), *Lunari* (a League of Legends faction). Final names still need a formal trademark check (USPTO/EUIPO) before the game is announced.

## The trainer (in the world)
- The trainer **walks with Emberoo**, a few steps behind. Enemies ignore them (Warden visors only see Glimra light).
- Original look: brown coat, cream shirt, **orange scarf matching Emberoo**, satchel. 18×28 sprite, front view for now (walk/diagonal animations later).
- **Trainer's Aid (F):** the trainer throws a healing tonic that arcs to Emberoo (+4 health). **3 charges**; can't be used at full health.
- **Berries:** toads sometimes drop a glowing berry (25%); walking over it refills one Aid charge (it waits if Aid is full).

## Drops and progression resources
- **Light motes (almost every kill):** the stolen light bursts out of defeated bound Glimra and flies to Emberoo = **XP**. *(Next to build.)*
- **Berries (sometimes):** refill Trainer's Aid charges.
- **No loot.** No gear piles, no inventory clutter.
- **Glimmer Shards (hand-placed, ~15–20 per game):** rewards from bosses, exploration and story moments, never random drops. First one after the first boss (~1 hour in). Socket into skills to change how they behave (never add a new element). 1 slot per skill, +1 per evolution. Free to swap outside combat.
- **Heat** (Emberoo's resource): built by landing jabs, spent by skills, cools off out of combat. Shown as fire pips beside the heart.

## Build system (locked)
- **Levelling:** a small automatic stat boost (the "ding") + **1 skill point** per level. **Evolution:** a big power jump + a new tree ring + another shard slot.
- **Ember Tree:** small (fits on one screen) with **2–3 labelled branches** (e.g. Inferno = burn, Flurry = speed/combos, Bruiser = tanky). Players can mix freely.
- Nodes should **change how you play**, not just add small percentages. Keep to ~5 clear stats (Health, Power, Speed, Heat, Burn).
- **Respec free or nearly free.** 1–2 optional "build starter" suggestions per creature.
- Lessons from research: PoE 2's huge tree overwhelms; Diablo 4's early tree felt shallow (gear decided builds) and its 2026 rework moved to skill variants that change behaviour; Last Epoch's per-skill trees + cheap respec are loved.

## Structure and story
- **Campaign ARPG** structure (like Grim Dawn / Diablo 4): story split into **acts**; each act is a region of **hand-made zones**. No roguelite randomised runs.
- **Moving hub:** the trainer journeys town to town / camp to camp; each act has a new hub.
- Story told mostly **in the hub** via short dialogue. No cutscenes.
- Journey-style story: a region to cross, a rival, powerful figures to beat, a villain group (original setting and characters).
- **Tone: dark themes, not graphic content.** Loss, war, corruption, moral grey areas. No gore.
- Scope: ~1 act for the demo, ~3 acts for the full game.
- Write the story **after** the vertical slice is fun.

## Platform
- Engine: Godot
- Release: Steam (PC)
- Team: solo developer (first game; full-time software dev)
- Pace: ~20 hours/week, sustainable over years

## Art
- 2D pixel art, made by the developer in Aseprite (studying *Pixel Logic*)
- Tiles and world: 16×16
- Creature size grows with evolution: stage 1 = 16×16, stage 2 ≈ 24×24, stage 3 = 32×32
- **Palette: Apollo** (46 colours, Lospec), chosen for its dark tone and clear ramps. Swappable later via Aseprite colour remap.
  - **Every colour we pick comes from Apollo**: art files *and* colours set in code (UI, particles, effects). Checked by script: all art is 100% Apollo; code colours snapped to Apollo.
  - On screen, transparency, fades and glow blend Apollo colours into in-between shades; that's expected and fine.
  - Use ~4–6 colours per creature
  - Darker, muted colours for the world; brighter, saturated colours for creatures, enemies and attacks (readability)
  - No pure black: outlines use `#090A14`; cool darks for world shadows, warm darks (`#241527`, `#341C27`) for the fire creature
- Silhouette first; one consistent light direction
- **No night/dark lighting.** Tried a dark tint + 2D point lights; rejected (the banded light rings looked bad). Keep the world bright.

## Combat
- Real-time, 2D
- The player directly controls the creature they send out

## Starter selection
- **No catching.** At the start, the player picks a starter creature, which is their class.
- Catching was cut for scope.

## Classes and creatures
- **One creature line per element.** Each line is its own class with its own element, playstyle and skill tree.
- **No dual masteries / class mixing.**
- Build **one creature first**; add the next only when the first is fun.

### Creature #1: Fire
- Melee brawler: fast claw combos
- Hits stack **burn** on enemies

## Enemies
- **All enemies are front view only for now** (always face the camera), to keep art small.
- **Handlers don't attack.** Early-game grunts: they keep their distance, back away when approached, and summon. ~5–6 jabs to kill.
- Handler sprite: **18×24** (humans use taller canvases at the same pixel size; never scale sprites in-game). Holds a **control rod** that signals the creatures' control collars; its tip flares when summoning.
- Handler look: hooded servant of the AI God, dark navy coat, shadowed face with a glowing cyan visor slit, cyan trim, control rod with a glowing tip.
- **Handlers (called Wardens in-game):** human trainers serving the AI God. They stay back and send out **waves of ~6 weak bound creatures that die in one hit** (control collars) for a PoE-style power fantasy.
- **Killing the Handler stops new waves.** Creatures already out keep fighting.
- Handlers use a **small fixed roster** of 2–3 bound creature species across the game (saves art).
- Vertical slice: 1 Handler + 1 bound creature type (simple: runs at you and bites).

### Creature #1 (player): Emberoo
- Fire kangaroo boxer. Stage 1 sprite done (16×16): idle (with blink), hop, jab, jab2, dodge in front/side/back.
- Jab: hold to repeat, alternates fists, roots you in place. Dodge: a kangaroo leap that can cancel a jab.
- **Skills on Q/W/E/R** (the skill bar), paid with Heat. **Flame Uppercut (E):** 3 Heat, 2s cooldown; a rising punch that bursts into a ~100° arc of flame (~26px), 3 damage + strong knockback to everything in it. Roots you; the dodge can cancel only its wind-up. Q, W and R are empty for now.
- **Controls:** mouse is the main control; arrow keys also move (no WASD, since W is a skill key). Space = dodge, F = Trainer's Aid.

## Naming
- Creature names blend **[element/trait] + [animal/sound]** into 2–3 fun syllables (e.g. **Emberoo**, **Toxlop**); evolutions get heavier names.
- Every name must be original and checked (web + later USPTO/EUIPO) before use.
- Names in use: **Glimra** (the creatures), **Emberoo** (player, fire kangaroo), **Toxlop** (toxic toad), **Wardens** (the Handlers; fine for enemies, not as a game title).

## HUD
- **Health: one heart** at the bottom-centre, filled with red that drains from the top down as health is lost, with the numbers beside it (e.g. 7/10) in a tiny pixel font.
- **Enemy health:** Wardens show a small bar once hit; one-hit mobs show none.
- **Ability hotbar (later, with the skill tree):** a row of skill slots at the bottom-centre beside the heart and Heat pips, with key labels and cooldown overlays.
- **No mana yet.** When skills arrive, Emberoo's resource is **Heat**, gained by landing hits and spent on fire skills, shown as **fire pips** next to the heart. Each element class gets its own resource.

## Skill tree presentation
- **Radial "Ember Tree":** Emberoo's live idle animation sits at the centre; the tree grows outward in rings. Inner ring = stage 1, middle ring opens at the stage 2 evolution, outer ring (Ultimates) at stage 3.
- Skills are diamond **embers**, stat picks are round **coals**; learned nodes glow, available ones are outlined, locked ones are cold coal. Learned paths are **flame veins**; learning a node sends fire along the vein.
- Same rules underneath as before (skill → Enhanced → choose 1 of 2; stat nodes between).
- Each element's tree has its own motif (fire veins for Emberoo; e.g. glowing mycelium for toxic).
- UI is **hybrid**: pixel-art icons and frames, text rendered at higher resolution for readability.
- **Premium polish checklist:** eased motion everywhere (no popping), 2D glow on bright pixels, a unique hand-drawn icon per skill, one good licensed pixel font, a custom 9-slice frame, generous spacing, sound for hover/learn/unlock, consistent style across all screens.
- Mockups: radial ember tree and column tree (session scratchpad; regenerate if needed).

## Visual hierarchy (applies to every enemy)
Brightest and busiest first: **player** > **danger cues** (attack tells, projectiles) > **elites/bosses** (auras, glows) > **trash mobs** (readable but quiet) > **world**.
- Trash mobs get no ambient particles; their monster feel comes from design (silhouette, one signature feature, expression).
- Trash effects only on **events**: e.g. Toxlop's toxic splat on death and droplets on its tongue lash.
- Ambient auras are reserved for elites, so an aura means "this one's dangerous".

## Elements
- **Vertical slice: flavour only.** Element sets colours, effects and theme; no damage rules.
- **Soon after: status effects.** Each element applies its own effect (fire = burn, toxic = poison over time).
- **No type chart for now.** Revisit only when there are many elements.

### Enemy #1: Toxlop, the toxic toad (locked)
- Purple toad with toxic green warts, yellow eyes; 16×16, sprite in `art/toxic_toad/`.
- **Front view only:** always faces the camera and hops in any direction (like a slime), so one view covers everything.
- Animations: idle 2, hop 4 (code lifts it in an arc with a ground shadow), attack 3 (mouth opens; the tongue is drawn in code toward the target).
- Hurt/death via shader flash and fade.
- Hyena was dropped as the first enemy (four-legged side view too hard at 16px); it may return later as a bigger enemy.
- Later enemies, one at a time: tick (drains energy), vulture (circles then dives).

## Progression
- Levelling + evolutions + skill trees
- Skill tree inspiration: Grim Dawn, PoE 2, Last Epoch, Diablo 4
  - Leaning toward D4-style skill tiers + "pick one of two" modifier choices
  - Stat-choice nodes are welcome
  - Keep trees small: dozens of nodes, not hundreds. Depth from combinations, not quantity.
- **Gems instead of loot:** gems change how attacks work and carry the build-crafting (the role gear plays in D4). No traditional loot system for now.

## Scope rules
- Vertical slice first, placeholder art allowed: 1 creature, 1 enemy type, XP/levelling, 1 evolution, 1 small skill tree (3–5 nodes).
- If it isn't fun with boxes, better art won't fix it.

## Code rules
- **Throwaway code goes.** A mockup, demo or prototype is deleted as soon as the real thing replaces it (git keeps the history).
- **One responsibility per file.** Aim for under ~200 lines; past that, split it into components or helpers.
- **Readable names.** Say what a thing is or does (`move_direction`, not `dir`); no unexplained magic numbers.
- **Colours only from the shared Apollo palette** (`scripts/ui/apollo_palette.gd`, `ApolloPalette`). Never a raw `Color(...)` value in a script; screen-specific roles (e.g. `EmberTreePalette`) are built from it.
- **Components over big classes.** A creature or enemy is a thin coordinator; each job (input, click orders, summoning, a shove, drops on death) lives in its own child node or helper.

## Open questions
- Core gameplay loop: draft is hub → link into zone → fight → XP + gems → hub to spend → harder zone → evolve
- How evolution is triggered and how it ties to the skill tree
- Gem system details

## Reference games
- **Monster Sanctuary:** per-monster skill trees, near-solo dev (turn-based)
- **Creature Keeper:** real-time creature-taming ARPG
- **Adore:** action roguelite, summon and control creatures
- **Hades:** melee game feel
- **Last Epoch / Grim Dawn / Diablo 4:** skill trees
