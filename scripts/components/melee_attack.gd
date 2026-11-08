class_name MeleeAttack
extends Node
## A close-range attack, like Emberoo's jab.
##
## Tracks whether an attack is in progress and spawns the impact effect
## at the moment the fist lands. An attack can be cancelled (e.g. by a dodge);
## a cancelled attack before the hit lands never hits. Damage will hook in here later.

## Fired once per attack when the punch damaged at least one target (e.g. so Heat can build).
signal hits_landed(hit_count: int)

## Seconds from pressing attack to the fist landing (end of the wind-up frame).
@export var hit_delay: float = 0.12
## Seconds the whole attack takes, start to recovery (the jab animation's length).
@export var attack_duration: float = 0.44
## How far in front of the creature the hit lands, in pixels.
@export var reach: float = 20.0
## Height of the fist above the creature's feet, in pixels (negative is up).
@export var fist_height: float = -7.0
## Effect shown where the hit lands.
@export var impact_effect: PackedScene
## Damage dealt to each target the hit lands on.
@export var damage: int = 1
## How close to the punch line a target's feet must be to get hit, in pixels.
@export var hit_radius: float = 9.0
## How far the attacker lunges forward during the wind-up, in pixels.
@export var lunge_distance: float = 6.0
## Group whose members this attack can hurt (each needs a child node named "Health").
@export var target_group: String = "enemies"
## Animations used in turn for back-to-back attacks, e.g. left fist then right fist.
@export var combo_animations: Array[String] = ["jab", "jab2"]

## Seconds trimmed off the end of every attack by upgrades (e.g. Quick Hands).
## Only the recovery is cut, so the fist still lands on the same animation frame.
var recovery_cut: float = 0.0

var is_attacking: bool = false
## The animation for the attack in progress (or the last one).
var current_animation: String = ""

var _combo_step: int = 0
var _attack_direction: Vector2 = Vector2.ZERO
var _time_attacking: float = 0.0
var _has_landed_hit: bool = false

@onready var attacker: Node2D = get_parent()


func _physics_process(delta: float) -> void:
	if is_attacking:
		_advance_attack(delta)


func is_ready() -> bool:
	return not is_attacking


func start(attack_direction: Vector2) -> void:
	is_attacking = true
	_attack_direction = attack_direction
	_time_attacking = 0.0
	_has_landed_hit = false
	_advance_combo()


## The attacker's speed while lunging forward during the wind-up; zero otherwise.
func lunge_velocity() -> Vector2:
	if not is_attacking or _time_attacking >= hit_delay:
		return Vector2.ZERO
	return _attack_direction * (lunge_distance / hit_delay)


## Stops the attack right away. Safe to call when not attacking.
func cancel() -> void:
	is_attacking = false


func _advance_attack(delta: float) -> void:
	_time_attacking += delta

	if not _has_landed_hit and _time_attacking >= hit_delay:
		_has_landed_hit = true
		_spawn_impact(_attack_direction)
		_damage_targets_in_reach(_attack_direction)

	if _time_attacking >= attack_length():
		is_attacking = false


## How long the attack takes after upgrades; never ends before the hit lands.
func attack_length() -> float:
	return maxf(hit_delay, attack_duration - recovery_cut)


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


## Hits everything along the punch, from the attacker's body out to full reach,
## so targets slightly closer or further than the fist still get hit.
func _damage_targets_in_reach(attack_direction: Vector2) -> void:
	var punch_start := attacker.global_position
	var punch_end := attacker.global_position + attack_direction * reach
	var hit_count := 0
	for target: Node2D in get_tree().get_nodes_in_group(target_group):
		var closest := Geometry2D.get_closest_point_to_segment(target.global_position, punch_start, punch_end)
		if target.global_position.distance_to(closest) > hit_radius:
			continue
		var target_health: Health = target.get_node_or_null("Health")
		if target_health != null:
			target_health.take_damage(damage, attacker.global_position)
			hit_count += 1
	if hit_count > 0:
		hits_landed.emit(hit_count)


func _hit_position(attack_direction: Vector2) -> Vector2:
	var fist_origin := attacker.global_position + Vector2(0, fist_height)
	return fist_origin + attack_direction * reach
