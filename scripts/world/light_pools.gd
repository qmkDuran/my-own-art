class_name LightPools
extends Node2D
## A zone's light: a soft, screen-shaped pool around the player (the ground keeps its full
## brightness near him and dims gently towards the screen's edges), plus small tinted pools
## around fires, lit conduits and machine cores (its LightPoolSource children).
##
## Only `lit_layers` (the world's ground and prop tile layers) are lit, by one shared shader
## (light_pools.gdshader), so the hero, enemies, effects, loot and the HUD keep their full
## brightness. A dim world, never a night filter: the edges stay readable.
## `strength` is the zone's one setting; at 0 the zone is left exactly as it was.

const SHADER := preload("res://scripts/shaders/light_pools.gdshader")
## Brightness at the screen's edges at full strength (the corners get a little darker).
const EDGE_BRIGHTNESS_AT_FULL := 0.5
## The most sources lit at once (the shader's MAX_SOURCES): those nearest the player.
const MAX_SOURCES := 16

## How strong the light pools are: 0 = off, 1 = edges at EDGE_BRIGHTNESS_AT_FULL.
@export_range(0.0, 1.0) var strength: float = 0.0
## The tile layers (ground, decals, props, trees) the light falls on.
@export var lit_layers: Array[CanvasItem] = []

var _material: ShaderMaterial
var _sources: Array[LightPoolSource] = []
## How far from the player a source can be and still light part of the screen.
var _view_reach: float = 0.0


func _ready() -> void:
	if strength <= 0.0:
		set_process(false)
		return
	var half_view := Vector2(GameView.size()) / 2.0
	_view_reach = half_view.length()
	_material = ShaderMaterial.new()
	_material.shader = SHADER
	_material.set_shader_parameter("pool_half_size", half_view)
	_material.set_shader_parameter("edge_brightness", lerpf(1.0, EDGE_BRIGHTNESS_AT_FULL, strength))
	for layer in lit_layers:
		layer.material = _material
	for child in get_children():
		if child is LightPoolSource:
			_sources.append(child as LightPoolSource)


func _process(_delta: float) -> void:
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var centre := player.global_position
	_material.set_shader_parameter("pool_centre", centre)
	_upload_sources(centre)


## Sends the shader the sources nearest `centre` that can reach the screen.
func _upload_sources(centre: Vector2) -> void:
	var in_view := _sources.filter(func(source: LightPoolSource) -> bool:
		return source.global_position.distance_to(centre) < _view_reach + source.radius)
	in_view.sort_custom(func(a: LightPoolSource, b: LightPoolSource) -> bool:
		return a.global_position.distance_squared_to(centre) < b.global_position.distance_squared_to(centre))
	var count := mini(in_view.size(), MAX_SOURCES)
	var positions := PackedVector4Array()
	var tints := PackedVector4Array()
	positions.resize(MAX_SOURCES)
	tints.resize(MAX_SOURCES)
	for i in count:
		var source: LightPoolSource = in_view[i]
		positions[i] = Vector4(source.global_position.x, source.global_position.y, source.radius, source.strength * strength)
		tints[i] = Vector4(source.tint.r, source.tint.g, source.tint.b, 1.0)
	_material.set_shader_parameter("sources", positions)
	_material.set_shader_parameter("source_tints", tints)
	_material.set_shader_parameter("source_count", count)
