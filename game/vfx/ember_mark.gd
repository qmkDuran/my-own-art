class_name EmberMark
extends Decal
## The aftermath of a hit: a soft glowing ember mark projected onto the cobbles that cools and fades over about
## a second and a half, with a few embers drifting up from it. Frees itself.

const MARK_HEIGHT: float = 0.6
const TEXTURE_SIZE: int = 64
const SPREAD: float = 0.4
const EMBER_SHARE: float = 0.06
const EDGE_COOL: Color = Color(0.3, 0.1, 0.0, 0.0)
const MID_COOL: Color = Color(1.0, 0.6, 0.3, 0.6)


func play(kit: VfxKit, spec: Dictionary) -> void:
	name = "EmberMark"
	var colour: Color = Tuning.color(spec["color"])
	var size: float = spec["size"]
	self.size = Vector3(size, MARK_HEIGHT, size)
	texture_albedo = _spot(colour)
	texture_emission = texture_albedo
	emission_energy = float(spec["energy"])
	modulate = colour
	upper_fade = 0.5
	lower_fade = 0.5
	var drift := ParticleBursts.embers(kit.quota.count(int(spec["embers"])), colour, size * EMBER_SHARE, float(
		spec["ember_rise"]), float(spec["seconds"]))
	(drift.process_material as ParticleProcessMaterial).spread = ParticleBursts.ALL_DIRECTIONS_DEG * SPREAD * 0.5
	add_child(drift)
	var seconds: float = spec["seconds"]
	var tween: Tween = create_tween()
	tween.tween_property(self, "emission_energy", 0.0, seconds)
	tween.parallel().tween_property(self, "albedo_mix", 0.0, seconds)
	tween.tween_callback(queue_free)


## A soft round glow with a ragged, smoky edge (a radial gradient, cooling outwards).
static func _spot(colour: Color) -> GradientTexture2D:
	var gradient := Gradient.new()
	gradient.set_color(0, colour)
	gradient.set_color(1, colour * EDGE_COOL)
	gradient.add_point(SPREAD, colour * MID_COOL)
	var texture := GradientTexture2D.new()
	texture.gradient = gradient
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.width = TEXTURE_SIZE
	texture.height = TEXTURE_SIZE
	return texture
