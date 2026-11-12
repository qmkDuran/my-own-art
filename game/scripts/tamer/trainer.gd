class_name Trainer
extends Node2D
## You, the trainer. You are never hurt (as in the shows): wild creatures ignore you. You walk where you left-click
## (grid path), roll (Space) to reposition, sync creatures with the Sync Lens, use items and call swaps. In battle
## you keep back on your own (BattleMode). Not a Combatant: nothing can target you.

const TEAM_LAYER: int = 4
const FPS: float = 8.0
const COLS: int = 8
const MOVING: float = 10.0
const ROLL_SPIN: float = TAU

var heading: Vector2 = Vector2.DOWN     ## last walking direction (the partner walks behind it)
var attack_target: Combatant            ## a foe your creature should go for on its own (Mark)
var sprite: Sprite2D
var body: CharacterBody2D
var T: Dictionary
var _goal: Vector2 = Vector2.INF
var _path := PackedVector2Array()
var _repath: float = 0.0
var _roll_vel: Vector2 = Vector2.ZERO
var _roll_t: float = 0.0
var _roll_cd: float = 0.0
var _anim_t: float = 0.0


func _ready() -> void:
	T = TamerData.rule("trainer")
	add_to_group(TreeFade.FOCUS)
	body = CharacterBody2D.new()
	body.collision_layer = TEAM_LAYER
	body.collision_mask = Combatant.WORLD_MASK
	body.motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = float(T["radius"])
	cs.shape = shape
	body.add_child(cs)
	add_child(body)
	body.top_level = true
	body.global_position = global_position
	add_child(PropSprite.shadow(22.0))
	var meta: Dictionary = TamerData.sprites["trainer"]
	sprite = Sprite2D.new()
	sprite.texture = PropSprite.tex("res://art/creatures/trainer.png")
	sprite.hframes = COLS
	sprite.vframes = 2
	sprite.offset = Vector2(0, -float(meta["frame"][1]) / 2.0 + (float(meta["frame"][1]) - float(meta["anchor"][1])))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/creature.gdshader")
	mat.set_shader_parameter("outline_color", Pal.c(String(TamerData.rule("control.outline"))))
	sprite.material = mat
	add_child(sprite)


func hit_radius() -> float:
	return float(T["radius"]) + 4.0


func set_highlight(on: bool) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("outline", 1.0 if on else 0.0)


func walk_to(p: Vector2) -> void:
	_goal = p
	_path.clear()


func stop() -> void:
	_goal = Vector2.INF
	_path.clear()


func walking() -> bool:
	return _goal != Vector2.INF


func rolling() -> bool:
	return _roll_t > 0.0


## Space: a quick roll toward the cursor (a fast reposition; you are never in danger).
func roll(toward: Vector2) -> bool:
	if _roll_cd > 0.0:
		return false
	var d: Dictionary = T["dodge"]
	var dir: Vector2 = (toward - global_position).normalized() if toward.distance_to(global_position) > 1.0 else heading
	_roll_vel = dir * float(d["distance"]) / float(d["time"])
	_roll_t = float(d["time"])
	_roll_cd = float(d["cooldown"])
	stop()
	Audio.sfx("dash", -8.0)
	Fx.burst(TamerGame.current.fx_layer, global_position + Vector2(0, -4), 10, Vector2(30, 90), 0.35,
		[Pal.c("bone"), Pal.c("pale"), Pal.c("mist", 0.0)], -dir, 50.0, Vector2(1.5, 2.5), false)
	var tw := create_tween()
	tw.tween_property(sprite, "rotation", ROLL_SPIN * signf(dir.x if absf(dir.x) > 0.1 else 1.0), float(d["time"]))
	tw.tween_callback(func() -> void: sprite.rotation = 0.0)
	return true


## Moved at once (the retreat to camp after a white-out).
func place(at: Vector2) -> void:
	stop()
	global_position = at
	body.global_position = at


func _physics_process(delta: float) -> void:
	_roll_cd = maxf(0.0, _roll_cd - delta)
	var want: Vector2 = Vector2.ZERO
	if _roll_t > 0.0:
		_roll_t -= delta
		want = _roll_vel
	elif _goal != Vector2.INF:
		want = _steer(delta) * float(T["speed"])
		if want == Vector2.ZERO:
			_goal = Vector2.INF
	if want.length() > MOVING:
		heading = want.normalized()
	body.global_position = global_position             # tests and retreats may move the trainer directly
	body.velocity = want
	body.move_and_slide()
	global_position = body.global_position
	_animate(delta, want)


func _steer(delta: float) -> Vector2:
	var nav: Nav = TamerGame.current.nav
	if nav.line_free(global_position, _goal):
		return (_goal - global_position).normalized() if global_position.distance_to(_goal) > Combatant.ARRIVE else Vector2.ZERO
	_repath -= delta
	if _path.is_empty() or _repath <= 0.0:
		_repath = Combatant.REPATH
		_path = nav.path(global_position, _goal)
	while not _path.is_empty() and global_position.distance_to(_path[0]) < Combatant.ARRIVE:
		_path.remove_at(0)
	return Vector2.ZERO if _path.is_empty() else (_path[0] - global_position).normalized()


func _animate(delta: float, want: Vector2) -> void:
	_anim_t += delta * FPS
	var row: int = 1 if want.length() > MOVING and _roll_t <= 0.0 else 0
	sprite.frame = row * COLS + int(_anim_t) % COLS
	if absf(want.x) > MOVING:
		sprite.flip_h = want.x < 0.0
