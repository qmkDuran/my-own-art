extends Node
## Music and sound effects (autoload `Audio`). Every sound is a code-made file in res://audio (see
## art/audio/synth.py); music loops, effects play on a small pool of players so they can overlap.

const DIR: String = "res://audio/"
const POOL: int = 6
const MUSIC_DB: float = -8.0
const SFX_DB: float = -4.0
const FADE: float = 0.4

var _music: AudioStreamPlayer
var _track: String = ""
var _pool: Array[AudioStreamPlayer] = []
var _next: int = 0
var _cache: Dictionary = {}


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.volume_db = MUSIC_DB
	add_child(_music)
	for i: int in POOL:
		var p := AudioStreamPlayer.new()
		p.volume_db = SFX_DB
		add_child(p)
		_pool.append(p)


func _stream(name: String) -> AudioStream:
	if not _cache.has(name):
		var path: String = DIR + name + ".wav"
		_cache[name] = load(path) if ResourceLoader.exists(path) else null
	return _cache[name]


func music(track: String) -> void:
	if track == _track:
		return
	_track = track
	var s: AudioStream = _stream("music_" + track)
	if s is AudioStreamWAV:
		(s as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
		(s as AudioStreamWAV).loop_end = (s as AudioStreamWAV).data.size() / 2
	_music.stream = s
	_music.volume_db = MUSIC_DB
	if s != null:
		_music.play()


func current_track() -> String:
	return _track


func sfx(name: String) -> void:
	var s: AudioStream = _stream("sfx_" + name)
	if s == null:
		return
	var p: AudioStreamPlayer = _pool[_next]
	_next = (_next + 1) % POOL
	p.stream = s
	p.play()
