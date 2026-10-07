// Local-candidate PCK validation, independent of the export process exit code.
const fs = require('node:fs');
const crypto = require('node:crypto');
const assert = require('node:assert/strict');
const path = require('node:path');
const root = path.resolve(__dirname, '../..');
const packPath = path.resolve(process.argv[2] || path.join(root, 'tmp/zh_cn_work_20261007/windows_candidate/MawangCastle.pck'));
const file = fs.openSync(packPath, 'r');
let cursor = 0;
function bytes(count) { const b = Buffer.alloc(count); assert.equal(fs.readSync(file,b,0,count,cursor),count,'truncated PCK'); cursor += count; return b; }
const u32 = () => bytes(4).readUInt32LE();
const u64 = () => Number(bytes(8).readBigUInt64LE());
assert.equal(u32(),0x43504447,'Godot PCK magic');
const format=u32(),engine=[u32(),u32(),u32()],flags=u32(),dataBase=u64();
assert.deepEqual(engine,[4,6,3]);
assert.equal(flags & 1,0,'unencrypted directory');
if(format===3)cursor=u64();else if(format===2)bytes(64);else throw Error('unknown PCK format '+format);
const count=u32(); assert.ok(count>100 && count<100000);
const entries={};
for(let i=0;i<count;i++) {
  const name=bytes(u32()).toString('utf8').replace(/\0+$/,'').replace(/^res:\/\//,'');
  const offset=u64(),size=u64();bytes(16);const entryFlags=u32();
  assert.ok(!(name in entries),'duplicate packed path '+name);
  entries[name]={offset,size,flags:entryFlags};
}
function entryBytes(name) {
  const entry=entries[name];assert.ok(entry,'missing '+name);
  assert.ok(entry.size>0,'empty '+name);
  const b=Buffer.alloc(entry.size);
  assert.equal(fs.readSync(file,b,0,b.length,dataBase+entry.offset),b.length,'truncated '+name);
  return b;
}
assert.ok(entryBytes('project.binary').length>100,'nonempty project settings');
const verified=[];
for(const name of ['data/localization/ui_zh_cn.json','data/localization/story_zh_cn.json','data/localization/v122_stage10_ui.json','data/localization/ui_en.json','data/localization/story_en.json']) {
  const packed=entryBytes(name),source=fs.readFileSync(path.join(root,name));
  assert.ok(packed.equals(source),'packed catalog differs from reviewed source: '+name);
  verified.push({path:name,bytes:packed.length,sha256:crypto.createHash('sha256').update(packed).digest('hex')});
}
const fontImport=entryBytes('assets/fonts/NotoSansCJKkr-Regular.otf.import').toString('utf8');
const fontPath=fontImport.match(/path="res:\/\/([^"\n]+)"/)[1];
assert.ok(entryBytes(fontPath).length>1000000,'bundled CJK font resource');
for(const original of ['scripts/core/LanguageSettings.gd','scripts/core/EnglishTranslation.gd','scripts/ui/UIFont.gd']) {
  const remap=entryBytes(original+'.remap').toString('utf8');
  const compiled=remap.match(/path="res:\/\/([^"\n]+)"/)[1];
  assert.ok(entryBytes(compiled).length>100,'compiled production script '+original);
}
const forbidden=Object.keys(entries).filter(name=>/^(?:assets\/source|docs|legal|marketing|steam|tmp|output|tools|web_Demo|addons\/steam_release_export_filter)\//.test(name));
assert.deepEqual(forbidden,[],'private source/tests/promotion excluded from runtime');
fs.closeSync(file);
console.log(JSON.stringify({result:'PASS',pack:packPath,engine:engine.join('.'),format,entries:count,project_settings_bytes:entries['project.binary'].size,bundled_font:fontPath,forbidden_paths:0,catalogs:verified},null,2));
