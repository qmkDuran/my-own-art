# Project R: Audio List (Chapter 1, "Night One")

Every sound here was **synthesised from scratch** by the scripts in `audio/tools/`
(numpy/scipy: oscillators, noise, filters, envelopes, a synthetic convolution reverb).
There are no recordings, samples, or third-party/copyrighted material. The alarm, siren and
broadcast tones are generic and on purpose do not match any real product or the real EAS/NOAA signals.

**Status: placeholder.** It works for prototyping and sets the mood. See "Quality notes" at the bottom.

## Folders and loading

| Folder | Godot path | Format |
|---|---|---|
| `audio/sfx/` | `res://audio/sfx/<name>.wav` | WAV, 44.1 kHz, 16-bit, **mono** |
| `audio/ambience/` | `res://audio/ambience/<name>.ogg` | OGG Vorbis, 44.1 kHz, **stereo** |
| `audio/music/` | `res://audio/music/<name>.ogg` | OGG Vorbis, 44.1 kHz, **stereo** |

**Loops.** Each file marked *loop = yes* is cut to loop seamlessly, sample-exact, with no fades at the
ends. In Godot 4, turn looping on when you import it:
- WAV: Import dock -> *Edit > Loop Mode = Forward* (loop begin 0, end = -1 / end of file).
- OGG: Import dock -> *Loop = On* (loop offset 0).
Or set it in code (`AudioStreamWAV.loop_mode = LOOP_FORWARD`, `loop_end = data size in frames`;
`AudioStreamOggVorbis.loop = true`).

**Variants.** Footsteps and typewriter ticks have numbered variants (`_01`..`_04` / `_01`..`_03`).
Pick one at random each time and add a small random pitch, e.g. `pitch_scale = randf_range(0.94, 1.06)`,
so repeats don't sound mechanical.

**Levels as delivered**
- One-shot SFX: peak normalised to **-3 dBFS**.
- UI sounds and typewriter ticks: peak **-6 dBFS**.
- Looping SFX (`*_loop.wav` in sfx/): **-22 LUFS** integrated (peaks at or below -3 dBFS).
- Ambience beds: **-26 LUFS** integrated (peaks at or below -6 dBFS).
- Music: **-16 LUFS** integrated, true peak at or below -1.5 dBFS.

"Suggested volume" below is a starting `volume_db` for the AudioStreamPlayer, with the bus at 0 dB.
Suggested buses are `Music`, `Ambience`, `SFX`, `UI`. Duck `Music` by about 4-6 dB under big story SFX
(power cut, crash, explosion).

---

## SFX (`res://audio/sfx/`)

| File | What it is | Loop | Len | Suggested vol (dB) | Where in Chapter 1 |
|---|---|---|---|---|---|
| `footstep_wood_01..04` | Shoe on hardwood: heel thump, toe roll, occasional faint board creak | no | 0.35 s | -10 | Walking around the house (kitchen, hall) |
| `footstep_carpet_01..04` | Soft muffled carpet step | no | 0.30 s | -8 | Living room and bedrooms; quietly searching for Mom |
| `footstep_asphalt_01..04` | Sneaker on asphalt or sidewalk: heel tap and grit scuff | no | 0.35 s | -10 | Walk to the corner store; running in the street |
| `footstep_grass_01..04` | Rustle and soft thump on a lawn | no | 0.40 s | -10 | Cutting across front yards |
| `footstep_glass_01..04` | Asphalt step crunching on broken glass | no | 0.35 s | -9 | Street after the crash; store floor after the window breaks |
| `door_open` | Latch click, short hinge creak, air | no | 1.6 s | -8 | Front door, leaving and coming home |
| `door_close` | Short creak, thud, latch, slight rattle | no | 1.4 s | -8 | Front door / store door |
| `fridge_hum_loop` | 60 Hz compressor hum with a little rattle | **yes** | 12 s | -14 (3D, short range) | Kitchen at home, Act 1, and still running when he comes home to the empty house |
| `tv_murmur_loop` | Muffled TV through a wall: two wordless "voices" and a soft music bed. Unintelligible | **yes** | 24 s | -12 (3D, from the TV) | Living room, evening (Mom's show) |
| `cutlery_clink` | Fork and knife clinks plus a plate tap | no | 1.2 s | -12 | Dinner / doing the dishes with Mom |
| `phone_buzz` | Phone vibrating twice on a wooden table | no | 1.6 s | -10 | Text from Mom asking for the store run; again with unanswered messages at home |
| `store_door_chime` | Generic two-note door bell (E6 to C6) | no | 3.0 s | -8 | Entering and leaving the corner store |
| `register_beep` | Short scanner/register beep | no | 0.16 s | -14 | Cashier ringing up items |
| `fluorescent_hum_loop` | 120 Hz ballast buzz, faint high whine, two flicker ticks | **yes** | 10 s | -10 | Inside the store, until the power cut |
| `power_cut` | Spark crack, heavy electrical thunk, mains hum pitching down to nothing, relay click | no | 3.5 s | -2 | THE moment: right after the silence beat, lights cut. Stop `fluorescent_hum_loop` on the same frame |
| `car_alarm_loop` | Generic two-tone alternating car alarm | **yes** | 4.8 s | -10 (3D) | Starts 1-2 s after the power cut and keeps going outside the store and on the street (several cars, random offsets, varied `pitch_scale`) |
| `car_crash` | Big impact, metal crunch, glass, scrape, debris | no | 4.0 s | -3 | Driverless car hits a pole or the storefront just after the cut |
| `glass_break` | Window or bottle shatter | no | 2.2 s | -6 | Store window, looters breaking in |
| `explosion_distant` | Low rolling boom with echoes off buildings | no | 6.0 s | -4 | A plane or gas main going up far away; one or two times in the street sequence |
| `fire_crackle_loop` | Burning car/house: roar plus crackles and snaps | **yes** | 14 s | -8 (3D near fires) | Burning car and house fires on the street |
| `siren_distant_loop` | Far rising/falling wail with town reverb (generic, not a real siren) | **yes** | 18 s | -10 | Street chaos; very faint behind the aftermath scene |
| `dog_bark` | Stylised medium dog, three barks | no | 1.6 s | -8 (3D) | Loose, scared dog in the street |
| `dog_growl` | Stylised low growl | no | 1.8 s | -9 (3D) | Same dog cornering the player before it bolts |
| `crowd_panic_far_loop` | Distant crowd: wordless shouts and screams, reverberant | **yes** | 16 s | -10 | From the power cut onward, outside; fades as he gets home |
| `scream_distant` | One wordless far-away scream (stylised) | no | 6.0 s (tail) | -9 | A few seconds after the lights die ("screams") |
| `whoosh` | Generic fast swish | no | 0.35 s | -9 | Missed punch, dodge, quick camera moves |
| `bat_swing` | Heavier, lower swing whoosh | no | 0.45 s | -6 | Looter swinging a bat |
| `punch` | Short swish plus fist-on-body impact | no | 0.45 s | -6 | Looter fight |
| `hit_heavy` | Blunt bat impact on a body | no | 0.70 s | -6 | Bat connects (player is hit or hits) |
| `hurt` | Wordless pained exhale ("ugh"), stylised | no | 1.0 s | -9 | Player takes damage |
| `grunt` | Wordless effort grunt, stylised | no | 0.9 s | -9 | Player punches or shoves, climbs over a fence |
| `pickup` | Hand grab plus a soft three-note bell | no | 0.6 s | -6 (UI bus) | Picking up items (water, flashlight, Mom's Bible) |
| `inventory_open` | Backpack zip/cloth plus a soft tone | no | 0.6 s | -6 (UI bus) | Opening the inventory |
| `ui_blip` | Soft short blip | no | 0.07 s | -6 (UI bus) | Menu cursor move |
| `ui_confirm` | Rising two-note confirm | no | 0.35 s | -6 (UI bus) | Menu select, dialogue advance |
| `ui_back` | Falling two-note back/cancel | no | 0.30 s | -6 (UI bus) | Menu back / close |
| `typewriter_tick_01..03` | Tiny click for text reveal | no | 0.05 s | -12 (UI bus) | Dialogue box letters (one tick every 2-3 letters, random variant). Cut the ticks hard when the cashier vanishes mid-sentence |
| `paper_rustle` | Paper unfolding or a page turning | no | 1.1 s | -8 | Reading Mom's letter; opening her Bible |
| `heartbeat_loop` | About 80 bpm heartbeat, low | **yes** | 6.0 s | -8, fade in | After the vanishing, at low HP, and while finding Mom's room empty |
| `drone_tension_loop` | Low detuned drone, rumble and air | **yes** | 24 s | -8, fade in | Right after the power cut; any moment of dread (also good under `unease`) |
| `silence_ring` | Very faint high ring (delivered at -24 dBFS peak) | no | 4.0 s | 0 | **Optional.** Late in the TOTAL SILENCE beat as a "pressure in the ears" cue. True digital silence is the default; use this only if testers think the game froze |
| `emergency_broadcast_tone` | Three pips, then a sustained two-tone alert, band-limited like a TV speaker. Generic, NOT real EAS | no | 6.0 s | -8 (3D, from TV/radio) | Dawn: the TV or radio comes back with the emergency broadcast |

## Ambience (`res://audio/ambience/`), stereo OGG, all loops

| File | What it is | Loop | Len | Suggested vol (dB) | Where in Chapter 1 |
|---|---|---|---|---|---|
| `suburban_evening_loop.ogg` | Summer evening: birds, a distant lawnmower going back and forth, kids playing far away (wordless), one far car, warm air | **yes** | 40 s | -4 | Opening: house exterior and through open windows inside (-10 inside) |
| `crickets_night_loop.ogg` | About 7 crickets across the stereo field, a far trill, night air | **yes** | 30 s | -4 | Walk to the store; outside after the chaos dies down; back home at night (-10 through windows) |
| `wind_loop.ogg` | Gusty wind with a faint whistle | **yes** | 30 s | -8 | Empty house with the door open, aftermath; layer over crickets |
| `chaos_city_far_loop.ogg` | Town in trouble: far sirens, a far car alarm, crowd, low roar of fires, distant bangs | **yes** | 30 s | -2 | Whole street sequence (bed under the 3D sources); -10 indoors afterward |
| `dawn_quiet_loop.ogg` | Morning after: a few hesitant birds, light breeze, one very far siren | **yes** | 40 s | -4 | Dawn / emergency broadcast scene |

## Music (`res://audio/music/`), stereo OGG, all loops, -16 LUFS

| File | Mood / content | Loop | Len | Suggested vol (dB) | Where in Chapter 1 |
|---|---|---|---|---|---|
| `title.ogg` | A minor music-box motif over a soft pad and low pulse; strings join on the second pass. Mysterious, a little hopeful. 70 bpm | **yes** | 54.9 s | -6 | Main menu / title screen |
| `home_evening.ogg` | Warm, nostalgic. Felt-piano arpeggios in D major, a gentle melody, soft pad, a low string line on the 3rd pass. 72 bpm | **yes** | 80.0 s | -8 | Evening at home with Mom (under the TV and dinner) |
| `unease.ogg` | Sparse and low. A-minor drone, isolated low piano notes, faint dissonant pairs, a soft pulse in the middle | **yes** | 64.0 s | -10 | Walking to the store and inside it. **Cut it hard** (not a fade) at the vanishing, together with every other sound |
| `chaos.ogg` | Pulsing, urgent. 16th-note low string ostinato in D minor, taiko-like toms, hats and high strings in the second half, dark swells. 128 bpm | **yes** | 60.0 s | -8 | Street sequence: fires, looters, dog; fade in about 2 s after the crash |
| `aftermath.ogg` | Mournful and slow. D-minor strings, a sparse piano melody, then a cello line. 54 bpm | **yes** | 71.1 s | -8 | Home, Mom gone: her Bible, her letter |
| `dawn_hope.ogg` | Quiet, a hint of hope. Em-C-G-D, high piano, pad, strings entering. 66 bpm | **yes** | 58.2 s | -8 | Dawn, after the emergency broadcast ends; end of chapter / credits card |

---

## Chapter 1 cue sheet (suggested)

1. **Evening at home.** `home_evening` + `suburban_evening_loop` (through windows) + `fridge_hum_loop` +
   `tv_murmur_loop`. Footsteps: wood/carpet. `cutlery_clink`, `phone_buzz`, dialogue ticks.
2. **Late errand.** `door_open`/`door_close`, crossfade to `crickets_night_loop`, `unease` fades in,
   asphalt/grass footsteps.
3. **Corner store.** `store_door_chime`, `fluorescent_hum_loop`, `register_beep`. Cashier dialogue ticks...
4. **The vanishing.** Mid-sentence: stop **everything** on one frame (all buses muted, no fade) and hold
   about 2-3 s of total silence (optional `silence_ring` at the end).
5. **Lights cut.** `power_cut` -> `car_alarm_loop` (+1.2 s) -> `car_crash` (+2.5 s) -> `scream_distant`,
   `glass_break`, `explosion_distant`; `drone_tension_loop` + `heartbeat_loop` fade in; `crowd_panic_far_loop`.
6. **The street.** `chaos` music, `chaos_city_far_loop`, 3D `fire_crackle_loop`, `siren_distant_loop`,
   `car_alarm_loop`s, `dog_bark`/`dog_growl`, fight: `bat_swing`, `hit_heavy`, `punch`, `whoosh`, `hurt`,
   `grunt`; `footstep_glass_*` near wrecks.
7. **Home, Mom gone.** `door_open`, `aftermath`, `crickets_night_loop` + `wind_loop`, `fridge_hum_loop`
   (silent at first, since the power is out; bring it back only if power returns), `footstep_carpet_*`,
   `paper_rustle`, `pickup` (Bible), letter text ticks, `heartbeat_loop` low.
8. **Dawn.** `dawn_quiet_loop`, `emergency_broadcast_tone` from the TV/radio, then `dawn_hope`.

## Regenerating

```
python3 audio/tools/gen_sfx.py [name ...]     # sfx/*.wav + ambience/*.ogg (deterministic, seeded)
python3 audio/tools/gen_music.py [track ...]  # music/*.ogg
```
Requires Python 3 + numpy + scipy, and ffmpeg (libvorbis) on PATH for loudness measurement and OGG encoding.
All SFX together take about 2 minutes on 4 cores; all music about 1 minute.

## Quality notes (honest)

- **Music is placeholder.** It is procedural: additive "felt piano", pads, simple string and bell
  synths, a synthetic reverb, and hand-written but simple progressions and melodies. It is in tune,
  loops seamlessly and is mixed sensibly, but it does not have the phrasing, dynamics and emotional
  arc of real scoring. For a Last of Us / To the Moon tone, `home_evening`, `aftermath` and `dawn_hope`
  are where a **composer** (even one recording a real piano and a solo cello or guitar) would add the most.
  Replace these first. `chaos` and `unease` hold up better as placeholders.
- **Voices are the weakest SFX.** `tv_murmur_loop`, `crowd_panic_far_loop`, `scream_distant`, `hurt`
  and `grunt` use formant synthesis. Muffled and far away they pass, but up close they sound
  synthetic. Swap them for recorded foley/walla, e.g. a royalty-free library under a licence you have
  checked (CC0 sources, or paid packs from Sonniss/Boom/Soundly), or record your own.
- **Dog** (`dog_bark`, `dog_growl`) is stylised. It reads as "dog" in context but is not realistic.
  Replace it with a recording if you want realism.
- **Holds up well:** the synthesised mechanical and electrical sounds (hums, `power_cut`,
  `car_alarm_loop`, sirens, UI, typewriter ticks, door chime, heartbeat, drone), `fire_crackle_loop`,
  `wind_loop` and `crickets_night_loop`. Footsteps, doors, `glass_break`, `car_crash` and
  `explosion_distant` are serviceable. A foley pass would make them more convincing.
- The siren, car alarm and broadcast tone are generic by design. Keep them that way: real EAS
  tones should not be used in media.
