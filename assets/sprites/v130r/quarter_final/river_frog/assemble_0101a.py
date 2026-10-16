"""0101a: crop, uniformly resize, align, assemble; never launch Godot."""
from pathlib import Path
import sys, json, hashlib, shutil, importlib.util
from PIL import Image, ImageDraw, ImageFont
import numpy as np
from scipy import ndimage

ROOT=Path(__file__).resolve().parents[5]
EXT=Path.home()/'Desktop'/'\uc9c4\ud589\uc911\uc778\ud504\ub85c\uc81d\ud2b8'/'_mockup'
OUT=ROOT/'_mockup/monsters_v130r/quarter_final'
RUNTIME=ROOT/'assets/sprites/v130r/quarter_final'
IDS=['river_frog','glue_snail','bridge_troll','under_bed_shadow','crumpled_map']
NAMES=['\ud401\ub2f9','\ub290\ub9bf','\ubc99\ubc99','\uc27f','\uaf2c\uae43']
L=Image.Resampling.LANCZOS
EDGES=[0,313,627,940,1254]
ANIMS={'idle_down':[0,1],'down':[2,3],'move_down':[4,5,6,7],'attack_down':[8,9,10,11],'skill_down':[12,13,14,15]}
PATCHES={
 'river_frog':{'attempt':2,'cols':2,'rows':1,'keys':[[2,2],[3,2]],'poses':['SW attack contact: short low frog paper shove toward DOWN LEFT, keep paper/hat/pouch; mouth low, no looking up','SW skill strongest: small water glint ATTACHED close to hands, NO floating bubbles, face low on southwest side']},
 'glue_snail':{'attempt':3,'cols':3,'rows':2,'keys':[[2,0],[2,1],[2,2],[3,0],[3,1],[3,2]],'poses':['SW attack windup','SW attack strike short sticky spit ATTACHED close to mouth DOWN LEFT','SW attack contact short sticky spit ATTACHED within silhouette near DOWN LEFT base','SW skill gather tiny glossy slime at base','SW skill prepare tiny glossy slime at base','SW skill strongest glossy slime hugging base; no distant particles']},
 'bridge_troll':{'attempt':3,'cols':2,'rows':2,'keys':[[3,0],[3,3],[4,0],[4,3]],'poses':['SW skill gather: protective wooden sign brace','SW skill settle: return wooden sign to chest','SW hit startle, worried eyes angled down-left','SW hit recover wooden sign at chest, face angled down-left']},
 'under_bed_shadow':{'attempt':2,'cols':3,'rows':2,'keys':[[2,2],[2,3],[2,5],[2,6],[2,7]],'poses':['SW attack contact: thin hands gently grab DOWN LEFT, hands kept close to body','SW attack recover: retract hands close beneath hood, never extend toward adjacent cell','NE REAR attack strike: back of hood, thin hands reach toward UPPER RIGHT, no face','NE REAR attack contact: back of hood, thin hands toward UPPER RIGHT, no face','NE REAR attack recover: back of hood, hands retract, no face','NE REAR hit reaction startle: back of hood, no face']}}
def dump(p,v):
    p.parent.mkdir(parents=True,exist_ok=True)
    p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def sha(p): return hashlib.sha256(p.read_bytes()).hexdigest()
def fit(im,w,h):
    im=im.convert('RGBA');b=im.getchannel('A').point(lambda a:255 if a>=8 else 0).getbbox()
    im=im.crop(b);im.thumbnail((w,h),L);return im
def label(im,xy,s,size=20,color='#eee9dc'):
    ImageDraw.Draw(im).text(xy,s,font=ImageFont.truetype('C:/Windows/Fonts/malgun.ttf',size),fill=color)
def prepare():
    identities={
      'river_frog':'Exactly the teal green plump river frog, droopy amber eyes, pale cream muzzle/belly, broad green leaf hat with water droplet, brown crossbody pouch with round bottle and folded leaf sprig, both hands holding ragged off-white blank paper. Hat TOP elliptical leaf plane dominant, broad back/shoulders behind hat, short belly. No added weapons.',
      'glue_snail':'Exactly the small round lilac snail with droopy patient face, TWO long stalk eyes AND little facial eyes. Cozy rounded spiral HOUSE shell, warm window, little copper-roof chimney, moss and small flowers. Preserve all shell details and flowers; show broad TOP of shell and roof receding upper-right, compressed face low on southwest side. Not a plain spiral shell.',
      'bridge_troll':'Exactly the gentle stocky BLUE-GREY stone troll, moss-covered hair/shoulders, wide ears, two small ivory tusks, worried dark eyes, RED scarf knot, rope shoulder straps, ragged brown lower clothing, both hands holding blank rectangular WOODEN SIGN. Crown and shoulder TOP planes/upper back wider than chest/face. NO mushrooms/new props.',
      'under_bed_shadow':'Exactly small inky-purple soft shadow blob, TWO big luminous lavender round eyes, long thin delicate shy hands, worn off-white bedsheet draped as little ghost hood with stitched seam, tiny holes and curled cloth corners. NO actual bed. Broad hood TOP/back dominates, eyes low on the down-left side, short compressed lower body.',
      'crumpled_map':'Exactly sentient crumpled yellowed ivory parchment map folded into little upright body, weathered ochre creases, expressive ink eyes/smile, curled paper-corner arms with folded paper fingers, small folded feet. Fine dotted routes/trees, EXACTLY THREE tiny throne doodles, NO letters/numbers. Same folded identity, no rods/costume. Broad folded TOP ridges recede upper-right, tiny face compressed low on southwest side.'}
    OUT.mkdir(parents=True,exist_ok=True)
    for sid in IDS:
        folder=OUT/sid;folder.mkdir(exist_ok=True)
        target=RUNTIME/sid;target.mkdir(parents=True,exist_ok=True)
        portrait=ROOT/f'assets/sprites/v130r/{sid}/portrait_{sid}_base.png'
        ref=Image.new('RGBA',(1440,960),'#353442')
        p=fit(Image.open(portrait),530,690);ref.alpha_composite(p,((600-p.width)//2,130))
        label(ref,(20,20),'IDENTITY ONLY / '+sid,26)
        label(ref,(620,20),'MAP CAMERA REFERENCES / 35-45 deg DOWN',24)
        paths=['interiors/barracks.png','interiors/bait_treasure.png','interiors/watchtower.png','bridge/bridge_water_y.png']
        references=[{'role':'identity','path':str(portrait),'sha256':sha(portrait)}]
        for i,part in enumerate(paths):
            path=EXT/'assets_v7d/final'/part;im=fit(Image.open(path),370,320)
            x=620+(i%2)*410;y=115+(i//2)*410
            ref.alpha_composite(im,(x+(390-im.width)//2,y));label(ref,(x,y+330),Path(part).stem,22)
            references.append({'role':'map camera','path':str(path),'sha256':sha(path)})
        ref.save(folder/'reference.png')
        thumb=ref.copy();thumb.thumbnail((900,600),L);thumb.save(folder/'reference_review.png')
        pilot=Image.new('RGBA',(1200,500),'#353442')
        for i,pid in enumerate(['river_frog','bridge_troll','slime']):
            path=ROOT/f'assets/source/imagegen/v130r_quarter_pilot2/{pid}/candidate_C.png'
            im=fit(Image.open(path),370,420);pilot.alpha_composite(im,(i*400+(400-im.width)//2,35))
            label(pilot,(i*400+15,460),pid+' / C',22)
            references.append({'role':'approved0098 C camera','path':str(path),'sha256':sha(path)})
        pilot.save(folder/'approved_C_camera.png')
        thumb=pilot.copy();thumb.thumbnail((960,400),L);thumb.save(folder/'approved_C_camera_review.png')
        dump(folder/'references.json',references)
        prompt='''Use case: stylized-concept. Production transparent combat animation sprite sheet for ONE species SPECIES. Input Image1: approved character on LEFT is IDENTITY and paint style only; actual game bed, chest, watchtower and bridge on RIGHT are CAMERA references. Input Image2: THREE USER-APPROVED 0098 C miniatures are the EXACT TARGET CAMERA; reproduce their elevation, foreshortening and southwest azimuth across every animation frame, not the earlier frontal portraits.
CAMERA: Orthographic 2:1 dimetric looking DOWN 42 degrees above horizontal. TOP planes must occupy AT LEAST as much projected area as front. Crown/back/shoulders broad and deep; body and legs strongly foreshortened. Face low on down-left side, broad forehead/small chin, far eye narrow, looking at ground not up at viewer. Feet stagger diagonally in depth. Tiny translucent horizontal 2:1 elliptical contact shadow, not a long cast shadow. Reference C is mandatory, even in attack/skill frames. Never switch to an eye-level portrait.
IDENTITY
OUTPUT: exactly EIGHT columns by FIVE rows, 40 full-body DISTINCT coherent poses, landscape canvas with generous transparent gutters. Columns1-4 face DOWN-LEFT SOUTHWEST, three-quarter FRONT; columns5-8 face UP-RIGHT NORTHEAST, genuine three-quarter BACK, see back of head/body and backs of props, NO frontal face pasted onto rear, NO horizontal flip. Same 42-degree camera for both directions. Keep correct accessory side by rotating in space.
For EACH four-column half use SAME 0096 frame order: Row1 idle relaxed, idle breathing, defeated kneeling/slumped, defeated low resting. Row2 four consecutive movement frames. Row3 attack windup, strike toward facing direction, contact, recover. Row4 skill gather, prepare, strongest expression, settle. Row5 four separate hit-reaction startle, recoil, compress, recover. Every pose keeps the approved identity/props/palette. No added magic objects. Species actions: ACTION.
Same character scale all40 cells. Contact at50% cell x /85% cell y. All body/limbs/props/effects/shadow fully within each cell with wide empty transparent gutters, no overlap. Enough space for raised props. Hand-painted dimensional cute horror chibi, clean readable at small game size. Native TRANSPARENT RGBA background, genuinely transparent gutters, no grid/panels/labels/numbers/writing/watermark/scene/floor/checkerboard paint. Do NOT depict reference montages. ONLY40 character sprites with small generated contact ellipses. Preserve all faces/props and high camera throughout.'''
        action={'river_frog':'short frog waddle; keep paper, pouch and hat; attack leans/hops down-left holding paper, skill gentle attached water glint', 'glue_snail':'four slow crawl stretch/contractions; attack short attached sticky slime spit; skill attached glossy trail close to base; house travels with body', 'bridge_troll':'four heavy short steps; attack wooden sign shove in facing direction, skill protective sign brace; retain scarf/ropes', 'under_bed_shadow':'four sneaky slides; attack elongated attached thin shadow hands, skill lift cloth corners/protective spread; no extra eyes', 'crumpled_map':'four folded paper-foot steps; attack paper-corner slap, skill inspect own markings/point the wrong way/open arms; three throne doodles stay tiny'}[sid]
        prompt=prompt.replace('SPECIES',sid).replace('\nIDENTITY\n','\nIdentity: '+identities[sid]+'\n').replace('ACTION',action)
        (folder/'prompt_attempt_1.txt').write_text(prompt+'\n',encoding='utf-8')
        (folder/'prompts.md').write_text('# '+sid+' / 0101a\n\n- image_gen; transparent_background=true\n- Image1: reference.png (identity + real map assets)\n- Image2: approved_C_camera.png (approved0098 C camera)\n\n## Attempt1\n\n```text\n'+prompt+'\n```\n',encoding='utf-8')
        dump(folder/'protected_hashes.json',{p.relative_to(ROOT).as_posix():sha(p) for p in (ROOT/f'assets/sprites/v130r/{sid}').glob('*') if p.is_file()})
    print('Prepared five species; native transparency required; no Godot')

def ingest(sid,attempt,path):
    folder=OUT/sid;im=Image.open(path)
    dest=folder/f'generated_attempt_{attempt}.png';shutil.copy2(path,dest)
    a=np.asarray(im.convert('RGBA').getchannel('A'))
    native=im.mode=='RGBA' and int(a.min())==0
    dump(folder/f'generation_attempt_{attempt}.json',{'original':str(path),'sha256':sha(dest),'size':im.size,'mode':im.mode,'native_transparent':native,'alpha':[int(a.min()),int(a.max())],'zero_alpha_pixels':int((a==0).sum()),'partial_alpha_pixels':int(((a>0)&(a<255)).sum())})
    canvas=Image.new('RGBA',im.size,'#353442');canvas.alpha_composite(im.convert('RGBA'));canvas.thumbnail((1000,700),L);canvas.convert('RGB').save(folder/f'attempt_{attempt}_review.png')
    print(sid,attempt,im.size,'native transparent',native)

def retry_prompt(sid,attempt,mode):
    folder=OUT/sid;base=(folder/'prompt_attempt_1.txt').read_text(encoding='utf-8')
    if mode=='sw':
        prompt=base.split('OUTPUT:')[0]+'''CAMERA CORRECTION: create a SQUAT WIDE foreshortened map creature seen clearly from ABOVE, in exact approved C camera. Broad folded paper crown/upper BACK planes extend deep to upper right and cover at least60% of projected body. Tiny face is compressed onto lower-left sloping front panel. Strong southwest three-quarter SIDE aspect: near eye larger, FAR eye narrow/partly around fold, no symmetrical frontal portrait. Short tiny paper feet stagger diagonally. KEEP approved gold paper, folds, dotted routes/trees, exactly3tiny throne doodles and small curled paper hands, no clothing or tools. It must still be the approved paper map creature. Do not change silhouette into a face-on tall flat rectangle.
OUTPUT exactly FOUR columns by FIVE rows=20 distinct SOUTHWEST poses only, all facing DOWN-LEFT. Native transparent RGBA canvas, absolutely NO brown or colored backdrop! transparent_background=true. No checkerboard paint. Portrait canvas, generous wide empty TRANSPARENT gutters. Row1 idle, breath, defeated slump, defeated low rest. Row2 four consecutive paper-foot walk frames. Row3 four paper corner slap frames windup/strike/contact/recover, aimed DOWN-LEFT. Row4 inspect markings/point wrong way/open arms/return. Row5 hit startle/recoil/compress/recover. Maintain same high camera and low compressed tiny face all20. All sprites full-body contained inside separate cells; small GENERATED soft contact ellipse under each. No ground/scenery/grid/text/labels/detached particles. Render only20 cutout sprites. NO opaque background of any color.'''
    elif mode=='ne':
        prompt=base.split('OUTPUT:')[0]+'''OUTPUT REPAIR: ONLY NORTHEAST direction. Portrait canvas exactly FOUR columns by FIVE rows =20 different complete sprites. ALL20 poses face SCREEN UPPER RIGHT in genuine three-quarter REAR view. Camera stays42degrees DOWN, see broad back/crown/shell/hood/paper fold tops. FACE IS HIDDEN IN EVERY CELL INCLUDING LAST COLUMN. Never reset to front for recover, defeated or movement. No frontal eyes/face visible except tiny far-side profile at most. Do not copy a FRONT sprite into final column! No horizontal mirroring. Keep same identity and physical accessory side. Leftmost column and rightmost column BOTH northeast rear. Row1 rear idle, rear breath, rear defeated slump, rear defeated rest. Row2 four consecutive rear moving poses. Row3 rear windup, rear strike aimed upper-right, rear contact, rear recover. Row4 rear skill gather, prepare, strongest, settle. Row5 rear hit startle, recoil, compress, recover. Keep same compact scale and elevation all20. Entire sprites contained in cells with WIDE transparent gutters; no touching neighbours. Generated small horizontal elliptical contact shadows. Native transparent RGBA only. No text/grid/scenery/checkerboard. If a shell creature: the eye stalks emerge on FAR UPPER-RIGHT SIDE of the shell and point AWAY; no face on screen lower-left. If troll, show mossy back in every cell; no frontal face in final hit recover. Image1 is identity+real map angles, Image2 is approvedC CAMERA reference. Do not render other species.'''
    else:
        prompt=base+'''\nCRITICAL CAMERA CORRECTION: previous crumpled_map was too upright and frontal. Reconstruct a TOP-DOWN 45-degree miniature with broad folded crown/upper paper BACK dominating at least 60% of projected body; SHORT compressed front face along lower LEFT edge only, tiny chin. Entire paper torso leans down-left, recedes/deepens upper-right. TOP folds cover most of the center, not a tall flat FRONT sheet. Left four columns show SOUTHWEST 3/4 strongly: face axis points lower-left, near ink eye larger, far ink eye narrow and partly hidden around fold. No symmetric straight-to-viewer face. Right four columns northeast REAR, no face AT ALL including last skill and last hit frames. Exact same camera as frog/troll/slime C. No change to crumpled paper identity, golden color, routes or three tiny throne doodles. Wide transparent gutters, separate40 poses.'''
    (folder/f'prompt_attempt_{attempt}.txt').write_text(prompt+'\n',encoding='utf-8')
    with (folder/'prompts.md').open('a',encoding='utf-8') as f:f.write(f'\n## Attempt{attempt} / {mode}\n\n```text\n'+prompt+'\n```\n')
    print('Prepared retry',sid,attempt,mode)

def patch_prompt(sid):
    spec=PATCHES[sid];folder=OUT/sid;attempt=spec['attempt']
    base=(folder/'prompt_attempt_1.txt').read_text(encoding='utf-8').split('OUTPUT:')[0]
    prompt=base+f'''OUTPUT TARGETED REPAIR ONLY: exactly {spec['cols']} columns x {spec['rows']} rows of full-body isolated animation sprites, {len(spec['poses'])} total. ALL sprites same body size and exact C camera elevation. Output NATIVE TRANSPARENT RGBA, no backdrop. VERY WIDE genuinely transparent gutters: each character occupies only CENTER60% of cell width and CENTER65% of cell height. At least15% EMPTY transparent padding on EVERY edge of EACH cell. Keep limbs/props/shadow/TINY attached effects entirely inside central60% width/65% height. No floating or detached particles, no long trailing effects, no inter-cell contact. Tiny horizontal elliptical contact shadows only. No grid, panels, text, labels, numbers. Input3 is previous generated sheet: identity/palette/props and same C camera only; DO NOT copy its tight spacing. Render ONLY this species.
Exact reading order, left to right then next row:\n'''
    prompt+='\n'.join(f'{i+1}. {pose}.' for i,pose in enumerate(spec['poses']))
    prompt+='\nDo not change which way a pose faces. SW=front three-quarter DOWN LEFT, NE=back three-quarter UPPER RIGHT with face HIDDEN. All poses look downward; never raise chin to camera. No scenery, checkerboard or background color. Native transparency is mandatory.'
    (folder/f'prompt_attempt_{attempt}.txt').write_text(prompt+'\n',encoding='utf-8')
    with (folder/'prompts.md').open('a',encoding='utf-8') as f:f.write(f'\n## Attempt{attempt} / targeted frame repair\n- Image3: generated_attempt_1.png\n\n```text\n'+prompt+'\n```\n')
    dump(folder/'patch_spec.json',spec);print('Prepared patch',sid,attempt)

def contact(im):
    a=np.array(im.getchannel('A'));yy,xx=np.where(a>=192)
    bottom=int(yy.max());band=(a>=192)&(np.indices(a.shape)[0]>=bottom-7)
    weights=np.where(band,a,0).sum(axis=0)
    return float((np.arange(im.width)*weights).sum()/weights.sum()),bottom

def body_height(im):
    a=np.array(im);yy,xx=np.where((a[:,:,3]>=96)&(a[:,:,:3].max(axis=2)>=52))
    return int(yy.max()-yy.min()+1)

def audit_cells(cells,path):
    a=np.array(Image.open(path).convert('RGBA').getchannel('A'));main,n=ndimage.label(a>=96);areas=np.bincount(main.ravel());areas[0]=0
    for rec in cells.values():
        sx,sy,ex,ey=rec['source_slice'];bx,by,bex,bey=rec['source_bbox']
        region=main[sy+by:sy+bey,sx+bx:sx+bex];present=np.bincount(region.ravel(),minlength=len(areas));present[0]=0
        k=int(present.argmax());rec['own_body_cropped_alpha96']=int(areas[k]-present[k]);large=np.where(areas>=max(4000,areas[k]*.4))[0]
        rec['foreign_body_pixels']=int(present[large].sum()-present[k])
    return cells

def extract(path,cols):
    im=Image.open(path).convert('RGBA');a=np.array(im.getchannel('A'))
    result=extract_seams(path,cols)
    main,n=ndimage.label(a>=96);areas=np.bincount(main.ravel());areas[0]=0
    for (row,col),rec in result.items():
        sx,sy,ex,ey=rec['source_slice'];bx,by,bex,bey=rec['source_bbox']
        region=main[sy+by:sy+bey,sx+bx:sx+bex];present=np.bincount(region.ravel(),minlength=len(areas));present[0]=0
        k=int(present.argmax());rec['own_body_cropped_alpha96']=int(areas[k]-present[k])
        large=np.where(areas>=max(4000,areas[k]*.4))[0]
        rec['foreign_body_pixels']=int(present[large].sum()-present[k])
        rec['crop_method']='Sparse seam rectangle then rectangular bounds of significant alpha24 components; all source pixels inside rectangle retained.'
    return result
def extract_seams(path,cols,rows=5):
    im=Image.open(path).convert('RGBA');a=np.array(im.getchannel('A'))
    def seam(counts,e,r):
        lo=max(1,round(e-r));hi=min(len(counts)-1,round(e+r))
        return min(range(lo,hi),key=lambda n:(int(counts[n]),abs(n-e)))
    ys=[0]+[seam((a>=32).sum(axis=1),im.height*k/rows,im.height/rows*.18) for k in range(1,rows)]+[im.height]
    cells={}
    for row in range(rows):
        xs=[0]+[seam((a[ys[row]:ys[row+1]]>=32).sum(axis=0),im.width*k/cols,im.width/cols*.14) for k in range(1,cols)]+[im.width]
        for col in range(cols):
            rect=[xs[col],ys[row],xs[col+1],ys[row+1]];cell=im.crop(rect);ca=np.array(cell.getchannel('A'))
            labels,n=ndimage.label(ca>=24);areas=np.bincount(labels.ravel());areas[0]=0
            keep=np.where(areas>=max(12,areas.max()*.002))[0];yy,xx=np.where(np.isin(labels,keep))
            b=[max(0,int(xx.min())-2),max(0,int(yy.min())-2),min(cell.width,int(xx.max())+3),min(cell.height,int(yy.max())+3)]
            outside=ca.copy();outside[b[1]:b[3],b[0]:b[2]]=0
            edge=np.concatenate([ca[0],ca[-1],ca[:,0],ca[:,-1]])
            cells[row,col]={'image':cell.crop(b),'source_slice':rect,'source_bbox':b,'slice_edge_alpha192':int((edge>=192).sum()),'cropped_residue_alpha8':int((outside>=8).sum()),'source_path':str(path)}
    return cells

def assemble(sid):
    folder=OUT/sid;target=RUNTIME/sid
    accepted=sid!='crumpled_map'
    first=extract(folder/'generated_attempt_1.png',8)
    cells={(r,c):v for (r,c),v in first.items()}
    if sid in ['glue_snail','bridge_troll']:
        repair=extract(folder/'generated_attempt_2.png',4)
        if sid=='glue_snail':
            normalization=body_height(cells[0,4]['image'])/body_height(repair[0,0]['image'])
            for (r,c),v in repair.items():v['source_normalization']=normalization;cells[r,c+4]=v
        else:
            repair[4,3]['source_normalization']=body_height(cells[4,7]['image'])/body_height(repair[4,3]['image']);cells[4,7]=repair[4,3]
    if sid=='crumpled_map':
        sw=extract(folder/'generated_attempt_3.png',4);ne=extract(folder/'generated_attempt_4.png',4)
        cells={(r,c):v for (r,c),v in sw.items()}
        cells.update({(r,c+4):v for (r,c),v in ne.items()})
    if sid in PATCHES:
        patch=PATCHES[sid];path=folder/f"generated_attempt_{patch['attempt']}.png"
        if path.exists():
            fixed=audit_cells(extract_seams(path,patch['cols'],patch['rows']),path)
            for i,key in enumerate(patch['keys']):
                v=fixed[divmod(i,patch['cols'])];old=cells[tuple(key)]
                v['source_normalization']=body_height(old['image'])*old.get('source_normalization',1)/body_height(v['image']);cells[tuple(key)]=v
    dest=target if accepted else folder/'rejected_sheets';dest.mkdir(parents=True,exist_ok=True)
    scale=min(250/max(v['image'].width*v.get('source_normalization',1) for v in cells.values()),250/max(v['image'].height*v.get('source_normalization',1) for v in cells.values()))
    for v in cells.values():
        n=v.get('source_normalization',1);cx,cy=contact(v['image']);scale=min(scale,139/max(1,cx*n),139/max(1,(v['image'].width-cx)*n),270/max(1,cy*n),15/max(1,(v['image'].height-cy)*n))
    meta={'species_id':sid,'status':'ACCEPTED_OFFLINE_NOT_INTEGRATED' if accepted else 'REJECTED_MAX_FOUR_ATTEMPTS','sheet_size':[1254,1254],'grid':[4,4],'cell_edges':EDGES,'logical_frame_size':[384,384],'logical_anchor':[192,345],'atlas_anchor':[156.5,289],'animations':ANIMS,'uniform_scale':scale,'directions':{},'camera_reference':'0098 approved C; requested42deg; visual evaluation only','measurement_note':'Contact is alpha>=192 bottom8px weighted center; not anatomical foot tracking. Original generated alpha retained. No background removal/painting/warp/mirroring.'}
    for direction,offset in [('sw',0),('ne',4)]:
        for hurt in [False,True]:
            atlas=Image.new('RGBA',(1254,313 if hurt else 1254));records=[]
            for index in range(4 if hurt else 16):
                row,col=(4,index) if hurt else divmod(index,4);src=cells[row,col+offset]
                final_scale=scale*src.get('source_normalization',1)
                sprite=src['image'].resize((max(1,round(src['image'].width*final_scale)),max(1,round(src['image'].height*final_scale))),L)
                cx,cy=contact(sprite);celltop=0 if hurt else EDGES[row]
                x=round(EDGES[col]+156.5-cx);y=celltop+289-cy
                assert x>=EDGES[col]+5 and x+sprite.width<EDGES[col+1]-5,(sid,direction,index,'horizontal clip')
                assert y>=celltop+5 and y+sprite.height<(313 if hurt else EDGES[row+1])-5,(sid,direction,index,'vertical clip')
                atlas.alpha_composite(sprite,(x,y))
                record={k:v for k,v in src.items() if k!='image'}
                record.update({'index':index,'rect':[x,y,sprite.width,sprite.height],'cell':[EDGES[col],celltop,EDGES[col+1]-EDGES[col],313 if hurt else EDGES[row+1]-celltop],'contact_x':round(x-EDGES[col]+cx,4),'support_y':289})
                records.append(record)
            filename=f'{sid}_hurt_{direction}.png' if hurt else f'{sid}_sheet'+('_ne' if direction=='ne' else '')+'.png'
            atlas.save(dest/filename,optimize=True)
            meta['directions'].setdefault(direction,{})['hurt' if hurt else 'combat']={'path':str(dest/filename),'frames':records,'sha256':sha(dest/filename)}
    dump(dest/'art_review.json',meta)
    attempts=sorted({int(Path(v['source_path']).stem.rsplit('_',1)[1]) for v in cells.values()})
    dump(folder/'selection.json',{'accepted':accepted,'combat_and_hurt':meta['directions'],'selected_attempts':attempts})
    failures=[(r,c,v['slice_edge_alpha192']) for (r,c),v in cells.items() if v['slice_edge_alpha192']]
    print(sid,'accepted' if accepted else 'REJECTED',40,'poses; source seam alpha192',failures)

def validate():
    report={}
    for sid in IDS:
        folder=OUT/sid;accepted=sid!='crumpled_map';dest=RUNTIME/sid if accepted else folder/'rejected_sheets'
        meta=json.loads((dest/'art_review.json').read_text(encoding='utf-8'))
        summary={'status':meta['status'],'frames':0,'unique_frames':0,'max_contact_x_error':0,'border_alpha_pixels':0,'source_edge_alpha192':0,'cropped_residue_alpha8':0,'own_body_cropped_alpha96':0,'foreign_body_pixels':0,'existing_species_files_changed':[]}
        hashes=set()
        for direction in meta['directions'].values():
            for kind,rec in direction.items():
                im=Image.open(rec['path']);assert im.mode=='RGBA' and im.size==(1254,313 if kind=='hurt' else 1254)
                for f in rec['frames']:
                    x,y,w,h=f['cell'];a=np.array(im.getchannel('A'))[y:y+h,x:x+w];border=a.copy();border[5:-5,5:-5]=0
                    summary['border_alpha_pixels']+=int((border>0).sum())
                    summary['source_edge_alpha192']+=f['slice_edge_alpha192'];summary['cropped_residue_alpha8']+=f['cropped_residue_alpha8']
                    summary['own_body_cropped_alpha96']+=f.get('own_body_cropped_alpha96',0);summary['foreign_body_pixels']+=f.get('foreign_body_pixels',0)
                    summary['max_contact_x_error']=max(summary['max_contact_x_error'],abs(f['contact_x']-156.5));assert f['support_y']==289
                    hashes.add(hashlib.sha256(im.crop((x,y,x+w,y+h)).tobytes()).hexdigest());summary['frames']+=1
                    # Reproduce the atlas rectangle exactly from source pixels + uniform resize.
                    source=Image.open(f['source_path']).convert('RGBA').crop(f['source_slice']).crop(f['source_bbox'])
                    rx,ry,rw,rh=f['rect'];source=source.resize((rw,rh),L)
                    blank=Image.new('RGBA',(rw,rh));blank.alpha_composite(source)
                    assert np.array_equal(np.array(blank),np.array(im.crop((rx,ry,rx+rw,ry+rh)))),(sid,'unexpected image manipulation')
        protected=json.loads((folder/'protected_hashes.json').read_text(encoding='utf-8'))
        summary['existing_species_files_changed']=[p for p,h in protected.items() if sha(ROOT/p)!=h]
        summary['unique_frames']=len(hashes)
        summary['mechanical_pass']=summary['frames']==40 and len(hashes)==40 and summary['border_alpha_pixels']==0 and summary['max_contact_x_error']<=.51 and not summary['existing_species_files_changed'] and summary['own_body_cropped_alpha96']==0 and summary['foreign_body_pixels']==0 and summary['source_edge_alpha192']==0
        dump(folder/'validation.json',summary);report[sid]=summary
    dump(OUT/'validation_0101a.json',report)
    print(json.dumps(report,ensure_ascii=False,indent=2))
    assert all(report[sid]['mechanical_pass'] for sid in IDS if sid!='crumpled_map'),'Adopted frame verification failed'
    assert report['crumpled_map']['status']=='REJECTED_MAX_FOUR_ATTEMPTS'

def load_meta(sid):
    path=(RUNTIME/sid if sid!='crumpled_map' else OUT/sid/'rejected_sheets')/'art_review.json'
    return json.loads(path.read_text(encoding='utf-8'))

def frame(sid,direction,index):
    meta=load_meta(sid);rec=meta['directions'][direction]['combat'];f=rec['frames'][index];x,y,w,h=f['rect']
    return Image.open(rec['path']).convert('RGBA').crop((x,y,x+w,y+h))

def boards():
    board=Image.new('RGBA',(1800,1500),'#353442')
    label(board,(35,15),'0101a / SW idle - move - attack / NE idle',30)
    label(board,(35,58),'T top >= front / F foreshortening / H high face / E ellipse / S southwest',22)
    headers=['SW IDLE 0','SW MOVE 4','SW ATTACK 10','NE IDLE 0']
    for j,h in enumerate(headers):label(board,(280+j*330,104),h,23)
    visual={}
    for i,sid in enumerate(IDS):
        y=155+i*263;accepted=sid!='crumpled_map'
        label(board,(25,y+40),NAMES[i],28);label(board,(25,y+80),sid,17)
        verdict='T O F O H O E O S O' if accepted else 'T X F O H ? E O S X'
        label(board,(25,y+116),'ADOPTED' if accepted else 'REJECTED / 4 calls',19,'#8fe8c2' if accepted else '#ff9a86')
        for j,(d,idx) in enumerate([('sw',0),('sw',4),('sw',10),('ne',0)]):
            im=fit(frame(sid,d,idx),275,205);board.alpha_composite(im,(270+j*330+(275-im.width)//2,y+(205-im.height)))
        label(board,(290,y+220),verdict,22,'#8fe8c2' if accepted else '#ff9a86')
        visual[sid]={'accepted':accepted,'T':accepted,'F':True,'H':True if accepted else None,'E':True,'S':accepted,'note':{'river_frog':'Leaf crown and upper back dominate, short belly, eyes down-left.','glue_snail':'Roof/house crown dominates, compressed face on lower-left, broad oval base.','bridge_troll':'Mossy crown/shoulders/back dominant, small down-left face, staggered short legs.','under_bed_shadow':'Hood crown/back broad, low recessed eyes, short shadow base.','crumpled_map':'Still reads as tall front paper panel; top>=front and SW3/4 not confidently satisfied. FOUR calls exhausted. No runtime adoption.'}[sid]}
    board.save(OUT/'review_0101a.png');small=board.copy();small.thumbnail((1080,900),L);small.convert('RGB').save(OUT/'review_0101a_review.png')
    source=EXT/'game_step2e/radial_barracks.png';mapim=Image.open(source).convert('RGBA')
    mapboard=Image.new('RGBA',(1920,1080),'#292934');label(mapboard,(25,15),'0101a / 0088 defense tile composite / body = tile width x 0.75',28)
    label(mapboard,(25,55),'Offline image assembly; original map pixels retained. Red panel is rejected candidate.',22)
    placements=[];crop=[290,180,650,444];panel_scale=600/360
    for i,sid in enumerate(IDS):
        x=20+(i%3)*635;y=130+(i//3)*465
        patch=mapim.crop(crop).resize((600,440),L);sprite=frame(sid,'sw',0);a=np.array(sprite)
        yy,xx=np.where((a[:,:,3]>=96)&(a[:,:,:3].max(axis=2)>=52));b=[int(xx.min()),int(yy.min()),int(xx.max()+1),int(yy.max()+1)]
        requested=72*panel_scale;s=requested/(b[3]-b[1]);size=(round(sprite.width*s),round(sprite.height*s));resized=sprite.resize(size,L)
        anchor=((472-crop[0])*panel_scale,(342-crop[1])*panel_scale)
        origin=(round(anchor[0]-(b[0]+b[2])/2*s),round(anchor[1]-b[3]*s));patch.alpha_composite(resized,origin)
        mapboard.alpha_composite(patch,(x,y));label(mapboard,(x,y-35),NAMES[i]+' / '+('ADOPTED' if sid!='crumpled_map' else 'REJECTED'),22,'#8fe8c2' if sid!='crumpled_map' else '#ff9a86')
        placements.append({'species':sid,'adopted':sid!='crumpled_map','capture_contact':[472,342],'crop':crop,'panel_scale':panel_scale,'body_box':b,'source_size':list(sprite.size),'size':size,'origin':origin,'capture_tile_width':96,'requested_capture_body_height':72,'body_to_tile':.75,'requested_panel_body_height':requested,'rounded_panel_body_height':(b[3]-b[1])*size[1]/sprite.height})
    mapboard.save(OUT/'on_map_0101a.png');small=mapboard.copy();small.thumbnail((1100,720),L);small.convert('RGB').save(OUT/'on_map_0101a_review.png')
    dump(OUT/'map_composite_0101a.json',{'source':str(source),'sha256':sha(source),'camera_scale':.75,'world_tile':[128,64],'capture_tile_width':96,'placements':placements})
    for sid in IDS:dump(OUT/sid/'visual_decisions.json',visual[sid])
    print('Saved requested review and 0088 map boards + reduced previews')

def provenance():
    for sid in IDS:
        folder=OUT/sid;docdir=ROOT/f'assets/source/imagegen/v130r_quarter_final/{sid}';docdir.mkdir(parents=True,exist_ok=True)
        accepted=sid!='crumpled_map';meta=load_meta(sid)
        lines=[f'# {sid} / 0101a', '', '- Generation model: GPT internal image generation','- Generated date: 2026-10-17','- Target version: v1.3.0',f'- Status: {meta["status"]}', '- Engine integration: none; Godot not launched.','']
        for p in sorted(folder.glob('generated_attempt_*.png')):
            lines.extend(['- Source image path: '+p.relative_to(ROOT).as_posix(),'- Source SHA-256: '+sha(p)])
        for name in ['reference.png','approved_C_camera.png']:
            lines.append('- Source image path: '+(folder/name).relative_to(ROOT).as_posix())
        if accepted:
            for direction in meta['directions'].values():
                for rec in direction.values():lines.append('- Runtime image path: '+Path(rec['path']).relative_to(ROOT).as_posix())
        lines+=['','Exact prompts and supplied reference roles: '+(folder/'prompts.md').relative_to(ROOT).as_posix(),
        'Reference images are crop/resize montages of approved portraits, real v7d map parts and 0098 C originals, not newly painted art. Original image_gen file paths/hashes: generation_attempt_*.json in same mockup species folder.',
        'Processing: rectangular crop, uniform per-image resizing, translation and montage assembly only. Native alpha retained; no painting, warp, mirror or background removal. Patch sources are normalized uniformly to the replaced pose body height; full NE source normalized by idle body height. Faint detached residue outside rectangular significant-component bounds may be omitted; own-body alpha96 loss=0 and foreign primary bodies=0 for all adopted frames.',
        '0096 contract: combat1254x1254;4x4;edges[0,313,627,940,1254];logical frame384x384;logical contact192,345;atlas contact156.5,289. Separate SW/NE hurt1254x313,4frames. Source generation alpha max may be254; never forced opaque.',
        'T/F/H/E/S are visual decisions, not a solved3D camera. Ellipse is partially occluded generated contact shadow; no exact2:1 pixel proof. Details such as tiny moss/flower placement, sheet holes/seams, dotted routes and throne marks vary across generated poses. Existing portraits/cards and historical combat sheets unchanged.',
        'Selected source rectangles and alignment: runtime art_review.json; selection/visual decisions/validation in mockup folder.']
        if not accepted:
            lines+=['','REJECTED: all four calls preserved; front paper surface still dominates / SW angle uncertain. No final runtime PNGs; rejected assembled sheets are in mockup/rejected_sheets only. No more image_gen calls without a new user decision.']
            (RUNTIME/sid/'REJECTED.md').write_text('\n'.join(lines[-2:])+'\n',encoding='utf-8')
        (docdir/'SOURCE.md').write_text('\n'.join(lines)+'\n',encoding='utf-8')
        shutil.copy2(folder/'prompts.md',docdir/'prompts.md')
        shutil.copy2(folder/'validation.json',docdir/'validation.json')
        shutil.copy2(folder/'visual_decisions.json',docdir/'visual_decisions.json')
    print('Saved provenance for five species; no shared CURRENT edits')

def decisions():
    data={
      'river_frog':[(1,'PARTIAL','T/F/H/E/S pass; SW attack10 and skill14 overlap source row boundary; those2 frames rejected'),(2,'ADOPTED','Two SW replacement poses; attached effects, native alpha, all criteria pass')],
      'glue_snail':[(1,'PARTIAL','SW camera criteria pass; some NE frames turn frontal; six SW frames overlap adjacent body/effects'),(2,'ADOPTED_NE','20 genuine NE rear poses; native alpha; selected all NE'),(3,'ADOPTED_SW_PATCH','Six SW attack/skill poses with ample margins; all criteria pass')],
      'bridge_troll':[(1,'PARTIAL','SW camera criteria pass; NE last hurt turns frontal; four SW skill/hurt frames touch source boundaries'),(2,'ADOPTED_ONE_NE','NE rear-only generation; select last hurt recover only'),(3,'ADOPTED_SW_PATCH','Four SW skill/hurt poses; all criteria pass')],
      'under_bed_shadow':[(1,'PARTIAL','Camera criteria pass; SW attack10/11 and NE attack9/10/11 have arms crossing source boundaries'),(2,'ADOPTED_PATCH','Two SW and three NE replacement attack poses; sixth generated NE hurt is unused')],
      'crumpled_map':[(1,'REJECTED','T top>=front not met; S too frontal; some NE final poses face front'),(2,'REJECTED','Still tall front paper panel, T/S insufficient; last NE hurt again front'),(3,'REJECTED_SW','Shorter SW-only20poses but broad front paper panel still dominant; T fails, H uncertain, S insufficient'),(4,'REJECTED_FOR_FINAL','NE-only20poses give genuine rear; full species still fails SW T/H/S. Some NE effects touch source crop edges. Four-call cap reached')]}
    for sid,rows in data.items():
        folder=OUT/sid;dump(folder/'attempt_decisions.json',[{'attempt':a,'status':st,'reason':why} for a,st,why in rows])
        with (folder/'prompts.md').open('a',encoding='utf-8') as f:
            f.write('\n## Selection and rejected-frame table\n\n| Attempt | Status | Reason |\n|---|---|---|\n')
            for a,st,why in rows:f.write(f'| {a} | {st} | {why} |\n')
        docdir=ROOT/f'assets/source/imagegen/v130r_quarter_final/{sid}'
        shutil.copy2(folder/'attempt_decisions.json',docdir/'attempt_decisions.json')
        shutil.copy2(folder/'prompts.md',docdir/'prompts.md')
    print('Recorded14 calls and explicit rejected-frame decisions')

if __name__=='__main__':
    if sys.argv[1]=='prepare': prepare()
    elif sys.argv[1]=='ingest': ingest(sys.argv[2],int(sys.argv[3]),Path(sys.argv[4]))
    elif sys.argv[1]=='retry': retry_prompt(sys.argv[2],int(sys.argv[3]),sys.argv[4])
    elif sys.argv[1]=='patch':patch_prompt(sys.argv[2])
    elif sys.argv[1]=='assemble':
        for sid in (sys.argv[2:] or IDS):assemble(sid)
    elif sys.argv[1]=='validate':validate()
    elif sys.argv[1]=='boards':boards()
    elif sys.argv[1]=='provenance':provenance()
    elif sys.argv[1]=='decisions':decisions()
