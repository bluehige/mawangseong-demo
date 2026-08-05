import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..", "..");
const SOURCE_SHA256 = "d421651b49739c88706c48c1482a3a1dc8dc7d697b017870f5f8ead19014914b";
const SOURCE_RELATIVE_PATH = "data/story/source/V122_MAIN_SCENARIO_DIALOGUE_BOOK_APPROVED_2026-07-31.md";
const SOURCE_PATH = path.join(REPO_ROOT, ...SOURCE_RELATIVE_PATH.split("/"));
const LEGACY_SOURCE_SHA256 = "6753f68e5cfb4662ee2ff978af5d39c73d5157bd595995438c1b4bf2de821f58";
const LEGACY_SOURCE_RELATIVE_PATH = "data/story/source/V122_MAIN_SCENARIO_DIALOGUE_BOOK_DAY01_05_2026-07-30.md";
const OUTPUT_DIR = path.join(REPO_ROOT, "data", "story", "v122_main");

const SPEAKERS = {
  "내레이션": "NARRATOR",
  "마왕": "CHR_DARKLORD_PLAYER",
  "바티": "CHR_BATI",
  "골딘": "CHR_GOLDIN",
  "푸딩": "CHR_PUDDING",
  "곱": "CHR_GOB",
  "핀": "CHR_PYNN",
  "로로": "CHR_ROLO",
  "밀로": "CHR_EXPLORER_MILO",
  "니아": "CHR_THIEF_NIA",
  "레온": "CHR_HERO_LEON",
  "레온의답신": "CHR_HERO_LEON",
  "레온의전언": "CHR_HERO_LEON",
  "아이리스": "CHR_INVESTIGATOR_IRIS",
  "셀렌": "CHR_SELEN",
  "셀렌의전언": "CHR_SELEN",
  "로만": "CHR_ROMAN",
  "로만의전언": "CHR_ROMAN",
};

const DYNAMIC_SPEAKER_ROLES = {
  "첫 승급자": "first_promoted",
  "두번째승급자": "second_promoted",
  "먼저승급한몬스터": "first_promoted",
  "나머지몬스터": "remaining_core_monsters",
};

const ENDING_IDS = {
  E00: "true_demon_castle",
  E01: "monster_family_castle",
  E02: "impregnable_demon_citadel",
  E03: "dread_overlord_rises",
  E04: "demon_hero_rival_pact",
};

function sha256(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

function fail(message) {
  throw new Error(message);
}

function normalize(text) {
  return text.replaceAll("\r\n", "\n");
}

function readSource() {
  if (!fs.existsSync(SOURCE_PATH)) {
    fail(`Missing approved source snapshot: ${SOURCE_RELATIVE_PATH}`);
  }
  const buffer = fs.readFileSync(SOURCE_PATH);
  const actualHash = sha256(buffer);
  if (actualHash !== SOURCE_SHA256) {
    fail(`Approved source hash mismatch: expected ${SOURCE_SHA256}, got ${actualHash}`);
  }
  return normalize(buffer.toString("utf8")).split("\n");
}

function refreshSource(sourcePath) {
  const sourceBuffer = fs.readFileSync(sourcePath);
  const actualHash = sha256(sourceBuffer);
  if (actualHash !== SOURCE_SHA256) {
    fail(`Approved source hash mismatch: expected ${SOURCE_SHA256}, got ${actualHash}`);
  }
  fs.mkdirSync(path.dirname(SOURCE_PATH), { recursive: true });
  fs.writeFileSync(SOURCE_PATH, sourceBuffer);
}

function portraitEmotion(speakerId, direction) {
  if (speakerId === "NARRATOR") return "none";
  const value = direction.replaceAll(" ", "");
  switch (speakerId) {
    case "CHR_DARKLORD_PLAYER":
      if (/(당황|긴장|충격|황급|놀람)/.test(value)) return "flustered";
      if (/(발끈|억울|분함|화|불쾌|어이없|절규)/.test(value)) return "offended";
      if (/(지휘|명령|결의|결단|최종명령|선언)/.test(value)) return "command";
      if (/(따뜻|미소|안도|인정|다독임)/.test(value)) return "soft";
      if (/(허세|만족|자랑|당당|감격|환희|위엄|뿌듯)/.test(value)) return "proud";
      return "serious";
    case "CHR_BATI":
      if (/(미소|따뜻)/.test(value)) return "dry_happy";
      if (/(설명|안내)/.test(value)) return "tutorial";
      if (/(건조|무심|담담|현실|정정)/.test(value)) return "dry";
      return "stern";
    case "CHR_GOLDIN":
      if (/(불안|긴장|다급|절박|경악|걱정|공포)/.test(value)) return "panic";
      if (/(안도|만족|흡족|평온|감격|황홀)/.test(value)) return "relieved";
      return "accounting";
    case "CHR_PUDDING":
      return /(용감|결심|기합|힘씀|단호|막아|다짐|의지)/.test(value) ? "brave" : "happy";
    case "CHR_GOB":
      return "eager";
    case "CHR_PYNN":
      return /(집중|조준|시선)/.test(value) ? "cast" : "proud";
    case "CHR_ROLO":
      if (/(당황|다급|긴장|뜨거움|머쓱)/.test(value)) return "flustered";
      if (/(보고|브리핑|지휘|낭독|공식)/.test(value)) return "briefing";
      return "mischief";
    case "CHR_EXPLORER_MILO":
      return /(공포|당황|절망|지침|혼란|미안)/.test(value) ? "panic" : "curious";
    case "CHR_THIEF_NIA":
      if (/(아픔|상처)/.test(value)) return "pain_smile";
      if (/화면밖/.test(value)) return "offscreen";
      if (/(집중|관찰)/.test(value)) return "focused";
      if (/놀람/.test(value)) return "surprised";
      return "teasing";
    case "CHR_HERO_LEON":
      if (/패배/.test(value)) return "defeated";
      if (/(아픔|상처)/.test(value)) return "pain";
      if (/매뉴얼/.test(value)) return "manual";
      if (/(정식|최종)/.test(value)) return "hero_final";
      if (/당황/.test(value)) return "flustered";
      return /(영웅|비장)/.test(value) ? "heroic" : "determined";
    case "CHR_INVESTIGATOR_IRIS":
      return /(냉정|경고)/.test(value) ? "stern" : "inquisitive";
    case "CHR_SELEN":
      if (/당황/.test(value)) return "flustered";
      return /(공식|기록|검토|보고)/.test(value) ? "checklist" : "formal";
    case "CHR_ROMAN":
      return /(피곤|마지못|숨을고르)/.test(value) ? "exhausted_command" : "formal";
    default:
      fail(`Unsupported portrait speaker: ${speakerId}`);
  }
}

function speakerFor(label) {
  return SPEAKERS[label] ?? "NARRATOR";
}

function conditionForBranch(label) {
  const compact = label.replaceAll(" ", "");
  if (ENDING_IDS[label]) return { all: [{ fact: "resolved_ending_id", op: "eq", value: ENDING_IDS[label] }] };
  if (compact.includes("보물·시설손실없음")) {
    return { all: [{ fact: "backline_damaged", op: "eq", value: false }] };
  }
  if (compact.includes("보물또는시설손실발생")) {
    return { all: [{ fact: "backline_damaged", op: "eq", value: true }] };
  }
  if (compact.includes("보물손실없음") || compact.includes("두도둑모두차단")) {
    return { all: [{ fact: "treasure_damaged", op: "eq", value: false }] };
  }
  if (compact.includes("보물손실발생") || compact.includes("한명이상약탈성공")) {
    return { all: [{ fact: "treasure_damaged", op: "eq", value: true }] };
  }
  if (compact.includes("핀선택결과")) {
    return { all: [{ fact: "first_promotion_monster_id", op: "eq", value: "imp" }] };
  }
  if (compact.includes("핀미선택")) {
    return { all: [{ fact: "first_promotion_monster_id", op: "ne", value: "imp" }] };
  }
  if (compact.includes("능선정찰선택시")) {
    return { all: [{ fact: "completed_raid_ids", op: "contains", value: "d16_route_recon" }] };
  }
  if (compact.includes("강변창고급습선택시")) {
    return { all: [{ fact: "completed_raid_ids", op: "contains", value: "d16_supply_ambush" }] };
  }
  if (compact.includes("가짜보급장부선택시")) {
    return { all: [{ fact: "completed_raid_ids", op: "contains", value: "d18_forged_manifest" }] };
  }
  if (compact.includes("밀수갱도봉쇄선택시")) {
    return { all: [{ fact: "completed_raid_ids", op: "contains", value: "d18_seal_smuggling_tunnel" }] };
  }
  if (compact.includes("DAY28분기A") || compact.includes("공성로정찰")) {
    return { all: [{ fact: "completed_raid_ids", op: "contains", value: "d28_siege_route_recon" }] };
  }
  if (compact.includes("DAY28분기B") || compact.includes("공병보급교란")) {
    return { all: [{ fact: "completed_raid_ids", op: "contains", value: "d28_engineer_supply_disruption" }] };
  }
  if (compact.includes("심사비용결과") || compact.includes("금화720·악명720이상유지")) {
    return { all: [{ fact: "stage_two_upgrade_funded", op: "eq", value: true }] };
  }
  if (compact.includes("금화또는악명기준미달")) {
    return { all: [{ fact: "stage_two_upgrade_funded", op: "eq", value: false }] };
  }
  if (compact.includes("선언A") || compact.includes("라이벌약속")) {
    return { all: [{ fact: "day29_declaration", op: "eq", value: "rival_pact" }] };
  }
  if (compact.includes("선언B") || compact.includes("성수호")) {
    return { all: [{ fact: "day29_declaration", op: "eq", value: "castle_oath" }] };
  }
  if (compact.includes("승리분기")) return { all: [{ fact: "win", op: "eq", value: true }] };
  if (compact.includes("패배분기")) return { all: [{ fact: "win", op: "eq", value: false }] };
  return null;
}

function sceneCategory(day, sectionHeading, branch) {
  const compact = sectionHeading.replaceAll(" ", "");
  const branchCompact = branch.replaceAll(" ", "");
  if (ENDING_IDS[branch] || sectionHeading.startsWith("기본엔딩")) return "ending";
  if (day === 29) return "management";
  if (day === 30) {
    if (branchCompact.includes("승리분기")) return "win";
    if (branchCompact.includes("패배분기")) return "loss";
    if (compact.includes("1막")) return "management";
    return "combat";
  }
  if (/(관리|1막)/.test(sectionHeading)) return "management";
  if (/(전투직전|2막)/.test(compact)) return "precombat";
  if (/(전투중|3막)/.test(compact)) return "combat";
  if (/(승리후|방어결과|4막)/.test(compact)) return "win";
  if (/패배/.test(sectionHeading)) return "loss";
  return "management";
}

function parseDays(lines) {
  const byDay = new Map();
  let day = 0;
  let sectionHeading = "";
  let branch = "";
  let endings = false;
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const dayMatch = line.match(/^## DAY (\d+)\b/);
    if (dayMatch) {
      day = Number(dayMatch[1]);
      sectionHeading = "관리 전";
      branch = "";
      endings = false;
      if (day >= 6 && day <= 30 && !byDay.has(day)) byDay.set(day, []);
      continue;
    }
    if (/^# 1회차 기본 엔딩/.test(line)) {
      day = 30;
      sectionHeading = "기본 엔딩";
      branch = "";
      endings = true;
      continue;
    }
    const h3 = line.match(/^###\s+(.+)$/);
    if (h3 && day >= 6 && day <= 30) {
      sectionHeading = h3[1].trim();
      branch = "";
      continue;
    }
    const h4 = line.match(/^####\s+(.+)$/);
    if (h4 && day >= 6 && day <= 30) {
      branch = h4[1].trim();
      continue;
    }
    const ending = line.match(/^##\s+(E\d\d)\s*[··].*$/);
    if (ending && endings) {
      sectionHeading = "기본 엔딩";
      branch = ending[1];
      continue;
    }
    const branchMatch = line.match(/^\s*-\s+\[분기:\s*(.+)\]\s*$/);
    if (branchMatch) {
      branch = branchMatch[1].trim();
      continue;
    }
    const dialogue = line.match(/^\s*-\s+\[([^|\]]+)\|([^\]]+)\]:\s(.*)$/);
    if (!dialogue || day < 6 || day > 30) continue;
    const [, speakerLabel, emotionDirection, textKo] = dialogue;
    const speakerId = speakerFor(speakerLabel);
    byDay.get(day).push({
      day,
      section_heading: sectionHeading,
      branch,
      speaker_id: speakerId,
      speaker_label: speakerLabel,
      speaker_role: DYNAMIC_SPEAKER_ROLES[speakerLabel] ?? "",
      emotion_direction: emotionDirection,
      portrait_emotion: portraitEmotion(speakerId, emotionDirection),
      text_ko: textKo,
      source_line: index + 1,
    });
  }
  return byDay;
}

function makeScene(day, id, trigger, delivery, repeatPolicy, cues, metadata = {}) {
  return {
    id,
    day,
    title: `DAY ${day} · ${metadata.title ?? "메인 시나리오"}`,
    trigger,
    delivery,
    repeat_policy: repeatPolicy,
    ...(delivery === "combat_bark" ? { queue_policy: "append" } : {}),
    metadata,
    cues: cues.map((cue, index) => ({
      id: `${id}_${String(index + 1).padStart(3, "0")}`,
      speaker_id: cue.speaker_id,
      speaker_label: cue.speaker_label,
      text_ko: cue.text_ko,
      emotion_direction: cue.emotion_direction,
      portrait_emotion: cue.portrait_emotion,
      source_line: cue.source_line,
      ...(cue.speaker_role !== "" ? { speaker_role: cue.speaker_role } : {}),
      ...(conditionForBranch(cue.branch) ? { conditions: conditionForBranch(cue.branch) } : {}),
    })),
  };
}

function buildDay(day, dialogue) {
  const groups = { management: [], precombat: [], combat: [], win: [], loss: [], ending: [] };
  for (const cue of dialogue) groups[sceneCategory(day, cue.section_heading, cue.branch)].push(cue);
  const scenes = [];
  if (groups.management.length) {
    scenes.push(makeScene(day, `STORY_D${String(day).padStart(2, "0")}_MANAGEMENT`, "management_entered", "blocking", "once_first_cycle_day", groups.management, { title: "관리 대화" }));
  }
  if (groups.precombat.length) {
    scenes.push(makeScene(day, `STORY_D${String(day).padStart(2, "0")}_PRECOMBAT`, "precombat_confirmed", "blocking", "once_battle", groups.precombat, { title: "전투 직전" }));
  }
  const combatChunks = [];
  for (let index = 0; index < groups.combat.length; index += 4) combatChunks.push(groups.combat.slice(index, index + 4));
  if (day === 30 && combatChunks.length > 8) {
    const overflow = combatChunks.splice(8).flat();
    groups.precombat.push(...overflow);
    const precombat = scenes.find((scene) => scene.id.endsWith("_PRECOMBAT"));
    if (precombat) {
      precombat.cues = makeScene(day, precombat.id, "precombat_confirmed", "blocking", "once_battle", groups.precombat, { title: "최종 공성 브리핑" }).cues;
      precombat.title = "DAY 30 · 최종 공성 브리핑";
    } else if (overflow.length) {
      scenes.push(makeScene(day, `STORY_D${String(day).padStart(2, "0")}_PRECOMBAT`, "precombat_confirmed", "blocking", "once_battle", overflow, { title: "최종 공성 브리핑" }));
    }
  }
  for (let index = 0; index < combatChunks.length; index += 1) {
    scenes.push(makeScene(
      day,
      `STORY_D${String(day).padStart(2, "0")}_COMBAT_${String(index + 1).padStart(2, "0")}`,
      "combat_time",
      "combat_bark",
      "once_battle",
      combatChunks[index],
      { title: "전투 대화", time_seconds: index * 10.0 },
    ));
  }
  if (groups.win.length) {
    scenes.push(makeScene(day, `STORY_D${String(day).padStart(2, "0")}_RESULT_WIN`, "result_win", "blocking", "once_battle", groups.win, { title: "승리 결산" }));
  }
  if (groups.loss.length) {
    scenes.push(makeScene(day, `STORY_D${String(day).padStart(2, "0")}_RESULT_LOSS`, "result_loss", "blocking", "once_battle", groups.loss, { title: "패배 결산" }));
  }
  if (groups.ending.length) {
    scenes.push(makeScene(day, `STORY_D${String(day).padStart(2, "0")}_ENDING`, "ending_entered", "blocking", "once_first_cycle_day", groups.ending, { title: "엔딩 후일담" }));
  }
  if (scenes.length === 0) fail(`No dialogue scenes built for DAY ${day}`);
  return { schema_version: 1, day, scenes };
}

function buildOutputs() {
  const lines = readSource();
  const parsed = parseDays(lines);
  const outputs = new Map();
  const dayFiles = [];
  for (let day = 1; day <= 30; day += 1) {
    const relativePath = `res://data/story/v122_main/day_${String(day).padStart(2, "0")}.json`;
    dayFiles.push(relativePath);
    if (day < 6) continue;
    const dayData = buildDay(day, parsed.get(day) ?? []);
    outputs.set(path.join(OUTPUT_DIR, `day_${String(day).padStart(2, "0")}.json`), `${JSON.stringify(dayData, null, 2)}\n`);
  }
  const manifest = {
    schema_version: 1,
    source_sha256: SOURCE_SHA256,
    source_snapshot: `res://${SOURCE_RELATIVE_PATH}`,
    source_day01_05_sha256: LEGACY_SOURCE_SHA256,
    source_day01_05_snapshot: `res://${LEGACY_SOURCE_RELATIVE_PATH}`,
    day_files: dayFiles,
  };
  outputs.set(path.join(OUTPUT_DIR, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
  return outputs;
}

function writeOutputs(outputs) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  for (const [outputPath, content] of outputs) fs.writeFileSync(outputPath, content, "utf8");
}

function checkOutputs(outputs) {
  let failed = false;
  for (const [outputPath, expected] of outputs) {
    const relativePath = path.relative(REPO_ROOT, outputPath).replaceAll("\\", "/");
    if (!fs.existsSync(outputPath)) {
      console.error(`MISSING ${relativePath}`);
      failed = true;
      continue;
    }
    if (fs.readFileSync(outputPath, "utf8") !== expected) {
      console.error(`STALE ${relativePath}`);
      failed = true;
    }
  }
  if (failed) process.exitCode = 1;
  else console.log(`V122_STORY_DAY06_30_GENERATOR_CHECK: PASS (${outputs.size} files)`);
}

function main() {
  const args = process.argv.slice(2);
  const refreshIndex = args.indexOf("--refresh-source");
  if (refreshIndex >= 0) {
    const sourcePath = args[refreshIndex + 1];
    if (!sourcePath) fail("--refresh-source requires the approved dialogue book path");
    refreshSource(path.resolve(sourcePath));
  }
  const outputs = buildOutputs();
  if (args.includes("--check")) checkOutputs(outputs);
  else {
    writeOutputs(outputs);
    console.log(`V122_STORY_DAY06_30_GENERATOR: PASS (${outputs.size} files)`);
  }
}

main();
