from pathlib import Path
if Path('assets/source/imagegen/v130r_step7_crumpled_map/HISTORICAL_SOURCE.md').exists():
 raise SystemExit('Step7 candidate is archived; preserve adopted 0103 runtime sheets. See assets/source/imagegen/v130r_step8_crumpled_map/SOURCE.md.')
from PIL import Image
from scipy import ndimage
import numpy as np,json
source=Path('assets/source/imagegen/v130r_step7_crumpled_map/generated_atlas_v2.png')
im=Image.open(source).convert('RGBA');a=np.array(im)[:,:,3]
labels,n=ndimage.label(a>=24);objects=ndimage.find_objects(labels);areas=np.bincount(labels.ravel())
parts=[]
for k,sl in enumerate(objects,1):
 if areas[k]>=500:
  y,x=sl;parts.append((x.start,y.start,x.stop,y.stop))
assert len(parts)==32
parts.sort(key=lambda b:(b[1]+b[3])/2)
ordered=[]
for row in range(8): ordered.extend(sorted(parts[row*4:row*4+4],key=lambda b:(b[0]+b[2])/2))
folder=Path('assets/sprites/v130r/quarter_final/crumpled_map');metrics=[]
for direction,start in [('sw',0),('ne',16)]:
 sheet=Image.new('RGBA',(1024,1024));frames=[]
 for index in range(16):
  b=ordered[start+index]
  crop=(max(0,b[0]-3),max(0,b[1]-3),min(im.width,b[2]+3),min(im.height,b[3]+3))
  tile=im.crop(crop);tile.thumbnail((232,230),Image.Resampling.LANCZOS)
  frames.append(tile);sheet.alpha_composite(tile,((index%4)*256+(256-tile.width)//2,(index//4)*256+238-tile.height))
  metrics.append({'direction':direction,'index':index,'source_bbox_alpha24':b,'raw_rectangular_crop':crop,'size':tile.size})
 sheet.save(folder/('crumpled_map_sheet'+('_ne' if direction=='ne' else '')+'.png'),optimize=True)
 frames[2].save(folder/f'crumpled_map_hurt_{direction}.png')
review={'species_id':'crumpled_map','status':'STEP7_NEW_GPT_V2_INTEGRATED','grid':[4,4],'sheet_size':[1024,1024],'source':source.as_posix(),'unique_poses_per_direction':16,'alpha_extrema':[0,254],'crop_method':'32 separated alpha24 connected body bounds plus3px raw rectangular padding; no masks or alpha edits; rows grouped by body center','frames':metrics}
(folder/'art_review.json').write_text(json.dumps(review,indent=2),encoding='utf-8')
p=source.parent/'SOURCE.md';s=p.read_text(encoding='utf-8').replace('Only equal-cell cropping, alpha-bounds rectangular cropping','The generator did not use equal row spacing, so equal-grid cropping was rejected before adoption. Only 32 separated body-component bounds with3px raw rectangular padding, alpha-bounds rectangular cropping');p.write_text(s,encoding='utf-8')
