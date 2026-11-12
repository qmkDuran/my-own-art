class_name PlayerModel
extends RefCounted
## What the bot has learned about this player's habits, from what it saw and heard across fights: favourite hiding
## spots and kinds, how soon they roll after its wind-ups, bite vs spit, time on high ground, where they set snares
## and which way they flee when hurt. Saved as JSON (user://player_model.json) and reset with F9.

signal learned(what: String)

var data: Dictionary = {}
var path: String


func _init(save_path: String) -> void:
	path = save_path
	reset()
	var text: String = FileAccess.get_file_as_string(path) if FileAccess.file_exists(path) else ""
	var parsed: Variant = JSON.parse_string(text) if text != "" else null
	if parsed is Dictionary:
		data.merge(parsed, true)


func reset() -> void:
	data = { "fights": 0, "hide_spots": {}, "hide_kinds": {}, "roll_delays": [], "attacks": { "bite": 0, "spit": 0 },
		"high_ground": { "on": 0, "total": 0 }, "snare_spots": [], "flee_dirs": [] }


func save() -> void:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "  "))


func note_fight() -> void:
	data["fights"] = int(data["fights"]) + 1


func note_hide(spot: HidingSpot) -> void:
	_count(data["hide_spots"], str(spot.spot_id))
	_count(data["hide_kinds"], spot.kind)
	learned.emit("you hide in the %s" % ("tall grass" if spot.kind == "grass" else "bushes"))


func note_attack(kind: String) -> void:
	_count(data["attacks"], kind)


func note_roll_delay(delay: float) -> void:
	_push(data["roll_delays"], delay)
	if rolls_early():
		learned.emit("you roll early")


func note_position(on_high_ground: bool) -> void:
	var tally: Dictionary = data["high_ground"]
	tally["total"] = int(tally["total"]) + 1
	tally["on"] = int(tally["on"]) + (1 if on_high_ground else 0)


func note_snare(where: Vector3) -> void:
	_push(data["snare_spots"], [where.x, where.z])
	learned.emit("you set snares here")


func note_flee(direction: Vector3) -> void:
	_push(data["flee_dirs"], [direction.x, direction.z])
	learned.emit("you flee this way when hurt")


## 0..1: how much this spot is a favourite (its share of all the hiding seen).
func favourite_weight(spot: HidingSpot) -> float:
	var spots: Dictionary = data["hide_spots"]
	var total: int = 0
	for key: String in spots:
		total += int(spots[key])
	return float(spots.get(str(spot.spot_id), 0)) / total if total > 0 else 0.0


func has_favourite() -> bool:
	return not (data["hide_spots"] as Dictionary).is_empty()


func favourite_kind() -> String:
	var kinds: Dictionary = data["hide_kinds"]
	var best: String = ""
	for kind: String in kinds:
		if best == "" or int(kinds[kind]) > int(kinds[best]):
			best = kind
	return best


## Share of observed rolls that came before the wind-up was half done (rolling on reflex, not on the hit).
func early_roll_share() -> float:
	var delays: Array = data["roll_delays"]
	if delays.is_empty():
		return 0.0
	var early: int = delays.filter(func(d: float) -> bool: return d < Tuning.ai_f("memory", "early_roll")).size()
	return float(early) / delays.size()


func rolls_early() -> bool:
	return early_roll_share() > 0.5


func bite_share() -> float:
	var attacks: Dictionary = data["attacks"]
	var total: int = int(attacks["bite"]) + int(attacks["spit"])
	return float(attacks["bite"]) / total if total > 0 else 0.5


func high_ground_share() -> float:
	var tally: Dictionary = data["high_ground"]
	return float(tally["on"]) / int(tally["total"]) if int(tally["total"]) > 0 else 0.0


func snare_spots() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for pair: Array in data["snare_spots"]:
		out.append(Vector3(float(pair[0]), 0.0, float(pair[1])))
	return out


## The average direction it flees in when hurt (zero when unknown).
func flee_direction() -> Vector3:
	var sum := Vector3.ZERO
	for pair: Array in data["flee_dirs"]:
		sum += Vector3(float(pair[0]), 0.0, float(pair[1]))
	return sum.normalized() if sum.length() > 0.0 else Vector3.ZERO


static func _count(table: Dictionary, key: String) -> void:
	table[key] = int(table.get(key, 0)) + 1


static func _push(list: Array, value: Variant) -> void:
	list.append(value)
	while list.size() > int(Tuning.ai_f("memory", "max_samples")):
		list.pop_front()
