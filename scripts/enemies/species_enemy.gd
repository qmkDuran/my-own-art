class_name SpeciesEnemy
extends Enemy
## An enemy of a species the player meets and keeps in the Creature Log (the bound Glimra,
## and the Warden Captain). Noticing the player is when they meet it (see PlayerAwareness);
## the first of its kind brings up the discovery card. Wardens aren't a species: they're Enemy.

@export_group("Creature info")
## Shown when the player first meets this species, and in the Creature Log.
@export var species_id: String = ""
@export var display_name: String = ""
@export var element: String = ""
## Without a painted portrait the discovery card shows its sprite instead.
@export var portrait: Texture2D


## Name, element and picture, for the discovery card and the Creature Log.
func creature_info() -> Dictionary:
	return CreatureInfo.describe(species_id, display_name, element, portrait, sprite)
