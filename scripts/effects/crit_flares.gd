class_name CritFlares
extends Node
## Flares a CritFlare on every enemy that takes a critical hit, bigger when it is the
## player's Counter Punch (a crit landed while the counter is armed).
##
## Lives once in the level (GameLayer) and watches the scene tree like DamageNumbers: any
## enemy (a member of `target_group` with a child "Health") is watched as soon as it appears.
## At most `max_flares` show at once, so a Spinning Hook full of crits stays readable, and
## a Counter Punch gets one big flare however many it hits.

## The player's Counter Punch, from the player.
const COUNTER_PUNCH_NODE := "CounterPunch"
## Height of the old 16 px enemies, used when a body can't be measured.
const FALLBACK_BODY_HEIGHT := 16.0

## Enemies in this group get flares.
@export var target_group: String = "enemies"
## The most flares on screen at once; more crits in that moment show only their numbers.
@export var max_flares: int = 4

var _live: Array[CritFlare] = []
## The physics frame the last Counter Punch flare showed: one punch hitting several enemies
## gets one big flare, the rest plain ones.
var _counter_frame: int = -1


func _ready() -> void:
	get_tree().node_added.connect(_on_node_added)
	for target in get_tree().get_nodes_in_group(target_group):
		_watch(Health.of(target))


## Catches enemies that join after the level started (e.g. toads a Warden summons).
func _on_node_added(node: Node) -> void:
	if node is Health and node.get_parent() != null:
		_watch(node as Health)


func _watch(health: Health) -> void:
	if health == null or not health.get_parent().is_in_group(target_group):
		return
	var on_hit := _on_hit.bind(health.get_parent())
	if not health.hit_taken.is_connected(on_hit):
		health.hit_taken.connect(on_hit)


func _on_hit(_amount: int, is_critical: bool, damage_type: Health.DamageType, target: Node2D) -> void:
	if not is_critical or damage_type != Health.DamageType.DIRECT or target.get_parent() == null:
		return
	# Untyped on purpose: a freed flare can't be held as a CritFlare.
	_live.assign(_live.filter(func(flare: Variant) -> bool: return is_instance_valid(flare)))
	if _live.size() >= max_flares:
		return
	var body_middle := target.global_position + Vector2(0, -FxBody.height_of(target, FALLBACK_BODY_HEIGHT) / 2.0)
	var is_counter := _is_counter_punch() and _counter_frame != Engine.get_physics_frames()
	if is_counter:
		_counter_frame = Engine.get_physics_frames()
	_live.append(CritFlare.spawn(target.get_parent(), body_middle, is_counter))


## True while the player's Counter Punch is armed: the crit that lands now is the counter.
func _is_counter_punch() -> bool:
	var player := PlayerFinder.find(self)
	if player == null:
		return false
	var counter := player.get_node_or_null(COUNTER_PUNCH_NODE) as CounterPunch
	return counter != null and counter.is_armed()
