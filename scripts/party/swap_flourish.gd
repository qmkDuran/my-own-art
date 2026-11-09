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
	var sprite := member.get_node_or_null("Sprite") as AnimatedSprite2D
	if sprite == null or sprite.sprite_frames == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.sprite_frames.get_frame_texture(sprite.animation, sprite.frame)
	ghost.flip_h = sprite.flip_h
	ghost.z_index = 2
	ghost.self_modulate = ApolloPalette.WHITE * 3.0
	member.get_parent().add_child(ghost)
	ghost.global_position = sprite.global_position
	var fade := ghost.create_tween().set_parallel()
	fade.tween_property(ghost, "modulate:a", 0.0, EXIT_SECONDS)
	fade.tween_property(ghost, "position:y", ghost.position.y - EXIT_RISE, EXIT_SECONDS)
	fade.chain().tween_callback(ghost.queue_free)


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
