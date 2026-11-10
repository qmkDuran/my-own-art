class_name Demon
extends CharacterBody2D
## A spiritual enemy (Eph 6:12): chases Michael and strikes, or keeps away and casts "flaming arrows" (Eph 6:16).
## Kinds and extras come from data (explode, charge, summon, blink); champions carry modifiers (hasted, ember-burst,
## shielded); one hero is much stronger. Struck: flash, sparks, knockback, number. Rebuked: flees. Slain: bursts into
## shadow and may leave an item. Demons arrive (and may leave) as streaks of black smoke (SmokeArrival).

signal slain(demon: Demon)
signal summon(kind: String, at: Vector2, count: int)

const SHADER: Shader = preload("res://shaders/shadow.gdshader")
const FRAME: int = 64
const FPS: float = 8.0
const AGGRO: float = 360.0
const SLEEP: float = 1300.0             # beyond this from Michael the demon does nothing (performance)
const FLASH_TIME: float = 0.1
const DISSOLVE_TIME: float = 0.7
const FRICTION: float = 9.0
const CHAIN_RADIUS: float = 70.0
const CHARACTER_LIGHT_MASK: int = 2     # lit by Michael's light on characters (not the ground)

var kind: String
var data: Dictionary
var level: int = 1
var rank: String = ""                   # "", "champion" or "hero"
var mods: Array = []                    # champion modifier ids
var hp: float
var max_hp: float
var barrier: float = 0.0
var damage: float
var target: Michael
var dead: bool = false
var arriving: bool = false

var _sprite: Sprite2D
var _mat: ShaderMaterial
var _knock: Vector2 = Vector2.ZERO
var _attack_t: float = 0.0
var _attacking: float = 0.0
var _fear: float = 0.0
var _stun: float = 0.0
var _anim_t: float = 0.0
var _home: Vector2
var _wander: Vector2
var _speed_k: float = 1.0
var _attack_k: float = 1.0
var _special_t: float = 0.0
var _armed: float = -1.0
var _charge_v: Vector2 = Vector2.ZERO
var _charge_t: float = 0.0
var _wind_t: float = 0.0
var _exploded: bool = false
var _empowered: float = 0.0
var _breath_t: float = 0.0
var _breath_cd: float = 2.0
var _breath_tick: float = 0.0


static func make(kind_id: String, at: Vector2, lvl: int, rank_id: String, michael: Michael, mod_ids: Array = []) -> Demon:
	var d := Demon.new()
	d.kind = kind_id
	d.data = GameData.enemies["kinds"][kind_id]
	d.level = lvl
	d.rank = rank_id
	d.mods = mod_ids
	d.position = at
	d._home = at
	d._wander = at
	d.target = michael
	return d


func _ready() -> void:
	add_to_group("demons")
	var scale_k: float = 1.0 + float(GameData.enemies["level_scale"]) * float(level - 1)
	var el: Dictionary = _rank_data()
	max_hp = float(data["hp"]) * scale_k * float(el.get("hp_mult", 1.0))
	hp = max_hp
	damage = float(data["damage"]) * scale_k * float(el.get("damage_mult", 1.0))
	for m: String in mods:
		var md: Dictionary = GameData.enemies["champion"]["mods"][m]
		_speed_k *= float(md.get("speed", 1.0))
		_attack_k *= float(md.get("attack", 1.0))
		barrier += max_hp * float(md.get("barrier", 0.0))
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = float(data["radius"])
	shape.shape = circle
	shape.position = Vector2(0, -circle.radius * 0.5)
	add_child(shape)
	collision_layer = 2
	collision_mask = 0 if data.get("flyer", false) else 1 | 2      # flyers pass over walls and wrecks
	_sprite = Sprite2D.new()
	_sprite.texture = load(data["sheet"]) as Texture2D
	_sprite.hframes = 4
	_sprite.vframes = 3
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME / 2.0, -FRAME + 2)
	_sprite.scale = Vector2.ONE * float(data.get("scale", 1.0))
	_sprite.light_mask = 1 | CHARACTER_LIGHT_MASK
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	_mat.set_shader_parameter("edge_color", rim_color())
	_sprite.material = _mat
	add_child(_sprite)
	if rank != "":
		var t: Array = el["tint"]
		_sprite.modulate = Color(float(t[0]), float(t[1]), float(t[2]))
		var aura := PointLight2D.new()
		aura.texture = LightTex.radial(128 if rank == "champion" else 256)
		aura.color = Color(1.0, 0.35, 0.2) if mods.is_empty() else Color(String(GameData.enemies["champion"]["mods"][mods[0]]["color"]))
		aura.energy = 0.6
		aura.position = Vector2(0, -24)
		add_child(aura)
		_name_label(display_name())
	_attack_t = randf_range(0.2, float(data["attack_time"]))
	_special_t = randf_range(1.0, 3.0)


func rim_color() -> Color:
	var rim: Array = data["rim"]
	return Color(float(rim[0]), float(rim[1]), float(rim[2]))


func _rank_data() -> Dictionary:
	return GameData.enemies[rank] if rank != "" else {}


func xp_value() -> float:
	return float(data["xp"]) * float(_rank_data().get("xp_mult", 1.0)) * (1.0 + 0.1 * float(level - 1))


func loot_quality() -> float:
	return float(_rank_data().get("loot_quality", 1.0))


func display_name() -> String:
	if rank == "hero":
		return String(GameData.enemies["hero"]["name"])
	var parts: PackedStringArray = []
	for m: String in mods:
		parts.append(String(GameData.enemies["champion"]["mods"][m]["label"]))
	parts.append(String(data["name"]))
	return " ".join(parts)


func _name_label(text: String) -> void:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 16
	ls.font_color = Color("f57d4a") if rank == "hero" else Color("fbb954")
	ls.outline_size = 4
	ls.outline_color = Color("2e222f")
	l.label_settings = ls
	l.text = text
	l.size = Vector2(160, 16)
	l.position = Vector2(-80, -FRAME * float(data.get("scale", 1.0)) - 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Overlay.follower(self).add_child(l)


# ------------------------------------------------------------------ behaviour
func _physics_process(delta: float) -> void:
	if dead or arriving:
		return
	var to: Vector2 = target.global_position - global_position
	var dist: float = to.length()
	if dist > SLEEP:
		return
	_anim_t += delta
	_attack_t -= delta * (1.0 / _attack_k)
	_fear -= delta
	_stun -= delta
	_special_t -= delta
	_empowered -= delta
	_breath_cd -= delta
	if _breath_t > 0.0:
		_breathe(delta, to)
	var want := Vector2.ZERO
	if _armed >= 0.0:
		_armed -= delta
		_sprite.modulate = Color(1.6, 0.8, 0.5) if int(_armed * 12.0) % 2 == 0 else Color.WHITE
		if _armed < 0.0:
			_explode(data["explode"])
			return
	elif _charge_t > 0.0:
		_charge_t -= delta
		want = _charge_v
		if global_position.distance_to(target.global_position) < float(data["radius"]) + 18.0:
			target.take_hit(float(data["charge"]["damage"]) * damage / float(data["damage"]), self, false)
			_charge_t = 0.0
	elif _wind_t > 0.0:
		_wind_t -= delta
		if _wind_t <= 0.0:
			_charge_t = float(data["charge"]["time"])
			_charge_v = to.normalized() * float(data["charge"]["speed"])
			Audio.sfx("dash", -8.0, 0.7)
	elif _stun > 0.0:
		want = Vector2.ZERO
	elif _fear > 0.0:
		want = -to.normalized() * float(data["speed"]) * 1.2
	elif dist < AGGRO and not target.down:
		_specials(to, dist)
		want = _hunt(to, dist)
	else:
		if global_position.distance_to(_wander) < 8.0:
			_wander = _home + Vector2(randf_range(-60, 60), randf_range(-40, 40))
		want = (_wander - global_position).normalized() * float(data["speed"]) * 0.35
	_knock = _knock.move_toward(Vector2.ZERO, _knock.length() * FRICTION * delta + 1.0)
	var boost: float = 1.25 if _empowered > 0.0 else 1.0
	velocity = want * (_speed_k * boost if _charge_t <= 0.0 else 1.0) + _knock
	move_and_slide()
	_animate(to)


## Rev 16:14: spirits performing signs: the impure spirit strengthens the demons around it for a while.
func empower(seconds: float) -> void:
	_empowered = maxf(_empowered, seconds)
	_sprite.modulate = Color(1.0, 1.25, 0.8)
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		if is_instance_valid(self) and not dead and rank == "":
			_sprite.modulate = Color.WHITE)


func _empowered_damage() -> float:
	return damage * (1.3 if _empowered > 0.0 else 1.0)


## Rev 9:17-18: fire, smoke and sulfur out of its mouth: a cone in front of the head.
func _breathe(delta: float, to: Vector2) -> void:
	_breath_t -= delta
	_attacking = 0.2
	_breath_tick -= delta
	if _breath_tick > 0.0:
		return
	_breath_tick = 0.2
	var b: Dictionary = data["breath"]
	var dir: Vector2 = Vector2(1, 0) if _sprite.flip_h else Vector2(-1, 0)
	var mouth: Vector2 = global_position + Vector2(dir.x * 34.0, -60.0)
	Fx.flame(get_parent(), mouth, dir)
	var rel: Vector2 = target.global_position + Vector2(0, -20) - mouth
	if rel.length() < float(b["range"]) and absf(rad_to_deg(dir.angle_to(rel))) < float(b["angle"]) / 2.0:
		target.take_hit(float(b["dps"]) * 0.2 * (1.0 + 0.16 * float(level - 1)), self, true)


func _specials(to: Vector2, dist: float) -> void:
	if data.has("breath") and _breath_cd <= 0.0 and dist < float(data["breath"]["range"]) + 20.0:
		_breath_cd = float(data["breath"]["every"])
		_breath_t = float(data["breath"]["time"])
		Audio.sfx("burst", -6.0, 0.5)
	if data.has("empower") and _special_t <= 0.0:
		var em: Dictionary = data["empower"]
		_special_t = float(em["every"])
		_attacking = 0.5
		Impact.blast(get_parent(), global_position, float(em["radius"]), Color("92a984"), 0.4)
		for n: Node in get_tree().get_nodes_in_group("demons"):
			if n != self and (n as Demon).global_position.distance_to(global_position) < float(em["radius"]):
				(n as Demon).empower(float(em["seconds"]))
		return
	if data.has("explode") and _armed < 0.0 and dist < float(data["explode"]["trigger"]):
		_armed = float(data["explode"]["arm"])
		Audio.sfx("bolt", -10.0, 1.4)
	if _special_t > 0.0:
		return
	if data.has("charge") and dist > float(data["charge"]["min"]) and dist < float(data["charge"]["max"]):
		_special_t = float(data["charge"]["cooldown"])
		_wind_t = float(data["charge"]["wind"])
		_attacking = _wind_t
	elif data.has("summon"):
		_special_t = float(data["summon"]["every"])
		_attacking = 0.5
		summon.emit(String(data["summon"]["kind"]), global_position, int(data["summon"]["count"]))
	elif data.has("blink") and dist > 60.0:
		_special_t = float(data["blink"]["every"])
		var behind: Vector2 = target.global_position - target.aim() * 46.0 + Vector2(randf_range(-20, 20), randf_range(-10, 10))
		Fx.shadow_puff(get_parent(), global_position + Vector2(0, -24))
		global_position = behind
		Fx.shadow_puff(get_parent(), global_position + Vector2(0, -24))
		Audio.sfx("dash", -12.0, 1.4)


func _hunt(to: Vector2, dist: float) -> Vector2:
	var speed: float = float(data["speed"])
	if data["behaviour"] == "ranged":
		if dist < float(data["range"]) and _attack_t <= 0.0:
			_cast(to)
		if dist < float(data["keep_away"]):
			return -to.normalized() * speed * 0.8
		return to.normalized() * speed if dist > float(data["range"]) * 0.9 else Vector2.ZERO
	if dist < float(data["range"]) + target.REACH_PAD:
		if _attack_t <= 0.0:
			_strike()
		return Vector2.ZERO
	return to.normalized() * speed


func _strike() -> void:
	_attack_t = float(data["attack_time"])
	_attacking = 0.35
	get_tree().create_timer(0.18).timeout.connect(func() -> void:
		if dead:
			return
		if data.has("slam"):
			Impact.blast(get_parent(), global_position, float(data["slam"]["radius"]), Color("9babb2"), 0.6)
			Audio.sfx("impact_heavy", -8.0, 1.2)
			if global_position.distance_to(target.global_position) < float(data["slam"]["radius"]):
				target.take_hit(damage, self, false)
		elif global_position.distance_to(target.global_position) < float(data["range"]) + target.REACH_PAD + 10.0:
			target.take_hit(_empowered_damage(), self, false))


func _cast(to: Vector2) -> void:
	_attack_t = float(data["attack_time"])
	_attacking = 0.4
	Audio.sfx("bolt", -14.0, randf_range(0.9, 1.1))
	Bolt.fire(get_parent(), global_position + Vector2(0, -30), to.normalized(), float(data["bolt_speed"]), _empowered_damage(), target)


func _animate(to: Vector2) -> void:
	_attacking -= get_physics_process_delta_time()
	var row: int = 0
	var n: int = 2
	if _attacking > 0.0:
		row = 2
		n = 3
	elif velocity.length() > 10.0:
		row = 1
		n = 4
	_sprite.frame = row * 4 + int(_anim_t * FPS * (2.0 if _charge_t > 0.0 else 1.0)) % n
	var face_x: float = to.x if _attacking > 0.0 or _fear <= 0.0 else -to.x
	if absf(velocity.x) > 6.0 and _attacking <= 0.0:
		face_x = velocity.x
	_sprite.flip_h = face_x > 0.0                       # the art faces left


# ------------------------------------------------------------------ struck, feared, slain
## A hit from Michael. Returns true if it was the killing blow.
func hurt(amount: float, from: Vector2, push: float, crit: bool) -> bool:
	if dead or arriving:
		return false
	var taken: float = amount
	if barrier > 0.0:
		var absorbed: float = minf(barrier, amount)
		barrier -= absorbed
		taken -= absorbed
		SkillFx.ring(get_parent(), global_position + Vector2(0, -24), 22.0, Color("c7dcd0"), 0.15)
	hp -= taken
	_knock += (global_position - from).normalized() * push * float(data["knockback"])
	_mat.set_shader_parameter("flash", 1.0)
	create_tween().tween_method(func(v: float) -> void: _mat.set_shader_parameter("flash", v), 1.0, 0.0, FLASH_TIME)
	FloatText.spawn(get_parent(), global_position, str(roundi(amount)), Color("f9c22b") if crit else Color.WHITE, crit)
	Impact.hit(get_parent(), global_position + Vector2(0, -22 * float(data.get("scale", 1.0))), crit)
	if hp <= 0.0:
		_die()
		return true
	Audio.sfx("demon_hurt", -16.0, randf_range(0.85, 1.15))
	return false


func fear(seconds: float) -> void:
	_fear = maxf(_fear, seconds)


func stun(seconds: float) -> void:
	_stun = maxf(_stun, seconds)
	_charge_t = 0.0
	_wind_t = 0.0


func push(v: Vector2) -> void:
	_knock += v


func _explode(ex: Dictionary) -> void:
	if _exploded:
		return
	_exploded = true
	var r: float = float(ex["radius"])
	Impact.explosion(get_parent(), global_position + Vector2(0, -10), r)
	Audio.sfx("burst", -4.0, 0.8)
	if global_position.distance_to(target.global_position) < r:
		target.take_hit(float(ex["damage"]) * (1.0 + 0.16 * float(level - 1)), self, false)
	if not dead:
		hp = 0.0
		_die()


func _die() -> void:
	dead = true
	remove_from_group("demons")
	collision_layer = 0
	collision_mask = 0
	var big: bool = rank != "" or float(data.get("scale", 1.0)) > 1.0 or float(data["hp"]) >= 100.0
	Impact.death(get_parent(), global_position + Vector2(0, -20), rim_color(), big)
	Audio.sfx("burst", -9.0, randf_range(0.85, 1.15))
	Audio.sfx("dissolve", -12.0, randf_range(0.85, 1.1))
	for n: Node in get_tree().get_nodes_in_group("demons"):        # the burst jolts its neighbours: packs fall in a ripple
		var o := n as Demon
		if o.global_position.distance_to(global_position) < CHAIN_RADIUS:
			o.push((o.global_position - global_position).normalized() * 120.0)
	if mods.has("emberburst"):
		_explode(GameData.enemies["champion"]["mods"]["emberburst"]["explode"])
	elif data.has("explode"):
		_explode(data["explode"])
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("dissolve", v), 0.0, 1.0, DISSOLVE_TIME)
	tw.tween_callback(queue_free)
	slain.emit(self)


## Show/hide while arriving or leaving as smoke.
func set_present(on: bool) -> void:
	arriving = not on
	visible = on
	if on:
		add_to_group("demons")
	else:
		remove_from_group("demons")
