const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const [inventoryFile, ...draftFiles] = process.argv.slice(2);
if (!inventoryFile || !draftFiles.length) throw new Error('Usage: node ImportUIEnglish.cjs FROZEN_INVENTORY_JSON DRAFT_JSON...');
const inventory = JSON.parse(fs.readFileSync(inventoryFile, 'utf8'));
const catalogPath = path.join(root, 'data/localization/ui_en.json');
const catalog = JSON.parse(fs.readFileSync(catalogPath, 'utf8'));
const placeholders = text => text.match(/%[-+0#]*[0-9]*(?:\.[0-9]+)?[sdf%]|\{\{[^{}]+\}\}/g) || [];
const problems = [];
const reviewed = new Set();
for (const filename of draftFiles) {
  const draft = JSON.parse(fs.readFileSync(filename, 'utf8'));
  assert.ok(Number.isInteger(draft.start) && draft.start >= 0 && Array.isArray(draft.translations) && draft.translations.length > 0 && draft.start + draft.translations.length <= inventory.length, 'Draft range: '+filename);
  draft.translations.forEach((text, offset) => {
    const index = draft.start + offset;
    assert.ok(!reviewed.has(index), 'Duplicate draft index: '+index);
    reviewed.add(index);
    const source = inventory[index].source;
    if (typeof text !== 'string' || !text.trim() || /[가-힣\uFFFD]/.test(text)) { problems.push({index,source,text,kind:'invalid English'}); return; }
    if (JSON.stringify(placeholders(source)) !== JSON.stringify(placeholders(text))) problems.push({index,source,text,kind:'placeholders'});
  });
}
if (problems.length) { console.log(JSON.stringify(problems,null,2)); process.exit(1); }
for (const filename of draftFiles) {
  const draft = JSON.parse(fs.readFileSync(filename, 'utf8'));
  draft.translations.forEach((text, offset) => catalog.messages[inventory[draft.start+offset].source] = text);
}
fs.writeFileSync(catalogPath, JSON.stringify(catalog,null,2)+'\n');
console.log(JSON.stringify({messages:Object.keys(catalog.messages).length,total:inventory.length}));
