const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const {collect} = require('../localization/InventoryEnglish.cjs');
function validate(root = path.resolve(__dirname,'../..')) {
  const raw = fs.readFileSync(path.join(root,'data/localization/ui_en.json'),'utf8');
  const catalog = JSON.parse(raw);
  assert.equal(catalog.schema_version,1);
  const keys = [...raw.matchAll(/^    ("(?:\\.|[^"\\])*"): /gm)].map(m=>JSON.parse(m[1]));
  assert.equal(keys.length,new Set(keys).size,'duplicate source keys');
  const tokens = s => s.match(/%[-+0#]*[0-9]*(?:\.[0-9]+)?[sdf%]|\{\{[^{}]+\}\}/g)||[];
  for (const [source,en] of Object.entries(catalog.messages)) {
    assert.ok(typeof en==='string' && en.trim(),'empty English: '+source);
    assert.ok(!/[가-힣\ufffd]/.test(en),'untranslated/corrupt English: '+source);
    assert.deepEqual(tokens(en),tokens(source),'format tokens: '+source);
  }
  const snapshot = path.join(root,'ui-source-inventory.json');
  const inventory = fs.existsSync(snapshot) ? JSON.parse(fs.readFileSync(snapshot,'utf8')) : collect(root);
  for (const row of inventory) assert.ok(catalog.messages[row.source],'missing UI: '+row.source);
  return {result:'PASS',source_strings:inventory.length,translations:Object.keys(catalog.messages).length,
    checks:['script/scene/data coverage','unique raw keys','nonempty English','no Hangul or replacement characters','ordered format tokens'],
    excluded:'Four pre-existing corrupt quarantine notes in wall_asset_catalog.json; not player-facing'};
}
if(require.main===module)console.log(JSON.stringify(validate(process.argv[2]),null,2));
module.exports={validate};
