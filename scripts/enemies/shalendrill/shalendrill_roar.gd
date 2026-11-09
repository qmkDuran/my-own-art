class_name ShalendrillRoar
extends Node
## The Shalendrill's phase change, at half health: it rears up and roars, the cyan in its
## stone flares (CaptainPhaseTwo flashes it and stirs its aura), the ground shakes and the
## blast throws the player back out of reach (no damage). The Shalendrill holds still with
## super armour while it plays.

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
		screen_shake.shake(3.0, duration * 0.7)
	if shockwave_scene != null:
		var mouth := boss.global_position + mouth_offset
		Shockwave.spawn(shockwave_scene, boss.get_parent(), mouth, 34.0, 0.45, Color(ApolloPalette.SKY_LIGHT, 0.9))
		Shockwave.spawn(shockwave_scene, boss.get_parent(), boss.global_position, blast_radius, 0.6, Color(ApolloPalette.SKY, 0.7))
	var player := PlayerFinder.find(self)
	if player == null:
		return
	var away := player.global_position - boss.global_position
	if away.length() <= blast_radius:
		PlayerHit.shove(player, (away.normalized() if away.length() > 0.1 else Vector2.DOWN) * push_speed, push_time)


## A fresh fight (the player fell): it roars again at half health.
func reset() -> void:
	has_roared = false
