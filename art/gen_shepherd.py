"""The risen Christ as the Shepherd by the river (Rev 7:17), appearance after Rev 1:13-16 (NIV): robe reaching down to his
feet, golden sash around his chest, hair white like wool, feet like bronze glowing. The face is painted as light by hand
afterwards (build_shepherd.py). Same prompt structure and style anchor that produced the hero's straight 3/4 front view."""
import sys; sys.path.insert(0, 'tools')
from plh import *
D = ("The risen Lord as a gentle shepherd, full body, standing calmly facing the viewer, a long pure white robe reaching down "
     "to his feet, a golden sash around his chest, short white hair like white wool and a short white beard, bare feet glowing "
     "like polished bronze, holding a simple wooden shepherd's staff upright in his right hand. Majestic yet gentle and humble, "
     "reverent. No crown, no halo, no wings, no weapon. Clean pixel art game sprite, dark outline, light from top-left")
gimg("shepherd", D, 64, 64, seed=121,
     refs=[("art/raw/char64_01.png", "Match only the pixel art style, body proportions, sprite size and white robe rendering; this is a different person")])
