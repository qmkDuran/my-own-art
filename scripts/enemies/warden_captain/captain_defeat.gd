class_name CaptainDefeat
extends BossDefeat
## The Warden Captain's defeat (see BossDefeat). He doesn't die. He staggers and drops to one
## knee; the control chip at his temple (`chip_glint`) blinks faster and faster, then shorts
## and cracks in the usual cyan spark burst, and the stolen light bursts out as XP. With the
## AI God's voice gone from his head, he says a few dazed words (`waking_words`, in the
## DialogueBox; the game pauses as for any conversation), gets up and staggers off north,
## back out through the arena gate, fading as he goes (the cracked chip still spitting sparks).
##
## His fate is a story seed (see DESIGN.md, "Act 1 outline"): he is Varn, Elder Bram's son,
## taken by the Wardens as a boy. StoryFlags.WARDEN_CAPTAIN_SPARED is set as the chip cracks
## (Bram and Pip in the hub talk about it from then on). The arena's defeated flag, the chip
## drop and the XP work exactly as for a boss that dies.

## The shake while he staggers.
const STAGGER_SHAKE_STRENGTH := 1.0
## The thud as his knee hits the ground.
const KNEEL_SHAKE_STRENGTH := 1.0
const KNEEL_SHAKE_SECONDS := 0.15
## The burst's two rings round the chip: a tight bright one and a wide soft one.
const INNER_RING_RADIUS := 26.0
const INNER_RING_SECONDS := 0.4
const INNER_RING_COLOR := Color(ApolloPalette.SKY_LIGHT, 0.9)
const OUTER_RING_RADIUS := 44.0
const OUTER_RING_SECONDS := 0.6
const OUTER_RING_COLOR := Color(ApolloPalette.SKY, 0.7)
## His walk off is a slow, unsteady stagger.
const WALK_OFF_ANIMATION_SPEED := 0.6

## What he says once the chip has cracked.
@export var waking_words: Dialogue
## His face in the DialogueBox (a 16×26 crop of his sheet).
@export var portrait: Texture2D
## The chip's glint, at his temple in the kneeling pose; the burst comes from there.
@export var chip_glint: ChipGlint
## Seconds he staggers before he drops to one knee.
@export var stagger_seconds: float = 0.9
## Seconds the chip blinks on his temple before it cracks.
@export var flicker_seconds: float = 1.0
## Seconds he kneels, dazed, between the crack and his first words.
@export var dazed_seconds: float = 1.0
## How far north he staggers off, in pixels, and how long it takes (he fades out over it).
@export var walk_off_distance: float = 60.0
@export var walk_off_seconds: float = 2.6


func _ready() -> void:
	burst_offset = chip_glint.position


func _play_beats() -> void:
	sprite.replay_animation("stagger")
	_shake(STAGGER_SHAKE_STRENGTH, stagger_seconds)
	await Wait.seconds(self, stagger_seconds)
	sprite.replay_animation("kneel", "defeated")
	_shake(KNEEL_SHAKE_STRENGTH, KNEEL_SHAKE_SECONDS)
	chip_glint.flicker(flicker_seconds)
	await Wait.seconds(self, flicker_seconds)


func _spawn_burst_rings(chip_position: Vector2) -> void:
	_spawn_ring(chip_position, INNER_RING_RADIUS, INNER_RING_SECONDS, INNER_RING_COLOR)
	_spawn_ring(chip_position, OUTER_RING_RADIUS, OUTER_RING_SECONDS, OUTER_RING_COLOR)


## He wakes up, talks, and walks away instead of fading where he fell.
func _leave() -> void:
	chip_glint.crack()
	StoryFlags.set_flag(StoryFlags.WARDEN_CAPTAIN_SPARED)
	await Wait.seconds(self, dazed_seconds)
	await _say_waking_words()
	await _walk_off()


func _say_waking_words() -> void:
	var box := DialogueBox.find(self)
	if waking_words == null or box == null:
		return
	box.play(boss.display_name, waking_words.lines, portrait)
	await box.finished


func _walk_off() -> void:
	sprite.speed_scale = WALK_OFF_ANIMATION_SPEED
	sprite.replay_animation("walk")
	# The whole body fades (shadow too), as he walks.
	var walk := boss.create_tween().set_parallel()
	walk.tween_property(boss, "global_position", boss.global_position + Vector2.UP * walk_off_distance, walk_off_seconds)
	walk.tween_property(boss, "modulate:a", 0.0, walk_off_seconds).set_ease(Tween.EASE_IN)
	await walk.finished
