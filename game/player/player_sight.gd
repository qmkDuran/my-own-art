class_name PlayerSight
extends Node
## What the player can perceive of the bot, by the same visibility rules the bot uses (range, line of sight, hidden
## in a bush unless very close) plus "on screen". Drives the bot's life bar, the lock-on, the player's awareness
## (for ambush rules) and the rustle cue: an unseen bot moving close by always gives itself away. Seeing it takes a
## clear line both from the creature's eyes and from the camera, so a bot hidden from your view stays hidden.

var sees_bot: bool = false
var rustling: bool = false
var rustle_from: Vector3 = Vector3.ZERO
var _player: Creature
var _bot: Creature
var _rig: CameraRig
var _since_seen: float = INF


func setup(player: Creature, bot: Creature, rig: CameraRig) -> void:
	_player = player
	_bot = bot
	_rig = rig
	name = "PlayerSight"


func _physics_process(delta: float) -> void:
	sees_bot = can_see_bot()
	_since_seen = 0.0 if sees_bot else _since_seen + delta
	_player.aware_of_opponent = _since_seen <= Tuning.f("stealth", "unaware_memory")
	var distance: float = _player.global_position.distance_to(_bot.global_position)
	rustling = not sees_bot and not _bot.is_dead() and distance <= Tuning.f("player_view", "rustle_distance") \
			and _bot.horizontal_speed() >= Tuning.f("player_view", "rustle_min_speed")
	rustle_from = _bot.global_position


func can_see_bot() -> bool:
	if _bot.is_dead():
		return false
	var distance: float = _player.eye_position().distance_to(_bot.chest_position())
	if distance > Tuning.f("player_view", "sight_range"):
		return false
	if _bot.stealth.is_hidden() and distance > Tuning.f("stealth", "reveal_distance"):
		return false
	if not _rig.camera.is_position_in_frustum(_bot.chest_position()):
		return false
	var world: World3D = _player.get_world_3d()
	var from_eyes: bool = Sight.clear(world, _player.eye_position(), _bot.chest_position())
	return from_eyes and Sight.clear(world, _rig.camera.global_position, _bot.chest_position())
