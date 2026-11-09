class_name SwapFlourish
extends RefCounted
## The little show around a team swap: the outgoing creature vanishes in a quick white flash
## that floats up and fades, and the incoming one lands with a burst in its element's colour
## (rings, sparks and a bright flash of its sprite).

const EXIT_SECONDS := 0.18
const EXIT_RISE := 5.0
const ENTRANCE_RING_RADIUS := 18.0
const ENTRANCE_RING_SECONDS := 0.3
const SPARK_COUNT := 12


## A white ghost of the creature's current frame, left behind where it stood.
static func play_exit(member: PlayableCreature) -> void:
	ghost(member, Vector2(0, -EXIT_RISE), EXIT_SECONDS, ApolloPalette.WHITE * 3.0)


## A copy of the creature's current frame that drifts by `drift` pixels over `seconds` while
## fading out, tinted `tint` (an Outro's exit: a leap up, a dive down).
static func ghost(member: PlayableCreature, drift: Vector2, seconds: float, tint: Color) -> void:
	var sprite := member.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null or not sprite.sprite_frames.has_animation(sprite.animation):
		return
	var copy := Sprite2D.new()
	copy.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	copy.flip_h = sprite.flip_h
	copy.z_index = 2
	copy.self_modulate = tint
	member.get_parent().add_child(copy)
	copy.global_position = sprite.global_position.round()
	var start := copy.position
	var fade := copy.create_tween().set_parallel()
	fade.tween_property(copy, "modulate:a", 0.0, seconds).set_ease(Tween.EASE_IN)
	fade.tween_method(func(offset: Vector2) -> void: copy.position = (start + offset).round(), Vector2.ZERO, drift, seconds) \
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	fade.chain().tween_callback(copy.queue_free)


## Rings and sparks in the element's colour, and the creature flashes that colour.
static func play_entrance(member: PlayableCreature, ring_scene: PackedScene) -> void:
	var color := ElementColors.for_element(member.element)
	var world := member.get_parent()
	var feet := member.global_position
	if ring_scene != null:
		Shockwave.spawn(ring_scene, world, feet, ENTRANCE_RING_RADIUS, ENTRANCE_RING_SECONDS, color)
		Shockwave.spawn(ring_scene, world, feet, ENTRANCE_RING_RADIUS * 0.5, ENTRANCE_RING_SECONDS * 0.7, ApolloPalette.WHITE)
	var sparks := ChipSparkBurst.new()
	sparks.spark_count = SPARK_COUNT
	sparks.duration = 0.4
	sparks.speed_range = Vector2(30, 70)
	sparks.colors = [color, ApolloPalette.WHITE]
	sparks.z_index = 2
	world.add_child(sparks)
	sparks.global_position = feet + Vector2(0, FrontViewCreature.BODY_HEIGHT)
	var hit_flash := member.get_node_or_null("HitFlash") as HitFlash
	if hit_flash != null:
		hit_flash.flash(color)
