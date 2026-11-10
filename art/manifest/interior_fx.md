# Interior, item and FX art - Chapter 1 (manifest)

Owner: interiors + FX art agent. Folders: `art/interior/` (props + tiles), `art/items/` (icons + world pickups), `art/fx/`.
Style per `art/STYLE.md`: Resurrect 64 only, 1 px `#2e222f` outline on props (none on floor tiles), light from the top-left, top-down 3/4.
Every generated piece used PixelLab `generate-image-v2` with `target_palette` = Resurrect 64 and `style_image` = `style_anchors/anchor_building_crop_256.png`,
then was snapped to the palette (Lab), alpha 0/255, and **reduced 2:1 by majority vote + re-outlined** to true scale (the generator draws furniture at ~2x).
Nothing is upscaled. Rugs (`rug`, `runner_rug`) are kept at their native generated size.
Scale check: characters ~60 px; fridge 71, door 63, couch 73x35, dining table 78x60 (4 chairs ~21x40), bed 44x60.

Pieces marked "(handoff)" come from the exterior agent's earlier pass (`revelation_art/handoff/`), unchanged. Its 32 px floor tiles are reused as is;
walls were rebuilt with a ceiling shadow, crown, baseboard and corner end pieces.

## art.json changes (data/ is owned by the engine team - apply these)

### Repoint existing ids (`path` only; keep `placeholder`)
| id | new path |
|---|---|
| `tile_wall_top` | `res://art/interior/tiles/wall_top.png` |
| `tile_wall_face` | `res://art/interior/tiles/wall_face_living.png` |
| `tile_floor_wood` | `res://art/interior/tiles/floor_wood.png` |
| `tile_floor_kitchen` | `res://art/interior/tiles/floor_kitchen.png` |
| `tile_carpet` | `res://art/interior/tiles/carpet_living.png` |
| `tile_door` | `res://art/interior/tiles/door_threshold.png` |
| `tile_store_floor` | `res://art/interior/tiles/floor_store.png` |
| `tile_store_wall_face` | `res://art/interior/tiles/wall_face_store.png` |
| `bed` | `res://art/interior/props/bed.png` |
| `desk` | `res://art/interior/props/desk.png` |
| `boxes` | `res://art/interior/props/boxes.png` |
| `shelf_small` | `res://art/interior/props/shelf_small.png` |
| `poster` | `res://art/interior/props/poster.png` |
| `window` | `res://art/interior/props/window_evening.png` |
| `phone_small` | `res://art/interior/props/phone_small.png` |
| `dining_table` | `res://art/interior/props/dining_table.png` |
| `chair` | `res://art/interior/props/chair_front.png` |
| `fridge` | `res://art/interior/props/fridge.png` |
| `stove` | `res://art/interior/props/stove.png` |
| `counter` | `res://art/interior/props/counter_sink.png` |
| `cupboard` | `res://art/interior/props/cupboard.png` |
| `calendar` | `res://art/interior/props/calendar.png` |
| `radio` | `res://art/interior/props/radio.png` |
| `mug` | `res://art/interior/props/mug.png` |
| `bible` | `res://art/interior/props/bible.png` |
| `couch` | `res://art/interior/props/couch.png` |
| `recliner` | `res://art/interior/props/recliner.png` |
| `tv` | `res://art/interior/props/tv_on.png` |
| `bookshelf` | `res://art/interior/props/bookshelf.png` |
| `keyboard` | `res://art/interior/props/keyboard.png` |
| `photos` | `res://art/interior/props/photos.png` |
| `smoke_alarm` | `res://art/interior/props/smoke_alarm.png` |
| `floor_lamp` | `res://art/interior/props/floor_lamp.png` |
| `rug` | `res://art/interior/props/rug.png` |
| `doormat` | `res://art/interior/props/doormat.png` |
| `key_hook` | `res://art/interior/props/coat_rack.png` |
| `slippers` | `res://art/interior/props/slippers.png` |
| `clothes_generic` | `res://art/interior/props/clothes_pile.png` |
| `glass_shards` | `res://art/interior/props/glass_floor.png` |
| `store_shelf` | `res://art/interior/props/store_shelf.png` |
| `cooler` | `res://art/interior/props/cooler.png` |
| `bread_rack` | `res://art/interior/props/bread_rack.png` |
| `candy_rack` | `res://art/interior/props/candy_rack.png` |
| `store_counter` | `res://art/interior/props/store_counter.png` |
| `lottery_screen` | `res://art/interior/props/lottery_kiosk.png` |
| `small_tv` | `res://art/interior/props/small_tv.png` |
| `glasses` | `res://art/interior/props/glasses.png` |
| `name_tag` | `res://art/interior/props/name_tag.png` |
| `mop` | `res://art/items/world/mop_world.png` |
| `wet_floor_sign` | `res://art/interior/props/wet_floor_sign.png` |
| `leash` | `res://art/interior/props/leash.png` |
| `sneaker` | `res://art/interior/props/sneaker.png` |
| `icon_food` | `res://art/items/icon_food.png` |
| `icon_water` | `res://art/items/icon_water.png` |
| `icon_medicine` | `res://art/items/icon_medicine.png` |
| `icon_bat` | `res://art/items/icon_bat.png` |
| `icon_mop` | `res://art/items/icon_mop.png` |
| `icon_key` | `res://art/items/icon_key.png` |
| `icon_bible` | `res://art/items/icon_bible.png` |
| `icon_letter` | `res://art/items/icon_letter.png` |
| `icon_milk` | `res://art/items/icon_milk.png` |
| `icon_bread` | `res://art/items/icon_bread.png` |
| `icon_battery` | `res://art/items/icon_battery.png` |
| `icon_card` | `res://art/items/icon_card.png` |
| `icon_bag` | `res://art/items/icon_bag.png` |
| `icon_box_cutter` | `res://art/items/icon_box_cutter.png` |
| `icon_phone` | `res://art/items/icon_phone.png` |
| `icon_candy` | `res://art/items/icon_candy.png` |

Notes on existing entities in `data/zones/*.json`:
- `h_laptop` (`laptop`): the desk sprite already has the monitor and keyboard, so drop `art` from `h_laptop` (keep the examine).
- `st_register` (`register`): the counter sprite includes the register and card reader; drop `art` from `st_register` or point it at nothing.
- `st_battery_hook` / `battery_hook`, `notice_board`, `window_lit` / `window_dark` (exterior), `fire` (prop): not drawn here, keep the placeholders
  (the street fire should use the animated `fx/fire*` strips).
- `k_counter` should use `counter_sink`; `k_drawer` (junk drawer, sugar tin) should use the new `counter` id.
- Chairs: give each chair its facing - `chair_front` (far side of the table), `chair_back` (near side), `chair_left` / `chair_right` (ends);
  `k_chair_mom` -> `chair_mom` (red knitted cushion, already angled as if pushed back for the C1_S08 fixed shot).
- After the moment (`if: vanished`): swap `st_cooler_*` to `cooler_dark` / `cooler_broken`, `st_tv` to `small_tv_off`, `st_lottery` to `lottery_kiosk_dark`,
  one `st_shelf_*` to `store_shelf_toppled`, and add floor decals `spilled_goods`, `milk_spill`, `glass_floor` (all `"floor": true`).
- `l_tv` -> `tv_on` before, `tv_breaking` in C1_S08 (`l_tv_night`).

### New ids to add (all `res://art/interior/props/<id>.png`, anchor bottom-centre unless noted)
`armchair_mom`, `armchair_rose`, `bible_open`, `camp_stove`, `candy_rack_toppled`, `ceiling_fan`, `ceiling_light`, `ceiling_light_dead`, `chair_back`, `chair_left`, `chair_right`, `chair_mom`, `clock`, `cooler_broken`, `cooler_dark`, `counter`, `cross`, `dad_photo`, `dish_towel`, `dishes`, `door`, `emergency_light`, `laundry_basket`, `letter`, `lottery_kiosk_dark`, `medicine_bottle`, `medkit`, `milk_spill`, `mop_bucket`, `newspaper_rack`, `nightstand`, `office_chair`, `pharmacy_counter`, `phone_dark`, `photo_small`, `plant_small`, `plant_tall`, `poster_band`, `runner_rug`, `scanner_gun`, `side_table_lamp`, `small_tv_off`, `spilled_goods`, `stairs_basement`, `stairs_up`, `stairs_up_runner`, `storage_boxes`, `storage_shelf`, `store_shelf_b`, `store_shelf_toppled`, `tv`, `tv_breaking`, `tv_small`, `tv_small_on`, `tv_small_breaking`, `water_heater`, `window_night`, `workbench`

New tiles worth adding to `data/tiles.json` (art ids `tile_<name>` -> `res://art/interior/tiles/<name>.png`):
`floor_bathroom`, `carpet_bedroom`, `carpet_hall`, `floor_basement`, `floor_basement_stain`, `floor_store_scuffed`, `floor_wood_walnut(_1)`, `floor_kitchen_warm`,
and per-room wall faces (`wall_face_<room>` for living, hall, kitchen, bedroom, bathroom, store, basement) via one wall tile id per room, e.g.
`"wall_kitchen": {"art": "tile_wall_top", "face_art": "tile_wall_face_kitchen", "solid": true}`.

## Props - `art/interior/props/` (102 files)
Anchor: bottom-centre (engine default) = the point where the object meets the floor. "Collision" is a suggested `solid` footprint `[w, h]`
measured up from the bottom edge (the engine centres it on x and puts its bottom at the anchor). Decals: `"floor": true` (floor) or placed on a wall face
(bottom of the decal ~8-12 px above the wall face's baseboard; windows/doors bottom at the floor line).

| file | size | anchor | collision | what |
|---|---|---|---|---|
| `armchair_mom` | 35x36 | bottom-centre | 33x18 | MOM'S ARMCHAIR (living room): mustard armchair with her granny-square throw |
| `armchair_rose` | 49x55 | bottom-centre | 47x27 | alt armchair with crocheted blanket (exterior agent's handoff) |
| `bed` | 44x60 | bottom-centre | 42x40 | hero bed, blue duvet |
| `bible` | 18x16 | floor/wall decal | - | Mom's Bible closed (handoff) |
| `bible_open` | 28x17 | floor/wall decal | - | Mom's Bible open (handoff) |
| `bookshelf` | 36x59 | bottom-centre | 34x16 | tall bookshelf (handoff, true scale) |
| `boxes` | 53x42 | bottom-centre | 51x14 | moving boxes 'APT - KITCHEN' |
| `bread_rack` | 39x42 | bottom-centre | 37x14 | store bread rack |
| `calendar` | 22x31 | floor/wall decal | - | wall calendar (wall decal) |
| `camp_stove` | 25x23 | bottom-centre | 23x7 | Dad's green camping stove (basement stash) |
| `candy_rack` | 30x39 | bottom-centre | 28x13 | store wire candy rack |
| `candy_rack_toppled` | 54x43 | bottom-centre | 52x14 | AFTER: candy rack knocked over, candy spilled |
| `ceiling_fan` | 46x44 | floor/wall decal | - | ceiling fan (draw above everything) |
| `ceiling_light` | 43x17 | floor/wall decal | - | store fluorescent panel, lit (draw above everything) |
| `ceiling_light_dead` | 43x17 | floor/wall decal | - | AFTER: dead fluorescent panel |
| `chair_back` | 21x38 | bottom-centre | 17x8 | dining chair seen from behind (near side of table) |
| `chair_front` | 22x45 | bottom-centre | 18x8 | dining chair facing camera (far side of table) |
| `chair_left` | 20x43 | bottom-centre | 16x8 | dining chair, faces right (left end) |
| `chair_mom` | 27x47 | bottom-centre | 23x8 | MOM'S CHAIR at the table: red knitted cushion, angled/pushed back (fixed-shot object) |
| `chair_right` | 20x43 | bottom-centre | 16x8 | dining chair, faces left (right end) |
| `clock` | 15x15 | floor/wall decal | - | wall clock (wall decal) |
| `clothes_pile` | 42x24 | floor/wall decal | - | pile of clothes (vanished person / bedroom floor) |
| `coat_rack` | 45x31 | bottom-centre | 43x10 | hall coat hooks with jackets, keys and the READ tote (= key hook) |
| `cooler` | 36x59 | bottom-centre | 34x16 | glass-door drinks fridge (lit) |
| `cooler_broken` | 36x59 | bottom-centre | 34x16 | AFTER: unlit fridge with shattered door |
| `cooler_dark` | 36x59 | bottom-centre | 34x16 | AFTER / power out: drinks fridge unlit |
| `couch` | 73x35 | bottom-centre | 71x17 | dusty-rose 3-seat sofa |
| `counter` | 43x53 | bottom-centre | 41x16 | kitchen counter with drawers (junk drawer, sugar tin, toaster) |
| `counter_sink` | 65x53 | bottom-centre | 63x16 | kitchen counter with sink and dish rack |
| `cross` | 8x12 | floor/wall decal | - | small wooden cross (wall decal) |
| `cupboard` | 41x71 | bottom-centre | 39x16 | tall pantry cupboard (plates) |
| `dad_photo` | 19x20 | floor/wall decal | - | framed photo of Dad with the fish (wall decal) |
| `desk` | 54x51 | bottom-centre | 52x16 | desk with monitor, keyboard, lamp (hero bedroom) |
| `dining_table` | 78x60 | bottom-centre | 76x24 | kitchen table with cloth and dinner, seats 4 |
| `dish_towel` | 13x30 | floor/wall decal | - | dish towel on hook (wall decal) |
| `dishes` | 19x16 | bottom-centre | 17x6 | stack of plates |
| `door` | 37x63 | floor/wall decal | - | interior door, closed (place on a wall face, bottom at the floor line) |
| `doormat` | 38x14 | floor/wall decal | - | door mat (floor decal) |
| `emergency_light` | 14x9 | floor/wall decal | - | wall emergency light, red lamps (store) |
| `floor_lamp` | 13x44 | bottom-centre | 8x6 | standing floor lamp (light source at the shade) |
| `fridge` | 36x71 | bottom-centre | 34x16 | kitchen fridge with magnets and the crayon drawing |
| `glass_floor` | 39x26 | floor/wall decal | - | AFTER: broken glass on the floor (floor decal) |
| `glasses` | 16x7 | floor/wall decal | - | reading glasses (handoff) |
| `keyboard` | 44x32 | bottom-centre | 42x10 | electric piano keyboard on stand |
| `laundry_basket` | 30x24 | bottom-centre | 28x8 | laundry basket |
| `leash` | 20x16 | floor/wall decal | - | empty dog leash (handoff) |
| `letter` | 18x12 | floor/wall decal | - | Mom's letter envelope (handoff) |
| `lottery_kiosk` | 21x51 | bottom-centre | 19x16 | lottery screen + phone charging lockers kiosk |
| `lottery_kiosk_dark` | 21x51 | bottom-centre | 19x16 | AFTER: kiosk, screen dead |
| `medicine_bottle` | 12x16 | floor/wall decal | - | pill bottle (handoff) |
| `medkit` | 19x16 | bottom-centre | 17x6 | red first-aid box (basement shelf) |
| `milk_spill` | 42x26 | floor/wall decal | - | AFTER: split milk carton puddle (floor decal) |
| `mop_bucket` | 30x43 | bottom-centre | 28x14 | mop in a yellow bucket |
| `mug` | 11x11 | floor/wall decal | - | Mom's mug |
| `mug_small` | 14x14 | floor/wall decal | - | mug (handoff variant) |
| `name_tag` | 16x9 | floor/wall decal | - | Hollis's name tag (handoff) |
| `newspaper_rack` | 30x36 | bottom-centre | 28x12 | wire newspaper / magazine rack |
| `nightstand` | 25x43 | bottom-centre | 23x14 | nightstand with lamp and glasses (Mom's room) |
| `office_chair` | 26x44 | bottom-centre | 24x14 | office chair |
| `pharmacy_counter` | 64x51 | bottom-centre | 62x16 | pharmacy counter with window and shelves |
| `phone_dark` | 11x18 | floor/wall decal | - | phone, screen off (handoff) |
| `phone_small` | 11x18 | floor/wall decal | - | phone, screen lit (handoff) |
| `photo_small` | 15x11 | floor/wall decal | - | small framed photo (wall decal) |
| `photos` | 38x14 | floor/wall decal | - | two framed family photos (wall decal) |
| `plant_small` | 18x19 | bottom-centre | 9x6 | small potted fern |
| `plant_tall` | 21x39 | bottom-centre | 10x6 | fiddle-leaf fig in pot |
| `poster` | 25x33 | floor/wall decal | - | faded space poster (bleached Saturn) |
| `poster_band` | 24x33 | floor/wall decal | - | made-up band poster |
| `radio` | 23x20 | bottom-centre | 21x6 | Mom's battery radio |
| `recliner` | 36x37 | bottom-centre | 34x18 | Dad's brown leather recliner |
| `rug` | 149x56 | floor/wall decal | - | patterned area rug (floor decal, native scale) |
| `runner_rug` | 139x37 | floor/wall decal | - | hallway runner (floor decal, native scale) |
| `scanner_gun` | 14x15 | floor/wall decal | - | store scanner gun (handoff) |
| `shadow` | 28x9 | floor/wall decal | - | soft contact shadow (handoff) |
| `shelf_small` | 41x45 | bottom-centre | 39x15 | trophy shelf |
| `side_table_lamp` | 19x33 | bottom-centre | 9x6 | round side table with lamp |
| `slippers` | 17x8 | floor/wall decal | - | Mom's slippers (side by side) |
| `small_tv` | 28x23 | floor/wall decal | - | wall-mounted store TV |
| `small_tv_off` | 28x23 | floor/wall decal | - | AFTER: store TV off |
| `smoke_alarm` | 11x11 | floor/wall decal | - | smoke alarm (wall/ceiling decal) |
| `sneaker` | 17x12 | floor/wall decal | - | child's sneaker (handoff) |
| `spilled_goods` | 63x35 | floor/wall decal | - | AFTER: spilled packaged goods (floor decal) |
| `stairs_basement` | 34x48 | bottom-centre | 32x16 | basement stairs going down (place in a wall gap / floor) |
| `stairs_up` | 39x56 | bottom-centre | 37x16 | staircase going up with banister |
| `stairs_up_runner` | 37x56 | bottom-centre | 35x16 | staircase with carpet runner (the creaky fourth stair) |
| `storage_boxes` | 40x42 | bottom-centre | 38x14 | basement boxes ('CHRISTMAS') |
| `storage_shelf` | 44x56 | bottom-centre | 42x16 | basement metal shelf: cans and water jugs (Mom's stash) |
| `store_counter` | 71x42 | bottom-centre | 69x14 | checkout counter with register, card reader, candy |
| `store_shelf` | 82x55 | bottom-centre | 80x16 | gondola shelf, snacks and cans (front view, 3 tiles wide) |
| `store_shelf_b` | 70x52 | bottom-centre | 68x16 | gondola shelf, bottles/soap/paper towels |
| `store_shelf_toppled` | 96x49 | bottom-centre | 94x16 | AFTER: gondola shelf knocked over, goods spilled |
| `stove` | 39x56 | bottom-centre | 37x16 | kitchen stove with pot |
| `tv` | 56x45 | bottom-centre | 54x15 | TV on low stand, off (handoff) |
| `tv_breaking` | 56x45 | bottom-centre | 54x15 | TV on: 'BREAKING' red ticker, empty anchor desk |
| `tv_on` | 56x45 | bottom-centre | 54x15 | TV on: news (evening) |
| `tv_small_breaking` | 45x43 | bottom-centre | 43x14 | smaller TV, breaking |
| `tv_small_on` | 45x43 | bottom-centre | 43x14 | smaller TV, news |
| `water_heater` | 31x61 | bottom-centre | 29x16 | basement water heater |
| `wet_floor_sign` | 16x23 | bottom-centre | 8x6 | yellow wet floor sign |
| `window_evening` | 36x42 | floor/wall decal | - | interior window, blinds, warm evening light (wall decal) |
| `window_night` | 37x42 | floor/wall decal | - | interior window at night (wall decal) |
| `workbench` | 64x41 | bottom-centre | 62x13 | Dad's workbench with vise |

## Tiles - `art/interior/tiles/` (32x32, no outline, tileable)
`carpet_bedroom`, `carpet_hall`, `carpet_living`, `door_threshold`, `floor_basement`, `floor_basement_stain`, `floor_bathroom`, `floor_kitchen`, `floor_kitchen_warm`, `floor_store`, `floor_store_scuffed`, `floor_wood`, `floor_wood_1`, `floor_wood_2`, `floor_wood_3`, `floor_wood_dark`, `floor_wood_walnut`, `floor_wood_walnut_1`, `store_wall_top`, `wall_face_basement`, `wall_face_basement_end_l`, `wall_face_basement_end_r`, `wall_face_basement_lower`, `wall_face_basement_tall`, `wall_face_basement_tall_end_l`, `wall_face_basement_tall_end_r`, `wall_face_basement_upper`, `wall_face_bathroom`, `wall_face_bathroom_end_l`, `wall_face_bathroom_end_r`, `wall_face_bathroom_lower`, `wall_face_bathroom_tall`, `wall_face_bathroom_tall_end_l`, `wall_face_bathroom_tall_end_r`, `wall_face_bathroom_upper`, `wall_face_bedroom`, `wall_face_bedroom_end_l`, `wall_face_bedroom_end_r`, `wall_face_bedroom_lower`, `wall_face_bedroom_tall`, `wall_face_bedroom_tall_end_l`, `wall_face_bedroom_tall_end_r`, `wall_face_bedroom_upper`, `wall_face_hall`, `wall_face_hall_end_l`, `wall_face_hall_end_r`, `wall_face_hall_lower`, `wall_face_hall_tall`, `wall_face_hall_tall_end_l`, `wall_face_hall_tall_end_r`, `wall_face_hall_upper`, `wall_face_kitchen`, `wall_face_kitchen_end_l`, `wall_face_kitchen_end_r`, `wall_face_kitchen_lower`, `wall_face_kitchen_tall`, `wall_face_kitchen_tall_end_l`, `wall_face_kitchen_tall_end_r`, `wall_face_kitchen_upper`, `wall_face_living`, `wall_face_living_end_l`, `wall_face_living_end_r`, `wall_face_living_lower`, `wall_face_living_tall`, `wall_face_living_tall_end_l`, `wall_face_living_tall_end_r`, `wall_face_living_upper`, `wall_face_store`, `wall_face_store_end_l`, `wall_face_store_end_r`, `wall_face_store_lower`, `wall_face_store_tall`, `wall_face_store_tall_end_l`, `wall_face_store_tall_end_r`, `wall_face_store_upper`, `wall_top`, `wall_top_e`, `wall_top_n`, `wall_top_s`, `wall_top_w`

- Floors: `floor_wood(_1.._3, _dark)`, `floor_kitchen`, `floor_store`, `floor_basement` (handoff); new `floor_wood_walnut(_1)` (muted, sits better
  under the generated furniture - used in the living-room mock), `floor_kitchen_warm`, `floor_bathroom` (8 px tiles), `carpet_living`, `carpet_bedroom`,
  `carpet_hall`, `floor_basement_stain`, `floor_store_scuffed`, `door_threshold` (doorway sill, use for `tile_door`).
- Walls (3/4): `wall_top` (cap seen from above; `wall_top_n/s/e/w` add a 1 px rim on one side for autotiling), `store_wall_top`.
  Faces per room (`living, hall, kitchen, bedroom, bathroom, store, basement`): `wall_face_<room>` is 32 px (the engine's single face row);
  `wall_face_<room>_tall` is 32x64 for 2-row walls, also split as `_upper` + `_lower` 32x32 tiles; `_end_l` / `_end_r` darken the left/right edge for
  inner corners and wall ends. Doorways = leave the cell as floor (`door_threshold`); windows and doors are props placed on the face
  (`window_evening`, `window_night`, `door`).

## Items - `art/items/`
Inventory icons, 32x32, centred, transparent: `icon_bag`, `icon_bat`, `icon_battery`, `icon_bible`, `icon_box_cutter`, `icon_bread`, `icon_candy`, `icon_card`, `icon_cash`, `icon_coffee_spilled`, `icon_crank_radio`, `icon_envelope`, `icon_flashlight`, `icon_food`, `icon_grocery_bag`, `icon_key`, `icon_letter`, `icon_medicine`, `icon_medkit`, `icon_milk`, `icon_mop`, `icon_painkillers`, `icon_phone`, `icon_phone_cracked`, `icon_water`, `icon_water_jug`.
(`icon_candy` is the handoff icon; all others were generated as one sheet and reduced.)

World pickups / dropped objects - `art/items/world/<name>_world.png`, anchor bottom-centre, no collision (radius-16 interact):
`bag_world` 16x14, `bat_world` 31x31, `battery_world` 6x9, `bible_world` 16x13, `box_cutter_world` 14x10, `bread_world` 14x15, `card_world` 12x7, `cash_world` 13x11, `coffee_spilled_world` 14x11, `crank_radio_world` 16x13, `flashlight_world` 14x12, `food_world` 8x12, `grocery_bag_world` 16x14, `key_world` 11x10, `letter_world` 16x14, `medicine_world` 6x11, `medkit_world` 15x11, `milk_world` 10x14, `mop_world` 31x32, `painkillers_world` 16x9, `phone_cracked_world` 14x11, `phone_world` 14x12, `water_jug_world` 10x15, `water_world` 6x15.
"What people were holding" drops: `phone_cracked_world`, `key_world`, `coffee_spilled_world`, `grocery_bag_world` (plus the handoff `phone_small`,
`glasses`, `name_tag`, `scanner_gun`, `sneaker`, `leash` in props). Small world items are the icon reduced 2:1; long items (`bat`, `mop`) are icon size.

## FX - `art/fx/` (timings in `art/fx/fx_anim.json`)
| file | size | frames | ms/frame | loop | origin px (in frame) | use |
|---|---|---|---|---|---|---|
| `fx/fire_small.png` | 160x28 | 8 x 20x28 (one row, left to right) | 90 | yes | [10, 27] | small flame loop (debris, stove-top, a burning bin); feet of the flame at origin |
| `fx/fire_medium.png` | 288x52 | 8 x 36x52 (one row, left to right) | 90 | yes | [18, 51] | medium flame loop (house/garage fire spot, store front at night) |
| `fx/dust_puff.png` | 192x24 | 6 x 32x24 (one row, left to right) | 70 | no | [16, 22] | one-shot dust puff (landing, shoving furniture, a falling shelf) |
| `fx/hit_flash.png` | 128x32 | 4 x 32x32 (one row, left to right) | 50 | no | [16, 16] | one-shot impact flash (bat / punch hit); centre on the point of contact |
| `fx/glass_burst.png` | 448x36 | 8 x 56x36 (one row, left to right) | 60 | no | [28, 35] | one-shot breaking-glass burst; last frame matches a settled shard pile (swap to props/glass_floor after) |
| `fx/fire.png` | 384x64 | 8 x 48x64 (one row, left to right) | 83 | yes | [24, 54] | looping car fire (place over the wreck bonnet; also small flames on debris) |
| `fx/smoke.png` | 768x96 | 16 x 48x96 (one row, left to right) | 100 | yes | [24, 94] | looping dark smoke column (place above the fire) |
| `fx/sparks.png` | 384x48 | 8 x 48x48 (one row, left to right) | 83 | no | [24, 24] | one-shot spark burst (broken streetlight, crash) |

Light / overlay textures (single colour, stepped alpha with 4x4 ordered dither, for PointLight2D `texture` or additive sprites):
`flashlight_cone` 200x172, `glass_shards` 72x16, `light_pool_cold` 192x192, `light_pool_fire` 128x128, `light_pool_fluorescent` 160x96, `light_pool_neutral` 128x128, `light_pool_red` 192x192, `light_pool_red_small` 96x64, `light_pool_street` 256x256, `light_pool_tv` 64x48, `light_pool_warm` 192x192, `light_window_evening` 80x72, `light_window_night` 80x72.
- `light_pool_warm`, `light_pool_cold`, `light_pool_fire`, `light_pool_street`, `flashlight_cone`, `glass_shards` are the handoff textures.
- New: `light_pool_red` / `light_pool_red_small` (store emergency light, pulse it), `light_pool_fluorescent`, `light_pool_tv`,
  `light_pool_neutral` (white - tint with the light's colour in `data/lights.json`), `light_window_evening` / `light_window_night`
  (slanted window light falling down-right; origin = top-left near the window bottom).
- `flashlight_cone`: origin at the left-middle (the lens), points right; rotate to aim.
- `fire.png`: the handoff car fire with its pale core recoloured to the palette yellow.

## Previews
`/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/revelation_art/interior/`: `mock_living_dinner_*`, `mock_store_after_*` (960x540 and 1920x1080),
`sheet_props_2x.png`, `sheet_tiles_2x.png`, `sheet_item_icons_3x.png`, `sheet_item_world_3x.png`, `sheet_fx_2x.png`, `fx_anims_3x.mp4`.
