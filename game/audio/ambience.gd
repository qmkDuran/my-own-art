class_name Ambience
extends Node3D
## The night's sound: now and then a single cricket somewhere out in the dark (sparse, quiet, never the same
## spot twice), the fountain trickling where it stands, a music box drifting from an upstairs window down Lamp
## Street, and rain that fades in and out with the weather.

const CHIRP_VARIANTS: int = 4

var _rain: AudioStreamPlayer
var _cricket: AudioStreamPlayer3D
var _chirps: Array[AudioStreamWAV] = []
var _next_chirp: float = 0.0
var _listener: Node3D


func setup(fountain: Node3D, listener: Node3D) -> void:
	name = "Ambience"
	_listener = listener
	for index: int in CHIRP_VARIANTS:
		_chirps.append(SoundSynth.cricket_chirp())
	_cricket = AudioStreamPlayer3D.new()
	_cricket.unit_size = Tuning.number("audio", "crickets", "unit_size")
	_cricket.max_distance = Tuning.number("audio", "crickets", "max_distance")
	_cricket.volume_db = Tuning.number("audio", "crickets", "volume_db")
	add_child(_cricket)
	_schedule_chirp()
	_placed(SoundSynth.trickle(), fountain.global_position, "trickle")
	_placed(SoundSynth.music_box(), Tuning.vec3(Tuning.doc("audio")["music"]["at"]), "music")
	_rain = _flat(SoundSynth.rain(), Tuning.number("audio", "rain", "fade_db"))
	set_rain(0.0)


func _process(delta: float) -> void:
	_next_chirp -= delta
	if _next_chirp > 0.0:
		return
	_schedule_chirp()
	var angle: float = randf() * TAU
	var distance: float = randf_range(Tuning.number("audio", "crickets", "distance_min"), Tuning.number("audio",
		"crickets", "distance_max"))
	_cricket.global_position = _listener.global_position + Vector3(cos(angle), 0.0, sin(angle)) * distance
	_cricket.stream = _chirps.pick_random()
	_cricket.play()


func _schedule_chirp() -> void:
	_next_chirp = randf_range(Tuning.number("audio", "crickets", "gap_min"), Tuning.number("audio", "crickets",
		"gap_max"))


func set_rain(mix: float) -> void:
	_rain.volume_db = lerpf(Tuning.number("audio", "rain", "fade_db"), Tuning.number("audio", "rain", "volume_db"),
		sqrt(mix))


func _flat(stream: AudioStream, volume: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume
	player.autoplay = true
	add_child(player)
	return player


func _placed(stream: AudioStream, at: Vector3, sound: String) -> void:
	var player := AudioStreamPlayer3D.new()
	player.stream = stream
	player.volume_db = Tuning.number("audio", sound, "volume_db")
	player.unit_size = Tuning.number("audio", sound, "unit_size")
	player.max_distance = Tuning.number("audio", sound, "max_distance")
	player.autoplay = true
	add_child(player)
	player.global_position = at
