import sys; sys.path.insert(0,'tools')
from plh import *
ST='/home/user/project-revelation/art/style_anchors/anchor_building_crop_256.png'
gimg("house", "A small cozy cottage of the new earth, whole building visible, three-quarter top-down view from the front-south, "
     "warm cream stone walls, wooden door in the middle of the front wall facing the viewer, two small windows with flower boxes, "
     "simple red-brown tiled roof, standing on grass. Bright, peaceful, clean pixel art game asset, dark outline, light from top-left", 128, 128, seed=81, style=ST)
gimg("frame", "A small house being built: wooden timber frame of a cottage under construction, posts and beams, half-finished cream stone "
     "lower walls, no roof yet, a few planks and stones stacked neatly beside it, standing on grass, three-quarter top-down view from the front-south. "
     "Bright, peaceful, clean pixel art game asset, dark outline, light from top-left", 128, 128, seed=82, style=ST)
gimg("vines", "One straight row of grapevines growing on a simple wooden trellis, seen from the front in three-quarter top-down view, "
     "green leaves and many ripe purple grape clusters hanging, wooden posts at both ends, standing on grass, wide horizontal row. "
     "Clean pixel art game asset, dark outline, light from top-left", 128, 64, seed=83, style=ST)
