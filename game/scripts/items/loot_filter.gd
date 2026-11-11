class_name LootFilter
extends RefCounted
## Which drops you see. Per rarity: show or hide; per slot: hide plain and magic pieces you don't want; rares and
## better can be emphasised (taller beam, a chime). Hidden drops never land, so the ground stays readable.

const RARITIES: Array[String] = ["normal", "magic", "rare", "set", "unique"]
const SLOTS: Array[String] = ["staff", "relic", "head", "body", "hands", "feet", "belt", "neck", "ring"]
const PLAIN: Array[String] = ["normal", "magic"]

static var show_rarity: Dictionary = {"normal": true, "magic": true, "rare": true, "set": true, "unique": true}
static var hide_plain_slots: Array = []
static var emphasise: bool = true
static var hidden_count: int = 0


static func shows(it: Dictionary) -> bool:
	if not bool(show_rarity.get(it["rarity"], true)):
		return false
	return not (PLAIN.has(String(it["rarity"])) and hide_plain_slots.has(String(it["slot"])))


static func emphasised(it: Dictionary) -> bool:
	return emphasise and not PLAIN.has(String(it["rarity"]))


static func toggle_rarity(r: String) -> void:
	show_rarity[r] = not bool(show_rarity.get(r, true))


static func toggle_slot(s: String) -> void:
	if hide_plain_slots.has(s):
		hide_plain_slots.erase(s)
	else:
		hide_plain_slots.append(s)


static func to_dict() -> Dictionary:
	return {"rarity": show_rarity, "slots": hide_plain_slots, "emphasise": emphasise}


static func from_dict(d: Dictionary) -> void:
	show_rarity = d.get("rarity", show_rarity)
	hide_plain_slots = d.get("slots", [])
	emphasise = bool(d.get("emphasise", true))
