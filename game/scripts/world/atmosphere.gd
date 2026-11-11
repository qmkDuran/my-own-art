class_name Atmosphere
extends Node
## The mood over a zone, Last Epoch style: the world stays readable everywhere (the zone's tinted ambient, scaled
## by the Brightness setting), the lantern's pool is the warm, saturated place, the rest cools and greys a little
## (the colour grade), haze drifts, the edges close in (vignette), and bright things bloom (2D glow). The UI sits on
## higher canvas layers and is neither graded nor bloomed. The Graphics setting (Low/Medium/High, default Medium)
## chooses what runs: Low has none of grade, bloom or shadows; Medium has the grade and hard-edged shadows from
## fewer casters (spells still shine through their additive glow layers); High adds the HDR bloom and soft shadows.

const GRADE_LAYER: int = 1
const GLOW_THRESHOLD: float = 1.3      ## only truly bright things (spells, panes, embers) bloom; lit ground does not
const GLOW_INTENSITY: float = 0.8
const GLOW_LEVELS: Array[float] = [1.0, 1.0, 0.6, 0.0, 0.0, 0.0, 0.0]
const GLOW_BLOOM: float = 0.0       ## no whole-screen bloom: it tinted dark things with the ground colour
const QUALITY: Dictionary = {
	"low": {"grade": false, "glow": false, "shadows": 0, "filter": Light2D.SHADOW_FILTER_NONE},
	"medium": {"grade": true, "glow": false, "shadows": 24, "filter": Light2D.SHADOW_FILTER_NONE},
	"high": {"grade": true, "glow": true, "shadows": 48, "filter": Light2D.SHADOW_FILTER_PCF5},
}
const QUALITY_ORDER: Array[String] = ["low", "medium", "high"]
const BRIGHT_MIN: float = 0.6
const BRIGHT_MAX: float = 1.6

var g: Game
var _grade: ShaderMaterial


static func quality() -> Dictionary:
	return QUALITY.get(String(GameData.setting("graphics", "medium")), QUALITY["medium"])


static func brightness() -> float:
	return clampf(float(GameData.setting("brightness", 1.0)), BRIGHT_MIN, BRIGHT_MAX)


## The world's ambient light: neutral (so people and creatures keep their own colours), as bright as the zone's
## tinted ambient, times Brightness. Above 1 brightens (HDR 2D).
static func ambient(biome: Dictionary) -> Color:
	var l: float = _level(biome) * brightness()
	return Color(l, l, l)


## The zone's own colour (cyan Glasswood, red Ember Road, violet Moth Hollow...), carried by its terrain, trees and
## props only; its channels average 1.
static func tint(biome: Dictionary) -> Color:
	var a: Array = biome["ambient"]["darkness"]
	var l: float = _level(biome)
	return Color(float(a[0]) / l, float(a[1]) / l, float(a[2]) / l)


static func _level(biome: Dictionary) -> float:
	var a: Array = biome["ambient"]["darkness"]
	return (float(a[0]) + float(a[1]) + float(a[2])) / 3.0


func setup(game: Game) -> void:
	g = game
	var q: Dictionary = quality()
	if bool(q["glow"]):
		add_child(_environment())
	if not bool(q["grade"]):
		set_process(false)
		return
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


func _environment() -> WorldEnvironment:
	var env := Environment.new()
	env.background_mode = Environment.BG_CANVAS
	env.background_canvas_max_layer = GRADE_LAYER          # the UI (higher layers) never blooms
	env.glow_enabled = true
	env.glow_hdr_threshold = GLOW_THRESHOLD
	env.glow_intensity = GLOW_INTENSITY
	env.glow_bloom = GLOW_BLOOM
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_ADDITIVE
	for level: int in GLOW_LEVELS.size():                  # a tight bloom: it never spills colour onto neighbours
		env.set_glow_level(level, GLOW_LEVELS[level])
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
