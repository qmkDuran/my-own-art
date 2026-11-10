class_name Travel
extends RefCounted
## A little state carried across scene changes: which way the player came, and recordings that continue.

## How the player arrives in the next scene: "earth" (city gate from the new earth), "city" (new earth from the city),
## "throne" (back into the city from the throne room), "to_throne" (throne room from the city), or "".
static var arriving: String = ""
## Where in the city the throne room was entered from ("garden" or "district"); the way back leads there.
static var throne_from: String = "district"
## True while a scripted recording should continue in the next scene; `demo_next` names its demo data key.
static var demo: bool = false
static var demo_next: String = ""
