class_name Travel
extends RefCounted
## Carries a little state across scene changes (which gate the player came through, demo recording).

## "earth" when arriving in the city from the new earth, "city" when arriving on the new earth from the city.
static var arriving: String = ""
## True while a scripted recording should continue in the next scene.
static var demo: bool = false
