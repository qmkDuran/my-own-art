import sys; sys.path.insert(0,'tools')
from plh import *
KIND={
 "lion":"like a lion: a noble golden lion with a flowing golden mane, calm and majestic face",
 "ox":"like an ox: a strong noble white ox with gentle eyes and small golden horns",
 "man":"with the face of a man: a strong masculine figure with the bearded face of a grown man, short dark curly hair, short dark beard, broad shoulders, calm noble expression, simple shining white tunic, no halo",
 "eagle":"like a flying eagle: a majestic golden-white eagle with a bright noble head, hovering",
}
k=sys.argv[1]; seed=int(sys.argv[2]) if len(sys.argv)>2 else 41
D=("A holy heavenly living creature before God's throne, "+KIND[k]+", with six great shining white feathered wings: "
"two wings raised above, two spread to the sides, two folded below. The wings are covered with ornamental gleaming eye patterns "
"like the jewel eyes of a peacock's feathers, gold and sky blue. Facing the viewer, radiant, reverent, majestic and beautiful, glowing with light. "
"Clean pixel art game sprite, dark outline, light from top-left, three-quarter top-down view")
gimg("cr_"+k+("" if len(sys.argv)<4 else sys.argv[3]),D,112,112,seed=seed,refs=[("art/raw/char64_01.png","Match only the pixel art style, outline and shading")])
