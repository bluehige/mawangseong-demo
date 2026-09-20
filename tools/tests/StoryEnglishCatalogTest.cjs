const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');

function validate(root = path.resolve(__dirname, '../..')) {
  const read = file => fs.readFileSync(path.join(root, file), 'utf8').replace(/^\uFEFF/, '');
  const raw = read('data/localization/story_en.json');
  assert.ok(!raw.includes('\uFFFD'), 'invalid replacement character in catalog');
  const en = JSON.parse(raw);
  assert.equal(en.schema_version, 1);
  assert.deepEqual(en.translated_days, [1,2,3,4,5,6,7,8,9,10]);
  const rawIds = [...raw.matchAll(/^\s*"(STORY_[^"]+)"\s*:/gm)].map(m => m[1]);
  assert.equal(rawIds.length, new Set(rawIds).size, 'duplicate story keys in JSON source');
  const rows = [];
  const sceneIds = [];
  const tokens = text => (text.match(/\{\{[^{}]+\}\}|%[sdif]/g) || []).sort();
  for (const day of en.translated_days) {
    const file = 'data/story/v122_main/day_' + String(day).padStart(2, '0') + '.json';
    const source = JSON.parse(read(file));
    assert.equal(source.day, day);
    for (const scene of source.scenes) {
      sceneIds.push(scene.id);
      assert.ok(en.scene_titles[scene.id]?.trim(), 'missing title: ' + scene.id);
      assert.ok(en.scene_titles[scene.id].startsWith('DAY ' + day + ' · '), 'wrong day in title');
      for (const cue of scene.cues) {
        const text = en.cues[cue.id];
        assert.equal(typeof text, 'string', 'missing translation: ' + cue.id);
        assert.ok(text.trim() && !/[가-힣]/.test(text), 'empty or untranslated cue: ' + cue.id);
        assert.deepEqual(tokens(text), tokens(cue.text_ko), 'placeholder mismatch: ' + cue.id);
        assert.ok(en.speaker_labels[cue.speaker_label], 'missing speaker: ' + cue.speaker_label);
        rows.push({day, scene_id:scene.id, cue_id:cue.id, speaker:cue.speaker_label, ko:cue.text_ko, en:text});
      }
    }
  }
  assert.equal(new Set(rows.map(r => r.cue_id)).size, rows.length, 'duplicate source cue ID');
  assert.deepEqual(Object.keys(en.cues).sort(), rows.map(r => r.cue_id).sort(), 'unknown or missing cues');
  assert.deepEqual(Object.keys(en.scene_titles).sort(), sceneIds.sort(), 'unknown or missing scenes');
  for (const [key, value] of Object.entries(en.ui)) {
    assert.ok(value.ko?.trim() && value.en?.trim(), 'missing UI translation: ' + key);
    assert.deepEqual(tokens(value.ko), tokens(value.en), 'UI placeholder mismatch: ' + key);
  }
  assert.equal(rows.length, 358);
  return {rows, report:{result:'PASS', days:en.translated_days, cues:rows.length, scenes:sceneIds.length,
    checks:['valid JSON','unique raw story keys','source ID coverage','no unknown IDs','nonempty English',
      'placeholder parity','speaker coverage','scene title coverage','UI locale parity']}};
}

if (require.main === module) console.log(JSON.stringify(validate(process.argv[2]).report, null, 2));
module.exports = {validate};
