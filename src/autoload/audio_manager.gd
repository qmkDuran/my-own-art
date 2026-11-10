extends Node
## Music (crossfaded), ambience layers and one-shot SFX, all addressed by name.
## Names resolve to files anywhere under res://audio/ (any of .ogg/.wav/.mp3):
##   "door_open" -> res://audio/**/door_open.wav
##   "footstep_wood" -> a random one of footstep_wood_01.., when no exact match exists.
## A missing name is logged once and ignored, so the game runs before the audio exists.

const AUDIO_ROOT := "res://audio/"
const EXTENSIONS: Array[String] = ["ogg", "wav", "mp3"]
const SILENT_DB := -60.0
const SFX_VOICES := 10
const BUSES: Array[String] = ["Music", "Ambience", "SFX"]

var _index: Dictionary = {}          # name -> Array[String] of paths
var _missing_logged: Dictionary = {}
var _music_players: Array[AudioStreamPlayer] = []
var _active_music := 0
var _music_name := ""
var _ambience: Dictionary = {}       # name -> AudioStreamPlayer
var _sfx_players: Array[AudioStreamPlayer] = []
var _next_sfx := 0
var _tweens: Dictionary = {}         # AudioStreamPlayer -> Tween (one fade per player)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_create_buses()
	_build_index(AUDIO_ROOT)
	for i in 2:
		_music_players.append(_make_player("Music", true))
	for i in SFX_VOICES:
		_sfx_players.append(_make_player("SFX", false))


## Stops everything now; call a few frames before quitting so the audio server releases its
## playbacks cleanly (Router.quit_game does this).
func shutdown() -> void:
	_music_name = ""
	_ambience.clear()
	_exit_tree()


## Stops and releases every stream on shutdown so nothing is left playing (or leaked) at exit.
func _exit_tree() -> void:
	for child: Node in get_children():
		if child is AudioStreamPlayer:
			(child as AudioStreamPlayer).stop()
			(child as AudioStreamPlayer).stream = null


# --- Music -------------------------------------------------------------------

func play_music(track: String, fade: float = 1.5, volume_db: float = -6.0) -> void:
	if track == _music_name:
		return
	var stream := _stream(track)
	_fade_out(_music_players[_active_music], fade)
	_music_name = track
	if stream == null:
		return
	_active_music = 1 - _active_music
	var player := _music_players[_active_music]
	player.stream = stream
	player.volume_db = SILENT_DB
	player.play()
	_fade_to(player, volume_db, fade)


func stop_music(fade: float = 1.5) -> void:
	_music_name = ""
	_fade_out(_music_players[_active_music], fade)


func current_music() -> String:
	return _music_name


# --- Ambience ----------------------------------------------------------------

func add_ambience(layer: String, volume_db: float = -10.0, fade: float = 2.0) -> void:
	if _ambience.has(layer):
		_fade_to(_ambience[layer], volume_db, fade)
		return
	var stream := _stream(layer)
	if stream == null:
		return
	var player := _make_player("Ambience", true)
	player.stream = stream
	player.volume_db = SILENT_DB
	player.play()
	_ambience[layer] = player
	_fade_to(player, volume_db, fade)


func remove_ambience(layer: String, fade: float = 2.0) -> void:
	if not _ambience.has(layer):
		return
	var player: AudioStreamPlayer = _ambience[layer]
	_ambience.erase(layer)
	_fade_out(player, fade, true)


## Keeps only the given layers playing (adds missing ones, fades out the rest).
func set_ambience(layers: Array, fade: float = 2.0) -> void:
	for layer: String in _ambience.keys():
		if not layers.has(layer):
			remove_ambience(layer, fade)
	for layer: Variant in layers:
		add_ambience(String(layer), -10.0, fade)


func ambience_layers() -> Array:
	return _ambience.keys()


# --- SFX ---------------------------------------------------------------------

func play_sfx(sound: String, volume_db: float = 0.0, pitch_jitter: float = 0.0) -> void:
	if sound.is_empty():
		return
	var stream := _stream(sound)
	if stream == null:
		return
	var player := _sfx_players[_next_sfx]
	_next_sfx = (_next_sfx + 1) % _sfx_players.size()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	player.play()


func has_sound(sound: String) -> bool:
	return not _paths_for(sound).is_empty()


# --- Internals ---------------------------------------------------------------

func _stream(sound: String) -> AudioStream:
	var paths := _paths_for(sound)
	if paths.is_empty():
		_log_missing_once(sound)
		return null
	var stream: AudioStream = load(paths.pick_random())
	if stream == null:
		_log_missing_once(sound)
	return stream


func _paths_for(sound: String) -> Array:
	if _index.has(sound):
		return _index[sound]
	var variants: Array = []
	for key: String in _index.keys():
		if _is_numbered_variant(key, sound):
			variants.append_array(_index[key])
	if not variants.is_empty():
		_index[sound] = variants
	return variants


static func _is_numbered_variant(key: String, base: String) -> bool:
	return key.begins_with(base + "_") and key.substr(base.length() + 1).is_valid_int()


func _build_index(dir_path: String) -> void:
	var dir := DirAccess.open(dir_path)
	if dir == null:
		return
	for sub: String in dir.get_directories():
		_build_index(dir_path.path_join(sub))
	for file: String in dir.get_files():
		var clean := file.trim_suffix(".import").trim_suffix(".remap")
		if not EXTENSIONS.has(clean.get_extension().to_lower()):
			continue
		var sound := clean.get_basename()
		var path := dir_path.path_join(clean)
		var list: Array = _index.get(sound, [])
		if not list.has(path):
			list.append(path)
		_index[sound] = list


func _log_missing_once(sound: String) -> void:
	if _missing_logged.has(sound):
		return
	_missing_logged[sound] = true
	print("[Audio] Missing sound '%s' (no file under %s); continuing silently." % [sound, AUDIO_ROOT])


func _make_player(bus: String, looping: bool) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.bus = bus
	if looping:
		player.finished.connect(player.play)
	add_child(player)
	return player


func _fade_to(player: AudioStreamPlayer, volume_db: float, duration: float) -> void:
	var tween := _new_tween(player)
	tween.tween_property(player, "volume_db", volume_db, maxf(duration, 0.01))


func _fade_out(player: AudioStreamPlayer, duration: float, free_after: bool = false) -> void:
	if not player.playing:
		if free_after:
			player.queue_free()
		return
	var tween := _new_tween(player)
	tween.tween_property(player, "volume_db", SILENT_DB, maxf(duration, 0.01))
	tween.tween_callback(player.stop)
	if free_after:
		tween.tween_callback(player.queue_free)


func _new_tween(player: AudioStreamPlayer) -> Tween:
	var previous: Tween = _tweens.get(player)
	if previous and previous.is_valid():
		previous.kill()
	var tween := create_tween()
	_tweens[player] = tween
	return tween


func _create_buses() -> void:
	for bus_name: String in BUSES:
		if AudioServer.get_bus_index(bus_name) != -1:
			continue
		AudioServer.add_bus()
		var index := AudioServer.bus_count - 1
		AudioServer.set_bus_name(index, bus_name)
		AudioServer.set_bus_send(index, "Master")
