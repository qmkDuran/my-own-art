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
- **The starters (story beat):** at the start, the professor has three starter Glimra and
  shrugs: kids don't care about Glimra any more, they're all into technology, "so... take all
  three." You begin with the full team: **Emberoo** (Fire, brawler), **Ripfin** (Tide, a
  shark-pup assassin) and **Mossdillo** (Bloom, an armadillo tank). Toxlop and Zephoot are
  **wild recruits** you unbind later (their playable kits are kept).

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
- **Swapping:** press 1/2/3. The outgoing creature plays its **Outro** exit (a flaming leap, a
  dive, a roll) and the incoming one makes an **entrance** at the same spot (flies in, erupts
  from the ground, drops from the sky). If its card is lit, the entrance fires its **Signal
  Skill** (see "Chaining").
  - **Swap cooldown 1.5 s** (tunable: `Party.swap_cooldown`), so swapping is a rhythm, not spam.
  - **Swap i-frames:** the incoming creature can't be hurt from the swap until its entrance
    (and Signal Skill) lands: about 8 frames plus the entrance (0.14 s + 0.15–0.18 s). A
    well-timed swap dodges a hit.
  - **Own health per creature.** A defeated creature can't be swapped in. When the active one
    falls, the next creature still standing jumps in at once. When all have fallen, you restart
    (later: at the checkpoint).
- **Outgoing creatures finish their move:** a creature swapped out right after a skill leaves
  its lingering hazard behind (e.g. Toxlop's puddle keeps poisoning). Later: a creature swapped
  out mid-skill finishes it off-field.

## Ability model: basic, Actives, a Signal Skill
We follow the proven tag-team loop of DragonSword: Awakening (source below) and add element
reactions as our own twist. Per creature:

| Slot | Key | What it is |
|---|---|---|
| Basic attack | right mouse / Shift+left / click an enemy (also Q) | spammable, defines the role |
| Active 1 | W | short cooldown, **applies the creature's status** (the set-up) |
| Active 2 | E | longer cooldown, the creature's big move (its "signature"); also applies or uses statuses |
| Signal Skill | the swap key, only while its card is lit | a big burst on swap-in, keyed to a **condition** on an enemy |
| Outro | the swap itself | a parting set-up or a gift for the teammate coming in |
| Passive trait (later) | none | one rule that makes the creature feel different |

- **No ultimates, no heavy attack.** Inputs stay simple; the presentation makes it flashy.
- **Hits shave cooldowns:** every landed hit takes 0.15 s off all of the attacker's cooldowns
  (`ElementStrike.COOLDOWN_SHAVE_PER_HIT`), so "keep hitting" brings the Actives back sooner.
- Not built yet: the dodge attack (dodge, then a light attack).
- Why 3 buttons and not more: each creature still plays well alone (set-up, payoff, role), and
  swapping adds depth on top. More is Project A's skill tree; it doesn't scale to a roster.

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
Source for the loop: allthings.how, "DragonSword Awakening: How Tag-Team Combat and Signal
Skills Work", https://allthings.how/dragonsword-awakening-how-tag-team-combat-and-signal-skills-work/
(we describe the system in our own terms; element reactions are ours, DSA's statuses don't react).

### 1. The loop
1. An **Active** puts a **status** on enemies (Rooted, Soaked, Burning, Airborne...).
2. You keep hitting: hits drain the enemy's **poise** and shave your cooldowns.
3. When the condition a teammate needs is really on an enemy near you, **that teammate's card
   lights up**: it glows in its element colour, its key number flashes, and a small badge above
   it shows the **icon of that status** (e.g. the roots of Rooted over Ripfin's card). No words.
   A card never lights just because the teammate exists.
4. Press its key: the teammate swaps in, its entrance lands and its **Signal Skill** fires (a
   big burst of rings in its element colour, 8-frame hit-stop). The outgoing creature's Outro is
   the "support attack" on the way out. Then swap back, or keep going.
5. What every skill, Signal Skill and reaction does is in the **chain guide (Tab)**, never on
   the battlefield (see "No words in combat").

### 2. Statuses (set-ups)
| Status | Element | Applied by (starters) | Looks like |
|---|---|---|---|
| Rooted | Bloom | Mossdillo: Bramble Snare, its Signal stomp | vines at the feet, green tint, held in place |
| Soaked | Tide | Ripfin: Undertow's splash, Whirlpool Outro | dripping, sky tint, slowed to 55% |
| Burning | Fire | Emberoo: Ember Leap Outro (and Searing Jab once learned) | embers, orange ticks |
| Airborne (Launched) | Wind / any | Ripfin: Riptide Ambush; Emberoo's Signal; Zephoot's Outro | floats up, wind swirl |
| Broken | none (poise) | anyone, by draining poise | knocked down, gold stars, gold poise bar |
| Poisoned | Toxic | Toxlop (wild recruit) | green pulse, green ticks |

**Stacking:** putting a status on an enemy that already has it drains 2 extra poise
(`SetUp.STACK_POISE_DRAIN`), so two creatures applying the same status Break it faster.

### 3. Poise and Break
- Every enemy has poise: 3 + its max health, capped at 3–12 (`Poise`). A thin **white bar**
  under its health bar (or over its head) shows once it has taken poise damage.
- Hits drain it: basic 1, Actives 2–3, Signal Skills 4. At zero the enemy is **Broken** for
  2.2 s (knocked down, held in place), then its poise refills. Left alone for 2.5 s, poise refills.
- **Super-armoured** enemies (a charging Gruntite, a slamming Captain) lose no poise: no opening.
- Later: elites get a grab point after a Break.

### 4. Signal Skills (the starters)
| Creature | Entrance | Signal Skill fires on | What it does |
|---|---|---|---|
| Emberoo | flies in from the side in a fire streak, lands a flaming uppercut | Airborne, Broken, Soaked | Flame Uppercut: 3 dmg to every set-up enemy within 90 px, throws them up again (Airborne); Fire on Soaked = **Steam Burst** |
| Ripfin | surfaces behind the nearest enemy, erupting in dirt and water | Rooted, Broken, Soaked | Ambush: a bite on set-up enemies within 26 px; always crits on Soaked; Tide on Rooted = **Drown** |
| Mossdillo | drops from the sky into a stomp: shockwave rings, flying leaves | Airborne, Burning | Thicket Stomp: slams airborne enemies down and Roots them; Bloom on Burning = **Wildfire** |

Outros: **Emberoo** leaps out in a column of flame and sets everything within 42 px Burning;
**Ripfin** dives and leaves a whirlpool (1.4 s) that drags enemies in and Soaks them (it keeps
working off-field); **Mossdillo** curls up and rolls away, leaving a **Bark Ward** on the
incoming creature (soaks the next 2 hits whole, 3 s). Zephoot keeps its Updraft Outro.

### 5. Element reactions (our twist)
When a hit of one element lands on an enemy carrying a status, the status is cashed in. Every
hit goes through `ElementStrike`, so any creature's attack can react. One sentence each:

| Status on the enemy | + Hit element | Reaction | What it does |
|---|---|---|---|
| Soaked | Fire | **Steam Burst** | the water flashes to steam: 3 dmg to every enemy within 36 px, knocked back |
| Rooted | Tide | **Drown** | the roots pull it under: 6 dmg to that enemy |
| Rooted | Fire | **Kindling** | the vines catch: 3 dmg and a big burn (2/s for 5 s) |
| Burning | Bloom | **Wildfire** | the fire spreads: 2 dmg, and Burning jumps to every enemy within 52 px |
| Poisoned | Fire | **Toxic Blaze** | the poison detonates: 2 dmg within 30 px, all set Burning |

Steam Burst, Drown, Kindling and Toxic Blaze use up the status; Wildfire keeps it burning.
Design-only rows for later elements: Launched + Stone = Crash Down, Burning + Stone = Molten,
Poisoned + Wind = Miasma, Staggered + Wind = Shatter Gust.

### 6. The Link meter (kept, light)
- One bar in 3 segments next to the team cards. It fills from hits (+1), reactions (+8) and
  Signal Skills (+8) (`LinkMeter`).
- Full (the bar and its label pulse gold in a gold glow): the next Signal Skill is a **Link
  Finisher**: double damage, a gold flash, an impact frame, big gold rings and **slow-mo at 0.3×
  for 20 game frames**. The meter empties. A plain (unlit) swap never spends it.

## Flashy combat: the hit-feel kit
Project B leans into spectacle. Built as `scripts/hit_feel/` (HitFeel, TimeControl, ImpactStar,
ImpactFrame, PixelDebris); every hit picks a weight:

| Weight | Used for | Hit-stop | Shake | Extras |
|---|---|---|---|---|
| LIGHT | basic hits, small skill hits | 3 frames | 1 px, 0.08 s | small spark (6 px star) in the element colour |
| HEAVY | Signal Skills, big Actives | 8 frames | 3 px, 0.25 s | big spark (12 px) + element and white rings |
| FINISHER | reactions | 10 frames | 3 px | HEAVY + **one impact frame** (a dark frame, then a pale one) |
| Link Finisher | a Signal on a full meter | (as HEAVY) | | + slow-mo 0.3× for 20 game frames, gold flash |

- The target flashes white (its HitFlash, about 2 frames bright).
- Screen shake is capped at **4 px** (`ScreenShake.MAX_STRENGTH`), whole pixels only.
- Speed lines on dashes and entrances (Undertow's surfacing, Rolling Thicket, Emberoo's fly-in,
  Mossdillo's drop).
- **No words pop up** (see below). Big beats get a wordless **burst** (`HitFeel.burst`: a large
  star and three rings): a Signal Skill in the creature's element colour, a reaction in its own
  colour (Steam Burst white, Drown sky, Kindling orange, Wildfire gold, Toxic Blaze green) plus a
  faint full-screen tint of that colour, a Break in cream. A reaction shows its burst, tint and
  impact frame once per beat (18 frames), however many enemies it hits.
- Screen flashes and impact frames are **light and never stack**: a flash is a 0.12–0.22 alpha
  tint fading in 0.12 s, the impact frame a 0.25 dark then 0.12 pale frame, and one asked for
  within 12 frames of the last is skipped (so a Steam Burst and the uppercut's gold flash on
  the same swap make one flash). Hit sparks have a tiny white pixel-plus heart, never a filled
  square (a frozen square over an enemy reads as a bug).
- **Damage numbers never overlap:** hits on the same target within 0.3 s merge into one rising
  total, a new number whose path up would cross another's is moved above it, at most 8 show at
  once (oldest first), and they draw at whole-number scales (crits 2×, popping in white).
- Everything is code-drawn on the pixel grid in Apollo colours (debris, rings, vines, whirlpool,
  bark plates); sprites move by whole pixels only.
- Real gaps between attacks (recovery frames, cooldowns, the 1.5 s swap cooldown), so it isn't mashy.

## No words in combat (decision)
The user's call (DragonSword: Awakening doesn't show them either): chains play out with **no
text on the battlefield**: no "STEAM BURST!", no "DROWN!", no "BREAK!", no "LINK FINISHER!",
no READY tags. The fight speaks in
colour, size and icons: element-coloured bursts and flashes, hit-stop, shake, impact frames,
slow-mo, and a status icon on a lit team card. (`WordBurst` was deleted.) Damage numbers stay:
they are numbers, not words. The names and exact effects live in one place, the chain guide.

## Chain guide (Tab)
**Tab** (or **Esc**) opens the Team Guide and pauses the game; Tab or Esc closes it. **←/→** or
clicking a tab turns the page. It draws at 960×540 in Monogram on dark cards edged in each
element's colour, like the Ember Tree (`scripts/ui/chain_guide_*.gd`).
- **Team:** a card per team member: its keys (RMB/Q, W, E), each skill's icon, name, cooldown,
  the status it sets up (icon) and one plain line with its real numbers; its **Signal Skill**
  and exactly which statuses fire it (`[Rooted] → Drown`, `[Broken] [Soaked] → Ambush`); and its
  swap-out move.
- **Chains:** the three steps of a chain, the Link meter, and every chain the team can do,
  e.g. `Mossdillo [W] Bramble Snare → [Rooted] → [2] Ripfin → Drown`.
- **Reactions:** status + hit element → reaction and what it does; every status with its icon
  and who on the team sets it.
- **Recruits:** the same cards for Toxlop and Zephoot (not on the team yet).

Everything is **read from the code**: each skill and swap move describes itself (`guide_line`,
`set_up_status`), Signal Skills list their `trigger_statuses`, reactions come from
`Reactions.TABLE` and `ReactionEffects.describe`, and the chains are worked out from all of that
(`ChainGuideRecipes`). Change a number and the guide follows. Status icons
(`ChainStatusIcons`) are the same ones the lit team cards use.

## Elements (recommend 8, room for 10)
More elements means more reactions to design and balance (every pair can react). **8** keeps
the reaction table readable; 2 more are saved for the story's late game.

| Element | Colour (Apollo) | Status it applies | Role it leans to |
|---|---|---|---|
| Fire | orange | Burning | brawler, finisher |
| Toxic | green light | Poisoned | applier, zone control |
| Wind | sky light | Launched | ranged, set-up |
| Stone | cork | Staggered / Break | tank |
| Tide | sky | Soaked (slowed) | assassin, healer |
| Spark | gold | Shocked (chains between enemies) | fast skirmisher |
| Bloom | green | Rooted | tank, controller |
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
| **Emberoo** (starter) | Fire | Brawler | Jab combo / Ash Guard / Flame Uppercut; Signal: Flame Uppercut; Outro: Ember Leap (Burning) | exists (5 views) |
| **Ripfin** (starter) | Tide | Assassin | Fin Slash / Undertow (Soaked) / Riptide Ambush; Signal: Ambush (Drown); Outro: Whirlpool | playable sheets |
| **Mossdillo** (starter) | Bloom | Tank | Claw Swipe / Bramble Snare (Rooted) / Rolling Thicket; Signal: Thicket Stomp; Outro: Bark Ward | playable sheets (side view) |
| **Toxlop** (wild recruit) | Toxic | Applier | Tongue Lash (poisons) / Poison Puddle / Leap Slam; Outro: poison mark | exists (front) |
| **Zephoot** (wild recruit) | Wind | Ranged | Gust Shot / Gale Push (cone knockback) / Updraft Dash; Outro: updraft launch (built) | exists (front) |
| **Gruntite** | Stone | Tank | Tusk Swipe / Brace (guard + taunt) / Charge Ram (Break); Intro: Crash Down on Launched | exists (front) |
| Drizzlit | Tide | Healer | Bubble Shot / Rain Patch (team regen inside) / Tidal Ring (Soaks, heals on reactions) | new |
| Sparkit | Spark | Skirmisher | Zap Bite / Static Dash / Chain Lightning (jumps between Shocked) | new |
| Thornub | Bloom | Controller | Thorn Flick / Bramble Snare (Root) / Overgrowth (pulls enemies into a knot) | new |
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
    with actions `idle, move, basic, skill, signature, intro, outro, hurt` (plus extras like
    Ripfin's `submerged`), 2–6 frames each. Frames are square and may be 16, 20 or 24 px: the
    loader reads the size from the sheet height and stands the sprite on its feet
    (`SingleViewAnimator.stands_on_feet`). A creature drawn in three-quarter side view facing
    right (Mossdillo) sets `faces_sideways` and flips when it moves or aims left.
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
| **Prototype** (now) | **5** (starters Emberoo, Ripfin, Mossdillo; recruits Toxlop, Zephoot) | 4 enemy types already exist | done |
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
  than one creature. Mitigation: three simple starters, then recruits one at a time (Toxlop
  in zone 1, Zephoot in zone 2), lit cards that say when to swap, and one sentence per reaction.
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
**How to play:** run the main scene (enemies start paused; press **F2** to wake them).
- **1 / 2 / 3:** swap to Emberoo / Ripfin / Mossdillo (1.5 s cooldown). A lit card (glowing,
  key flashing, a status icon over it) means pressing it fires that creature's Signal Skill.
- **Tab** (or **Esc**): the chain guide (pauses). **K:** the Ember Tree (Emberoo only).
- **Right mouse** (or Shift+left, left-click an enemy, or **Q**): basic attack. **W:** Active 1.
  **E:** Active 2. **Space:** dodge. Left mouse: move.
- **Emberoo:** Project A's kit (F3 grants debug points, K opens the Ember Tree for Ash Guard and
  Flame Uppercut; Tab no longer opens the tree, it opens the chain guide).
- **Ripfin:** Fin Slash (quick bite), Undertow (dives, swims under the enemy nearest the cursor,
  surfaces behind it; the splash Soaks everything around), Riptide Ambush (bursts up under every
  Soaked enemy in turn and throws each Airborne).
- **Mossdillo:** Claw Swipe, Bramble Snare (vines at the cursor Root a pack), Rolling Thicket
  (rolls to the cursor; Rooted enemies take double and are bowled into the others).
- **Chains to try** (all listed in the guide's Chains page): jab with Emberoo, swap to
  Mossdillo (Ember Leap burns the pack: Wildfire); snare the pack, swap to Ripfin (Drown);
  Undertow and Riptide Ambush, swap to Emberoo (the whirlpool soaks them: Steam Burst, and the
  uppercut throws them up); swap to Mossdillo (Thicket Stomp slams and roots them), Rolling
  Thicket through the roots. Fill the Link meter for a Link Finisher.

**Code map:** `scripts/party/` (Party, PartyMemberSwitch, SwapFlourish, ElementColors),
`scripts/party/chain/` (SwapMove, SignalSkill and the three Intros UppercutIntro, AmbushIntro,
StompIntro; the Outros EmberLeapOutro, WhirlpoolOutro, BarkWardOutro, UpdraftOutro; SetUp,
Reactions, ReactionEffects, ElementStrike, ElementalHits, LinkMeter, SpriteMotion),
`scripts/hit_feel/` (the kit), `scripts/components/` (Soaked, Rooted, Broken, PinnedEffect,
Poise, Launched), `scripts/skills/glimra/` (Swipe, Undertow, RiptideAmbush, BrambleSnare,
RollingThicket, EnemyPassThrough, plus Toxlop's and Zephoot's abilities),
`scripts/effects/` (Whirlpool, BarkWard, BrambleVines, SlashArc), `scripts/ui/team_panel.gd`
(lit cards with status badges), `scripts/ui/link_meter_bar.gd`, `scripts/ui/chain_status_icons.gd`,
the chain guide `scripts/ui/chain_guide_*.gd` (ChainGuideScreen in `scenes/game/game_layer.tscn`), scenes `scenes/creatures/ripfin/`,
`scenes/creatures/mossdillo/`. Ruins Edge still plays Project A's solo Emberoo.

**Not built yet:** unbinding/recruiting (Toxlop and Zephoot aren't on the team yet), the dodge
attack, elite grab points, ranks, awakening, passive traits, Trainer's Aid for non-Emberoo
creatures, XP per creature.
