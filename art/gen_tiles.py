import sys,json,base64; sys.path.insert(0,'tools')
from plh import *
A=Image.open(ANCHOR_TILES).convert('RGBA')
sty=[]
for box in [(0,0,32,32),(32,32,64,64)]:
    t=A.crop(box); sty.append({"base64":b64(t)["base64"],"width":32,"height":32})
D=("1). street paved with pure gold like transparent glass, large smooth golden glass slabs with soft bright reflections, top-down, seamless "
"2). pure gold glassy pavement slabs, translucent shining gold, subtle light streaks, top-down, seamless "
"3). pure gold glassy pavement, plain smooth golden glass, top-down, seamless "
"4). lush bright green grass meadow with tiny white and yellow flowers, top-down, seamless "
"5). lush bright green grass, soft and healthy, top-down, seamless "
"6). bright green grass with a few small white flowers, top-down, seamless")
body={"description":D,"tile_type":"square_topdown","tile_size":32,"tile_view":"top-down","outline_mode":"segmentation",
      "target_palette":PAL,"seed":7,"style_images":sty,"style_options":{"color_palette":False,"outline":True,"detail":True,"shading":True}}
j=guard.paid_post("/create-tiles-pro",body,15,"tilesA_gold_grass")
json.dump(j,open(RAW+"tilesA.json","w"))
lr=j.get("last_response") or j
print(j.get("status"), list(lr.keys()))
