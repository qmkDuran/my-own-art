import sys; sys.path.insert(0,'tools')
from plh import *
D=("A joyful resurrected man in glory, full body, standing, facing the viewer, healthy strong real human body, "
"warm dark brown skin, short black curly hair, short neat black beard, peaceful happy smile. "
"Long shining pure white fine linen robe down to the ankles, soft pale blue-grey folds, simple white sash at the waist, "
"simple brown sandals. He holds one tall green palm branch upright in his right hand. "
"Reverent, bright, clean pixel art game sprite, dark outline, light from top-left")
J='/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/jesus/pixellab_jesus_64.png'
gimg("char64",D,64,64,seed=21,refs=[(J,"Match only the pixel art style, body proportions, sprite size and white robe rendering; this is a different man")])
