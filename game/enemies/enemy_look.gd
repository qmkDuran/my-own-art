class_name EnemyLook
extends Node3D
## How an enemy shows what it is doing: a cool rim light so it reads against the dark woods (violet and an aura for
## the boss), the elite's moonlit shield bubble (rippling and cracking as it is hit), the glow of a shot being
## charged, the flicker of a swarmer winding up, and the boss's phase-two flare.

const SHIELD_HEIGHT_SHARE: float = 0.5
const CHARGE_FROM: float = 0.15
const WINDUP_SIZE: float = 0.35
const WINDUP_LIFT: float = 0.6

var _enemy: Enemy
var _bubble: Bubble
var _aura: OmniLight3D
var _orb: Node3D


func setup(enemy: Enemy) -> void:
	name = "Look"
	_enemy = enemy
	var look: Dictionary = Tuning.doc("vfx")["combat"]["enemy"]
	var boss: bool = enemy.role == "boss"
	enemy.set_rim.call_deferred(float(look["boss_rim_strength" if boss else "rim_strength"]), Tuning.color(
		look["boss_rim" if boss else "rim"]))
	if boss:
		_add_aura()
	if enemy.max_shield > 0.0:
		_add_shield()


func _add_aura() -> void:
	_aura = OmniLight3D.new()
	_aura.light_color = Tuning.color(_enemy.spec["aura_color"])
	_aura.light_energy = float(_enemy.spec["aura_energy"])
	_aura.omni_range = float(_enemy.spec["aura_range"])
	_aura.position = Vector3(0.0, _enemy.radius * 2.0, _enemy.radius * 2.0)
	add_child(_aura)


func _add_shield() -> void:
	var spec: Dictionary = Tuning.doc("vfx")["combat"]["shield"]
	var height: float = float(Tuning.doc("assets")[_enemy.spec["asset"]]["height"])
	_bubble = Bubble.new()
	add_child(_bubble)
	_bubble.setup(spec, height * SHIELD_HEIGHT_SHARE * float(spec["size"]))
	_bubble.position.y = height * SHIELD_HEIGHT_SHARE


## Where the enemy's shots leave from (just in front of its body).
func muzzle() -> Vector3:
	return _enemy.centre() + _enemy.global_basis.z * _enemy.radius


## A glowing orb grows at the muzzle over the wind-up of a shot.
func charge(seconds: float) -> void:
	var look: Dictionary = Tuning.doc("vfx")["combat"]["enemy"]
	_orb = SoftGlow.make(Tuning.color(look["charge"]), float(look["charge_size"]), float(look["charge_energy"]))
	add_child(_orb)
	_orb.global_position = muzzle()
	_orb.scale = Vector3.ONE * CHARGE_FROM
	var tween: Tween = _orb.create_tween()
	tween.tween_property(_orb, "scale", Vector3.ONE, seconds).set_ease(Tween.EASE_IN)
	tween.tween_callback(_orb.queue_free)


## A swarmer's quick warning flicker above its head.
func windup(seconds: float) -> void:
	var look: Dictionary = Tuning.doc("vfx")["combat"]["enemy"]
	var spark: Node3D = SoftGlow.make(Tuning.color(look["windup"]), WINDUP_SIZE, float(look["charge_energy"]))
	add_child(spark)
	spark.position.y = float(_enemy.spec["hover"]) + _enemy.radius * 2.0 + WINDUP_LIFT
	var tween: Tween = spark.create_tween()
	tween.tween_property(spark, "scale", Vector3.ONE * CHARGE_FROM, seconds)
	tween.tween_callback(spark.queue_free)


func shield_struck(hit: Hit, left_share: float) -> void:
	if _bubble == null:
		return
	_bubble.ripple(hit.point)
	_bubble.set_crack(1.0 - left_share)
	_enemy.roster.cue("shield_hit", hit.point)


func shatter() -> void:
	if _bubble != null:
		_bubble.queue_free()
		_bubble = null
	_enemy.roster.fx.shield_shatter(_enemy)


func phase_two() -> void:
	var look: Dictionary = Tuning.doc("vfx")["combat"]["enemy"]
	if _aura != null:
		create_tween().tween_property(_aura, "light_energy", float(look["phase_aura_energy"]), 1.0)
	_enemy.roster.fx.phase_ring(_enemy)
	_enemy.roster.cue("boss_roar", _enemy.centre())
