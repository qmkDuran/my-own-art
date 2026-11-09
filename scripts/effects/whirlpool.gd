class_name Whirlpool
extends Node2D
## Ripfin's whirlpool: a spinning ring of water on the ground that drags every enemy within
## `RADIUS` toward its centre and keeps them Soaked, then drains away.

const RADIUS := 52.0
const SECONDS := 1.4
## How fast enemies are dragged in, in pixels per second.
const PULL_SPEED := 55.0
## Enemies this close to the middle stop being dragged.
const CENTRE_RADIUS := 6.0
const SOAK_SECONDS := 4.0
const ARM_COUNT := 4
## It opens up over this long, then shrinks by this share of its size over its life.
const OPEN_SECONDS := 0.15
const SHRINK_SHARE := 0.3
## How fast the arms spin, in radians per second (clockwise).
const SPIN_SPEED := 8.0
const RIM_ALPHA := 0.5
## Each arm is a few arcs, from the rim inward, each a step further round.
const ARC_STEPS := 3
const ARC_STEP_INWARD := 0.25
const ARC_STEP_TWIST := 0.6
const ARC_LENGTH := 1.1
const OUTER_ARC_SHARE := 0.85

var _age: float = 0.0


static func spawn(world: Node, at: Vector2) -> void:
	var whirlpool := Whirlpool.new()
	whirlpool.z_index = 0
	world.add_child(whirlpool)
	whirlpool.global_position = at.round()


func _ready() -> void:
	for target_health in AbilityTargets.within(self, global_position, RADIUS):
		SetUp.apply(target_health, SetUp.SOAKED, SOAK_SECONDS)


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= SECONDS:
		queue_free()
		return
	for target_health in AbilityTargets.within(self, global_position, RADIUS):
		var enemy := target_health.get_parent() as Node2D
		var to_centre := global_position - enemy.global_position
		if to_centre.length() > CENTRE_RADIUS:
			enemy.global_position += to_centre.normalized() * PULL_SPEED * delta
	queue_redraw()


func _draw() -> void:
	var life := _age / SECONDS
	var size := RADIUS * minf(1.0, _age / OPEN_SECONDS) * (1.0 - SHRINK_SHARE * life)
	var fade := 1.0 - life * life
	var spin := -_age * SPIN_SPEED
	draw_arc(Vector2.ZERO, roundf(size), 0.0, TAU, 32, Color(ApolloPalette.BLUE, RIM_ALPHA * fade), 1.0)
	for arm in ARM_COUNT:
		var start_angle := spin + TAU * arm / ARM_COUNT
		for step in ARC_STEPS:
			var radius := roundf(size * (OUTER_ARC_SHARE - step * ARC_STEP_INWARD))
			var color := ApolloPalette.SKY_LIGHT if step == 0 else ApolloPalette.SKY
			var arc_start := start_angle + step * ARC_STEP_TWIST
			draw_arc(Vector2.ZERO, radius, arc_start, arc_start + ARC_LENGTH, 8, Color(color, fade), 1.0)
	draw_rect(Rect2(Vector2(-1, -1), Vector2(2, 2)), Color(ApolloPalette.WHITE, fade))
