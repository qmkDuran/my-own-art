extends Node
## Moving between zones (registered as the "ZoneTravel" autoload). A ZoneExit asks for a trip;
## this fades the screen to dark, loads the target zone and puts Emberoo at its ZoneEntry
## with the zone-entrance hop, then fades back in.
##
## How Emberoo ends up at the entry: before the zone loads, the entry becomes the last
## checkpoint reached (Checkpoints), so arriving somewhere is also where you get back up
## after a fall, and the new zone's Respawner bounds Emberoo in onto it as it does for a
## loaded save. Every zone has its own GameLayer (HUD, screens, respawner) and the autoloads
## keep the progress, so the zone is simply swapped; the Trainer's Aid charges are carried
## over by hand (they live on the player). The game is saved once the new zone is in.

## Fired once the new zone is in and the screen starts to clear.
signal arrived(zone_path: String, entry_id: String)

## Seconds the screen takes to go dark, and to come back.
const FADE_OUT_SECONDS := 0.35
const FADE_IN_SECONDS := 0.4
## Above the HUD and every screen (the death screen is layer 4).
const CURTAIN_LAYER := 20

## True from the start of the fade-out until the new zone is showing.
var is_travelling: bool = false

var _curtain: ColorRect


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var layer := CanvasLayer.new()
	layer.layer = CURTAIN_LAYER
	add_child(layer)
	_curtain = ColorRect.new()
	_curtain.color = Color(ApolloPalette.OUTLINE, 0.0)
	_curtain.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(_curtain)
	_curtain.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


## Takes Emberoo to the entry `entry_id` (a ZoneEntry's `checkpoint_id`) of the zone scene at
## `zone_path`. Ignored while a trip is already under way or if the zone doesn't exist.
func travel(zone_path: String, entry_id: String) -> void:
	if is_travelling or not ResourceLoader.exists(zone_path):
		return
	is_travelling = true
	var aid_data := _carried_aid_data()
	var tree := get_tree()
	tree.paused = true  # nothing moves or hits while the screen goes dark
	await _fade_to(1.0, FADE_OUT_SECONDS)
	Checkpoints.reach(zone_path, entry_id)
	tree.paused = false
	tree.change_scene_to_file(zone_path)
	await tree.scene_changed
	# One more frame, so the Respawner's deferred start has put Emberoo on the entry.
	await tree.process_frame
	_give_aid_data(aid_data)
	SaveGame.save_now()
	arrived.emit(zone_path, entry_id)
	await _fade_to(0.0, FADE_IN_SECONDS)
	is_travelling = false


func _fade_to(alpha: float, seconds: float) -> Signal:
	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(_curtain, "color:a", alpha, seconds)
	return tween.finished


func _carried_aid_data() -> Dictionary:
	var aid := PlayerFinder.find_component(self, TrainerAid.NODE_NAME) as TrainerAid
	return aid.to_save_data() if aid != null else {}


func _give_aid_data(data: Dictionary) -> void:
	var aid := PlayerFinder.find_component(self, TrainerAid.NODE_NAME) as TrainerAid
	if aid != null and not data.is_empty():
		aid.load_save_data(data)
