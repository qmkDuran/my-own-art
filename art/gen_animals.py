import sys; sys.path.insert(0,'tools')
from plh import *
A=("One gentle, peaceful animal of the new earth, full body standing calmly on grass, three-quarter view facing left, "
"healthy and calm, soft friendly expression, not threatening, no blood, no teeth bared. "
"Each image a different animal from this list: a lion with golden mane, a brown bear, a spotted leopard, a grey wolf, "
"a brown and white cow, a strong ox. Clean pixel art game sprite, dark outline, light from top-left, three-quarter top-down view")
B=("One small gentle young animal of the new earth, full body standing calmly, three-quarter view facing right, "
"soft and peaceful. Each image a different young animal from this list: a white fluffy lamb, a small brown and white young goat kid, "
"a young calf, a young lion cub with a small mane. Clean pixel art game sprite, dark outline, light from top-left, three-quarter top-down view")
gimg("animA",A,64,64,seed=71)
gimg("animB",B,48,48,seed=72)
