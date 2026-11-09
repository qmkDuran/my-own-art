class_name Checkpoint
extends Marker2D
## A place to get back up after falling (see Respawner). Walking within `reach_radius` makes
## it the last checkpoint reached (the Checkpoints autoload, which is saved): a small
## "CHECKPOINT" toast, and at a waystone its glyph lights up (WaystoneGlow).
##
## The zone's start checkpoint (`is_zone_start`, at the spawn) counts as reached from the
## start, silently, so a fall before any other checkpoint puts you back at the spawn.

const GROUP := "checkpoints"

## Names it in the save; the node's name when left empty.
@export var checkpoint_id: String = ""
## The spawn point's checkpoint: reached silently when the zone starts with none reached yet.
@export var is_zone_start: bool = false
## Walking this close (in pixels) reaches it.
@export var reach_radius: float = 40.0
## Off where there is no waystone to light (e.g. the start checkpoint).
@export var has_waystone: bool = false
## Where the waystone's glyph is, from this marker, in pixels.
@export var glyph_offset: Vector2 = Vector2(0, -33)

var _glow: WaystoneGlow = null


func _ready() -> void:
	add_to_group(GROUP)
	if checkpoint_id == "":
		checkpoint_id = name
	if has_waystone:
		_glow = WaystoneGlow.new()
		_glow.position = glyph_offset
		add_child(_glow)
	# The start checkpoint is only ever reached here, so walking back past the spawn
	# never undoes a later checkpoint.
	set_physics_process(not is_zone_start)
	if is_zone_start and Checkpoints.last_in_zone(_zone()) == "":
		reach(false)
	_refresh_glow()
	Checkpoints.changed.connect(_refresh_glow)


func _physics_process(_delta: float) -> void:
	if is_current():
		return
	var player := PlayerFinder.find(self)
	if player != null and global_position.distance_squared_to(player.global_position) <= reach_radius * reach_radius:
		reach(true)


## True while this is the last checkpoint reached.
func is_current() -> bool:
	return Checkpoints.last_in_zone(_zone()) == checkpoint_id


## Makes this the last checkpoint reached; with `announce`, the HUD shows the toast.
func reach(announce: bool) -> void:
	if Checkpoints.reach(_zone(), checkpoint_id) and announce:
		CheckpointToast.announce_reached(self)


func _refresh_glow() -> void:
	if _glow != null:
		_glow.set_lit(is_current())


func _zone() -> String:
	return Checkpoints.zone_of(self)
