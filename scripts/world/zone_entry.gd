class_name ZoneEntry
extends Checkpoint
## Where a ZoneExit in another zone puts Emberoo (see ZoneTravel). Its `checkpoint_id` is the
## entry id the exit names (e.g. "from_hometown"). Arriving makes it the last checkpoint
## reached, so a fall in this zone before any other checkpoint puts you back here; walking
## past it later never reaches it again (no toast).
##
## Keep it a few tiles away from the zone's exits, so arriving never walks straight back out.


func _ready() -> void:
	super._ready()
	set_physics_process(false)  # reached only by arriving
