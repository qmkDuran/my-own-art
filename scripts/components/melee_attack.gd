class_name MeleeAttack
extends Node
## A close-range attack, like Emberoo's jab.
##
## Tracks whether an attack is in progress and spawns the impact effect
## at the moment the fist lands. Damage will hook in here later.

## Seconds from pressing attack to the fist landing (end of the wind-up frame).
@export var hit_delay: float = 0.12
## Seconds the whole attack takes, start to recovery (the jab animation's length).
@export var attack_duration: float = 0.44
## How far in front of the creature the hit lands, in pixels.
@export var reach: float = 12.0
## Height of the fist above the creature's feet, in pixels (negative is up).
@export var fist_height: float = -7.0
## Effect shown where the hit lands.
@export var impact_effect: PackedScene
## Animations used in turn for back-to-back attacks, e.g. left fist then right fist.
@export var combo_animations: Array[String] = ["jab", "jab2"]

var is_attacking: bool = false
## The animation for the attack in progress (or the last one).
var current_animation: String = ""

var _combo_step: int = 0

@onready var attacker: Node2D = get_parent()


func is_ready() -> bool:
	return not is_attacking


func start(attack_direction: Vector2) -> void:
	is_attacking = true
	_advance_combo()

	await get_tree().create_timer(hit_delay).timeout
	_spawn_impact(attack_direction)

	await get_tree().create_timer(attack_duration - hit_delay).timeout
	is_attacking = false


func _advance_combo() -> void:
	current_animation = combo_animations[_combo_step]
	_combo_step = (_combo_step + 1) % combo_animations.size()


func _spawn_impact(attack_direction: Vector2) -> void:
	if impact_effect == null:
		return

	var impact: Node2D = impact_effect.instantiate()
	# Added to the world, not the attacker, so the effect stays where the hit landed.
	attacker.get_parent().add_child(impact)
	impact.global_position = _hit_position(attack_direction)
	impact.rotation = attack_direction.angle()


func _hit_position(attack_direction: Vector2) -> Vector2:
	var fist_origin := attacker.global_position + Vector2(0, fist_height)
	return fist_origin + attack_direction * reach
