"""Compare actual Godot captures against the approved artwork (no repainting)."""
import argparse
import csv
import hashlib
import json
from pathlib import Path

import numpy as np
from PIL import Image

REPO = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("reference", type=Path, help="assets_v7d")
    parser.add_argument("output", type=Path, help="game_step1 capture directory")
    args = parser.parse_args()
    out = args.output
    checks = []

    def check(ok, label):
        checks.append(dict(ok=bool(ok), label=label))

    ref = Image.open(args.reference/"preview_full.png").convert("RGB")
    full = Image.open(out/"game_full.png").convert("RGB")
    zoom = Image.open(out/"game_zoom2x.png").convert("RGB")
    art = Image.open(out/"game_full_art_only.png").convert("RGB")
    for label, im in [("reference",ref),("full",full),("zoom",zoom),("art-only",art)]:
        check(im.size==(1920,1080),"1920x1080 "+label)
    compare = Image.new("RGB",(3840,1080))
    compare.paste(ref,(0,0));compare.paste(full,(1920,0))
    compare.save(out/"compare_game_vs_mockup.png")
    layout = json.loads((REPO/"data/maps/v130r_step1/layout.json").read_text(encoding="utf-8"))
    records = list(csv.DictReader((args.reference/"final/asset_table.csv").open(encoding="utf-8-sig")))
    for rec in records:
        path = REPO/"assets/maps/v130r_step1"/rec["path"]
        check(hashlib.sha256(path.read_bytes()).hexdigest()==rec["sha256"],"approved pixels "+rec["path"])
        check(layout["assets"][rec["path"]]["pivot"]==[float(rec["pivot_x"]),float(rec["pivot_y"])],"approved pivot "+rec["path"])
    a,b = np.asarray(art,dtype=float),np.asarray(ref,dtype=float)
    delta = np.abs(a-b)
    # Search local registration on independently chosen visible landmark regions.
    # Zero displacement detects placement/pivot errors separately from resampling.
    regions = {"throne":(1070,65,1280,265),"vault":(1420,300,1580,445),
               "ward_core":(1055,380,1220,550),"barracks":(565,440,770,565),
               "recovery":(940,625,1115,745),"watchtower":(410,525,520,680),
               "bait_treasure":(685,735,800,835),"entrance":(405,710,550,845),
               "entrance_bridge":(70,890,340,1040),"water":(1190,320,1340,370)}
    registration = {}
    for name,(x1,y1,x2,y2) in regions.items():
        values=[]
        for dy in range(-3,4):
            for dx in range(-3,4):
                error=float(np.abs(a[y1+dy:y2+dy,x1+dx:x2+dx]-b[y1:y2,x1:x2]).mean())
                values.append((error,dx,dy))
        error,dx,dy=min(values)
        registration[name]=dict(offset=[dx,dy],mean_rgb_error=error)
        check((dx,dy)==(0,0),"no landmark displacement "+name)
    report = dict(result="PASS" if all(c["ok"] for c in checks) else "FAIL",checks=checks,
                  mean_rgb_error=float(delta.mean()),p99_channel_error=float(np.percentile(delta,99)),
                  exact_rgb_fraction=float(np.all(delta==0,axis=2).mean()),registration=registration,
                  expected_difference="Godot linear texture filtering vs Pillow bicubic/Lanczos; control overlay in game_full only")
    (out/"capture_audit.json").write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps({k:v for k,v in report.items() if k!="checks"},indent=2))
    if report["result"]!="PASS": raise SystemExit(1)


if __name__=="__main__":
    main()
