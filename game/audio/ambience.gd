class_name Ambience
extends Node3D
## The night's sound: crickets everywhere, the fountain trickling where it stands, a music box drifting from an
## upstairs window down Lamp Street, and rain that fades in and out with the weather.

var _rain: AudioStreamPlayer


func setup(fountain: Node3D) -> void:
	name = "Ambience"
	_flat(SoundSynth.crickets(), Tuning.number("audio", "crickets", "volume_db"))
	_placed(SoundSynth.trickle(), fountain.global_position, "trickle")
	_placed(SoundSynth.music_box(), Tuning.vec3(Tuning.doc("audio")["music"]["at"]), "music")
	_rain = _flat(SoundSynth.rain(), Tuning.number("audio", "rain", "fade_db"))
	set_rain(0.0)


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
