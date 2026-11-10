"""City district: dwellings (John 14:2) and gifts of the nations (Rev 21:24-26).
The view wording is the one that gave straight-front houses last pass (gen_earth_build2.py)."""
import sys; sys.path.insert(0, 'tools')
from plh import *
ST = '/home/user/project-revelation/art/style_anchors/anchor_building_crop_256.png'
VIEW = ("seen straight from the front (south) in a three-quarter top-down view: the front wall faces the viewer squarely "
        "and runs parallel to the bottom edge, the roof slopes away and is seen from above, NOT isometric, NOT turned diagonally")
if 'mansion' in sys.argv:
    gimg("mansion", "A dignified dwelling in the holy city New Jerusalem, " + VIEW + ". Walls of pale sea-green translucent jasper "
         "and white stone with fine gold trim, one arched front door of pearl in the middle of the front wall at ground level, "
         "the door taller than a man, windows with thin gold frames at head height, a gently sloped roof of gold tiles, a few small "
         "precious gem stones set along the cornice. Glorious but simple and calm, not gaudy, no towers, no flags. The building fills "
         "the image, standing on a thin strip of golden pavement. Bright, peaceful, clean pixel art game asset, dark outline, light "
         "from top-left", 168, 168, seed=101, style=ST)
if 'gifts' in sys.argv:
    gimg("gifts", "One precious gift brought by the nations into the holy city, a single small object on its own, held upright. "
         "Each image a different gift from this list: a small golden treasure chest, a golden crown, a tall white alabaster jar, "
         "a woven basket of fruit, a folded bolt of fine purple cloth, a golden bowl of incense, a small wooden harp, a box of "
         "precious gems. Clean pixel art game item icon, dark outline, light from top-left", 32, 32, seed=102, style=ST)
