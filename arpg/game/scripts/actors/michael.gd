class_name Michael
extends CharacterBody2D
## The archangel Michael (Jude 9; Rev 12:7; Dan 10:13), sent in answer to prayer.
## Moves where he is sent (click-to-move), strikes with the sword in a three-hit combo and dodges. He casts no glow on
## the ground: a light that touches only characters (light mask 2) keeps him and the demons near him readable at night.
## Holds his numbers (Stats), growth (Progression) and the armour of God (Inventory). Skills live in SkillSystem.

signal life_changed
signal struck_down
signal raised

const FRAME: int = 64
const ROWS: Dictionary = {"down": 0, "up": 1, "left": 2, "right": 2}
const WALK_FPS: float = 11.0
const SLASH_FPS: float = 24.0
const HIT_FRAME: int = 4
const REACH_PAD: float = 14.0
const ARRIVE: float = 6.0
const COMBO_WINDOW: float = 0.55
const DOWN_SECONDS: float = 2.5
const CHARACTER_LIGHT: float = 0.9

var stats := Stats.new()
var prog := Progression.new()
var inv := Inventory.new()
var skills: SkillSystem
var life: float = 100.0
var glory: float = 100.0
var down: bool = false
var invulnerable: bool = false
var facing: String = "down"

var _sprite: Sprite2D
var _sheets: Dictionary = {}
var _move_dir: Vector2 = Vector2.ZERO
var _move_to: Vector2 = Vector2.INF
var _slash_t: float = -1.0
var _slash_hit_done: bool = false
var _combo: int = 0
var _combo_t: float = 0.0
var _aim: Vector2 = Vector2.DOWN
var _dash_v: Vector2 = Vector2.ZERO
var _dash_t: float = 0.0
var _dodge_cd: float = 0.0
var _anim_t: float = 0.0
var _step_t: float = 0.0
var _spawn: Vector2
var _cast_t: float = 0.0
var _afterimage_t: float = 0.0


func _ready() -> void:
	add_to_group("michael")
	_spawn = position
	collision_layer = 4
	collision_mask = 1
	var shape := CollisionShape2D.new()
	var c := CapsuleShape2D.new()
	c.radius = 9.0
	c.height = 18.0
	shape.shape = c
	shape.rotation = PI / 2.0
	shape.position = Vector2(0, -6)
	add_child(shape)
	for anim: String in ["idle", "walk", "slash"]:
		_sheets[anim] = load("res://art/michael/%s.png" % anim) as Texture2D
	_sprite = Sprite2D.new()
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME / 2.0, -FRAME + 3)
	_sprite.light_mask = 1 | Demon.CHARACTER_LIGHT_MASK
	add_child(_sprite)
	var readable := PointLight2D.new()
	readable.texture = LightTex.radial(384)
	readable.color = Color(0.85, 0.85, 1.0)
	readable.energy = CHARACTER_LIGHT
	readable.range_item_cull_mask = Demon.CHARACTER_LIGHT_MASK
	readable.position = Vector2(0, -30)
	add_child(readable)
	skills = SkillSystem.new(self)
	add_child(skills)
	prog.changed.connect(refresh_stats)
	inv.changed.connect(refresh_stats)
	refresh_stats()
	life = stats.v("life")
	glory = stats.v("glory")
	_set_anim("idle", 0)


func refresh_stats() -> void:
	var life_frac: float = life / maxf(1.0, stats.v("life"))
	stats.compute(prog.level, inv.equipped_stats(), prog.passive_stats())
	life = clampf(life_frac * stats.v("life"), 1.0, stats.v("life"))
	glory = minf(glory, stats.v("glory"))
	life_changed.emit()


# ------------------------------------------------------------------ commands (player input and the demo bot)
func set_move_dir(v: Vector2) -> void:
	_move_dir = v
	if v != Vector2.ZERO:
		_move_to = Vector2.INF


func move_to(p: Vector2) -> void:
	_move_to = p


func stop() -> void:
	_move_to = Vector2.INF
	_move_dir = Vector2.ZERO


func aim_at(p: Vector2) -> void:
	if _slash_t >= 0.0:
		return                                   # a swing keeps the direction it started with
	var d: Vector2 = p - (global_position + Vector2(0, -28))
	if d.length() > 2.0:
		_aim = d.normalized()


func busy() -> bool:
	return down or _slash_t >= 0.0 or _dash_t > 0.0 or _cast_t > 0.0 or skills.charging()


## The sword (Eph 6:17): three swings, the last wider and heavier.
func strike(p: Vector2) -> void:
	if down or _slash_t >= 0.0 or _dash_t > 0.0 or skills.charging():
		return
	aim_at(p)
	_move_to = Vector2.INF
	_combo = (_combo + 1) % 3 if _combo_t > 0.0 else 0
	_slash_t = 0.0
	_slash_hit_done = false
	facing = _dir_name(_aim)
	Audio.sfx("swing", -10.0, randf_range(0.95, 1.1) + 0.06 * _combo)


## Dash (Space): a quick move toward where he walks (or aims), untouchable while it lasts; afterimages and a smoke
## trail mark it.
func dodge() -> void:
	if down or _dodge_cd > 0.0 or skills.charging():
		return
	var d: Vector2 = _velocity_dir()
	var dd: Dictionary = GameData.skill("dash")
	_dash_t = float(dd["time"])
	_dash_v = d * float(dd["distance"]) / float(dd["time"])
	_dodge_cd = dash_cooldown()
	_slash_t = -1.0
	_cast_t = 0.0
	_afterimage_t = 0.0
	invulnerable = true
	facing = _dir_name(d)
	Audio.sfx("dash", -6.0)
	Fx.shadow_puff(get_parent(), global_position + Vector2(0, -16))


func _velocity_dir() -> Vector2:
	if _move_dir != Vector2.ZERO:
		return _move_dir.normalized()
	if _move_to != Vector2.INF and _move_to.distance_to(global_position) > ARRIVE:
		return (_move_to - global_position).normalized()
	return _aim


func dash_cooldown() -> float:
	return float(GameData.skill("dash")["cooldown"]) / (1.0 + stats.v("dodge_pct") / 100.0)


func dodge_ready() -> float:
	return maxf(0.0, _dodge_cd)


## A brief stand after a skill (cast speed shortens it).
func cast_lock() -> void:
	_cast_t = stats.cast_time()


func _afterimage() -> void:
	var ghost := Sprite2D.new()
	ghost.texture = _sprite.texture
	ghost.hframes = _sprite.hframes
	ghost.vframes = _sprite.vframes
	ghost.frame = _sprite.frame
	ghost.flip_h = _sprite.flip_h
	ghost.centered = false
	ghost.offset = _sprite.offset
	ghost.position = global_position
	ghost.modulate = Color(0.6, 0.75, 1.0, 0.55)
	ghost.z_index = -1
	get_parent().add_child(ghost)
	var tw := ghost.create_tween()
	tw.tween_property(ghost, "modulate:a", 0.0, 0.3)
	tw.tween_callback(ghost.queue_free)


# ------------------------------------------------------------------ frame
func _physics_process(delta: float) -> void:
	_anim_t += delta
	_combo_t -= delta
	_dodge_cd -= delta
	_regen(delta)
	if down:
		velocity = Vector2.ZERO
		return
	if _dash_t > 0.0:
		_dash_t -= delta
		_afterimage_t -= delta
		if _afterimage_t <= 0.0:
			_afterimage_t = 0.035
			_afterimage()
			Fx.shadow_puff(get_parent(), global_position + Vector2(0, -8)).amount = 4
		velocity = _dash_v
		move_and_slide()
		if _dash_t <= 0.0:
			invulnerable = false
		_set_anim("walk", int(_anim_t * WALK_FPS * 2.0) % 8)
		return
	if skills.charging():
		move_and_slide()
		return
	if _cast_t > 0.0:
		_cast_t -= delta
		velocity = Vector2.ZERO
		_set_anim("slash", 2)
		return
	if _slash_t >= 0.0:
		_update_slash(delta)
		velocity = Vector2.ZERO
		return
	var dir: Vector2 = _move_dir
	if dir == Vector2.ZERO and _move_to != Vector2.INF:
		var to: Vector2 = _move_to - global_position
		if to.length() < ARRIVE:
			_move_to = Vector2.INF
		else:
			dir = to.normalized()
	velocity = dir * stats.move_speed()
	move_and_slide()
	if dir != Vector2.ZERO:
		facing = _dir_name(dir)
		_set_anim("walk", int(_anim_t * WALK_FPS * stats.move_speed() / Stats.SPEED) % 8)
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.36
			Audio.sfx("step", -16.0, randf_range(0.8, 1.1))
	else:
		_set_anim("idle", int(_anim_t * 1.5) % 2)


func _update_slash(delta: float) -> void:
	var speed: float = SLASH_FPS * (1.0 + stats.v("attack_pct") / 100.0)
	_slash_t += delta * speed
	var f: int = int(_slash_t)
	if f >= HIT_FRAME and not _slash_hit_done:
		_slash_hit_done = true
		skills.strike_hit(_aim, _combo)
	if f >= 9:
		_slash_t = -1.0
		_combo_t = COMBO_WINDOW
		return
	_set_anim("slash", f)


func _regen(delta: float) -> void:
	if down:
		return
	life = minf(stats.v("life"), life + stats.v("life_regen") * delta)
	glory = minf(stats.v("glory"), glory + (float(GameData.skills["glory_regen"]) + stats.v("glory_regen")) * delta)


func _set_anim(anim: String, frame: int) -> void:
	var tex: Texture2D = _sheets[anim]
	if _sprite.texture != tex:
		_sprite.texture = tex
		_sprite.hframes = int(tex.get_width() / float(FRAME))
		_sprite.vframes = 3
	_sprite.frame = ROWS[facing] * _sprite.hframes + mini(frame, _sprite.hframes - 1)
	_sprite.flip_h = facing == "right"


static func _dir_name(v: Vector2) -> String:
	if absf(v.x) > absf(v.y) * 1.1:
		return "right" if v.x > 0.0 else "left"
	return "down" if v.y > 0.0 else "up"


func aim() -> Vector2:
	return _aim


func face_toward(v: Vector2) -> void:
	facing = _dir_name(v)


# ------------------------------------------------------------------ being struck
## A blow (physical), a bolt (shadow) or fire. Blows can be blocked: a block takes off the block amount.
func take_hit(raw: float, _source: Node2D, ranged: bool, kind: String = "physical") -> void:
	if down or invulnerable:
		return
	var dmg: float = stats.mitigate(raw, kind)
	if not ranged and kind == "physical" and randf() * 100.0 < stats.v("block"):
		dmg = maxf(0.0, dmg - stats.v("block_amount"))
		FloatText.spawn(get_parent(), global_position + Vector2(0, -12), "Block", Color("8fd3ff"))
		Audio.sfx("shield", -14.0, 1.3)
	if skills.shield_on():
		dmg *= 1.0 - skills.shield_reduce()
	life -= dmg
	FloatText.spawn(get_parent(), global_position, str(roundi(dmg)), Color("e83b3b"))
	_sprite.modulate = Color(1.0, 0.55, 0.55)
	create_tween().tween_property(_sprite, "modulate", Color.WHITE, 0.2)
	life_changed.emit()
	if life <= 0.0:
		_struck_down()


func shield_active() -> bool:
	return skills.shield_on()


func shield_radius() -> float:
	return float(GameData.skill("shield")["radius"])


func shield_blocked(at: Vector2) -> void:
	Audio.sfx("shield", -10.0, randf_range(0.95, 1.1))
	skills.on_quench(at)
	SkillFx.ring(get_parent(), at, 16.0, Color("8fd3ff"), 0.25)


## An angel is not slain: struck down, he is raised again where he was sent ("Peace! Be strong now", Dan 10:19).
func _struck_down() -> void:
	down = true
	life = 0.0
	_sprite.modulate = Color(0.5, 0.5, 0.7, 0.6)
	struck_down.emit()
	get_tree().create_timer(DOWN_SECONDS).timeout.connect(func() -> void:
		position = _spawn
		life = stats.v("life")
		glory = stats.v("glory")
		down = false
		_sprite.modulate = Color.WHITE
		raised.emit()
		life_changed.emit())
