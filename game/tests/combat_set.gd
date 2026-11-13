class_name CombatSet
extends RefCounted
## Staging helpers for the combat stills: put the player somewhere facing a way, still target dummies in a fan in
## front of them (brainless, so the picture holds), a live pack of swarmers, the boss fight in his ring, aiming
## the camera at an enemy, waiting for a telegraph to wind up, and freezing everything for paired stills.

const FAN: float = 0.6
const PACK_KINDS: Array[String] = ["mushroom_imp", "mushroom_imp", "pumpkin_head", "mushroom_imp", "sheet_ghost"]
const PACK_SPREAD: float = 3.0

var m: Main
var tool: Node


func _init(main: Main, shots: Node) -> void:
	m = main
	tool = shots


func place_player(at: Vector3, yaw: float, pitch: float) -> void:
	m.player.global_position = at
	m.player.yaw = yaw
	m.player.rotation.y = yaw
	m.camera_rig.yaw = yaw
	m.camera_rig.pitch = pitch
	m.camera_rig.snap()
	m.health.invulnerable = true
	await tool.call("seconds", 0.5)


## Still enemies in a fan ahead of the player (spread: the fan's half-angle as a share of its width).
func dummies(kinds: Array, from: Vector3, distance: float, spread: float) -> Array[Enemy]:
	var out: Array[Enemy] = []
	var forward: Vector3 = -m.player.global_basis.z
	for index: int in kinds.size():
		var share: float = (index - (kinds.size() - 1) * 0.5) * spread
		var at: Vector3 = from + forward.rotated(Vector3.UP, share * FAN) * (distance + index % 2 * 1.5)
		var enemy: Enemy = m.roster.spawn(kinds[index], at)
		enemy.brain = EnemyBrain.new()
		enemy.look_at_point = m.player.global_position
		out.append(enemy)
	return out


## A live pack of swarmers around a point.
func pack(at: Vector3, count: int) -> Array[Enemy]:
	var out: Array[Enemy] = []
	for index: int in count:
		var spot: Vector3 = at + Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * PACK_SPREAD
		out.append(m.roster.spawn(PACK_KINDS[index % PACK_KINDS.size()], spot))
	return out


## Turns the camera (and so the crosshair) onto an enemy.
func aim_at(enemy: Enemy) -> void:
	var to: Vector3 = enemy.centre() - (m.player.global_position + Vector3.UP * Tuning.f("camera", "height"))
	m.camera_rig.yaw = atan2(-to.x, -to.z)
	m.camera_rig.pitch = atan2(to.y, Vector2(to.x, to.z).length())
	m.kit.aim.engage()
	await tool.call("frames", 10)


func arena_centre() -> Vector3:
	return Tuning.point(Tuning.doc("mission")["arena"]["center"])


## The player at the ring's entrance, the boss inside, the fight on.
func boss_fight() -> void:
	var centre: Vector3 = arena_centre()
	await place_player(centre + Vector3(-9.0, 0.0, 0.0), -PI * 0.5, -0.1)
	m.mission.barrier.close()
	m.roster.spawn("gloom_king", centre + Vector3(4.0, 0.0, 0.0))
	await tool.call("seconds", 1.0)
	m.kit.aim.lock(m.roster.boss())
	await tool.call("seconds", 0.6)


## Waits until a ground telegraph has wound up to a share of its time.
func wait_for_telegraph(share: float) -> void:
	for frame: int in 600:
		for child: Node in m.roster.get_children():
			if child is Telegraph and (child as Telegraph).progress >= share and not (child as Telegraph).done:
				return
		await tool.call("frames", 1)


## Stops everything moving (enemies, magic, particles keep their place for a second still).
func freeze() -> void:
	m.get_tree().paused = true
	m.combat_hud.process_mode = Node.PROCESS_MODE_ALWAYS
