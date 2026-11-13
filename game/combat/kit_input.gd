class_name KitInput
extends Node
## The mouse and keys for the Lamplighter's kit: hold the left button to keep firing the primary, hold the right
## button to charge the heavy and let go to fire it, hold Q to aim the bomb's arc and let go to throw, E raises
## the ward, V blinks, R calls the Sunrise when the meter is full, Tab locks on.

var enabled: bool = true
var _kit: LamplighterKit


func setup(kit: LamplighterKit) -> void:
	name = "KitInput"
	_kit = kit


func _physics_process(_delta: float) -> void:
	if enabled and Input.is_action_pressed("primary") and not _kit.heavy.charging and not _kit.bomb.aiming:
		_kit.primary.trigger()


func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event.is_action_pressed("heavy"):
		_kit.heavy.begin()
	elif event.is_action_released("heavy"):
		_kit.heavy.release()
	elif event.is_action_pressed("bomb"):
		_kit.bomb.begin_aim()
	elif event.is_action_released("bomb"):
		_kit.bomb.release()
	elif event.is_action_pressed("ward"):
		_kit.ward.raise()
	elif event.is_action_pressed("dash"):
		_kit.blink.go()
	elif event.is_action_pressed("super"):
		_kit.sunrise.fire()
	elif event.is_action_pressed("lock_on"):
		_kit.aim.toggle_lock()
