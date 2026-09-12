"""Measure native alpha atlas regions for runtime drawing. Never rewrites PNG pixels."""
import json
from pathlib import Path
from PIL import Image
import numpy as np

def components(mask):
 h,w=mask.shape
 active=mask.copy()
 found=[]
 for yy,xx in zip(*np.where(mask)):
  if not active[yy,xx]: continue
  stack=[(int(xx),int(yy))]
  active[yy,xx]=False
  x0=x1=int(xx);y0=y1=int(yy);area=0
  while stack:
   x,y=stack.pop();area+=1
   x0=min(x0,x);x1=max(x1,x);y0=min(y0,y);y1=max(y1,y)
   for nx,ny in ((x-1,y),(x+1,y),(x,y-1),(x,y+1)):
    if 0<=nx<w and 0<=ny<h and active[ny,nx]:
     active[ny,nx]=False;stack.append((nx,ny))
  found.append((area,x0,y0,x1+1,y1+1))
 return sorted(found,reverse=True)

def measure(id,path):
 a=np.asarray(Image.open(path))
 if a.shape[2]!=4: raise ValueError(id+': missing native alpha')
 a=a[:,:,3];h,w=a.shape
 masses=(a>128).sum(axis=1)
 ys=[0]+[min(range(int(h*i/4)-25,int(h*i/4)+26),key=lambda v:(masses[v],abs(v-h*i/4))) for i in [1,2,3]]+[h]
 raw=[];bounds=[]
 for row in range(4):
  for col in range(4):
   left=round(w*col/4);right=round(w*(col+1)/4)
   region=a[ys[row]:ys[row+1],left:right]
   parts=components(region>160)
   if not parts: raise ValueError(id+': empty frame')
   area,x0,y0,x1,y1=parts[0]
   # Include detached nearby sparks, but exclude neighboring characters' edge fragments.
   for part in parts[1:]:
    n,bx0,by0,bx1,by1=part
    # A detached piece entering from a cell edge belongs to the neighboring pose.
    if bx0==0 or by0==0 or bx1==region.shape[1] or by1==region.shape[0]: continue
    distance=max(x0-bx1,bx0-x1,y0-by1,by0-y1,0)
    if n>=max(12,area*0.002) and distance<20:
     x0=min(x0,bx0);y0=min(y0,by0);x1=max(x1,bx1);y1=max(y1,by1)
   raw.append([left,ys[row],right-left,ys[row+1]-ys[row]])
   bounds.append([max(0,x0-2),max(0,y0-2),min(region.shape[1],x1+2),min(region.shape[0],y1+2)])
 rects=[];margins=[];visible=[]
 for i,(r,b) in enumerate(zip(raw,bounds)):
  row=i//4;anchor=b[3] if row==0 else max(bounds[row*4+j][3] for j in range(4))
  # Keep a soft-alpha halo around the body without changing its display scale.
  v=[max(0,b[0]-10),max(0,b[1]-10),min(r[2],b[2]+10),min(r[3],b[3]+10)]
  # Soft halo may reach an excluded neighbor fragment; stop before its opaque pixels.
  cell=a[r[1]:r[1]+r[3],r[0]:r[0]+r[2]]
  for side in ['left','right','top','bottom']:
   if side=='right':
    hits=np.where(cell[v[1]:v[3],b[2]:v[2]]>160)[1]
    if hits.size: v[2]=b[2]+int(hits.min())
   elif side=='left':
    hits=np.where(cell[v[1]:v[3],v[0]:b[0]]>160)[1]
    if hits.size: v[0]+=int(hits.max())+1
   elif side=='bottom':
    hits=np.where(cell[b[3]:v[3],v[0]:v[2]]>160)[0]
    if hits.size: v[3]=b[3]+int(hits.min())
   else:
    hits=np.where(cell[v[1]:b[1],v[0]:v[2]]>160)[0]
    if hits.size: v[1]+=int(hits.max())+1
  rects.append([r[0]+v[0],r[1]+v[1],v[2]-v[0],v[3]-v[1]])
  margins.append([(384-r[2])/2+v[0],346-anchor+v[1],384-(v[2]-v[0]),384-(v[3]-v[1])])
  visible.append([(384-r[2])/2+b[0],346-anchor+b[1],b[2]-b[0],b[3]-b[1]])
 return {'path':'res://'+path.as_posix(),'frame_size':[384,384],'regions':rects,'margins':margins,'visible_bounds':visible,'idle_height':float(np.median([bounds[i][3]-bounds[i][1] for i in [0,1]])),'rows':ys,'alpha_format':'RGBA','idle_boxes':bounds[:2]}

if __name__=='__main__':
 out={p.name.removesuffix('_sheet.png'):measure(p.name.removesuffix('_sheet.png'),p) for p in sorted(Path('assets/sprites/uiux3d').glob('*_sheet.png'))}
 Path('data/uiux_actor_art.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
 print(json.dumps({k:{'height':v['idle_height'],'rows':v['rows']} for k,v in out.items()}))
