class_name CharacterModel
extends Node3D
## A rigged Meshy character (one GLB holding the mesh, skin and every clip): turned so it faces the node's -Z
## like every other mover, its clips set to loop, and played by name with a soft blend. The player and every
## townsperson use one.

var animator: AnimationPlayer
var skeleton: Skeleton3D
var _clip: String = ""


func setup(path: String) -> void:
	name = "Model"
	var model: Node3D = (load(path) as PackedScene).instantiate()
	model.rotation.y = PI
	add_child(model)
	animator = model.find_child("AnimationPlayer", true, false)
	skeleton = model.find_child("Skeleton3D", true, false)
	for clip: StringName in animator.get_animation_list():
		animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR


func has_clip(clip: String) -> bool:
	return animator.has_animation(clip)


## Plays a clip (no-op if it is already playing) blending over blend seconds, at a playback speed.
func play(clip: String, blend: float, speed: float = 1.0) -> void:
	animator.speed_scale = speed
	if clip == _clip:
		return
	_clip = clip
	animator.play(clip, blend)


func current_clip() -> String:
	return _clip


## A node that follows a bone (for a carried lantern).
func attach_to_bone(bone: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	return attachment
