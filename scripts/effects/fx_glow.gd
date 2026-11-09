class_name FxGlow
extends Node2D
## A soft light behind a bright effect: three stepped discs added onto what's beneath
## (additive blending), brightest in the middle, fading out over `lifetime`. Pixel steps,
## not a smooth gradient, so it matches the art. Frees itself when done.
##
## Kept faint on purpose (`strength` is the middle's added alpha, at most MAX_STRENGTH), so
## stacked hits brighten the spot without ever washing the screen out.

const MAX_STRENGTH := 0.35
## Each disc's radius as a share of the glow's radius, outermost first.
const STEPS: Array[float] = [1.0, 0.66, 0.33]

var radius: float = 12.0
var color: Color = ApolloPalette.ORANGE
var strength: float = 0.25
var lifetime: float = 0.2

var _age: float = 0.0


## Adds a glow to `parent` at its origin; `parent` must already be in the tree.
static func add_to(parent: Node2D, glow_radius: float, glow_color: Color, glow_strength: float, glow_lifetime: float) -> FxGlow:
	var glow := FxGlow.new()
	glow.radius = glow_radius
	glow.color = glow_color
	glow.strength = minf(glow_strength, MAX_STRENGTH)
	glow.lifetime = glow_lifetime
	glow.show_behind_parent = true
	parent.add_child(glow)
	return glow


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive


func _process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade := 1.0 - _age / lifetime
	var step_alpha := strength * fade * fade / STEPS.size()
	for share in STEPS:
		FxPixels.draw_disc(self, Vector2.ZERO, radius * share, Color(color, step_alpha))
