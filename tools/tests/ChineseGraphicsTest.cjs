const fs=require('node:fs'),zlib=require('node:zlib'),assert=require('node:assert/strict'),path=require('node:path');
const root=path.resolve(__dirname,'../..');
function png(file,inspectAlpha=false) {
  const b=fs.readFileSync(path.join(root,file));assert.equal(b.subarray(1,4).toString(),'PNG');
  const width=b.readUInt32BE(16),height=b.readUInt32BE(20),depth=b[24],type=b[25];
  const result={path:file,width,height,bytes:b.length};
  if(!inspectAlpha)return result;
  assert.equal(depth,8);assert.equal(type,6,'real RGBA required');assert.equal(b[28],0,'noninterlaced PNG');
  const parts=[];let p=8;
  while(p<b.length){let n=b.readUInt32BE(p),kind=b.toString('ascii',p+4,p+8);if(kind==='IDAT')parts.push(b.subarray(p+8,p+8+n));p+=n+12;}
  const raw=zlib.inflateSync(Buffer.concat(parts)),stride=width*4;let prev=Buffer.alloc(stride),pos=0,zero=0,partial=0,opaque=0;
  const paeth=(a,b,c)=>{let p=a+b-c,pa=Math.abs(p-a),pb=Math.abs(p-b),pc=Math.abs(p-c);return pa<=pb&&pa<=pc?a:pb<=pc?b:c;};
  for(let y=0;y<height;y++) {
    const filter=raw[pos++],row=Buffer.from(raw.subarray(pos,pos+stride));pos+=stride;assert.ok(filter<=4);
    for(let x=0;x<stride;x++){let a=x>=4?row[x-4]:0,b=prev[x],c=x>=4?prev[x-4]:0;let delta=filter===1?a:filter===2?b:filter===3?Math.floor((a+b)/2):filter===4?paeth(a,b,c):0;row[x]=(row[x]+delta)&255;}
    for(let x=3;x<stride;x+=4){let a=row[x];if(a===0)zero++;else if(a===255)opaque++;else partial++;}
    prev=row;
  }
  assert.ok(zero>0 && opaque>0,'transparent background and visible pixels');
  return {...result,alpha_zero:zero,alpha_partial:partial,alpha_opaque:opaque};
}
const expected={'store/header_capsule.png':[920,430],'store/small_capsule.png':[462,174],'store/main_capsule.png':[1232,706],'store/vertical_capsule.png':[748,896],'library/capsule.png':[600,900],'library/header.png':[920,430],'library/logo.png':[1280,720]};
const images=[];
for(const [file,size]of Object.entries(expected)){let info=png('marketing/steam/schinese/'+file,file==='library/logo.png');assert.deepEqual([info.width,info.height],size);images.push(info);}
images.push(png('assets/source/imagegen/steam_chinese_title_local_candidate/chinese_logo_generated.png',true));
const promo=png('marketing/steam/promo/promo_schinese.png');assert.deepEqual([promo.width,promo.height],[1672,941]);images.push(promo);
assert.ok(fs.readFileSync(path.join(root,promo.path)).equals(fs.readFileSync(path.join(root,'assets/source/imagegen/steam_chinese_promo_local_candidate/chinese_promo_generated.png'))),'promo original preserved');
console.log(JSON.stringify({result:'PASS',images},null,2));
