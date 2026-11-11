class_name Atmosphere
extends Node
## The mood over a zone, Last Epoch style: the world stays readable everywhere (the zone's tinted ambient, scaled
## by the Brightness setting), the lantern's pool is the warm, saturated place, the rest cools and greys a little
## (the colour grade), haze drifts, the edges close in (vignette), and bright things bloom (2D glow). The UI sits on
## higher canvas layers and is neither graded nor bloomed.

const GRADE_LAYER: int = 1
const GLOW_THRESHOLD: float = 0.82
const GLOW_INTENSITY: float = 0.55
const GLOW_BLOOM: float = 0.05
const BRIGHT_MIN: float = 0.6
const BRIGHT_MAX: float = 1.6

var g: Game
var _grade: ShaderMaterial


static func brightness() -> float:
	return clampf(float(GameData.setting("brightness", 1.0)), BRIGHT_MIN, BRIGHT_MAX)


## The zone's ambient light: its own tint (cyan Glasswood, red Ember Road, violet Moth Hollow...) times Brightness.
static func ambient(biome: Dictionary) -> Color:
	var a: Array = biome["ambient"]["darkness"]
	var k: float = brightness()
	return Color(float(a[0]) * k, float(a[1]) * k, float(a[2]) * k)       # above 1 brightens (HDR 2D)


func setup(game: Game) -> void:
	g = game
	var layer := CanvasLayer.new()
	layer.layer = GRADE_LAYER
	add_child(layer)
	var rect := ColorRect.new()
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_grade = ShaderMaterial.new()
	_grade.shader = preload("res://shaders/grade.gdshader")
	rect.material = _grade
	layer.add_child(rect)
	add_child(_environment())


func _environment() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = GRADE_LAYER          # the UI (higher layers) never blooms
	env.glow_enabled = true
	env.glow_hdr_threshold = GLOW_THRESHOLD
	env.glow_intensity = GLOW_INTENSITY
	env.glow_bloom = GLOW_BLOOM
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	var we := WorldEnvironment.new()
	we.environment = env
	return we


func _process(_delta: float) -> void:
	var vp: Rect2 = get_viewport().get_visible_rect()
	var at: Vector2 = g.get_viewport().get_canvas_transform() * g.player.light.global_position
	var zoom: float = g.camera.zoom.x
	_grade.set_shader_parameter("light_uv", at / vp.size)
	_grade.set_shader_parameter("light_r", g.player.light.light_radius() * zoom / vp.size.x)
	_grade.set_shader_parameter("aspect", vp.size.x / vp.size.y)
	_grade.set_shader_parameter("time", Time.get_ticks_msec() / 1000.0)
