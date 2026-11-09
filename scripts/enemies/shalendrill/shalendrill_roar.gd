class_name ShalendrillRoar
extends Node
## The Shalendrill's phase change, at half health: it rears up and roars, the cyan in its
## stone flares (BossPhaseTwo flashes it and stirs its aura), the ground shakes and the
## blast throws the player back out of reach (no damage). The Shalendrill holds still with
## super armour while it plays.

## The screen shake: its strength, and the share of the roar it lasts.
const SHAKE_STRENGTH := 3.0
const SHAKE_SHARE := 0.7
## The two blast rings: a small bright one from the mouth, a wide one at the feet as far
## as the blast reaches.
const MOUTH_RING_RADIUS := 34.0
const MOUTH_RING_SECONDS := 0.45
const MOUTH_RING_COLOR := Color(ApolloPalette.SKY_LIGHT, 0.9)
const BLAST_RING_SECONDS := 0.6
const BLAST_RING_COLOR := Color(ApolloPalette.SKY, 0.7)

## Seconds the roar lasts.
@export var duration: float = 1.3
## The blast throws a player this close away, in pixels.
@export var blast_radius: float = 56.0
@export var push_speed: float = 220.0
@export var push_time: float = 0.3
@export var screen_shake: ScreenShake
@export var shockwave_scene: PackedScene
## Where the roar comes from, relative to the feet (its head).
@export var mouth_offset: Vector2 = Vector2(0, -22)

## True once this fight's phase-change roar has played.
var has_roared: bool = false

@onready var boss: Node2D = get_parent()


func play() -> void:
	has_roared = true
	if screen_shake != null:
		screen_shake.shake(SHAKE_STRENGTH, duration * SHAKE_SHARE)
	if shockwave_scene != null:
		var mouth := boss.global_position + mouth_offset
		Shockwave.spawn(shockwave_scene, boss.get_parent(), mouth, MOUTH_RING_RADIUS, MOUTH_RING_SECONDS, MOUTH_RING_COLOR)
		Shockwave.spawn(shockwave_scene, boss.get_parent(), boss.global_position, blast_radius, BLAST_RING_SECONDS, BLAST_RING_COLOR)
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var away := player.global_position - boss.global_position
	if away.length() <= blast_radius:
		PlayerHit.shove(player, (away.normalized() if away.length() > 0.1 else Vector2.DOWN) * push_speed, push_time)


## A fresh fight (the player fell): it roars again at half health.
func reset() -> void:
	has_roared = false
