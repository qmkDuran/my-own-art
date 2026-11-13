class_name SfxPlayer
extends Node3D
## Short effect sounds played where they happen: a small pool of 3D players and the effect sounds (synthesised
## once, see SoundSynth.effect) by name.

const POOL: int = 8

var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer3D] = []
var _next: int = 0


func _ready() -> void:
	name = "SfxPlayer"
	for index: int in POOL:
		var player := AudioStreamPlayer3D.new()
		add_child(player)
		_players.append(player)


func play(sound: String, at: Vector3) -> void:
	if not _streams.has(sound):
		_streams[sound] = SoundSynth.effect(sound)
	var player: AudioStreamPlayer3D = _players[_next]
	_next = (_next + 1) % _players.size()
	player.stream = _streams[sound]
	player.volume_db = Tuning.number("audio", sound, "volume_db")
	player.global_position = at
	player.play()
