class_name ForestArt
extends Node3D
## Draws every tree in the woods with a handful of multimeshes (a few crown shapes per kind, instanced with their
## own size, turn and green), so a big lush forest stays cheap on the Compatibility renderer. Crowns sway in the
## wind; a climbed tree's crown shakes. Climbable trees carry pale scratch rings on the trunk.

const VARIANTS: int = 4
const SHAKES: int = 4
const SHAKE_ANGLE: float = 0.08
const SHAKE_TIME: float = 0.35
const CROWN_SWAY: float = 0.12
const CROWN_SWAY_HEIGHT: float = 8.0
const LUMP: float = 0.14
const PINE_GREENS: Array[String] = ["pine", "pine_light"]
const LEAF_GREENS: Array[String] = ["leaf", "leaf_light", "leaf_warm"]
const MARK_RINGS: int = 2
const MARK_BULGE: float = 1.07
const MARK_HEIGHT: float = 0.07
const MARK_START: float = 0.8
const MARK_STEP: float = 0.7

var _trees: Array[Dictionary] = []
var _crowns: Dictionary = {}
var _rng := RandomNumberGenerator.new()


func setup(seed_value: int) -> void:
	name = "ForestArt"
	_rng.seed = seed_value


## Remembers a tree to draw; returns its index (for shaking).
func add_tree(ground: Vector3, kind: String, scale: float, yaw: float, climbable: bool) -> int:
	var greens: Array[String] = PINE_GREENS if kind == "pine" else LEAF_GREENS
	_trees.append({ "at": ground, "kind": kind, "scale": scale, "yaw": yaw, "climbable": climbable,
		"variant": _rng.randi() % VARIANTS, "green": Tuning.palette(greens[_rng.randi() % greens.size()]) })
	return _trees.size() - 1


func finish() -> void:
	for kind: String in ["pine", "leafy"]:
		_add_layer(TreeShapes.trunk(kind), WoodsMaterials.solid("bark"), _where(kind, -1), false)
		for variant: int in VARIANTS:
			var crown := MultiMeshInstance3D.new()
			crown.multimesh = _multimesh(TreeShapes.crown(kind, _rng, LUMP), _where(kind, variant), true)
			crown.material_override = WoodsMaterials.foliage(CROWN_SWAY, CROWN_SWAY_HEIGHT)
			add_child(crown)
			_crowns["%s%d" % [kind, variant]] = crown
	_add_marks()


## A quick wobble of one tree's crown (something is climbing it).
func shake(index: int) -> void:
	var tree: Dictionary = _trees[index]
	var crown: MultiMeshInstance3D = _crowns["%s%d" % [tree["kind"], tree["variant"]]]
	var slot: int = _where(tree["kind"], tree["variant"]).find(index)
	var base: Transform3D = _transform(tree)
	var wobble: Callable = func(t: float) -> void:
		var tilt: float = sin(t * TAU * SHAKES) * SHAKE_ANGLE
		crown.multimesh.set_instance_transform(slot, base.rotated_local(Vector3.FORWARD, tilt))
	create_tween().tween_method(wobble, 0.0, 1.0, SHAKE_TIME)


func _where(kind: String, variant: int) -> Array[int]:
	var picked: Array[int] = []
	for index: int in _trees.size():
		var tree: Dictionary = _trees[index]
		if tree["kind"] == kind and (variant < 0 or tree["variant"] == variant):
			picked.append(index)
	return picked


func _add_layer(mesh: Mesh, material: Material, indices: Array[int], colored: bool) -> void:
	var layer := MultiMeshInstance3D.new()
	layer.multimesh = _multimesh(mesh, indices, colored)
	layer.material_override = material
	add_child(layer)


func _multimesh(mesh: Mesh, indices: Array[int], colored: bool) -> MultiMesh:
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = colored
	multimesh.mesh = mesh
	multimesh.instance_count = indices.size()
	for slot: int in indices.size():
		multimesh.set_instance_transform(slot, _transform(_trees[indices[slot]]))
		if colored:
			multimesh.set_instance_color(slot, _trees[indices[slot]]["green"])
	return multimesh


static func _transform(tree: Dictionary) -> Transform3D:
	var basis := Basis(Vector3.UP, float(tree["yaw"])).scaled(Vector3.ONE * float(tree["scale"]))
	return Transform3D(basis, tree["at"])


func _add_marks() -> void:
	var ring := CylinderMesh.new()
	ring.top_radius = Props.TRUNK_RADIUS * MARK_BULGE
	ring.bottom_radius = Props.TRUNK_RADIUS * MARK_BULGE
	ring.height = MARK_HEIGHT
	var marks: Array[Transform3D] = []
	for tree: Dictionary in _trees:
		if tree["climbable"]:
			for k: int in MARK_RINGS:
				var at: Vector3 = tree["at"] + Vector3.UP * (MARK_START + k * MARK_STEP)
				marks.append(Transform3D(Basis.IDENTITY.scaled(Vector3(tree["scale"], 1.0, tree["scale"])), at))
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = ring
	multimesh.instance_count = marks.size()
	for k: int in marks.size():
		multimesh.set_instance_transform(k, marks[k])
	var layer := MultiMeshInstance3D.new()
	layer.multimesh = multimesh
	layer.material_override = WoodsMaterials.solid("climb_mark")
	add_child(layer)
