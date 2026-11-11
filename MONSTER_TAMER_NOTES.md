# MONSTER TAMER (working title) — design notes

An original creature-befriending RPG in the handheld tradition: top-down grid overworld, turn-based battles with a
timing press, and a withered land that heals as you make friends. Godot 4.7, typed GDScript, all art and audio made
by code. Everything here is invented for this game.

## 1. Premise
You are **Rowan**, raised by **Gran Hazel** in the village of **Fernhollow** at the foot of the **Wending Vale**.
For ten years the Vale has been going quiet: colour drains out of the meadows, the river slows to mud, flowers stay
shut. The old folk call it **the Hush**. Wild creatures — **wildkin** — grew wary and hid, and people stopped
walking with them.

Long ago, people and wildkin kept each other: the Vale's heart, the **Wellspring** in the grove above the village,
only runs while the two are bound by trust. Nobody captures a wildkin. You earn its trust, and it chooses to come
along. Each wildkin that joins you wakes a little more of the land.

## 2. World and story (slice)
- **Fernhollow** (town): Gran's cottage, the Mender's hut (healing), Pell's Pantry (shop), a neighbour's house,
  villagers. Gran's garden is grey at the start and blooms at the first heal.
- **Bramble Lane** (route north): tall grass, a dried-up stream with a footbridge, two other tenders who challenge
  you (Juni, your bold neighbour, and Forager Lio). The stream runs again at the first heal.
- **Wellspring Grove**: the heart of the Vale, deeply withered. Brambles block the way to the Wellspring until enough
  wildkin trust you; at the spring itself you wake it (final heal of the slice).
- **Keeper Tamsin** tends the grove. In the intro she brings three lost young wildkin to Fernhollow and asks you to
  take one as your first companion (it chooses you back).

Beats: intro cards (the Hush) → Tamsin and the choice of companion → Gran sends you to the Mender and up the Lane →
first befriending (stream flows, Gran's garden blooms) → three friends (grove flowers return, brambles fall back)
→ wake the Wellspring (the grove turns green, the end of the slice).

## 3. Elements
Five elements, each strong against two and weak against two (a balanced pentagon):

| Attacker → | Bloom | Cinder | Tide | Gale | Stone |
|---|---|---|---|---|---|
| **Bloom** (roots, leaves) | · | ½ | **x1.5** | ½ | **x1.5** |
| **Cinder** (fire, warmth) | **x1.5** | · | ½ | **x1.5** | ½ |
| **Tide** (water, rain) | ½ | **x1.5** | · | ½ | **x1.5** |
| **Gale** (wind, sky) | **x1.5** | ½ | **x1.5** | · | ½ |
| **Stone** (rock, earth) | ½ | **x1.5** | ½ | **x1.5** | · |

Reading: roots drink rivers and split stone; fire burns leaves and feeds on wind; water douses fire and wears
stone; wind scatters seeds and whips waves; stone smothers fire and breaks wind. "½" is x0.67 in play.
Same-element moves get a x1.2 kinship bonus.

## 4. Roster (11 species)
| Creature | Element | Where | Notes |
|---|---|---|---|
| Mossfawn → **Grovehart** | Bloom | starter | fawn with a moss blanket; bond form grows branch antlers in blossom |
| Emberkit → **Hearthfox** | Cinder | starter | fox kit with a flame-tip tail; bond form has an ember ruff |
| Ripplet → **Rivermane** | Tide | starter | otter pup with a droplet curl; bond form has a mane like a stream |
| Thistlehog | Bloom | Lane, grove | hedgehog with thistle-head spines |
| Kindlemoth | Cinder | Lane (evening grass), grove | fuzzy moth with ember-eyed wings |
| Drizzlesnail | Tide | grove | snail carrying its own rain cloud |
| Cobblemole | Stone | Lane | mole in a coat of river stones |
| Puffwren | Gale | Lane, grove | round wren puffed like a dandelion clock |

Each has 4–6 moves (data/moves.json), a front and back battle sprite (80x80), and a 24x24 party icon.

## 5. Battle rules
- Turn-based: choose **Strike** (a move), **Befriend** (wild only), **Bag**, **Team** (switch) or **Run**.
  Faster creature acts first (ties: the player).
- **Timing press**: every attack you make and every attack aimed at you shows a ring shrinking onto a target
  circle. Press Z / Space / click as it lands. *Perfect* = x1.3 damage when attacking, x0.6 taken when defending;
  *Good* = x1.15 / x0.8; a miss is simply normal damage. The window is generous and the press is never required.
- Damage = (power x attack / defense x level factor) x element x kinship x timing, with a small random spread.
- Levels and XP: winning, befriending and good timing give XP; level-ups raise stats from species bases.
- Fainting: a creature at 0 HP must swap; if all faint you wake at the Mender's (coins halved).

## 6. Trust (befriending)
- Wild creatures show a **mood** each turn: Wary, Playful, Hungry or Sleepy. The Trust meter (0–100) fills from:
  - **Calm** (soothing words): best when it is Wary.
  - **Play**: best when it is Playful.
  - **Offer a treat** from the bag: best when Hungry; a treat it *likes* (by species) is worth much more.
  - Gentle actions use the timing press too: a Perfect press gives a bigger gain.
  - Matching the mood gives a large gain, a mismatch a small one; Sleepy creatures barely respond, except to calm.
- **Don't over-hurt it**: hitting a wild creature below 30% HP costs Trust; knocking it out scares it away.
  A creature at around half HP after a fair fight respects you a little (+Trust once).
- At 100 Trust it **chooses to join** (no device, no throw). It becomes the next party member (max 6).
- Trainer creatures already have partners: Befriend is unavailable.

## 7. Bond and bond-evolution
Each creature has **Bond** (0–100): +battles fought together, +good timing, +treats it likes, +walking with you
(steps while leading the party). Starters change form when **Bond ≥ 60 and level ≥ 7** (checked after battle):
Mossfawn → Grovehart, Emberkit → Hearthfox, Ripplet → Rivermane.

## 8. Restoration rules
World **heal stage** is derived from befriended species and story flags (data/restoration.json):
1. First wildkin befriended → Bramble Lane's stream runs, the Lane's south meadow and Gran's garden regain colour.
2. Three wildkin befriended → the grove's outer meadow blooms, the brambles before the Wellspring recede.
3. Wellspring woken (talk to it once stage 2 is reached) → the whole grove heals.
Each map lists heal regions (rectangles with the stage that heals them); terrain and props inside use their
withered twin until then. Healing plays a shimmer and a chime, and the change is visible at once.
