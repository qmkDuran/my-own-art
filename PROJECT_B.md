# Project B: Team Glimra (design doc)

> A second direction for the same world as Project A (DESIGN.md): same story start, same art
> rules (Apollo palette, 16×16 creatures), same code rules. Different structure: instead of one
> creature with a deep skill tree, you build a **team** and **swap mid-fight**.
> This doc is the memory for Project B. Check new ideas against it first.

## Hook
**Free them, team up, chain them.** You fight as a team of up to three Glimra you have freed
from the AI God's control chips and swap between them mid-fight. Each creature has a few
moves that are easy to read. The fun is in **chaining** them: one creature sets the enemy up,
the next one swaps in and cashes it in for a big, flashy finisher.

## World and story (shared with Project A)
- Same premise: the trainer and Emberoo (a fire kangaroo) fall into the dark portal world. There
  an **AI God** drains Glimra light, and its **Wardens** bind Glimra with **control chips**.
- What's different: the chips are now a **game mechanic**. You can break a beaten creature's chip
  and **unbind** it, and a freed Glimra may choose to join you. This fits the theme: you don't
  catch creatures, you free them.
- The trainer still stays unseen in the field and guides the team through the spirit link. The
  **Link Rod** (the hacked Warden rod from Project A's story) is the tool that unbinds.

## Core loop
1. Enter a zone (we reuse Project A's maps: Ruins Edge first).
2. Fight packs of chipped Glimra and Wardens with your team of 3, swapping to chain set-ups into finishers.
3. Sometimes a defeated creature's chip **cracks**. Unbind it to add it to your roster (optional).
4. Earn **XP** (light motes) and **upgrade materials**, then rank up the same few abilities of the creatures you like.
5. Try new team combinations for new chains. Go deeper into harder zones and bosses.

**No loot.** No gear, no inventory grid. **The creatures are the loot:** finding and unbinding
new ones is how your playstyle and your chains change.

## Team and swap rules
- **Team size:** 3 on the field roster (keys **1/2/3**). Later you could keep up to 6 in the
  team, picking 3 before a zone, plus a reserve kept at the hub. The prototype has 3.
- **One creature on the field at a time.** The others are benched. Benched creatures are frozen:
  no regeneration, and their cooldowns and status effects wait.
- **Swapping:** press 1/2/3. The outgoing creature vanishes in a white flash, and the incoming
  one appears **at the same spot** with a burst in its element colour.
  - **Swap cooldown 1.5 s** (tunable: `Party.swap_cooldown`), so swapping is a rhythm, not spam.
  - **Entrance shield:** the incoming creature can't be hurt for about 8 frames (0.14 s). A
    well-timed swap can dodge a hit.
  - **Own health per creature.** A defeated creature can't be swapped in. When the active one
    falls, the next creature still standing jumps in at once. When all have fallen, you restart
    (later: at the checkpoint).
- **Outgoing creatures finish their move:** a creature swapped out right after a skill leaves
  its lingering hazard behind (e.g. Toxlop's puddle keeps poisoning). Later: a creature swapped
  out mid-skill finishes it off-field.

## Ability model: how many abilities?
**User question: "2 or 3 abilities?"** **Our answer: 3 active abilities per creature, plus 1
passive trait, plus the swap moves (Intro and Outro), which fire on their own.**

| Slot | Key | What it is |
|---|---|---|
| Basic attack | right mouse / Shift+left / click an enemy (also Q) | spammable, defines the role (melee jab, tongue, orb) |
| Skill | W | short cooldown (4–6 s), usually **applies a status** (the set-up) |
| Signature | E | long cooldown, the big flashy move, the main thing awakening upgrades |
| Passive trait | none | one rule that makes the creature feel different (e.g. "Toxlop's poison lasts longer") |
| Outro / Intro | the swap itself | the set-up a creature leaves as it goes out / the finisher it does as it comes in |

Why 3 and not 2:
- **With 2,** a creature is a basic attack plus one button. With three on the team that's only
  three real decisions per fight, and swapping becomes the only depth.
- **With 3,** each creature can do **set-up (skill), payoff (signature) and its role (basic)** on its
  own, so it still plays well alone, and swapping adds depth on top instead of being required.
- **More than 3** (a skill tree's worth) is Project A's design. It multiplies art, balance and
  UI per creature, and that doesn't scale to a roster.
- The passive trait and the swap moves cost almost no art and no keys, but they give each
  creature its identity in a team.

### Upgrades (slow, in place)
- Levelling never adds new abilities. It **upgrades the same 3**: each ability has **ranks 1–5**,
  bought with XP-gated upgrade materials.
  - Ranks 2 and 4 add numbers (damage, area, duration, a shorter cooldown).
  - Ranks 3 and 5 add an **extra effect** (e.g. Tongue Lash rank 3 pulls the enemy in; Gust Shot
    rank 5 pierces).
- Upgrades come **slowly**: roughly one rank-up per zone cleared at first.
- **Avoid the grind** (a lesson from gacha party games): few material types, guaranteed progress
  from repeat content (no low-chance drops for upgrades), no stamina or energy gates, no
  gear.

### Awoken forms (no evolutions)
- No evolution lines (they triple the art). Instead, at a high level (proposal: level 30, with all
  three abilities at rank 3 or higher), a creature **awakens**:
  - **Look:** a glow and a palette shift (an Apollo colour remap through the existing
    `scripts/shaders/palette_swap.gdshader`, plus a soft aura). No new sprites needed.
  - **Power:** its **signature is upgraded** into an awoken version (bigger, plus a new effect),
    and its Intro gets stronger.
- This works differently from Project A, where evolution is a new body plus a new tree ring.

## Recruiting: Unbinding (design only, not built yet)
- **No thrown capture device of any kind.** The creature is freed and *chooses* you.
- **Chip cracks:** when a chipped Glimra is defeated, there's a **chance its chip cracks**
  instead of it fainting. It slumps **dazed**, with cracked-chip sparks (reuse `ChipSparkBurst`)
  and a clear marker above it.
  - Base chance: about 15%. It rises to about 40% once **the Warden controlling it** is defeated
    (this rewards "take out the Warden first"). Elites and bosses are scripted.
- **Unbinding is the player's choice:** walk up and **hold the interact key** to channel the Link
  Rod for **1.5–2 s**. Other enemies can interrupt it (a hit cancels it), so clear the area first.
  - **Success:** the chip shatters and the creature joins your team (or the hub reserve if the team is full).
  - **Ignore it:** after about 8 s it wakes up and runs off, free (no penalty).
- **Optional and opt-in.** Never needed to progress: every story fight can be won with the starter
  team.
- **Duplicates:** unbinding a species you already have gives **chip fragments** for that species.
  Fragments are that creature's upgrade material, so repeats are always useful.
- **Shiny chips are RARE:** each repeat unbind of a species you own has a **1.5% chance**
  (one tunable: `SHINY_CHIP_CHANCE`) to drop a **shiny chip**, which turns that creature into
  its shiny variant (cosmetic only: an Apollo palette swap). **Pity:** guaranteed at the
  **60th** repeat unbind of that species without one (`SHINY_PITY_UNBINDS`), so it's never
  hopeless.

## Chaining: the core combat hook
Party games where characters set each other up are the inspiration. In our terms:

### 1. Statuses are set-ups (shared by everyone)
A creature's skill or Outro puts a **status** on enemies. Any teammate can cash in any status,
so team-building means **pairing appliers with finishers**.

| Status | Element | Applied by (starter) | Looks like |
|---|---|---|---|
| Launched | Wind | Zephoot's Outro (built), Updraft Dash | enemy floats up with a wind swirl |
| Poisoned | Toxic | Toxlop's tongue and puddle (built) | green pulse, green ticks |
| Burning | Fire | Emberoo's Searing Jab (Project A) | embers, orange ticks |
| Staggered / Break | Stone | Gruntite's Charge Ram | stone tint, can't act |

### 2. Outro and Intro (swap combos)
- **Outro:** when a creature is swapped out, it leaves a set-up where it stood (e.g. Zephoot
  launches nearby enemies; Toxlop leaves a poison mark).
- **Intro:** the incoming creature's entrance attack. When its set-up is present, it **cashes it
  in** for a big finisher (e.g. Emberoo's flaming uppercut on Launched enemies).
- **Armed state:** whenever an Intro would cash in right now, that teammate's **HUD card glows**
  in its element colour. Pressing its key is the payoff. This rewards timing (swapping into
  the status window), not mashing.

### 3. Element reactions (any applier, any finisher)
| Status on the enemy | + Finisher element | Reaction |
|---|---|---|
| Poisoned (Toxic) | Fire | **Toxic Blaze:** the poison detonates; area damage, burn spreads |
| Launched (Wind) | Fire | **Firestorm:** a flame vortex spreads Burning to every enemy nearby |
| Launched (Wind) | Stone | **Crash Down:** slammed into the ground; big damage + Break |
| Poisoned (Toxic) | Wind | **Miasma:** the poison becomes a drifting cloud, spreading poison |
| Burning (Fire) | Stone | **Molten:** armour melts; the target takes +50% damage for 4 s |
| Poisoned (Toxic) | Stone | **Corrode:** Break lasts twice as long |
| Staggered (Stone) | Wind | **Shatter Gust:** knocked far back, hits enemies it flies into |

Later elements add their own rows. Keep each reaction to **one clear sentence**.

### 4. The Link meter
- A meter on the HUD fills from hits landed (faster from status hits). It has **3 segments**.
- An Outro/Intro chain **costs 1 segment**. Without a segment, a swap is a plain swap, so the
  rhythm is "build, chain, build".
- **Full meter + a reaction lands = finisher slow-mo:** 0.3× speed for about 20 frames.
- Prototype: no meter yet. The one chain is always available (see "Prototype").

## Flashy combat (feel targets)
Project B leans more toward spectacle than Project A. Targets at 480×270:
- **Hit-stop:** 2–4 frames on normal hits, **6–10 frames on Intro and reaction hits** (built for
  the Intro: `HitStop`, 0.09 s).
- **Hit flash:** the target flashes white for 1–2 frames (`HitFlash` exists).
- **Screen shake:** 1–3 px, fading. More than 4 px is noise at this resolution.
- **Big hits** get one impact frame (a screen flash or silhouette; built as `ScreenFlash`) and
  a large 2–3 frame hit spark, **one accent colour per element**.
- **Intro entrance:** a 4–6 frame entrance pose with a dust ring.
- **Real gaps between attacks** (recovery frames, cooldowns), so the game isn't mashy.

## Elements (recommend 8, room for 10)
More elements means more reactions to design and balance (every pair can react). **8** keeps
the reaction table readable; 2 more are saved for the story's late game.

| Element | Colour (Apollo) | Status it applies | Role it leans to |
|---|---|---|---|
| Fire | orange | Burning | brawler, finisher |
| Toxic | green light | Poisoned | applier, zone control |
| Wind | sky light | Launched | ranged, set-up |
| Stone | cork | Staggered / Break | tank |
| Water | sky | Soaked (slow; heals the team on reactions) | healer |
| Spark | gold | Shocked (chains between enemies) | fast skirmisher |
| Flora | green | Rooted | controller |
| Frost | silver | Chilled (slowed, then frozen) | controller, ranged |
| *Light (late)* | cream | Revealed (crits) | support; it's what the AI God steals |
| *Shadow (late)* | magenta | Marked | assassin; the AI God's corrupted Glimra |

Colours live in `scripts/party/element_colors.gd` (all from `ApolloPalette`).

## Roles
- **Brawler:** melee damage, the usual finisher (Emberoo).
- **Ranged:** safe chip damage, sets up from afar (Zephoot).
- **Applier / Support:** spreads statuses, area denial (Toxlop).
- **Tank:** guards, taunts, breaks armour (Gruntite).
- **Healer:** sustains the team, mostly through reactions (no plain heal-bot).
- **Controller:** roots, slows, groups enemies up for others.
A good team of 3 = one applier + one finisher + one flex (tank, healer or controller).

## Starter roster proposal (10)
Existing art first. *New names still need a trademark check before announcing.*

| Creature | Element | Role | Basic / Skill / Signature (+ Outro, Intro) | Art |
|---|---|---|---|---|
| **Emberoo** | Fire | Brawler | Jab combo / Ash Guard / Flame Uppercut; Intro: uppercut on Launched (built) | exists (5 views) |
| **Toxlop** | Toxic | Applier | Tongue Lash (poisons) / Poison Puddle / Leap Slam; Outro: poison mark | exists (front) |
| **Zephoot** | Wind | Ranged | Gust Shot / Gale Push (cone knockback) / Updraft Dash; Outro: updraft launch (built) | exists (front) |
| **Gruntite** | Stone | Tank | Tusk Swipe / Brace (guard + taunt) / Charge Ram (Break); Intro: Crash Down on Launched | exists (front) |
| Drizzlit | Water | Healer | Bubble Shot / Rain Patch (team regen inside) / Tidal Ring (Soaks, heals on reactions) | new |
| Sparkit | Spark | Skirmisher | Zap Bite / Static Dash / Chain Lightning (jumps between Shocked) | new |
| Thornub | Flora | Controller | Thorn Flick / Bramble Snare (Root) / Overgrowth (pulls enemies into a knot) | new |
| Rimeling | Frost | Controller / Ranged | Ice Needle / Frost Lane (Chill) / Glacier Drop (freezes Chilled) | new |
| Cindermoth | Fire | Applier | Ember Dust / Flare Swirl (Burning) / Sunburst (detonates burns) | new |
| Glimmoth | Light | Support (late) | Light Mote / Halo (team crit buff) / Dawnbreak (reveals and staggers) | new, story |

## Art strategy (key)
- **Playable creatures can be front-view-only,** like the current enemies (Toxlop, Zephoot,
  Gruntite in `art/`): they hop or float and always face the camera. This makes each creature
  **far cheaper** than Emberoo's 5-view sets (5 views × 7 animations). A front-view creature
  needs one view × about 8 short sheets.
- **Two tiers of art:**
  - **Wild/enemy version:** basic animations only (front view, hop or float, one simple attack:
    3 sheets, which already exist for Toxlop, Zephoot and Gruntite).
  - **Team version:** once a creature can JOIN the team, it gets proper playable sheets, built
    gradually ("we'll build as we go"): `art/<creature>/<creature>_play_<action>_sheet.png`
    with actions `idle, move, basic, skill, signature, intro, outro, hurt` (16×16 frames,
    2–4 frames each).
  - The prototype's Toxlop and Zephoot already use their `_play_` sheets (basic, skill and
    signature play on their abilities; intro on swap-in, outro in the swap-out flash, hurt on
    a hit). A creature without them can point its scene at its enemy sheets instead. The
    flash, rings, tongue, orbs and wind are drawn in code, so a front-view sprite still reads
    as an attack.
  - A team creature wears a thin ring in its element colour at its feet (`AllyMarker`), so a
    playable Zephoot never reads as an enemy one.
- Emberoo stays 5-view (he's the mascot). Every new creature is front-view.
- Shiny variants and awoken forms are **palette swaps and glows**, so they need no new frames.

### "How many creatures can we realistically do?"
Solo developer, about 20 h/week. Estimate per front-view team creature: about 1 week of art
(8 short sheets plus a portrait) and about 1 week of code and tuning (3 abilities plus
Intro/Outro/trait, reusing `TimedAbility` and `AbilityTargets`). A wild-only enemy version is
2–3 days.

| Milestone | Playable (team) creatures | Wild-only species | Total time for creatures |
|---|---|---|---|
| **Prototype** (now) | **3** (Emberoo, Toxlop, Zephoot) | 4 enemy types already exist | done |
| **Demo** (1 act, ~5 zones) | **6–8** (add Gruntite + 3–4 new) | +2–3 | ~3–4 months |
| **Release** (3 acts) | **18–24** | +6–10 (enemy-only, Wardens' stock) | ~1–1.5 years spread over development |

More than ~24 playable creatures is not realistic solo. Each new creature also adds rows to
the reaction table and balance work. Expand later with updates or the cousin's help.

## Progression (no loot)
- **XP:** light motes from every kill (Project A's `LightMote`). Each creature levels on its own;
  benched team members get a share (50%) so swapping isn't punished.
- **Upgrade materials (few types):** *Light Dust* (every fight, common), one *Essence* per
  element (from specific areas: Toxic essence from the Sunken Garden, etc.), *Heartstones*
  (bosses, for rank 5 and awakening), plus that species' *chip fragments* from repeat unbinds.
- Spend them at the hub to rank up abilities. Progress is always guaranteed: a repeat run of a
  zone always gives materials.
- **Glimmer Shards** (from Project A) could become +1 team slot (4th, 5th, 6th member) and Link
  meter upgrades.

## A note on references
The user referenced **DragonSword: Awakening** (Hound13, 2026). Our system above is described in
our own terms, from public summaries only, and we make no claims about how that game works in
detail. Other references: party action games with swap combos, and Monster Sanctuary for
creature roles.

## Risks (honest)
- **Roster art cost:** the biggest risk. Even front-view, 20+ creatures at 8 sheets each is about
  a year of art. Mitigation: two art tiers (wild vs team), palette swaps for shinies and awoken
  forms, effects drawn in code, and creatures built only when the current team is fun.
- **Balance of swaps:** swapping can become mandatory (always swap after each skill) or
  pointless. Mitigation: the 1.5 s cooldown, the Link meter gating chains, creatures that are
  complete on their own (3 abilities), and benched creatures don't regenerate. Watch for one
  dominant team: reactions must be roughly equal in value.
- **Complexity vs Project A:** 3 creatures × 3 abilities + statuses + reactions is more to learn
  than one creature. Mitigation: introduce creatures one at a time (start with Emberoo, free
  Toxlop in zone 1, Zephoot in zone 2), and keep each reaction to one sentence.
- **Legal:** in 2024 Nintendo and The Pokémon Company sued Pocketpair (Palworld) in Japan over
  patents. Reports say the patents cover capturing creatures by **throwing an item** at them,
  and creature **riding/mounting**. We use no capture device at all: the creature is defeated,
  its chip cracks, the player channels a rod at a creature that's already free, and it
  *chooses* to join. Still: no thrown items for recruiting, no ball-like object, and no
  riding. **Get a patent/IP lawyer's check before release.** Do the trademark checks on every
  creature name (USPTO/EUIPO) and on the game's title.
- **Mashiness:** party games can turn into rotating cooldowns. Our answer: armed Intros reward
  timing, there are gaps between attacks, and status windows are short (Launched lasts 2.5 s, about 1 s past the swap cooldown).

## Prototype (built in the test arena, `scenes/main/main.tscn`)
**How to play:** run the main scene (the test arena; enemies start paused, press **F2** to
wake them).
- **1 / 2 / 3:** swap to Emberoo / Toxlop / Zephoot (1.5 s cooldown; the HUD cards at the
  bottom left show the key, sprite, health and cooldown veil).
- **Right mouse** (or Shift+left, or left-click an enemy, or **Q**): basic attack. **W:**
  skill. **E:** signature. **Space:** dodge. Left mouse: move. The skill bar shows the
  active creature's abilities.
- **Emberoo** has Project A's full kit (jab combo, plus the Ember Tree skills once learned:
  F3 grants debug points, K opens the tree).
- **Toxlop:** Tongue Lash (poisons a line), Poison Puddle (lobbed at the cursor, poisons for
  4 s), Leap Slam (leap to the cursor, untouchable in the air, area slam + knockback).
- **Zephoot:** Gust Shot (fast orb), Gale Push (cone knockback), Updraft Dash (scatters enemies,
  then an untouchable dash).
- **The chain proof:** fight near enemies as Zephoot, then press **1**. Zephoot's Outro
  throws nearby enemies up (Launched, 2.5 s), and Emberoo comes in with a flaming uppercut that
  does 4 bonus damage to every launched enemy, with a gold screen flash, hit-stop and a shake.
  Or swap Zephoot out to Toxlop first: Emberoo's card then glows (Intro armed), and the 1.5 s
  swap cooldown leaves about 1 s to bring him in for the payoff.

**Code map:** `scripts/party/` (Party, PartyMemberSwitch, SwapFlourish, ElementColors,
`chain/` SwapMove, UpdraftOutro, UppercutIntro), `scripts/creatures/playable_creature.gd`
(shared base for Emberoo's Creature and FrontViewCreature),
`scripts/creatures/front_view_creature.gd`, `scripts/skills/glimra/` (the six abilities,
TimedAbility, AbilityTargets, WindShot), `scripts/components/launched.gd`,
`scripts/effects/` (PoisonPuddle, GaleCone, ScreenFlash, HitStop), `scripts/ui/team_panel.gd`,
scenes `scenes/creatures/toxlop/`, `scenes/creatures/zephoot/`, `scenes/effects/wind_shot.tscn`.
HUD widgets rebind on a swap through `PlayerWatch`. Ruins Edge still plays Project A's
solo Emberoo (no Party there yet).

**Not built yet:** unbinding/recruiting, the Link meter, reactions, ranks, awakening, the
passive traits, the other Outros/Intros, Trainer's Aid for non-Emberoo creatures (F only heals
Emberoo; the flasks hide while another creature is out), XP per creature.
