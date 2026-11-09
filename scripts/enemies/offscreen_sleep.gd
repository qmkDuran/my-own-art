class_name OffscreenSleep
extends Node
## Puts its enemy (the parent) to sleep while it's far off-screen, so a zone full of enemies
## only pays for the ones near the player: no AI, pathing, animation or physics processing
## while asleep. It wakes once the player comes within `wake_range_in_screens` screens (along
## either axis), and at once whenever it's hurt, staying awake a while after.
##
## Sleeping only pauses processing. Being hit, noticed or alerted by its pack still works
## (those are signals and method calls), and the enemy carries on where it left off.
## This node keeps running (process mode Always) so it can wake its enemy again.

## Seconds between distance checks; enemies spread their checks across this interval.
const CHECK_INTERVAL := 0.25
## Number of different check times enemies are spread across.
const CHECK_SLOTS := 16

## How far from the player, in screen widths and heights, the enemy stays awake. Far beyond
## any enemy's notice distance and shooting range, so nothing nearby is ever asleep.
@export var wake_range_in_screens: float = 1.5
## Seconds it stays awake after being hurt, wherever the player is (e.g. a burn far away).
@export var stay_awake_after_hit: float = 3.0
## Its enemy's Health: a hit wakes it.
@export var health: Health

var is_asleep: bool = false

var _wake_range: Vector2
var _seconds_until_check: float = 0.0
var _seconds_awake_after_hit: float = 0.0

@onready var enemy: Node2D = get_parent()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_wake_range = Vector2(GameView.size()) * wake_range_in_screens
	# Spread by instance (not randf), so adding sleep never changes the game's random rolls.
	_seconds_until_check = CHECK_INTERVAL * (get_instance_id() % CHECK_SLOTS) / CHECK_SLOTS
	health.hit_taken.connect(_on_hit_taken)


func _physics_process(delta: float) -> void:
	if get_tree().paused:
		return
	_seconds_awake_after_hit = maxf(0.0, _seconds_awake_after_hit - delta)
	_seconds_until_check -= delta
	if _seconds_until_check > 0.0:
		return
	_seconds_until_check = CHECK_INTERVAL
	_set_asleep(_is_far_from_player() and _seconds_awake_after_hit <= 0.0)


func _is_far_from_player() -> bool:
	var player := PlayerFinder.find(self)
	if player == null:
		return false
	var offset := (enemy.global_position - player.global_position).abs()
	return offset.x > _wake_range.x or offset.y > _wake_range.y


func _set_asleep(asleep: bool) -> void:
	if asleep == is_asleep:
		return
	is_asleep = asleep
	enemy.process_mode = Node.PROCESS_MODE_DISABLED if asleep else Node.PROCESS_MODE_INHERIT


func _on_hit_taken(_amount: int, _is_critical: bool, _damage_type: Health.DamageType) -> void:
	_seconds_awake_after_hit = stay_awake_after_hit
	_set_asleep(false)
