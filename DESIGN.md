# Design Doc

> The project's memory. Claude doesn't remember past sessions, so decisions live here.
> New idea? Check it against this doc first. If it doesn't fit the current milestone, it goes in a parking lot.

## Hook
An ARPG where your starter creature is your class. You're a trainer who sends a creature into the world through a **spirit link** and **fights as it**, with deep skill trees and gems that change how its attacks work.

## Story frame
- **Spirit link:** the trainer stays safe in the hub and guides the creature through a mental bond. This explains why the player directly controls the creature.
- The trainer appears only in the hub/town (story, menus, gems, skills). The creature is alone in the world.

## Story premise
- You pick your starter creature, then you and your trainer **fall through a portal** into another world.
- In this world, creatures have been **hunted almost to extinction**. Humans harvest their ability energy to power their **AI God**.
- A few creatures survive, hiding in the wild. Later, they could **freely join you** as new classes (no capture).
- Humans are the threat. **Your trainer is the exception** and travels with you (moving hub).
- Use our own word for creatures, never "Pokémon". *(Name TBD.)*

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
  - Use ~4–6 colours per creature
  - Darker, muted colours for the world; brighter, saturated colours for creatures, enemies and attacks (readability)
  - No pure black: outlines use `#090A14`; cool darks for world shadows, warm darks (`#241527`, `#341C27`) for the fire creature
- Silhouette first; one consistent light direction

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
- **Handlers:** human trainers serving the AI God. They stay back and send out **waves of ~6 weak bound creatures** (control collars) for a PoE-style power fantasy.
- **Killing the Handler stops new waves.** Creatures already out keep fighting.
- Handlers use a **small fixed roster** of 2–3 bound creature species across the game (saves art).
- Vertical slice: 1 Handler + 1 bound creature type (simple: runs at you and bites).

### Creature #1 (player): Emberoo
- Fire kangaroo boxer. Stage 1 sprite done (16×16): idle (with blink), hop, jab, jab2, dodge in front/side/back.
- Jab: hold to repeat, alternates fists, roots you in place. Dodge: a kangaroo leap that can cancel a jab.

## Elements
- **Vertical slice: flavour only.** Element sets colours, effects and theme; no damage rules.
- **Soon after: status effects.** Each element applies its own effect (fire = burn, toxic = poison over time).
- **No type chart for now.** Revisit only when there are many elements.

### Enemy #1: Toxic Toad (locked)
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
