# anim.py animname template_id dirs   (template mode, 1 gen/dir)
import sys,os,json,time,subprocess; sys.path.insert(0,os.path.dirname(__file__))
from plh import *
an,tpl,dirs=sys.argv[1],sys.argv[2],sys.argv[3].split(",")
mode=sys.argv[4] if len(sys.argv)>4 else "template"
cid=open(RAW+"char_id.txt").read().strip()
body={"character_id":cid,"animation_name":an,"directions":dirs,"mode":mode,"template_animation_id":tpl}
est={"template":1,"skeleton-v3":4}[mode]*len(dirs)
r=guard.paid_post("/characters/animations",body,est,f"anim_{an}_{mode}_{'-'.join(dirs)}")
for jid in r.get("background_job_ids") or []:
    for i in range(150):
        j=guard.get("/background-jobs/"+jid)
        if j.get("status") in("completed","failed","error","cancelled"): break
        time.sleep(6)
    print(jid,j.get("status"),j.get("usage"))
g,u=guard.balance(); open(guard.LOG,"a").write(f"  (after jobs of {an}) total_used={guard.START-g}\tusd={u}\n")
subprocess.run([sys.executable,os.path.dirname(__file__)+"/fetchchar.py","hero",cid])
