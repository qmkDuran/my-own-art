class_name Trainer
extends Combatant
## You, the trainer: you walk where you click (grid path), roll out of danger (Space, with a moment of
## untouchability), use items, and point your creature at foes. You can be hit; a ward from your creature soaks hits.
## If you fall you wake at camp, gently. Life comes back slowly out of a fight.

signal fell
signal rose
signal hurt

const TEAM_LAYER: int = 4
const FPS: float = 8.0
const COLS: int = 8
const MOVING: float = 10.0
const QUIET_AFTER: float = 4.0          ## seconds since the last hit before life starts coming back
const ROLL_SPIN: float = TAU

var life: float
var max_life: float
var heading: Vector2 = Vector2.DOWN     ## last walking direction (the partner walks behind it)
var attack_target: Combatant            ## the foe you clicked: your creature goes for it
var sprite: Sprite2D
var down: bool = false
var guard_left: float = 0.0
var guard_t: float = 0.0
var _goal: Vector2 = Vector2.INF
var _roll_vel: Vector2 = Vector2.ZERO
var _roll_t: float = 0.0
var _roll_cd: float = 0.0
var _quiet: float = 0.0
var _anim_t: float = 0.0
var _flash_t: float = 0.0
var T: Dictionary


func _ready() -> void:
	T = TamerData.rule("trainer")
	side = SIDE_TEAM
	add_to_group(SIDE_TEAM)
	add_to_group(TreeFade.FOCUS)
	collision_layer = TEAM_LAYER
	collision_mask = WORLD_MASK
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	max_life = float(T["life"])
	life = max_life
	var cs := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = float(T["radius"])
	cs.shape = shape
	add_child(cs)
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


func alive() -> bool:
	return not down


func max_life_value() -> float:
	return max_life


func set_highlight(on: bool) -> void:
	(sprite.material as ShaderMaterial).set_shader_parameter("outline", 1.0 if on else 0.0)


func walk_to(p: Vector2) -> void:
	_goal = p
	clear_path()


func stop() -> void:
	_goal = Vector2.INF
	clear_path()


func walking() -> bool:
	return _goal != Vector2.INF


func rolling() -> bool:
	return _roll_t > 0.0


## Space: a quick roll toward the cursor; you can't be hit while rolling.
func roll(toward: Vector2) -> bool:
	if _roll_cd > 0.0 or down:
		return false
	var d: Dictionary = T["dodge"]
	var dir: Vector2 = (toward - global_position).normalized() if toward.distance_to(global_position) > 1.0 else heading
	_roll_vel = dir * float(d["distance"]) / float(d["time"])
	_roll_t = float(d["time"])
	_roll_cd = float(d["cooldown"])
	iframe_t = float(d["iframes"])
	stop()
	Audio.sfx("dash", -8.0)
	Fx.burst(TamerGame.current.fx_layer, global_position + Vector2(0, -4), 10, Vector2(30, 90), 0.35,
		[Pal.c("bone"), Pal.c("pale"), Pal.c("mist", 0.0)], -dir, 50.0, Vector2(1.5, 2.5), false)
	var tw := create_tween()
	tw.tween_property(sprite, "rotation", ROLL_SPIN * signf(dir.x if absf(dir.x) > 0.1 else 1.0), float(d["time"]))
	tw.tween_callback(func() -> void: sprite.rotation = 0.0)
	return true


func add_guard(amount: float, time: float) -> void:
	guard_left = maxf(guard_left, amount)
	guard_t = time


func heal(amount: float) -> void:
	if not down:
		life = minf(max_life, life + amount)


func receive_hit(dmg: float, dir: Vector2, knock_px: float, _stun: float, _attacker: Combatant) -> void:
	if untouchable():
		return
	if guard_t > 0.0:
		var soak: float = minf(guard_left, dmg)
		guard_left -= soak
		dmg -= soak
	life -= dmg
	hurt.emit()
	_quiet = QUIET_AFTER
	_flash_t = 0.06
	iframe_t = float(T["hurt_iframes"])
	shove(dir, knock_px)
	CameraRig.shake(0.2)
	if life <= 0.0:
		_fall()


func _fall() -> void:
	down = true
	life = 0.0
	stop()
	attack_target = null
	sprite.rotation = PI * 0.5
	Audio.sfx("hurt", -2.0, 0.8)
	fell.emit()


## Back on your feet at `at` (the camp), whole again.
func rise_at(at: Vector2) -> void:
	down = false
	life = max_life
	global_position = at
	sprite.rotation = 0.0
	iframe_t = 1.0
	rose.emit()


func _physics_process(delta: float) -> void:
	_tick(delta)
	var want: Vector2 = Vector2.ZERO
	if _roll_t > 0.0:
		_roll_t -= delta
		want = _roll_vel
	elif not down and _goal != Vector2.INF:
		want = steer_to(_goal, delta) * float(T["speed"])
		if want == Vector2.ZERO:
			_goal = Vector2.INF
	if want.length() > MOVING:
		heading = want.normalized()
	velocity = want + knock_velocity(delta)
	move_and_slide()
	_animate(delta, want)


func _tick(delta: float) -> void:
	_roll_cd = maxf(0.0, _roll_cd - delta)
	iframe_t = maxf(0.0, iframe_t - delta)
	guard_t = maxf(0.0, guard_t - delta)
	_quiet -= delta
	if _quiet <= 0.0 and not down:
		life = minf(max_life, life + float(T["regen_out_of_fight"]) * delta)


func _animate(delta: float, want: Vector2) -> void:
	_anim_t += delta * FPS
	var row: int = 1 if want.length() > MOVING and _roll_t <= 0.0 else 0
	sprite.frame = row * COLS + int(_anim_t) % COLS
	if absf(want.x) > MOVING:
		sprite.flip_h = want.x < 0.0
	_flash_t = maxf(0.0, _flash_t - delta)
	sprite.modulate = Color(2.0, 1.2, 1.2) if _flash_t > 0.0 else Color.WHITE
	sprite.self_modulate.a = 0.6 if iframe_t > 0.0 and _roll_t <= 0.0 and int(_anim_t * 2.0) % 2 == 0 else 1.0
