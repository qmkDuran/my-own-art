extends Node
## Overclocked chip mod "Flame Uppercut pulls enemies in" (added by ChipEffects): right
## after the flame bursts, enemies in front of Emberoo (a little past the flame's reach)
## are yanked toward him instead of thrown away, bunching them up for the next jabs.
##
## Each enemy is pulled just hard enough to slide to PULL_STOP_DISTANCE from him, worked out
## from its own knockback friction (distance = speed² / (2 × friction)).

## How much further than the flame's reach the pull grabs, in pixels.
const EXTRA_REACH := 20.0
## Where pulled enemies come to rest, in pixels from Emberoo's feet.
const PULL_STOP_DISTANCE := 10.0
## Used for enemies without their own knockback friction.
const DEFAULT_FRICTION := 500.0

## Seconds until the pull, or a negative number while none is coming.
var _seconds_to_pull: float = -1.0
## Where the uppercut was aimed when it was used.
var _aim: Vector2 = Vector2.RIGHT

@onready var _caster: Node2D = get_parent()
@onready var _skill_bar: SkillBar = get_parent().get_node(SkillBar.NODE_NAME)
@onready var _uppercut: FlameUppercut = get_parent().get_node(FlameUppercut.NODE_PATH)


func _ready() -> void:
	_skill_bar.skill_used.connect(_on_skill_used)


func _physics_process(delta: float) -> void:
	if _seconds_to_pull < 0.0:
		return
	_seconds_to_pull -= delta
	if _seconds_to_pull < 0.0 and _uppercut.is_casting:
		_pull_enemies_in()


func _on_skill_used(slot_index: int) -> void:
	if slot_index == _uppercut.slot_index:
		_aim = (_caster.call("aim_direction") as Vector2).normalized()
		# One physics frame after the burst, so the pull replaces the uppercut's own knockback.
		_seconds_to_pull = _uppercut.wind_up + 1.0 / Engine.physics_ticks_per_second


func _pull_enemies_in() -> void:
	var half_arc := deg_to_rad(_uppercut.arc_degrees) / 2.0
	for target: Node2D in get_tree().get_nodes_in_group(_uppercut.target_group):
		var to_target := target.global_position - _caster.global_position
		var distance := to_target.length()
		if distance > _uppercut.reach + EXTRA_REACH or distance <= PULL_STOP_DISTANCE:
			continue
		if absf(_aim.angle_to(to_target)) > half_arc or not EnemyReactions.can_be_thrown(target):
			continue
		var friction: float = target.get("knockback_friction") if "knockback_friction" in target else DEFAULT_FRICTION
		var speed := sqrt(2.0 * friction * (distance - PULL_STOP_DISTANCE))
		EnemyReactions.throw(target, -to_target.normalized() * speed)
