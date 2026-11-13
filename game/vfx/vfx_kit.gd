class_name VfxKit
extends Node3D
## The shared toolbox for effects: the light and particle quota of the graphics tier, the effect sounds, the hit
## feel, and the effect assets (the Blender flipbooks and meshes, loaded once). `source` picks the Blender-assisted
## or the pure-Godot version of each piece (data/vfx.json), so the two can be compared.

const BLENDER: String = "blender"

var quota := VfxQuota.new()
var sfx: SfxPlayer
var hit_feel: HitFeel
var source: String = ""
var _assets: Dictionary = {}


func setup(camera: Camera3D) -> void:
	name = "VfxKit"
	source = Tuning.doc("vfx")["source"]
	sfx = SfxPlayer.new()
	add_child(sfx)
	hit_feel = HitFeel.new()
	add_child(hit_feel)
	hit_feel.setup(camera)


func uses_blender() -> bool:
	return source == BLENDER


## One of the effect assets in data/vfx.json "assets" (a texture or a mesh), loaded once.
func asset(key: String) -> Resource:
	if not _assets.has(key):
		_assets[key] = load(Tuning.doc("vfx")["assets"][key])
	return _assets[key]


## The first mesh inside a Blender effect GLB.
func effect_mesh(key: String) -> Mesh:
	if not _assets.has(key + "_mesh"):
		var scene: Node = (asset(key) as PackedScene).instantiate()
		var instance: MeshInstance3D = scene.find_children("*", "MeshInstance3D", true, false)[0]
		_assets[key + "_mesh"] = instance.mesh
		scene.free()
	return _assets[key + "_mesh"]


func flipbook_frames() -> Vector2i:
	var frames: Array = Tuning.doc("vfx")["assets"]["flipbook_frames"]
	return Vector2i(int(frames[0]), int(frames[1]))


## Adds a node to the world at a position (effects live in the world, not on whoever made them).
func place(node: Node3D, at: Vector3) -> void:
	get_tree().current_scene.add_child(node)
	node.global_position = at
