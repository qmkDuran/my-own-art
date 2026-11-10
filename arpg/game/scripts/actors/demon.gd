class_name Demon
extends CharacterBody2D
## A spiritual enemy (Eph 6:12): chases Michael and strikes, or keeps its distance and casts "flaming arrows" (Eph 6:16).
## Struck: flash, knockback, number. Rebuked: flees in fear. Slain: dissolves into shadow and may leave an item.

signal slain(demon: Demon)

const SHADER: Shader = preload("res://shaders/shadow.gdshader")
const FRAME: int = 64
const FPS: float = 8.0
const AGGRO: float = 330.0
const FLASH_TIME: float = 0.1
const DISSOLVE_TIME: float = 0.9
const FRICTION: float = 9.0

var kind: String
var data: Dictionary
var level: int = 1
var rank: String = ""                  # "", "champion" or "hero"
var hp: float
var max_hp: float
var damage: float
var target: Michael
var dead: bool = false

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


static func make(kind_id: String, at: Vector2, lvl: int, rank_id: String, michael: Michael) -> Demon:
	var d := Demon.new()
	d.kind = kind_id
	d.data = GameData.enemies["kinds"][kind_id]
	d.level = lvl
	d.rank = rank_id
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
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = float(data["radius"])
	shape.shape = circle
	shape.position = Vector2(0, -circle.radius * 0.5)
	add_child(shape)
	collision_layer = 2
	collision_mask = 1 | 2
	_sprite = Sprite2D.new()
	_sprite.texture = load(data["sheet"]) as Texture2D
	_sprite.hframes = 4
	_sprite.vframes = 3
	_sprite.centered = false
	_sprite.offset = Vector2(-FRAME / 2.0, -FRAME + 2)
	_mat = ShaderMaterial.new()
	_mat.shader = SHADER
	var rim: Array = data["rim"]
	_mat.set_shader_parameter("edge_color", Color(float(rim[0]), float(rim[1]), float(rim[2])))
	_sprite.material = _mat
	add_child(_sprite)
	if rank != "":
		var t: Array = el["tint"]
		_sprite.modulate = Color(float(t[0]), float(t[1]), float(t[2]))
		var aura := PointLight2D.new()
		aura.texture = LightTex.radial(128 if rank == "champion" else 256)
		aura.color = Color(1.0, 0.35, 0.2)
		aura.energy = 0.7
		aura.position = Vector2(0, -24)
		add_child(aura)
		_name_label(String(el.get("name", el.get("label", ""))))
	_attack_t = randf_range(0.2, float(data["attack_time"]))


func _rank_data() -> Dictionary:
	return GameData.enemies[rank] if rank != "" else {}


func xp_value() -> float:
	return float(data["xp"]) * float(_rank_data().get("xp_mult", 1.0)) * (1.0 + 0.1 * float(level - 1))


func loot_quality() -> float:
	return float(_rank_data().get("loot_quality", 1.0))


func display_name() -> String:
	return String(_rank_data().get("name", data["name"])) if rank == "hero" else String(data["name"])


func _name_label(text: String) -> void:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font_size = 16
	ls.font_color = Color("f57d4a") if rank == "hero" else Color("fbb954")
	ls.outline_size = 4
	ls.outline_color = Color("2e222f")
	l.label_settings = ls
	l.text = text
	l.size = Vector2(120, 16)
	l.position = Vector2(-60, -FRAME - 8)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Overlay.follower(self).add_child(l)


func _physics_process(delta: float) -> void:
	if dead:
		return
	_anim_t += delta
	_attack_t -= delta
	_fear -= delta
	_stun -= delta
	var want := Vector2.ZERO
	var to: Vector2 = target.global_position - global_position
	var dist: float = to.length()
	if _stun > 0.0:
		want = Vector2.ZERO
	elif _fear > 0.0:
		want = -to.normalized() * float(data["speed"]) * 1.2
	elif dist < AGGRO and not target.down:
		want = _hunt(to, dist)
	else:
		if global_position.distance_to(_wander) < 8.0:
			_wander = _home + Vector2(randf_range(-60, 60), randf_range(-40, 40))
		want = (_wander - global_position).normalized() * float(data["speed"]) * 0.35
	_knock = _knock.move_toward(Vector2.ZERO, _knock.length() * FRICTION * delta + 1.0)
	velocity = want + _knock
	move_and_slide()
	_animate(to)


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
		if not dead and global_position.distance_to(target.global_position) < float(data["range"]) + target.REACH_PAD + 10.0:
			target.take_hit(damage, self, false))


func _cast(to: Vector2) -> void:
	_attack_t = float(data["attack_time"])
	_attacking = 0.4
	Audio.sfx("bolt", -14.0, randf_range(0.9, 1.1))
	Bolt.fire(get_parent(), global_position + Vector2(0, -30), to.normalized(), float(data["bolt_speed"]), damage, target)


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
	_sprite.frame = row * 4 + int(_anim_t * FPS) % n
	var face_x: float = to.x if _attacking > 0.0 or _fear <= 0.0 else -to.x
	if absf(velocity.x) > 6.0 and _attacking <= 0.0:
		face_x = velocity.x
	_sprite.flip_h = face_x > 0.0                       # the art faces left


## A hit from Michael. Returns true if it was the killing blow.
func hurt(amount: float, from: Vector2, push: float, crit: bool) -> bool:
	if dead:
		return false
	hp -= amount
	_knock += (global_position - from).normalized() * push * float(data["knockback"])
	_mat.set_shader_parameter("flash", 1.0)
	create_tween().tween_method(func(v: float) -> void: _mat.set_shader_parameter("flash", v), 1.0, 0.0, FLASH_TIME)
	FloatText.spawn(get_parent(), global_position, str(roundi(amount)), Color("f9c22b") if crit else Color.WHITE, crit)
	if hp <= 0.0:
		_die()
		return true
	Audio.sfx("demon_hurt", -16.0, randf_range(0.85, 1.15))
	return false


func fear(seconds: float) -> void:
	_fear = maxf(_fear, seconds)


func stun(seconds: float) -> void:
	_stun = maxf(_stun, seconds)


func _die() -> void:
	dead = true
	remove_from_group("demons")
	collision_layer = 0
	collision_mask = 0
	Audio.sfx("dissolve", -10.0, randf_range(0.85, 1.1))
	var smoke := Fx.shadow_puff(get_parent(), global_position + Vector2(0, -24))
	get_tree().create_timer(1.5).timeout.connect(smoke.queue_free)
	var tw := create_tween()
	tw.tween_method(func(v: float) -> void: _mat.set_shader_parameter("dissolve", v), 0.0, 1.0, DISSOLVE_TIME)
	tw.tween_callback(queue_free)
	slain.emit(self)
