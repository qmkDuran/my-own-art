class_name AwakeningLook
extends Node
## Keeps Emberoo looking like his Awakening stage: recolours the sprite (AwakeningPalette)
## and switches on the quiet aura from Awakening II.
##
## Follows every change of stage at once (loading, the debug key), except while the
## awakening moment plays: AwakeningMoment then calls `show_stage` at its flare.

@export var sprite: AnimatedSprite2D
@export var aura: AwakeningAura
@export var awakening_moment: AwakeningMoment


func _ready() -> void:
	# The sprite (CreatureAnimator) built its frames in its own _ready, before this one.
	EmberooFlameMarker.mark_frames(sprite.sprite_frames)
	show_stage(Awakening.stage)
	Awakening.stage_changed.connect(_on_stage_changed)


func show_stage(stage: int) -> void:
	AwakeningPalette.apply(sprite, stage)
	aura.visible = stage >= AwakeningStage.TWO


func _on_stage_changed(stage: int) -> void:
	if not awakening_moment.is_playing:
		show_stage(stage)
