class_name TrainerPresets
extends RefCounted
## The trainer kit's colour ramps and key colours, read from data/trainer/presets.json.
##
## Every ramp is three colours, light to dark. Hair, top, bottom and shoes layers are drawn
## in the grey key ramp; the body is drawn in the skin key ramp. A palette-swap shader
## turns each key ramp into the chosen ramp.

const PRESETS_PATH := "res://data/trainer/presets.json"

## Which group of ramps each kind of choice picks from.
const HAIR := "hair"
const OUTFIT := "outfit"
const SKIN := "skin"

static var _data: Dictionary = {}


## Names of the ramps in a group ("hair", "outfit" or "skin"), in file order.
static func ramp_names(group: String) -> Array[StringName]:
	var names: Array[StringName] = []
	for ramp_name: String in _presets()[group]:
		names.append(StringName(ramp_name))
	return names


## The three colours (light, mid, dark) of one ramp.
static func ramp(group: String, ramp_name: StringName) -> PackedColorArray:
	return _to_colors(_presets()[group][String(ramp_name)])


## The grey key ramp that hair and clothes are drawn in.
static func grey_key() -> PackedColorArray:
	return _key_ramp("recolour_greys")


## The skin key ramp that the body is drawn in.
static func skin_key() -> PackedColorArray:
	return _key_ramp(SKIN)


static func _key_ramp(key_name: String) -> PackedColorArray:
	var key: Dictionary = _presets()["key"][key_name]
	return _to_colors([key["light"], key["mid"], key["dark"]])


static func _to_colors(hex_codes: Array) -> PackedColorArray:
	var colors := PackedColorArray()
	for hex_code: String in hex_codes:
		colors.append(Color.html(hex_code))
	return colors


static func _presets() -> Dictionary:
	if _data.is_empty():
		var json: JSON = load(PRESETS_PATH)
		_data = json.data
	return _data
