# Project R: Audio Credits and Licences

Every sound in `audio/` is either **synthesised by us** (scripts in `audio/tools/`, no third-party
material) or built from the **third-party recordings listed below**. All third-party material is
**CC0 1.0 (public-domain dedication)**: commercial use, editing and redistribution are allowed and no
attribution is legally required. We still credit everyone (suggested in-game credits text at the bottom).

- Licence texts and source records are kept in `audio/licenses/`:
  `CC0-1.0_legalcode.txt`, `kenney_impact-sounds_License.txt`, `bigsoundbank_licenses.txt`
  (licence page), `bigsoundbank_items.txt` (every sound used, with its page URL and the licence its
  page states) and `opengameart_items.txt` (every OpenGameArt item used, with author, licence field
  and page text).
- All sources were **accessed 2026-11-09**.
- How each file was made (cuts, layers, filters, loop points) is in `audio/tools/build_sourced.py`.
  Common processing for every file: downmix/resample to 44.1 kHz, DC/rumble high-pass, trimmed,
  short fades, then loudness/peak normalised to the targets in `AUDIO_LIST.md` (SFX peak -3 dBFS,
  looping SFX -22 LUFS, ambience -26 LUFS, music -16 LUFS / peak <= -1.5 dBFS). Loops are made
  seamless with a crossfade of the material after the loop point into the start.

## Sources

| Short name | Source | Author | URL | Licence |
|---|---|---|---|---|
| BSB #nnnn | BigSoundBank (LaSonotheque) sound number nnnn, "Free and royalty-free" | Joseph SARDIN (and co-authors named per sound below) | `https://bigsoundbank.com/<sound page>` (full URLs in `licenses/bigsoundbank_items.txt`) | CC0 1.0 ("License CC0 (public domain): Free and royalty-free" on each sound page; https://bigsoundbank.com/licenses.html) |
| Kenney Impact | "Impact Sounds" (1.0) | Kenney (www.kenney.nl) | https://kenney.nl/assets/impact-sounds | CC0 1.0 (License.txt in the pack) |
| OGA qubodup dog | "Dog Snarl Grunt Grumble" | qubodup | https://opengameart.org/content/dog-snarl-grunt-grumble | CC0 |
| OGA scream | "Female Scream 1" | Nocturnal_Vanguard (AuraVoice) | https://opengameart.org/content/female-scream-1 | CC0 |
| OGA pain | "Pain sounds by EmoPreben" (v2) | EmoPreben (Lasse Bührmann) | https://opengameart.org/content/pain-sounds-by-emopreben | CC0 |
| OGA Vaporware | "Calm Piano 1 (Vaporware)" | The Cynic Project (cynicmusic) | https://opengameart.org/content/calm-piano-1-vaporware | CC0 |
| OGA At Home | "At Home - Orchestral" | Wolfgang_ | https://opengameart.org/content/at-home-orchestral | CC0 |
| OGA Emotional Piano | "Emotional Piano" (file `emotional_piano_solo_0.ogg`) | Centurion_of_war | https://opengameart.org/content/emotional-piano-0 | CC0 |
| OGA The Hope | "The Hope" | TAD | https://opengameart.org/content/the-hope | CC0 |
| OGA Revelation | "Revelation" | Indieteur | https://opengameart.org/content/revelation | CC0 |

## Per file

"Placeholder layer" means our own synthesised placeholder (from `gen_sfx.py`) was mixed in quietly.

### SFX (`audio/sfx/`)

| Game file | Source(s) | Changes |
|---|---|---|
| `footstep_wood_01..04` | BSB #0165 "Man Footsteps on the Wooden Floor" (author: DavidGreck) | 4 single steps cut at 1.09/2.34/2.94/3.56 s, 0.35 s each, faded |
| `footstep_asphalt_01..04` | BSB #0514 "Footsteps, Shoe on Concrete" | 4 single steps (0.40/1.08/2.48/7.50 s), 0.35 s |
| `footstep_glass_01..04` | BSB #0514 (other steps) + Kenney Impact `impactGlass_light_000..003` + placeholder layer (glass crunch, high-passed at 2.5 kHz) | Layered and trimmed to 0.35 s |
| `footstep_carpet_01..04` | Kenney Impact `footstep_carpet_000`, `_001`, `_003`; `_04` = `_001` slowed 7% and low-passed (the pack has only 3 unique carpet takes) | Padded to 0.30 s |
| `footstep_grass_01..04` | Kenney Impact `footstep_grass_000..003` | Trimmed to 0.40 s, faded |
| `door_open` | BSB #1702 "Apartment Door, Opening #1" | First 1.75 s (latch, handle, swing), faded |
| `door_close` | BSB #1704 "Apartment Door, Closing #1" | 1.95-3.6 s (end of swing, slam, latch) |
| `cutlery_clink` | BSB #1191 "Cutlery, set on a plate" | Two takes joined, 1.2 s |
| `phone_buzz` | BSB #1034 "Mobile vibrator without protective shell" | Two buzzes shortened to 0.65 s each, 1.6 s total |
| `glass_break` | BSB #0387 "A Mirror Explodes" + BSB #0771 "Broken glass" (falling shards) | Layered, light reverb, 2.2 s |
| `car_crash` | BSB #1266 "Metal trash can", #1774 "Falling sheet steel bar #4", #1776 "Fall 2 sheet steel bars #1", #0148 "Glass Burst", #0771 "Broken glass"; Kenney Impact `impactMetal_heavy_000`, `_003`; placeholder layer (low-passed at 300 Hz for weight) | Layered montage, reverb, 4.0 s |
| `explosion_distant` | BSB #1023 "Explosion far Away #1" (slowed 20%, low-passed) + BSB #3113 "Thunder #2" (authors: Joseph SARDIN & Axeline T.; as the rolling echo, low-passed) + placeholder layer (sub, low-passed at 160 Hz) | Layered, long reverb, 6.0 s |
| `dog_bark` | BSB #2954 "Barking Dog #2" | Two double-barks, 1.6 s |
| `dog_growl` | OGA qubodup dog: `dog-growl.flac`, `dog-grumble.flac`, `dog-snarl.flac` | Joined in sequence, 1.8 s |
| `scream_distant` | OGA scream `female_scream_1.ogg` | Band-passed 300-3200 Hz, heavy reverb (distance), 6.0 s |
| `hurt` | OGA pain "Painsounds v2 - Track 5 - Urggh" | Downmixed, padded to 1.0 s |
| `grunt` | OGA pain "Painsounds v2 - Track 3 - Huuurh" | Downmixed, padded to 0.9 s |
| `whoosh` | BSB #1799 "Whoosh #6" | Trimmed to 0.35 s |
| `bat_swing` | BSB #1795 "Whoosh #3" | Slowed 15% (lower, heavier), trimmed to 0.45 s |
| `punch` | BSB #1797 "Whoosh #5" + BSB #2461 "Punch #6" | Layered, 0.45 s |
| `hit_heavy` | Kenney Impact `impactPunch_heavy_000` + BSB #0444 "Punch #2" | Layered (+ low-passed copy for weight), 0.7 s |
| `paper_rustle` | BSB #0493 "Pages that turn #1" | One page turn, 1.1 s |
| `tv_murmur_loop` | BSB #0684 "Walla Group: Averages Discussions" + OGA Vaporware (music bed at -14 dB) | Band-limited like a TV speaker, low-passed (through a wall) so no words are intelligible, light room reverb, 24 s seamless loop |
| `crowd_panic_far_loop` | BSB #3391 "Manifestation #14" (authors: Joseph SARDIN & Axeline T.), #0685 "Walla Group: Strong Discussions", shouts from #1662 "Howling of a Girl #1", #1663 "howling of a girl #2", #1664 "Howling of a Boy #1", #1679 "howling of a boy #2", OGA scream | Filtered (far away), reverb, shouts scattered, 16 s seamless loop |
| `fire_crackle_loop` | BSB #0987 "Big Branching Fire #1" | 8-25 s section, 14 s seamless loop |

Unchanged (still our synthesised placeholders, no third-party material): `fridge_hum_loop`,
`store_door_chime`, `register_beep`, `fluorescent_hum_loop`, `power_cut`, `car_alarm_loop`,
`siren_distant_loop`, `pickup`, `inventory_open`, `ui_blip`, `ui_confirm`, `ui_back`,
`typewriter_tick_01..03`, `heartbeat_loop`, `drone_tension_loop`, `silence_ring`,
`emergency_broadcast_tone`.

### Ambience (`audio/ambience/`)

| Game file | Source(s) | Changes |
|---|---|---|
| `suburban_evening_loop.ogg` | BSB #1859 "Evening Birds" + BSB #1082 "Parisian park, children's games" (far, -13 dB, filtered) | 40 s seamless loop |
| `crickets_night_loop.ogg` | BSB #1880 "Campaign at Night #4" | 30 s seamless loop |
| `wind_loop.ogg` | BSB #1714 "Wind from inside #1" | 30 s seamless loop |
| `dawn_quiet_loop.ogg` | BSB #0935 "Birds waking #2" + our synthesised `siren_distant_loop` (very low, filtered) | 40 s seamless loop |

Unchanged (synthesised): `chaos_city_far_loop.ogg`.

### Music (`audio/music/`)

| Game file | Source | Changes |
|---|---|---|
| `home_evening.ogg` | OGA At Home: "At Home - Orchestral" by Wolfgang_ | Loop 1.50-47.93 s of the original (46.4 s), 1.5 s crossfade |
| `aftermath.ogg` | OGA Emotional Piano: "Emotional Piano" (solo version) by Centurion_of_war | Loop 1.50-59.09 s (57.6 s), 1.5 s crossfade |
| `dawn_hope.ogg` | OGA The Hope: "The Hope" by TAD | Loop 11.00-144.54 s (133.5 s), 2 s crossfade |
| `title.ogg` | OGA Revelation: "Revelation" by Indieteur | Loop 1.50-78.30 s (76.8 s), 2 s crossfade |

Unchanged (synthesised): `unease.ogg`, `chaos.ogg`.

## Suggested in-game credits (not required by CC0, but kind)

```
Additional sounds: Joseph SARDIN - BigSoundBank.com (CC0)
Sound effects: Kenney (www.kenney.nl) (CC0)
Sounds from OpenGameArt.org (CC0): qubodup, Nocturnal_Vanguard (AuraVoice), EmoPreben (Lasse Bührmann)
Music from OpenGameArt.org (CC0):
  "At Home - Orchestral" by Wolfgang_
  "Emotional Piano" by Centurion_of_war
  "The Hope" by TAD
  "Revelation" by Indieteur
  "Vaporware" (TV background) by The Cynic Project / cynicmusic.com / pixelsphere.org
```

## Notes and residual risks

- CC0 on OpenGameArt is declared by the uploader; we only used items whose uploader presents
  themselves as the author (the page text says they recorded/composed it) and that are long-standing
  uploads. We cannot independently verify authorship. Keep the page records in `licenses/`.
- BigSoundBank states its "Free and royalty-free" sounds are CC0 and not registered in Content ID;
  if a video platform ever flags a trailer, the licence page explains how to dispute it.
- Nothing here comes from commercial games/films, YouTube, AI-music services, or any NC/ND/SA licence.
