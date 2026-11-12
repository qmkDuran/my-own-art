# How to play the creature-trainer demo

A combat test for one question: **is the combat fun and fair?** It starts in the **Gate Hall**, a test hub where
every arena, difficulty and team is one walk away. About 15-20 minutes tries everything.

## Run it (Windows)
1. Clone the repository and check out the `tamer-arpg` branch.
2. Open Godot 4.7.2, choose **Import**, and pick `game/project.godot`.
3. Press **F5** (Run Project). The demo starts in the Gate Hall (no title screen).

The first import takes a minute while Godot builds its cache. Errors about fonts on the very first import go away on
their own.

## The Gate Hall
- **Four gates** along the back wall: **Meadow, Riverbank, Forest, Ruins**. Walk through one and the battle starts
  in that arena. The sign under each gate names its main mechanic and lists things to try there.
- **Difficulty lever** (left, F): Easy / Normal / Hard.
- **Arena size lever** (left, F): medium or large arenas (the camera fits either).
- **Opponent switch** (left, F): a wild creature 1v1, a wild **alpha** (bigger, tougher, better rewards), or a
  trainer 3v3 (the Gate Warden).
- **Team station** (right, F): pick 3 of the 6 creatures (the order is the swap order), a level (5, 15 or 30), and
  each one's 4 moves (click a slot to cycle through the moves it knows; hover for what it does). Closing it makes
  the picks your team.
- **Sync Lens stand** (bottom, F): switch between the basic lens and the upgraded Sync Lens+.
- **The door** (right wall) leads to the route. The arch at the route's start leads back. The hall heals your team.

## Battles
Walk into a wild creature, accept a trainer, or walk through a gate: a black swirl closes and you are in a walled
arena, 1v1, with a fixed camera. Your trainer watches from outside the left wall and is never hurt. Afterwards the
swirl takes you back to the exact spot. On the route your creatures' health carries over between battles; the
Gate Hall and the camp heal.

**You are your creature:**
- **Left click** moves it (hold to keep moving).
- **Right click** is its basic **physical** attack, at the creature under the cursor or a swing toward the cursor
  (hold to keep the combo going). It must be close. Physical hits fill the **gauge** (3 segments under the card).
- **Q W E R** are its 4 moves (icons on the card; hover one for what it does):
  - **Physical** moves are free and fill the gauge.
  - **Special** moves cost gauge (pips on the icon). Hold the key to see where it goes, release to use it. They are
    **skillshots**: they wind up, fly where you aimed, and can miss. Lead moving targets.
  - Every wind-up (yours in gold, the foe's in red) shows on the ground where the move will land.
  - **Status** moves (marked HOLD) are **channelled**: hold the key; the circle at your creature's feet fills (the longer,
    the stronger, up to 100%); release to use it. You can't move or dodge while channelling, and a hit cancels it.
    When a foe channels, hit it.
- **Space** dodges (short, with a cooldown). Moves commit: no dodging during a wind-up or recovery.
- **1 2 3** swap (costs 1 gauge segment, then a 3 s cooldown). The swap-in strikes as it lands.
- **F** syncs (see below). No items in battle.

**What to watch:**
- **Red warnings** show where a foe's attack will land, for exactly as long as its wind-up (the same wind-ups as
  yours). Easy foes react slowly, attack less often and rarely dodge; Hard ones dodge your wind-ups, lead their
  shots, take cover and high ground, **bait** you (step into your range, then dodge the move you commit to),
  **push** you toward walls, rocks and thorns, and burn or flatten your home terrain.
- **Elements:** a hit with the element advantage does x1.3 ("Strong hit!") and staggers faster. Nothing is ever
  resisted. Press **I** for a creature's element and what it is strong against.
- **Stagger:** the gold bar under a foe's life fills with hits. Full, it is **STAGGERED**: it reels and takes 50% more.
- **Buffs and debuffs:** a **gold ring with rising arrows** at a creature's feet is a buff, a **purple ring with
  sinking arrows** a debuff; icons with timers show over both creatures and on your card. One buff and one debuff
  at a time (a new one replaces the old). Each buff has a cost:
  Sprint leaves Lethargy behind, Harden is slow and can't dodge, Berserk takes more, Camouflage makes the first hit
  taken a critical. Buffs fade faster when you are hit.
- **Home terrain** (in the info panel): each creature has a bonus somewhere (the honey badger on burning ground,
  the cuttlefish in water, the pangolin on roots and rubble, the wolf in tall grass, the aye-aye on high ground, the
  devil in mud). Each bonus has a cost, and nobody is weaker anywhere else.
- **Terrain your moves change** (it changes the fight, never ends it; only moves change it, and only a patch):
  Ember sets grass burning; the fire creeps slowly through grass and burns anyone in it (you too), then leaves ash
  and smoke that hide whoever is inside, then a burnt field that slows a little, and the grass regrows after about
  20 s. Gale flattens grass (it regrows) and blows smoke and fog away. Bloom moves regrow grass at once, and the
  pangolin's Vine Wall grows cover (Ember burns it). Echo and heavy hits break a rock into rubble (trips a dash),
  the bridge (whoever is on it falls in) and cracked floor (a pit). Walls, ledges and deep water never break.
- **Bonuses are capped:** element + terrain + buffs add at most +40% damage together.
- **Channelling** shows as a circle filling at the creature's feet.
- **Equal footing:** opponents play by exactly your rules (same stats at the same level, the same moves, wind-ups,
  gauge, swap cost and cooldown, entry strike, no items). Difficulty only changes how smart they are. Each species
  moves in its own style: brawlers walk in, kiters keep their distance, tanks advance slowly and hold, flankers
  circle and strike.
- **Alphas:** rare, bigger, glowing wild creatures with more life and their signature move. A real fight, double
  rewards. One roams the route; the Gate Hall's switch sends one too.
- **Your trainer** calls the swaps and shouts on big moments from the arena edge.
- **Winning** a wild battle gives XP and materials; a trainer battle is 3v3 (their creatures are the balls at the
  top). **Losing** (your whole team down) ends the battle; on the route you wake at camp and lose one of each material.

## The route
- **Exploring:** left click walks, Space rolls. Your creature follows.
- **Wild creatures never force a fight.** Shy ones flee, calm ones ignore you, territorial ones warn ("!") and calm
  down if you back off, and the rare **aggressive** one (red eye glint) chases you. Walk into one to battle it.
- **Quick win:** if your active creature is 8 or more levels above a wild one, walking into it beats it on the
  spot (XP and materials, no arena). Alphas always fight.
- **Ivo**, a rival trainer, asks "Want to battle?" when you come close: Accept or Decline.
- **Sync Lens:** in a wild battle, weaken the creature until **gold stars** show (its life under the pink mark),
  then press **F**: your trainer's lens beam locks on and a 2.5 s scan runs. The creature **struggles** (red-telegraphed
  lunges at your creature): dodge them, because a hit on your creature (or you hitting it) breaks the scan; the
  stars stay and you can retry after a moment. Success: it joins your team (or the Sanctuary at camp) and the
  battle is won. The basic lens only reads common creatures; the aye-aye is rare (switch to Sync Lens+ at the
  Gate Hall, which also scans faster).
- **Camp:** walk into the campfire clearing to rest: everyone is healed, the camp panel opens (C): choose moves,
  raise stats with materials, the Sanctuary. **Z / V** use a Honeyberry or Smelling Salts outside battle.

## Growth
- XP from wins; levels unlock moves (the team station or camp picks the 4 active ones). Each creature's signature
  move unlocks at level 25.
- The **honey badger evolves at 16** into the Ratel Warden (a short ceremony). Try level 15 at the station, then
  win a battle or two, or pick level 30 to start evolved.
- **Shinies** are 1 in 4096. **F1** (dev) sends a shiny into the meadow arena from the Gate Hall, or spawns one next
  to you on the route.

## Controls
| Key | Outside battle (trainer) | In battle (your creature) |
|---|---|---|
| **Left click** | Walk (hold to keep walking) | Move (hold to keep moving) |
| **Right click** | - | Basic physical attack (hold for the combo) |
| **Q W E R** | - | Moves: hold to aim (or channel a status move), release to use |
| **Space** | Roll | Dodge |
| **1 2 3** | Swap creature | Swap (1 gauge, then a cooldown) |
| **F** | Use the hall object you stand at (levers, switch, station, lens) | Sync Lens on a weakened creature (gold stars) |
| **Z / V** | Honeyberry (heal) / Smelling Salts (revive) | - |
| **I / C / Esc** | Creature info / camp panel (at camp) / close panels | same |
| **F1** | Dev: a shiny | - |

## Things worth telling us
- Did you ever get hit by something you could not see coming? (That is a fairness bug.)
- Do skillshots feel readable, both yours and theirs? Too slow, too fast?
- Is channelling a status move worth the risk?
- Does Easy / Normal / Hard feel like three different opponents?
- Which arena was the most fun, and why? Medium or large?
- Did burning, smoke or a broken bridge ever feel unfair, or just change the fight?
