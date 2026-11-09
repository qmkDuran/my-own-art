class_name CrewEncounter
extends Encounter
## A zone's mini-event (see Encounter): a crew of enemies at work on something (e.g. Wardens
## cutting a frozen Glimra out of the ice). Once every crew member is down, the boss banner
## announces "<CREW NAME> DEFEATED" and the Barricade they guarded opens (the ice cracks, a
## pocket opens up). Creatures the crew summoned keep fighting, but don't hold the win back.

@export var crew: Array[Node2D] = []
## The name in the banner, e.g. "Ice Cutters" ("" = no banner).
@export var crew_name: String = ""


func _fighters() -> Array[Node2D]:
	return crew


func _celebrate() -> void:
	if crew_name != "":
		BossHealthBar.announce_defeat(self, crew_name)
