class_name PostureCheck
extends RefCounted
## Posture checks for the smoke test: the player and every townsperson stand up straight, in their idle and at
## mid-stance of their walk (the moment the feet pass each other), measured on the skeleton as drawn (after the
## posture correction, read as the skeleton finishes updating): in side view the head and the hips within a few
## centimetres of the vertical line through the mid-ankles, and the spine (hips to neck) leaning less than a few
## degrees. Clips a character keeps on purpose (the old man's dozing stoop) are left out. An idle is judged by its
## average over the cycle (it sways).

const CLIPS: Array[String] = ["idle", "walk"]
const SAMPLES: int = 12
const HEAD: String = "Head"
const SETTLE_SECONDS: float = 0.8

var m: Main
var failures: Array[String] = []


func _init(main: Main) -> void:
	m = main


func run() -> Array[String]:
	var people: Array[Dictionary] = [{ "model": m.player.model, "who": "player", "keep": [] }]
	for index: int in m.townsfolk.size():
		var person: Townsperson = m.townsfolk[index]
		people.append({ "model": person.model, "who": person.person_name, "keep": Tuning.doc("npcs")["townsfolk"][
			index].get("keep_pose", []) })
	m.controller.enabled = false
	for person: Townsperson in m.townsfolk:
		person.set_process(false)
	for entry: Dictionary in people:
		for clip: String in CLIPS:
			if not (entry["keep"] as Array).has(clip):
				await _check(entry["model"], entry["who"], clip)
	for person: Townsperson in m.townsfolk:
		person.set_process(true)
	return failures


func _check(model: CharacterModel, who: String, clip: String) -> void:
	model.play(clip, 0.0)
	await m.get_tree().create_timer(SETTLE_SECONDS).timeout
	var length: float = model.animator.get_animation(clip).length
	var poses: Array[Dictionary] = []
	for index: int in SAMPLES:
		model.animator.seek(length * index / SAMPLES, true)
		model.animator.speed_scale = 0.0
		var pose: Dictionary = {}
		model.skeleton.skeleton_updated.connect(func() -> void: pose.merge(_pose(model), true), CONNECT_ONE_SHOT)
		for frame: int in 3:
			await m.get_tree().process_frame
		poses.append(pose)
	model.animator.speed_scale = 1.0
	var judged: Dictionary = _mid_stance(poses) if clip == "walk" else _average(poses)
	var lean: float = rad_to_deg(float(judged["lean"]))
	var text: String = "head %.3f m and hips %.3f m from the mid-ankles, spine lean %.1f deg" % [judged["head"],
		judged["hips"], lean]
	print("SMOKE posture %s %s: %s" % [who, clip, text])
	if absf(float(judged["head"])) > Tuning.f("posture", "max_head_offset") or absf(lean) > Tuning.f("posture",
			"max_lean_deg") or absf(float(judged["hips"])) > Tuning.f("posture", "max_hips_offset"):
		failures.append("%s's %s posture: %s" % [who, clip, text])


## The walk's mid-stance: the sample where the feet pass each other.
static func _mid_stance(poses: Array[Dictionary]) -> Dictionary:
	var best: Dictionary = poses[0]
	for pose: Dictionary in poses:
		if float(pose["feet_apart"]) < float(best["feet_apart"]):
			best = pose
	return best


## An idle as it reads overall: the average over its cycle.
static func _average(poses: Array[Dictionary]) -> Dictionary:
	var out: Dictionary = { "head": 0.0, "lean": 0.0, "hips": 0.0 }
	for pose: Dictionary in poses:
		for key: String in out:
			out[key] = float(out[key]) + float(pose[key]) / poses.size()
	return out


func _pose(model: CharacterModel) -> Dictionary:
	var skeleton: Skeleton3D = model.skeleton
	var forward: Vector3 = -model.global_basis.z
	var at: Callable = func(bone: String) -> Vector3:
		return skeleton.global_transform * skeleton.get_bone_global_pose(skeleton.find_bone(bone)).origin
	var left: Vector3 = at.call("LeftFoot")
	var right: Vector3 = at.call("RightFoot")
	var ankles: Vector3 = (left + right) * 0.5
	var spine: Vector3 = at.call(PostureFix.NECK) - at.call(PostureFix.HIPS)
	return { "head": (at.call(HEAD) - ankles).dot(forward), "lean": atan2(spine.dot(forward), spine.dot(Vector3.UP)),
		"hips": (at.call(PostureFix.HIPS) - ankles).dot(forward), "feet_apart": absf((left - right).dot(forward)) }
