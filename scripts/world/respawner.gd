class_name Respawner
extends Node
## Death and respawn, ARPG style and forgiving. When the player's health hits zero:
##   1. the fall (about a second): the creature collapses (CreatureFall) in slow motion;
##   2. the screen fades to dark with "EMBEROO FELL" (DeathScreen);
##   3. in the dark, the zone resets (WorldReset: the dead stay dead, the living go home,
##      summons vanish, a boss fight starts over) and the creature gets back up at the last
##      checkpoint reached in this zone (Checkpoint), full health, no Heat, full Aid;
##   4. the dark lifts and it bounds in (ZoneEntrance).
## No XP is lost. A level with no checkpoints (the test arena) respawns the player in place.
##
## Also puts the player at the saved checkpoint when a zone starts from a save.

## Engine time scale during the fall.
const SLOW_MOTION_SCALE := 0.35
## Real seconds of each beat.
const FALL_SECONDS := 0.7
const FADE_OUT_SECONDS := 0.35
const DARK_SECONDS := 0.45
const FADE_IN_SECONDS := 0.4

@export var death_screen: DeathScreen

## True from the fall until the player is back up.
var is_respawning: bool = false


func _ready() -> void:
	_watch_player.call_deferred()


func _exit_tree() -> void:
	if is_respawning:
		Engine.time_scale = 1.0


func _watch_player() -> void:
	var player := PlayerFinder.find(self) as Creature
	if player == null:
		return
	player.health.died.connect(_on_player_died.bind(player))
	_start_at_saved_checkpoint(player)


func _on_player_died(player: Creature) -> void:
	if is_respawning:
		return
	is_respawning = true
	var fall_spot := player.global_position
	CreatureFall.collapse(player, FALL_SECONDS)
	Engine.time_scale = SLOW_MOTION_SCALE
	await _real_seconds(FALL_SECONDS)
	Engine.time_scale = 1.0
	await death_screen.fade_out(FADE_OUT_SECONDS)
	await _real_seconds(DARK_SECONDS)
	WorldReset.after_player_fell(self)
	CreatureFall.get_up_at(player, _respawn_point(fall_spot))
	death_screen.fade_in(FADE_IN_SECONDS)
	is_respawning = false


## Where the creature gets back up: the last checkpoint reached in this zone, else the zone's
## start checkpoint, else where it fell.
func _respawn_point(fall_spot: Vector2) -> Vector2:
	var checkpoint := _current_checkpoint()
	return checkpoint.global_position if checkpoint != null else fall_spot


func _current_checkpoint() -> Checkpoint:
	var zone_start: Checkpoint = null
	for node in get_tree().get_nodes_in_group(Checkpoint.GROUP):
		var checkpoint := node as Checkpoint
		if checkpoint == null:
			continue
		if checkpoint.is_current():
			return checkpoint
		if checkpoint.is_zone_start:
			zone_start = checkpoint
	return zone_start


## A save made after reaching a checkpoint starts the zone there instead of at the spawn.
func _start_at_saved_checkpoint(player: Creature) -> void:
	var checkpoint := _current_checkpoint()
	if checkpoint != null and not checkpoint.is_zone_start:
		CreatureFall.bound_in_at(player, checkpoint.global_position)


func _real_seconds(seconds: float) -> Signal:
	return get_tree().create_timer(seconds, true, false, true).timeout
