import sys; sys.path.insert(0,'tools')
from plh import *
D=("A small pure white lamb standing calmly on four legs, three-quarter view facing right and slightly toward the viewer, "
"soft fluffy white wool, gentle dark eyes, small ears, peaceful and innocent, softly glowing with holy light. "
"Clean pixel art game sprite, dark outline, light from top-left")
gimg("lamb",D,48,48,seed=12,refs=[("art/raw/char64_01.png","Match only the pixel art style, outline and shading")])
