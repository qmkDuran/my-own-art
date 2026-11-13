class_name SfxPlayer
extends Node3D
## Short effect sounds played where they happen: a pool of 3D players and the sounds by name, either synthesised
## once (SoundSynth.effect) or loaded from the CC0 files in data/audio.json. A cue (data/audio.json "cues") layers
## several sounds, each with its own level, pitch, random pitch jitter and delay, so one ability sounds rich.

const POOL: int = 28

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer3D] = []
var _next: int = 0


func _ready() -> void:
	name = "SfxPlayer"
	for index: int in POOL:
		var player := AudioStreamPlayer3D.new()
		player.unit_size = Tuning.number("audio", "sfx_space", "unit_size")
		player.max_distance = Tuning.number("audio", "sfx_space", "max_distance")
		add_child(player)
		_players.append(player)


## A layered cue from data/audio.json "cues".
func cue(name_of_cue: String, at: Vector3) -> void:
	for layer: Dictionary in Tuning.doc("audio")["cues"][name_of_cue]:
		var pitch: float = float(layer["pitch"]) * (1.0 + randf_range(-1.0, 1.0) * float(layer["jitter"]))
		var delay: float = layer["delay"]
		if delay > 0.0:
			get_tree().create_timer(delay, false).timeout.connect(_start.bind(layer["sound"], at, float(layer["db"]),
				pitch))
		else:
			_start(layer["sound"], at, float(layer["db"]), pitch)


## The levels every cue layer uses (for the audio level checks).
static func cue_levels() -> Array[float]:
	var out: Array[float] = []
	for cue_layers: Array in Tuning.doc("audio")["cues"].values():
		for layer: Dictionary in cue_layers:
			out.append(float(layer["db"]))
	return out


func stream(sound: String) -> AudioStream:
	if not _streams.has(sound):
		var files: Dictionary = Tuning.doc("audio")["files"]
		_streams[sound] = load(files[sound]) if files.has(sound) else SoundSynth.effect(sound)
	return _streams[sound]


func _start(sound: String, at: Vector3, volume: float, pitch: float) -> void:
	var player: AudioStreamPlayer3D = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = stream(sound)
	player.volume_db = volume
	player.pitch_scale = pitch
	player.global_position = at
	player.play()
