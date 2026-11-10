class_name TriggerArea
extends Area2D
## Runs a dialogue/cinematic script when the player walks in. One-shot triggers set a
## "done:<id>" flag so they never fire again (the flag is saved with progress).

var script_ref := ""
var done_flag := ""
var _player_inside := false


func setup(rect: Rect2, ref: String, one_shot_flag: String) -> void:
	script_ref = ref
	done_flag = one_shot_flag
	collision_layer = 0
	collision_mask = Layers.PLAYER
	monitorable = false
	position = rect.position + rect.size / 2.0
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var collider := CollisionShape2D.new()
	collider.shape = shape
	add_child(collider)


func _physics_process(_delta: float) -> void:
	if Router.is_gameplay_paused():
		return
	var inside := _has_player()
	if inside and not _player_inside:
		_fire()
	_player_inside = inside


func _has_player() -> bool:
	for body: Node2D in get_overlapping_bodies():
		if body is Player:
			return true
	return false


func _fire() -> void:
	if not done_flag.is_empty():
		GameState.flags.set_flag(done_flag)
	Dialogue.run(script_ref)
