class_name GenStep
extends RefCounted
## One step of laying out a zone (ZoneGen runs them in order). Shares the layout being built, the biome rules,
## the seeded random source and noise, and a few helpers.

const T := ZoneLayout.T

var z: ZoneLayout
var b: Dictionary
var rng: RandomNumberGenerator
var noise: FastNoiseLite


func with(layout: ZoneLayout, biome: Dictionary, r: RandomNumberGenerator, n: FastNoiseLite) -> GenStep:
	z = layout
	b = biome
	rng = r
	noise = n
	return self


func _weighted(table: Dictionary) -> String:
	var total: float = 0.0
	for k: String in table:
		total += float(table[k])
	var roll: float = rng.randf() * total
	for k: String in table:
		roll -= float(table[k])
		if roll <= 0.0:
			return k
	return String(table.keys()[0])

func _shuffle(a: Array) -> void:
	for i: int in range(a.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Variant = a[i]
		a[i] = a[j]
		a[j] = tmp

static func _vec(a: Array) -> Vector2:
	return Vector2(float(a[0]), float(a[1]))
