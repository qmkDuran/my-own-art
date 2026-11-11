class_name Player
extends CharacterBody2D
## The Lamplighter: walks where you click (grid path, pulled tight), stands to attack or cast toward the cursor,
## dashes (Wickstep), drinks tonics, carries the lantern's Light. Holds his build (Progression), bag (Inventory)
## and the numbers derived from both (Stats). Front-facing sprite; attacks aim in any direction via effects.

signal life_changed
signal died_and_rose

const POSES: Dictionary = {"idle": 0, "walk": 1, "strike": 2, "cast": 3, "hurt": 4}
const FRAMES: Dictionary = {"idle": 4, "walk": 6, "strike": 4, "cast": 3, "hurt": 1}
const FPS: Dictionary = {"idle": 5.0, "walk": 10.0, "strike": 14.0, "cast": 10.0, "hurt": 8.0}
const ARRIVE: float = 6.0
const LIGHT_OFFSET := Vector2(10, -6)
const LANTERN_OFFSET := Vector2(20, -50)
const HURT_TIME: float = 0.18
const HIT_FLASH: float = 0.035
const HURT_SHAKE: float = 0.3
const DASH_GHOSTS: int = 4
const INVULN_AFTER_RISE: float = 2.0
const PUSH_DECAY: float = 6.0
const BURST_WINDOW: float = 0.5
const WICK_BONE_SHARE: float = 0.25
const HEARTBEAT_COOLDOWN: float = 60.0
const HEARTBEAT_GRACE: float = 2.0

var stats := Stats.new()
var prog := Progression.new()
var inv := Inventory.new()
var light: LanternLight
var skills: SkillSystem
var sprite: Sprite2D
var radius: float
var life: float
var oil: float
var tonics: int
var dead: bool = false
var aim: Vector2 = Vector2.DOWN
var busy_t: float = 0.0               ## attacking / casting: no walking
var respawn_at: Vector2
var _path := PackedVector2Array()
var _pose: String = "idle"
var _pose_t: float = 0.0
var _pose_lock: float = 0.0
var _flash_t: float = 0.0
var _dash_t: float = 0.0
var _dash_cd: float = 0.0
var _dash_dir: Vector2
var _invuln: float = 0.0
var _tonic_t: float = 0.0
var _tonic_heal: float = 0.0
var _slow: float = 0.0
var _slow_t: float = 0.0
var _push: Vector2 = Vector2.ZERO
var _last_burst: float = -100.0
var _heartbeat_t: float = 0.0


func _ready() -> void:
	add_to_group("player")
	collision_layer = 4
	collision_mask = 1 | 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	radius = float(GameData.player["radius"])
	_make_body()
	light = LanternLight.new()
	light.stats = stats
	light.position = LIGHT_OFFSET
	add_child(light)
	skills = SkillSystem.new()
	skills.player = self
	add_child(skills)
	prog.changed.connect(refresh_stats)
	inv.changed.connect(refresh_stats)
	_starting_gear()
	refresh_stats()
	life = stats.max_life()
	oil = stats.max_oil()
	tonics = max_tonics()
	respawn_at = global_position


func _make_body() -> void:
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	add_child(cs)
	add_child(PropSprite.shadow(30.0))
	sprite = Sprite2D.new()
	sprite.texture = PropSprite.tex("res://art/actors/lamplighter.png")
	sprite.hframes = 6
	sprite.vframes = 5
	sprite.offset = Vector2(0, -32 + 3)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/hit_flash.gdshader")
	mat.set_shader_parameter("flash_color", Pal.c("rose"))
	sprite.material = mat
	add_child(sprite)
	PropSprite.add_glow(sprite, "res://art/actors/lamplighter_glow.png")


## The order's issue: a plain hook staff, a long coat and a hand lantern (worn from the start).
func _starting_gear() -> void:
	for id: String in GameData.player["starting_gear"]:
		var base: Dictionary = LootGen.base_by_id(id)
		var it: Dictionary = LootGen.make_from_base(base, 1, "normal")
		inv.equipped[inv.target_slot(it)] = it


func refresh_stats() -> void:
	stats.rebuild(prog, inv)
	life = minf(life, stats.max_life())
	oil = minf(oil, stats.max_oil())
	life_changed.emit()


func max_tonics() -> int:
	return int(GameData.player["tonic"]["charges"]) + int(stats.v("tonic_charges"))


func untouchable() -> bool:
	return dead or _dash_t > 0.0 or _invuln > 0.0


## Where the lantern hangs (effects start here).
func lantern_pos() -> Vector2:
	return global_position + Vector2(LANTERN_OFFSET.x * (-1.0 if sprite.flip_h else 1.0), LANTERN_OFFSET.y)


# ------------------------------------------------------------------ commands
func walk_to(p: Vector2) -> void:
	if dead:
		return
	_path = Game.current.nav.path(global_position, p)


func stop() -> void:
	_path.clear()


func walking() -> bool:
	return not _path.is_empty()


func face(p: Vector2) -> void:
	var d: Vector2 = p - global_position
	if d.length() > 1.0:
		aim = d.normalized()
		sprite.flip_h = aim.x < -0.2


## Hold still for an attack or cast: the pose plays, walking stops.
func act(pose: String, seconds: float) -> void:
	busy_t = seconds
	_pose_lock = seconds
	_set_pose(pose)
	stop()


func dash(toward: Vector2) -> bool:
	if dead or _dash_cd > 0.0 or busy_t > 0.0:
		return false
	var D: Dictionary = GameData.player["dash"]
	_dash_dir = (toward - global_position).normalized()
	if _dash_dir == Vector2.ZERO:
		_dash_dir = aim
	_dash_t = float(D["time"])
	_dash_cd = float(D["cooldown"]) / (1.0 + stats.v("dash_cd_pct") / 100.0)
	stop()
	Audio.sfx("dash", -6.0)
	_dash_ghosts()
	skills.on_dash(global_position, _dash_dir)
	return true


func dash_cooldown() -> Vector2:
	var full: float = float(GameData.player["dash"]["cooldown"]) / (1.0 + stats.v("dash_cd_pct") / 100.0)
	return Vector2(_dash_cd, full)


func drink_tonic() -> bool:
	if dead or tonics <= 0 or life >= stats.max_life():
		return false
	tonics -= 1
	var T: Dictionary = GameData.player["tonic"]
	_tonic_t = float(T["duration"])
	_tonic_heal = stats.max_life() * float(T["heal_fraction"]) / _tonic_t
	Audio.sfx("tonic", -6.0)
	Fx.halo(Game.current.fx_layer, global_position + Vector2(0, -24), 40.0, Pal.c("rose", 0.6), 0.5)
	return true


func refill_tonics() -> void:
	tonics = max_tonics()


# ------------------------------------------------------------------ being hit
func take_hit(dmg: float, from: Vector2, drain: float) -> void:
	if stats.has_special("wick_bone") and oil > 0.0:          # Wick and Bone: a quarter is paid in Oil
		var paid: float = minf(oil, dmg * WICK_BONE_SHARE)
		oil -= paid
		dmg -= paid
	if dmg >= life and stats.has_special("seventh_heartbeat") and _heartbeat_t <= 0.0:   # The Seventh Heartbeat
		_heartbeat_t = HEARTBEAT_COOLDOWN
		dmg = life - 1.0
		_invuln = HEARTBEAT_GRACE
		Fx.halo(Game.current.fx_layer, global_position + Vector2(0, -24), 60.0, Pal.c("rose", 0.8), 0.5)
	life = maxf(0.0, life - dmg)
	light.on_hit(dmg / stats.max_life(), drain)
	_flash_t = HIT_FLASH
	if _pose_lock <= 0.0:
		_set_pose("hurt")
		_pose_lock = HURT_TIME
	CameraRig.shake(HURT_SHAKE * clampf(dmg / stats.max_life() * 6.0, 0.3, 1.0))
	Audio.sfx("hurt", -6.0, randf_range(0.95, 1.05))
	Fx.burst(Game.current.fx_layer, global_position + Vector2(0, -26), 8, Vector2(40, 120), 0.35,
		[Pal.c("rose"), Pal.c("blood"), Pal.c("blood", 0.0)], (global_position - from).normalized(), 60.0)
	life_changed.emit()
	if life <= 0.0:
		_fall()


func _fall() -> void:
	dead = true
	stop()
	Game.current.hud.notice("The light gutters... you wake by the last lit waylamp")
	get_tree().create_timer(1.6, false).timeout.connect(_rise)


func _rise() -> void:
	dead = false
	global_position = respawn_at
	life = stats.max_life() * float(GameData.player["respawn_life_fraction"])
	oil = stats.max_oil()
	light.value = float(GameData.light["start"])
	refill_tonics()
	_invuln = INVULN_AFTER_RISE
	died_and_rose.emit()
	life_changed.emit()


## Bursts landing at the same moment hurt once: true (and the window starts) if this one may land.
func burst_ready() -> bool:
	var now: float = Time.get_ticks_msec() / 1000.0
	if now - _last_burst < BURST_WINDOW:
		return false
	_last_burst = now
	return true


## Silk and the like: move slower for a while (the strongest slow wins).
func slow(fraction: float, seconds: float) -> void:
	_slow = maxf(_slow if _slow_t > 0.0 else 0.0, fraction)
	_slow_t = maxf(_slow_t, seconds)


## A shove (a wing gust): slides the Lamplighter, decaying quickly.
func push(v: Vector2) -> void:
	_push += v


func gain_life(v: float) -> void:
	life = minf(stats.max_life(), life + v)


# ------------------------------------------------------------------ frame
func _physics_process(delta: float) -> void:
	_timers(delta)
	if dead:
		velocity = Vector2.ZERO
		return
	if _dash_t > 0.0:
		var D: Dictionary = GameData.player["dash"]
		velocity = _dash_dir * float(D["distance"]) / float(D["time"])
	elif busy_t > 0.0:
		velocity = Vector2.ZERO
	else:
		velocity = _follow_path()
	velocity += _push
	_push = _push.lerp(Vector2.ZERO, minf(1.0, PUSH_DECAY * delta))
	move_and_slide()
	_animate(delta)


func _timers(delta: float) -> void:
	busy_t = maxf(0.0, busy_t - delta)
	_pose_lock = maxf(0.0, _pose_lock - delta)
	_dash_t = maxf(0.0, _dash_t - delta)
	_dash_cd = maxf(0.0, _dash_cd - delta)
	_invuln = maxf(0.0, _invuln - delta)
	_flash_t = maxf(0.0, _flash_t - delta / maxf(Engine.time_scale, 0.01))   # real time: hit-stop must not stretch it
	_slow_t = maxf(0.0, _slow_t - delta)
	_heartbeat_t = maxf(0.0, _heartbeat_t - delta)
	(sprite.material as ShaderMaterial).set_shader_parameter("flash", 0.18 if _flash_t > 0.0 else 0.0)
	sprite.modulate.a = 0.5 if _invuln > 0.0 and int(_invuln * 10.0) % 2 == 0 else 1.0
	if dead:
		return
	life = minf(stats.max_life(), life + stats.life_regen() * delta)
	oil = minf(stats.max_oil(), oil + stats.oil_regen() * delta)
	if _tonic_t > 0.0:
		_tonic_t -= delta
		life = minf(stats.max_life(), life + _tonic_heal * delta)


func _follow_path() -> Vector2:
	while not _path.is_empty() and global_position.distance_to(_path[0]) < ARRIVE:
		_path.remove_at(0)
	if _path.is_empty():
		return Vector2.ZERO
	var dir: Vector2 = (_path[0] - global_position).normalized()
	if absf(dir.x) > 0.2:
		sprite.flip_h = dir.x < 0.0
	return dir * stats.move_speed() * skills.move_mult() * (1.0 - (_slow if _slow_t > 0.0 else 0.0))


func _animate(delta: float) -> void:
	if _pose_lock <= 0.0:
		_set_pose("walk" if velocity.length() > 5.0 else "idle")
	_pose_t += delta * float(FPS[_pose])
	var n: int = int(FRAMES[_pose])
	var f: int = mini(int(_pose_t), n - 1) if _pose_lock > 0.0 else int(_pose_t) % n
	PropSprite.set_frame(sprite, int(POSES[_pose]) * 6 + f)


func _set_pose(p: String) -> void:
	if p != _pose:
		_pose = p
		_pose_t = 0.0


func _dash_ghosts() -> void:
	for k: int in DASH_GHOSTS:
		get_tree().create_timer(float(GameData.player["dash"]["time"]) * k / DASH_GHOSTS, false).timeout.connect(func() -> void:
			var g := Sprite2D.new()
			g.texture = sprite.texture
			g.hframes = sprite.hframes
			g.vframes = sprite.vframes
			g.frame = sprite.frame
			g.flip_h = sprite.flip_h
			g.offset = sprite.offset
			g.global_position = global_position
			g.modulate = Pal.c("amber", 0.5)
			g.material = Fx.glow_material()
			Game.current.fx_layer.add_child(g)
			var tw := g.create_tween()
			tw.tween_property(g, "modulate:a", 0.0, 0.3)
			tw.tween_callback(g.queue_free))
