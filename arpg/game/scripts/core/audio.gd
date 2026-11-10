extends Node
## Small audio manager (autoload "Audio"). Music lives here so it can cross-fade between scenes;
## ambience loops are created as children of the scene that owns them, so they stop with it.
## All sounds are original procedural audio (art/audio/synth.py, CC0).

const DIR: String = "res://audio/"
const MASTER_DB: float = 2.0
const LIMIT_DB: float = -1.0            # a hard limiter on the master bus keeps stacked hits under 0 dBFS
const DUCK_DB: float = 3.5              # each copy of a sound already playing makes the next one quieter
const MAX_COPIES: int = 4

var _music: AudioStreamPlayer
var _music_name: String = ""
var _music_target_db: float = -10.0
var _playing: Dictionary = {}           # sound -> copies playing


func _ready() -> void:
	AudioServer.set_bus_volume_db(0, MASTER_DB)
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = LIMIT_DB
	AudioServer.add_bus_effect(0, limiter)


func _loop_stream(sound: String) -> AudioStream:
	var s := load(DIR + sound + ".ogg") as AudioStreamOggVorbis
	s.loop = true
	return s


## Start (or keep) a music loop, cross-fading from whatever played before.
func play_music(sound: String, volume_db: float = -10.0, fade: float = 1.5) -> void:
	_music_target_db = volume_db
	if sound == _music_name and _music != null:
		set_music_volume(volume_db, fade)
		return
	if _music != null:
		var old: AudioStreamPlayer = _music
		var out := create_tween()
		out.tween_property(old, "volume_db", -60.0, fade)
		out.tween_callback(old.queue_free)
	_music_name = sound
	_music = AudioStreamPlayer.new()
	_music.stream = _loop_stream(sound)
	_music.volume_db = -60.0
	add_child(_music)
	_music.play()
	create_tween().tween_property(_music, "volume_db", volume_db, fade)


## Temporarily move the music level (e.g. duck under the worship hymn); restore with restore_music().
func set_music_volume(volume_db: float, fade: float = 1.0) -> void:
	if _music != null:
		create_tween().tween_property(_music, "volume_db", volume_db, fade)


func restore_music(fade: float = 1.5) -> void:
	set_music_volume(_music_target_db, fade)


## A looping ambience owned by `owner_node` (freed with its scene).
func loop_player(owner_node: Node, sound: String, volume_db: float) -> AudioStreamPlayer:
	var p := AudioStreamPlayer.new()
	p.stream = _loop_stream(sound)
	p.volume_db = volume_db
	owner_node.add_child(p)
	p.play()
	return p


## A one-shot sound; the player frees itself when done. Copies of the same sound are ducked and capped.
func sfx(sound: String, volume_db: float = -8.0, pitch: float = 1.0, delay: float = 0.0) -> void:
	var copies: int = int(_playing.get(sound, 0))
	if copies >= MAX_COPIES:
		return
	_playing[sound] = copies + 1
	var p := AudioStreamPlayer.new()
	p.stream = load(DIR + sound + ".wav") as AudioStream
	p.volume_db = volume_db - DUCK_DB * copies
	p.pitch_scale = pitch
	add_child(p)
	p.finished.connect(func() -> void:
		_playing[sound] = maxi(0, int(_playing.get(sound, 1)) - 1)
		p.queue_free())
	if delay > 0.0:
		get_tree().create_timer(delay).timeout.connect(p.play)
	else:
		p.play()
