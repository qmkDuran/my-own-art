"""The angel at the pearl gate (Rev 21:12: twelve angels at the gates). A tall adult angel standing in welcome beside the
open gate, wings folded behind. Same prompt structure, size and style anchor that produced the hero and the Shepherd."""
import sys; sys.path.insert(0, 'tools')
from plh import *
D = ("A tall majestic angel of heaven standing calmly at a gate, full body, facing the viewer, adult, a long shining white robe "
     "reaching to the feet with a thin gold belt, two large white feathered wings folded behind the back with the wing tips "
     "visible above the shoulders and beside the legs, hands open at the sides in welcome, short hair, serene face. "
     "No halo, no crown, no weapon, no sword. Clean pixel art game sprite, dark outline, light from top-left")
gimg("gate_angel", D, 64, 64, seed=212,
     refs=[("art/raw/char64_01.png", "Match only the pixel art style, body proportions, sprite size and white robe rendering; this is a different being")])
