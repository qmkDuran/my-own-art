# Audio credits and licences

Every sound in this folder is **original procedural audio**, synthesized for this project by
`art/audio/synth.py` (numpy/scipy additive synthesis, filtered noise, synthetic convolution reverb).
No recordings, samples or sound libraries were used, and nothing was downloaded.

**Licence:** CC0 1.0 Universal (public domain dedication), see `LICENSE-CC0.txt`.

## Musical source material
| File | Content | Source / licence |
|---|---|---|
| `holy.wav` | Instrumental arrangement (flute/organ-like lead, wordless "aah" pad, harp) of the opening phrase of the hymn tune **NICAEA** ("Holy, Holy, Holy! Lord God Almighty") | Tune by John Bacchus Dykes, 1861. **Public domain** (composer died 1876). The arrangement is original, CC0. No lyrics are sung. |
| `city_music.ogg`, `menu_music.ogg`, `throne_music.ogg` | Original chord progressions in D major (pads, harp arpeggios, wordless choir, organ pedal, bells) | Original, CC0 |

## Sound list
| File | Use |
|---|---|
| `menu_music.ogg` | Start-menu loop (16 s) |
| `city_music.ogg` | Holy city music bed: warm pads and harp (32 s loop) |
| `air.ogg` | Calm air, no birds or wind gusts (12 s loop) |
| `river.ogg` | River of the water of life, volume follows the distance to the river (8 s loop) |
| `step_gold0-2.wav` | Soft chime-like steps on gold and glass (also used, higher, on the sea of glass) |
| `step_grass0-1.wav` | Soft steps on the grass banks |
| `gate_chime.wav` | Rising bells when stepping into the light of the pearl gate |
| `throne_music.ogg` | Throne room: wordless choir "aah", organ pedal on D, harps, distant bells (32 s loop) |
| `lamps.ogg` | Very quiet hiss and crackle of the seven lamps of fire (6 s loop) |
| `thunder1-2.wav` | Soft rolling thunder after each lightning flash (Rev 4:5) |
| `crown_cast.wav` | Harp glissando when the elders cast their crowns (Rev 4:10) |
| `crown_land.wav` | Soft metallic clink as crowns come to rest on the glass |
| `wing_whoosh.wav` | Very quiet rush on each downstroke of the living creatures' wings |
| `pastoral_music.ogg` | New earth: pastoral loop in G (pads, harp, flute-like tune), original (29 s loop) |
| `lamb.wav`, `cow.wav` | Very quiet lamb and cow voices on the new earth (formant synthesis) |
| `knock.wav` | Gentle wooden hammer knock for the builder (Isa 65:21) |
| `holy.wav` | Plays when the player kneels (E): the music swells into "Holy, Holy, Holy" (Rev 4:8) |

Loops are rendered so that their tails (note releases, reverb, filtered noise) wrap back onto their start, which makes them seamless.
Rebuild everything with `python3 art/audio/synth.py` from the `heaven/` folder.
