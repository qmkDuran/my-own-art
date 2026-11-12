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
  in that arena. The sign under each gate lists things to try there.
- **Difficulty lever** (left, F): Easy / Normal / Hard.
- **Opponent switch** (left, F): a wild creature 1v1, or a trainer 3v3 (the Gate Warden).
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
  - **Status** moves (marked HOLD) are **channelled**: hold the key; the bar under your creature fills (the longer,
    the stronger, up to 100%); release to use it. You can't move or dodge while channelling, and a hit cancels it.
    When a foe channels, hit it.
- **Space** dodges (short, with a cooldown). Moves commit: no dodging during a wind-up or recovery.
- **1 2 3** swap (costs 1 gauge segment, then a 3 s cooldown). The swap-in strikes as it lands.
- **F** syncs (see below). No items in battle.

**What to watch:**
- **Red warnings** show where a foe's attack will land. Easy foes wind up longer; Hard ones less.
- **Elements:** a hit with the element advantage does x1.3 ("Strong hit!") and staggers faster. Nothing is ever
  resisted. Press **I** for a creature's element and what it is strong against.
- **Stagger:** the gold bar under a foe's life fills with hits. Full, it is **STAGGERED**: it reels and takes 50% more.
- **Buffs and debuffs** show as icons with timers over both creatures and on your card. Each buff has a cost:
  Sprint leaves Lethargy behind, Harden is slow and can't dodge, Berserk takes more, Camouflage makes the first hit
  taken a critical. Buffs fade faster when you are hit.
- **Home terrain** (in the info panel): each creature has a bonus somewhere (the honey badger on burning ground,
  the cuttlefish in water, the pangolin on roots and rubble, the wolf in tall grass, the aye-aye on high ground, the
  devil in mud). Each bonus has a cost, and nobody is weaker anywhere else.
- **Terrain your moves change:** Ember burns grass to coals, Gale flattens grass and clears fog, Echo and heavy hits
  break rocks, the bridge and cracked floor, the pangolin's Vine Wall grows cover (Ember burns it).
- **Winning** a wild battle gives XP and materials; a trainer battle is 3v3 (their creatures are the balls at the
  top). **Losing** (your whole team down) ends the battle; on the route you wake at camp and lose one of each material.

## The route
- **Exploring:** left click walks, Space rolls. Your creature follows.
- **Wild creatures never force a fight.** Shy ones flee, calm ones ignore you, territorial ones warn ("!") and calm
  down if you back off, and the rare **aggressive** one (red eye glint) chases you. Walk into one to battle it.
- **Ivo**, a rival trainer, asks "Want to battle?" when you come close: Accept or Decline.
- **Sync Lens:** in a wild battle, weaken a creature (its life under the pink mark: it stops fighting) or stagger
  it, then **hold F**: the scan ring fills and it joins your team (or the Sanctuary at camp) and the battle is won.
  The basic lens only reads common creatures; the aye-aye is rare (switch to Sync Lens+ at the Gate Hall).
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
| **F** | Use the hall object you stand at (lever, switch, station, lens) | Hold to sync a weakened or staggered creature |
| **Z / V** | Honeyberry (heal) / Smelling Salts (revive) | - |
| **I / C / Esc** | Creature info / camp panel (at camp) / close panels | same |
| **F1** | Dev: a shiny | - |

## Things worth telling us
- Did you ever get hit by something you could not see coming? (That is a fairness bug.)
- Do skillshots feel readable, both yours and theirs? Too slow, too fast?
- Is channelling a status move worth the risk?
- Does Easy / Normal / Hard feel like three different opponents?
- Which arena was the most fun, and why?
