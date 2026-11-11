class_name LightField
extends RefCounted
## Every light that pushes back the Dusk (the Lamplighter's lantern, a thrown lantern, lit waylamps) is in the
## "light_sources" group with light_pos() and light_radius(). An enemy outside all of them is Shrouded.

const GROUP: String = "light_sources"


static func lit(tree: SceneTree, p: Vector2) -> bool:
	for n: Node in tree.get_nodes_in_group(GROUP):
		if n.has_method("light_radius") and p.distance_to(n.call("light_pos")) <= float(n.call("light_radius")):
			return true
	return false
