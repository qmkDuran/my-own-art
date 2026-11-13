class_name PlayerSight
extends Node
## What the player can perceive of the bot, by exactly the rules the bot uses (Visibility: range, line of sight,
## concealment, burrowed or submerged, sense reveals) plus "on screen". A concealed bot is not drawn at all, so a
## hidden bot is truly invisible until a sense move reveals it. Drives the bot's life bar, the lock-on and the
## player's awareness (for the ambush rule). Seeing it takes a clear line from the creature's eyes and the camera.

var sees_bot: bool = false
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
	_bot.model.visible = _bot.is_dead() or not Visibility.hides(_bot, distance, null)


func can_see_bot() -> bool:
	if _bot.is_dead():
		return false
	var distance: float = _player.eye_position().distance_to(_bot.chest_position())
	if distance > Visibility.sight_range(_player, Tuning.f("player_view", "sight_range")):
		return false
	if Visibility.hides(_bot, distance, null):
		return false
	if not _rig.camera.is_position_in_frustum(_bot.chest_position()):
		return false
	var world: World3D = _player.get_world_3d()
	var from_eyes: bool = Sight.clear(world, _player.eye_position(), _bot.chest_position())
	return from_eyes and Sight.clear(world, _rig.camera.global_position, _bot.chest_position())
