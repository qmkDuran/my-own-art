"""HARD budget guard for the heaven demo. Every PixelLab POST must go through paid_post().
Floor: subscription generations may not drop below FLOOR. USD credits must not change."""
import json, urllib.request, urllib.error, sys, time
B="https://api.pixellab.ai/v2"; START=99.5; CAP=0.0; FLOOR=START-CAP; USD0=2.18083018988485
LOG="/tmp/claude-0/-home-user-my-own-art/cb019c91-d4b5-5ec5-a8ec-8aef6ba03cf6/scratchpad/heaven/spend_log.txt"
def _req(method,path,body=None):
    r=urllib.request.Request(B+path,data=None if body is None else json.dumps(body).encode(),method=method,
        headers={"Content-Type":"application/json","Authorization":"Bearer dummy"})
    return json.load(urllib.request.urlopen(r,timeout=300))
def balance():
    b=_req("GET","/balance"); return b["subscription"]["generations"], b["credits"]["usd"]
def get(path): return _req("GET",path)
def paid_post(path, body, est, label):
    g,u=balance()
    if u < USD0-1e-6: sys.exit(f"!!! USD credits changed ({u}); STOP")
    if g-est < FLOOR-1e-6: sys.exit(f"!!! BUDGET: {START-g:.1f} used, {est} more would exceed cap {CAP}; STOP")
    r=_req("POST",path,body)
    jid=r.get("background_job_id") or r.get("job_id")
    if jid:
        for _ in range(120):
            r=_req("GET","/background-jobs/"+jid)
            if r.get("status") in ("completed","failed","error","cancelled"): break
            time.sleep(5)
    g2,u2=balance()
    open(LOG,"a").write(f"{label}\tcost={g-g2}\ttotal_used={START-g2}\tusd={u2}\n")
    return r
