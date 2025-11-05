#!/usr/bin/env python3
import csv, argparse
from datetime import datetime, timezone
from math import sqrt
def iso_to_dt(s):
    try: return datetime.fromisoformat(s.replace("Z","")).astimezone(timezone.utc)
    except: return None
def read_csv(path):
    rows=[]
    with open(path, newline='') as f:
        r=csv.DictReader(f)
        for row in r:
            dt=iso_to_dt(row.get("Timestamp_UTC",""))
            if not dt: continue
            def ffloat(k):
                try: return float(row.get(k,""))
                except: return None
            rows.append({"t": dt,"drift": ffloat("Drift_System_vs_GNSS_s"),"B": ffloat("B_total_uT"),"P": ffloat("Pressure_hPa")})
    return rows
def align(a,b, tol_s=60):
    ai=0; bi=0; pairs=[]
    a_sorted=sorted(a, key=lambda x:x["t"]); b_sorted=sorted(b, key=lambda x:x["t"])
    for ar in a_sorted:
        best=None; bestdt=None
        while bi < len(b_sorted) and b_sorted[bi]["t"] < ar["t"]:
            bi+=1
        candidates=[]
        if bi>0: candidates.append(b_sorted[bi-1])
        if bi<len(b_sorted): candidates.append(b_sorted[bi])
        for br in candidates:
            dt=abs((ar["t"]-br["t"]).total_seconds())
            if best is None or dt<bestdt:
                best=br; bestdt=dt
        if best is not None and bestdt<=tol_s:
            pairs.append((ar,best,bestdt))
    return pairs
def stats(pairs, key):
    xs=[]; ys=[]
    for a,b,_ in pairs:
        va=a.get(key); vb=b.get(key)
        if va is None or vb is None: continue
        xs.append(va); ys.append(vb)
    if not xs: return {"n":0}
    n=len(xs)
    mean_diff=sum((x - y) for x,y in zip(xs,ys))/n
    mx=sum(xs)/n; my=sum(ys)/n
    cov=sum((x-mx)*(y-my) for x,y in zip(xs,ys))/n
    vx=sum((x-mx)**2 for x in xs)/n; vy=sum((y-my)**2 for y in ys)/n
    corr = cov / sqrt(vx*vy) if vx>0 and vy>0 else None
    return {"n":n, "mean_diff": mean_diff, "corr": corr}
def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--a", required=True, help="Chacaltaya CSV")
    ap.add_argument("--b", required=True, help="DigitalOcean CSV")
    ap.add_argument("--out", default="comparison_summary.txt")
    ap.add_argument("--tol", type=int, default=60)
    args=ap.parse_args()
    A=read_csv(args.a); B=read_csv(args.b)
    pairs=align(A,B, tol_s=args.tol)
    with open(args.out,"w") as f:
        f.write("OTSL Comparison Summary\n")
        f.write(f"Pairs aligned (<= {args.tol}s): {len(pairs)}\n")
        from pprint import pformat
        def line(label, key):
            from pprint import pformat
            return f"{label}: " + pformat(stats(pairs,key)) + "\n"
        f.write(line("Drift (A-B)", "drift"))
        f.write(line("|B| total (uT) correlation", "B"))
        f.write(line("Pressure (hPa) correlation", "P"))
    print(f"Wrote {args.out}")
if __name__=="__main__":
    main()
