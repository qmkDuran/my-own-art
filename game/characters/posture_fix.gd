class_name PostureFix
extends SkeletonModifier3D
## Stands a Meshy character up straight. The Meshy rigs come with a lean baked in (in the bind pose and some clips:
## the hips pushed forward of the ankles and the spine tilted back). At load each standing clip is measured over
## its cycle: how far the hips sit in front of the mid-ankles and how far the spine (hips to neck) leans. Every
## frame, after the animation, the hips are moved back over the ankles (the upper legs turned so the feet stay put)
## and the lowest spine bone is pitched so the spine stands upright. Corrections glide over a clip blend.

const HIPS: String = "Hips"
const NECK: String = "neck"
const SPINE: String = "Spine02"
const LEGS: Array[String] = ["LeftUpLeg", "RightUpLeg"]
const FEET: Array[String] = ["LeftFoot", "RightFoot"]
const TINY: float = 0.0001

var corrections: Dictionary = {}
var _model: CharacterModel
var _forward: Vector3 = Vector3.BACK
var _axis: Vector3 = Vector3.RIGHT
var _bones: Dictionary = {}
var _leg_length: float = 1.0
var _shift: float = 0.0
var _turn: float = 0.0


## Measures every standing clip of the model (call before adding the modifier to the skeleton).
func measure(model: CharacterModel, clips: Array, samples: int) -> void:
	name = "PostureFix"
	_model = model
	var skeleton: Skeleton3D = model.skeleton
	var relative: Transform3D = model.global_transform.affine_inverse() * skeleton.global_transform
	_forward = (relative.basis.inverse() * Vector3.FORWARD).normalized()
	_axis = Vector3.UP.cross(_forward).normalized()
	for bone: String in [HIPS, NECK, SPINE] + LEGS + FEET:
		_bones[bone] = skeleton.find_bone(bone)
	for clip: String in clips:
		if model.has_clip(clip):
			corrections[clip] = _measure_clip(clip, samples)
	skeleton.reset_bone_poses()
	_leg_length = _point(FEET[0]).distance_to(_point(LEGS[0]))


## The hips-ahead-of-ankles offset and the spine lean (radians, forward positive) in the pose shown now.
func stance() -> Vector2:
	var ankles: Vector3 = (_point(FEET[0]) + _point(FEET[1])) * 0.5
	var hips: Vector3 = _point(HIPS)
	var spine: Vector3 = _point(NECK) - hips
	return Vector2((hips - ankles).dot(_forward), atan2(spine.dot(_forward), spine.dot(Vector3.UP)))


func _measure_clip(clip: String, samples: int) -> Vector2:
	var animation: Animation = _model.animator.get_animation(clip)
	_model.animator.play(clip)
	var total := Vector2.ZERO
	for index: int in samples:
		_model.animator.seek(animation.length * index / samples, true)
		total += stance()
	return total / samples


func _point(bone: String) -> Vector3:
	return _model.skeleton.get_bone_global_pose(int(_bones[bone])).origin


func _process_modification() -> void:
	var goal: Vector2 = corrections.get(_model.current_clip(), Vector2.ZERO)
	var blend: float = clampf(get_process_delta_time() / maxf(Tuning.f("player", "blend_seconds"), TINY), 0.0,
		1.0)
	_shift = lerpf(_shift, -goal.x, blend)
	_turn = lerpf(_turn, -goal.y, blend)
	var skeleton: Skeleton3D = get_skeleton()
	var hips: int = int(_bones[HIPS])
	skeleton.set_bone_pose_position(hips, skeleton.get_bone_pose_position(hips) + _forward * _shift)
	for leg: String in LEGS:
		_rotate(skeleton, int(_bones[leg]), asin(clampf(_shift / _leg_length, -1.0, 1.0)))
	_rotate(skeleton, int(_bones[SPINE]), _turn)


## Turns a bone about the skeleton's sideways axis (positive tips it forward).
func _rotate(skeleton: Skeleton3D, bone: int, angle: float) -> void:
	var parent: Basis = skeleton.get_bone_global_pose(skeleton.get_bone_parent(bone)).basis.orthonormalized()
	var turned: Basis = parent.inverse() * Basis(_axis, angle) * parent * Basis(skeleton.get_bone_pose_rotation(bone))
	skeleton.set_bone_pose_rotation(bone, turned.get_rotation_quaternion())
