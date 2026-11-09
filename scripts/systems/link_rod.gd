extends Node
## The trainer's Link Rod: a stolen, hacked Warden control rod (registered as the "LinkRod"
## autoload). It holds the hacked chips the player has, which of them sit in its slots,
## and the scrap used to hack them (see DESIGN.md, "Loot: hacked chips").
##
## ChipEffects applies the equipped chips' revealed mods to Emberoo; the Link Rod screen (C)
## shows and changes everything here. Every change fires `changed` (and autosaves).

signal changed
## A chip went into storage (e.g. picked up), for the HUD toast.
signal chip_added(chip: Chip)
## A chip couldn't be stored (storage full), for the HUD toast.
signal storage_full

## Slots the rod starts with; each CHIP_SLOT Glimmer Shard adds one, up to MAX_SLOTS.
const BASE_SLOTS := 1
const MAX_SLOTS := 4
## Chips kept at most (equipped ones included); salvage some to make room.
const MAX_CHIPS := 20

var scrap: int = 0

var _chips: Array[Chip] = []
## Serials of the equipped chips, in slot order.
var _equipped: Array[int] = []
var _next_serial: int = 1


func _ready() -> void:
	ShardInventory.collected.connect(func(_shard_id: String) -> void: changed.emit())


func slot_count() -> int:
	return mini(MAX_SLOTS, BASE_SLOTS + ShardInventory.count_of(ShardReward.Kind.CHIP_SLOT))


func chips() -> Array[Chip]:
	return _chips


func is_full() -> bool:
	return _chips.size() >= MAX_CHIPS


func find_chip(serial: int) -> Chip:
	for chip in _chips:
		if chip.serial == serial:
			return chip
	return null


## A new chip from a drop (not stored yet: see `add_chip`).
func roll_chip(tier: int, quality: Dictionary) -> Chip:
	var chip := ChipRoller.roll_chip(_next_serial, tier, quality)
	_next_serial += 1
	return chip


## Stores a chip; false (and nothing stored) when storage is full.
func add_chip(chip: Chip) -> bool:
	if chip == null:
		return false
	if is_full():
		storage_full.emit()
		return false
	_next_serial = maxi(_next_serial, chip.serial + 1)
	_chips.append(chip)
	chip_added.emit(chip)
	changed.emit()
	return true


func add_scrap(amount: int) -> void:
	scrap += amount
	changed.emit()


# --- Slots ------------------------------------------------------------------------

func is_equipped(chip: Chip) -> bool:
	return chip != null and _equipped.has(chip.serial)


## The chip in a slot, or null when it is empty.
func chip_in_slot(slot_index: int) -> Chip:
	return find_chip(_equipped[slot_index]) if slot_index < _equipped.size() else null


func equipped_chips() -> Array[Chip]:
	var equipped: Array[Chip] = []
	for serial in _equipped:
		equipped.append(find_chip(serial))
	return equipped


func has_free_slot() -> bool:
	return _equipped.size() < slot_count()


## Puts the chip in the first free slot. False when it can't (no free slot, or already in).
func equip(chip: Chip) -> bool:
	if chip == null or is_equipped(chip) or not has_free_slot() or not _chips.has(chip):
		return false
	_equipped.append(chip.serial)
	changed.emit()
	return true


func unequip(chip: Chip) -> void:
	if is_equipped(chip):
		_equipped.erase(chip.serial)
		changed.emit()


## Breaks the chip down for scrap (taking it out of its slot first). Returns the scrap gained.
func salvage(chip: Chip) -> int:
	if not _chips.has(chip):
		return 0
	_equipped.erase(chip.serial)
	_chips.erase(chip)
	scrap += chip.salvage_value()
	changed.emit()
	return chip.salvage_value()


# --- Hacking ----------------------------------------------------------------------

## "" if the hack can be done now, else why not (see ChipHacking).
func hack_refusal(chip: Chip, mod_index: int, hack_kind: ChipHacking.Hack) -> String:
	return ChipHacking.refusal(chip, mod_index, hack_kind, scrap)


## Spends the scrap and hacks the mod. False (nothing spent) when it can't.
func hack(chip: Chip, mod_index: int, hack_kind: ChipHacking.Hack) -> bool:
	if hack_refusal(chip, mod_index, hack_kind) != "":
		return false
	scrap -= ChipHacking.cost(hack_kind)
	ChipHacking.apply(chip, mod_index, hack_kind)
	changed.emit()
	return true


# --- Save -------------------------------------------------------------------------

func to_save_data() -> Dictionary:
	return {
		"scrap": scrap,
		"chips": _chips.map(func(chip: Chip) -> Dictionary: return chip.to_save_data()),
		"equipped": _equipped.duplicate(),
	}


## Restores a save (an empty one means no chips and no scrap). Damaged chips are dropped,
## and equipped serials that don't match a chip (or don't fit the slots) are left out.
func load_save_data(data: Dictionary) -> void:
	scrap = SaveData.read_int(data, "scrap", 0, 0, SaveData.NO_LIMIT)
	_chips.clear()
	_equipped.clear()
	_next_serial = 1
	var saved_chips: Variant = data.get("chips")
	if saved_chips is Array:
		for chip_data: Variant in saved_chips:
			var chip := Chip.from_save_data(chip_data) if chip_data is Dictionary else null
			if chip != null and find_chip(chip.serial) == null and not is_full():
				_chips.append(chip)
				_next_serial = maxi(_next_serial, chip.serial + 1)
	var saved_equipped: Variant = data.get("equipped")
	if saved_equipped is Array:
		for serial: Variant in saved_equipped:
			var chip := find_chip(int(serial)) if (serial is int or serial is float) else null
			if chip != null and not is_equipped(chip) and has_free_slot():
				_equipped.append(chip.serial)
	changed.emit()
