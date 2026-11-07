# Design Doc

> The project's memory. Claude doesn't remember past sessions, so decisions live here.
> New idea? Check it against this doc first. If it doesn't fit the current milestone, it goes in a parking lot.

## Hook
A creature collector built like an ARPG. You're a trainer who sends a creature into battle and **fights as it**, with deep skill trees and gems that change how its attacks work.

## Platform
- Engine: Godot
- Release: Steam (PC)
- Team: solo developer (first game; full-time software dev)
- Pace: ~20 hours/week, sustainable over years

## Art
- 2D pixel art, made by the developer in Aseprite (studying *Pixel Logic*)
- Tiles and world: 16×16
- Creature size grows with evolution: stage 1 = 16×16, stage 2 ≈ 24×24, stage 3 = 32×32
- Use a limited, existing palette (e.g. from Lospec)
- Silhouette first; one consistent light direction

## Combat
- Real-time, 2D
- The player directly controls the creature they send out

## Classes and creatures
- **One creature line per element.** Each line is its own class with its own element, playstyle and skill tree.
- **No dual masteries / class mixing.**
- Build **one creature first**; add the next only when the first is fun.

### Creature #1: Fire
- Melee brawler: fast claw combos
- Hits stack **burn** on enemies

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
- Core gameplay loop (what does a session look like?)
- How catching works
- How evolution is triggered and how it ties to the skill tree
- Gem system details

## Reference games
- **Monster Sanctuary:** per-monster skill trees, near-solo dev (turn-based)
- **Creature Keeper:** real-time creature-taming ARPG
- **Adore:** action roguelite, summon and control creatures
- **Hades:** melee game feel
- **Last Epoch / Grim Dawn / Diablo 4:** skill trees
