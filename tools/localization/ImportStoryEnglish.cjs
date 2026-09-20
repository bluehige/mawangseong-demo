// Import reviewed, ordered dialogue drafts while preserving every source cue ID.
const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const file = path.join(root, 'data/localization/story_en.json');
const catalog = JSON.parse(fs.readFileSync(file, 'utf8'));
const draft = JSON.parse(fs.readFileSync(process.argv[2], 'utf8'));
const tokens = value => (value.match(/\{\{[^{}]+\}\}|%[sdif]/g) || []).sort();
let added = 0;
for (const [day, translations] of Object.entries(draft.days)) {
  const source = JSON.parse(fs.readFileSync(path.join(root, 'data/story/v122_main/day_' + day.padStart(2, '0') + '.json'), 'utf8'));
  const cues = source.scenes.flatMap(scene => scene.cues);
  assert.equal(translations.length, cues.length, 'cue count for DAY ' + day);
  for (let i = 0; i < cues.length; i++) {
    const en = translations[i];
    assert.ok(typeof en === 'string' && en.trim() && !/[가-힣\uFFFD]/.test(en), cues[i].id);
    assert.deepEqual(tokens(en), tokens(cues[i].text_ko), cues[i].id + ' placeholders');
    catalog.cues[cues[i].id] = en;
    added++;
  }
  if (!catalog.translated_days.includes(Number(day))) catalog.translated_days.push(Number(day));
}
Object.assign(catalog.scene_titles, draft.scene_titles || {});
for (const day of catalog.translated_days) {
  const source = JSON.parse(fs.readFileSync(path.join(root, 'data/story/v122_main/day_' + String(day).padStart(2, '0') + '.json'), 'utf8'));
  for (const scene of source.scenes) {
    const label = String(scene.title || scene.metadata?.title || scene.id).replace(/^DAY \d+ · /, '');
    if (draft.scene_title_labels?.[label]) catalog.scene_titles[scene.id] = 'DAY ' + day + ' · ' + draft.scene_title_labels[label];
  }
}
Object.assign(catalog.speaker_labels, draft.speaker_labels || {});
catalog.translated_days.sort((a,b) => a-b);
fs.writeFileSync(file, JSON.stringify(catalog, null, 2) + '\n');
console.log(JSON.stringify({imported:added,total:Object.keys(catalog.cues).length,days:catalog.translated_days}));
