# fetchchar.py NAME CID  (free GETs)
import sys,os,json,re; sys.path.insert(0,os.path.dirname(__file__))
from plh import *
name,cid=sys.argv[1],sys.argv[2]
c=guard.get(f"/characters/{cid}")
json.dump({"id":cid,"detail":c},open(RAW+f"ch_{name}.json","w"))
for d,u in (c.get("rotation_urls") or {}).items():
    if u: fetch(u).save(RAW+f"ch_{name}_rot_{d}.png")
seen={}
for a in c.get("animations") or []:
    an=re.sub(r'[^a-z0-9]+','-',(a.get("display_name") or a.get("animation_type")).lower())[:30]
    for dd in a.get("directions") or []:
        d=dd["direction"]; k=seen.get((an,d),0); seen[(an,d)]=k+1
        folder=RAW+f"anim/{name}/{an}"+(f"_{k}" if k else ""); os.makedirs(folder,exist_ok=True)
        for i,u in enumerate(dd.get("frames") or []):
            p=f"{folder}/{d}_{i:02d}.png"
            if not os.path.exists(p): fetch(u).save(p)
print(name,c.get("status"),c.get("size"),[(a.get("display_name") or a.get("animation_type"),[x["direction"] for x in a.get("directions",[])]) for a in c.get("animations") or []])
