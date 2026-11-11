class_name Enemy
extends CharacterBody2D
## A creature of the Dusk. Data-driven (enemies.json): life, damage and speed scale with level and rank (normal,
## magic, rare, boss); modifiers (Hasted, Glass-Skinned, Light-Drinker, Shard-Burst) change numbers and are shown
## in its name. It sleeps until the Lamplighter comes near, then runs its behaviour (EnemyBrain). Shrouded =
## outside every light: its body darkens to a silhouette with glowing eyes, and it hits harder.

signal died(e: Enemy)

const HIT_FLASH: float = 0.035          ## about two frames
const HIT_FLASH_AMOUNT: float = 0.45
const DEATH_TIME: float = 0.28
const KNOCK_DECAY: float = 9.0
const SEPARATION: float = 0.9
const PERSONAL_SPACE: float = 1.3       # bodies keep this much more than touching apart, so a crowd never reads as one blob
const SHROUD_CHECK: float = 0.15
const BURN_TIME: float = 2.0
const BURN_TICK: float = 0.5
const BAR_W: float = 28.0
const MOVE_ANIM_SPEED: float = 8.0
const SHROUD_TINT := Color(0.72, 0.7, 0.86)            ## outside the light: cooler, never a silhouette
const AVOID_NEIGHBOURS: float = 90.0     ## RVO: how far an enemy looks for others to steer around
const AVOID_HORIZON: float = 0.5
const BOSS_SHROUD_TINT := Color(0.85, 0.82, 0.95)       ## a boss is always readable
const BOSS_LIGHT_RANGE: float = 150.0
const BOSS_LIGHT_ENERGY: float = 0.75

var kind: String
var data: Dictionary
var home: Vector2
var rank: String = "normal"
var mods: Array = []
var level: int = 1
var life: float
var max_life: float
var damage: float
var speed: float
var radius: float
var dead: bool = false
var awake: bool = false
var shrouded: bool = true
var stun_t: float = 0.0
var exposed_pct: float = 0.0          ## from a thrown lantern's Beacon
var _exposed_t: float = 0.0
var brain: EnemyBrain
var sprite: Sprite2D
var _flash_t: float = 0.0
var _knock: Vector2 = Vector2.ZERO
var _avoid: NavigationAgent2D
var _safe: Vector2 = Vector2.ZERO
var _burn_dps: float = 0.0
var _burn_t: float = 0.0
var _burn_tick: float = 0.0
var _shroud_t: float = 0.0
var _anim_t: float = 0.0
var _row: int = 0
var _shown_shroud: float = 1.0


## The Tuesday loop: back where it stood that morning, whole again, asleep until you come near.
func rewind() -> void:
	life = max_life
	global_position = home
	awake = false
	_knock = Vector2.ZERO
	Fx.burst(Game.current.fx_layer, global_position, 8, Vector2(20, 60), 0.4, [Pal.c("bone"), Pal.c("pale", 0.0)])


func setup(k: String, r: String, m: Array, lvl: int) -> void:
	kind = k
	data = GameData.enemy(k)
	rank = r
	mods = m
	level = lvl
	var E: Dictionary = GameData.enemies
	var rk: Dictionary = E["ranks"][rank]
	max_life = float(data["life"]) * (1.0 + float(E["life_per_level"]) * (lvl - 1)) * float(rk["life"]) * _mod_mult("life")
	life = max_life
	damage = float(data["damage"]) * (1.0 + float(E["damage_per_level"]) * (lvl - 1)) * float(rk["damage"])
	speed = float(data["speed"]) * _mod_mult("speed")
	radius = float(data["radius"]) * float(rk["scale"])


func _mod_mult(key: String) -> float:
	var m: float = 1.0
	for id: String in mods:
		m *= float(GameData.enemies["mods"][id].get(key, 1.0))
	return m


func _ready() -> void:
	home = position
	add_to_group("enemies")
	collision_layer = 2
	collision_mask = 1 | 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var cs := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = radius
	cs.shape = c
	add_child(cs)
	_make_sprite()
	_make_avoidance()
	brain = EnemyBrain.make(self)
	if rank != "boss":
		var tag := EnemyTag.new()
		tag.enemy = self
		Overlay.follower(self).add_child(tag)


func _make_sprite() -> void:
	var meta: Dictionary = GameData.sprites["actors"][data["sprite"]]
	var fw: Vector2 = Vector2(float(meta["frame"][0]), float(meta["frame"][1]))
	add_child(PropSprite.shadow(radius * 2.4))
	sprite = Sprite2D.new()
	sprite.texture = PropSprite.tex("res://art/actors/%s.png" % data["sprite"])
	sprite.hframes = 4
	sprite.vframes = 3
	sprite.offset = Vector2(0, -fw.y / 2.0 + (fw.y - float(meta["anchor"][1])))
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://shaders/hit_flash.gdshader")
	sprite.material = mat
	sprite.scale = Vector2.ONE * float(GameData.enemies["ranks"][rank]["scale"])
	add_child(sprite)
	PropSprite.add_glow(sprite, "res://art/actors/%s_glow.png" % data["sprite"])
	if rank == "boss":                                      # its own dim light: the whole silhouette always reads
		var l := PointLight2D.new()
		l.texture = LightTex.soft(128)
		l.texture_scale = BOSS_LIGHT_RANGE / 64.0
		l.color = Pal.c("pale")
		l.energy = BOSS_LIGHT_ENERGY
		l.position = Vector2(0, -body_height() * 0.6)
		add_child(l)


func body_height() -> float:
	return float(GameData.sprites["actors"][data["sprite"]]["frame"][1]) * 0.6 * sprite.scale.y


func display_name() -> String:
	var parts: Array[String] = []
	for id: String in mods:
		parts.append(String(GameData.enemies["mods"][id]["name"]))
	parts.append(String(data["name"]))
	return " ".join(parts)


func damage_taken_mult() -> float:
	return _mod_mult("damage_taken") * (1.0 + exposed_pct / 100.0)


func light_drain() -> float:
	var d: float = float(data.get("light_drain", 0.0))
	for id: String in mods:
		d += float(GameData.enemies["mods"][id].get("light_drain", 0.0))
	return d


func attack_speed() -> float:
	return _mod_mult("attack_speed")


# ------------------------------------------------------------------ being hit
func take_damage(dmg: float, crit: bool, dir: Vector2, opts: Dictionary) -> void:
	life -= dmg
	if not bool(opts.get("dot", false)):                   # burns and ground fires don't flash
		_flash_t = HIT_FLASH
	wake()
	_knock += dir.normalized() * float(opts.get("knockback", 30.0 if crit else 12.0)) * (0.3 if rank == "boss" else 1.0) * 6.0
	stun_t = maxf(stun_t, float(opts.get("stun", 0.0)) * (0.3 if rank == "boss" else 1.0))
	if life <= 0.0:
		_die()


func expose(pct: float, seconds: float) -> void:
	exposed_pct = pct
	_exposed_t = seconds


func burning() -> bool:
	return _burn_t > 0.0


## Tether: dragged toward a point (a strong shove that decays like knockback).
func pull_toward(at: Vector2, strength: float) -> void:
	_knock = (at - global_position).normalized() * minf(strength, global_position.distance_to(at) * KNOCK_DECAY)


func ignite(total: float) -> void:
	_burn_dps = maxf(_burn_dps, total / BURN_TIME)
	_burn_t = BURN_TIME


func wake() -> void:
	awake = true


func _die() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	remove_from_group("enemies")
	var size: float = sprite.scale.x * (2.2 if rank == "boss" else 1.0) * (1.4 if kind == "hound" else 1.0)
	Fx.death_burst(Game.current.fx_layer, global_position + Vector2(0, -body_height() * 0.4), size, kind != "gloam")
	Fx.flash(Game.current.fx_layer, global_position, 70.0 * size, Pal.c("violet_lt"), 0.9, 0.3)
	Audio.sfx("die_glass" if kind != "gloam" else "die_dark", -6.0, randf_range(0.9, 1.1))
	CameraRig.shake(Combat.KILL_SHAKE * size)
	if mods.has("shard_burst"):
		brain.shard_ring(int(GameData.enemies["mods"]["shard_burst"]["death_shards"]))
	if data.has("death_burst"):
		_death_burst(data["death_burst"])
	died.emit(self)
	var tw := create_tween()
	tw.set_parallel()
	tw.tween_property(sprite, "scale", Vector2(sprite.scale.x * 1.4, sprite.scale.y * 0.2), DEATH_TIME)
	tw.tween_property(self, "modulate:a", 0.0, DEATH_TIME)
	tw.chain().tween_callback(queue_free)


## Husks burst when they fall: a circle warns, then the embers inside it burn (bursts landing together count
## once, so clearing a crowd of them is not a death sentence).
func _death_burst(db: Dictionary) -> void:
	var at: Vector2 = global_position
	var r: float = float(db["radius"])
	var dmg: float = damage * float(db["damage"])
	var fx: Node2D = Game.current.fx_layer
	Telegraph.circle(fx, at, r, float(db["delay"])).fired.connect(func() -> void:
		Fx.burst(fx, at, 24, Vector2(60, 180), 0.5, [Pal.c("gold"), Pal.c("flame"), Pal.c("ember", 0.0)])
		Fx.flash(fx, at, r * 2.0, Pal.c("flame"), 1.4, 0.3)
		Audio.sfx("flare", -10.0, 1.4)
		var p: Player = Game.current.player
		if p.global_position.distance_to(at) < r + p.radius and p.burst_ready():
			Combat.hit_player(null, dmg, "blunt", at))


## Navigation avoidance (RVO): packs flow around each other and around the Lamplighter instead of stacking up.
func _make_avoidance() -> void:
	_avoid = NavigationAgent2D.new()
	_avoid.avoidance_enabled = true
	_avoid.radius = radius * PERSONAL_SPACE
	_avoid.neighbor_distance = AVOID_NEIGHBOURS
	_avoid.time_horizon_agents = AVOID_HORIZON
	_avoid.max_speed = speed * 3.0
	_avoid.velocity_computed.connect(func(v: Vector2) -> void: _safe = v)
	add_child(_avoid)


# ------------------------------------------------------------------ frame
func _physics_process(delta: float) -> void:
	if dead:
		return
	_status(delta)
	var want: Vector2 = Vector2.ZERO
	if stun_t <= 0.0:
		want = brain.think(delta)
	_avoid.velocity = want                                  # RVO steers the wish around the pack and the Lamplighter
	velocity = (_safe if want != Vector2.ZERO else Vector2.ZERO) + _knock + _separation() * speed * SEPARATION
	_knock = _knock.lerp(Vector2.ZERO, minf(1.0, KNOCK_DECAY * delta))
	move_and_slide()
	_animate(delta, want)


func _status(delta: float) -> void:
	stun_t = maxf(0.0, stun_t - delta)
	_exposed_t -= delta
	if _exposed_t <= 0.0:
		exposed_pct = 0.0
	_flash_t = maxf(0.0, _flash_t - delta / maxf(Engine.time_scale, 0.01))   # real time: hit-stop must not stretch it
	(sprite.material as ShaderMaterial).set_shader_parameter("flash", HIT_FLASH_AMOUNT if _flash_t > 0.0 else 0.0)
	_shroud_t -= delta
	if _shroud_t <= 0.0:
		_shroud_t = SHROUD_CHECK
		shrouded = not LightField.lit(get_tree(), global_position) or (Game.current.player.skills.skill("eclipse") as Eclipse).active()
	_shown_shroud = move_toward(_shown_shroud, 1.0 if shrouded else 0.0, delta * 4.0)
	var lit := Color.WHITE * ZoneView.actor_gain()                  # as bright as the zone around it
	sprite.self_modulate = lit.lerp(lit * (SHROUD_TINT if rank != "boss" else BOSS_SHROUD_TINT), _shown_shroud)
	if _burn_t > 0.0:
		_burn_t -= delta
		_burn_tick -= delta
		if _burn_tick <= 0.0:
			_burn_tick = BURN_TICK
			Combat.hit_enemy(self, _burn_dps * BURN_TICK, {"dot": true, "kind": "spell", "more": 1.0 / Game.current.player.stats.increased("spell")})
			Fx.burst(Game.current.fx_layer, global_position + Vector2(0, -body_height() * 0.5), 4, Vector2(10, 40), 0.4,
				[Pal.c("gold"), Pal.c("flame"), Pal.c("ember", 0.0)], Vector2.UP, 30.0)


func _separation() -> Vector2:
	var push: Vector2 = Vector2.ZERO
	for n: Node in get_tree().get_nodes_in_group("enemies"):
		var o := n as Enemy
		if o == self or not o.awake:
			continue
		var d: Vector2 = global_position - o.global_position
		var min_d: float = (radius + o.radius) * PERSONAL_SPACE
		if d.length() < min_d and d.length() > 0.01:
			push += d.normalized() * (1.0 - d.length() / min_d)
	return push + _space_from(Game.current.player.global_position, Game.current.player.radius)


## Keep off the Lamplighter's body too: melee reach is longer than this, so bites still land.
func _space_from(at: Vector2, other_radius: float) -> Vector2:
	var d: Vector2 = global_position - at
	var min_d: float = (radius + other_radius) * PERSONAL_SPACE
	if d.length() >= min_d or d.length() <= 0.01:
		return Vector2.ZERO
	return d.normalized() * (1.0 - d.length() / min_d)


func _animate(delta: float, want: Vector2) -> void:
	var row: int = brain.anim_row(want)
	if row != _row:
		_row = row
		_anim_t = 0.0
	_anim_t += delta * float(data["fps"]) * (1.0 if want.length() < 1.0 else want.length() / maxf(speed, 1.0)) * (MOVE_ANIM_SPEED / 8.0)
	var n: int = 3 if row == 2 else 4
	var f: int = mini(int(_anim_t), n - 1) if row == 2 else int(_anim_t) % n
	var target: Player = Game.current.player
	sprite.flip_h = target.global_position.x < global_position.x if kind == "hound" else false
	PropSprite.set_frame(sprite, row * 4 + f)
	if data.has("hover"):                                     # fliers float above their shadow
		sprite.position.y = -float(data["hover"]) + sin(_anim_t * 0.8) * 2.0
