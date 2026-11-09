# Chapter 1: "Night One" (Playable Script)

Project R (Project Revelation), pre-tribulation path. Script version 0.1.

> **Work of fiction.** No real people, companies, products, brands or call signs. Scripture is quoted from the KJV (public domain) with the chapter and verse cited.

---

## 0. How to Read This File (engine loading format)

Each scene is a fenced `yaml` block that can be extracted and parsed directly. Prose outside the blocks is for humans: direction, tone and art notes.

**ID scheme**

| Kind | Pattern | Example |
|---|---|---|
| Scene | `C1_S##` | `C1_S05` |
| Dialogue / text line | `C1_S##_L###` | `C1_S05_L012` |
| Choice | `C1_S##_CH##` with options `A`, `B`, `C` | `C1_S03_CH01.B` |
| Interactable object | `C1_OBJ_<NAME>` | `C1_OBJ_DAD_PHOTO` |
| Task | `C1_T##` | `C1_T04` |
| Flag | `C1_<NAME>` | `C1_LAST_WORDS` |
| Music cue | `MUS_<NAME>` | `MUS_HOME_EVENING` |
| Ambience | `AMB_<NAME>` | `AMB_SUBURB_DUSK` |
| Sound effect | `SFX_<NAME>` | `SFX_SMOKE_CHIRP` |

**Line fields:** `id`, `who` (speaker id), `text`, and optional fields: `beat` (a pause in seconds before the line), `cond` (flag condition), `set` (flags set when shown), `sfx`, `emote` (portrait or animation hint), `style` (`normal`, `whisper`, `shout`, `scripture`, `handwritten`, `system`, `broadcast`, `feed`).

**Speakers:** `HERO`, `MOM`, `WALT`, `FELIX`, `DANA`, `NOAH`, `ERIK`, `INES`, `HOLLIS`, `WADE`, `STRANGER`, `PHONE`, `TV`, `RADIO`, `FEED`, `CAPTION` (time and place cards only), `PROMPT` (UI). There is no narrator.

**Text variables:** `{HERO}`, `{THEY}`, `{THEM}`, `{THEIR}`, `{THEMSELF}`, `{KID}` (Mom's nickname, "kiddo"). See STORY_BIBLE section 3.

**Choices:** `options` hold `id`, `text`, `set` (flags), `goto` (next line or scene), and an optional `cond`. Choice timers are in seconds (`timer: 0` means no timer).

**Flags introduced in this chapter**

| Flag | Values | Default |
|---|---|---|
| `C1_GRACE` | `bowed`, `waited`, `ate` | `waited` |
| `C1_FAITH_TALK` | `open`, `dismissive`, `silent` | `silent` |
| `C1_LAST_WORDS` | `kind`, `curt`, `joke` | `curt` |
| `C1_MET_INES` | `true`, `false` | `false` |
| `C1_LOOTER` | `fought`, `gave_bag`, `talked_down` | `fought` |
| `C1_HAS_BATTERY` | `true`, `false` | `false` |
| `C1_BISCUIT` | `befriended`, `avoided`, `scared_off` | `avoided` |
| `C1_HELPED_DANA` | `true`, `false` | `false` |
| `C1_READ_LETTER` | `true` | - |
| `C1_FOUND_STASH` | `true`, `false` | `false` |
| `C1_INTRUDER` | `hid`, `scared_off`, `fought` | `hid` |
| `C1_GAVE_WATER` | `true`, `false` | `false` |
| `C1_ALARM_FIXED` | `true`, `false` | `false` |
| `C1_PRAYED` | `true`, `false` | `false` |

---

## Scene List

| ID | Scene | Time | Location | Core gameplay |
|---|---|---|---|---|
| C1_S00 | Cold Open | - | Black | Title cards |
| C1_S01 | The Bedroom | 7:22 PM | 12 Linden Court, upstairs | Movement, examine |
| C1_S02 | The House | 7:26 PM | Upstairs hall, stairs, living room | Free exploration |
| C1_S03 | Dinner | 7:31 PM | Kitchen | Set the table, dialogue choices |
| C1_S04 | Linden Court | 8:41 PM | The street at dusk | Walk, optional neighbours, Biscuit lesson |
| C1_S05 | Ridge Corner Market | 8:52 PM | The corner store | Shopping task, then THE MOMENT |
| C1_S06 | The Looter | 9:04 PM | The corner store | First confrontation |
| C1_S07 | The Street | 9:09 PM | Ridge Road and Linden Court | Chaos, the dog, the rescue choice |
| C1_S08 | The Empty Chair | 9:31 PM | 12 Linden Court | Search the house |
| C1_S09 | The Letter | 9:48 PM | Kitchen | Read Mom's letter |
| C1_S10 | The Basement | 11:14 PM | Basement (power out) | Flashlight, find the stash |
| C1_S11 | The Stranger | 1:42 AM | Kitchen and back door | Stealth or defence |
| C1_S12 | Before Dawn | 4:51 AM | Upstairs hall, kitchen | Fix the alarm, optional prayer |
| C1_S13 | The Broadcast | 6:02 AM | Living room | Radio and feed chatter |
| C1_S14 | End Card | - | Black | "Chapter 2: three months later..." |

---

## C1_S00: Cold Open

Direction: black screen. Cicadas fade in. Typed text, one card at a time, no music.

```yaml
scene: C1_S00
name: "Cold Open"
location: BLACK
music: null
ambience: AMB_CICADAS_FAR
lines:
  - { id: C1_S00_L001, who: CAPTION, text: "Halvern Ridge, New Jersey." }
  - { id: C1_S00_L002, who: CAPTION, text: "Friday, July 12, 2030." }
  - { id: C1_S00_L003, who: CAPTION, text: "7:22 PM." , beat: 1.0 }
  - { id: C1_S00_L004, who: CAPTION, text: "Watch therefore: for ye know not what hour your Lord doth come. (Matthew 24:42)", style: scripture, beat: 1.5 }
next: C1_S01
```

---

## C1_S01: The Bedroom

Direction: {HERO}'s childhood bedroom, half unpacked. Evening sun through blinds. {HERO} is face-down on the bed, laptop open. The phone buzzes.

```yaml
scene: C1_S01
name: "The Bedroom"
location: HOUSE_BEDROOM_HERO
time: "19:22"
music: MUS_HOME_EVENING        # soft, warm, a few guitar notes; it stops when the player leaves the room
ambience: AMB_HOUSE_SUMMER     # AC hum, cicadas outside, distant lawnmower
lines:
  - { id: C1_S01_L001, who: PHONE, text: "MOM: dinner", sfx: SFX_PHONE_BUZZ, style: system }
  - { id: C1_S01_L002, who: PHONE, text: "MOM: dinner dinner", sfx: SFX_PHONE_BUZZ, style: system, beat: 1.5 }
  - { id: C1_S01_L003, who: PHONE, text: "MOM: I can hear you not moving", sfx: SFX_PHONE_BUZZ, style: system, beat: 1.5 }
  - { id: C1_S01_L004, who: HERO, text: "Coming.", emote: groggy }
  - { id: C1_S01_L005, who: PROMPT, text: "Move: WASD / left stick. Examine: E / (A)." }
tasks:
  - { id: C1_T01, text: "Go downstairs for dinner.", complete_on: enter C1_S03 }
objects:
  - id: C1_OBJ_LAPTOP
    name: "Laptop"
    examine: "An email, opened twice. 'Thank you for your interest. We've decided to go in another direction.' The third this month."
  - id: C1_OBJ_BOXES
    name: "Moving boxes"
    examine: "Labelled 'APT - KITCHEN' and 'APT - MISC.' Four months, still taped. Unpacking them would make it permanent."
  - id: C1_OBJ_TROPHY
    name: "Shelf of trophies"
    examine: "Fourth-grade spelling bee, second place. Mom had the word 'necessary' engraved on the base because {HERO} missed it."
  - id: C1_OBJ_POSTER
    name: "Faded poster"
    examine: "A space poster from middle school. The sun has bleached Saturn to a ghost."
  - id: C1_OBJ_BED
    name: "Bed"
    examine: "Too short since tenth grade. Mom still makes it with the dinosaur sheets when the others are in the wash."
  - id: C1_OBJ_DESK_DRAWER
    name: "Desk drawer"
    examine: "Old sketchbooks. A drawing of Dad asleep in his recliner, mouth open. You were twelve. He laughed for a week."
  - id: C1_OBJ_WINDOW
    name: "Window"
    examine: "Linden Court, glowing orange. Mr. Dunmore is watering the same patch of lawn he waters every night."
  - id: C1_OBJ_PHONE
    name: "Phone"
    examine: "47 unread on Murmur. 'You won't believe what happened on the ridge tonight' - a lost cat. Battery 31%."
    pickup: ITEM_PHONE
next_on_exit: C1_S02
```

---

## C1_S02: The House

Direction: the player passes through the upstairs hall, past Mom's room, down the stairs and through the living room. It is optional exploration; the scent of chicken pulls the player toward the kitchen (the light is warmer there). **Introduce the smoke alarm chirp here.** One short, high beep about every 40 seconds, only audible in the hall.

```yaml
scene: C1_S02
name: "The House"
location: HOUSE_UPSTAIRS_HALL, HOUSE_MOM_ROOM, HOUSE_STAIRS, HOUSE_LIVING_ROOM
time: "19:26"
music: null
ambience: AMB_HOUSE_SUMMER
sfx_loops:
  - { id: SFX_SMOKE_CHIRP, interval_s: 40, area: HOUSE_UPSTAIRS_HALL }
  - { id: SFX_MOM_HUM, area: HOUSE_KITCHEN, audible_from: HOUSE_STAIRS }   # Mom humming her tune, off-key
objects:
  - id: C1_OBJ_SMOKE_ALARM
    name: "Smoke alarm"
    examine: "Chirp. It's been doing that for... a while. A week? You keep meaning to deal with it."
    examine_after: { cond: "C1_ALARM_FIXED == true", text: "Silent. Mom would say 'Finally.'" }
  - id: C1_OBJ_HALL_PHOTOS
    name: "Hallway photos"
    examine: "School photos, every year, in order. Then a gap after ninth grade. Then graduation. Mom never filled the gap."
  - id: C1_OBJ_DAD_PHOTO
    name: "Photo of Dad"
    examine: "Dad at the shore, sunburnt, holding up a fish too small to keep. Tom Hale, 1979-2019. He threw it back."
  - id: C1_OBJ_MOM_DOOR
    name: "Mom's room"
    examine: "The door's open a crack. It smells like her lotion and old paper."
  - id: C1_OBJ_MOM_NIGHTSTAND
    name: "Mom's nightstand"
    examine: "Reading glasses (her spare pair), a library book on hummingbirds - 'Overdue' sticky note in her own handwriting - and a little lamp shaped like a lighthouse."
  - id: C1_OBJ_MOM_PRAYER_LIST
    name: "Index card on the mirror"
    examine: "A prayer list in her neat print. 'Walt - his knee. The Okoros - a baby? Ines - her eyes. Hollis & Ellen. {HERO} - everything.' 'Everything' is underlined twice."
  - id: C1_OBJ_STAIR_CREAK
    name: "Fourth stair"
    examine: "It creaks. It has always creaked. You used to skip it sneaking out at sixteen. She always knew anyway."
  - id: C1_OBJ_RECLINER
    name: "Dad's recliner"
    examine: "Nobody sits in it. Mom dusts it every Saturday."
  - id: C1_OBJ_TV
    name: "TV"
    examine: "Muted. A news ticker: 'EARTHQUAKE SWARM CONTINUES... HEAT RECORD BROKEN FOR 9TH DAY... TALKS STALL AGAIN...' You change nothing."
  - id: C1_OBJ_BOOKSHELF
    name: "Bookshelf"
    examine: "Mysteries, gardening, a dozen Bibles in different sizes and translations. 'People keep giving me Bibles,' she says, like it's a problem."
  - id: C1_OBJ_PIANO_KEYS
    name: "Old keyboard"
    examine: "One key sticks: middle C. Mom plays around it."
next_on_enter: { HOUSE_KITCHEN: C1_S03 }
```

---

## C1_S03: Dinner

Direction: the kitchen is the warmest room in the game. Late sun, steam from the pot, a fan turning. Mom (Marian, 57, cardigan despite the heat, reading glasses pushed into her hair) is at the stove. The table has two chairs set out of four. This scene is where the player must fall a little in love with her. Keep her funny.

```yaml
scene: C1_S03
name: "Dinner"
location: HOUSE_KITCHEN
time: "19:31"
music: MUS_DINNER                # gentle piano and acoustic guitar, warm, lightly comic
ambience: AMB_KITCHEN            # simmering pot, ceiling fan, cicadas through the screen door
lines:
  - { id: C1_S03_L001, who: MOM, text: "There you are. I was about to send a search party.", emote: smile }
  - { id: C1_S03_L002, who: HERO, text: "I was working." }
  - { id: C1_S03_L003, who: MOM, text: "Face-down. With your eyes closed." }
  - { id: C1_S03_L004, who: HERO, text: "It's a design thing. You wouldn't understand." }
  - { id: C1_S03_L005, who: MOM, text: "Mm-hm. Set the table, Picasso." }
  - { id: C1_S03_L006, who: PROMPT, text: "Pick up: E / (A). Place: E / (A) at the table." }

tasks:
  - id: C1_T02
    text: "Set the table."
    subtasks:
      - { id: C1_T02a, text: "Plates (cupboard)", object: C1_OBJ_CUPBOARD }
      - { id: C1_T02b, text: "Forks (drawer)", object: C1_OBJ_FORK_DRAWER }
      - { id: C1_T02c, text: "Iced tea (fridge)", object: C1_OBJ_FRIDGE }
    complete_line: C1_S03_L020

task_lines:
  - { id: C1_S03_L010, trigger: "pickup C1_OBJ_FORK_DRAWER", who: MOM, text: "Not the good forks. Those are for company." }
  - { id: C1_S03_L011, trigger: "after C1_S03_L010", who: HERO, text: "We never have company." }
  - { id: C1_S03_L012, trigger: "after C1_S03_L011", who: MOM, text: "Then they're for a special occasion. Any day now." , emote: wink }
  - { id: C1_S03_L013, trigger: "pickup C1_OBJ_FRIDGE", who: MOM, text: "And there's no milk, before you look. That's going to be your job." }
  - { id: C1_S03_L014, trigger: "place third item at table, if player places a 3rd plate", who: MOM, text: "...Three plates?", emote: soft }
  - { id: C1_S03_L015, trigger: "after C1_S03_L014", who: HERO, text: "Habit. Sorry." }
  - { id: C1_S03_L016, trigger: "after C1_S03_L015", who: MOM, text: "Don't be. He'd have eaten two plates anyway." }

dialogue:
  - { id: C1_S03_L020, who: MOM, text: "Sit, sit. Chicken and rice. And tomatoes from the garden.", sfx: SFX_CHAIR_SCRAPE }
  - { id: C1_S03_L021, who: HERO, text: "These are tomatoes?" }
  - { id: C1_S03_L022, who: MOM, text: "They're doing their best. Like all of us." }
  - { id: C1_S03_L023, who: MOM, text: "Let me say grace.", emote: folds_hands }

choices:
  - id: C1_S03_CH01
    prompt: null
    timer: 0
    options:
      - { id: A, text: "[Bow your head.]", set: { C1_GRACE: bowed }, goto: C1_S03_L030 }
      - { id: B, text: "[Wait quietly.]", set: { C1_GRACE: waited }, goto: C1_S03_L030 }
      - { id: C, text: "[Start eating.]", set: { C1_GRACE: ate }, goto: C1_S03_L029 }

dialogue_2:
  - { id: C1_S03_L029, who: MOM, text: "...and bless the one who's already chewing. Amen.", emote: amused }
  - { id: C1_S03_L030, who: MOM, text: "Lord, thank You for this food, and this house, and this person across from me. Amen.", cond: "C1_GRACE != ate", style: normal }
  - { id: C1_S03_L031, who: MOM, text: "So. Any word from the studio in the city?" }
  - { id: C1_S03_L032, who: HERO, text: "They 'went in another direction.'" }
  - { id: C1_S03_L033, who: MOM, text: "Their loss." }
  - { id: C1_S03_L034, who: HERO, text: "It's always their loss. At some point it's my loss." }
  - { id: C1_S03_L035, who: MOM, text: "You're twenty-five. You're allowed to lose a few.", beat: 0.5 }
  - { id: C1_S03_L036, who: MOM, text: "Did you see the news? Another quake. And the fires out west." }
  - { id: C1_S03_L037, who: HERO, text: "Mom. Don't." }
  - { id: C1_S03_L038, who: MOM, text: "I didn't say anything." }
  - { id: C1_S03_L039, who: HERO, text: "You were about to say Jesus is coming back." }
  - { id: C1_S03_L040, who: MOM, text: "I was about to say pass the salt.", beat: 0.8 }
  - { id: C1_S03_L041, who: MOM, text: "But also yes." }

choices_2:
  - id: C1_S03_CH02
    timer: 0
    options:
      - { id: A, text: "\"Do you really believe that? Like, actually?\"", set: { C1_FAITH_TALK: open }, goto: C1_S03_L050 }
      - { id: B, text: "\"People have been saying that for two thousand years.\"", set: { C1_FAITH_TALK: dismissive }, goto: C1_S03_L060 }
      - { id: C, text: "[Say nothing. Pass the salt.]", set: { C1_FAITH_TALK: silent }, goto: C1_S03_L070 }

branch_open:
  - { id: C1_S03_L050, who: MOM, text: "I really do.", emote: soft }
  - { id: C1_S03_L051, who: MOM, text: "Not because I'm brave. Because I've read the end of the book." }
  - { id: C1_S03_L052, who: MOM, text: "He made me a promise. He's never broken one yet." }
  - { id: C1_S03_L053, who: HERO, text: "Even with Dad?", beat: 0.6 }
  - { id: C1_S03_L054, who: MOM, text: "Even with Dad.", beat: 1.0 }
  - { id: C1_S03_L055, who: MOM, text: "I didn't understand it. I still trusted Him. Those can both be true." }
  - { id: C1_S03_L056, who: HERO, text: "...I don't know how you do that." }
  - { id: C1_S03_L057, who: MOM, text: "One day at a time. Mostly badly.", emote: smile, goto: C1_S03_L080 }

branch_dismissive:
  - { id: C1_S03_L060, who: MOM, text: "They have. And one day they'll be right." }
  - { id: C1_S03_L061, who: MOM, text: "'Watch therefore: for ye know not what hour your Lord doth come.'", style: scripture }
  - { id: C1_S03_L062, who: HERO, text: "Did you just quote at me?" }
  - { id: C1_S03_L063, who: MOM, text: "A little. Matthew twenty-four. It's a good one." }
  - { id: C1_S03_L064, who: HERO, text: "You've got one for everything." }
  - { id: C1_S03_L065, who: MOM, text: "That's sort of the point of the book, {KID}.", goto: C1_S03_L080 }

branch_silent:
  - { id: C1_S03_L070, who: MOM, text: "...", emote: watches, beat: 1.2 }
  - { id: C1_S03_L071, who: MOM, text: "Okay." }
  - { id: C1_S03_L072, who: MOM, text: "I'm still going to pray for you. You can't stop me.", emote: smile, goto: C1_S03_L080 }

converge:
  - { id: C1_S03_L080, who: MOM, text: "Oh! Before I forget.", sfx: SFX_SMOKE_CHIRP_DISTANT }
  - { id: C1_S03_L081, who: MOM, text: "Hear that?" }
  - { id: C1_S03_L082, who: HERO, text: "The bird?" }
  - { id: C1_S03_L083, who: MOM, text: "The smoke alarm. It's been chirping for a week." }
  - { id: C1_S03_L084, who: HERO, text: "A WEEK?" }
  - { id: C1_S03_L085, who: MOM, text: "I thought you liked it. Like a little pet." }
  - { id: C1_S03_L086, who: MOM, text: "It wants a nine-volt. And we need milk. And bread." }
  - { id: C1_S03_L087, who: MOM, text: "Corner market's open till ten. My card's on the hook." }
  - { id: C1_S03_L088, who: HERO, text: "I have money." }
  - { id: C1_S03_L089, who: MOM, text: "You have pride. Take the card." }
  - { id: C1_S03_L090, who: PROMPT, text: "New task: The errand." }

tasks_2:
  - id: C1_T03
    text: "Take Mom's card and the tote bag from the hook by the door."
    objects: [C1_OBJ_KEY_HOOK]
  - id: C1_T04
    text: "Buy milk, bread and a 9-volt battery at Ridge Corner Market."

objects:
  - id: C1_OBJ_CUPBOARD
    name: "Cupboard"
    examine: "Mismatched plates. The one with the chip is Mom's. She insists."
  - id: C1_OBJ_FORK_DRAWER
    name: "Drawer"
    examine: "Forks, a corkscrew no one has used since 2019, and forty rubber bands."
  - id: C1_OBJ_FRIDGE
    name: "Fridge"
    examine: "A crayon drawing from a kid at Mom's school: 'MRS. HALE IS THE BEST LIBERRIAN.' A magnet holds a verse card: 'Fear thou not; for I am with thee. (Isaiah 41:10)'"
  - id: C1_OBJ_CALENDAR
    name: "Wall calendar"
    examine: "July. 'Thurs - Bible study (bring casserole).' 'Sat - farmers market.' 'Sun - church.' On the 13th, in small letters: '{HERO} - ask about the bike trail?'"
  - id: C1_OBJ_RADIO_KITCHEN
    name: "Old radio on the windowsill"
    examine: "Mom's radio. Battery-powered, 'in case.' Tuned to Ridge Radio's oldies hour."
  - id: C1_OBJ_TEA_MUG
    name: "Mom's mug"
    examine: "'WORLD'S OKAYEST MOM.' A gift from you, age 19. She uses it every single day."
  - id: C1_OBJ_KEY_HOOK
    name: "Key hook"
    examine: "Mom's card, house keys and a canvas tote that says 'READ.' Of course it does."
    pickup: [ITEM_MOM_CARD, ITEM_TOTE_BAG, ITEM_HOUSE_KEYS]
  - id: C1_OBJ_BIBLE_KITCHEN
    name: "Mom's Bible"
    examine: "On the table, where it always is. Soft leather, cracked at the spine. Red ink and sticky notes. You don't open it."
  - id: C1_OBJ_GARDEN_DOOR
    name: "Screen door"
    examine: "The tomato garden. Six plants, two tomatoes, both small and proud."
```

### C1_S03b: At the Door

Direction: the camera holds wide on the hall. Mom leans in the kitchen doorway, drying her hands. The porch light is off. This is the last time the player sees her in Chapters 1-10. Hold it slightly longer than feels comfortable.

```yaml
scene: C1_S03b
name: "At the Door"
location: HOUSE_FRONT_HALL
time: "20:39"
music: MUS_DINNER_TAIL          # the dinner theme thins to a single held note
ambience: AMB_HOUSE_SUMMER
lines:
  - { id: C1_S03b_L001, who: MOM, text: "Take a jacket. It's supposed to rain." }
  - { id: C1_S03b_L002, who: HERO, text: "It's ninety degrees." }
  - { id: C1_S03b_L003, who: MOM, text: "{KID}.", beat: 0.8 }
  - { id: C1_S03b_L004, who: MOM, text: "I love you. You know that, right?", beat: 0.5 }
choices:
  - id: C1_S03b_CH01
    timer: 0
    options:
      - { id: A, text: "\"Love you too, Mom.\"", set: { C1_LAST_WORDS: kind }, goto: C1_S03b_L010 }
      - { id: B, text: "\"Yeah. Back in twenty.\"", set: { C1_LAST_WORDS: curt }, goto: C1_S03b_L020 }
      - { id: C, text: "\"I know. It's in the house rules. Right under 'no shoes on the couch.'\"", set: { C1_LAST_WORDS: joke }, goto: C1_S03b_L030 }
lines_after:
  - { id: C1_S03b_L010, who: MOM, text: "Good.", emote: smile, goto: C1_S03b_L040 }
  - { id: C1_S03b_L020, who: MOM, text: "Twenty. I'm timing you.", emote: smile, goto: C1_S03b_L040 }
  - { id: C1_S03b_L030, who: MOM, text: "Rule number one. Don't forget it.", emote: laugh, goto: C1_S03b_L040 }
  - { id: C1_S03b_L040, who: MOM, text: "Go on. I'll leave the light on.", sfx: SFX_PORCH_LIGHT_CLICK }
on_end:
  - "Porch light turns on. It remains on in every later shot of the house until the power fails at 23:14."
next: C1_S04
```

---

## C1_S04: Linden Court

Direction: dusk, orange to violet. Sprinklers, kids, dogs, a radio playing somewhere. The player walks about 90 seconds to Ridge Road, then the store. Every neighbour is optional but the path brushes past each one. **Plant everything that will matter in S07.** Make the street feel alive so its later emptiness hurts.

```yaml
scene: C1_S04
name: "Linden Court"
location: STREET_LINDEN_COURT, STREET_RIDGE_ROAD
time: "20:41"
music: MUS_SUMMER_STREET        # light, warm, a slow walking tempo; it fades as the player reaches the store
ambience: AMB_SUBURB_DUSK       # sprinklers, a basketball bouncing, distant traffic, a radio playing an indistinct ballgame
npcs: [WALT, FELIX, DANA, NOAH, ERIK, INES, BISCUIT]

walt:   # Walt Dunmore, 68, watering his lawn next door
  - { id: C1_S04_L001, who: WALT, text: "Hale kid." }
  - { id: C1_S04_L002, who: HERO, text: "Mr. Dunmore." }
  - { id: C1_S04_L003, who: WALT, text: "You tell your mother her tomatoes are a disgrace." }
  - { id: C1_S04_L004, who: HERO, text: "She knows." }
  - { id: C1_S04_L005, who: WALT, text: "I've got stakes in the garage. If she wants 'em.", beat: 0.6 }
  - { id: C1_S04_L006, who: WALT, text: "Don't tell her I offered." }

okoros:  # Felix and Dana Okoro, across the street, unloading groceries from their SUV
  - { id: C1_S04_L010, who: FELIX, text: "{HERO}! Still looking for work?" }
  - { id: C1_S04_L011, who: FELIX, text: "My cousin's warehouse needs night shift. Forklifts. You'd love it." }
  - { id: C1_S04_L012, who: DANA, text: "Felix. Let the poor kid breathe." }
  - { id: C1_S04_L013, who: FELIX, text: "I'm networking!" }
  - { id: C1_S04_L014, who: DANA, text: "He's been networking the whole cul-de-sac. Ignore him." }
  - { id: C1_S04_L015, who: FELIX, text: "Gotta run anyway. Picking Mama up at the station at nine." }
  - { id: C1_S04_L016, who: FELIX, text: "Tell Marian we'll see her Sunday. Front row, like always.", emote: grin }
  - { id: C1_S04_L017, who: DANA, text: "You'll see her. I'll be asleep in the car.", emote: eye_roll }

noah:  # Noah Lindqvist, 7, on his bike; his dad Erik on the porch
  - { id: C1_S04_L020, who: NOAH, text: "Watch! No hands!" }
  - { id: C1_S04_L021, who: HERO, text: "Wow. Very dangerous. Very cool." }
  - { id: C1_S04_L022, who: NOAH, text: "Mrs. Hale gave me a book about sharks. Did you know they never stop swimming?" }
  - { id: C1_S04_L023, who: ERIK, text: "Noah! Inside by nine!" }
  - { id: C1_S04_L024, who: NOAH, text: "Five more minutes!" }

ines_and_biscuit:  # Mrs. Ines Albright, 74, walking Biscuit (scruffy terrier mix). This teaches the CALM mechanic.
  - { id: C1_S04_L030, who: INES, text: "Don't mind him. He barks at everyone he loves.", sfx: SFX_DOG_BARK_SMALL }
  - { id: C1_S04_L031, who: INES, text: "Crouch down. Give him the back of your hand. Slowly." }
  - { id: C1_S04_L032, who: PROMPT, text: "Hold C / (B) to crouch. Hold E / (A) to offer your hand." }
  - { id: C1_S04_L033, who: INES, text: "There. See? Now you're family.", cond: "calm_success", set: { C1_MET_INES: true } }
  - { id: C1_S04_L034, who: INES, text: "Tell your mother I haven't forgotten her hummingbird book. These eyes, you know." }
  - { id: C1_S04_L035, who: INES, text: "Come on, Biscuit. Home. Biscuit. Biscuit, HOME." }

objects:
  - id: C1_OBJ_OKORO_SUV
    name: "The Okoros' SUV"
    examine: "Silver, spotless. A 'BABY ON BOARD' sign still in its packaging on the dashboard. Huh."
  - id: C1_OBJ_NOAH_BIKE
    name: "Noah's bike"
    examine: "Red, with streamers. A shark sticker on the bell."
  - id: C1_OBJ_CHURCH_FLYER
    name: "Flyer on the lamppost"
    examine: "'Ridge Community Church - Sunday 10 AM - All welcome.' Someone has drawn a little UFO in the corner."
  - id: C1_OBJ_WALT_FLAG
    name: "Walt's porch"
    examine: "A rocking chair, a cooler and a radio. Walt's world."
  - id: C1_OBJ_FOR_SALE
    name: "For Sale sign"
    examine: "Number 9 has been for sale since March. Nobody can afford Linden Court anymore. Including you."
  - id: C1_OBJ_SKY
    name: "The sky"
    examine: "Clear. A few planes blinking toward the city. One star, early."
next_on_enter: { STORE_INTERIOR: C1_S05 }
```

---

## C1_S05: Ridge Corner Market

Direction: a narrow, bright corner store. Humming refrigerators, a lottery screen, a ceiling fan. **Hollis Grant** (50s, cardigan vest, name tag, a believer) is at the register humming the same kind of hymn tune Mom hums. **Wade Pruitt** (30s, work shirt, exhausted) argues on his phone in aisle 2. The player shops. At checkout, at exactly 21:03:00, it happens.

```yaml
scene: C1_S05
name: "Ridge Corner Market"
location: STORE_INTERIOR
time: "20:52"
music: null
ambience: AMB_STORE              # fridge hum, fan, fluorescent buzz, door chime
sfx_loops: [ { id: SFX_HOLLIS_HUM, area: STORE_REGISTER } ]
lines:
  - { id: C1_S05_L001, who: HOLLIS, text: "Evening! Marian's kid, right?", sfx: SFX_DOOR_CHIME }
  - { id: C1_S05_L002, who: HERO, text: "Guilty." }
  - { id: C1_S05_L003, who: HOLLIS, text: "How's your mother?" }
  - { id: C1_S05_L004, who: HERO, text: "Good. Ordering me around." }
  - { id: C1_S05_L005, who: HOLLIS, text: "That's love. That's what that is." }

wade_background:   # Wade's half of a phone call, triggered as the player passes aisle 2
  - { id: C1_S05_L010, who: WADE, text: "I said Monday. ...No. Monday.", style: normal }
  - { id: C1_S05_L011, who: WADE, text: "Put him on. Put him on. ...Hey, buddy. Hey. Yeah, Daddy's coming Sunday." }
  - { id: C1_S05_L012, who: WADE, text: "No, I didn't forget. Tell Mommy I didn't forget." }

tasks:
  - id: C1_T04
    subtasks:
      - { id: C1_T04a, text: "Milk", object: C1_OBJ_STORE_FRIDGE }
      - { id: C1_T04b, text: "Bread", object: C1_OBJ_STORE_BREAD }
      - { id: C1_T04c, text: "9-volt battery", object: C1_OBJ_STORE_BATTERY_HOOK, set: { C1_HAS_BATTERY: true } }
    then: "Go to the register."

objects:
  - id: C1_OBJ_STORE_FRIDGE
    name: "Dairy fridge"
    examine: "Milk, the store brand. The fridge door is frosted. You draw a little face in it."
    pickup: ITEM_MILK
  - id: C1_OBJ_STORE_BREAD
    name: "Bread shelf"
    examine: "Two loaves left. You take the one Mom likes, the one with seeds that get stuck in your teeth."
    pickup: ITEM_BREAD
  - id: C1_OBJ_STORE_BATTERY_HOOK
    name: "Battery hook"
    examine: "Nine-volt. Single pack. The price makes you wince. Everything does."
    pickup: ITEM_BATTERY_9V
  - id: C1_OBJ_STORE_SNACKS
    name: "Candy rack"
    examine: "Mom's favourite: the peanut butter cups. You could. You don't need a reason."
    pickup_optional: ITEM_CANDY      # if taken, it appears in S12 and Ch2 as a small grief item
  - id: C1_OBJ_STORE_LOTTERY
    name: "Lottery screen"
    examine: "JACKPOT: a number with too many zeros. Below, in smaller text: 'Odds 1 in 300,000,000.'"
  - id: C1_OBJ_STORE_NOTICE
    name: "Notice board"
    examine: "Lost cat. Guitar lessons. 'Free kittens.' A card in neat handwriting: 'Need prayer? Ask Hollis.'"
  - id: C1_OBJ_STORE_TV
    name: "Little TV above the counter"
    examine: "A talk show panel arguing about rising seas. Muted."

checkout:
  - { id: C1_S05_L020, who: HOLLIS, text: "All set? Let's see.", sfx: SFX_SCANNER_BEEP }
  - { id: C1_S05_L021, who: HOLLIS, text: "Nine-volt. Ah. The smoke alarm.", cond: "C1_HAS_BATTERY == true" }
  - { id: C1_S05_L022, who: HERO, text: "It's been chirping for a week." }
  - { id: C1_S05_L023, who: HOLLIS, text: "Ha! Ours too. Ellen's been on me about it for a month.", emote: laugh, sfx: SFX_SCANNER_BEEP }
  - { id: C1_S05_L024, who: HOLLIS, text: "Hey. You tell your mom I said Thursday group misses her casserole.", sfx: SFX_SCANNER_BEEP }
  - { id: C1_S05_L025, who: HOLLIS, text: "And you tell her that I think it's going to be—", style: normal, typing_interrupt: true }
```

### THE MOMENT (scripted, 21:03:00)

**Direction (critical).**
1. As Hollis's line types out, the text stops mid-word at "be—". The dialogue box stays on screen.
2. **Frame 0:** a single, very faint, pure tone, almost subliminal. It is the trumpet motif (SFX_TRUMPET_FAINT, 0.4 s), lower than the fridge hum. Most players won't consciously hear it.
3. **Frame 1:** Hollis is gone. No flash, no particles, no glow. He is simply not there. The scanner gun, his reading glasses and his phone drop to the counter.
4. **Total silence beat: 4.0 seconds.** Cut ALL audio: music, ambience, fridges, fan, UI. The dropped objects land with **no sound**. The ceiling fan keeps turning silently. Player input is disabled. The dialogue box with the unfinished line remains.
5. **At 4.0 s, sound returns all at once:** a car crash outside (SFX_CRASH_BIG), then a second, then car alarms, a woman screaming far away, the door chime ringing as wind pushes it. The lights flicker.
6. Hollis's phone, face-up on the counter, starts buzzing: "ELLEN calling".

Accessibility: a "silence" caption can appear for deaf and hard-of-hearing players: `[Silence.]`

```yaml
scene: C1_S05_MOMENT
name: "The Moment"
location: STORE_INTERIOR
time: "21:03:00"
script:
  - { t: 0.00, action: freeze_typewriter, line: C1_S05_L025 }
  - { t: 0.00, action: play_sfx, id: SFX_TRUMPET_FAINT, volume: 0.08 }
  - { t: 0.05, action: despawn_npc, id: HOLLIS, fx: none }
  - { t: 0.05, action: spawn_props, ids: [PROP_SCANNER_GUN_DROPPED, PROP_GLASSES_DROPPED, PROP_PHONE_HOLLIS] }
  - { t: 0.05, action: audio_mute_all, include_ui: true }
  - { t: 0.05, action: disable_input }
  - { t: 0.05, action: show_caption_if_enabled, text: "[Silence.]" }
  - { t: 4.05, action: audio_unmute_all }
  - { t: 4.05, action: play_sfx, id: SFX_CRASH_BIG }
  - { t: 4.60, action: play_sfx, id: SFX_CRASH_FAR }
  - { t: 4.90, action: play_sfx_loop, id: SFX_CAR_ALARMS }
  - { t: 5.20, action: play_sfx, id: SFX_SCREAM_DISTANT }
  - { t: 5.20, action: light_flicker, area: STORE_INTERIOR, duration: 1.5 }
  - { t: 6.00, action: play_sfx_loop, id: SFX_PHONE_BUZZ_COUNTER }
  - { t: 6.50, action: enable_input }
lines:
  - { id: C1_S05_L030, who: HERO, text: "...Hollis?", beat: 1.0 }
  - { id: C1_S05_L031, who: HERO, text: "Hollis?" }
  - { id: C1_S05_L032, who: WADE, text: "Where'd he go?", style: normal }
  - { id: C1_S05_L033, who: WADE, text: "WHERE'D HE GO?", style: shout }
objects:
  - id: C1_OBJ_HOLLIS_PHONE
    name: "Hollis's phone"
    examine: "'ELLEN calling.' It stops. Starts again. Stops. The lock screen is a photo of two people at a lake, laughing."
  - id: C1_OBJ_HOLLIS_GLASSES
    name: "Reading glasses"
    examine: "Still warm."
  - id: C1_OBJ_HOLLIS_TAG
    name: "Name tag"
    examine: "'HOLLIS - Ask me anything!' It's on the floor behind the counter, face-up."
next: C1_S06
```

---

## C1_S06: The Looter

Direction: Wade's phone is on the floor. He keeps calling a number that doesn't answer. Then he breaks. He vaults the counter, sweeps the shelf of painkillers and cigarettes into a bag, and turns on {HERO}, who is between him and the door. This is the **first confrontation**. Teach shove (push away), dodge (roll) and grab (improvised weapon). Wade is not a villain: he's terrified.

```yaml
scene: C1_S06
name: "The Looter"
location: STORE_INTERIOR
time: "21:04"
music: MUS_TENSION_LOW          # low pulse, heartbeat-like
ambience: AMB_STORE_ALARMED     # store hum plus outside alarms, muffled
lines:
  - { id: C1_S06_L001, who: WADE, text: "He was on the phone. My boy was on the phone." }
  - { id: C1_S06_L002, who: WADE, text: "And then he wasn't. He just. He wasn't." }
  - { id: C1_S06_L003, who: WADE, text: "Nobody's answering. NOBODY'S ANSWERING." }
  - { id: C1_S06_L004, who: WADE, text: "...", sfx: SFX_SHELF_SWEEP, emote: grabs_meds }
  - { id: C1_S06_L005, who: HERO, text: "Hey. Hey, man, what are you doing?" }
  - { id: C1_S06_L006, who: WADE, text: "What's it look like? It's over. Don't you get it? It's OVER." }
  - { id: C1_S06_L007, who: WADE, text: "Give me the bag." }
  - { id: C1_S06_L008, who: HERO, text: "It's milk." }
  - { id: C1_S06_L009, who: WADE, text: "GIVE ME THE BAG.", style: shout }
choices:
  - id: C1_S06_CH01
    timer: 6
    default: A
    options:
      - { id: A, text: "[Fight. Get out of the way.]", set: { C1_LOOTER: fought }, goto: COMBAT_C1_WADE }
      - { id: B, text: "[Give him the bag.]", set: { C1_LOOTER: gave_bag, C1_HAS_BATTERY: false }, goto: C1_S06_L030 }
      - { id: C, text: "\"Wade. Right? Wade. Breathe. Look at me.\"", cond: "C1_S05_L011 heard", set: { C1_LOOTER: talked_down }, goto: C1_S06_L040 }
```

**Note on option C.** Show it only if the player walked past aisle 2 and heard Wade's phone call, which reveals his name on his work-shirt patch and his son. That rewards attention.

```yaml
combat:
  id: COMBAT_C1_WADE
  type: tutorial_brawl
  enemy: { id: WADE, hp: 3, attacks: [lunge, grab], telegraph_s: 0.8 }
  prompts:
    - { id: C1_S06_L010, who: PROMPT, text: "Dodge: SPACE / (B). Roll out of the lunge." }
    - { id: C1_S06_L011, who: PROMPT, text: "Shove: Q / (X). Push him back." }
    - { id: C1_S06_L012, who: PROMPT, text: "The mop handle. Pick it up: E / (A)." }
  props: [PROP_MOP_HANDLE, PROP_WET_FLOOR_SIGN, PROP_DISPLAY_RACK]
  rules:
    - "The hero cannot die here. At low health, Wade knocks the hero down, takes the bag and flees (outcome becomes gave_bag)."
    - "At 0 HP Wade slips on spilled milk, hits the shelf and stumbles out. He is not killed."
  win_lines:
    - { id: C1_S06_L020, who: WADE, text: "...Sorry. I'm sorry. I'm sorry.", emote: stumbling_out }
    - { id: C1_S06_L021, who: HERO, text: "...", emote: shaking }
    - { id: C1_S06_L022, who: HERO, text: "My hands won't stop." }
  loot_after: [ITEM_BOX_CUTTER]   # dropped by Wade; needed in S07 to cut a seatbelt
  next: C1_S07

gave_bag:
  - { id: C1_S06_L030, who: HERO, text: "Here. Take it. Take it." }
  - { id: C1_S06_L031, who: WADE, text: "...", emote: snatches_bag_runs, sfx: SFX_DOOR_CHIME_SLAM }
  - { id: C1_S06_L032, who: HERO, text: "The battery was in there.", beat: 1.2 }
  - { id: C1_S06_L033, who: HERO, text: "...Who cares about the battery." }
  - { id: C1_S06_L034, who: PROMPT, text: "A box cutter lies on the floor where he dropped it.", set: { item_available: ITEM_BOX_CUTTER } }
  - { goto: C1_S07 }

talked_down:
  - { id: C1_S06_L040, who: WADE, text: "...", emote: freezes, beat: 1.0 }
  - { id: C1_S06_L041, who: HERO, text: "You've got a kid. Sunday, right? You told him Sunday." }
  - { id: C1_S06_L042, who: WADE, text: "He was on the phone.", emote: crumbling }
  - { id: C1_S06_L043, who: HERO, text: "Then go find out. Go. That's what you do. Not this." }
  - { id: C1_S06_L044, who: WADE, text: "...", emote: drops_bag_of_meds }
  - { id: C1_S06_L045, who: WADE, text: "If he's gone. If he's really..." }
  - { id: C1_S06_L046, who: WADE, text: "...", emote: runs_out, sfx: SFX_DOOR_CHIME }
  - { id: C1_S06_L047, who: PROMPT, text: "He left a box cutter on the counter.", set: { item_available: ITEM_BOX_CUTTER } }
  - { goto: C1_S07 }

optional_pickups_after:   # the player may take or leave these. Each is a quiet moral beat, with no flag beyond inventory.
  - { id: ITEM_PAINKILLERS, examine: "Painkillers, spilled across the floor. Nobody's going to pay for anything tonight." }
  - { id: ITEM_WATER_BOTTLES, examine: "A case of water. Heavy. You don't know yet why you'd want it." }
```

---

## C1_S07: The Street

Direction: outside, the world has broken. Ridge Road at night is lit by fire and headlights. The Okoros' SUV has hit a lamppost at the corner of Linden Court: the driver's seat is empty and Felix is gone. Dana is pinned in the passenger seat and smoke rises from the engine. Noah's bike lies in the street, its back wheel still spinning. Erik is screaming Noah's name. A self-driving delivery van rolls slowly, aimless, honking. Biscuit's empty leash drags behind him. He is wild with fear and blocks the alley shortcut home. Walt is on his porch with a shotgun and a radio.

**Phones:** every call gets "NETWORK BUSY". Mom's number gets "Call failed." The player can try at any time (`ITEM_PHONE`), and it always fails.

```yaml
scene: C1_S07
name: "The Street"
location: STREET_RIDGE_ROAD_NIGHT, STREET_LINDEN_COURT_NIGHT, ALLEY_SHORTCUT, BACKYARDS
time: "21:09"
music: MUS_CHAOS_PULSE          # percussion, no melody, rising
ambience: AMB_STREET_CHAOS      # alarms, distant sirens, a helicopter, dogs, shouting, a transformer buzz
tasks:
  - { id: C1_T05, text: "Get home to Mom." }
lines_entry:
  - { id: C1_S07_L001, who: HERO, text: "What..." }
  - { id: C1_S07_L002, who: HERO, text: "What is happening?" }
  - { id: C1_S07_L003, who: PHONE, text: "Calling MOM... Call failed. Network busy.", style: system, sfx: SFX_CALL_FAIL }
  - { id: C1_S07_L004, who: HERO, text: "Come on. Come on, Mom." }

ambient_barks:   # positional, triggered by proximity
  - { id: C1_S07_L010, who: ERIK, text: "NOAH! NOAH!", style: shout }
  - { id: C1_S07_L011, who: ERIK, text: "He was right there. He was RIGHT THERE.", style: shout }
  - { id: C1_S07_L012, who: STRANGER, text: "My husband was driving! He was DRIVING!", style: shout }
  - { id: C1_S07_L013, who: STRANGER, text: "Get off the road! The cars are just going!", style: shout }
  - { id: C1_S07_L014, who: WALT, text: "Everybody INSIDE! You hear me? Inside!", style: shout }
  - { id: C1_S07_L015, who: WALT, text: "Hale kid! Get home! Now!", style: shout }

objects:
  - id: C1_OBJ_NOAH_BIKE_NIGHT
    name: "Noah's bike"
    examine: "Lying in the middle of the road. The back wheel is still turning. Tick. Tick. Tick. The streamers move in the hot wind."
  - id: C1_OBJ_DELIVERY_VAN
    name: "Delivery van"
    examine: "No one inside. It isn't supposed to have anyone inside. It drives in circles, politely honking."
  - id: C1_OBJ_SKY_NIGHT
    name: "The sky"
    examine: "An orange glow over the city. Two planes, low, wrong. A third, falling slowly, very far away. You stop looking."
  - id: C1_OBJ_SHOE_STREET
    name: "A sneaker"
    examine: "A child's sneaker, laces still tied, in the gutter. You can't tell whose. You keep walking."
```

### C1_S07a: Biscuit (the panicked dog)

Direction: Biscuit stands in the alley shortcut, trailing his leash. Mrs. Albright is nowhere. Her cardigan isn't anywhere either; the leash's loop handle lies empty on the pavement. He barks and snarls, hackles up, terrified. The shortcut is 30 seconds home; going around through the backyards takes about 2 minutes, past a fence and a loose neighbourhood guard dog. **The calm mechanic is the one Mrs. Albright taught in S04.**

```yaml
scene: C1_S07a
name: "Biscuit"
location: ALLEY_SHORTCUT
animal: { id: BISCUIT, state: panicked, fear: 100, aggression: 40 }
lines:
  - { id: C1_S07a_L001, who: HERO, text: "Biscuit? Hey. Hey, buddy." }
  - { id: C1_S07a_L002, who: HERO, text: "Where's Mrs. Albright?", beat: 0.8 }
  - { id: C1_S07a_L003, who: PROMPT, text: "Crouch and offer your hand to calm him. Move slowly.", cond: "C1_MET_INES == true" }
  - { id: C1_S07a_L004, who: PROMPT, text: "He's terrified. Approach slowly, or go around.", cond: "C1_MET_INES == false" }
mechanic:
  calm:
    input: "crouch + hold offer hand"
    rule: "Fear drops while crouched, still and close. Sudden movement or sprinting raises fear. At 0 fear, success."
    bonus: "If C1_MET_INES, fear drops twice as fast."
    fail: "At aggression 100 he snaps once (minor damage) and bolts; outcome = scared_off."
choices:
  - id: C1_S07a_CH01
    timer: 0
    options:
      - { id: A, text: "[Calm him.]", goto: CALM_MINIGAME, on_success: { set: { C1_BISCUIT: befriended } }, on_fail: { set: { C1_BISCUIT: scared_off } } }
      - { id: B, text: "[Go around through the backyards.]", set: { C1_BISCUIT: avoided }, goto: BACKYARD_ROUTE }
      - { id: C, text: "[Stomp and shout to scare him off.]", set: { C1_BISCUIT: scared_off }, goto: C1_S07a_L030 }
success_lines:
  - { id: C1_S07a_L020, who: HERO, text: "There. There you go. Good boy.", emote: kneeling }
  - { id: C1_S07a_L021, who: HERO, text: "I don't know where she went either." }
  - { id: C1_S07a_L022, who: PROMPT, text: "Biscuit follows you." }
scare_lines:
  - { id: C1_S07a_L030, who: HERO, text: "GO! Get out of here!", style: shout }
  - { id: C1_S07a_L031, who: HERO, text: "...Sorry. Sorry.", beat: 1.5, emote: guilty }
backyard_route:
  hazards: [chain_link_fence_climb, guard_dog_on_chain (avoid radius), kiddie_pool (noise), motion_light]
  examine:
    - { id: C1_OBJ_BACKYARD_GRILL, text: "Burgers still on the grill. Smoke and no one." }
    - { id: C1_OBJ_BACKYARD_TV, text: "Through a window: a living room, a TV, a game paused. Two controllers on the couch. One person screaming into a phone." }
```

### C1_S07b: Dana (the key choice)

Direction: the Okoros' SUV has hit the lamppost at the corner of Linden Court. The driver's door is open and the seat is empty; Felix's seatbelt is still buckled across nothing. Dana is in the passenger seat, conscious, bleeding from the forehead, her belt jammed and her door crushed. Smoke rises from under the hood, and a small flame appears after 20 seconds. **She sees {HERO}.** The house is 150 metres away, and the porch light is visible from here.

This is the **key choice** of the chapter: help her (risk, time) or run home to Mom.

```yaml
scene: C1_S07b
name: "Dana"
location: STREET_LINDEN_COURT_CORNER
lines:
  - { id: C1_S07b_L001, who: DANA, text: "{HERO}! {HERO}, help me! Please!", style: shout }
  - { id: C1_S07b_L002, who: DANA, text: "He was driving. Felix was DRIVING. And then the wheel just—" }
  - { id: C1_S07b_L003, who: DANA, text: "The belt's stuck. I can't—my door won't—" }
  - { id: C1_S07b_L004, who: HERO, text: "Mom's not answering. I have to—", style: normal }
  - { id: C1_S07b_L005, who: DANA, text: "PLEASE.", style: shout, sfx: SFX_ENGINE_FIRE_START }
choices:
  - id: C1_S07b_CH01
    timer: 10                    # if it expires: the hero hesitates and the choice resolves as B (run home)
    default: B
    options:
      - { id: A, text: "[Help Dana.]", set: { C1_HELPED_DANA: true }, goto: RESCUE_DANA }
      - { id: B, text: "[Run home to Mom.]", set: { C1_HELPED_DANA: false }, goto: C1_S07b_L040 }
rescue:
  id: RESCUE_DANA
  timer_s: 45
  steps:
    - { step: 1, text: "Open the driver's door and climb across.", input: interact }
    - { step: 2, text: "Cut the seatbelt.", requires: ITEM_BOX_CUTTER, alt: "Without the box cutter: wrench the buckle (mash E / (A), slower)." }
    - { step: 3, text: "Pull Dana out through the driver's side.", input: "hold E / (A) and walk backward" }
    - { step: 4, text: "Drag her clear of the car.", input: "walk to the safe zone (Walt's lawn)" }
  fail: "At 45 s Walt arrives with a fire extinguisher and pulls her out with the hero. The hero is burned (permanent scar cosmetic; -1 max HP for Ch1-2). Still counts as HELPED."
  lines:
    - { id: C1_S07b_L010, who: HERO, text: "Hold still. I've got you." }
    - { id: C1_S07b_L011, who: DANA, text: "Felix. Where's Felix?" }
    - { id: C1_S07b_L012, who: HERO, text: "I don't know. I don't know." }
    - { id: C1_S07b_L013, who: DANA, text: "Hurry. Hurry, it's getting hot—", cond: "rescue_time > 25" }
    - { id: C1_S07b_L014, who: HERO, text: "Come on. Out. OUT.", style: shout }
  success_lines:
    - { id: C1_S07b_L020, who: DANA, text: "...", emote: coughing_on_lawn, sfx: SFX_CAR_FIRE_WHOOSH }
    - { id: C1_S07b_L021, who: WALT, text: "I got her. I got her, kid. Go home. Go find your mother." }
    - { id: C1_S07b_L022, who: DANA, text: "{HERO}.", beat: 0.8 }
    - { id: C1_S07b_L023, who: DANA, text: "...Thank you." }
    - { id: C1_S07b_L024, who: DANA, text: "He said they'd see your mom Sunday. Front row.", emote: dazed }
    - { goto: C1_S08 }
run_home:
  - { id: C1_S07b_L040, who: HERO, text: "I'm sorry. I'm sorry, I'll get help—" }
  - { id: C1_S07b_L041, who: DANA, text: "{HERO}! DON'T—", style: shout }
  - { id: C1_S07b_L042, who: WALT, text: "I got her! Go!", style: shout, beat: 2.0 }
  - { id: C1_S07b_L043, who: PROMPT, text: "Behind you, Walt is running toward the car with an extinguisher. You don't look back." }
  - { goto: C1_S08 }
```

**Consequence notes for later chapters.**
- `C1_HELPED_DANA = true`: in Ch2, Dana brings {HERO} antibiotics and a jug of water: "You came back for me." She becomes a trade contact until Ch3.
- `C1_HELPED_DANA = false`: Walt got her out, and she was burned. In Ch2 her burned SUV is still at the corner. She doesn't open her door to {HERO}, but leaves a note in Ch3: "I'd have run too. I think. -D."

---

## C1_S08: The Empty Chair

Direction: Linden Court is dark except for fires and headlights. **The Hale porch light is on.** The front door is unlocked. Inside, the house is exactly as the player left it: warm light, the fan turning, the TV muted with a ticker now reading "BREAKING". **No music** when the player enters. The chirp of the smoke alarm continues every 40 seconds. The player can move freely; the house is a search space. Each room has a "Mom?" call (`search` interaction). The kitchen is the last room the camera allows, or the player can go there first; either way, the empty chair is a fixed shot.

```yaml
scene: C1_S08
name: "The Empty Chair"
location: HOUSE_ALL_ROOMS_NIGHT
time: "21:31"
music: null
ambience: AMB_HOUSE_NIGHT_OUTSIDE_CHAOS   # house hum plus muffled sirens and alarms through the walls
sfx_loops: [ { id: SFX_SMOKE_CHIRP, interval_s: 40, area: HOUSE_UPSTAIRS_HALL, audible_house_wide: true } ]
tasks:
  - { id: C1_T06, text: "Find Mom." }
entry_lines:
  - { id: C1_S08_L001, who: HERO, text: "Mom?", sfx: SFX_DOOR_OPEN }
  - { id: C1_S08_L002, who: HERO, text: "Mom! I'm back!", cond: "C1_BISCUIT == befriended" }
  - { id: C1_S08_L003, who: HERO, text: "It's okay, Biscuit. Stay.", cond: "C1_BISCUIT == befriended" }
  - { id: C1_S08_L004, who: HERO, text: "Mom?" , beat: 1.5 }
search_calls:     # one per room, when the player uses "search" in that room
  - { id: C1_S08_L010, room: HOUSE_LIVING_ROOM, who: HERO, text: "Mom?" }
  - { id: C1_S08_L011, room: HOUSE_MOM_ROOM, who: HERO, text: "Mom? Are you up here?" }
  - { id: C1_S08_L012, room: HOUSE_BATHROOM, who: HERO, text: "Mom, I'm coming in. ...Mom?" }
  - { id: C1_S08_L013, room: HOUSE_BEDROOM_HERO, who: HERO, text: "...Why would she be in here." }
  - { id: C1_S08_L014, room: HOUSE_GARAGE, who: HERO, text: "Mom? The car's still here. Mom?" }
  - { id: C1_S08_L015, room: HOUSE_BACKYARD, who: HERO, text: "MOM!", style: shout }
  - { id: C1_S08_L016, room: HOUSE_BASEMENT_DOOR, who: HERO, text: "Mom? ...It's locked. She never locks it." }
objects_night:
  - id: C1_OBJ_MOM_CHAIR
    name: "Mom's chair"
    fixed_shot: true
    examine: "Pushed back from the table, the way you push a chair back to stand up."
  - id: C1_OBJ_MOM_MUG_NIGHT
    name: "Mom's mug"
    examine: "'WORLD'S OKAYEST MOM.' Tea. Half full. Still warm."
  - id: C1_OBJ_MOM_SLIPPERS
    name: "Slippers"
    examine: "Under the table. Both of them. Side by side, like she just stepped up out of them."
  - id: C1_OBJ_MOM_GLASSES_NIGHT
    name: "Reading glasses"
    examine: "On the open Bible. Folded. She always folds them."
  - id: C1_OBJ_MOM_PHONE_NIGHT
    name: "Mom's phone"
    examine: "On the table. 23 messages in the 'Thursday Bible Study' group. The last one was sent at 9:02 PM by Hollis: 'Praying for all of you tonight, friends. Something in my spirit says look up.' Nothing after."
  - id: C1_OBJ_BIBLE_OPEN
    name: "Mom's Bible (open)"
    examine: "Open to First Thessalonians, chapter four. Something is tucked inside, an envelope."
    pickup: [ITEM_MOM_BIBLE, ITEM_MOM_LETTER]
    on_pickup: { goto: C1_S09 }
  - id: C1_OBJ_TV_NIGHT
    name: "TV"
    examine: "'BREAKING: MILLIONS REPORTED MISSING WORLDWIDE.' The anchor's chair is empty. A producer is standing in shot, staring at it."
  - id: C1_OBJ_STOVE_NIGHT
    name: "The stove"
    examine: "Off. She turned it off. Of course she did."
  - id: C1_OBJ_PORCH_LIGHT
    name: "Porch light switch"
    examine: "On. 'I'll leave the light on.' You don't touch it."
fixed_shot_lines:   # triggered once, on the first examine of C1_OBJ_MOM_CHAIR
  - { id: C1_S08_L030, who: HERO, text: "...", beat: 2.0 }
  - { id: C1_S08_L031, who: HERO, text: "Mom.", beat: 1.5 }
  - { id: C1_S08_L032, who: HERO, text: "This isn't funny.", beat: 2.0 }
  - { id: C1_S08_L033, who: HERO, text: "...", sfx: SFX_SMOKE_CHIRP, beat: 3.0 }
music_on_bible_examine: MUS_LETTER_THEME_INTRO   # a single piano note sustains as the player picks up the Bible
```

---

## C1_S09: The Letter

Direction: {HERO} sits **in Mom's chair**, which is the only time the game uses this seat for the hero. The envelope is soft and handled; the paper inside has been folded and unfolded many times. Different inks show it was rewritten over years. On it, in Mom's handwriting:

> *{HERO}. Read this if I'm ever suddenly gone. (Not if I'm at the grocery store.)*

The letter is shown on a full-screen paper panel in a handwritten font, one page at a time, with the player advancing. **Music:** `MUS_LETTER_THEME`, piano alone; Mom's hum melody played slowly. **No other sound** except, once, the smoke alarm's chirp, during page 3.

The scripture is set in the same handwriting but in **red ink** (her red pen).

```yaml
scene: C1_S09
name: "The Letter"
location: HOUSE_KITCHEN_NIGHT
time: "21:48"
music: MUS_LETTER_THEME
ambience: null
ui: LETTER_PANEL
set_on_enter: { C1_READ_LETTER: true }
pages:
  - id: C1_S09_P1
    lines:
      - { id: C1_S09_L001, style: handwritten, text: "My {KID}," }
      - { id: C1_S09_L002, style: handwritten, text: "If you're reading this, then I'm gone, and I think you know where. I'm so sorry I'm not there to make you coffee and pretend I'm not watching you drink it." }
      - { id: C1_S09_L003, style: handwritten, text: "I first wrote this the week after Dad's funeral, when you stopped talking to God, and for a while, to me. I've rewritten it every couple of years. This version is from April, the week you moved home. You were so embarrassed. I was so happy. I'm sorry. I was." }
      - { id: C1_S09_L004, style: handwritten, text: "Whatever the last thing was that we said to each other, if it was kind, I'm glad. If it was short, don't you dare carry it. I heard the love under it. I always do." }

  - id: C1_S09_P2
    lines:
      - { id: C1_S09_L010, style: handwritten, text: "Here's what I believe just happened. I'm not guessing. It's written down, and He keeps His word:" }
      - { id: C1_S09_L011, style: scripture_red, text: "\"For the Lord himself shall descend from heaven with a shout, with the voice of the archangel, and with the trump of God: and the dead in Christ shall rise first: Then we which are alive and remain shall be caught up together with them in the clouds, to meet the Lord in the air: and so shall we ever be with the Lord.\" (1 Thessalonians 4:16-17)" }
      - { id: C1_S09_L012, style: handwritten, text: "In a moment. In the twinkling of an eye (1 Corinthians 15:52). That's how fast. I hope it didn't scare you too badly. I hope I didn't drop anything heavy on your foot." }
      - { id: C1_S09_L013, style: handwritten, text: "That means Dad's there too. I'm with your father, {KID}. Isn't that something." }

  - id: C1_S09_P3
    sfx_once: { id: SFX_SMOKE_CHIRP, at_line: C1_S09_L022 }
    lines:
      - { id: C1_S09_L020, style: handwritten, text: "Now the hard part. I won't lie to you, I never have. What comes next will be the hardest time the world has ever seen. Jesus said so Himself (Matthew 24:21). People will be scared and hungry, and they'll do scary, hungry things. Some of them will be our neighbours. Be kind anyway. Be careful anyway." }
      - { id: C1_S09_L021, style: handwritten, text: "A man will come with a plan for peace. Everybody will love him. Don't. When they say peace, it isn't:" }
      - { id: C1_S09_L022, style: scripture_red, text: "\"For when they shall say, Peace and safety; then sudden destruction cometh upon them.\" (1 Thessalonians 5:3)" }
      - { id: C1_S09_L023, style: handwritten, text: "And one day they'll ask you to take a mark, in your hand or on your forehead, so you can buy groceries (Revelation 13:16-17). Whatever they call it, however sweetly they ask, however hungry you are: DON'T. I'm begging you. Read Revelation 14:9-10 if you don't believe me. Then read it again." }

  - id: C1_S09_P4
    lines:
      - { id: C1_S09_L030, style: handwritten, text: "But listen. LISTEN. This is the part I've rewritten the most." }
      - { id: C1_S09_L031, style: handwritten, text: "It is not too late for you. Not even now. Not even after everything you've said about Him, which, I'll remind you, He heard, and He still wants you." }
      - { id: C1_S09_L032, style: scripture_red, text: "\"That if thou shalt confess with thy mouth the Lord Jesus, and shalt believe in thine heart that God hath raised him from the dead, thou shalt be saved.\" (Romans 10:9)" }
      - { id: C1_S09_L033, style: scripture_red, text: "\"For whosoever shall call upon the name of the Lord shall be saved.\" (Romans 10:13)" }
      - { id: C1_S09_L034, style: handwritten, text: "Whosoever. That's you. I checked." }
      - { id: C1_S09_L035, style: handwritten, text: "You don't need the right words. Talk to Him like you talk to me when you're mad. He can take it. He's been knocking on your door for eleven years:" }
      - { id: C1_S09_L036, style: scripture_red, text: "\"Behold, I stand at the door, and knock: if any man hear my voice, and open the door, I will come in to him, and will sup with him, and he with me.\" (Revelation 3:20)" }

  - id: C1_S09_P5
    lines:
      - { id: C1_S09_L040, style: handwritten, text: "Practical things, because I'm still your mother:" }
      - { id: C1_S09_L041, style: handwritten, text: "- The basement. The key is in the sugar tin. Under the stairs: water (12 jugs), cans, the first aid kit, batteries, Dad's camping stove, the hand-crank radio. I know. I KNOW. You laughed at me. Laugh now, I dare you." }
      - { id: C1_S09_L042, style: handwritten, text: "- The coffee can on the top shelf has cash. Spend it fast. I don't think cash will last long." }
      - { id: C1_S09_L043, style: handwritten, text: "- Dad's toolbox is in the garage. You were always good with your hands. Like him." }
      - { id: C1_S09_L044, style: handwritten, text: "- Read my Bible. Start with John. Then read Revelation slowly, with a pencil, and don't skip the scary parts. I underlined what helped me. Maybe it'll help you." }
      - { id: C1_S09_L045, style: handwritten, text: "- Ezra Kamau from church may come by. If he's still here, it means he missed it too. Let him in. He's a good man, and he'll be very sad." }

  - id: C1_S09_P6
    lines:
      - { id: C1_S09_L050, style: handwritten, text: "I'm not lost, {KID}. I'm home. Jesus promised:" }
      - { id: C1_S09_L051, style: scripture_red, text: "\"In my Father's house are many mansions: if it were not so, I would have told you. I go to prepare a place for you. And if I go and prepare a place for you, I will come again, and receive you unto myself; that where I am, there ye may be also.\" (John 14:2-3)" }
      - { id: C1_S09_L052, style: handwritten, text: "There's a place for you too. I asked. I'll be waiting right by the door, and I'll leave the light on." }
      - { id: C1_S09_L053, style: handwritten, text: "Come home, {KID}." }
      - { id: C1_S09_L054, style: handwritten, text: "All my love, forever and then some,\nMom" }
      - { id: C1_S09_L055, style: handwritten, text: "P.S. The smoke alarm in the hall needs a 9-volt. I know you forgot.", beat: 1.5 }

after_letter:   # returns to gameplay view; hero still in Mom's chair
  - { id: C1_S09_L060, who: HERO, text: "...", beat: 3.0 }
  - { id: C1_S09_L061, who: HERO, text: "I didn't forget.", cond: "C1_HAS_BATTERY == true" }
  - { id: C1_S09_L062, who: HERO, text: "I had it. I had it, Mom.", cond: "C1_HAS_BATTERY == false" }
  - { id: C1_S09_L063, who: HERO, text: "I said I loved you. At least I said it.", cond: "C1_LAST_WORDS == kind", beat: 1.5 }
  - { id: C1_S09_L064, who: HERO, text: "'Back in twenty.' That's what I said. Back in twenty.", cond: "C1_LAST_WORDS == curt", beat: 1.5 }
  - { id: C1_S09_L065, who: HERO, text: "You laughed. At least you were laughing.", cond: "C1_LAST_WORDS == joke", beat: 1.5 }
  - { id: C1_S09_L066, who: HERO, text: "...", beat: 2.0 }
  - { id: C1_S09_L067, who: PROMPT, text: "Mom's Bible and letter added to your inventory. You can reread them at any time." }
tasks_after:
  - { id: C1_T07, text: "Find the basement key (the sugar tin).", object: C1_OBJ_SUGAR_TIN }
objects:
  - id: C1_OBJ_SUGAR_TIN
    name: "Sugar tin"
    examine: "Sugar. And a small brass key wrapped in a sticky note: 'Told you.'"
    pickup: ITEM_BASEMENT_KEY
```

---

## C1_S10: The Basement

Direction: as the player unlocks the basement door, **the power fails across the whole town** (23:14). The fridge hum dies and so do the fan and the porch light. The silence is a different kind from the store's: the alarms outside continue, but the house is dead. The player must find the flashlight in the kitchen junk drawer (the letter didn't mention it, but the junk drawer is where everything is) and go down. Teach flashlight, battery life and limited light.

```yaml
scene: C1_S10
name: "The Basement"
location: HOUSE_KITCHEN_DARK, HOUSE_BASEMENT
time: "23:14"
music: null
ambience: AMB_HOUSE_DARK       # no hum; outside sirens louder; a dripping pipe
events:
  - { t: 0.0, action: power_fail, sfx: SFX_POWER_DOWN, set_world: { power: off, porch_light: off } }
lines:
  - { id: C1_S10_L001, who: HERO, text: "No. No, no, no." }
  - { id: C1_S10_L002, who: HERO, text: "...The porch light.", beat: 1.5 }
  - { id: C1_S10_L003, who: PROMPT, text: "Find a light. Kitchen drawers." }
tasks:
  - { id: C1_T08, text: "Find a flashlight.", object: C1_OBJ_JUNK_DRAWER }
  - { id: C1_T09, text: "Search the basement.", set_on_complete: { C1_FOUND_STASH: true } }
objects:
  - id: C1_OBJ_JUNK_DRAWER
    name: "Junk drawer"
    examine: "Takeout menus, birthday candles, a screwdriver, eleven pens (two work), and a flashlight. Mom labelled it 'FLASHLIGHT.'"
    pickup: ITEM_FLASHLIGHT
    prompt: "Flashlight: F / (Y). Batteries drain. Use it wisely."
  - id: C1_OBJ_STASH_WATER
    name: "Water jugs"
    examine: "Twelve gallon jugs, each dated in marker. The oldest says 2021. She's been rotating them for nine years."
    pickup: ITEM_WATER_JUG x4    # carry limit; the rest stay as the house supply
  - id: C1_OBJ_STASH_CANS
    name: "Shelves of cans"
    examine: "Soup, beans, peaches, tuna. Alphabetised. Of course they're alphabetised."
    pickup: ITEM_CANNED_FOOD x6
  - id: C1_OBJ_STASH_MEDKIT
    name: "First aid kit"
    examine: "A real one, not a box of bandages. A note taped inside the lid: 'Ask June at the clinic if you don't know what something does.' You don't know a June."
    pickup: ITEM_MEDKIT
  - id: C1_OBJ_STASH_RADIO
    name: "Hand-crank radio"
    examine: "Still in the box. Dad bought it in 2012, after the big storm. It has a little solar panel."
    pickup: ITEM_CRANK_RADIO
  - id: C1_OBJ_STASH_STOVE
    name: "Dad's camping stove"
    examine: "Dented green steel. It smells like every camping trip. Two fuel canisters beside it."
    pickup: ITEM_CAMP_STOVE
  - id: C1_OBJ_STASH_BATTERIES
    name: "Box of batteries"
    examine: "AA, AAA, D. And at the bottom, in its own bag with a sticky note: one 9-volt. 'For when you forget.'"
    pickup: [ITEM_BATTERIES_AA, ITEM_BATTERY_9V]
    set: { C1_HAS_BATTERY: true }
  - id: C1_OBJ_COFFEE_CAN
    name: "Coffee can (top shelf)"
    examine: "Rolled bills, $640, and a folded index card: 'Spend it FAST.'"
    pickup: ITEM_CASH
  - id: C1_OBJ_DAD_WORKBENCH
    name: "Dad's old workbench"
    examine: "His pencil marks are still on the wood. 'Measure twice.' He wrote it there so he'd stop forgetting."
  - id: C1_OBJ_CHRISTMAS_BOX
    name: "Box marked 'CHRISTMAS'"
    examine: "Ornaments. On top, the clay angel you made in first grade. It has one wing. Mom put it on top of the tree every single year."
lines_after_battery:
  - { id: C1_S10_L020, who: HERO, text: "'For when you forget.'", cond: "picked up ITEM_BATTERY_9V from stash" }
  - { id: C1_S10_L021, who: HERO, text: "...You knew me so well.", beat: 1.0 }
```

---

## C1_S11: The Stranger

Direction: 1:42 AM. {HERO} has fallen asleep on the living-room couch with the flashlight. A sound wakes {THEM}: the back door handle rattling. Then glass breaking. The player has 8 seconds of "waking up" before control returns. This is a **stealth and defence tutorial** with three resolutions. The stranger is a man in his 40s, wild-eyed, thirsty; his wife is diabetic and the pharmacies were looted. He is not a monster.

```yaml
scene: C1_S11
name: "The Stranger"
location: HOUSE_GROUND_FLOOR_DARK
time: "01:42"
music: MUS_STEALTH_LOW            # sparse, ticking, very low
ambience: AMB_HOUSE_DARK
events:
  - { t: 0.0, action: play_sfx, id: SFX_DOOR_HANDLE_RATTLE }
  - { t: 2.5, action: play_sfx, id: SFX_GLASS_BREAK_SMALL }
  - { t: 4.0, action: play_sfx, id: SFX_FOOTSTEPS_GLASS }
lines:
  - { id: C1_S11_L001, who: HERO, text: "...", emote: wakes_up }
  - { id: C1_S11_L002, who: HERO, text: "Mom?", style: whisper }
  - { id: C1_S11_L003, who: STRANGER, text: "Anybody here? Hello?", style: whisper }
  - { id: C1_S11_L004, who: PROMPT, text: "Flashlight off: F / (Y). Sneak: hold C / (B). Hide: E / (A) at a hiding spot." }
choices:
  - id: C1_S11_CH01
    timer: 0
    note: "Not a menu: the outcome is determined by what the player does."
    outcomes:
      - { id: hid, trigger: "player stays hidden until the stranger leaves (about 60 s)", set: { C1_INTRUDER: hid } }
      - { id: scared_off, trigger: "player makes loud noise (pans, shouting, slamming a door) without being seen", set: { C1_INTRUDER: scared_off } }
      - { id: fought, trigger: "player confronts the stranger (hit, shove, or flashlight in the face)", set: { C1_INTRUDER: fought } }
hiding_spots: [UNDER_STAIRS_CLOSET, PANTRY, BEHIND_RECLINER, BASEMENT_STAIRS]
noise_objects:
  - { id: C1_OBJ_POT_RACK, text: "Mom's pots. Loud ones." }
  - { id: C1_OBJ_FOURTH_STAIR, text: "The creaky fourth stair. It'll give you away, or it'll scare him." }
stranger_barks:
  - { id: C1_S11_L010, who: STRANGER, text: "I just need water. That's all. I'm not gonna hurt anybody." }
  - { id: C1_S11_L011, who: STRANGER, text: "The taps are dry on Birch Street. You hear me? DRY." }
  - { id: C1_S11_L012, who: STRANGER, text: "My wife needs her insulin. The pharmacy's gone. Everything's gone." }
  - { id: C1_S11_L013, who: STRANGER, text: "Please. Please, if somebody's here." }
outcome_lines:
  hid:
    - { id: C1_S11_L020, who: STRANGER, text: "...", sfx: SFX_FRIDGE_OPEN_EMPTY }
    - { id: C1_S11_L021, who: STRANGER, text: "...God help us.", style: whisper, sfx: SFX_FOOTSTEPS_LEAVING }
    - { id: C1_S11_L022, who: HERO, text: "...", beat: 2.0 }
  scared_off:
    - { id: C1_S11_L030, who: STRANGER, text: "Okay! Okay, I'm going! I'm going!", style: shout, sfx: SFX_FOOTSTEPS_RUN }
  fought:
    - { id: C1_S11_L040, who: STRANGER, text: "Don't! Don't, I'm going—", style: shout }
    - { id: C1_S11_L041, who: STRANGER, text: "...", emote: falls_and_flees, sfx: SFX_FOOTSTEPS_RUN }
    - { id: C1_S11_L042, who: HERO, text: "...He wanted water.", beat: 1.5 }
gave_water_option:
  note: "In any outcome, if the player has ITEM_WATER_JUG and is within 3 m of the stranger before he leaves, a prompt appears."
  prompt: { id: C1_S11_L050, who: PROMPT, text: "Give him a water jug? (E / A)" }
  on_accept:
    set: { C1_GAVE_WATER: true }
    remove_item: ITEM_WATER_JUG x1
    lines:
      - { id: C1_S11_L051, who: HERO, text: "Here. Take it. Go." }
      - { id: C1_S11_L052, who: STRANGER, text: "...", beat: 1.5, emote: stares }
      - { id: C1_S11_L053, who: STRANGER, text: "Thank you. Thank you. God bless you." }
      - { id: C1_S11_L054, who: HERO, text: "...Yeah.", beat: 1.0 }
task_after:
  - { id: C1_T10, text: "Block the broken back door.", object: C1_OBJ_BACK_DOOR, input: "drag the kitchen table / Dad's toolbox board (hold E / A)" }
```

**Biscuit:** if `C1_BISCUIT == befriended`, Biscuit growls before the glass breaks (an early warning) and stays with {HERO} when hiding. If the player picks "fought," Biscuit barks and the stranger flees faster.

---

## C1_S12: Before Dawn

Direction: 4:51 AM. Grey light at the windows. The town is quieter: fewer alarms, more sirens far away, birds starting. {HERO} hasn't slept again. Two small, optional, important things are available: **fix the smoke alarm** and **sit in Mom's chair** (pray). Neither is required. The game waits; a soft prompt appears after 60 seconds if neither is done, and the scene ends when the player walks to the radio/TV in the living room.

```yaml
scene: C1_S12
name: "Before Dawn"
location: HOUSE_UPSTAIRS_HALL, HOUSE_KITCHEN_DAWN
time: "04:51"
music: null
ambience: AMB_DAWN_AFTERMATH    # first birds, far sirens, a dog barking, wind
sfx_loops: [ { id: SFX_SMOKE_CHIRP, interval_s: 40, area: HOUSE_UPSTAIRS_HALL, audible_house_wide: true, until_flag: "C1_ALARM_FIXED == true" } ]

task_alarm:
  id: C1_T11
  text: "(Optional) Replace the smoke alarm battery."
  requires: ITEM_BATTERY_9V
  object: C1_OBJ_SMOKE_ALARM
  steps:
    - "Drag the hall chair under the alarm."
    - "Stand on it, twist off the cover, swap the battery (a short 3-step mini-task)."
  on_complete:
    set: { C1_ALARM_FIXED: true }
    sfx: [SFX_ALARM_TEST_BEEP]     # one long test beep, then nothing, ever again
    lines:
      - { id: C1_S12_L001, who: HERO, text: "...", beat: 2.0 }
      - { id: C1_S12_L002, who: HERO, text: "There." }
      - { id: C1_S12_L003, who: HERO, text: "It's fixed, Mom.", beat: 1.5 }
      - { id: C1_S12_L004, who: HERO, text: "It's so quiet now.", beat: 2.0 }
  if_no_battery:
    lines:
      - { id: C1_S12_L005, who: HERO, text: "No battery. Of course.", cond: "C1_HAS_BATTERY == false" }
      - { id: C1_S12_L006, who: HERO, text: "Just keep chirping, then. Somebody should make noise in this house.", cond: "C1_HAS_BATTERY == false" }

task_pray:
  id: C1_T12
  text: "(Optional) Sit in Mom's chair."
  object: C1_OBJ_MOM_CHAIR
  prompt: { id: C1_S12_L010, who: PROMPT, text: "Hold P / (LB) to pray. You don't know how." }
  if_held:
    set: { C1_PRAYED: true }
    music: MUS_HUM_FRAGMENT       # three notes of Mom's hum, played on a soft piano, then it stops
    lines:
      - { id: C1_S12_L011, who: HERO, text: "I don't know if You're there.", beat: 1.0 }
      - { id: C1_S12_L012, who: HERO, text: "She thought You were. She was never wrong about anything. It was annoying.", beat: 1.5 }
      - { id: C1_S12_L013, who: HERO, text: "If she's with You..." , beat: 2.0 }
      - { id: C1_S12_L014, who: HERO, text: "Tell her I got the battery.", cond: "C1_HAS_BATTERY == true", beat: 1.5 }
      - { id: C1_S12_L015, who: HERO, text: "Tell her I'm sorry about the battery.", cond: "C1_HAS_BATTERY == false", beat: 1.5 }
      - { id: C1_S12_L016, who: HERO, text: "...That's all I've got.", beat: 2.0 }
  if_released_early_or_skipped:
    set: { C1_PRAYED: false }
    lines:
      - { id: C1_S12_L020, who: HERO, text: "...Not yet.", beat: 1.5 }

objects:
  - id: C1_OBJ_WINDOW_DAWN
    name: "Window"
    examine: "Linden Court in grey light. The Okoros' SUV, black and burned out. Noah's bike, upright now: someone stood it up against the lamppost. Walt is asleep in his rocking chair with the shotgun across his knees."
  - id: C1_OBJ_FRIDGE_DAWN
    name: "Fridge"
    examine: "Warm. The milk you brought home is going to spoil by noon. The crayon drawing is still there. 'BEST LIBERRIAN.'"
  - id: C1_OBJ_CANDY
    name: "Peanut butter cups"
    cond: "has ITEM_CANDY"
    examine: "You bought them for her. You put them on her plate. You don't know why."
next_on_interact: { C1_OBJ_RADIO_KITCHEN: C1_S13, C1_OBJ_CRANK_RADIO_USE: C1_S13 }
```

---

## C1_S13: The Broadcast

Direction: 6:02 AM. The player turns on Mom's battery radio (or cranks Dad's radio from the stash). Static, then an emergency tone, then a calm synthetic voice (the standard emergency alert format, made up, no real agency names). Between bursts the player can switch "stations" (scroll the dial) and open their phone's Murmur feed, which has one bar of signal. Everything is **chatter** (see STORY_BIBLE section 7). Nothing is confirmed. The player can listen as long as they like. The scene ends when the player sets the radio down, or after all the main lines.

```yaml
scene: C1_S13
name: "The Broadcast"
location: HOUSE_KITCHEN_DAWN
time: "06:02"
music: null
ambience: AMB_DAWN_AFTERMATH
ui: RADIO_DIAL_AND_FEED      # left: dial with 3 stations; right: phone feed, scrollable
sfx: [SFX_RADIO_STATIC, SFX_EMERGENCY_TONE]

station_1_emergency:   # always first
  - { id: C1_S13_L001, who: RADIO, style: broadcast, text: "[TONE]" , sfx: SFX_EMERGENCY_TONE }
  - { id: C1_S13_L002, who: RADIO, style: broadcast, text: "This is an emergency alert for all residents of the tri-state area." }
  - { id: C1_S13_L003, who: RADIO, style: broadcast, text: "At approximately 9:03 PM Eastern last night, a large number of persons were reported missing worldwide." }
  - { id: C1_S13_L004, who: RADIO, style: broadcast, text: "The cause is unknown. Officials ask the public to remain calm and remain indoors." }
  - { id: C1_S13_L005, who: RADIO, style: broadcast, text: "Do not attempt to travel. Major roads, bridges and tunnels into New York City are closed." }
  - { id: C1_S13_L006, who: RADIO, style: broadcast, text: "Boil all tap water. Do not call emergency services unless there is an immediate threat to life." }
  - { id: C1_S13_L007, who: RADIO, style: broadcast, text: "Report missing persons through your local relief center when it opens. Further information will follow." }
  - { id: C1_S13_L008, who: RADIO, style: broadcast, text: "[TONE]" }

station_2_ridge_radio:   # local community radio, a volunteer host who stayed up all night
  - { id: C1_S13_L020, who: RADIO, text: "...still here. Ridge Radio. It's me, it's just me, the engineer's gone. Or. I don't know." }
  - { id: C1_S13_L021, who: RADIO, text: "Callers. Line one, you're on." }
  - { id: C1_S13_L022, who: RADIO, text: "CALLER: It's the rapture. My grandmother told me. My grandmother TOLD me!" }
  - { id: C1_S13_L023, who: RADIO, text: "CALLER: That's ridiculous. It's an attack. Some kind of weapon. They hit the cities first." }
  - { id: C1_S13_L024, who: RADIO, text: "CALLER: Then why'd they take my baby? Why would a weapon take my BABY?", beat: 1.0 }
  - { id: C1_S13_L025, who: RADIO, text: "...Okay. Okay. Let's. Let's take a minute.", beat: 2.0 }
  - { id: C1_S13_L026, who: RADIO, text: "Shelter at the middle school gym is open. Bring blankets. Bring water if you have it." }
  - { id: C1_S13_L027, who: RADIO, text: "And if your kids are gone... I'm sorry. I'm so sorry. Mine too." }

station_3_far_station:   # distant, crackling, a late-night talk host
  - { id: C1_S13_L030, who: RADIO, text: "...I've been saying this for YEARS, folks. They're not gone. They're TAKEN. Up. Into a ship." }
  - { id: C1_S13_L031, who: RADIO, text: "Why do you think the planes fell? Why do you think the satellites went dark at 9:02?" }
  - { id: C1_S13_L032, who: RADIO, text: "CALLER: Some people are saying fallen angels, that the Nephilim—" }
  - { id: C1_S13_L033, who: RADIO, text: "We are NOT doing angels on this show. We're doing facts. Next caller." }

feed_murmur:   # phone feed, scrollable, each a separate card. Handles are invented.
  - { id: C1_S13_L040, who: FEED, style: feed, text: "@ridgewatch: anyone on linden ct?? the hale house porch light was on all night then went out w the grid. pls tell me someone's ok" }
  - { id: C1_S13_L041, who: FEED, style: feed, text: "@nightnurse_ana: 3 doctors gone mid-surgery at my hospital. ALL the newborns in the NICU. I can't. I can't." }
  - { id: C1_S13_L042, who: FEED, style: feed, text: "@truthseeker_0: GOVERNMENT EXPERIMENT. A frequency test went wrong. Watch my video before they delete it." }
  - { id: C1_S13_L043, who: FEED, style: feed, text: "@grace_notes_77: Matthew 24:40. 'Then shall two be in the field; the one shall be taken, and the other left.' I was left. I knew better. I knew better." }
  - { id: C1_S13_L044, who: FEED, style: feed, text: "@alt_skywatch: UNEXPLAINED LIGHT over the ocean at 9:03, five witnesses. Not saying aliens. Saying not NOT aliens." }
  - { id: C1_S13_L045, who: FEED, style: feed, text: "@marketpulse: Trading halted globally. Payment systems 'experiencing interruptions.' Stock up on whatever you can, people." }
  - { id: C1_S13_L046, who: FEED, style: feed, text: "@halvern_moms: Has anyone seen Ines Albright? Her dog was found by the alley. Her glasses were on the sidewalk." }
  - { id: C1_S13_L047, who: FEED, style: feed, text: "@worldnews_relay: Leaders call for emergency summit. 'Humanity must stand together,' said one envoy. Names of attendees to follow." }

end_lines:
  - { id: C1_S13_L060, who: HERO, text: "...", beat: 2.0 }
  - { id: C1_S13_L061, who: HERO, text: "Everybody's got a theory.", beat: 1.0 }
  - { id: C1_S13_L062, who: HERO, text: "Mom had a letter.", beat: 2.0 }
  - { id: C1_S13_L063, who: PROMPT, text: "Mom's Bible: First Thessalonians 4 is marked. Read it now? (Optional)" }
optional_read:
  - { id: C1_S13_L064, who: CAPTION, style: scripture, text: "\"For the Lord himself shall descend from heaven with a shout, with the voice of the archangel, and with the trump of God...\" (1 Thessalonians 4:16)" }
  - { id: C1_S13_L065, who: CAPTION, style: scripture, text: "\"Wherefore comfort one another with these words.\" (1 Thessalonians 4:18)" }
next: C1_S14
```

---

## C1_S14: End Card

Direction: fade to the window shot of the Hale house from the street, at dawn. The porch light is dark. Hold. Then black.

```yaml
scene: C1_S14
name: "End Card"
location: STREET_LINDEN_COURT_DAWN -> BLACK
music: MUS_CHAPTER_END           # Mom's hum melody, solo cello, one phrase, unresolved
lines:
  - { id: C1_S14_L001, who: CAPTION, text: "Of the people who vanished, no one came back.", beat: 2.0 }
  - { id: C1_S14_L002, who: CAPTION, text: "Of the people who stayed, everyone had a theory." , beat: 1.5 }
  - { id: C1_S14_L003, who: CAPTION, text: "[ CHAPTER 1: NIGHT ONE ]", beat: 2.5 }
  - { id: C1_S14_L004, who: CAPTION, text: "", beat: 2.0 }
  - { id: C1_S14_L005, who: CAPTION, text: "Chapter 2", style: title }
  - { id: C1_S14_L006, who: CAPTION, text: "Three months later...", style: title, beat: 1.5 }
  - { id: C1_S14_L007, who: CAPTION, text: "\"For when they shall say, Peace and safety...\" (1 Thessalonians 5:3)", style: scripture, beat: 1.5 }
save_point: true
flags_carried: [C1_GRACE, C1_FAITH_TALK, C1_LAST_WORDS, C1_MET_INES, C1_LOOTER, C1_HAS_BATTERY, C1_BISCUIT, C1_HELPED_DANA, C1_READ_LETTER, C1_FOUND_STASH, C1_INTRUDER, C1_GAVE_WATER, C1_ALARM_FIXED, C1_PRAYED]
next_chapter: C2
```

---

## Music and Sound Cue Summary

| Scene | Music | Ambience | Key SFX |
|---|---|---|---|
| S00 | none | AMB_CICADAS_FAR | - |
| S01 | MUS_HOME_EVENING | AMB_HOUSE_SUMMER | SFX_PHONE_BUZZ |
| S02 | none | AMB_HOUSE_SUMMER | SFX_SMOKE_CHIRP, SFX_MOM_HUM |
| S03 | MUS_DINNER | AMB_KITCHEN | SFX_CHAIR_SCRAPE, SFX_SMOKE_CHIRP_DISTANT |
| S03b | MUS_DINNER_TAIL | AMB_HOUSE_SUMMER | SFX_PORCH_LIGHT_CLICK |
| S04 | MUS_SUMMER_STREET | AMB_SUBURB_DUSK | SFX_DOG_BARK_SMALL |
| S05 | none | AMB_STORE | SFX_DOOR_CHIME, SFX_SCANNER_BEEP, SFX_HOLLIS_HUM |
| MOMENT | **total silence, 4.0 s** | **muted** | SFX_TRUMPET_FAINT (0.08 vol), then SFX_CRASH_BIG, SFX_CAR_ALARMS, SFX_SCREAM_DISTANT, SFX_PHONE_BUZZ_COUNTER |
| S06 | MUS_TENSION_LOW | AMB_STORE_ALARMED | SFX_SHELF_SWEEP, SFX_DOOR_CHIME_SLAM |
| S07 | MUS_CHAOS_PULSE | AMB_STREET_CHAOS | SFX_CALL_FAIL, SFX_ENGINE_FIRE_START, SFX_CAR_FIRE_WHOOSH |
| S08 | none | AMB_HOUSE_NIGHT_OUTSIDE_CHAOS | SFX_DOOR_OPEN, SFX_SMOKE_CHIRP |
| S09 | MUS_LETTER_THEME (piano, Mom's hum melody) | none | SFX_SMOKE_CHIRP (once, page 3) |
| S10 | none | AMB_HOUSE_DARK | SFX_POWER_DOWN |
| S11 | MUS_STEALTH_LOW | AMB_HOUSE_DARK | SFX_DOOR_HANDLE_RATTLE, SFX_GLASS_BREAK_SMALL, SFX_FOOTSTEPS_GLASS |
| S12 | none / MUS_HUM_FRAGMENT if praying | AMB_DAWN_AFTERMATH | SFX_ALARM_TEST_BEEP |
| S13 | none | AMB_DAWN_AFTERMATH | SFX_RADIO_STATIC, SFX_EMERGENCY_TONE |
| S14 | MUS_CHAPTER_END (solo cello) | - | - |

**Audio motifs to keep consistent across the game**
- **Mom's hum** (an original melody): S02 (hummed), S09 (piano), S12 (three notes), S14 (cello), Epilogue (full ensemble).
- **The chirp**: grief made audible. If `C1_ALARM_FIXED == false`, it continues into Ch2 until the player finds a 9-volt.
- **The faint trumpet tone**: in the MOMENT only; returns in full in Chapter 10.

---

## Art Needs (Chapter 1)

**Tilesets and environments**
1. 12 Linden Court, a 1970s two-storey colonial. Interiors: hero's bedroom, upstairs hall, Mom's bedroom, bathroom, stairs, living room, kitchen with dining nook, front hall, garage, basement (shelves, workbench), backyard with tomato garden. Each in **three lighting states**: evening (warm), night with power (lamp-lit), dark (flashlight only), plus dawn (grey-blue).
2. Linden Court cul-de-sac: six houses (Hale, Dunmore, Okoro, Lindqvist, Albright, the For-Sale house), lawns, sprinklers, lampposts. Two states: dusk (alive) and night chaos (fires, abandoned cars, debris), plus a dawn aftermath.
3. Ridge Road: strip of shops, crossing, corner. The alley shortcut. Backyards route (fences, kiddie pool, grill, chained guard dog, motion light).
4. Ridge Corner Market interior: 3 aisles, fridges, register counter, lottery screen, small TV, notice board. Normal and post-moment (spilled items, flickering lights).

**Characters (top-down sprite plus dialogue portrait set)**
- {HERO} (3 body/presentation options for pronoun choice, sharing one animation set). Portraits: neutral, groggy, smile, worried, crying, shaking, kneeling.
- Mom (Marian): sprite with stove, sitting, standing in doorway, hands folded (grace). Portraits: smile, wink, soft, amused, laugh, watches.
- Walt Dunmore (garden hose, porch with shotgun, sleeping in chair).
- Felix and Dana Okoro (Dana: normal, injured in car, on lawn).
- Noah Lindqvist (on bike) and Erik Lindqvist (porch, screaming in street).
- Ines Albright (walking) and **Biscuit** (walk, sniff, bark, panicked snarl, calm sit, follow, growl).
- Hollis Grant (register, humming).
- Wade Pruitt (phone call, panic, lunge, grab, stumble-out, crying).
- Stranger (sneaking, pleading, fleeing).
- Background panicked neighbours (3-4 variants).

**Props and FX**
- Dropped items: scanner gun, reading glasses, phone (with "ELLEN calling" screen), name tag; empty leash; child's sneaker; spinning bike wheel (looped animation).
- Crashed SUV with smoke and fire (states: smoking, small flame, burning, burned out). Driver seatbelt buckled across an empty seat.
- Self-driving delivery van (circling).
- Smoke alarm (close-up for the mini-task), chair, battery.
- Mom's Bible (closed, open), letter envelope, and **full-screen letter paper panel** (handwritten font with black and red ink, different ink tones per rewrite era).
- Flashlight cone and limited-light shader. Power-fail transition.
- Radio dial UI (3 stations) and phone Murmur feed UI (fictional app, no real-world design references).
- Sky: dusk, night with orange city glow and falling plane silhouettes (far, small, not graphic), dawn.

**UI**
- Typed-text dialogue box with portrait; handwritten and scripture text styles; system/phone style; broadcast style; feed card style.
- Prompt bar, task list, inventory grid with item icons (milk, bread, 9V, tote, card, keys, box cutter, phone, Bible, letter, basement key, flashlight, water jug, cans, medkit, crank radio, camp stove, batteries, cash, candy).
- Title and chapter cards.

**Sensitivity notes for art**
- The vanishing is **not** a light show. No beams, no glow, no ascending figures. The person is simply not there.
- No gore. The crash and fire are shown at a distance in pixel scale. Dana's injury is a small red mark.
- Children's absence is shown only through objects (the bike, the sneaker, the NICU feed post). Never show a child vanishing on screen.
