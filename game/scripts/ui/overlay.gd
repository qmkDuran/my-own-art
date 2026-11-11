class_name Overlay
extends RefCounted
## World-space text the darkness must not dim (damage numbers, item names, enemy titles): a CanvasLayer that
## follows the camera above the lit world.

static var layer: CanvasLayer


static func create(parent: Node) -> CanvasLayer:
	layer = CanvasLayer.new()
	layer.layer = 2
	layer.follow_viewport_enabled = true
	parent.add_child(layer)
	return layer


## A holder on the overlay that copies `follow`'s position; freed with it.
static func follower(follow: Node2D) -> Node2D:
	var holder := Node2D.new()
	layer.add_child(holder)
	var rt := RemoteTransform2D.new()
	rt.update_rotation = false
	rt.update_scale = false
	follow.add_child(rt)
	rt.remote_path = rt.get_path_to(holder)
	follow.tree_exiting.connect(holder.queue_free)
	return holder
