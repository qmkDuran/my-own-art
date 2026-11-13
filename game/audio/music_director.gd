class_name MusicDirector
extends Node
## The music, by game state (data/music.json): the cozy-spooky town theme in town, an adventurous track while
## exploring the mission, the whimsical-intense combat track while enemies are engaged (a little louder for the
## boss). A state change crossfades: each track's loudness glides (in linear amplitude, so the blend stays even)
## to its target over the crossfade time; tracks that are silent stop, and a track coming back starts again.

const SILENT: float = 0.0

var state: String = ""
var _players: Dictionary = {}
var _targets: Dictionary = {}
var _levels: Dictionary = {}
var _boost: float = 0.0


func setup() -> void:
	name = "MusicDirector"
	process_mode = Node.PROCESS_MODE_ALWAYS
	var tracks: Dictionary = Tuning.doc("music")["tracks"]
	for track: String in tracks:
		var player := AudioStreamPlayer.new()
		var music: AudioStream = load(tracks[track]["path"])
		if music is AudioStreamOggVorbis:
			(music as AudioStreamOggVorbis).loop = true
		player.stream = music
		player.volume_db = float(Tuning.doc("music")["silent_db"])
		add_child(player)
		_players[track] = player
		_targets[track] = SILENT
		_levels[track] = SILENT
	set_state("town")


## town, explore, combat or boss.
func set_state(new_state: String) -> void:
	if new_state == state:
		return
	state = new_state
	var playing: String = Tuning.doc("music")["states"][state]
	_boost = float(Tuning.doc("music")["boss_boost_db"]) if state == "boss" else 0.0
	for track: String in _players:
		_targets[track] = 1.0 if track == playing else SILENT
		var player: AudioStreamPlayer = _players[track]
		if track == playing and not player.playing:
			player.play()


## Each track's current loudness as a share of its full level (0..1), for the crossfade checks.
func levels() -> Dictionary:
	return _levels.duplicate()


## The dB level a track plays at when it is the one playing.
func full_db(track: String) -> float:
	return float(Tuning.doc("music")["tracks"][track]["volume_db"]) + (_boost if Tuning.doc("music")["states"].get(
		state, "") == track else 0.0)


func _process(delta: float) -> void:
	var step: float = delta / float(Tuning.doc("music")["crossfade_seconds"])
	for track: String in _players:
		var player: AudioStreamPlayer = _players[track]
		_levels[track] = move_toward(float(_levels[track]), float(_targets[track]), step)
		player.volume_db = _db_for(track, float(_levels[track]))
		if float(_levels[track]) == SILENT and player.playing:
			player.stop()


func _db_for(track: String, share: float) -> float:
	var silent: float = float(Tuning.doc("music")["silent_db"])
	if share <= SILENT:
		return silent
	return maxf(linear_to_db(share * db_to_linear(full_db(track))), silent)
