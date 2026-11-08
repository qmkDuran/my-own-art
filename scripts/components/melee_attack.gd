class_name MeleeAttack
extends Node
## A close-range attack, like Emberoo's jab.
##
## Tracks whether an attack is in progress. At the moment the fist lands it spawns the
## impact effect and damages every target along the punch. An attack can be cancelled
## (e.g. by a dodge); a cancelled attack before the hit lands never hits.
## With a `finisher`, the attack after the last of `combo_animations` is the finisher
## (e.g. jab, jab, Spinning Hook): same buffering and cancel rules, its own timing and hit.
## Until the finisher is learned (SpinningHook.is_unlocked) the chain is just the jabs.
## Where the combo is lives in a ComboChain: only its time window ever resets it.
## Damage goes through CritRoll, so the attacker's critical hits apply to every punch.

## Fired once per attack (finisher included) when it damaged at least one target (e.g. so Heat can build).
signal hits_landed(hit_count: int)
## Fired for each target a jab or the finisher hit, after its damage (e.g. so Searing Jab can burn it).
signal target_hit(target_health: Health)

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
## How close to the punch line a target's body centre must be to get hit, in pixels.
## Generous on purpose, so a jab that looks like it connects does (like Path of Exile).
@export var hit_radius: float = 12.0
## Height of a target's body centre above its feet, in pixels (negative is up).
@export var target_body_height: float = -6.0
## How far the attacker lunges forward during the wind-up, in pixels.
## The lunge starts fast and eases to a stop as the fist lands, so it reads as a snap forward.
@export var lunge_distance: float = 6.0
## Seconds after the hit lands before moving may cut the rest of the attack short
## (an "animation cancel"), so the extended fist is still seen for a moment.
## Dodging can cancel at any time; holding attack never cancels, it chains.
@export var move_cancel_delay: float = 0.07
## Seconds without attacking after which the combo starts again from the first fist.
## Generous, so the chain carries across kills and short walks between enemies.
@export var combo_reset_time: float = 2.0
## Group whose members this attack can hurt (each needs a child node named "Health").
@export var target_group: String = "enemies"
## Animations used in turn for back-to-back attacks, e.g. left fist then right fist.
@export var combo_animations: Array[String] = ["jab", "jab2"]
## Ends the combo after the jabs (e.g. the Spinning Hook), then it starts over. Optional.
@export var finisher: SpinningHook

## Seconds trimmed off the end of every attack by upgrades (e.g. Quick Hands).
## Only the recovery is cut, so the fist still lands on the same animation frame.
var recovery_cut: float = 0.0

var is_attacking: bool = false
## The animation for the attack in progress (or the last one).
var current_animation: String = ""

## Where the combo is; read it (e.g. ComboPips) but let this attack drive it.
var combo: ComboChain

var _attack_direction: Vector2 = Vector2.ZERO
var _time_attacking: float = 0.0
var _has_landed_hit: bool = false
var _is_finisher: bool = false

@onready var attacker: Node2D = get_parent()


func _ready() -> void:
	combo = ComboChain.new(_chain_length(), combo_reset_time)


func _physics_process(delta: float) -> void:
	if is_attacking:
		_advance_attack(delta)
	else:
		combo.wait(delta)


## Whether the combo ends in the finisher right now (it exists and is learned).
func has_finisher() -> bool:
	return finisher != null and finisher.is_unlocked()


func is_ready() -> bool:
	return not is_attacking


func start(attack_direction: Vector2) -> void:
	is_attacking = true
	_attack_direction = attack_direction
	_time_attacking = 0.0
	_has_landed_hit = false
	_advance_combo()


## The attacker's speed while lunging forward during the wind-up; zero otherwise.
## Starts at twice the average speed and slows evenly to zero as the fist lands,
## which still covers exactly `lunge_distance`. The finisher stays rooted.
func lunge_velocity() -> Vector2:
	if not is_attacking or _is_finisher or _time_attacking >= hit_delay:
		return Vector2.ZERO
	var wind_up_left := 1.0 - _time_attacking / hit_delay
	return _attack_direction * (2.0 * lunge_distance / hit_delay) * wind_up_left


## Whether moving may cut the rest of this attack short: only after the hit has landed
## and the extended fist has been shown for `move_cancel_delay` seconds.
func can_cancel_by_moving() -> bool:
	return is_attacking and _has_landed_hit and _time_attacking >= _hit_delay() + move_cancel_delay


## Stops the attack right away. Safe to call when not attacking.
## Never drops the combo: an attack cut short before its hit is retried on the next press.
func cancel() -> void:
	if is_attacking and not _has_landed_hit:
		combo.note_cancelled_before_landing()
	is_attacking = false


func _advance_attack(delta: float) -> void:
	_time_attacking += delta

	if not _has_landed_hit and _time_attacking >= _hit_delay():
		_has_landed_hit = true
		_land_hit()

	if _time_attacking >= attack_length():
		is_attacking = false


## How long the attack takes after upgrades; never ends before the hit lands.
func attack_length() -> float:
	var full_length := finisher.attack_duration if _is_finisher else attack_duration
	return maxf(_hit_delay(), full_length - recovery_cut)


func _hit_delay() -> float:
	return finisher.hit_delay if _is_finisher else hit_delay


## Jab, jab, ..., then the finisher (if learned), then back to the first jab.
func _advance_combo() -> void:
	combo.resize(_chain_length())
	var step := combo.begin_attack()
	_is_finisher = has_finisher() and step == combo_animations.size()
	current_animation = finisher.animation_name if _is_finisher else combo_animations[step]


func _chain_length() -> int:
	return combo_animations.size() + (1 if has_finisher() else 0)


func _land_hit() -> void:
	combo.note_landed()
	var struck: Array[Health] = []
	if _is_finisher:
		struck = finisher.strike(attacker)
	else:
		_spawn_impact(_attack_direction)
		struck = _damage_targets_in_reach(_attack_direction)
	for target_health in struck:
		target_hit.emit(target_health)
	if not struck.is_empty():
		hits_landed.emit(struck.size())


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
## Measured at fist height against each target's body centre (not its feet).
## Returns the Health of every target hit.
func _damage_targets_in_reach(attack_direction: Vector2) -> Array[Health]:
	var punch_start := attacker.global_position + Vector2(0, fist_height)
	var punch_end := punch_start + attack_direction * reach
	var struck: Array[Health] = []
	for target: Node2D in get_tree().get_nodes_in_group(target_group):
		var body_centre := target.global_position + Vector2(0, target_body_height)
		var closest := Geometry2D.get_closest_point_to_segment(body_centre, punch_start, punch_end)
		if body_centre.distance_to(closest) > hit_radius:
			continue
		var target_health: Health = target.get_node_or_null("Health")
		if target_health != null:
			CritRoll.deal_damage(attacker, target_health, damage)
			struck.append(target_health)
	return struck


func _hit_position(attack_direction: Vector2) -> Vector2:
	var fist_origin := attacker.global_position + Vector2(0, fist_height)
	return fist_origin + attack_direction * reach
