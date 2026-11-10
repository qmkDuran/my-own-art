"""PAID (10 gens, 16 variants at 64 px): the archangel Michael (Jude 9; Rev 12:7; Dan 10:13), a warrior angel with a drawn
sword (Num 22:31). Same prompt structure and style anchor that produced the heaven hero; run from heaven/."""
import sys; sys.path.insert(0, 'tools')
from plh import *
D = ("The archangel Michael, a mighty warrior angel, full body, standing facing the viewer, adult and tall, large white "
     "feathered wings folded half open behind his shoulders, polished silver and gold armour breastplate over a white tunic, "
     "gold belt, armoured boots, a drawn longsword held in his right hand pointing down, short dark hair, stern noble face, "
     "dignified and powerful, not cute. No halo, no crown, no helmet. Clean pixel art game sprite, dark outline, light from top-left")
gimg("arpg_michael", D, 64, 64, seed=777,
     refs=[("art/raw/char64_01.png", "Match only the pixel art style, adult body proportions and sprite size; this is a different being")])
