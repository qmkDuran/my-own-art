import sys,json,time,subprocess; sys.path.insert(0,'tools')
from plh import *
im=Image.open('art/raw/char64_01.png').convert('RGBA')
body={"description":"joyful man in a long white linen robe holding a green palm branch, dark brown skin, short black curly hair and beard, sandals",
 "reference_image":b64(im),"n_directions":4,"view":"low top-down","template_id":"mannequin","no_background":True,
 "image_size":{"width":64,"height":64}}
r=guard.paid_post("/create-character-v3",body,2,"char_create_v3_4dir")
print(json.dumps(r)[:600])
cid=r.get("character_id") or (r.get("last_response") or {}).get("character_id")
for i in range(100):
    c=guard.get(f"/characters/{cid}")
    ru=c.get("rotation_urls") or {}
    if ru and all(ru.values()): break
    time.sleep(6)
open('art/raw/char_id.txt','w').write(cid)
subprocess.run([sys.executable,'tools/fetchchar.py','hero',cid])
