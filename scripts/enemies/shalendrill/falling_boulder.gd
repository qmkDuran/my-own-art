class_name FallingBoulder
extends Node2D
## One boulder of the Shalendrill's Rockfall: a red circle on the ground fills while the rock
## falls, the rock drops in for the last moment and shatters. Anyone in the circle when it
## lands is hurt. Lives in the world, so it keeps falling whatever the boss does; frees itself.

const BOULDER_TEXTURE := preload("res://art/shalendrill/shalendrill_boulder.png")
## Share of the fall during which the rock itself is in view (it drops in at the end).
const VISIBLE_SHARE := 0.35
## Height the rock drops from, in pixels.
const DROP_HEIGHT := 70.0
const FILL_ALPHA := Vector2(0.08, 0.32)
const OUTLINE_ALPHA := 0.8
## The small screen shake as it hits the ground.
const IMPACT_SHAKE_STRENGTH := 1.5
const IMPACT_SHAKE_SECONDS := 0.15

var radius: float = 13.0
## Seconds from the marker appearing to the impact.
var fall_time: float = 1.1
var damage: int = 2
var dust_scene: PackedScene
var screen_shake: ScreenShake

var _elapsed: float = 0.0
var _rock := Sprite2D.new()


## Drops a boulder on `at` (world coordinates).
static func spawn(world: Node, at: Vector2) -> FallingBoulder:
	var boulder := FallingBoulder.new()
	# On the ground: over the floor, under the creatures (z 1).
	boulder.z_index = 0
	world.add_child(boulder)
	boulder.global_position = at
	return boulder


func _ready() -> void:
	_rock.texture = BOULDER_TEXTURE
	_rock.visible = false
	# The rock is drawn over the creatures; the marker stays on the ground.
	_rock.z_index = 3
	add_child(_rock)


func _process(delta: float) -> void:
	_elapsed += delta
	var progress := _elapsed / fall_time
	var drop_progress := (progress - (1.0 - VISIBLE_SHARE)) / VISIBLE_SHARE
	_rock.visible = drop_progress > 0.0
	_rock.position = Vector2(0, -DROP_HEIGHT * (1.0 - clampf(drop_progress, 0.0, 1.0)) - 4.0).round()
	if progress >= 1.0:
		_impact()
		return
	queue_redraw()


func _impact() -> void:
	DustPuff.spawn(dust_scene, get_parent(), global_position)
	if screen_shake != null:
		screen_shake.shake(IMPACT_SHAKE_STRENGTH, IMPACT_SHAKE_SECONDS)
	var player := PlayerFinder.find(self)
	if player != null and player.global_position.distance_to(global_position) <= radius:
		PlayerHit.try_to_hurt(player, damage, global_position)
	queue_free()


func _draw() -> void:
	var progress := clampf(_elapsed / fall_time, 0.0, 1.0)
	draw_circle(Vector2.ZERO, radius, Color(TelegraphPainter.DANGER_COLOR, lerpf(FILL_ALPHA.x, FILL_ALPHA.y, progress)))
	draw_circle(Vector2.ZERO, radius * progress, Color(TelegraphPainter.DANGER_COLOR, FILL_ALPHA.y))
	var outline := TelegraphPainter.outline_color(TelegraphPainter.pulse(_elapsed), OUTLINE_ALPHA)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 28, outline, TelegraphPainter.OUTLINE_WIDTH)
