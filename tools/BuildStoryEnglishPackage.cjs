// Build a verified full-English source patch, comparison tables and Steam assets.
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const {execFileSync} = require('node:child_process');
const {validate} = require('./tests/StoryEnglishCatalogTest.cjs');
const {validate:validateUI} = require('./tests/UIEnglishCatalogTest.cjs');
const {collect} = require('./localization/InventoryEnglish.cjs');

const root = path.resolve(__dirname, '..');
const destination = process.argv[2];
const baseArg = process.argv[3];
if (!destination || !baseArg) {
  console.error('Usage: node tools/BuildStoryEnglishPackage.cjs OUTPUT_DIRECTORY BASE_COMMIT');
  process.exit(1);
}
const output = path.resolve(root, destination);
if (fs.existsSync(output)) throw new Error('Choose a new output directory; existing output is preserved.');
const git = args => execFileSync('git', ['-c', 'core.safecrlf=false', ...args], {cwd:root, encoding:'utf8', maxBuffer:128*1024*1024});
const base = git(['rev-parse', '--verify', baseArg + '^{commit}']).trim();
const sourceCommit = git(['rev-parse', 'HEAD']).trim();
const {rows, report} = validate(root);
const uiReport = validateUI(root);
// Build after the implementation commit so Git can encode added binary assets.
const changed = git(['diff','--name-only',base,'HEAD']).trim().split('\n')
  .filter(file => file && !file.startsWith('docs/handoff/'));
if (!changed.includes('data/localization/ui_en.json')) throw new Error('Commit the full English implementation before building the package.');
if (git(['diff','--name-only','HEAD','--',...changed]).trim()) throw new Error('Implementation differs from its recorded commit.');
const originals = report.days.map(day => 'data/story/v122_main/day_' + String(day).padStart(2, '0') + '.json');
const files = [];
const write = (file, data) => {
  const target = path.join(output, file);
  fs.mkdirSync(path.dirname(target), {recursive:true});
  fs.writeFileSync(target, data);
  files.push(file);
};
for (const file of [...changed, ...originals]) write(file, fs.readFileSync(path.join(root, file)));

const patch = git(['diff','--binary','--full-index','--no-ext-diff','--no-color','--no-renames',base,'HEAD','--',...changed]);
write('story-english.patch', patch);
write('ui-source-inventory.json', JSON.stringify(collect(root),null,2)+'\n');
write('ui-bilingual.json', fs.readFileSync(path.join(root,'data/localization/ui_en.json')));
const screenshots = {
  '01_castle_management.png':'day_01_management.png',
  '02_monster_growth.png':'monster.png',
  '03_infamy_raid.png':'raid.png',
  '04_defense_combat.png':'combat.png',
  '05_castle_heart.png':'heart_selection.png',
  '06_defense_result.png':'result_win.png'
};
const captures = path.join(root,'tmp/full_english_validation_1080');
const screenReport = JSON.parse(fs.readFileSync(path.join(captures,'runtime_report_views.json')));
if (screenReport.result !== 'PASS') throw new Error('Final English screen audit must pass.');
for (const [target,source] of Object.entries(screenshots)) write('marketing/steam/english/screenshots/'+target,fs.readFileSync(path.join(captures,source)));
write('marketing/steam/english/screenshots/SCREENSHOTS.md','# English gameplay captures\n\nCaptured from the English implementation at 1920 × 1080 using FullEnglishRuntimeTest.tscn. Actual unedited Godot renderings, with reproducible test states. No AI image editing. The fifth capture shows Castle Heart selection, a current feature; the old direct-control promotional screenshot is not reused.\n');
write('dialogue-bilingual.json', JSON.stringify(rows, null, 2) + '\n');
const escape = text => String(text).replace(/[&<>"']/g, char => ({'&':'&amp;','<':'&lt;','>':'&gt;','"':'&quot;',"'":'&#39;'}[char]));
write('dialogue-bilingual.html', `<!doctype html>
<html lang="ko"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>마왕성 DAY 1–30 · 한영 대사 ${rows.length}개</title>
<style>body{font:16px/1.6 system-ui,sans-serif;margin:32px;color:#20232a;background:#faf9f6}h1{font-size:28px}p{max-width:900px}input{box-sizing:border-box;width:min(700px,100%);font:inherit;padding:12px;border:1px solid #888;border-radius:6px}table{border-collapse:collapse;width:100%;margin-top:20px;background:white}th,td{padding:14px;border:1px solid #ccc;text-align:left;vertical-align:top}th{background:#ede9df;position:sticky;top:0}td:nth-child(1){width:19%;font-size:12px;overflow-wrap:anywhere}td:nth-child(2),td:nth-child(3){width:40%;white-space:pre-wrap}small{color:#555}tr[hidden]{display:none}@media(max-width:700px){body{margin:12px}th,td{padding:8px}}</style>
<h1>마왕성 · DAY 1–30 한영 대사 대조표</h1>
<p>DAY 1–30 모든 분기·승패 대사 ${rows.length}개입니다. 한국어 원문과 고유 ID를 보존했습니다. UI 번역은 ui-bilingual.json에서 확인할 수 있습니다.</p>
<p><label for="query">날짜·화자·ID·대사 검색</label><br><input id="query" type="search" placeholder="예: DAY 7, Gob, 바티, STORY_D10"></p><p id="count">${rows.length} / ${rows.length}개</p>
<table><thead><tr><th>날짜 · 화자 · ID</th><th>한국어 원문</th><th>English</th></tr></thead><tbody>
${rows.map(row => `<tr><td>DAY ${row.day} · ${escape(row.speaker)}<br><small>${escape(row.scene_id)}<br>${escape(row.cue_id)}</small></td><td>${escape(row.ko)}</td><td lang="en">${escape(row.en)}</td></tr>`).join('\n')}
</tbody></table>
<script>const rows=Array.from(document.querySelectorAll('tbody tr'));document.getElementById('query').addEventListener('input',event=>{const query=event.target.value.trim().toLowerCase();let visible=0;for(const row of rows){row.hidden=!row.textContent.toLowerCase().includes(query);if(!row.hidden)visible++;}document.getElementById('count').textContent=visible+' / '+rows.length+'개';});</script></html>\n`);
write('validation.json', JSON.stringify({base_commit:base, source_commit:sourceCommit, story:report,ui:uiReport,screens:screenReport}, null, 2) + '\n');
write('README.md', `# 마왕성 전체 영어화 수정 패키지

- DAY 1–30 전체 ${rows.length}개 대사·${report.scenes}개 장면 제목과 ${uiReport.translations}개 UI 번역 항목을 포함합니다.
- 게임의 한국어 원본 데이터·ID·저장 형식을 유지하고 영어 선택 시 표시를 번역합니다.
- 영문 로고·캡슐 6종·실제 게임 화면 캡처 6장과 생성 출처를 포함합니다.
- 실행 파일·엔진·오디오·사용자 저장 파일은 포함하지 않습니다. 정식 출시 또는 Steam 업로드는 별도 단계입니다.
- 패치 기준 SHA: ${base}
- 생성 시 작업 트리 HEAD: ${sourceCommit} (전달 내용의 정확한 바이트는 SHA256SUMS.json 기준)

## 내용 보기와 검증

1. dialogue-bilingual.html을 열면 원문·영문·화자·고유 ID를 함께 검색할 수 있습니다.
2. 패키지 폴더에서 Node.js로 node tools/tests/StoryEnglishCatalogTest.cjs를 실행합니다. 포함된 원문 JSON과 번역의 ID·누락·중복·치환문자를 검사합니다.
   UI 검사는 node tools/tests/UIEnglishCatalogTest.cjs입니다. 번들에서는 포함한 원문 목록을, 전체 저장소에서는 스크립트·씬·데이터를 직접 검사합니다.
3. SHA256SUMS.json은 각 파일의 SHA256·바이트 크기를 기록합니다. 자체 파일은 목록에서 제외합니다.

## 저장소 적용

기준 SHA와 일치하는 깨끗한 프로젝트에서 git apply --check /path/to/story-english.patch를 먼저 실행한 뒤 git apply /path/to/story-english.patch로 적용합니다. 패키지 전체를 덮어쓰지 마세요. data/story의 한국어 파일은 검증용 원본이며 패치 수정 대상이 아닙니다.
패치는 신규 영문 이미지도 포함합니다. screenshots 폴더의 6장은 전달용 촬영 산출물이며 소스 패치에는 포함하지 않습니다.

## 실제 게임 검사

전체 프로젝트 및 Godot 4.6.3이 필요합니다. 테스트에는 분리한 APPDATA 경로를 사용해 개인 저장 파일을 보존하세요.

- Godot --headless --path . res://tools/tests/StoryEnglishRuntimeTest.tscn
- Godot --headless --path . res://tools/tests/V122Stage10LocalizationTest.tscn
- Godot --headless --path . res://tools/tests/V122StoryRuntimeIntegrationTest.tscn
- Godot --headless --path . res://tools/tests/EnglishTranslationTest.tscn
- Godot --headless --path . res://tools/tests/UIEnglishFormattedTest.tscn
- 전체 영문 표시 확인: Godot --path . --rendering-method gl_compatibility --resolution 1280x720 res://tools/tests/FullEnglishRuntimeTest.tscn
- 1080p 캡처: 같은 명령의 해상도를 1920x1080으로 바꾸고 끝에 -- --views-only --audit-dir=tmp/full_english_validation_1080을 붙입니다.

validator는 정적 검사를 실행합니다. 전체 회귀 검사나 전체 캠페인 검수를 대신하지 않습니다.
`);
const manifest = files.sort().map(file => {
  const data = fs.readFileSync(path.join(output, file));
  return {file, bytes:data.length, sha256:crypto.createHash('sha256').update(data).digest('hex')};
});
write('SHA256SUMS.json', JSON.stringify(manifest, null, 2) + '\n');
console.log(JSON.stringify({output, base, files:files.length, cues:rows.length, bytes:manifest.reduce((sum,file) => sum + file.bytes,0)}, null, 2));
