extends Node
## Story moments that have happened (registered as the "StoryFlags" autoload), each a name
## that is either set or not: the arrival raid won, the Link Rod handed over, the Warden
## Captain beaten. Things in the world ask `has` and change when a flag is set; SaveGame saves
## them like any other system (`to_save_data` / `load_save_data`).

## Fired when a flag is set for the first time (SaveGame saves then).
signal changed(flag: String)

## The Warden raid at the Hometown Outskirts was beaten off (the barricade into town is open).
const ARRIVAL_RAID_WON := "arrival_raid_won"
## The Tinkerer hacked the stolen Warden rod into the Link Rod (the C key works from then on).
const LINK_ROD_GIVEN := "link_rod_given"

var _flags: Dictionary = {}


func has(flag: String) -> bool:
	return _flags.has(flag)


## Sets `flag`; setting one that is already set does nothing.
func set_flag(flag: String) -> void:
	if flag == "" or _flags.has(flag):
		return
	_flags[flag] = true
	changed.emit(flag)


## What SaveGame writes.
func to_save_data() -> Dictionary:
	var names: Array[String] = []
	for flag: String in _flags:
		names.append(flag)
	names.sort()
	return {"flags": names}


## Restores the saved flags (an empty save means none yet). Unknown names are kept as they are.
func load_save_data(data: Dictionary) -> void:
	_flags.clear()
	var names: Variant = data.get("flags")
	if not names is Array:
		return
	for flag: Variant in names:
		if flag is String and flag != "":
			_flags[flag] = true
