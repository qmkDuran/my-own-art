class_name Reactions
extends RefCounted
## Element reactions, Project B's own twist on tag-team chaining (see PROJECT_B.md,
## "Element reactions"): when a hit of one element lands on an enemy carrying a status from
## another, the status is cashed in for a bonus effect. One table, one sentence each.
## What each reaction does lives in ReactionEffects.

const STEAM_BURST := "steam_burst"
const WILDFIRE := "wildfire"
const DROWN := "drown"
const KINDLING := "kindling"
const TOXIC_BLAZE := "toxic_blaze"

## In priority order: the first row that matches is the one that fires.
## status: what the enemy carries; element: the hit's element; name: what the chain guide
## calls it (never shown in combat); color: its burst and flash; consumes: whether the
## status ends. What each one does, in words and numbers, is ReactionEffects.describe.
const TABLE: Array[Dictionary] = [
	{"id": STEAM_BURST, "status": SetUp.SOAKED, "element": "Fire", "name": "Steam Burst", "color": ApolloPalette.WHITE, "consumes": true},
	{"id": DROWN, "status": SetUp.ROOTED, "element": "Tide", "name": "Drown", "color": ApolloPalette.SKY, "consumes": true},
	{"id": KINDLING, "status": SetUp.ROOTED, "element": "Fire", "name": "Kindling", "color": ApolloPalette.ORANGE, "consumes": true},
	{"id": WILDFIRE, "status": SetUp.BURNING, "element": "Bloom", "name": "Wildfire", "color": ApolloPalette.GOLD, "consumes": false},
	{"id": TOXIC_BLAZE, "status": SetUp.POISONED, "element": "Fire", "name": "Toxic Blaze", "color": ApolloPalette.GREEN_LIGHT, "consumes": true},
]
## A reaction's burst, flash and impact frame show at most once per this many physics
## frames, so a Signal Skill that sets off five Steam Bursts at once still reads as one beat.
const SHOW_GAP_FRAMES := 18

const REACTION_BURST_RADIUS := 34.0
## Light: a tint of the reaction's colour, not a white-out.
const REACTION_FLASH_ALPHA := 0.12

static var _last_shown_frame: Dictionary = {}


## The reaction a hit of `element` would set off on `target` right now ({} for none).
static func find_for(target: Node, element: String) -> Dictionary:
	if element.is_empty():
		return {}
	for reaction in TABLE:
		if reaction["element"] == element and SetUp.has(target, reaction["status"]):
			return reaction
	return {}


## The reaction a hit of `element` sets off on an enemy carrying `status_name` ({} for none),
## e.g. Tide on Rooted is Drown. The chain guide uses it to name each Signal Skill's payoff.
static func find_for_status(status_name: String, element: String) -> Dictionary:
	for reaction in TABLE:
		if reaction["element"] == element and reaction["status"] == status_name:
			return reaction
	return {}


## Sets `reaction` off on the enemy with `target_health` (already hit by `attacker`).
static func trigger(reaction: Dictionary, attacker: Node2D, target_health: Health) -> void:
	var target := target_health.get_parent() as Node2D
	if target == null or not attacker.is_inside_tree():
		return
	if reaction["consumes"]:
		SetUp.consume(target, reaction["status"])
	var is_shown := _claim_show(reaction["id"])
	ReactionEffects.play(reaction["id"], attacker, target_health, is_shown)
	if is_shown:
		var color: Color = reaction["color"]
		HitFeel.burst(target.get_parent(), target.global_position, color, REACTION_BURST_RADIUS)
		ScreenFlash.play(attacker, color, REACTION_FLASH_ALPHA)
	LinkMeter.add_from(attacker, LinkMeter.PER_REACTION)


static func _claim_show(reaction_id: String) -> bool:
	var now := Engine.get_physics_frames()
	var last: int = _last_shown_frame.get(reaction_id, -SHOW_GAP_FRAMES)
	if now - last < SHOW_GAP_FRAMES:
		return false
	_last_shown_frame[reaction_id] = now
	return true
