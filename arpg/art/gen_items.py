"""PAID (10 gens, 64 variants at 32 px): inventory icons for the armour of God (Eph 6:13-17) and rings/amulets.
Listing the pieces spreads the variants across them. Run from heaven/."""
import sys; sys.path.insert(0, 'tools')
from plh import *
D = ("A single inventory item icon for a fantasy action game, centred, plain transparent background. Each image a different "
     "item from this list: a leather belt with a gold buckle; a silver breastplate; a pair of armoured sandal boots; a round "
     "shield with a gold cross rim; a silver helmet; a shining longsword; a gold ring with a gem; an amulet on a chain. "
     "Clean pixel art icon, dark outline, light from top-left")
gimg("arpg_item", D, 32, 32, seed=316, style=None)
