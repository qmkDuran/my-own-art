"""Scale phase: houses at true scale (~3 people tall, door taller than a person) in the meadow's straight 3/4 view."""
import sys; sys.path.insert(0, 'tools')
from plh import *
ST = '/home/user/project-revelation/art/style_anchors/anchor_building_crop_256.png'
VIEW = ("seen straight from the front (south) in a three-quarter top-down view: the front wall faces the viewer squarely "
        "and runs parallel to the bottom edge, the roof slopes away and is seen from above, NOT isometric, NOT turned diagonally")
gimg("house2x", "A cozy two-storey cottage of the new earth, " + VIEW + ". Warm cream stone walls, a wooden front door in the middle "
     "of the front wall at ground level, the door taller than a man, windows with flower boxes at head height, red-brown tiled roof, "
     "a chimney. The cottage fills the image, standing on a thin strip of grass. Bright, peaceful, clean pixel art game asset, "
     "dark outline, light from top-left", 168, 168, seed=91, style=ST)
gimg("frame2x", "A two-storey cottage being built, " + VIEW + ". Cream stone ground floor walls finished with a door opening in the middle "
     "of the front wall, wooden timber frame of the upper storey and bare roof beams, no roof tiles yet, a ladder leaning on the wall, "
     "a neat stack of planks and stones beside it. Fills the image, standing on a thin strip of grass. Bright, peaceful, clean pixel art "
     "game asset, dark outline, light from top-left", 168, 168, seed=92, style=ST)
gimg("vines2x", "One straight row of grapevines on a sturdy wooden trellis seen from the front in three-quarter top-down view, the trellis "
     "a little taller than a man, wooden posts at both ends, green leaves and many ripe purple grape clusters, a wide horizontal row filling "
     "the width of the image, standing on grass. Clean pixel art game asset, dark outline, light from top-left", 128, 80, seed=93, style=ST)
