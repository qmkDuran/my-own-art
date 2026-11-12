class_name Main
extends Node3D
## One match: builds the woods, the two creatures, the camera, the player's controls and senses, the bot's brain
## (with what it remembers of this player), the HUD, the match flow, the session log and the debug keys, and wires
## them together (dependencies are handed in here, not looked up). At the end of a fight the bot's memory is saved.

## The running match, for the automated tests and screenshots (the only global handle into a match).
static var current: Main
## Restart (and the tests) skip the start screen.
static var skip_intro: bool = false
## Where the bot's memory of the player lives; tests point it elsewhere.
static var memory_path: String = ""

var woods: Woods
var player: Creature
var bot: Creature
var rig: CameraRig
var sight: PlayerSight
var lock_on: LockOn
var controller: PlayerController
var brain: BotBrain
var hud: Hud
var flow: MatchFlow
var model: PlayerModel
var session_log: SessionLog
var markers: TacticalMarkers
var overlay: DebugOverlay


func _ready() -> void:
	current = self
	InputSetup.install()
	woods = Woods.new()
	woods.name = "Woods"
	add_child(woods)
	woods.build()
	player = _spawn("player", woods.player_spawn, woods.bot_spawn)
	bot = _spawn("bot", woods.bot_spawn, woods.player_spawn)
	player.opponent = bot
	player.see_through_cover = true
	bot.opponent = player
	_add_player_side()
	model = PlayerModel.new(memory_path if memory_path != "" else Tuning.ai["memory"]["path"])
	brain = BotBrain.new()
	add_child(brain)
	brain.setup(bot, player, woods, model)
	hud = Hud.new()
	add_child(hud)
	hud.setup(self)
	flow = MatchFlow.new()
	add_child(flow)
	flow.setup(player, bot)
	flow.phase_changed.connect(_on_phase)
	hud.watch_flow(flow)
	_add_tools()
	flow.begin(not skip_intro)


func _add_tools() -> void:
	session_log = SessionLog.new()
	add_child(session_log)
	session_log.setup(self)
	markers = TacticalMarkers.new()
	add_child(markers)
	markers.setup(brain.tactics)
	overlay = DebugOverlay.new()
	hud.add_overlay(overlay)
	overlay.setup(brain, markers)
	var keys := DevKeys.new()
	add_child(keys)
	keys.setup(overlay, brain)


func _on_phase(phase: MatchFlow.Phase) -> void:
	if phase == MatchFlow.Phase.WON or phase == MatchFlow.Phase.LOST:
		model.note_fight()
		model.save()


func _spawn(look_key: String, at: Vector3, facing: Vector3) -> Creature:
	var creature := Creature.new()
	var toward: Vector3 = facing - at
	creature.setup(look_key, at, atan2(-toward.x, -toward.z))
	add_child(creature)
	return creature


func _add_player_side() -> void:
	rig = CameraRig.new()
	add_child(rig)
	rig.setup(player)
	sight = PlayerSight.new()
	sight.setup(player, bot, rig)
	add_child(sight)
	lock_on = LockOn.new()
	lock_on.setup(player, bot, sight, rig)
	add_child(lock_on)
	controller = PlayerController.new()
	controller.setup(player, rig, lock_on)
	add_child(controller)
