# Chatter Library: Chapters 1-3

Project R (Project Revelation). Radio, feed, graffiti, flyer and shelter chatter.

> **Rules (from STORY_BIBLE section 7).**
> - Chatter is **never confirmed**: no scene, item or cutscene proves a theory true.
> - Only Scripture is presented as truth, and only when it is quoted accurately with a citation.
> - Everything here is fictional: no real people, networks, hosts, apps, brands, call signs or slogans. Feed handles are invented.
> - The regime's official messaging is chatter too.

**Source tags** (for UI styling): `RADIO`, `FEED` (Murmur posts), `GRAFFITI`, `FLYER`, `SHELTER` (overheard argument or bark), `BROADCAST` (official alerts and Concord messaging).

**Fields:** `id`, `ch` (earliest chapter it can play), `src`, `text`, `theme`. Lines can be pulled at random by chapter and source unless the `theme` is `scripted` (used in a specific scene).

**Themes:** `aliens`, `angels`, `govt`, `science`, `faith`, `grief`, `survival`, `regime`, `gang`, `rumour`, `humour`.

```yaml
chatter:
  # ---------------- CHAPTER 1: Night One (July 12-13, 2030) ----------------
  - { id: CH_001, ch: 1, src: RADIO,    theme: aliens,   text: "They didn't vanish. They were LIFTED. Tell me what lifts a whole maternity ward. Tell me." }
  - { id: CH_002, ch: 1, src: RADIO,    theme: govt,     text: "Every satellite blinked at 9:02. One minute before. Ask yourself who knew." }
  - { id: CH_003, ch: 1, src: FEED,     theme: grief,    text: "@coffee_and_cats: my daughter was holding my hand in the parking lot. I'm still holding my hand out. I can't put it down." }
  - { id: CH_004, ch: 1, src: FEED,     theme: science,  text: "@phys_nerd_ok: Before anyone says 'quantum': no. That's not how any of this works. I don't know what this is. Nobody does." }
  - { id: CH_005, ch: 1, src: FEED,     theme: faith,    text: "@grace_notes_77: 'In a moment, in the twinkling of an eye, at the last trump.' 1 Corinthians 15:52. My pastor preached it every year. He's gone. I'm here." }
  - { id: CH_006, ch: 1, src: FEED,     theme: angels,   text: "@nephilim_truth: FALLEN ANGELS harvested them. Genesis 6 is happening again. Wake up." }
  - { id: CH_007, ch: 1, src: FEED,     theme: rumour,   text: "@ridgewatch: Ridge Corner Market cashier gone mid-shift. Store open, register open, nobody there. Don't go in, people are fighting inside." }
  - { id: CH_008, ch: 1, src: RADIO,    theme: humour,   text: "...and if you're calling to ask if this counts as a sick day, sir, I genuinely do not know." }
  - { id: CH_009, ch: 1, src: BROADCAST, theme: govt,    text: "Remain indoors. Boil all tap water. Do not travel. Further information will follow." }
  - { id: CH_010, ch: 1, src: SHELTER,  theme: grief,    text: "They took the babies. What kind of weapon takes the babies and leaves the soldiers?" }
  - { id: CH_011, ch: 1, src: SHELTER,  theme: faith,    text: "My mother told me. Forty years she told me. I used to hang up on her." }
  - { id: CH_012, ch: 1, src: FEED,     theme: aliens,   text: "@alt_skywatch: Lights over the Atlantic at 9:03, three separate pilots. Not saying aliens. Not NOT saying aliens." }
  - { id: CH_013, ch: 1, src: FEED,     theme: survival, text: "@prepper_dad_nj: Payments are down. If you have cash, spend it on water and meds TODAY. Tomorrow it's paper." }
  - { id: CH_014, ch: 1, src: GRAFFITI, theme: grief,    text: "WHERE DID YOU GO" }
  - { id: CH_015, ch: 1, src: GRAFFITI, theme: faith,    text: "THE ONE SHALL BE TAKEN AND THE OTHER LEFT - MATT 24:40" }

  # ---------------- CHAPTER 2: Peace and Safety (October 2030) ----------------
  - { id: CH_101, ch: 2, src: BROADCAST, theme: regime,  text: "Halvern Ridge Relief Center now open at the middle school. Register for your Unity Credit wallet. Food. Water. Hope." }
  - { id: CH_102, ch: 2, src: BROADCAST, theme: regime,  text: "Secretary Vael: 'The ones we lost were not taken from us. We were given a second chance. Let us not waste it on old divisions.'" }
  - { id: CH_103, ch: 2, src: BROADCAST, theme: regime,  text: "The Covenant of Seven is signed. Seven years of guaranteed peace. Peace in the Middle East. Peace in our streets. Peace in our hearts." }
  - { id: CH_104, ch: 2, src: RADIO,    theme: science,  text: "The Concord's science panel calls it a 'planetary consciousness event.' A shedding. Their words, folks, not mine." }
  - { id: CH_105, ch: 2, src: RADIO,    theme: rumour,   text: "Word is the relief trucks only stop at houses that registered. Unconfirmed. But my neighbour got two boxes and I got none." }
  - { id: CH_106, ch: 2, src: FEED,     theme: regime,   text: "@hopefulhalvern: Say what you want about Vael, my kids ate three meals today. First time since July." }
  - { id: CH_107, ch: 2, src: FEED,     theme: faith,    text: "@left_behind_ezra: 'For when they shall say, Peace and safety; then sudden destruction cometh upon them.' 1 Thessalonians 5:3. Please. Please read it." }
  - { id: CH_108, ch: 2, src: FEED,     theme: govt,     text: "@truthseeker_0: Why did the Concord exist three weeks after? You don't build THAT in three weeks. They were READY." }
  - { id: CH_109, ch: 2, src: FEED,     theme: aliens,   text: "@starseed_collective: The vanished were ascended to a higher frequency. Those of us left are the next wave. Meditate. Prepare." }
  - { id: CH_110, ch: 2, src: SHELTER,  theme: angels,   text: "It was demons. My cousin says they look like us. They could be standing in this line." }
  - { id: CH_111, ch: 2, src: SHELTER,  theme: grief,    text: "I keep setting four places. My husband says stop. I can't stop." }
  - { id: CH_112, ch: 2, src: SHELTER,  theme: humour,   text: "Three months, no mortgage payments. Nobody's coming to collect. Bank's empty. Banker's gone. Silver linings." }
  - { id: CH_113, ch: 2, src: GRAFFITI, theme: regime,   text: "PEACE AND SAFETY (painted over a church sign)" }
  - { id: CH_114, ch: 2, src: GRAFFITI, theme: faith,    text: "1 THESS 5:3 (painted under it, smaller, in a different hand)" }
  - { id: CH_115, ch: 2, src: FLYER,    theme: faith,    text: "MISSED IT? So did I. Bible study, Tuesdays, Ezra's garage, 14 Birch St. Bring questions. Bring anger. Bring yourself. 'Whosoever shall call upon the name of the Lord shall be saved' (Romans 10:13)." }
  - { id: CH_116, ch: 2, src: FLYER,    theme: regime,   text: "UNITY CREDIT: Your wallet. Your rations. Your future. One world. One peace." }
  - { id: CH_117, ch: 2, src: RADIO,    theme: rumour,   text: "Reports out of the west of a man on a white motorcycle handing out Concord flags at every border. Somebody's got a sense of theatre." }
  - { id: CH_118, ch: 2, src: FEED,     theme: grief,    text: "@nightnurse_ana: still going to work. still opening the NICU door every morning. still empty." }

  # ---------------- CHAPTER 3: The Red Horse (January-September 2031) ----------------
  - { id: CH_201, ch: 3, src: BROADCAST, theme: regime,  text: "Unrest in border regions is temporary. The Concord's Peacekeepers are restoring order. Please report hoarding to the Directorate." }
  - { id: CH_202, ch: 3, src: BROADCAST, theme: regime,  text: "Ration adjustment: one loaf of bread per adult per day, 40 Unity Credit. Luxury goods are unaffected." }
  - { id: CH_203, ch: 3, src: RADIO,    theme: survival, text: "Forty credit for a loaf. Forty. That's a day. That's a whole day's allowance for BREAD." }
  - { id: CH_204, ch: 3, src: RADIO,    theme: rumour,   text: "Wine's still on the shelves at the Concord store in the city. Oil too. They won't touch those. Just everything you can actually eat." }
  - { id: CH_205, ch: 3, src: RADIO,    theme: gang,     text: "Avoid the Ridge Road overpass. The Tollmen are charging fuel to cross. I said AVOID IT." }
  - { id: CH_206, ch: 3, src: FEED,     theme: gang,     text: "@ridgewatch: Tollmen took the reservoir road. If you need water go before dawn. They sleep in." }
  - { id: CH_207, ch: 3, src: FEED,     theme: survival, text: "@prepper_dad_nj: Coyotes in the middle school field in broad daylight. Starving. Keep your small dogs in." }
  - { id: CH_208, ch: 3, src: FEED,     theme: govt,     text: "@truthseeker_0: War in three regions at once? Funny how peace lasted exactly as long as it took to register everyone." }
  - { id: CH_209, ch: 3, src: FEED,     theme: faith,    text: "@left_behind_ezra: 'And there went out another horse that was red: and power was given to him that sat thereon to take peace from the earth.' Revelation 6:4. Read it. Then look outside." }
  - { id: CH_210, ch: 3, src: FEED,     theme: aliens,   text: "@alt_skywatch: The vanished are coming BACK in the ships. Concord is negotiating. That's what the 'peace' was. Bookmark this." }
  - { id: CH_211, ch: 3, src: SHELTER,  theme: survival, text: "You share or you leave. That's the rule here. No hiding cans in your sleeping bag." }
  - { id: CH_212, ch: 3, src: SHELTER,  theme: grief,    text: "I miss complaining. Remember complaining? About traffic? About the internet being slow?" }
  - { id: CH_213, ch: 3, src: SHELTER,  theme: faith,    text: "Hen reads to us at night. I don't believe it. I still listen. Don't tell anybody." }
  - { id: CH_214, ch: 3, src: SHELTER,  theme: gang,     text: "Royce Gant mowed my lawn for six years. Now he wants my generator to let me walk down my own road." }
  - { id: CH_215, ch: 3, src: GRAFFITI, theme: gang,     text: "TOLL ROAD - PAY OR SWIM (on the overpass, in orange)" }
  - { id: CH_216, ch: 3, src: GRAFFITI, theme: grief,    text: "HALE HOUSE - BURNED JAN 18 - NOBODY HOME (on the Linden Court sign, after the fire)" }
  - { id: CH_217, ch: 3, src: GRAFFITI, theme: faith,    text: "THOU SHALT NOT STEAL (on a looted pharmacy; underneath, someone wrote: SAYS WHO)" }
  - { id: CH_218, ch: 3, src: FLYER,    theme: regime,   text: "MISSING PERSONS CLAIMS CLOSE MARCH 1. After this date the vanished will be declared deceased. Their assets will support the common good." }
  - { id: CH_219, ch: 3, src: RADIO,    theme: humour,   text: "Weather today: cold. Tomorrow: cold. Ridge Radio, your source for the obvious, broadcasting on a car battery and spite." }
  - { id: CH_220, ch: 3, src: RADIO,    theme: angels,   text: "CALLER: The vanished were the angels all along, see. Hiding among us. Now they're gone, so it's just us. Just people. That's why everything's like this." }
```

**Count:** 15 (Ch1) + 18 (Ch2) + 20 (Ch3) = **53 lines.**

**Scripture used in chatter (verified KJV):**
- 1 Corinthians 15:52: "In a moment, in the twinkling of an eye, at the last trump"
- Matthew 24:40: "Then shall two be in the field; the one shall be taken, and the other left." (The graffiti in CH_015 is condensed and in capitals, as graffiti would be.)
- 1 Thessalonians 5:3: "For when they shall say, Peace and safety; then sudden destruction cometh upon them"
- Romans 10:13: "For whosoever shall call upon the name of the Lord shall be saved."
- Revelation 6:4: "And there went out another horse that was red: and power was given to him that sat thereon to take peace from the earth"
- Exodus 20:15: "Thou shalt not steal." (CH_217, graffiti)

**Writer notes**
- `@left_behind_ezra` is Ezra Kamau's Murmur account. Players can recognise him before they meet him in person in Ch2.
- CH_117 (the white motorcycle) is a deliberate, unconfirmed echo of the first seal (Revelation 6:2). The game never confirms that it is literal, and never explains it.
- CH_204 echoes the third seal's "see thou hurt not the oil and the wine" (Revelation 6:6) as a rumour, not a narrator's statement.
- Keep chatter short (under 160 characters where possible) so it fits a single feed card or a radio subtitle line.
