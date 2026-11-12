class_name SplatFx
extends Node3D
## Where a glob of spit lands: a bright splat stuck to the surface plus a few droplets, fading out over a few
## seconds so the player can read exactly what stopped the shot.

const SPLAT_RADIUS: float = 0.4
const SPLAT_THICKNESS: float = 0.06
const DROPLETS: int = 6
const DROPLET_RADIUS: float = 0.07
const DROPLET_REACH: float = 0.6
const DROPLET_TIME: float = 0.35
const LINGER_TIME: float = 3.0
const FADE_TIME: float = 1.0
const SPIT_EMISSION: float = 0.8
const NEARLY_SIDEWAYS: float = 0.9

static var _spit_material: StandardMaterial3D


static func spit_material() -> StandardMaterial3D:
	if _spit_material == null:
		_spit_material = StandardMaterial3D.new()
		var green: Color = Tuning.color(Tuning.creatures["glow"]["spit"])
		_spit_material.albedo_color = green
		_spit_material.emission_enabled = true
		_spit_material.emission = green
		_spit_material.emission_energy_multiplier = SPIT_EMISSION
	return _spit_material


static func spawn(parent: Node, at: Vector3, normal: Vector3) -> void:
	var fx := SplatFx.new()
	parent.add_child(fx)
	fx.global_position = at
	fx._build(normal)


func _build(normal: Vector3) -> void:
	var material: StandardMaterial3D = spit_material().duplicate()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var disc := CylinderMesh.new()
	disc.top_radius = SPLAT_RADIUS
	disc.bottom_radius = SPLAT_RADIUS
	disc.height = SPLAT_THICKNESS
	var splat := MeshInstance3D.new()
	splat.mesh = disc
	splat.material_override = material
	add_child(splat)
	var helper: Vector3 = Vector3.RIGHT if absf(normal.x) < NEARLY_SIDEWAYS else Vector3.FORWARD
	var side: Vector3 = normal.cross(helper).normalized()
	splat.basis = Basis(side, normal, side.cross(normal))
	for k: int in DROPLETS:
		_droplet(material, normal, side, k)
	var fade: Tween = create_tween()
	fade.tween_interval(LINGER_TIME)
	fade.tween_property(material, "albedo_color:a", 0.0, FADE_TIME)
	fade.tween_callback(queue_free)


func _droplet(material: StandardMaterial3D, normal: Vector3, side: Vector3, index: int) -> void:
	var ball := SphereMesh.new()
	ball.radius = DROPLET_RADIUS
	ball.height = DROPLET_RADIUS * 2.0
	var drop := MeshInstance3D.new()
	drop.mesh = ball
	drop.material_override = material
	add_child(drop)
	var spread: Vector3 = side.rotated(normal, TAU * index / DROPLETS)
	var target: Vector3 = (spread + normal).normalized() * DROPLET_REACH
	create_tween().tween_property(drop, "position", target, DROPLET_TIME).set_ease(Tween.EASE_OUT)
