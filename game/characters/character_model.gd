class_name CharacterModel
extends Node3D
## A rigged Meshy character (one GLB holding the mesh, skin and every clip): turned so it faces the node's -Z
## like every other mover, its clips set to loop, its walk and run strides measured, its baked-in lean corrected
## (PostureFix), and played by name with a soft blend. The player and every
## townsperson use one.

const LEFT_TOE: String = "LeftToeBase"
const RIGHT_TOE: String = "RightToeBase"
const MOVING_CLIPS: Array[String] = ["walk", "run"]
const JUMP: String = "jump"
const HIPS_TRACK: String = ":Hips"

var animator: AnimationPlayer
var skeleton: Skeleton3D
var _clip: String = ""
var _foot_speeds: Dictionary = {}
var _plants: Dictionary = {}
var posture: PostureFix


func setup(path: String, keep_pose: Array = []) -> void:
	name = "Model"
	var model: Node3D = (load(path) as PackedScene).instantiate()
	model.rotation.y = PI
	add_child(model)
	animator = model.find_child("AnimationPlayer", true, false)
	skeleton = model.find_child("Skeleton3D", true, false)
	for clip: StringName in animator.get_animation_list():
		animator.get_animation(clip).loop_mode = Animation.LOOP_LINEAR
	if has_clip(JUMP):
		animator.get_animation(JUMP).loop_mode = Animation.LOOP_NONE
		_cap_rise(animator.get_animation(JUMP))
	for clip: String in MOVING_CLIPS:
		if has_clip(clip):
			var measured: float = ground_speed(clip, Tuning.i("stride", "samples"), Tuning.f("stride", "planted_band"))
			_foot_speeds[clip] = measured if measured > 0.0 else Tuning.f("stride", "fallback")
	_stand_up(keep_pose)


## Straightens the rig's baked-in lean on every standing clip (except clips whose pose is meant, like a stoop).
func _stand_up(keep_pose: Array) -> void:
	var clips: Array = Tuning.doc("tuning")["posture"]["clips"].filter(func(clip: String) -> bool:
		return not keep_pose.has(clip))
	posture = PostureFix.new()
	posture.measure(self, clips, Tuning.i("posture", "samples"))
	skeleton.add_child(posture)
	_clip = ""


func has_clip(clip: String) -> bool:
	return animator.has_animation(clip)


## Plays a clip (no-op if it is already playing) blending over blend seconds, at a playback speed.
func play(clip: String, blend: float, speed: float = 1.0) -> void:
	animator.speed_scale = speed
	if clip == _clip:
		return
	_clip = clip
	animator.play(clip, blend)


## Plays a clip from a point in it (a jump from its take-off), not looping.
func play_from(clip: String, offset: float, blend: float) -> void:
	animator.speed_scale = 1.0
	_clip = clip
	animator.play(clip, blend)
	animator.seek(offset, true)


## How fast the feet travel in a moving clip (measured at load), so callers can match playback to body speed.
func foot_speed(clip: String) -> float:
	return float(_foot_speeds.get(clip, Tuning.f("stride", "fallback")))


func current_clip() -> String:
	return _clip


## How fast a planted foot travels in a clip (metres per second, model space): the walking speed at which the
## clip's feet would not slide. A foot counts as planted while it is within a hair of its lowest height.
func ground_speed(clip: String, samples: int, planted_band: float) -> float:
	var animation: Animation = animator.get_animation(clip)
	var bones: Array[int] = [skeleton.find_bone(LEFT_TOE), skeleton.find_bone(RIGHT_TOE)]
	var tracks: Array = [[], []]
	animator.play(clip)
	for index: int in samples + 1:
		animator.seek(animation.length * index / samples, true)
		for side: int in 2:
			var at: Vector3 = skeleton.global_transform * skeleton.get_bone_global_pose(bones[side]).origin
			(tracks[side] as Array).append(at)
	var travelled: float = 0.0
	var planted_time: float = 0.0
	var plants := PackedFloat32Array()
	for side: int in 2:
		var lowest: float = (tracks[side] as Array).map(func(p: Vector3) -> float: return p.y).min()
		for index: int in samples:
			var a: Vector3 = tracks[side][index]
			var b: Vector3 = tracks[side][index + 1]
			if a.y < lowest + planted_band and b.y < lowest + planted_band:
				travelled += absf(b.z - a.z)
				planted_time += animation.length / samples
			elif b.y < lowest + planted_band:
				plants.append(animation.length * (index + 1) / samples)
	_plants[clip] = plants
	return travelled / planted_time if planted_time > 0.0 else 0.0


## The moments in a moving clip (seconds) when a foot comes down, for footsteps.
func plant_times(clip: String) -> PackedFloat32Array:
	return _plants.get(clip, PackedFloat32Array())


## The physics lifts the body in a jump, so the clip's own upward hip motion is capped at its standing height
## (crouches still lower the hips; in the air the legs tuck instead).
func _cap_rise(animation: Animation) -> void:
	for track: int in animation.get_track_count():
		if animation.track_get_type(track) != Animation.TYPE_POSITION_3D:
			continue
		if not String(animation.track_get_path(track)).ends_with(HIPS_TRACK):
			continue
		var standing: float = (animation.track_get_key_value(track, 0) as Vector3).y
		for key: int in animation.track_get_key_count(track):
			var value: Vector3 = animation.track_get_key_value(track, key)
			animation.track_set_key_value(track, key, Vector3(value.x, minf(value.y, standing), value.z))


## A node that follows a bone (for a carried lantern).
func attach_to_bone(bone: String) -> BoneAttachment3D:
	var attachment := BoneAttachment3D.new()
	attachment.bone_name = bone
	skeleton.add_child(attachment)
	return attachment
