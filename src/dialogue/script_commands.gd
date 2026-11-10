class_name ScriptCommands
extends RefCounted
## The "~ command" vocabulary of .dlg scripts. Each command is one small method; add new ones
## by writing a method and registering it in _init. Commands may be coroutines (awaited).
##
## Flow-control commands (if, goto, end) are handled by the Dialogue runner itself.

var _handlers: Dictionary = {}


func _init() -> void:
	_handlers = {
		"set": _set_flag,
		"unset": _unset_flag,
		"give": _give,
		"take": _take,
		"heal": _heal,
		"equip": _equip,
		"sfx": _sfx,
		"music": _music,
		"music_stop": _music_stop,
		"ambience": _ambience,
		"ambience_stop": _ambience_stop,
		"ambience_clear": _ambience_clear,
		"wait": _wait,
		"ambient": _ambient,
		"vignette": _vignette,
		"lights": _lights,
		"shake": _shake,
		"vanish": _vanish,
		"hide": _hide,
		"show": _show,
		"card": _card,
		"zone": _zone,
		"checkpoint": _checkpoint,
		"event": _event,
		"toast": _toast,
		"mute_all": _mute_all,
		"unmute_all": _unmute_all,
		"end_chapter": _end_chapter,
	}


func has_command(command: String) -> bool:
	return _handlers.has(command)


## Commands that take screen time; the dialogue box hides before running them.
func is_cinematic(command: String) -> bool:
	return command in ["card", "zone", "end_chapter"]


func execute(command: String, args: Array[String]) -> void:
	var handler: Callable = _handlers.get(command, Callable())
	if not handler.is_valid():
		push_error("Unknown dialogue command '~ %s'" % command)
		return
	await handler.call(args)


# --- State -------------------------------------------------------------------

func _set_flag(args: Array[String]) -> void:
	var value: Variant = true
	if args.size() > 1:
		value = parse_value(args[1])
	GameState.flags.set_flag(args[0], value)


func _unset_flag(args: Array[String]) -> void:
	GameState.flags.clear(args[0])


func _give(args: Array[String]) -> void:
	var item_id := args[0]
	GameState.inventory.add(item_id, _int_arg(args, 1, 1))
	Events.toast.emit("Got: %s" % String(DB.item(item_id).get("name", item_id)))
	AudioManager.play_sfx("pickup")


func _take(args: Array[String]) -> void:
	GameState.inventory.remove(args[0], _int_arg(args, 1, 1))


func _heal(args: Array[String]) -> void:
	GameState.heal(_int_arg(args, 0, 1))


func _equip(args: Array[String]) -> void:
	GameState.inventory.equip(args[0])


# --- Audio -------------------------------------------------------------------

func _sfx(args: Array[String]) -> void:
	AudioManager.play_sfx(args[0], _float_arg(args, 1, 0.0))


func _music(args: Array[String]) -> void:
	AudioManager.play_music(args[0], _float_arg(args, 1, 1.5))


func _music_stop(args: Array[String]) -> void:
	AudioManager.stop_music(_float_arg(args, 0, 1.5))


func _ambience(args: Array[String]) -> void:
	AudioManager.add_ambience(args[0], _float_arg(args, 1, -10.0), _float_arg(args, 2, 1.5))


func _ambience_stop(args: Array[String]) -> void:
	AudioManager.remove_ambience(args[0], _float_arg(args, 1, 1.5))


func _ambience_clear(args: Array[String]) -> void:
	AudioManager.set_ambience([], _float_arg(args, 0, 1.5))


## Total silence (every bus, UI included), e.g. the beat right after the vanishing.
func _mute_all(_args: Array[String]) -> void:
	AudioServer.set_bus_mute(0, true)


func _unmute_all(_args: Array[String]) -> void:
	AudioServer.set_bus_mute(0, false)


# --- Presentation --------------------------------------------------------------

func _wait(args: Array[String]) -> void:
	await Router.get_tree().create_timer(_float_arg(args, 0, 1.0)).timeout


func _ambient(args: Array[String]) -> void:
	var zone := _zone_node()
	if zone:
		zone.set_ambient(Color.from_string(args[0], Color.WHITE), _float_arg(args, 1, 1.0))


func _vignette(args: Array[String]) -> void:
	if Router.game:
		Router.game.set_vignette(_float_arg(args, 0, 0.5), _float_arg(args, 1, 1.0))


func _lights(args: Array[String]) -> void:
	var zone := _zone_node()
	if zone:
		zone.set_light_group(args[0], args[1] if args.size() > 1 else "off", _float_arg(args, 2, 0.6))


func _shake(args: Array[String]) -> void:
	Events.shake_requested.emit(_float_arg(args, 0, 4.0), _float_arg(args, 1, 0.4))


## Removes a character on the spot, leaving the clothes pile its zone entry declares ("leaves").
func _vanish(args: Array[String]) -> void:
	var zone := _zone_node()
	if zone:
		await zone.vanish_entity(args[0])


func _hide(args: Array[String]) -> void:
	GameState.flags.set_flag(ZoneEntityLink.gone_flag(args[0]))


func _show(args: Array[String]) -> void:
	GameState.flags.clear(ZoneEntityLink.gone_flag(args[0]))


func _card(args: Array[String]) -> void:
	await Router.show_card(args[0], GameState.substitute(args[1]) if args.size() > 1 else "", args[2] if args.size() > 2 else "")


func _zone(args: Array[String]) -> void:
	await Router.go_to_zone(args[0], args[1] if args.size() > 1 else "")


func _checkpoint(_args: Array[String]) -> void:
	var player_position: Variant = null
	if Router.game and Router.game.player:
		player_position = Router.game.player.global_position
	GameState.save_checkpoint(player_position)


func _event(args: Array[String]) -> void:
	Events.story_event.emit(args[0])


func _toast(args: Array[String]) -> void:
	Events.toast.emit(GameState.substitute(" ".join(args)))


func _end_chapter(args: Array[String]) -> void:
	GameState.chapter = _int_arg(args, 0, GameState.chapter + 1)
	GameState.save_checkpoint(GameState.spawn_position)
	await Router.return_to_menu()


# --- Helpers -----------------------------------------------------------------

func _zone_node() -> Zone:
	return Router.game.zone if Router.game else null


static func _int_arg(args: Array[String], index: int, fallback: int) -> int:
	return int(args[index]) if args.size() > index and args[index].is_valid_int() else fallback


static func _float_arg(args: Array[String], index: int, fallback: float) -> float:
	return float(args[index]) if args.size() > index and args[index].is_valid_float() else fallback


static func parse_value(text: String) -> Variant:
	if text == "true":
		return true
	if text == "false":
		return false
	if text.is_valid_int():
		return int(text)
	if text.is_valid_float():
		return float(text)
	return text
