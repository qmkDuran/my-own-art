class_name CounterPunch
extends Node
## Counter Punch (Ember Tree, Bruiser; an Ash Guard upgrade): a hit taken while guarding
## "arms" the counter. The next punch that lands within `window` seconds is a sure critical
## hit and throws every enemy it hits back hard. Emberoo pulses gold while it is armed.
##
## Listens to Health (hits taken) and MeleeAttack (punches landing); forces the crit through
## CritRoll. Its numbers fill the Counter Punch facts in the tree.

## The Counter Punch node's id (Ember Tree, Bruiser).
const COUNTER_PUNCH_ID := "counter_punch"

## Seconds after the guarded hit during which the counter stays armed.
@export var window: float = 1.0
## Speed the countered enemy is thrown back at, in pixels per second (a jab gives about 120).
@export var knockback_speed: float = 240.0
## Seconds between the gold pulses that show the counter is armed.
@export var pulse_interval: float = 0.25

@export var health: Health
@export var melee_attack: MeleeAttack
@export var ash_guard: AshGuard
@export var crit_roll: CritRoll
@export var hit_flash: HitFlash

var _armed_seconds_left: float = 0.0
var _seconds_to_next_pulse: float = 0.0

@onready var _owner_body: Node2D = get_parent()


func _ready() -> void:
	health.damaged.connect(_on_damaged)
	melee_attack.target_hit.connect(_on_target_hit)
	melee_attack.hits_landed.connect(func(_count: int) -> void: _disarm())


func is_learned() -> bool:
	return EmberTree.is_learned(COUNTER_PUNCH_ID)


func is_armed() -> bool:
	return _armed_seconds_left > 0.0


func _physics_process(delta: float) -> void:
	if not is_armed():
		return
	_armed_seconds_left -= delta
	if not is_armed():
		_disarm()
		return
	_seconds_to_next_pulse -= delta
	if _seconds_to_next_pulse <= 0.0:
		_pulse()


func _on_damaged(_amount: int, _source_position: Vector2) -> void:
	if not ash_guard.is_casting or not is_learned():
		return
	_armed_seconds_left = window
	crit_roll.is_sure_crit = true
	# Deferred, so the gold pulse shows over the creature's own white hit flash.
	_pulse.call_deferred()


func _on_target_hit(target_health: Health) -> void:
	if not is_armed():
		return
	var target := target_health.get_parent() as Node2D
	if target == null or not target.has_method("knock_back"):
		return
	var away := target.global_position - _owner_body.global_position
	if away.length() < 0.1:
		away = Vector2.RIGHT
	target.call("knock_back", away.normalized() * knockback_speed)


func _pulse() -> void:
	_seconds_to_next_pulse = pulse_interval
	hit_flash.flash(ApolloPalette.GOLD)


func _disarm() -> void:
	_armed_seconds_left = 0.0
	crit_roll.is_sure_crit = false
