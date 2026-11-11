extends Node
## Audio (autoload "Audio"). All sounds are procedural (art/audio/synth.py, CC0, made for this game). Music
## cross-fades between the exploring score and the boss score. A hard limiter on the master bus keeps stacked
## hits clean, and copies of a sound already playing are quieter and capped.

const DIR: String = "res://audio/"
const LIMIT_DB: float = -1.0
const DUCK_DB: float = 3.0
const MAX_COPIES: int = 4

var _music: AudioStreamPlayer
var _music_name: String = ""
var _playing: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var limiter := AudioEffectHardLimiter.new()
	limiter.ceiling_db = LIMIT_DB
	AudioServer.add_bus_effect(0, limiter)


func _stream(sound: String, ext: String) -> AudioStream:
	var path: String = DIR + sound + ext
	return load(path) as AudioStream if ResourceLoader.exists(path) else null


func play_music(sound: String, fade: float = 2.0) -> void:
	if sound == _music_name:
		return
	if _music != null:
		var old: AudioStreamPlayer = _music
		var out := create_tween()
		out.tween_property(old, "volume_db", -60.0, fade)
		out.tween_callback(old.queue_free)
	_music_name = sound
	var s: AudioStream = _stream(sound, ".ogg")
	if s == null:
		return
	(s as AudioStreamOggVorbis).loop = true
	_music = AudioStreamPlayer.new()
	_music.stream = s
	_music.volume_db = -60.0
	add_child(_music)
	_music.play()
	create_tween().tween_property(_music, "volume_db", float(GameData.setting("music_volume_db", -10.0)), fade)


func sfx(sound: String, volume_db: float = -8.0, pitch: float = 1.0) -> void:
	var copies: int = int(_playing.get(sound, 0))
	if copies >= MAX_COPIES:
		return
	var s: AudioStream = _stream(sound, ".wav")
	if s == null:
		return
	_playing[sound] = copies + 1
	var p := AudioStreamPlayer.new()
	p.stream = s
	p.volume_db = volume_db - DUCK_DB * copies + float(GameData.setting("sfx_volume_db", 0.0))
	p.pitch_scale = pitch
	add_child(p)
	p.finished.connect(func() -> void:
		_playing[sound] = maxi(0, int(_playing.get(sound, 1)) - 1)
		p.queue_free())
	p.play()
