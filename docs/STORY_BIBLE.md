# Project R (Project Revelation) - Story Bible

Version 0.1, pre-tribulation path. Written for typed text with no voice acting.

> **Work of fiction.** Every person, place, company, product, currency, device and organisation in this game is made up. The Antichrist figure, the False Prophet and the regime are fully fictional. They are not modelled on any real person, movement, nation or institution. Scripture is quoted from the King James Version (KJV, public domain), with the chapter and verse cited each time.

---

## 1. Premise

**Friday, July 12, 2030. Halvern Ridge, New Jersey.**

A 25-year-old moved back into their mother's house because rent, loans and a failed start-up job ate everything. Mom is a quiet believer. She never pushes, but she leaves her Bible open on the kitchen table. At 9:03 PM, while the hero is at the corner store buying milk and a 9-volt battery, millions of people vanish in an instant. Mom is one of them.

What follows is seven years of the world described in the Book of Revelation, seen from the ground. It is not shown through armies and thrones but through a person with a backpack, a dead phone, a dog that may or may not trust them, and a letter from their mother. The hero survives hunger, gangs, the regime's enforcers, wild animals, plagues and the darkness out of the pit. Slowly, painfully, and without being forced, they come to the faith their mother had. The story ends where Revelation ends: in the New Jerusalem, where "God shall wipe away all tears" (Revelation 21:4).

**One-line pitch:** *The Last of Us meets This War of Mine, told through the Book of Revelation: a doubter left behind tries to survive the end of the world, and finds the way home.*

---

## 2. Themes

| Theme | How it shows up |
|---|---|
| **Left behind, but not abandoned** | Mom's letter, the open Bible, the light she "left on." God's patience: "not willing that any should perish, but that all should come to repentance" (2 Peter 3:9). |
| **Grief before survival** | Chapter 1 is about a family dinner and an empty chair, not about combat. Loss comes first and survival second, as in The Last of Us. |
| **Hard choices, ordinary people** | Share food or keep it. Help a stranger or stay hidden. Lie to an enforcer or not. There are no perfect answers, as in This War of Mine. |
| **Peace that is not peace** | "For when they shall say, Peace and safety; then sudden destruction cometh upon them" (1 Thessalonians 5:3). The regime's slogans are always gentle. |
| **The cost of the mark** | Buying and selling are tied to worship (Revelation 13:16-17). Refusing it means hunger. Taking it means losing everything (Revelation 14:9-11). |
| **Overcoming by faith, not firepower** | "And they overcame him by the blood of the Lamb, and by the word of their testimony; and they loved not their lives unto the death" (Revelation 12:11). The hero fights to survive, but the story is never won by violence. |
| **Truth versus chatter** | Everyone has a theory. Only Scripture explains. (See section 7.) |
| **Home** | The house on Linden Court, then the Pumphouse, then the tunnels, and finally the city that "had no need of the sun" (Revelation 21:23). |

---

## 3. Writing Rules

1. **The Bible is the only "truth" in the story.** Characters can be wrong, and the narrative must not be. Biblical events happen as written. Where the text is open to interpretation (timing, identities), the game shows the events and lets characters wonder. It never states a speculative interpretation as fact.
2. **Respectful tone.** No mockery of believers, Scripture or God. Unbelievers are written with compassion too. Mom would want that.
3. **God is shown only as light and a voice.** His words are always Scripture (KJV) and set in a distinct typeface. **Christ** is shown reverently, with His face in light (never drawn), and only in heaven scenes. When He returns (Chapter 10), the player on earth sees the heavens open and the light, not a figure in close-up.
4. **Demons appear only where Revelation shows them:** the opening of the pit and the locusts (Revelation 9:1-11). They are written as horror to survive, not to fight for fun.
5. **No voice acting.** Lines are short and typed. Silence is a tool. Sound cues carry emotion. A line should rarely be longer than about 120 characters, so split it into beats instead.
6. **Every story beat pairs with something to DO.** If a scene is only reading, cut it or give it a task (search, carry, hide, repair, cook, calm, choose).
7. **No real people, companies, products, brands, logos, call signs or slogans.** Generic objects only ("a phone," "the store's soda fridge," "a sedan").
8. **Grounded realism.** People fight over food, water, medicine, fuel and shelter. Violence has weight. The hero is not a soldier.

### Hero variables (gender-neutral writing)

| Variable | Default | Notes |
|---|---|---|
| `{HERO}` | Alex | Player can rename. |
| `{HERO_FULL}` | Alex Hale | Surname fixed: Hale. |
| `{THEY}` / `{THEM}` / `{THEIR}` / `{THEIRS}` / `{THEMSELF}` | they / them / their / theirs / themself | Set by pronoun choice: he/him, she/her, they/them. |
| `{KID}` | kiddo | Mom's nickname for the hero, the same for every gender. |
| `{CHILD_WORD}` | kid | Used by neighbours ("the Hale kid"). |

Write around gendered words. Use "the Hale kid," "Marian's kid," "my child," never "son" or "daughter."

---

## 4. Characters

### 4.1 The hero: {HERO} Hale, 25

- **Background.** Grew up in Halvern Ridge. Dad (Tom Hale, a machinist) died of a heart attack when {HERO} was 14. {HERO} went to college for design, then worked two years for a city start-up that folded in spring 2030. Unable to afford rent, {THEY} moved back home in April.
- **Faith.** A doubter, not a mocker. {THEY} went to church as a kid, then stopped after Dad died ("Where was He?"). {THEY} loves Mom and finds her faith both comforting and unbearable.
- **Personality.** Wry, tired, a little ashamed of being "back in my childhood bedroom at 25." Kind underneath, and quick with a joke when scared.
- **Skills (gameplay).** Handy with tools (Dad's garage), fast and observant. Not a fighter, but learns.
- **Arc.**
  - Ch1-3: grief, anger, survival.
  - Ch4: hits bottom. A martyr's courage shakes {THEM}.
  - Ch5: comes to faith (Romans 10:9).
  - Ch6-10: a believer under persecution who protects others.
  - Epilogue: home.
- **Alone.** No siblings, no partner. Friends from school moved away. After Night One {THEY} is truly alone until the hideout in Chapter 3.

### 4.2 Mom: Marian Hale, 57

- School librarian at Halvern Ridge Middle. Hums hymns off-key. Grows tomatoes badly and makes a famous peach cobbler. Keeps everything ("you never know").
- **Quiet believer.** She prays at the kitchen table at 6 AM. She keeps a Bible with red-pen underlines and sticky notes, and a little prepper streak she's embarrassed about: water and tins in the basement. She never lectures. When {HERO} pushes back, she says, "Okay. I'm still going to pray for you. You can't stop me."
- **Taken** on Night One. Her absence is the spine of the story. Her **letter** (Chapter 1) is the player's first guide. Her **Bible** is an inventory item the whole game, and its underlines unlock "Remembered Verse" moments.
- **Heaven.** Glimpsed in heaven interludes among the multitude, never speaking until the Epilogue reunion.

### 4.3 Supporting characters

| Name | Role | First appears | Notes |
|---|---|---|---|
| **Ezra Kamau**, 63 | **The believer who helps.** Retired city bus driver and Mom's friend from church. | Ch2 | Ezra was not taken. "I knew it all. I sang it all. I didn't *mean* it." He came to real faith on Night One, weeping in his car. He brings food to {HERO}, leaves Bible verses taped to the door, and teaches {HERO} to find water. **Martyred in Ch4** (fifth seal, Revelation 6:9-11; the beheaded of Revelation 20:4). Seen in white in the Ch4 interlude (Revelation 7:9, 7:14). |
| **June Castellano**, 46 | Survivor at the Pumphouse; ER nurse. | Ch3 | Pragmatic, sharp, an agnostic who doesn't argue. Runs medicine and triage. "I don't do theories. I do sutures." Her faith question is the slowest. She comes to faith in Ch8, when the locusts pass over Avi but not her. Gameplay: crafting medicine and treating wounds. |
| **Teo Ruiz**, 15 in 2031 | Survivor; angry teen. | Ch3 | His dad was taken on Night One; his mom was killed in the Ch3 riots. Teo hates God for it. He is fast and a good climber. **Key arc:** at the midpoint (Ch6) he wants to take the Seal ID to get insulin for his little sister. The player's choices across the game decide whether he refuses. |
| **Pia Ruiz**, born Oct 2030 | Teo's baby sister. | Ch3 | Born after Night One, so she was not taken. Diagnosed with Type 1 diabetes in Ch4 (age 1-2), June's diagnosis. From then on her insulin is a constant pressure in the hideout economy. |
| **Marcus Bell**, 38 | Survivor; mechanic. | Ch3 | Gentle giant. Lost his wife and baby on Night One (taken). Runs generators, bikes and radios. Becomes a believer in Ch5 with {HERO}. Gameplay: repairs, crafting, the radio. |
| **Henrietta "Hen" Moss**, 71 | Survivor; retired history teacher. | Ch3 | Knows the Bible "like a textbook." She was a church organist who never believed a word. Now she believes every word and is frightened by it. She reads to the group. Dies of illness in Ch7 (Wormwood water), at peace. |
| **Avi Sandler**, 29 | **One of the 144,000** (Revelation 7:4; 14:1-5). | Ch5 | A Jewish software tester from New York. He came to faith in Jesus as Messiah after the disappearances, sealed by God (Revelation 7:3). He carries an unseen seal that the player never sees drawn: other characters only *notice* he is untouched. Fearless and funny, he preaches in the tunnels. In Ch8 the locusts cannot hurt him (Revelation 9:4). Leads the group into the city. |
| **Royce Gant, "the Toll"**, 44 | **Gang leader.** | Ch3 | Ex-landscaper, now leader of **the Tollmen**, who hold the Ridge Road overpass and the Halvern reservoir road and charge "tolls" in fuel, food and people. Charismatic and pragmatic, cruel when cornered. Later he runs a black market for people without the mark, then sells them out to the Directorate (Ch6-7). **Takes the mark.** His last scene is in the Ch9 darkness (Revelation 16:10-11): he "repented not." |
| **Inspector Dane Corrow**, 39 | **The enforcer.** Unity Compliance Directorate (UCD). | Ch2 (feeds), Ch4 (in person) | Former county police. Believes order saves lives, and at first he is not wrong. He is polite and tired. The player meets him at ration checkpoints. At the midpoint he takes the mark and leads believer raids, with drones and robot Hounds. The tragedy is that he almost listened once (Ch5). He meets the hero for the last time in Ch9. |
| **Cassian Vael** | **The leader** (the beast of Revelation 13:1-8; "the prince that shall come," Daniel 9:26-27). | Ch2 (feeds only) | Secretary of **the Global Concord**. Fully fictional. He is seen only on screens, billboards and drone projections, and from a crowd at a great distance. Calm, warm and reasonable. He brokers the seven-year covenant (Daniel 9:27). After a fatal wound that heals (Revelation 13:3) he grows strange and absolute. At the midpoint he declares himself God (2 Thessalonians 2:4). Never shown in close-up and never given a backstory scene. He is a distant figure. |
| **The Herald, Teodor Rhane** | **The False Prophet** (the second beast, Revelation 13:11-17; 19:20). | Ch4 (feeds) | A soft-spoken "spiritual unifier" of no recognisable faith tradition. He wears plain grey, never a real-world religious garment or symbol. He performs signs: fire from the sky on live feed (Revelation 13:13). He launches the Voice and the Seal ID. Seen only on screens and from a distance. |
| **The Voice** | **The image of the beast** (Revelation 13:14-15). | Ch5 (launch), Ch6 (speaks) | A global AI with Vael's likeness and calm tone that "speaks" through every screen, kiosk, drone and Hound. It knows your name. It demands worship of Vael. Typed in a cold monospace with no portrait, only a waveform. |
| **The neighbours** (Ch1) | Mr. Walt Dunmore (68, next door, grumpy, kind); Dana and Felix Okoro (30s, across the street; Felix is taken while driving); Mrs. Ines Albright (74, owner of Biscuit, the dog; taken); the Lindqvist family (their son Noah, 7, is taken from his bike). | Ch1 | Walt reappears in Ch2-3 as a stubborn holdout who trades with {HERO}. |
| **Hollis Grant**, 50s | Cashier at Ridge Corner Market, a believer. | Ch1 | Taken mid-sentence. |
| **Wade Pruitt**, 30s | Customer, later the first looter. | Ch1 | Desperate, not evil. Can reappear in Ch3 as a Tollman, or dead, depending on the Ch1 choice. |
| **Biscuit** | A scruffy terrier-mix dog. | Ch1 | Optional companion. His owner Mrs. Albright vanished mid-walk. If befriended he can find food, warn of danger and comfort {HERO}. **Biscuit never dies on screen.** If he is lost (given as a toll in Ch3, or run off with the wild-dog pack in Ch4), he is found again on Linden Court in Ch10. The game makes no claim about animals in heaven. |

---

## 5. The World in 2030

### 5.1 Halvern Ridge, NJ (fictional)

A commuter suburb of about 22,000 in the hills west of the Hudson, 40 minutes by train to New York City. It has cul-de-sacs, a dying strip mall, one main street (Ridge Road), a reservoir and pumphouse, a commuter rail station, a middle school, three churches and a mosque. Summer heat, cicadas, sprinklers. Housing costs drove the young away; {HERO} is the only person under 30 on Linden Court.

Key locations:

| Location | Chapters | Purpose |
|---|---|---|
| **12 Linden Court** (the Hale house) | 1-3 | Home, base and grief. A two-storey 1970s colonial with a basement and Dad's garage. |
| **Linden Court and Ridge Road** | 1-3 | Street, crash sites, neighbours. |
| **Ridge Corner Market** | 1-2 | The corner store. Later looted, then a Tollmen outpost. |
| **Halvern Ridge Middle School** | 2-3 | Mom's library; later a Concord ration and registration centre. |
| **Ridge Road overpass** | 3 | Tollmen territory. |
| **The Pumphouse** | 3-5 | An old brick reservoir pumphouse in the woods. The survivors' hideout, with water access. |
| **The commuter line** | 5 | Walk the dead rail line into New York City. |
| **New York City: "the Line"** | 5-9 | A disused, sealed-off subway spur under Manhattan (fictional) where believers hide. |
| **The Concord Exchange tower** | 6-9 | A fictional Manhattan tower: the regional hub of the Concord's trade and Seal ID network, its spire projecting the Voice. |

### 5.2 Technology in 2030 (fiction)

- **Near-cashless.** Physical cash is still legal on Night One, but rarely used. Mom keeps a coffee can of it.
- **Phones and feeds.** Everyone lives on a social feed app, **Murmur** (fictional). Short clips, rumours, livestreams.
- **Home assistants, autonomous delivery drones** and **self-driving rideshares.** On Night One, cars whose drivers vanished keep going or crash, depending on the model. Drones fall when the network chokes.
- **Implants** exist as medical and payment novelties for the rich. After the midpoint they become mandatory.
- **Robots.** Warehouse and security robots. Later the Directorate's **Hounds** (quadruped robots) and **Halos** (surveillance drones with a ring light).

### 5.3 The regime

- **The Global Concord.** A union of nations and blocs, formed in the chaos after Night One, led by Cassian Vael.
- **The Covenant of Seven** (fictional name). The treaty Vael "confirms with many" for seven years (Daniel 9:27), including a guarantee of peace for Israel and the rebuilding of worship in Jerusalem.
- **Unity Compliance Directorate (UCD).** Enforcement: inspectors, Peacekeepers in grey, drones, Hounds.
- **Unity Credit (UC).** The single digital currency. Ration allowances, wages, purchases.
- **Seal ID.** *(Proposed name, to be checked; alternatives below.)* A subdermal implant in the right hand or the forehead (Revelation 13:16) that links identity, Unity Credit and a pledge of allegiance to Vael. From the midpoint, no one can buy or sell without it (Revelation 13:17).

---

## 6. Made-Up Names List

All names are invented for this game. **Every name marked "to be checked" must be cleared (trademark and search conflict check) before release.**

| Thing | Name | Alternatives | Status |
|---|---|---|---|
| The town | Halvern Ridge, NJ | - | to be checked |
| The corner store | Ridge Corner Market | - | to be checked |
| The leader (Antichrist) | Cassian Vael | Aurel Danek, Severin Kael | to be checked |
| The False Prophet | Teodor Rhane, "the Herald" | Ilan Vesh | to be checked |
| The leader's union | the Global Concord | the Accord of Nations | to be checked |
| The treaty | the Covenant of Seven | the Halcyon Accord | to be checked |
| Digital currency | Unity Credit (UC) | Concord Credit, Common Mark | to be checked |
| **The mark** | **Seal ID** | Keystone, Concord Seal, LifeKey, Pledge Chip | **to be checked (high priority)** |
| The talking AI (image of the beast) | the Voice | Logos (rejected: biblical term for Christ), Oracle (too generic), Concord Mind | to be checked |
| Enforcement agency | Unity Compliance Directorate (UCD) | Office of Concord Order | to be checked |
| Enforcers | Peacekeepers | Wardens | to be checked |
| Surveillance drones | Halos | Lanterns | to be checked |
| Robot dogs | Hounds | - | to be checked |
| Social feed app | Murmur | Chorus | to be checked |
| Local radio | Ridge Radio (community radio, no call sign) | - | to be checked |
| Gang | the Tollmen | - | to be checked |
| Hideout 1 | the Pumphouse | - | - |
| Hideout 2 | the Line | - | - |
| Trade tower in NYC | Concord Exchange | - | to be checked |
| Pledge phrase | "One world. One peace. One Voice." | - | to be checked |

---

## 7. Chatter vs. Truth Rules

The world is drowning in explanations. The game uses them for texture, fear and dark humour, **never as answers**.

1. **Chatter is never confirmed.** Aliens, fallen angels, "the Harvest" cult, government experiments, a rogue AI, quantum accidents and solar weapons are all heard on the radio, on Murmur, in graffiti and in shelter arguments. No scene, item or cutscene ever proves one true.
2. **Scripture is the only explanation the story affirms**, and it is shown by events matching the text, not by a narrator.
3. **The regime's explanation is chatter too.** The Concord's official line in Ch2 ("a global consciousness event," "the planet shedding the intolerant") is propaganda and is framed as such.
4. **Characters can believe chatter.** Teo believes the aliens theory until Ch6. Gant believes nothing. The game lets them be wrong without mocking them.
5. **Media source tags.** Every chatter line carries a source tag, so the UI can style it: `RADIO`, `FEED`, `GRAFFITI`, `SHELTER` (overheard argument), `BROADCAST` (official), `FLYER`.
6. **No real names** in chatter: no real people, networks, hosts, apps or brands. Use invented handles (`@ridgewatch_88`).
7. **Scripture in chatter** is allowed only when quoted accurately and cited (believers' graffiti and flyers).
8. **Tone curve.** Ch1-2 chatter is shock and theories. Ch3-4 is survival, rumours of food and of the Tollmen. Ch5-6 is propaganda and fear of the Voice. Ch7-9 is despair, "they repented not" (Revelation 9:20-21; 16:9, 11), and rare hope.

See `CHATTER.md` for the library for Chapters 1-3.

---

## 8. Gameplay Pillars (story-facing)

| Pillar | Description |
|---|---|
| **Explore and examine** | Every room is lived in. Examine text tells the family's story without exposition. |
| **Scavenge and manage** | Food, water, medicine, fuel, batteries. Hideout economy (This War of Mine style): who eats, who keeps watch, who goes out. |
| **Survive encounters** | Top-down action. Shove, dodge, swing improvised tools, sneak, hide, distract. Lethal force is possible but has emotional cost (flags, dialogue). |
| **Animals** | Starving dogs, coyotes, a black bear, rats (disease) and, after Wormwood, worse. Calm, avoid, distract with food, or fight. |
| **Choices with weight** | A key choice per chapter plus many small ones. Flags carry forward. |
| **Prayer** | A hold-to-pray action. It is never a magic button. It calms {HERO} (it steadies aim and lowers panic), opens Remembered Verses and some dialogue, and is available from Ch1, but its prompt text changes as faith grows. |
| **Mom's Bible** | An inventory item. Underlined verses unlock as the story reaches them (the "Remembered Verse" card). The journal tracks verses found. |

---

## 9. Chapter Timeline (pre-tribulation path)

Prophetic timeline used: the seven years (Daniel's 70th week, Daniel 9:27) are counted as 2,520 days (two halves of 1,260 days; Revelation 11:3, 12:6), starting when the covenant is confirmed.

- **Night One** (the catching away, 1 Thessalonians 4:16-17): Friday, July 12, 2030, 9:03 PM EDT.
- **Day 1 of the seven years** (the covenant): Tuesday, October 15, 2030.
- **Midpoint, Day 1,260** (the abomination; 2 Thessalonians 2:4; Matthew 24:15): Tuesday, March 28, 2034.
- **Day 2,520** (the end of the seven years; the return of Christ): Tuesday, September 8, 2037.

> **Interpretation note.** Scripture does not give calendar dates. These are the game's fiction. Where futurist interpreters differ, the game picks one reading and notes it here: the two witnesses prophesy in the first half; the trumpets follow the midpoint, as decided with the project lead; the Rev 14:6 angel preaches during the witnesses' ministry. The game shows events, not a doctrinal argument.

---

### Chapter 1: "Night One"
**Date:** Fri, July 12, 2030 (7:30 PM) to Sat, July 13, 2030 (6:10 AM). **Location:** 12 Linden Court; Linden Court; Ridge Corner Market.

- **Biblical events.** The catching away of believers: "the dead in Christ shall rise first: Then we which are alive and remain shall be caught up together with them in the clouds" (1 Thessalonians 4:16-17); "In a moment, in the twinkling of an eye" (1 Corinthians 15:52); "the one shall be taken, and the other left" (Matthew 24:40).
- **Player experience.**
  - Dinner with Mom: small talk, a soft argument about faith, the errand (milk, bread, a 9-volt battery for the chirping smoke alarm).
  - The walk past neighbours.
  - At the store the cashier vanishes mid-sentence, followed by total silence.
  - Chaos: crashes, alarms, a looter, a panicked dog, a neighbour trapped in a car.
  - Home: Mom's empty chair, her Bible, her letter.
  - A night intruder.
  - Dawn emergency broadcast.
- **Gameplay focus.** Tutorial: movement, examine, inventory, the first shove-and-dodge fight, calming an animal, a timed rescue, a stealth/defence night sequence. Gameplay ends with finding the basement stash the letter reveals.
- **Key choice.** Help Dana Okoro out of the burning car, or run home to Mom (`C1_HELPED_DANA`). Also tracked: last words to Mom, the looter outcome, Biscuit.
- **Scripture.** 1 Thess 4:16-17; 1 Cor 15:51-52; John 14:2-3; Matthew 24:40-42; Romans 10:9, 13; Revelation 3:20; 1 Thess 5:3; Revelation 13:16-17; 14:9-10.
- **Post-trib mode changes.** Night One is not a disappearance. It becomes a different shock: the night of the covenant broadcast and the first blackout (the white horse). Mom is **not** taken. She survives into the tribulation as a mentor, and the letter becomes a letter she writes later (Ch6) before being arrested. The vanishing moment moves to Chapter 10, as the gathering at Christ's return (Matthew 24:29-31).

### Chapter 2: "Peace and Safety"
**Date:** October 2030 (three months later). **Location:** Halvern Ridge: the house, the school (now a ration centre), Ridge Road.

- **Biblical events.** The covenant confirmed for "one week" (seven years): "And he shall confirm the covenant with many for one week" (Daniel 9:27). The **first seal**, the white horse: "he went forth conquering, and to conquer" (Revelation 6:1-2). The world says "Peace and safety" (1 Thessalonians 5:3).
- **Player experience.**
  - Alone in the house, rationing the basement stash.
  - The town is half empty: abandoned cars, unharvested gardens, the school turned into a Concord relief centre handing out Unity Credit wallets.
  - Ezra Kamau knocks: Mom's church friend, the believer who was left behind and now believes. He leaves bread and a verse. {HERO} doesn't want to hear it.
  - Cassian Vael signs the Covenant of Seven on every screen. The street cheers.
  - Walt Dunmore, next door, trades and grumbles.
  - Night: someone paints "PEACE AND SAFETY" over a church sign.
- **Gameplay focus.** Daily survival loop (hunger, water, sleep). Scavenge abandoned houses on Linden Court (each house a small story). Repair the generator in Dad's garage. First trades with Walt.
- **Key choice.** Register for the Concord relief wallet (Unity Credit, not the mark) to get food, or stay off the grid (`C2_REGISTERED_UC`). Registering means easier food in Ch3, but the Directorate can track you later (Ch4 raid risk). Secondary: let Ezra in, or keep the door shut (`C2_EZRA_TRUST`).
- **Scripture.** Daniel 9:27; 1 Thess 5:3; Revelation 6:1-2; Matthew 24:4-5 ("Take heed that no man deceive you"); 2 Peter 3:9.
- **Heaven Interlude I, "The Throne."** After the chapter, a short non-interactive scene. Light, a rainbow "like unto an emerald" (Revelation 4:3), the four living creatures crying "Holy, holy, holy, Lord God Almighty, which was, and is, and is to come" (Revelation 4:8), and the scroll and the Lamb, "Worthy is the Lamb that was slain" (Revelation 5:12). Christ is a radiance at the centre, His face in light. Among the multitude, a woman in white with a librarian's posture: Mom. She does not speak.
- **Post-trib mode changes.** Mom is present. The key choice becomes hers and {HERO}'s together: Mom refuses the wallet, and the hero can register anyway.

### Chapter 3: "The Red Horse"
**Date:** January-September 2031. **Location:** Halvern Ridge, Ridge Road overpass, the reservoir woods, the Pumphouse.

- **Biblical events.** The **second seal**, the red horse: "power was given to him that sat thereon to take peace from the earth, and that they should kill one another" (Revelation 6:3-4): regional wars, riots, militias. The **third seal**, the black horse, famine and prices: "A measure of wheat for a penny, and three measures of barley for a penny; and see thou hurt not the oil and the wine" (Revelation 6:5-6). Food is rationed while luxuries stay on the shelves of the rich.
- **Player experience.**
  - Supply chains collapse. A loaf of bread costs a day's ration allowance.
  - The Tollmen take the overpass. Gangs strip Linden Court.
  - In a winter storm the Hale house is raided and burned, by the Tollmen or by desperate strangers depending on flags. {HERO} saves what fits in a backpack: Mom's Bible, the letter, Dad's multitool, a photo.
  - Alone in the snow, {HERO} follows Ezra's directions to the Pumphouse and meets June, Teo, little Pia, Marcus and Hen.
  - First confrontation with Royce Gant at the overpass.
- **Gameplay focus.** Leaving home (a set-piece escape from the burning house). Winter survival (cold meter, fire, shelter). The first stealth zone (the Tollmen overpass). Joining the hideout: introduce the shared economy (who eats, who keeps watch, who goes out) and the pressure of a baby in the group (formula, warmth, crying near enemies).
- **Key choice.** At the overpass, Gant offers safe passage for Biscuit, or for the Okoro family heirloom watch, or for "a little work" (`C3_TOLL_PAYMENT`: `dog | item | work | sneak`). Second key choice at the Pumphouse: share your remaining stash with the group, or hide some for yourself (`C3_SHARED_STASH`).
- **Scripture.** Revelation 6:3-6; Matthew 24:6-7 ("nation shall rise against nation"); Psalm 23:4; Matthew 25:35 ("I was an hungred, and ye gave me meat").
- **Post-trib mode changes.** Mom leaves the house with {HERO}. Hen's role (the Bible reader) is reduced and Mom reads instead.

### Chapter 4: "The Pale Horse"
**Date:** October 2031-August 2032. **Location:** The Pumphouse; Halvern Ridge (the dead town); a field hospital; the woods.

- **Biblical events.** The **fourth seal**: "behold a pale horse: and his name that sat on him was Death, and Hell followed with him. And power was given unto them over the fourth part of the earth, to kill with sword, and with hunger, and with death, and with the beasts of the earth" (Revelation 6:7-8; compare "the sword, and the famine, and the noisome beast, and the pestilence," Ezekiel 14:21).
  - **Sword:** militia raids and the Tollmen.
  - **Hunger:** empty land.
  - **Death (pestilence):** a fever epidemic, with June's field hospital.
  - **Beasts:** real animals. Starving dog packs, coyotes bold in daylight, a black bear in the school cafeteria, and rats carrying the fever.
  - The **fifth seal**, martyrs: "the souls of them that were slain for the word of God, and for the testimony which they held" (Revelation 6:9-11). Ezra is arrested by the Directorate for preaching at the ration line and is executed.
  - The **sixth seal** (chapter climax): "there was a great earthquake; and the sun became black as sackcloth of hair, and the moon became as blood" (Revelation 6:12-17). People hide in caves and rocks and cry to them, "hide us from the face of him that sitteth on the throne, and from the wrath of the Lamb" (6:16).
- **Player experience.** The hideout is besieged by sickness and animals. Inspector Corrow appears in person at the ration checkpoint and is courteous. Ezra's last visit: he gives {HERO} his small wooden cross and says, "Your mother's prayers aren't finished yet." {HERO} sees his execution reported on Murmur, and later finds his body's resting place. The great earthquake collapses half the Pumphouse.
- **Gameplay focus.** Animal encounters: track, avoid, distract with food, fight. Medicine runs to the abandoned hospital. Triage decisions in the field hospital. Earthquake escape set piece.
- **Key choice.** Two patients and one dose of antibiotics: Hen, or a Tollman's injured son brought to the door (`C4_DOSE_TO`: `hen | tollman_son`). This changes Gant's attitude in Ch6-7. Secondary: try to rescue Ezra (a doomed stealth mission he refuses through a note) or honour his wish and stay (`C4_EZRA_RESCUE_ATTEMPT`).
- **Scripture.** Revelation 6:7-17; Ezekiel 14:21; Revelation 20:4; Revelation 2:10 ("be thou faithful unto death, and I will give thee a crown of life").
- **Heaven Interlude II, "White Robes."** Under the altar, the souls cry "How long, O Lord" (Revelation 6:10). White robes are given to each (6:11). Then a great multitude "which no man could number" (7:9), and an elder's words: "These are they which came out of great tribulation, and have washed their robes, and made them white in the blood of the Lamb" (7:14). Ezra, in white, turns his face toward the light. Mom is beside him.
- **Post-trib mode changes.** Mom is arrested with Ezra. The player chooses who to try to save. Mom is martyred here (Revelation 6:9-11), and the interlude shows her instead.

### Chapter 5: "The Two Witnesses"
**Date:** September 2032-March 2034. **Location:** The ruined Pumphouse, then the dead commuter line into New York City, then the Line (an abandoned subway spur).

- **Biblical events.**
  - **The two witnesses** in Jerusalem, seen on every feed: "And I will give power unto my two witnesses, and they shall prophesy a thousand two hundred and threescore days, clothed in sackcloth" (Revelation 11:3). Fire from their mouths against those who would hurt them, and no rain in the days of their prophecy (11:5-6). The world hates them and cannot stop them.
  - **The 144,000** sealed from the tribes of Israel: "Hurt not the earth, neither the sea, nor the trees, till we have sealed the servants of our God in their foreheads" (Revelation 7:3-4).
  - **The angel with the everlasting gospel:** "Fear God, and give glory to him; for the hour of his judgment is come" (Revelation 14:6-7). It is heard and seen worldwide. Every language hears it.
  - The **seventh seal**: "there was silence in heaven about the space of half an hour" (Revelation 8:1).
- **Player experience.**
  - The group must leave the ruined Pumphouse and walk the rail line into New York City, where the Line hides believers.
  - On the way they meet Avi Sandler, laughing in the ruins of a station, unafraid. He is one of the sealed.
  - On every screen, the witnesses. Teo says they're "deepfakes." Hen reads Revelation 11 and goes pale.
  - In the sky the angel's proclamation: the whole world stops.
  - **{HERO} comes to faith.** It happens in the dark at the bottom of a flooded station stair, with Mom's letter, Ezra's cross and the verse Mom underlined twice (Romans 10:9). Marcus kneels with {THEM}.
- **Gameplay focus.** A long journey level, a cinematic walk with combat and puzzles along the rail line. First large NYC exploration. Halo drones (avoid detection cones). Rebuild the radio to hear the believers' network.
  - **The "Silence" sequence (8:1):** at chapter end, for 30 real-time seconds, all audio and UI disappear. The player can only walk. Then the first trumpet's sound starts Chapter 6. *(For accessibility, it can be skipped.)*
- **Key choice.** Faith is not forced by a button, and the chapter does not end until {HERO} kneels. The player chooses **how**: the words of the prayer (`C5_PRAYER_WORDS`: `mom | dad | plain | silent`). Secondary: Inspector Corrow corners {HERO} alone and lets {THEM} go, asking, "Is it true? Your God?" Answer honestly or deflect (`C5_TOLD_CORROW`).
- **Scripture.** Revelation 11:3-6; 7:1-8; 14:1-7; 8:1; Romans 10:9, 13; Luke 15:20; Isaiah 41:10.
- **Post-trib mode changes.** If Mom was martyred, {HERO}'s conversion happens at her grave. Avi still meets the group.

### Chapter 6: "The Abomination" (Midpoint)
**Date:** March 2034 (Day 1,260: Tue, March 28, 2034). **Location:** New York City: the Line, the streets around the Concord Exchange, a Seal ID station.

- **Biblical events.**
  - The witnesses finish their testimony and are killed by the beast. Their bodies lie in the street for three and a half days while the world celebrates and sends gifts (Revelation 11:7-10). Then "the Spirit of life from God entered into them, and they stood upon their feet; and great fear fell upon them which saw them" (11:11). They ascend in a cloud and a great earthquake follows (11:12-13). The whole world watches it live.
  - Vael, healed from a fatal wound (Revelation 13:3), sits in the temple in Jerusalem, "shewing himself that he is God" (2 Thessalonians 2:4; Matthew 24:15; Daniel 9:27).
  - The Herald gives life to the image, and **the Voice speaks** and orders that those who refuse to worship be killed (Revelation 13:15).
  - **Seal ID is mandatory:** "that no man might buy or sell, save he that had the mark" (Revelation 13:16-17).
  - The 42 months begin (13:5) and war is made on the saints (13:7).
- **Player experience.**
  - The festival in the streets over the witnesses' bodies, then the terror when they stand up.
  - The Voice speaks on every screen in NYC, and it says {HERO}'s name.
  - Seal ID booths appear on every corner. Food can only be bought with the mark.
  - Corrow takes the mark on a live feed.
  - Teo disappears to get insulin for Pia.
- **Gameplay focus.** Infiltration: follow Teo into a Seal ID station, past Hounds, Halos and Peacekeepers. Puzzle: find insulin without the mark (the black market, Gant's people, or a raid on a Concord pharmacy).
- **Key choice.** Teo is in line at the booth. Talk him out of it, physically drag him away, or let him choose (`C6_TEO_OUTCOME`: `refused | dragged | took_mark`). The outcome depends on accumulated trust flags (`C3_SHARED_STASH`, `C4_DOSE_TO`, Teo trust score). **{HERO} cannot take the mark.** If the player hovers the booth's "Accept" prompt, Mom's handwriting over the screen quotes Revelation 14:9-10, and {HERO} steps back. The player is never given a game-over "mark" ending. Taking it is shown as the loss it is, through other characters.
- **Scripture.** Revelation 11:7-13; 13:1-18; 14:9-12; 2 Thessalonians 2:3-4; Daniel 9:27; Matthew 24:15-21.
- **Post-trib mode changes.** None in events. In post-trib mode the midpoint is the same, and the change is only who is alive.

### Chapter 7: "Wormwood"
**Date:** April-August 2034. **Location:** NYC (the Line, flooded harbour edges, Central Park as farmland, burned rooftops).

- **Biblical events.** The **first four trumpets** (Revelation 8:7-12):
  - Hail and fire mingled with blood, and a third of the trees and all green grass burnt (8:7).
  - A great burning mountain cast into the sea: a third of the sea becomes blood and a third of the ships are destroyed (8:8-9).
  - A great star, **Wormwood**, falls on the rivers and springs, "and many men died of the waters, because they were made bitter" (8:10-11).
  - A third of the sun, moon and stars darkened (8:12).
  - An eagle cries "Woe, woe, woe" (8:13).
- **Player experience.** Water is the whole world now. Burned-out Manhattan blocks, with ash falling on stalled traffic. Hen drinks bad water to spare the children's ration, falls ill, and dies at peace while the group sings. Gant offers clean water at the price of names.
- **Gameplay focus.** Water collection and purification (craft filters and stills, test water). Fire spread set piece. Night stealth in shortened daylight (the darkened third shows as the day/night clock skipping hours).
- **Key choice.** Gant offers 40 litres of clean water for the location of one believer cell (not yours) (`C7_GANT_DEAL`: `refused | false_location | accepted`). `accepted` causes a raid and a death, which is heavy and remembered. `false_location` leads to a fight later.
- **Scripture.** Revelation 8:7-13; Psalm 23:2-3 ("he leadeth me beside the still waters"); John 4:14 ("whosoever drinketh of the water that I shall give him shall never thirst"); Revelation 14:13 ("Blessed are the dead which die in the Lord").
- **Post-trib mode changes.** If Mom is alive in post-trib mode (on a branch where she escaped arrest), Hen's death scene shifts to Mom or Hen depending on flags.

### Chapter 8: "The Pit"
**Date:** August 2034-January 2035 (five months). **Location:** NYC underground, then the surface.

- **Biblical events.**
  - The **fifth trumpet**: "I saw a star fall from heaven unto the earth: and to him was given the key of the bottomless pit" (Revelation 9:1). Smoke darkens the sun (9:2).
  - Out of the smoke come **locusts**, and "it was commanded them that they should not hurt the grass of the earth, neither any green thing, neither any tree; but only those men which have not the seal of God in their foreheads. And to them it was given that they should not kill them, but that they should be tormented five months" (9:4-5). "And in those days shall men seek death, and shall not find it" (9:6). Their king is "Abaddon" or "Apollyon" (9:11).
  - The **sixth trumpet**: the four angels loosed at the Euphrates and an army of 200 million. A third of mankind is killed (9:13-19), heard only through reports.
  - "Yet repented not" (9:20-21).
  - The **seventh trumpet**: "The kingdoms of this world are become the kingdoms of our Lord, and of his Christ" (11:15).
- **Player experience.**
  - Horror. The sky is black with smoke. The locusts are seen in fragments, rendered as Revelation describes them (9:7-10): "like unto horses prepared unto battle," "faces were as the faces of men," "hair as the hair of women," "teeth were as the teeth of lions," "tails like unto scorpions." They are never shown as monsters to farm.
  - Avi walks through them untouched. The others hide.
  - {HERO}'s protection is **not assumed**. The text names those with "the seal of God in their foreheads," and the game shows that Avi is sealed and makes no promise about anyone else. {HERO} survives by hiding, and is stung once in a scripted scene: five months of torment play out as a time-skip of pain and prayer.
  - June watches Avi and comes to faith.
  - Gant, stung, begs for death and cannot find it (9:6).
- **Gameplay focus.** Survival horror: sealed rooms, smoke, sound-based stealth, no combat against the locusts (no damage dealt; they cannot be killed). Escort sequences where Avi leads others through. Inventory triage under torment (a "pain" status that blurs controls).
- **Key choice.** Gant, stung and raving, is outside the Line's door. Let him in (risking discovery) or leave him (`C8_GANT_SHELTER`). If let in, he does not repent, which honours 9:20-21, but he does not betray them that night either.
- **Scripture.** Revelation 9:1-21; 11:15-19; Isaiah 26:20 ("hide thyself as it were for a little moment, until the indignation be overpast").
- **Post-trib mode changes.** None in events.

### Chapter 9: "Babylon"
**Date:** 2035-August 2037. **Location:** NYC: the Concord Exchange district, the harbour, the bridges.

- **Biblical events.** The **bowls** of wrath (Revelation 16):
  1. Sores on those with the mark (16:2). The marked are visibly afflicted, and the unmarked are not.
  2. The sea becomes "as the blood of a dead man" (16:3).
  3. The rivers and springs become blood (16:4-7).
  4. The sun scorches men with fire, "and they repented not to give him glory" (16:8-9).
  5. Darkness on the beast's kingdom: "they gnawed their tongues for pain" (16:10-11).
  6. The Euphrates dried up for the kings of the east, and unclean spirits gather the kings to "the battle of that great day of God Almighty" (16:12-14). The gathering at Armageddon (16:16) is reported.

  **Babylon the great falls**: "Babylon the great is fallen, is fallen" (18:2). "Come out of her, my people" (18:4). "For in one hour is thy judgment come" (18:10). The merchants weep, "for no man buyeth their merchandise any more" (18:11).
- **Interpretation care.** The game does **not** claim New York City is the biblical Babylon. It shows the global trade system of the beast, "Babylon," collapsing in one hour, and the player witnesses its NYC hub, the Concord Exchange, burning as part of that fall. Characters may argue about what Babylon is. The narrative stays silent.
- **Player experience.** Scorching heat by day and dark by night. Corrow, covered in sores, hunts the Line. The final confrontation with Corrow in the darkness of the fifth bowl: he cannot see, and {HERO} can choose to lead him out. He refuses to "give him glory" and curses God (16:11). He is not redeemed, because the text is clear about those with the mark. {HERO} still shows him mercy. Then "Come out of her": the group flees the city across a bridge as the Exchange burns in one hour.
- **Gameplay focus.** Heat and dark survival (time shade, carry water). Large-scale escape set piece. Final defence of the Line.
- **Key choice.** Mercy to Corrow: lead him out of the dark, or leave him (`C9_CORROW_MERCY`). The outcome doesn't change his fate. It changes {HERO}.
- **Scripture.** Revelation 16:1-16; 17:1-6 (read carefully, unquoted interpretations avoided); 18:1-24; Matthew 5:44 ("Love your enemies").
- **Heaven Interlude III, "Hallelujah."** The multitude: "Alleluia: for the Lord God omnipotent reigneth" (Revelation 19:6); "Blessed are they which are called unto the marriage supper of the Lamb" (19:9). Then heaven opens, and the light rides out (19:11). Seen from heaven, Mom among the armies "clothed in fine linen, white and clean" (19:14).

### Chapter 10: "The Last Day"
**Date:** September 2037 (Day 2,520: Tue, Sept 8, 2037). **Location:** The hills above the Hudson (Halvern Ridge, home again), then the sky.

- **Biblical events.**
  - The **seventh bowl**: "It is done" (16:17). The greatest earthquake, cities fall, and great hail (16:18-21).
  - The armies of the beast gather "to make war against him that sat on the horse" (19:19).
  - **Christ returns**: "And I saw heaven opened, and behold a white horse; and he that sat upon him was called Faithful and True" (19:11). "KING OF KINGS, AND LORD OF LORDS" (19:16). "Every eye shall see him" (1:7; Matthew 24:30).
  - The beast and false prophet are "cast alive into a lake of fire burning with brimstone" (19:20).
- **Player experience.**
  - The survivors walk home to Halvern Ridge: back to Linden Court, to the burned house.
  - The final siege: Peacekeeper remnants and the last of the Tollmen trap them at the ridge. The ground breaks, the hail falls, and the player fights to protect Pia and Teo (if alive).
  - Then the sky opens. All combat ends instantly. Every enemy drops their weapon. The sound is the trumpet from Night One, but complete.
  - Light fills the whole screen from the east (Matthew 24:27). No figure is drawn on earth, only light and the words of 19:11-16, typed slowly.
  - On the horizon the Concord Exchange's projection of Vael flickers and goes dark forever.
  - If Biscuit was lost, he finds {HERO} on Linden Court in the last minute before the light. This is a grace note for the player, not a doctrinal statement.
- **Gameplay focus.** The final survival defence (the hardest fight), then the controls are taken away gently: "Put it down."
- **Key choice.** The final moment before the light: {HERO} drops the weapon and kneels, or stands with arms open (`C10_FINAL_POSTURE`: cosmetic, affects the Epilogue's first frame). All paths lead home.
- **Scripture.** Revelation 16:17-21; 19:11-21; Matthew 24:27-31; Zechariah 14:4; Revelation 1:7; 22:20 ("Surely I come quickly. Amen. Even so, come, Lord Jesus").
- **Post-trib mode changes.** **This is where the vanishing moment moves.** The gathering of believers to meet the Lord (Matthew 24:31; 1 Thess 4:16-17) happens here, with the trumpet. The Ch1 silence beat is reused here, and the remaining believers are caught up into the light.

### Epilogue: "All Things New"
**After the thousand years** (Revelation 20:1-6 is shown as a single title card: "And they lived and reigned with Christ a thousand years," 20:4). **Location:** the New Jerusalem.

- **Biblical events.** "And I saw a new heaven and a new earth" (21:1). The holy city descending (21:2). "Behold, the tabernacle of God is with men" (21:3). "And God shall wipe away all tears from their eyes; and there shall be no more death, neither sorrow, nor crying, neither shall there be any more pain" (21:4). "Behold, I make all things new" (21:5). The city "had no need of the sun" (21:23). The river of the water of life and the tree of life (22:1-2). "And they shall see his face; and his name shall be in their foreheads" (22:4).
- **Player experience.**
  - A walk in light, the only fully calm level. No HUD. Jasper walls, gates of pearl, streets of gold "as it were transparent glass" (21:21), all in luminous pixel art.
  - Survivors (those who died in faith, and those who lived) are met along the way: Ezra, Hen, June, Marcus, Avi, and Teo and Pia depending on flags.
  - At the river: Mom. The first and only time Mom speaks after Chapter 1. Her first line: "Hi, {KID}. You got the battery?" Then {HERO} cries, which is typed as silence, then a laugh.
  - Christ: His face is light. He speaks only Scripture: "I am Alpha and Omega, the beginning and the end" (21:6); "Behold, I make all things new" (21:5).
  - God is light and a voice from the throne (21:3-5).
- **Gameplay focus.** Walk, look, remember. Pick fruit from the tree of life and drink from the river. Credits roll over a playable view of the city.
- **Final card.** Revelation 22:20, then "Thank you for playing."

---

## 10. Choice and Flag Overview

| Flag | Set in | Values | Consequence |
|---|---|---|---|
| `C1_LAST_WORDS` | Ch1 | `kind`, `curt`, `joke` | Mom's letter has a different first line. Remembered in Ch5 prayer and the Epilogue. |
| `C1_FAITH_TALK` | Ch1 | `open`, `dismissive`, `silent` | Ezra's first line in Ch2. |
| `C1_LOOTER` | Ch1 | `fought`, `gave_bag`, `talked_down` | Wade's fate (Ch3: Tollman, dead or ally). |
| `C1_BISCUIT` | Ch1 | `befriended`, `avoided`, `scared_off` | Dog companion. |
| `C1_HELPED_DANA` | Ch1 | `true`, `false` | Dana appears in Ch2-3 (gives medicine, or her empty car is found). |
| `C1_PRAYED` | Ch1 | `true`, `false` | Prayer prompt text in Ch2. |
| `C1_INTRUDER` | Ch1 | `hid`, `scared_off`, `fought` | Ch2 security of the house. |
| `C2_REGISTERED_UC` | Ch2 | `true`, `false` | Food in Ch3, Directorate tracking in Ch4. |
| `C2_EZRA_TRUST` | Ch2 | 0-3 | Ezra's later scenes. |
| `C3_TOLL_PAYMENT` | Ch3 | `dog`, `item`, `work`, `sneak` | Gant's attitude; Biscuit. |
| `C3_SHARED_STASH` | Ch3 | `true`, `false` | Group trust, Teo outcome. |
| `C4_DOSE_TO` | Ch4 | `hen`, `tollman_son` | Hen's health, Gant's debt. |
| `C5_PRAYER_WORDS` | Ch5 | `mom`, `dad`, `plain`, `silent` | Epilogue lines. |
| `C5_TOLD_CORROW` | Ch5 | `true`, `false` | Ch9 dialogue. |
| `C6_TEO_OUTCOME` | Ch6 | `refused`, `dragged`, `took_mark` | Teo's fate (Ch9 sores; Epilogue presence). |
| `C7_GANT_DEAL` | Ch7 | `refused`, `false_location`, `accepted` | Raids, guilt. |
| `C8_GANT_SHELTER` | Ch8 | `true`, `false` | Ch9 events. |
| `C9_CORROW_MERCY` | Ch9 | `true`, `false` | Epilogue reflection. |
| `C10_FINAL_POSTURE` | Ch10 | `kneel`, `open_arms` | Epilogue first frame. |

---

## 11. Audio Direction Notes (for the audio agent)

- **Silence is the signature.** The vanishing moment (Ch1) and the Silence in Heaven (Ch5 end, Revelation 8:1) are absolute: no music, no ambience, no UI sounds.
- **Mom's hum.** A hymn-like original melody (write an original tune, not an existing hymn arrangement) hummed off-key in Ch1. It returns as the theme of the Epilogue, played in tune by a full ensemble.
- **The chirp.** The smoke alarm's low-battery chirp (one short beep every ~40 s) in the empty house is the sound of grief in Ch1-2.
- **The Voice.** A cold, perfectly smooth synthetic tone with a sub-bass hum. Never musical.
- **The trumpet.** A single unearthly trumpet-like tone heard in Night One's first instant (very faint, almost subliminal, at 9:03:00). It is heard in full only in Ch10.

---

## 12. Open Questions (to be checked with the project lead)

1. Final name for the mark (Seal ID vs. alternatives); trademark checks on all made-up names.
2. Whether the Ch1 vanished people leave clothes behind (pop-culture trope) or simply vanish with what they held falling. **Current choice:** the person and their clothes vanish; held objects (phone, pen, glasses, leash) fall. Scripture says only that we "shall be changed" (1 Corinthians 15:51-52), so the game avoids the clothes trope.
3. Children taken on Night One (Noah Lindqvist). The script handles this gently: an empty bike with a spinning wheel. Confirm the tone with the project lead.
4. The placement of the Rev 14:6 angel and the two witnesses (first half) is the chosen futurist reading. Confirm.
5. Hero death and martyrdom. Currently the hero survives to Ch10. An optional "martyr ending" path (Revelation 20:4) is possible for a later version.
