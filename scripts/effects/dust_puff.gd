class_name DustPuff
extends Node2D
## A small puff of dust kicked up from the ground, e.g. a Gruntite scraping its hoof before
## a charge or bonking into a wall. An event effect: it plays once and removes itself.
##
## Use `spawn`; the puffs drift out sideways and up while they grow and fade.

## How many little clouds make up the puff.
@export var cloud_count: int = 5
## Seconds until the puff has faded away.
@export var duration: float = 0.35
## How far the clouds drift out sideways, in pixels.
@export var spread: float = 7.0
## How far the clouds rise, in pixels.
@export var rise: float = 3.0
## Radius of each cloud when it appears and when it has fully grown, in pixels.
@export var cloud_radius: Vector2 = Vector2(1.0, 2.5)
@export var colors: Array[Color] = [ApolloPalette.CREAM, ApolloPalette.GREY_LIGHT]

var _elapsed: float = 0.0
## Where each cloud ends up, relative to the puff's centre.
var _cloud_targets: Array[Vector2] = []


## Adds a puff from `scene` to `world` at `at` (world coordinates).
static func spawn(scene: PackedScene, world: Node, at: Vector2) -> void:
	if scene == null:
		return
	var puff: DustPuff = scene.instantiate()
	world.add_child(puff)
	puff.global_position = at


func _ready() -> void:
	for cloud_number in cloud_count:
		var sideways := randf_range(-spread, spread)
		_cloud_targets.append(Vector2(sideways, -randf_range(0.0, rise)))


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= duration:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var progress := clampf(_elapsed / duration, 0.0, 1.0)
	# Eases out: the clouds burst outward quickly, then hang while they fade.
	var travel := 1.0 - pow(1.0 - progress, 2.0)
	var radius := roundf(lerpf(cloud_radius.x, cloud_radius.y, travel))
	for cloud_number in _cloud_targets.size():
		var color: Color = colors[cloud_number % colors.size()]
		var faded := Color(color, 1.0 - progress)
		draw_circle((_cloud_targets[cloud_number] * travel).round(), radius, faded)
