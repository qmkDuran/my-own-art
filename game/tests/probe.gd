extends Node
## Test probe (autoload "Probe"): with the user arg --probe, logs the player's position, collider and NPC counts
## every 30 physics frames, so runs can be compared before/after refactors. Silent otherwise.

const EVERY: int = 30

var _on: bool = false


func _ready() -> void:
	_on = OS.get_cmdline_user_args().has("--probe")
	process_mode = Node.PROCESS_MODE_ALWAYS


func _physics_process(_delta: float) -> void:
	if not _on or Engine.get_physics_frames() % EVERY != 0:
		return
	var scene: Node = get_tree().current_scene
	if scene == null:
		return
	var player: Node2D = get_tree().get_first_node_in_group("player") as Node2D
	var pos: String = "-" if player == null else "%d,%d" % [roundi(player.global_position.x), roundi(player.global_position.y)]
	print("PROBE %s f=%d p=%s blockers=%d npcs=%d" % [scene.name, Engine.get_physics_frames(), pos,
		_count(scene, "StaticBody2D"), _count(scene, "Npc")])


func _count(root: Node, kind: String) -> int:
	var n: int = 0
	for c: Node in root.find_children("*", "", true, false):
		if (kind == "Npc" and c is Npc) or (kind != "Npc" and c.is_class(kind)):
			n += 1
	return n
