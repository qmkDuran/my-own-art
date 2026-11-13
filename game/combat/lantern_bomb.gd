class_name LanternBomb
extends Node
## The lantern bomb: hold to aim (a dotted arc and a ring show where it lands and how far it reaches), let go to
## throw it along that very arc; it bursts in teal spirit-fire, hurting everything in its radius. On a cooldown.
## The target is where the crosshair points, kept between min_range and max_range of the player.

var aiming: bool = false
var _kit: LamplighterKit
var _preview: ArcPreview


func setup(kit: LamplighterKit) -> void:
	name = "LanternBomb"
	_kit = kit


func begin_aim() -> bool:
	if aiming or _kit.busy() or not (_kit.cooldowns["bomb"] as Cooldown).is_ready():
		return false
	aiming = true
	_preview = ArcPreview.new()
	_kit.player.add_child(_preview)
	_preview.setup(_kit.fx.look("bomb"), int(Tuning.number("combat", "bomb", "preview_points")), Tuning.number(
		"combat", "bomb", "radius"))
	_preview.show_arc(current_arc())
	return true


## The arc a throw would take right now (the preview shows exactly this).
func current_arc() -> BombArc:
	var from: Vector3 = _kit.aim.muzzle()
	var target: Vector3 = _kit.aim.point
	var flat := Vector3(target.x - from.x, 0.0, target.z - from.z)
	var reach: float = clampf(flat.length(), Tuning.number("combat", "bomb", "min_range"), Tuning.number("combat",
		"bomb", "max_range"))
	if flat.length() > Hit.TINY:
		target = Vector3(from.x, 0.0, from.z) + flat.normalized() * reach
		target.y = _kit.ground_at(target + Vector3.UP * (from.y - _kit.player.global_position.y))
	return BombArc.toward(from, target, _kit.player.get_world_3d(), [_kit.player.get_rid()])


func _process(_delta: float) -> void:
	if aiming:
		_preview.show_arc(current_arc())
		_kit.aim.engage()


## Throws the bomb along the previewed arc; returns it (null when not aiming).
func release() -> BombShell:
	if not aiming:
		return null
	aiming = false
	var arc: BombArc = current_arc()
	_preview.queue_free()
	var shell := BombShell.new()
	shell.launch(_kit, arc)
	(_kit.cooldowns["bomb"] as Cooldown).start()
	_kit.fx.kit.sfx.cue("bomb_throw", arc.from)
	_kit.aim.engage()
	return shell
