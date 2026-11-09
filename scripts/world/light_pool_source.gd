class_name LightPoolSource
extends Marker2D
## A small pool of light on the ground around something that glows: a firepit, a lit conduit,
## a machine's core. A child of the zone's LightPools, which lights the world's tiles with it.

## How far the light reaches, in world pixels.
@export var radius: float = 64.0
## How bright the middle of the pool is: 1.0 lifts the ground there to full brightness.
@export_range(0.0, 1.0) var strength: float = 0.8
## The light's colour (orange for fire, cyan for the stolen Glimra light).
@export var tint: Color = ApolloPalette.ORANGE
