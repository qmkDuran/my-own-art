class_name SceneData
extends RefCounted
## Loads a scene's content (positions, people, verses, colliders, demo routes) from JSON and converts values.


static func load_json(path: String) -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	assert(parsed is Dictionary, "bad scene data: " + path)
	return parsed


static func vec(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))


static func rect(a: Array) -> Rect2:
	return Rect2(float(a[0]), float(a[1]), float(a[2]), float(a[3]))


static func color(a: Array) -> Color:
	return Color(float(a[0]), float(a[1]), float(a[2]), float(a[3]) if a.size() > 3 else 1.0)


## [[x, y, pause], ...] -> autopilot waypoints
static func waypoints(a: Array) -> Array[Vector3]:
	var out: Array[Vector3] = []
	for w: Array in a:
		out.append(Vector3(float(w[0]), float(w[1]), float(w[2])))
	return out


static func points(a: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for p: Array in a:
		out.append(vec(p))
	return out
