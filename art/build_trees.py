"""Trees of life game/art/tree1.png, tree2.png: the generated dirt patch is peeled away so the roots sit on grass."""
import sys
from PIL import Image
sys.path.insert(0, 'art')
from common import erode_ground

DIRT = ('ab947a', '966c6c', '4c3e24', '676633')
BASE_ROW = 100              # only the foot of the tree is peeled

if __name__ == '__main__':
    for src, dst in (('tree_01', 'tree1'), ('tree_02', 'tree2')):
        erode_ground(Image.open(f'art/raw/{src}.png').convert('RGBA'), DIRT, BASE_ROW).save(f'game/art/{dst}.png')
    print('trees ok')
