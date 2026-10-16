"""Import the approved v7d pieces, preserving pixels, pivots and assembly order.

Only image placement, coverage masks and the reference affine cliff transform
are used. No artwork is drawn, generated, keyed, recolored or retouched.
"""
import argparse
import csv
import hashlib
import json
from pathlib import Path
import shutil

from PIL import Image, ImageDraw

REPO = Path(__file__).resolve().parents[2]
ART = REPO / "assets/maps/v130r_step1"
DATA = REPO / "data/maps/v130r_step1"
SOURCE = REPO / "assets/source/imagegen/v130r_step1"
SIZE = (3712, 2432)
W, H = 32, 18
L = Image.Resampling.LANCZOS


def p(x, y):
    return round(64 * (x + y - W) + 2304), round(32 * (y + W - x) + 512)


def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path, help="Approved assets_v7d folder (read only)")
    parser.add_argument("--plan", type=Path, required=True)
    args = parser.parse_args()
    reference = args.source
    records = list(csv.DictReader((reference / "final/asset_table.csv").open(encoding="utf-8-sig")))
    images, table = {}, {}
    for r in records:
        src = reference / "final" / r["path"]
        assert sha(src) == r["sha256"], r["path"]
        im = Image.open(src).convert("RGBA")
        assert im.size == (int(r["width"]), int(r["height"])), r["path"]
        dst = ART / r["path"]
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        original = SOURCE / "approved_final" / r["path"]
        original.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, original)
        images[r["path"]] = im
        table[r["path"]] = dict(size=list(im.size), pivot=[float(r["pivot_x"]), float(r["pivot_y"])], sha256=r["sha256"])
    # The original CSV is provenance, not a Godot localization catalog.
    shutil.copy2(reference / "final/asset_table.csv", SOURCE / "reference_asset_table.csv.txt")
    DATA.mkdir(parents=True, exist_ok=True)
    shutil.copy2(args.plan, DATA / "plan_E_cells.txt")
    plan = args.plan.read_text(encoding="utf-8-sig")
    rows = [s for s in plan.splitlines() if s and not s.startswith("#")]
    assert len(rows) == H and all(len(s) == W for s in rows)
    buildings = json.loads(next(s.split(":", 1)[1] for s in plan.splitlines() if s.startswith("# buildings:")))

    def cell(chars, x, y):
        return 0 <= x < W and 0 <= y < H and rows[y][x] in chars

    nodes = []
    generated_sources = {}

    def add(path, anchor, depth=None, layer="objects", pivot=None, **extra):
        # The reference rounds anchor minus pivot, including half-pixel pivots.
        pv = pivot if pivot is not None else table[path]["pivot"]
        nodes.append(dict(asset=path, anchor=list(anchor), pivot=list(pv),
                          position=[round(anchor[0] - pv[0]), round(anchor[1] - pv[1])],
                          depth=anchor[1] if depth is None else depth, layer=layer, **extra))

    def derived(name, image, anchor, source, pivot=(0, 0), layer="terrain"):
        path = "assembled/" + name + ".png"
        dest = ART / path
        dest.parent.mkdir(parents=True, exist_ok=True)
        image.save(dest, optimize=True)
        images[path] = image
        table[path] = dict(size=list(image.size), pivot=list(pivot), sha256=sha(dest))
        generated_sources[path] = source
        add(path, anchor, layer=layer, pivot=pivot)

    # Geological front faces before the floor, exactly as assemble.py.
    for a, b, side in [((0, 0), (0, H), "down"), ((0, H), (W, H), "up")]:
        pa, pb = p(*a), p(*b)
        width = pb[0] - pa[0]
        slope = .5 if side == "down" else -.5
        band = images[f"cliff/straight_{side}_flat.png"].resize((width, 175), L)
        rise = round(abs(slope) * width)
        strip = band.transform((width, 175 + rise), Image.Transform.AFFINE,
                               (1, 0, 0, -slope, 1, -rise if slope < 0 else 0), Image.Resampling.BICUBIC)
        derived("cliff_" + side, strip, (pa[0], min(pa[1], pb[1]) - 7), reference/f"final/cliff/straight_{side}_flat.png")
    for x in range(W):
        if not cell("~B", x, 0):
            add("perimeter/edge_nw.png", p(x, 1), layer="terrain")
    for y in range(H):
        if not cell("~B", W - 1, y):
            add("perimeter/edge_ne.png", p(W - 1, y + 1), layer="terrain")
    add("terrain/ground_unique_field.png", p(0, 0), layer="terrain")

    def boundary(cells):
        from collections import defaultdict
        group = defaultdict(list)
        for x, y in sorted(cells):
            for neighbor, axis, fixed, start in [((x, y-1), "x", y, x), ((x, y+1), "x", y+1, x), ((x-1, y), "y", x, y), ((x+1, y), "y", x+1, y)]:
                if neighbor not in cells:
                    group[axis, fixed].append(start)
        for (axis, fixed), values in sorted(group.items()):
            values = sorted(set(values))
            start = previous = values[0]
            for value in values[1:] + [10**6]:
                if value != previous + 1:
                    yield ((start, fixed), (previous+1, fixed)) if axis == "x" else ((fixed, start), (fixed, previous+1))
                    start = value
                previous = value

    # One global material field per area: no per-cell UV seams or internal curbs.
    for cat, chars in [("water", "~B"), ("road", "=Xm")]:
        cells = {(x, y) for y in range(H) for x in range(W) if cell(chars, x, y)}
        mask = Image.new("L", (SIZE[0]*2, SIZE[1]*2))
        d = ImageDraw.Draw(mask)
        for x, y in cells:
            d.polygon([(a*2, b*2) for a, b in [p(x,y), p(x+1,y), p(x+1,y+1), p(x,y+1)]], fill=255)
        mask = mask.resize(SIZE, L)
        field = Image.new("RGBA", SIZE)
        material = images[f"terrain/{cat}_material.png"]
        for y in range(0, SIZE[1], material.height):
            for x in range(0, SIZE[0], material.width):
                field.paste(material, (x, y))
        field.putalpha(mask)
        box = mask.getbbox()
        derived(cat + "_field", field.crop(box), box[:2], reference/f"final/terrain/{cat}_material.png")
        for a, b in boundary(cells):
            pa, pb = p(*a), p(*b)
            side = "down" if pb[1] > pa[1] else "up"
            width = pb[0] - pa[0]
            # The supplied 128px rails are segments of continuous affine rails.
            # Rebuild whole runs from the supplied flat artwork for identical joins.
            flat = Image.open(reference / f"edges/{cat}/straight_{side}_flat.png").convert("RGBA")
            band = Image.new("RGBA", (width, flat.height))
            from PIL import ImageOps
            for i, xx in enumerate(range(0, width, flat.width)):
                band.paste(ImageOps.mirror(flat) if i % 2 else flat, (xx, 0))
            slope = .5 if side == "down" else -.5
            rise = round(width*.5)
            strip = band.transform((width, flat.height+rise), Image.Transform.AFFINE,
                                   (1,0,0,-slope,1,-rise if slope<0 else 0),Image.Resampling.BICUBIC)
            derived(f"{cat}_{a[0]}_{a[1]}_{b[0]}_{b[1]}", strip, (pa[0], min(pa[1], pb[1])-3), reference/f"edges/{cat}/straight_{side}_flat.png")
        for vy in range(H+1):
            for vx in range(W+1):
                q = [xy in cells for xy in [(vx-1,vy-1),(vx,vy-1),(vx,vy),(vx-1,vy)]]
                if sum(q) in (1, 3):
                    kind = "outer" if sum(q)==1 else "inner"
                    index = q.index(True) if kind=="outer" else q.index(False)
                    add(f"{cat}/{kind}_corner_q{index}.png", p(vx,vy), layer="terrain")
    add("terrain/entrance_external_road.png", p(0, 9), layer="terrain")
    bridges, seen = [], set()
    for y in range(H):
        for x in range(W):
            if not cell("B", x, y) or (x,y) in seen:
                continue
            todo, group = [(x,y)], []
            while todo:
                a,b = todo.pop()
                if (a,b) in seen or not cell("B",a,b):
                    continue
                seen.add((a,b)); group.append((a,b))
                todo.extend([(a-1,b),(a+1,b),(a,b-1),(a,b+1)])
            bridges.append(group)
            center = p((min(a for a,b in group)+max(a for a,b in group)+1)/2,
                       (min(b for a,b in group)+max(b for a,b in group)+1)/2)
            add("bridge/bridge_water_y.png", center, layer="terrain")

    names = {"E":"entrance","W":"watchtower","L":"bait_treasure","K":"barracks","R":"recovery_nest","C":"ward_core","T":"throne","V":"vault"}
    for building in buildings:
        bx,by,bw,bh = building["rect"]
        side = building["door"]
        building.update(id=names[building["code"]], fixed=building["code"] in "ETV")
        if building["code"] == "E":
            continue
        length = bw if side in "NS" else bh
        choices = []
        for start in range(length-1):
            inside, outside = [], []
            for j in (start,start+1):
                if side=="N": inside.append((bx+j,by));outside.append((bx+j,by-1))
                elif side=="S": inside.append((bx+j,by+bh-1));outside.append((bx+j,by+bh))
                elif side=="W": inside.append((bx,by+j));outside.append((bx-1,by+j))
                else: inside.append((bx+bw-1,by+j));outside.append((bx+bw,by+j))
            score = sum(3 if cell("=XB",x,y) else 2 if cell("m",x,y) else 0 for x,y in outside)
            choices.append((score,-abs((start+1)-length/2),start,inside,outside))
        _,_,start,inside,outside = max(choices)
        assert all(cell("=XmB",x,y) for x,y in outside)
        gap = set(inside)
        for x,y in inside:
            add("building/threshold.png", p(x+.5,y+.5), layer="terrain")
        dc = (bx+start+1,by) if side=="N" else (bx+start+1,by+bh) if side=="S" else (bx,by+start+1) if side=="W" else (bx+bw,by+start+1)
        building.update(door_cell=list(dc), door_outside=outside, arch="up" if side in "NS" else "down")
        for x in range(bx,bx+bw):
            if not (side=="N" and (x,by) in gap): add("building/back_nw.png",p(x,by+1))
            if not (side=="S" and (x,by+bh-1) in gap): add("building/front_se.png",p(x,by+bh))
        for y in range(by,by+bh):
            if not (side=="E" and (bx+bw-1,y) in gap): add("building/back_ne.png",p(bx+bw-1,y+1))
            if not (side=="W" and (bx,y) in gap): add("building/front_sw.png",p(bx,y+1))
        add("building/back_corner.png",p(bx+bw-1,by+1))
        add("building/front_corner.png",p(bx,by+bh))
        anchor = p(*dc)
        add("building/door_arch_"+building["arch"]+".png",anchor,anchor[1]+1, building=building["id"])

    monsters, traps = [], []
    for y in range(H):
        for x in range(W):
            anchor = p(x+.5,y+.5)
            if rows[y][x]=="X":
                kind = "spikes" if (x+y)%2==0 else "sticky"
                add(f"traps/{kind}.png",anchor,cell=[x,y]);traps.append(dict(cell=[x,y],kind=kind))
            if rows[y][x]=="m":
                kind = ["slime","goblin"][(x+y)%2]
                add(f"monsters/{kind}.png",anchor,anchor[1]+2,cell=[x,y],facing="down")
                monsters.append(dict(cell=[x,y],kind=kind,facing="down"))
    for b in buildings:
        if b["code"]=="E": continue
        bx,by,bw,bh = b["rect"]
        add("interiors/"+b["id"]+".png",p(bx,by+bh),p(bx+bw/2,by+bh/2)[1]+12,building=b["id"])
    anchor = p(.25,9)
    add("interiors/entrance.png",anchor,anchor[1]+5,building="entrance")
    # v7d draws the outside bridge after the object pass; preserve that overlap.
    add("bridge/entrance_bridge.png",p(-1.7,9),layer="entrance_bridge")
    # Stable order for equal foot depths matches Python's reference sort.
    ordered = [n for n in nodes if n["layer"]=="terrain"]
    ordered += sorted((n for n in nodes if n["layer"]=="objects"),key=lambda n:n["depth"])
    ordered += [n for n in nodes if n["layer"]=="entrance_bridge"]
    layout = dict(id="approved_v7d_E",grade="E",size=[W,H],tile_size=[128,64],
                  rows=rows,buildings=buildings,bridges=bridges,traps=traps,monsters=monsters,
                  projection="X_iso=y; Y_iso=W-x",origin=[2304,512],
                  full_camera=dict(scale=.48,center=[1856,1260]),
                  default_camera=dict(scale=.75,center=list(p(18,9))),
                  background=dict(asset="background/cave_background.png",position=[-144,135],size=[4000,2250]),
                  assets=table,draw_list=ordered)
    write(DATA/"layout.json",layout)
    # Preserve assembly references and provenance without copying previews/builds.
    SOURCE.mkdir(parents=True,exist_ok=True)
    for cat in ("road", "water"):
        for side in ("up", "down"):
            dest = SOURCE / "assembly_rails" / cat / f"straight_{side}_flat.png"
            dest.parent.mkdir(parents=True,exist_ok=True)
            shutil.copy2(reference/f"edges/{cat}/straight_{side}_flat.png",dest)
    for name in ["SOURCE.md","SOURCE_v7b.md","SOURCE_v7c.md","SOURCE_v7d.md","assemble.py","assemble_v7.py","assemble_v7c.py","assemble_v7d.py"]:
        # Normalize only the final blank lines in archived text, not its logic.
        (SOURCE/("reference_"+name)).write_text((reference/name).read_text(encoding="utf-8-sig").rstrip("\r\n")+"\n",encoding="utf-8")
    text = ["# Approved v7d map import — 2026-10-16", "", "- Generation model: GPT internal image generation",
            "- Generated date: 2026-10-16", "- Target version: v1.3.0", "",
            "User-approved external assets_v7d artwork; no new generation calls in this session.",
            "The final table's SHA256, dimensions, native alpha and pivots are preserved.",
            "Derived images only assemble source artwork with coverage masks or affine placement.",
            "No background removal, recolor, synthetic decoration or changes to original pixels.", "",
            "Source folder: `"+reference.as_posix()+"`", "Plan: `"+args.plan.as_posix()+"`", "",
            "Approved packed pieces and assembly rails are also preserved here as source copies.",
            "Raw generation originals, prompts and processing history remain in the external source folder;",
            "the reference_SOURCE*.md files record their history. Those historical paths are not runtime mappings.", "",
            "## Source copies", ""]
    for r in records:
        text.append("- Source image path: "+(SOURCE/"approved_final"/r["path"]).relative_to(REPO).as_posix())
    for src in sorted((SOURCE/"assembly_rails").rglob("*.png")):
        text.append("- Source image path: "+src.relative_to(REPO).as_posix())
    text.extend(["", "## Runtime images", ""])
    for r in records:
        text.append("- Runtime image path: "+(ART/r["path"]).relative_to(REPO).as_posix())
    for name, src in sorted(generated_sources.items()):
        text.append("- Runtime image path: "+(ART/name).relative_to(REPO).as_posix())
    text.extend(["", "## Derived assembly inputs", ""])
    for name, src in sorted(generated_sources.items()):
        text.append("- `"+name+"` ← `"+src.relative_to(reference).as_posix()+"`")
    (SOURCE/"SOURCE.md").write_text("\n".join(text)+"\n",encoding="utf-8")
    print(f"Imported {len(records)} approved pieces; {len(table)-len(records)} geometric assemblies; {len(ordered)} image nodes; {len(monsters)} defenders.")


if __name__ == "__main__":
    main()
