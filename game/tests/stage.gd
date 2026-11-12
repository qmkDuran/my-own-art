class_name Stage
extends RefCounted
## Test and screenshot staging: put creatures exactly where a scenario needs them, point the camera, wait frames.

const SETTLE_LIFT: float = 0.05

var match_root: Main
var tree: SceneTree


func _init(root: Main) -> void:
	match_root = root
	tree = root.get_tree()


func place(creature: Creature, spot: Vector2, look_toward: Vector3) -> void:
	creature.global_position = match_root.woods.ground_at(spot) + Vector3.UP * SETTLE_LIFT
	creature.velocity = Vector3.ZERO
	creature.move_intent = Vector3.ZERO
	var toward: Vector3 = look_toward - creature.global_position
	creature.yaw = atan2(-toward.x, -toward.z)


func face(creature: Creature, point: Vector3) -> void:
	var toward: Vector3 = point - creature.global_position
	creature.yaw = atan2(-toward.x, -toward.z)


## Camera straight behind the player, looking where the player faces.
func camera_behind_player(pitch_degrees: float) -> void:
	match_root.rig.yaw = match_root.player.yaw
	match_root.rig.pitch = deg_to_rad(pitch_degrees)
	match_root.rig.snap()


## Takes the player off the keyboard and mouse so a scenario can aim and act for it.
func script_player() -> void:
	match_root.controller.set_physics_process(false)


## Stops the bot's mind so a scenario controls it fully.
func freeze_bot() -> void:
	match_root.brain.active = false
	match_root.brain.mover.stop()
	match_root.bot.has_look_target = false


func frames(count: int) -> void:
	for k: int in count:
		await tree.physics_frame


func seconds(duration: float) -> void:
	await frames(ceili(duration * Engine.physics_ticks_per_second))


static func ground_xz(point: Vector3) -> Vector2:
	return Vector2(point.x, point.z)
