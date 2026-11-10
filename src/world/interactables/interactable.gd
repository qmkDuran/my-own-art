class_name Interactable
extends Area2D
## Something the player can use with the interact key. Subclasses implement _perform().
## "requires" is a Condition; when unmet the locked lines are spoken instead.

var verb := "Examine"
var requires: Variant = null
var locked_lines: Array = []
var locked_ref := ""


func _init() -> void:
	collision_layer = Layers.INTERACTABLE
	collision_mask = 0
	monitoring = false
	monitorable = true


func add_circle(radius: float, offset: Vector2 = Vector2.ZERO) -> void:
	var shape := CircleShape2D.new()
	shape.radius = radius
	var collider := CollisionShape2D.new()
	collider.shape = shape
	collider.position = offset
	add_child(collider)


func configure_lock(data: Dictionary) -> void:
	requires = data.get("requires")
	locked_lines = data.get("locked_lines", [])
	locked_ref = String(data.get("locked_dialogue", ""))


func prompt() -> String:
	return verb


func interact(player: Player) -> void:
	if not Condition.check(requires):
		await _refuse()
		return
	await _perform(player)


func _refuse() -> void:
	AudioManager.play_sfx("ui_back")
	if not locked_ref.is_empty():
		await Dialogue.run(locked_ref)
	elif not locked_lines.is_empty():
		await Dialogue.run_lines(locked_lines)


func _perform(_player: Player) -> void:
	pass
