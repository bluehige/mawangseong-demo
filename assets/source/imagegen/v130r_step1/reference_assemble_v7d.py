from pathlib import Path
from PIL import Image
import numpy as np
import json,hashlib,csv
R=Path(__file__).resolve().parent
B=R.parent/'assets_v7c'
def P(x,y): return np.array([64*(x+y-32)+2304,32*(y+32-x)+512])
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def write(p,o): (R/p).write_text(json.dumps(o,ensure_ascii=False,indent=2),encoding='utf-8')
raw=Image.open(R/'source/entrance_bridge.png').convert('RGBA')
a=np.array(raw.getchannel('A'));assert a.min()==0 and a.max()==255
# Affine assembly only: two deck axes align to the unchanged isometric grid.
source_anchor=np.array([1330.,135.])
source_axes=np.array([[-1100.,180.],[610.,95.]])
world_anchor=P(-1.7,9)
world_axes=np.column_stack((P(-13,9)-world_anchor,P(-1.7,11)-world_anchor))
M=world_axes@np.linalg.inv(source_axes)
t=world_anchor-M@source_anchor
corners=np.array([[0,0],[raw.width,0],[0,raw.height],[raw.width,raw.height]])@M.T+t
lo=np.floor(corners.min(axis=0)).astype(int);hi=np.ceil(corners.max(axis=0)).astype(int)
inv=np.linalg.inv(M);off=inv@(lo-t)
part=raw.transform(tuple(hi-lo),Image.Transform.AFFINE,tuple([inv[0,0],inv[0,1],off[0],inv[1,0],inv[1,1],off[1]]),Image.Resampling.BICUBIC)
bbox=part.getbbox();part=part.crop(bbox);lo+=np.array(bbox[:2])
out=R/'final/bridge/entrance_bridge.png';out.parent.mkdir(parents=True,exist_ok=True);part.save(out)
canvas=Image.open(B/'assembly_cave_native.png').convert('RGBA');canvas.alpha_composite(part,tuple(lo))
canvas.save(R/'assembly_cave_native.png')
world=Image.open(B/'assembly_native.png').convert('RGBA');world.alpha_composite(part,tuple(lo));world.save(R/'assembly_native.png')
layer=Image.new('RGBA',canvas.size);layer.alpha_composite(part,tuple(lo));layer.save(R/'layers/entrance_bridge.png')
def camera(im,f,c,size=(1920,1080)):
 w,h=size
 return im.transform(size,Image.Transform.AFFINE,(1/f,0,c[0]-w/2/f,0,1/f,c[1]-h/2/f),Image.Resampling.BICUBIC).convert('RGB')
bg=Image.open(B/'source/cave_background.png').convert('RGBA').resize((4000,2250),Image.Resampling.LANCZOS)
origin=np.array([-144,135])
def render(f,c):
 c=np.array(c)
 view=camera(bg,f,c-origin).convert('RGBA')
 def overlay(im,position):
  cc=c-np.array(position);w,h=view.size
  view.alpha_composite(im.transform(view.size,Image.Transform.AFFINE,(1/f,0,cc[0]-w/2/f,0,1/f,cc[1]-h/2/f),Image.Resampling.BICUBIC))
 overlay(Image.open(B/'assembly_native.png').convert('RGBA'),(0,0))
 overlay(part,lo)
 return view.convert('RGB')
render(.48,(1856,1260)).save(R/'preview_full.png')
# Shift the detail camera toward the bridge so both the gateway and outside landing are visible.
render(1.1,(800,1870)).save(R/'entrance_close.png')
manifest=json.loads((R/'checks/final_manifest.json').read_text(encoding='utf-8'))
rec=dict(manifest[0]);pivot=world_anchor-lo
rec.update(name='bridge_entrance_bridge',path='bridge/entrance_bridge.png',width=part.width,height=part.height,pivot_x=float(pivot[0]),pivot_y=float(pivot[1]),pivot_normalized_x=float(pivot[0]/part.width),pivot_normalized_y=float(pivot[1]/part.height),anchor='P(-1.7,9), northeast deck endpoint',world_top_left=','.join(map(str,lo)),source='source/entrance_bridge.png',sha256=sha(out),notes='GPT native alpha; plank/rope/stone E bridge; 2-cell deck; northeast entrance to southwest cave floor; affine assembly only')
manifest=[e for e in manifest if e['path']!='bridge/entrance_bridge.png'];manifest.append(rec);write('checks/final_manifest.json',manifest)
with (R/'final/asset_table.csv').open('w',newline='',encoding='utf-8-sig') as f:
 w=csv.DictWriter(f,fieldnames=list(manifest[0]));w.writeheader();w.writerows(manifest)
write('final/bridge/entrance_bridge_placement.json',dict(world_top_left=lo.tolist(),anchor=world_anchor.tolist(),deck_endpoints=[world_anchor.tolist(),P(-13,9).tolist()],width_cells=2,screen_axis_slope=-.5,affine_matrix=M.tolist(),source_anchor=source_anchor.tolist()))
before=json.loads((R/'checks/v7c_preserved_hashes.json').read_text(encoding='utf-8'))
assert all(sha(B/p)==h for p,h in before.items())
for e in manifest: assert sha(R/'final'/e['path'])==e['sha256'],e['path']
for p in ['preview_full.png','entrance_close.png','final/bridge/entrance_bridge.png']: Image.open(R/p).verify()
checks=dict(result='PENDING_VISUAL',v7c_files_preserved=len(before),native_alpha_range=[int(a.min()),int(a.max())],transparent_fraction=float((a==0).mean()),bridge_width_cells=2,deck_axis_slope=-.5,outputs={p:list(Image.open(R/p).size) for p in ['preview_full.png','entrance_close.png','final/bridge/entrance_bridge.png']},final_manifest_verified=len(manifest),assembly_only=True,game_code_changed=False,godot_run=False,commit_made=False)
write('checks/v7d_validation.json',checks);write('verify.json',checks)
print(json.dumps(checks,ensure_ascii=False,indent=2))
