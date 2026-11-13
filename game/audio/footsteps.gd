class_name Footsteps
extends Node3D
## Footsteps for a walking character: each time a foot comes down in the walk or run clip (the plant moments its
## CharacterModel measured), a step sounds at the feet, of the surface underfoot (cobbles, the bridge, the grass
## of the meadow), picked from a few variants with a little random pitch and loudness, louder when running.

const MOVING: Array[String] = ["walk", "run"]

static var _streams: Dictionary = {}

var _model: CharacterModel
var _level: float = 0.0
var _player: AudioStreamPlayer3D
var _last_position: float = -1.0
var steps_played: int = 0


func setup(model: CharacterModel, level_db: float) -> void:
	name = "Footsteps"
	_model = model
	_level = level_db
	_player = AudioStreamPlayer3D.new()
	_player.unit_size = Tuning.number("audio", "steps", "unit_size")
	_player.max_distance = Tuning.number("audio", "steps", "max_distance")
	_player.max_polyphony = 2
	add_child(_player)


func _process(_delta: float) -> void:
	var clip: String = _model.current_clip()
	if not MOVING.has(clip) or not _model.animator.is_playing():
		_last_position = -1.0
		return
	var now: float = _model.animator.current_animation_position
	if _last_position >= 0.0:
		for moment: float in _model.plant_times(clip):
			if _crossed(_last_position, now, moment):
				_step(clip)
				break
	_last_position = now


## True when playback went past a moment since the last frame (the clip may have looped around).
static func _crossed(before: float, now: float, moment: float) -> bool:
	if now >= before:
		return moment > before and moment <= now
	return moment > before or moment <= now


func _step(clip: String) -> void:
	var surface: String = Blocks.surface_at(get_world_3d(), global_position)
	var spec: Dictionary = Tuning.doc("audio")["steps"]
	var jitter: float = float(spec["db_jitter"])
	_player.stream = variant(surface)
	_player.volume_db = _level + randf_range(-jitter, jitter) + (float(spec["run_db"]) if clip == "run" else 0.0)
	_player.pitch_scale = 1.0 + randf_range(-1.0, 1.0) * float(spec["pitch_jitter"])
	_player.play()
	steps_played += 1


## One of the synthesised variants of a surface's step (made once, shared by everyone).
static func variant(surface: String) -> AudioStreamWAV:
	if not _streams.has(surface):
		var made: Array[AudioStreamWAV] = []
		for index: int in int(Tuning.number("audio", "steps", "variants")):
			made.append(SoundSynth.footstep(surface))
		_streams[surface] = made
	return (_streams[surface] as Array).pick_random()
