import sys; sys.path.insert(0,'tools')
from plh import *
D=("A great city gate made from one single giant pearl: a huge round lustrous white pearl with a tall arched passage cut through its middle, "
"the gateway stands wide open with no doors closed, the passage glows with radiant warm golden-white light. "
"Smooth iridescent pearly white surface with soft pink, lavender and pale blue sheen and bright highlights. "
"The pearl stands on a base of precious gem stone foundations, golden pavement threshold at the bottom of the passage. "
"Front view, three-quarter top-down, clean pixel art game asset, dark outline, light from top-left")
gimg("gate",D,144,160,seed=9,style='/home/user/project-revelation/art/style_anchors/anchor_building_crop_256.png',
     refs=[("art/raw/wall_00.png","The gate stands in this city wall: match its pixel art style, outline, scale and gem foundations")])
