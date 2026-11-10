import sys; sys.path.insert(0,'tools')
from plh import *
D=("One of the twenty-four elders of heaven, seated on a small golden throne, side view facing right, full body. "
"A dignified old man with white hair and white beard, warm peaceful face, wearing a long pure white robe, "
"a golden crown on his head, holding a small golden harp on his lap. The throne is gold with a white cushion and a high back. "
"Reverent, bright, clean pixel art game sprite, dark outline, light from top-left")
gimg("elder",D,64,64,seed=31,refs=[("art/raw/char64_01.png","Match the pixel art style, proportions, head size and white robe rendering")])
