class_name EmberTreeData
extends RefCounted
## What is in Emberoo's Ember Tree: its branches and nodes (see DESIGN.md, "Build system").
##
## Content only. Add, move or reword nodes here without touching the rules (EmberTree)
## or the screen (EmberTreeScreen). Each branch is a direction out from Emberoo; nodes
## further out need a node closer in. Inner ring = Stage 1, middle = Stage 2, outer = Stage 3.

const Kind := EmberTreeNode.Kind

## Each branch's direction from the centre, in degrees (0 = right, -90 = up).
const BRANCHES := {
	"inferno": {"title": "Inferno", "theme": "Burn", "angle": -90.0},
	"flurry": {"title": "Flurry", "theme": "Speed and combos", "angle": 30.0},
	"bruiser": {"title": "Bruiser", "theme": "Tough", "angle": 150.0},
}

## Siblings on the same tier fan out this many degrees either side of their branch.
const SPREAD_NEAR := 20.0
const SPREAD_FAR := 15.0

const NODE_ROWS := [
	# --- Inferno: set things on fire and let it spread -------------------------
	{"id": "searing_jab", "branch": "inferno", "stage": 1, "tier": 0, "kind": Kind.SKILL, "icon": "flame",
		"title": "Searing Jab", "text": "Your jabs set enemies alight. Burning foes keep taking damage for a few seconds after you move on."},
	{"id": "hot_knuckles", "branch": "inferno", "stage": 1, "tier": 1, "angle": -SPREAD_NEAR, "kind": Kind.STAT, "icon": "fist",
		"requires": ["searing_jab"], "stats": {EmberTreeEffects.JAB_DAMAGE: 1},
		"title": "Hot Knuckles", "text": "+1 Power. Every jab hits one point harder, so small foes go down in fewer punches."},
	{"id": "flame_uppercut", "branch": "inferno", "stage": 1, "tier": 1, "angle": SPREAD_NEAR, "kind": Kind.SKILL, "icon": "up",
		"requires": ["searing_jab"],
		"title": "Flame Uppercut", "text": "A rising punch that bursts into flame, hitting everything in a small arc in front of you."},
	{"id": "kindling", "branch": "inferno", "stage": 1, "tier": 2, "angle": -SPREAD_FAR, "kind": Kind.STAT, "icon": "spark",
		"requires": ["hot_knuckles"],
		"title": "Kindling", "text": "Burns last twice as long, so you can light a crowd and dance away while it smoulders."},
	{"id": "wildfire", "branch": "inferno", "stage": 1, "tier": 2, "angle": SPREAD_FAR, "kind": Kind.UPGRADE, "icon": "wave",
		"requires": ["flame_uppercut"],
		"title": "Wildfire", "text": "Flame Uppercut upgrade. An enemy that dies while burning passes its flames to the nearest foe."},

	# --- Flurry: be fast, chain punches ---------------------------------------
	{"id": "spinning_hook", "branch": "flurry", "stage": 1, "tier": 0, "kind": Kind.SKILL, "icon": "swirl",
		"title": "Spinning Hook", "text": "Every third jab in a chain becomes a spinning hook that hits all around you."},
	{"id": "quick_hands", "branch": "flurry", "stage": 1, "tier": 1, "angle": -SPREAD_NEAR, "kind": Kind.STAT, "icon": "hands",
		"requires": ["spinning_hook"], "stats": {EmberTreeEffects.JAB_RECOVERY_CUT: 0.08},
		"title": "Quick Hands", "text": "You recover from each jab sooner, so punches chain together noticeably faster."},
	{"id": "ember_hop", "branch": "flurry", "stage": 1, "tier": 1, "angle": SPREAD_NEAR, "kind": Kind.SKILL, "icon": "hop",
		"requires": ["spinning_hook"],
		"title": "Ember Hop", "text": "Your dodge leaves a short trail of fire that burns anything that follows you through it."},
	{"id": "light_feet", "branch": "flurry", "stage": 1, "tier": 2, "angle": -SPREAD_FAR, "kind": Kind.STAT, "icon": "boot",
		"requires": ["quick_hands"], "stats": {EmberTreeEffects.MOVE_SPEED: 12.0},
		"title": "Light Feet", "text": "+Speed. Emberoo runs clearly faster, easy to pick fights and to leave them."},
	{"id": "spring_legs", "branch": "flurry", "stage": 1, "tier": 2, "angle": SPREAD_FAR, "kind": Kind.STAT, "icon": "spring",
		"requires": ["ember_hop"], "stats": {EmberTreeEffects.DODGE_COOLDOWN_CUT: 0.25},
		"title": "Spring Legs", "text": "Your dodge is ready again almost as soon as you land, so you can hop twice in a row."},

	# --- Bruiser: stand your ground and take it --------------------------------
	{"id": "ash_guard", "branch": "bruiser", "stage": 1, "tier": 0, "kind": Kind.SKILL, "icon": "shield",
		"title": "Ash Guard", "text": "Hold to brace and harden into ash: you take far less damage, but you can't move."},
	{"id": "thick_hide", "branch": "bruiser", "stage": 1, "tier": 1, "angle": -SPREAD_NEAR, "kind": Kind.STAT, "icon": "heart",
		"requires": ["ash_guard"], "stats": {EmberTreeEffects.MAX_HEALTH: 2},
		"title": "Thick Hide", "text": "+2 Health. Emberoo can take two more hits before going down."},
	{"id": "counter_punch", "branch": "bruiser", "stage": 1, "tier": 1, "angle": SPREAD_NEAR, "kind": Kind.UPGRADE, "icon": "fist",
		"requires": ["ash_guard"],
		"title": "Counter Punch", "text": "Ash Guard upgrade. Getting hit while braced fires back an automatic punch."},
	{"id": "iron_gut", "branch": "bruiser", "stage": 1, "tier": 2, "angle": -SPREAD_FAR, "kind": Kind.STAT, "icon": "heart",
		"requires": ["thick_hide"], "stats": {EmberTreeEffects.MAX_HEALTH: 3},
		"title": "Iron Gut", "text": "+3 Health. Built to stay in the thick of a fight instead of hopping out."},
	{"id": "unshakable", "branch": "bruiser", "stage": 1, "tier": 2, "angle": SPREAD_FAR, "kind": Kind.STAT, "icon": "anchor",
		"requires": ["counter_punch"],
		"title": "Unshakable", "text": "Enemy shoves barely move you, so a Warden can't push you out of a combo."},

	# --- Stage 2: opens at the first evolution ----------------------------------
	{"id": "meteor_fist", "branch": "inferno", "stage": 2, "tier": 3, "angle": -SPREAD_FAR, "kind": Kind.SKILL, "icon": "star",
		"requires": ["kindling"],
		"title": "Meteor Fist", "text": "Leap up and crash down fist-first, leaving a pool of fire where you land."},
	{"id": "heat_sink", "branch": "inferno", "stage": 2, "tier": 3, "angle": SPREAD_FAR, "kind": Kind.STAT, "icon": "spark",
		"requires": ["wildfire"],
		"title": "Heat Sink", "text": "Hold more Heat at once, so you can save up for two big moves back to back."},
	{"id": "blur_step", "branch": "flurry", "stage": 2, "tier": 3, "angle": -SPREAD_FAR, "kind": Kind.SKILL, "icon": "hop",
		"requires": ["light_feet"],
		"title": "Blur Step", "text": "Dodging through an enemy leaves an afterimage that punches it for you."},
	{"id": "second_wind", "branch": "flurry", "stage": 2, "tier": 3, "angle": SPREAD_FAR, "kind": Kind.STAT, "icon": "boot",
		"requires": ["spring_legs"], "stats": {EmberTreeEffects.MOVE_SPEED: 12.0},
		"title": "Second Wind", "text": "+Speed. Even faster on your feet; the toads can't keep up."},
	{"id": "molten_armour", "branch": "bruiser", "stage": 2, "tier": 3, "angle": -SPREAD_FAR, "kind": Kind.SKILL, "icon": "shield",
		"requires": ["iron_gut"],
		"title": "Molten Armour", "text": "Enemies that hit you in melee are scorched by your molten skin."},
	{"id": "big_heart", "branch": "bruiser", "stage": 2, "tier": 3, "angle": SPREAD_FAR, "kind": Kind.STAT, "icon": "heart",
		"requires": ["unshakable"], "stats": {EmberTreeEffects.MAX_HEALTH: 3},
		"title": "Big Heart", "text": "+3 Health. Bigger body, bigger heart."},

	# --- Stage 3: Ultimates, at the final evolution -----------------------------
	{"id": "blazing_sun", "branch": "inferno", "stage": 3, "tier": 4, "kind": Kind.ULTIMATE, "icon": "sun",
		"requires": ["meteor_fist", "heat_sink"],
		"title": "Blazing Sun", "text": "Become a living sun for a few seconds, burning everything around you."},
	{"id": "inferno_rush", "branch": "flurry", "stage": 3, "tier": 4, "kind": Kind.ULTIMATE, "icon": "star",
		"requires": ["blur_step", "second_wind"],
		"title": "Inferno Rush", "text": "A storm of blazing punches that ends in an explosion."},
	{"id": "rekindle", "branch": "bruiser", "stage": 3, "tier": 4, "kind": Kind.ULTIMATE, "icon": "flame",
		"requires": ["molten_armour", "big_heart"],
		"title": "Rekindle", "text": "Once per fight, rise from defeat in a burst of flame with half your health."},
]

static var _nodes: Array[EmberTreeNode] = []
static var _by_id: Dictionary[String, EmberTreeNode] = {}


static func all_nodes() -> Array[EmberTreeNode]:
	_build_once()
	return _nodes


## The node with this id, or null if there is none.
static func find(id: String) -> EmberTreeNode:
	_build_once()
	return _by_id.get(id)


static func branch_title(branch: String) -> String:
	return BRANCHES[branch]["title"]


static func branch_angle(branch: String) -> float:
	return BRANCHES[branch]["angle"]


static func _build_once() -> void:
	if not _nodes.is_empty():
		return
	for row: Dictionary in NODE_ROWS:
		var node := EmberTreeNode.from_row(row)
		_nodes.append(node)
		_by_id[node.id] = node
