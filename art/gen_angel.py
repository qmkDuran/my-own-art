import sys; sys.path.insert(0,'tools')
from plh import *
D=("A small angel of heaven praising God, full body facing the viewer, long shining white robe, two large white feathered wings spread, "
"both hands raised in praise, short hair, peaceful face, softly glowing with light. Clean tiny pixel art sprite, dark outline")
gimg("angel",D,32,32,seed=5,refs=[("art/raw/char64_01.png","Match only the pixel art style, outline and shading")])
