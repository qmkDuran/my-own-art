class_name ElementalHits
extends Node
## Makes a MeleeAttack's hits (Emberoo's jabs and hook, which deal their own damage) count
## as element hits: hit feel, poise, cooldown shaving, the Link meter and reactions
## (see ElementStrike).

@export var melee_attack: MeleeAttack
## Poise each landed jab drains.
@export var poise_damage: int = 1


func _ready() -> void:
	melee_attack.target_hit.connect(_on_target_hit)


func _on_target_hit(target_health: Health) -> void:
	var attacker := get_parent() as Node2D
	var reaction := Reactions.find_for(target_health.get_parent(), ElementStrike.element_of(attacker))
	ElementStrike.after_hit(attacker, target_health, poise_damage, reaction)
	var spots: Array[Vector2] = [(target_health.get_parent() as Node2D).global_position]
	HitFeel.land(attacker, spots, ElementColors.for_element(ElementStrike.element_of(attacker)), HitFeel.Weight.LIGHT)
