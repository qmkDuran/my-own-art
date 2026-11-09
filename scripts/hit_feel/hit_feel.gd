class_name HitFeel
extends RefCounted
## The reusable hit-feel kit (see PROJECT_B.md, "Hit-feel kit"): one call per landed hit
## gives it the freeze, shake, spark and ring that fit how big it is. The target's own white
## flash comes from its HitFlash when it takes damage.
##
##   LIGHT   basic hits:            3-frame hit-stop, 1 px shake, small spark
##   HEAVY   Signal Skills, skills: 8-frame hit-stop, 3 px shake, big spark + rings
##   FINISHER reactions:            HEAVY + one impact frame
## A Link Finisher adds `link_slow_mo` (0.3× for 20 game frames).

enum Weight { LIGHT, HEAVY, FINISHER }

const LIGHT_STOP_FRAMES := 3
const HEAVY_STOP_FRAMES := 8
const FINISHER_STOP_FRAMES := 10
const LIGHT_SHAKE := 1.0
const HEAVY_SHAKE := 3.0
const LIGHT_SHAKE_SECONDS := 0.08
const HEAVY_SHAKE_SECONDS := 0.25
const LIGHT_SPARK_RADIUS := 6.0
const HEAVY_SPARK_RADIUS := 12.0
const RING_RADIUS := 20.0
const RING_SECONDS := 0.28
const LINK_SLOW_SCALE := 0.3
const LINK_SLOW_GAME_FRAMES := 20
## Where a spark sits on a target: the middle of its body, above the feet.
const BODY_OFFSET := Vector2(0, -7)

const RING_SCENE := preload("res://scenes/effects/shockwave.tscn")


## Plays the feel of `attacker` landing a hit of `weight` at each of `spots` (target feet),
## in `color` (the element's).
static func land(attacker: Node2D, spots: Array[Vector2], color: Color, weight: Weight) -> void:
	if spots.is_empty() or not attacker.is_inside_tree():
		return
	var world := attacker.get_parent()
	var is_light := weight == Weight.LIGHT
	for spot in spots:
		var body := spot + BODY_OFFSET
		ImpactStar.spawn(world, body, LIGHT_SPARK_RADIUS if is_light else HEAVY_SPARK_RADIUS, color)
		if not is_light:
			Shockwave.spawn(RING_SCENE, world, spot, RING_RADIUS, RING_SECONDS, color)
			Shockwave.spawn(RING_SCENE, world, spot, RING_RADIUS * 0.5, RING_SECONDS * 0.7, ApolloPalette.WHITE)
	shake(attacker, LIGHT_SHAKE if is_light else HEAVY_SHAKE, LIGHT_SHAKE_SECONDS if is_light else HEAVY_SHAKE_SECONDS)
	var time := TimeControl.of(attacker.get_tree())
	match weight:
		Weight.LIGHT:
			time.hit_stop(LIGHT_STOP_FRAMES)
		Weight.HEAVY:
			time.hit_stop(HEAVY_STOP_FRAMES)
		Weight.FINISHER:
			time.hit_stop(FINISHER_STOP_FRAMES)
			ImpactFrame.play(attacker)


## Shakes the camera through the attacker's ScreenShake (every creature has one).
static func shake(attacker: Node, strength: float, seconds: float) -> void:
	var screen_shake := attacker.get_node_or_null("ScreenShake") as ScreenShake
	if screen_shake != null:
		screen_shake.shake(strength, seconds)


## The Link Finisher's slow-motion.
static func link_slow_mo(asker: Node) -> void:
	TimeControl.of(asker.get_tree()).slow_mo(LINK_SLOW_SCALE, LINK_SLOW_GAME_FRAMES)
