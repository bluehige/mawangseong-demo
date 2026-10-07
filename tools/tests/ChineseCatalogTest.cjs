const fs = require('node:fs');
const path = require('node:path');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../..');
const read = file => JSON.parse(fs.readFileSync(path.join(root,file),'utf8'));
const tokens = text => text.match(/%[-+0#]*[0-9]*(?:\.[0-9]+)?[sdf%]|\{\{[^{}]+\}\}/g)||[];
function check(source,target,id) {
  assert.ok(typeof target==='string' && target.trim(), 'empty: '+id);
  assert.ok(!/[가-힣\uFFFD]/.test(target), 'Korean/corrupt: '+id);
  assert.deepEqual(tokens(target),tokens(source),'ordered placeholders: '+id);
}
const enUI=read('data/localization/ui_en.json');
const zhUI=read('data/localization/ui_zh_cn.json');
assert.equal(zhUI.schema_version,1);
assert.deepEqual(Object.keys(zhUI.messages).sort(),Object.keys(enUI.messages).sort(),'UI source key parity');
for(const [source,text] of Object.entries(zhUI.messages))check(source,text,source);
for(const [key,value] of Object.entries({'CAMPAIGN MODE':'战役模式','REGION ROUTE':'区域路线','발견':'已发现','LIVING CASTLE / HEART COVENANT':'活体城堡 / 城心契约','Compact · 1366/1280':'紧凑布局 · 1366/1280','Standard · 1920':'标准布局 · 1920'}))assert.equal(zhUI.supplemental_messages[key],value);
for(const key of ['%s 진입 복도','%s 안쪽 복도','%s 합류 복도','%s 통로','도둑은 이 방을 목표로 이동합니다. %d초 방치되면 금화 %d을 잃습니다.'])assert.ok(zhUI.supplemental_messages[key], 'runtime composition template: '+key);
for(const [source,text] of Object.entries(zhUI.supplemental_messages))check(source,text,source);
const stage=read('data/localization/v122_stage10_ui.json').locales;
assert.deepEqual(Object.keys(stage.zh_CN).sort(),Object.keys(stage.ko).sort(),'stable settings/tutorial keys');
for(const key in stage.ko)check(stage.ko[key],stage.zh_CN[key],key);
const zhStory=read('data/localization/story_zh_cn.json');
const enStory=read('data/localization/story_en.json');
assert.equal(zhStory.schema_version,1);
assert.deepEqual(zhStory.translated_days,Array.from({length:30},(_,i)=>i+1));
const cues=[],scenes=[];
for(let day=1;day<=30;day++) {
  const source=read(`data/story/v122_main/day_${String(day).padStart(2,'0')}.json`);
  for(const scene of source.scenes) {
    scenes.push(scene.id);
    check('',zhStory.scene_titles[scene.id],scene.id);
    assert.ok(zhStory.scene_titles[scene.id].startsWith(`第${day}天 · `),'day in title: '+scene.id);
    for(const cue of scene.cues) {
      cues.push(cue.id);
      check(cue.text_ko,zhStory.cues[cue.id],cue.id);
      assert.ok(zhStory.speaker_labels[cue.speaker_label], 'speaker: '+cue.speaker_label);
    }
  }
}
assert.deepEqual(Object.keys(zhStory.cues).sort(),cues.sort(),'cue ID parity');
assert.deepEqual(Object.keys(zhStory.scene_titles).sort(),scenes.sort(),'scene ID parity');
assert.deepEqual(Object.keys(zhStory.speaker_labels).sort(),Object.keys(enStory.speaker_labels).sort());
assert.deepEqual(Object.keys(zhStory.ui).sort(),Object.keys(enStory.ui).sort());
for(const [key,entry] of Object.entries(zhStory.ui)) {
  assert.equal(entry.ko,enStory.ui[key].ko);
  assert.equal(entry.en,enStory.ui[key].en);
  check(entry.ko,entry.zh_CN,key);
}
for(const file of ['ui_zh_cn.json','story_zh_cn.json']) {
  const raw=fs.readFileSync(path.join(root,'data/localization',file),'utf8');
  const keys=[...raw.matchAll(/^    ("(?:\\.|[^"\\])*"): /gm)].map(m=>JSON.parse(m[1]));
  assert.equal(keys.length,new Set(keys).size,'duplicate raw keys: '+file);
}
assert.equal(cues.length,1741);assert.equal(scenes.length,216);assert.equal(Object.keys(zhUI.messages).length,5344);
for (const target of [...Object.values(zhUI.messages),...Object.values(stage.zh_CN),...Object.values(zhStory.scene_titles),...Object.values(zhStory.cues)]) {
  assert.ok(!/\b(?:DAY|Stage|Lv\.?|hunger)\b/.test(target),'unlocalized display convention: '+target);
}
console.log(JSON.stringify({result:'PASS',ui:5344,settings:142,cues:1741,titles:216,speakers:39,story_ui:9,checks:['source and ID coverage','ordered printf and named tokens','no empty or Hangul/replacement text','day prefixes','ko/en story UI parity','unique raw keys']},null,2));
