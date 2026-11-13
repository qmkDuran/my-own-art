class_name Encounter
extends RefCounted
## One fight of the mission (data/mission.json encounters): it starts when the player walks into its trigger
## circle, spawning its first wave; the next wave comes when the one before is down to wave_at enemies; it is
## cleared when the last wave is beaten.

var id: String = ""
var spec: Dictionary = {}
var started: bool = false
var cleared: bool = false
var wave: int = 0
var alive: Array[Enemy] = []


func _init(encounter_spec: Dictionary) -> void:
	spec = encounter_spec
	id = spec["id"]


func is_boss() -> bool:
	return spec.get("boss", false)


## True while it is being fought.
func engaged() -> bool:
	return started and not cleared


## Advances the fight; returns what happened this frame: "started", "wave", "cleared" or "".
func update(player_at: Vector3, roster: Roster) -> String:
	if cleared:
		return ""
	var trigger: Array = spec["trigger"]
	if not started:
		if Vector2(player_at.x - float(trigger[0]), player_at.z - float(trigger[1])).length() < float(trigger[2]):
			started = true
			_spawn(0, roster)
			return "started"
		return ""
	alive = alive.filter(func(enemy: Enemy) -> bool: return is_instance_valid(enemy) and enemy.is_alive())
	var waves: Array = spec["waves"]
	if wave + 1 < waves.size() and alive.size() <= int(spec["wave_at"]):
		wave += 1
		_spawn(wave, roster)
		return "wave"
	if alive.is_empty() and wave == waves.size() - 1:
		cleared = true
		return "cleared"
	return ""


func _spawn(index: int, roster: Roster) -> void:
	for entry: Array in spec["waves"][index]:
		alive.append(roster.spawn(entry[0], Tuning.point(entry.slice(1))))
