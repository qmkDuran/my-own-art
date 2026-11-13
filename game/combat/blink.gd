class_name Blink
extends Node
## The blink (V): the snappy grounded dash (Agility) with no hurt while it lasts, plus a warm streak along its path
## and a soft pop where it starts. On a short cooldown.

const STREAK_WIDTH: float = 4.0
const STREAK_POINTS: int = 4

var _kit: LamplighterKit
var _trail: RibbonTrail


func setup(kit: LamplighterKit) -> void:
	name = "Blink"
	_kit = kit


func go() -> bool:
	if _kit.busy() or not (_kit.cooldowns["blink"] as Cooldown).is_ready():
		return false
	if not _kit.player.agility.start_dash(_kit.player.dash_direction()):
		return false
	_kit.player.puff()
	(_kit.cooldowns["blink"] as Cooldown).start()
	var spec: Dictionary = _kit.fx.look("blink")
	var colour: Color = Tuning.color(spec["color"])
	var star := StarPop.new()
	var chest: Vector3 = _kit.player.global_position + Vector3.UP * Tuning.number("combat", "player", "chest_height")
	_kit.fx.kit.place(star, chest)
	star.play(colour, colour.darkened(0.5), float(spec["ghost_alpha"]) * 2.0, float(spec["ghost_seconds"]), 1.0)
	if _kit.fx.kit.quota.trails:
		_trail = RibbonTrail.new()
		_trail.setup(_kit.player.lantern.light, colour, float(spec["streak_size"]) * STREAK_WIDTH, int(spec["ghosts"]) *
			STREAK_POINTS)
		_kit.player.add_child(_trail)
		get_tree().create_timer(float(spec["ghost_seconds"]), false).timeout.connect(_trail.queue_free)
	_kit.fx.kit.sfx.cue("blink", chest)
	return true
