class_name SenseView
extends Node3D
## What the player's sense moves show in the world: with Keen Ears every sound Thornback makes within the widened
## hearing range pops up as a ping where it came from; Scent Trail lays glowing paw marks along where it walked.
## (Echo Pulse needs nothing here: it simply makes the hidden visible.)

const PING_LIFE: float = 1.4
const PING_RADIUS: float = 0.9
const MARK_SIZE: float = 0.16
const MARK_LIFT: float = 0.1
const MARK_FLAT: float = 0.2

var _player: Creature
var _ping_color: Color


func setup(player: Creature) -> void:
	_player = player
	name = "SenseView"
	_ping_color = Tuning.color(Tuning.creatures["glow"]["sense"])
	NoiseBus.noise_made.connect(_on_noise)
	player.sensed.connect(_on_sensed)


func _on_noise(source: Node3D, origin: Vector3, radius: float, _kind: String) -> void:
	if not _player.effects.has("hearing") or source != _player.opponent:
		return
	if Visibility.hears(_player, origin, radius):
		AreaFx.spawn(self, origin, PING_RADIUS, _ping_color)


func _on_sensed(kind: String, points: Array) -> void:
	if kind != "scent":
		return
	var duration: float = 0.0
	for move: Move in _player.moves:
		if move.spec.get("mode", "") == "scent":
			duration = move.number("duration")
	for point: Vector3 in points:
		_mark(point, duration)


func _mark(point: Vector3, duration: float) -> void:
	var paw := MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = MARK_SIZE
	disc.bottom_radius = MARK_SIZE
	disc.height = MARK_SIZE * MARK_FLAT
	paw.mesh = disc
	var material: StandardMaterial3D = WoodsMaterials.glow(_ping_color, 1.0)
	paw.material_override = material
	add_child(paw)
	paw.global_position = point + Vector3.UP * MARK_LIFT
	var fade: Tween = paw.create_tween()
	fade.tween_interval(duration)
	fade.tween_property(material, "albedo_color:a", 0.0, PING_LIFE)
	fade.tween_callback(paw.queue_free)
