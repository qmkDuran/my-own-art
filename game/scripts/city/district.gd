class_name District
extends Node2D
## The city district below the garden heart: the great street of gold running west to the throne's light,
## dwellings with pearl doors on the street (John 14:2), planters, the jasper balustrade over the city in light.
## Geometry from res://art/district/layout.json (art/build_district.py). The One on the throne is never drawn:
## the west end of the street is light only (Rev 22:3-5).

const ART: String = "res://art/district/"
const DWELLING_FOOT_FRAC: float = 0.84
const DWELLING_FOOT_DEPTH: float = 40.0
const PLANTER_FOOT := Vector2(50, 16)
const LIGHT_POS := Vector2(-40, 600)        # the city's throne glow sprite: light centre at its left edge
const RAYS_SCALE := Vector2(1.2, 1.2)
const RAYS_OFFSET := Vector2(0, 60)
const RAYS_TURN: float = 0.04

var _layout: Dictionary
var _rays: Sprite2D


## Background and light go on this node; dwellings are y-sorted in `world`.
func build(world: Node2D) -> void:
	_layout = SceneData.load_json(ART + "layout.json")
	SpriteFactory.sprite(self, ART + "dbg.png", Vector2(0, float(_layout["origin_y"])), -10)
	for d: Array in _layout["dwellings"]:
		var feet := Vector2(float(d[1]), float(d[2]))
		SpriteFactory.grounded(world, ART + "%s.png" % d[0], feet)
		var w: float = float(d[3]) * DWELLING_FOOT_FRAC
		Blockers.add(self, Rect2(feet.x - w / 2.0, feet.y - DWELLING_FOOT_DEPTH - 4.0, w, DWELLING_FOOT_DEPTH))
	for p: Array in _layout["planters"]:
		Blockers.footprint(self, SceneData.vec(p), PLANTER_FOOT)
	var street: Array = _layout["street"]
	var centre_y: float = (float(street[0]) + float(street[1])) / 2.0
	SpriteFactory.sprite(self, "res://art/glow_throne.png", LIGHT_POS, -8, true)
	_rays = SpriteFactory.glow(self, "res://art/throne/rays.png", Vector2(0, centre_y), RAYS_SCALE, -8, RAYS_OFFSET)
	Fx.motes(self, Rect2(0, float(_layout["origin_y"]), 1920, 540), 160, Vector2(-6, -3), Color(1, 0.98, 0.8))
	Fx.sparkles(self, Vector2(120, centre_y), Vector2(110, 120), 50)


func animate(time: float) -> void:
	_rays.rotation = time * RAYS_TURN
