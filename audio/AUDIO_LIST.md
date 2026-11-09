# Project R: Audio List (Chapter 1, "Night One")

Sounds come from two places:

- **Recorded, CC0 third-party sources** (BigSoundBank, Kenney, OpenGameArt), cut, layered, looped and
  normalised by `audio/tools/build_sourced.py`. Marked **[CC0]** below, with the source in short.
  Full credits, URLs and licence records: `audio/CREDITS.md` and `audio/licenses/`.
  All are CC0 (public-domain dedication): commercial use is fine, attribution is optional.
- **Synthesised from scratch** by `audio/tools/gen_sfx.py` / `gen_music.py` (numpy/scipy: oscillators,
  noise, filters, envelopes, a synthetic convolution reverb). Marked **[synth]**. The alarm, siren and
  broadcast tones are generic and on purpose do not match any real product or the real EAS/NOAA signals.

File names, formats and loudness targets did not change when sounds were replaced, so the engine needs
no changes. See "Quality notes" at the bottom.

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
| `footstep_wood_01..04` | **[CC0]** Shoe on a wooden floor (BigSoundBank #0165) | no | 0.35 s | -10 | Walking around the house (kitchen, hall) |
| `footstep_carpet_01..04` | **[CC0]** Soft carpet step (Kenney Impact Sounds) | no | 0.30 s | -8 | Living room and bedrooms; quietly searching for Mom |
| `footstep_asphalt_01..04` | **[CC0]** Shoe on concrete/sidewalk (BigSoundBank #0514) | no | 0.35 s | -10 | Walk to the corner store; running in the street |
| `footstep_grass_01..04` | **[CC0]** Step on grass (Kenney Impact Sounds) | no | 0.40 s | -10 | Cutting across front yards |
| `footstep_glass_01..04` | **[CC0]** Concrete step (BigSoundBank #0514) + glass crunch (synth layer) + Kenney glass tick | no | 0.35 s | -9 | Street after the crash; store floor after the window breaks |
| `door_open` | **[CC0]** Real door: latch, handle, swing (BigSoundBank #1702) | no | 1.75 s | -8 | Front door, leaving and coming home |
| `door_close` | **[CC0]** End of swing, slam, latch (BigSoundBank #1704) | no | 1.65 s | -8 | Front door / store door |
| `fridge_hum_loop` | [synth] 60 Hz compressor hum with a little rattle | **yes** | 12 s | -14 (3D, short range) | Kitchen at home, Act 1, and still running when he comes home to the empty house |
| `tv_murmur_loop` | **[CC0]** Muffled TV through a wall: real conversation walla (BigSoundBank #0684) band-limited and low-passed so no words are intelligible, plus a faint piano bed (OGA "Vaporware") | **yes** | 24 s | -12 (3D, from the TV) | Living room, evening (Mom's show) |
| `cutlery_clink` | **[CC0]** Cutlery set on a plate, two takes (BigSoundBank #1191) | no | 1.2 s | -12 | Dinner / doing the dishes with Mom |
| `phone_buzz` | **[CC0]** Phone vibrating twice (BigSoundBank #1034) | no | 1.6 s | -10 | Text from Mom asking for the store run; again with unanswered messages at home |
| `store_door_chime` | [synth] Generic two-note door bell (E6 to C6) | no | 3.0 s | -8 | Entering and leaving the corner store |
| `register_beep` | [synth] Short scanner/register beep | no | 0.16 s | -14 | Cashier ringing up items |
| `fluorescent_hum_loop` | [synth] 120 Hz ballast buzz, faint high whine, two flicker ticks | **yes** | 10 s | -10 | Inside the store, until the power cut |
| `power_cut` | [synth] Spark crack, heavy electrical thunk, mains hum pitching down to nothing, relay click | no | 3.5 s | -2 | THE moment: right after the silence beat, lights cut. Stop `fluorescent_hum_loop` on the same frame |
| `car_alarm_loop` | [synth] Generic two-tone alternating car alarm | **yes** | 4.8 s | -10 (3D) | Starts 1-2 s after the power cut and keeps going outside the store and on the street (several cars, random offsets, varied `pitch_scale`) |
| `car_crash` | **[CC0]** Big impact, metal crunch, glass, debris: recorded metal/glass layers (BigSoundBank, Kenney) over the synth low end | no | 4.0 s | -3 | Driverless car hits a pole or the storefront just after the cut |
| `glass_break` | **[CC0]** Mirror shatter + falling shards (BigSoundBank #0387, #0771) | no | 2.2 s | -6 | Store window, looters breaking in |
| `explosion_distant` | **[CC0]** Far explosion (BigSoundBank #1023) with a thunder roll as the echo (#3113) over the synth sub | no | 6.0 s | -4 | A plane or gas main going up far away; one or two times in the street sequence |
| `fire_crackle_loop` | **[CC0]** Real large fire: roar plus crackles (BigSoundBank #0987) | **yes** | 14 s | -8 (3D near fires) | Burning car and house fires on the street |
| `siren_distant_loop` | [synth] Far rising/falling wail with town reverb (generic, not a real siren) | **yes** | 18 s | -10 | Street chaos; very faint behind the aftermath scene |
| `dog_bark` | **[CC0]** Real medium dog, two double barks (BigSoundBank #2954) | no | 1.6 s | -8 (3D) | Loose, scared dog in the street |
| `dog_growl` | **[CC0]** Real growl, grumble, snarl (OGA, qubodup) | no | 1.8 s | -9 (3D) | Same dog cornering the player before it bolts |
| `crowd_panic_far_loop` | **[CC0]** Distant crowd: real protest crowd and walla, far shouts and screams, filtered and reverberant (BigSoundBank, OGA) | **yes** | 16 s | -10 | From the power cut onward, outside; fades as he gets home |
| `scream_distant` | **[CC0]** One far-away female scream (OGA "Female Scream 1", filtered + reverb) | no | 6.0 s (tail) | -9 | A few seconds after the lights die ("screams") |
| `whoosh` | **[CC0]** Fast swish (BigSoundBank #1799) | no | 0.35 s | -9 | Missed punch, dodge, quick camera moves |
| `bat_swing` | **[CC0]** Heavier, lower swing whoosh (BigSoundBank #1795, slowed) | no | 0.45 s | -6 | Looter swinging a bat |
| `punch` | **[CC0]** Short swish plus fist-on-body impact (BigSoundBank #1797, #2461) | no | 0.45 s | -6 | Looter fight |
| `hit_heavy` | **[CC0]** Blunt heavy impact on a body (Kenney + BigSoundBank #0444) | no | 0.70 s | -6 | Bat connects (player is hit or hits) |
| `hurt` | **[CC0]** Real male pained "urgh" (OGA, EmoPreben) | no | 1.0 s | -9 | Player takes damage |
| `grunt` | **[CC0]** Real male effort/pain "huuurh" (OGA, EmoPreben) | no | 0.9 s | -9 | Player punches or shoves, climbs over a fence |
| `pickup` | [synth] Hand grab plus a soft three-note bell | no | 0.6 s | -6 (UI bus) | Picking up items (water, flashlight, Mom's Bible) |
| `inventory_open` | [synth] Backpack zip/cloth plus a soft tone | no | 0.6 s | -6 (UI bus) | Opening the inventory |
| `ui_blip` | [synth] Soft short blip | no | 0.07 s | -6 (UI bus) | Menu cursor move |
| `ui_confirm` | [synth] Rising two-note confirm | no | 0.35 s | -6 (UI bus) | Menu select, dialogue advance |
| `ui_back` | [synth] Falling two-note back/cancel | no | 0.30 s | -6 (UI bus) | Menu back / close |
| `typewriter_tick_01..03` | [synth] Tiny click for text reveal | no | 0.05 s | -12 (UI bus) | Dialogue box letters (one tick every 2-3 letters, random variant). Cut the ticks hard when the cashier vanishes mid-sentence |
| `paper_rustle` | **[CC0]** A page turning (BigSoundBank #0493) | no | 1.1 s | -8 | Reading Mom's letter; opening her Bible |
| `heartbeat_loop` | [synth] About 80 bpm heartbeat, low | **yes** | 6.0 s | -8, fade in | After the vanishing, at low HP, and while finding Mom's room empty |
| `drone_tension_loop` | [synth] Low detuned drone, rumble and air | **yes** | 24 s | -8, fade in | Right after the power cut; any moment of dread (also good under `unease`) |
| `silence_ring` | [synth] Very faint high ring (delivered at -24 dBFS peak) | no | 4.0 s | 0 | **Optional.** Late in the TOTAL SILENCE beat as a "pressure in the ears" cue. True digital silence is the default; use this only if testers think the game froze |
| `emergency_broadcast_tone` | [synth] Three pips, then a sustained two-tone alert, band-limited like a TV speaker. Generic, NOT real EAS | no | 6.0 s | -8 (3D, from TV/radio) | Dawn: the TV or radio comes back with the emergency broadcast |

## Ambience (`res://audio/ambience/`), stereo OGG, all loops

| File | What it is | Loop | Len | Suggested vol (dB) | Where in Chapter 1 |
|---|---|---|---|---|---|
| `suburban_evening_loop.ogg` | **[CC0]** Evening birds with children playing far away (BigSoundBank #1859, #1082) | **yes** | 40 s | -4 | Opening: house exterior and through open windows inside (-10 inside) |
| `crickets_night_loop.ogg` | **[CC0]** Real night countryside: steady crickets/insects, night air (BigSoundBank #1880) | **yes** | 30 s | -4 | Walk to the store; outside after the chaos dies down; back home at night (-10 through windows) |
| `wind_loop.ogg` | **[CC0]** Wind heard from inside a house (BigSoundBank #1714) | **yes** | 30 s | -8 | Empty house with the door open, aftermath; layer over crickets |
| `chaos_city_far_loop.ogg` | [synth] Town in trouble: far sirens, a far car alarm, crowd, low roar of fires, distant bangs | **yes** | 30 s | -2 | Whole street sequence (bed under the 3D sources); -10 indoors afterward |
| `dawn_quiet_loop.ogg` | **[CC0]** Morning birds waking (BigSoundBank #0935) + one very far synth siren | **yes** | 40 s | -4 | Dawn / emergency broadcast scene |

## Music (`res://audio/music/`), stereo OGG, all loops, -16 LUFS

| File | Mood / content | Loop | Len | Suggested vol (dB) | Where in Chapter 1 |
|---|---|---|---|---|---|
| `title.ogg` | **[CC0]** "Revelation" by Indieteur (OGA): calm, meditative acoustic piece in E minor. Mysterious, a little hopeful | **yes** | 76.8 s | -6 | Main menu / title screen |
| `home_evening.ogg` | **[CC0]** "At Home - Orchestral" by Wolfgang_ (OGA): calm, warm, A major | **yes** | 46.4 s | -8 | Evening at home with Mom (under the TV and dinner) |
| `unease.ogg` | [synth] Sparse and low. A-minor drone, isolated low piano notes, faint dissonant pairs, a soft pulse in the middle | **yes** | 64.0 s | -10 | Walking to the store and inside it. **Cut it hard** (not a fade) at the vanishing, together with every other sound |
| `chaos.ogg` | [synth] Pulsing, urgent. 16th-note low string ostinato in D minor, taiko-like toms, hats and high strings in the second half, dark swells. 128 bpm | **yes** | 60.0 s | -8 | Street sequence: fires, looters, dog; fade in about 2 s after the crash |
| `aftermath.ogg` | **[CC0]** "Emotional Piano" (solo) by Centurion_of_war (OGA): slow, sparse, emotional solo piano | **yes** | 57.6 s | -8 | Home, Mom gone: her Bible, her letter |
| `dawn_hope.ogg` | **[CC0]** "The Hope" by TAD (OGA): starts quiet, gentle orchestra that swells and settles, G major. Hopeful | **yes** | 133.5 s | -8 | Dawn, after the emergency broadcast ends; end of chapter / credits card |

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
python3 audio/tools/gen_sfx.py [name ...]     # [synth] sfx/*.wav + ambience/*.ogg (deterministic, seeded)
python3 audio/tools/gen_music.py [track ...]  # [synth] music/*.ogg
python3 audio/tools/build_sourced.py --src <downloads> --placeholders <dir with gen_sfx/gen_music output> [job ...]
                                              # [CC0] files, from the original downloads listed in CREDITS.md
```
**Careful:** `gen_sfx.py` / `gen_music.py` with no names also write the placeholder versions of the
[CC0] files. Generate the placeholders into a copy (they are needed as `--placeholders`, a few sounds
layer them in), or run `build_sourced.py` again afterwards. The original downloads are not in the repo;
re-download them from the URLs in `CREDITS.md`.
Requires Python 3 + numpy + scipy, and ffmpeg (libvorbis) on PATH for loudness measurement and OGG encoding.
All SFX together take about 2 minutes on 4 cores; all music about 1 minute.

## Quality notes (honest)

**Update (CC0 pass).** Voices, the dog, footsteps, doors, glass, crash, explosion, fire, the fight
foley, four ambiences and four music tracks (`title`, `home_evening`, `aftermath`, `dawn_hope`) are
now real recordings / real compositions under CC0 (see the [CC0] marks and `CREDITS.md`). The music
pieces are short indie game tracks, looped at a repeating phrase: they are a clear step up from the
procedural music but they are not a bespoke score; a composer is still the best final answer.
`unease`, `chaos`, `chaos_city_far_loop`, the electrical/mechanical sounds, sirens, alarm, UI and
broadcast tone stay synthesised on purpose. The notes below describe the original synthesised set.

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
