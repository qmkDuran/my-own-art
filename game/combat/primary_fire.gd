class_name PrimaryFire
extends Node
## The primary, the bread and butter: while the button is held, a quick lantern bolt every fire_interval
## (data/combat.json primary), from the lantern towards the crosshair with a hair of spread, with a little muzzle
## pop, a plucky cast sound and a tiny camera kick.

const MUZZLE_POP: float = 1.0

var _kit: LamplighterKit
var _wait: float = 0.0


func setup(kit: LamplighterKit) -> void:
	name = "PrimaryFire"
	_kit = kit


## Fires one bolt if the interval has passed; true when it fired.
func trigger() -> bool:
	if _wait > 0.0 or _kit.busy():
		return false
	_wait = Tuning.number("combat", "primary", "fire_interval")
	_kit.aim.engage()
	var from: Vector3 = _kit.aim.muzzle()
	var spread: float = deg_to_rad(Tuning.number("combat", "primary", "spread_deg"))
	var direction: Vector3 = _kit.aim.direction_from(from).rotated(Vector3.UP, randf_range(-spread, spread))
	var bolt := PlayerBolt.new()
	_kit.roster.add_effect(bolt, from)
	bolt.setup(_kit, direction)
	_muzzle(from)
	_kit.fx.kit.sfx.cue("primary_cast", from)
	_kit.camera_rig.kick(Tuning.number("combat", "camera", "kick"))
	return true


func _muzzle(at: Vector3) -> void:
	var spec: Dictionary = _kit.fx.look("primary")["muzzle"]
	var star := StarPop.new()
	_kit.fx.kit.place(star, at)
	star.play(Tuning.color(spec["color"]), Tuning.color(_kit.fx.look("primary")["impact"]["tip_color"]),
		float(spec["size"]), float(spec["seconds"]), float(spec["energy"]) * MUZZLE_POP)


func _process(delta: float) -> void:
	_wait = maxf(_wait - delta, 0.0)
