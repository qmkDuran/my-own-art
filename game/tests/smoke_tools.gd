class_name SmokeTools
extends RefCounted
## Smoke checks for the playtest fixes: footsteps sound while walking and the surface underfoot is right (cobbles,
## the bridge, the meadow's grass), the controls (Shift only runs, V dashes, F9 is VSync), fly mode flies free and
## puts the player back where they were, the performance overlay reports, and the Windows renderer toggle writes
## its setting for the next start.

const FLY_SECONDS: float = 0.5
const SURFACES: Dictionary = { "cobbles": Vector3(-20.0, 0.0, 0.0), "bridge": Vector3(0.0, 1.0, 17.0),
	"grass": Vector3(0.0, 0.0, 50.0) }

var m: Main
var failures: Array[String] = []


func _init(main: Main) -> void:
	m = main


func run() -> Array[String]:
	_check_surfaces()
	_check_controls()
	await _check_footsteps()
	await _check_fly()
	_check_overlay()
	_check_driver()
	return failures


func _expect(ok: bool, what: String) -> void:
	if not ok:
		failures.append(what)


func _check_surfaces() -> void:
	for surface: String in SURFACES:
		var found: String = Blocks.surface_at(m.get_world_3d(), SURFACES[surface])
		_expect(found == surface, "the floor at %s sounds of %s (got %s)" % [SURFACES[surface], surface, found])


func _check_controls() -> void:
	_expect(_has_key("dash", KEY_V), "V dashes")
	_expect(_has_key("vsync", KEY_F9), "F9 toggles VSync")
	_expect(_has_key("fly", KEY_F1) and _has_key("perf_overlay", KEY_F3), "F1 flies and F3 shows the overlay")
	_expect(not _has_key("dash", KEY_SHIFT), "Shift does not dash")
	var keys: Dictionary = {}
	for action: String in InputSetup.KEYS:
		for key: Key in InputSetup.KEYS[action]:
			_expect(not keys.has(key), "key %s is bound twice (%s and %s)" % [key, keys.get(key, ""), action])
			keys[key] = action


static func _has_key(action: String, key: Key) -> bool:
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey and (event as InputEventKey).physical_keycode == key:
			return true
	return false


func _check_footsteps() -> void:
	m.controller.enabled = false
	m.player.global_position = Vector3(-30.0, 0.05, 0.0)
	var before: int = m.player.footsteps.steps_played
	m.player.wish = Vector3.RIGHT
	await m.get_tree().create_timer(2.0).timeout
	m.player.wish = Vector3.ZERO
	var steps: int = m.player.footsteps.steps_played - before
	print("SMOKE footsteps: %d steps in 2 s of walking" % steps)
	_expect(steps >= 2, "footsteps sound while walking (%d in 2 s)" % steps)


func _check_fly() -> void:
	var stand: Vector3 = m.player.global_position
	m.fly.toggle()
	_expect(m.fly.current and not m.hud.visible, "fly mode takes the camera and hides the HUD")
	Input.action_press("move_forward")
	await m.get_tree().create_timer(FLY_SECONDS).timeout
	Input.action_release("move_forward")
	_expect(m.fly.global_position.distance_to(m.camera_rig.camera.global_position) > 1.0, "fly mode flies")
	m.fly.toggle()
	_expect(m.camera_rig.camera.current and m.hud.visible, "leaving fly mode returns to the player's camera")
	_expect(m.player.global_position.distance_to(stand) < FLY_SECONDS, "the player waits where they were")
	m.controller.enabled = false


func _check_overlay() -> void:
	m.perf_overlay.toggle()
	var text: String = m.perf_overlay.text()
	_expect(m.perf_overlay.visible and text.contains("fps") and text.contains("Draw calls"), "the overlay reports")
	m.perf_overlay.toggle()


func _check_driver() -> void:
	var before: String = m.display.windows_driver()
	m.display.toggle_windows_driver()
	_expect(m.display.windows_driver() != before, "F10 switches the Windows renderer for the next start")
	m.display.toggle_windows_driver()
