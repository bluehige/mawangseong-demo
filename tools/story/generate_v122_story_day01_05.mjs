import crypto from "node:crypto";
import fs from "node:fs";
import path from "node:path";
import process from "node:process";
import { fileURLToPath } from "node:url";

const SCRIPT_DIR = path.dirname(fileURLToPath(import.meta.url));
const REPO_ROOT = path.resolve(SCRIPT_DIR, "..", "..");
const SOURCE_SHA256 = "6753f68e5cfb4662ee2ff978af5d39c73d5157bd595995438c1b4bf2de821f58";
const SNAPSHOT_SHA256 = "886f27b8f07c2d8e613f7b0d7708878a436fb0ac62d0913289eff514a565e940";
const SNAPSHOT_RELATIVE_PATH = "data/story/source/V122_MAIN_SCENARIO_DIALOGUE_BOOK_DAY01_05_2026-07-30.md";
const SNAPSHOT_PATH = path.join(REPO_ROOT, ...SNAPSHOT_RELATIVE_PATH.split("/"));
const OUTPUT_DIR = path.join(REPO_ROOT, "data", "story", "v122_main");

const SPEAKER_IDS = {
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
};

const EMOTIONS = {
  "내레이션": {
    "담담": "none",
  },
  "마왕": {
    "감격": "proud",
    "결심": "determined",
    "경계 속 호감": "soft",
    "고민": "serious",
    "기대": "proud",
    "긴장": "tense_proud",
    "긴장한 허세": "tense_proud",
    "다급": "flustered",
    "다독임": "soft",
    "단호": "serious",
    "당당": "proud",
    "당황": "flustered",
    "따뜻함": "soft",
    "만족": "proud",
    "무시": "serious",
    "반가움": "soft",
    "발끈": "offended_proud",
    "부드러움": "soft",
    "비장": "proud",
    "시치미": "recover_pride",
    "아쉬움": "deflated",
    "안도": "soft",
    "억울": "offended",
    "우쭐": "proud",
    "의심": "curious",
    "의아": "curious",
    "의욕": "determined",
    "작게": "flustered",
    "절규": "offended",
    "절망": "deflated",
    "조심": "serious",
    "지휘": "command",
    "진심": "serious",
    "충격": "shocked",
    "침묵": "deflated",
    "태연": "recover_pride",
    "허세": "proud",
    "환희": "proud",
    "황급": "flustered",
    "황당": "flustered",
    "황당한 만족": "recover_pride",
    "회복한 허세": "recover_pride",
  },
  "바티": {
    "건조": "dry",
    "냉정": "stern",
    "단호": "stern",
    "무심": "dry",
    "브리핑": "briefing",
    "설명": "tutorial",
    "안내": "tutorial",
    "엄중": "stern",
    "예고": "briefing",
    "의심": "dry",
    "작게": "neutral",
    "정정": "dry",
    "지적": "dry",
    "진지": "serious",
    "현실적": "dry",
    "희미한 미소": "dry_happy",
  },
  "골딘": {
    "경계": "panic",
    "계산": "accounting",
    "단호": "accounting",
    "담담": "accounting",
    "불안": "panic",
    "뿌듯": "relieved",
    "설명": "accounting",
    "안도": "relieved",
    "진지": "accounting",
    "패닉": "panic",
    "평온": "relieved",
    "흡족": "relieved",
  },
  "푸딩": {
    "걱정": "brave",
    "기쁨": "happy",
    "반가움": "happy",
    "뿌듯": "happy",
    "선의": "happy",
    "신남": "happy",
    "용감": "brave",
    "진지": "brave",
    "힘씀": "brave",
  },
  "핀": {
    "놀림": "proud",
    "여유": "proud",
    "웃음": "proud",
    "자신만만": "proud",
    "장난": "proud",
    "집중": "cast",
    "흡족": "proud",
  },
  "곱": {
    "감동 후 의욕": "eager",
    "고민": "eager",
    "기대": "eager",
    "들뜸": "eager",
    "신남": "eager",
    "용감": "eager",
    "의욕": "eager",
    "진지한 척": "eager",
    "집중 과다": "eager",
    "추격": "eager",
  },
  "밀로": {
    "감탄": "curious",
    "공포": "panic",
    "당황": "panic",
    "멀리서 혼란": "panic",
    "절망": "panic",
    "지침": "panic",
    "호기심": "curious",
  },
  "니아": {
    "만족": "teasing",
    "부드러운 흥미": "teasing",
    "아픔 섞인 웃음": "pain_smile",
    "여유": "teasing",
    "웃음": "teasing",
    "장난": "teasing",
    "집중": "focused",
    "평가": "teasing",
    "화면 밖 빈정거림": "offscreen",
  },
  "레온": {
    "결연": "determined",
    "경쟁심": "determined",
    "매뉴얼 낭독": "manual",
    "멀리서 비장": "heroic",
    "승리했지만 당황": "victory_flustered",
    "아픔": "pain",
    "영웅적": "heroic",
    "패배했지만 씩씩함": "defeated",
  },
  "로로": {
    "과장": "mischief",
    "기쁨": "mischief",
    "다급": "flustered",
    "당당": "briefing",
    "뜨거움": "flustered",
    "새 계획": "mischief",
    "솔직": "flustered",
    "신남": "mischief",
    "진지한 척": "briefing",
    "집중": "briefing",
    "활기": "briefing",
  },
};

const condition = (fact, op, value) => ({ all: [{ fact, op, value }] });
const gobFront = condition("gob_formation", "eq", "front");
const gobRear = condition("gob_formation", "eq", "rear");
const noTreasureLoss = condition("treasure_gold_stolen_this_battle", "eq", 0);
const treasureLoss = condition("treasure_gold_stolen_this_battle", "gt", 0);
const raidMission = (missionId) => condition("raid_mission_id", "eq", missionId);
const raidMonster = (monsterId) => condition("selected_raid_monster_ids", "contains", monsterId);

function sha256(buffer) {
  return crypto.createHash("sha256").update(buffer).digest("hex");
}

function fail(message) {
  throw new Error(message);
}

function readSnapshotLines() {
  if (!fs.existsSync(SNAPSHOT_PATH)) {
    fail(`Missing source snapshot: ${SNAPSHOT_RELATIVE_PATH}`);
  }
  const buffer = fs.readFileSync(SNAPSHOT_PATH);
  const actualHash = sha256(buffer);
  if (actualHash !== SNAPSHOT_SHA256) {
    fail(`Source snapshot hash mismatch: expected ${SNAPSHOT_SHA256}, got ${actualHash}`);
  }
  return buffer.toString("utf8").split("\n");
}

function refreshSnapshot(sourcePath) {
  const sourceBuffer = fs.readFileSync(sourcePath);
  const actualHash = sha256(sourceBuffer);
  if (actualHash !== SOURCE_SHA256) {
    fail(`Full source hash mismatch: expected ${SOURCE_SHA256}, got ${actualHash}`);
  }
  const marker = Buffer.from("## DAY 6", "utf8");
  const markerOffset = sourceBuffer.indexOf(marker);
  if (markerOffset < 0) {
    fail("DAY 6 marker not found in full source");
  }
  const snapshotBuffer = sourceBuffer.subarray(0, markerOffset);
  const snapshotHash = sha256(snapshotBuffer);
  if (snapshotHash !== SNAPSHOT_SHA256) {
    fail(`DAY 1~5 snapshot hash mismatch: expected ${SNAPSHOT_SHA256}, got ${snapshotHash}`);
  }
  fs.mkdirSync(path.dirname(SNAPSHOT_PATH), { recursive: true });
  fs.writeFileSync(SNAPSHOT_PATH, snapshotBuffer);
}

function parseDialogue(lines, sourceLine) {
  const raw = lines[sourceLine - 1];
  if (raw === undefined) {
    fail(`Missing source line ${sourceLine}`);
  }
  const match = raw.match(/^\s*-\s+\[([^|\]]+)\|([^\]]+)\]:\s(.*)$/);
  if (!match) {
    fail(`Source line ${sourceLine} is not a dialogue line: ${raw}`);
  }
  const [, speakerLabel, emotionDirection, textKo] = match;
  const speakerId = SPEAKER_IDS[speakerLabel];
  const portraitEmotion = EMOTIONS[speakerLabel]?.[emotionDirection];
  if (!speakerId) {
    fail(`Unmapped speaker at line ${sourceLine}: ${speakerLabel}`);
  }
  if (!portraitEmotion) {
    fail(`Unmapped emotion at line ${sourceLine}: ${speakerLabel}|${emotionDirection}`);
  }
  return {
    speaker_id: speakerId,
    speaker_label: speakerLabel,
    text_ko: textKo,
    emotion_direction: emotionDirection,
    portrait_emotion: portraitEmotion,
    source_line: sourceLine,
  };
}

function range(start, end) {
  return Array.from({ length: end - start + 1 }, (_, index) => start + index);
}

function cueLine(sourceLine, options = {}) {
  return { sourceLine, ...options };
}

function scene(lines, definition) {
  const result = {
    id: definition.id,
    day: definition.day,
    trigger: definition.trigger,
    delivery: definition.delivery,
    repeat_policy: definition.repeatPolicy,
  };
  if (definition.queuePolicy) {
    result.queue_policy = definition.queuePolicy;
  }
  if (definition.conditions) {
    result.conditions = definition.conditions;
  }
  if (definition.metadata) {
    result.metadata = definition.metadata;
  }
  result.cues = definition.cueLines.map((value, index) => {
    const descriptor = typeof value === "number" ? cueLine(value) : value;
    const cue = {
      id: `${definition.id}_${String(index + 1).padStart(3, "0")}`,
      ...parseDialogue(lines, descriptor.sourceLine),
    };
    if (descriptor.conditions) {
      cue.conditions = descriptor.conditions;
    }
    if (descriptor.replacesCueIds) {
      cue.replaces_cue_ids = descriptor.replacesCueIds;
    }
    return cue;
  });
  return result;
}

function blockingScene(lines, day, id, trigger, cueLines, sourceSection, options = {}) {
  return scene(lines, {
    id,
    day,
    trigger,
    delivery: "blocking",
    repeatPolicy: options.repeatPolicy ?? "once_first_cycle_day",
    conditions: options.conditions,
    metadata: {
      source_section: sourceSection,
      ...(options.metadata ?? {}),
    },
    cueLines,
  });
}

function combatTimeScenes(lines, day, lineStart, scenePrefix) {
  const times = [0.0, 8.0, 16.0, 24.0];
  return times.map((timeSeconds, index) =>
    scene(lines, {
      id: `${scenePrefix}_${String(index + 1).padStart(2, "0")}`,
      day,
      trigger: "combat_time",
      delivery: "combat_bark",
      repeatPolicy: "once_battle",
      queuePolicy: "append",
      metadata: {
        source_section: "전투 중 짧은 대화",
        time_seconds: timeSeconds,
      },
      cueLines: [lineStart + index * 2, lineStart + index * 2 + 1],
    }),
  );
}

function buildDay01(lines) {
  return {
    schema_version: 1,
    day: 1,
    scenes: [
      blockingScene(lines, 1, "STORY_D01_MANAGEMENT_ENTRY", "management_entered", range(68, 75), "관리 전 대화"),
      blockingScene(
        lines,
        1,
        "STORY_D01_PLACEMENT_FRONT",
        "placement_confirmed",
        [114, 115],
        "선택/분기 메모",
        {
          repeatPolicy: "once_battle",
          conditions: gobFront,
          metadata: { branch_group: "gob_formation", branch_mode: "exclusive", branch_value: "front" },
        },
      ),
      blockingScene(
        lines,
        1,
        "STORY_D01_PLACEMENT_REAR",
        "placement_confirmed",
        [117, 118],
        "선택/분기 메모",
        {
          repeatPolicy: "once_battle",
          conditions: gobRear,
          metadata: { branch_group: "gob_formation", branch_mode: "exclusive", branch_value: "rear" },
        },
      ),
      blockingScene(lines, 1, "STORY_D01_PRECOMBAT", "precombat_confirmed", range(79, 86), "전투 직전 대화", {
        repeatPolicy: "once_battle",
      }),
      ...combatTimeScenes(lines, 1, 90, "STORY_D01_COMBAT_TIME"),
      blockingScene(lines, 1, "STORY_D01_RESULT_WIN", "result_win", range(101, 108), "승리 후 대화", {
        repeatPolicy: "once_battle",
      }),
      blockingScene(lines, 1, "STORY_D01_RESULT_LOSS", "result_loss", range(120, 121), "선택/분기 메모", {
        repeatPolicy: "once_battle",
      }),
    ],
  };
}

function buildDay02(lines) {
  const resultSceneId = "STORY_D02_RESULT_WIN";
  return {
    schema_version: 1,
    day: 2,
    scenes: [
      blockingScene(lines, 2, "STORY_D02_MANAGEMENT_ENTRY", "management_entered", range(137, 144), "관리 전 대화"),
      blockingScene(lines, 2, "STORY_D02_PRECOMBAT", "precombat_confirmed", range(148, 155), "전투 직전 대화", {
        repeatPolicy: "once_battle",
      }),
      ...combatTimeScenes(lines, 2, 159, "STORY_D02_COMBAT_TIME"),
      blockingScene(
        lines,
        2,
        resultSceneId,
        "result_win",
        [
          cueLine(170, { conditions: noTreasureLoss }),
          cueLine(183, {
            conditions: treasureLoss,
            replacesCueIds: [`${resultSceneId}_001`],
          }),
          171,
          172,
          cueLine(173, { conditions: noTreasureLoss }),
          cueLine(184, {
            conditions: treasureLoss,
            replacesCueIds: [`${resultSceneId}_005`],
          }),
          174,
          175,
          176,
          177,
        ],
        "승리 후 대화 + 선택/분기 메모",
        {
          repeatPolicy: "once_battle",
          metadata: { branch_group: "treasure_loss", branch_mode: "exclusive", replacement_cue_count: 2 },
        },
      ),
    ],
  };
}

function buildDay03(lines) {
  const bossScene = (threshold, cueLines) =>
    scene(lines, {
      id: `STORY_D03_COMBAT_BOSS_HP_${String(Math.round(threshold * 100)).padStart(2, "0")}`,
      day: 3,
      trigger: "combat_boss_hp",
      delivery: "combat_bark",
      repeatPolicy: "once_battle",
      queuePolicy: "append",
      metadata: {
        source_section: "전투 중 짧은 대화",
        threshold,
      },
      cueLines,
    });
  return {
    schema_version: 1,
    day: 3,
    scenes: [
      blockingScene(lines, 3, "STORY_D03_MANAGEMENT_ENTRY", "management_entered", range(201, 208), "관리 전 대화"),
      blockingScene(lines, 3, "STORY_D03_PRECOMBAT", "precombat_confirmed", range(212, 219), "전투 직전 대화", {
        repeatPolicy: "once_battle",
      }),
      bossScene(0.75, range(223, 226)),
      bossScene(0.5, range(227, 228)),
      bossScene(0.25, range(229, 230)),
      blockingScene(lines, 3, "STORY_D03_RESULT_WIN", "result_win", range(234, 241), "승리 후 대화", {
        repeatPolicy: "once_battle",
      }),
      blockingScene(lines, 3, "STORY_D03_RESULT_LOSS", "result_loss", range(250, 251), "선택/분기 메모", {
        repeatPolicy: "once_battle",
      }),
    ],
  };
}

function buildDay04(lines) {
  const gobSelected = raidMonster("mon_core_gob");
  const puddingSelected = raidMonster("mon_core_pudding");
  const pynnSelected = raidMonster("mon_core_pynn");
  const rosterCues = [
    ...range(278, 284),
    cueLine(289, { conditions: gobSelected }),
    cueLine(290, { conditions: gobSelected }),
    cueLine(292, { conditions: puddingSelected }),
    cueLine(293, { conditions: puddingSelected }),
    cueLine(295, { conditions: pynnSelected }),
    cueLine(296, { conditions: pynnSelected }),
  ];
  const resolutionCues = [
    300,
    301,
    cueLine(303, { conditions: gobSelected }),
    cueLine(304, { conditions: gobSelected }),
    cueLine(306, { conditions: puddingSelected }),
    cueLine(307, { conditions: puddingSelected }),
    cueLine(309, { conditions: pynnSelected }),
    cueLine(310, { conditions: pynnSelected }),
    311,
    312,
    313,
    ...range(317, 324),
  ];
  return {
    schema_version: 1,
    day: 4,
    scenes: [
      blockingScene(lines, 4, "STORY_D04_MANAGEMENT_ENTRY", "management_entered", range(267, 274), "관리 전 대화"),
      blockingScene(
        lines,
        4,
        "STORY_D04_RAID_ROSTER",
        "raid_roster_confirmed",
        rosterCues,
        "전투 직전 대화 + 원정대 선택 반응",
        {
          repeatPolicy: "once_raid",
          conditions: raidMission("d04_signpost_flip"),
          metadata: { mission_id: "d04_signpost_flip", branch_mode: "additive", sequence: 1 },
        },
      ),
      blockingScene(
        lines,
        4,
        "STORY_D04_RAID_RESOLUTION",
        "raid_completed",
        resolutionCues,
        "전투 중 짧은 대화 + 승리 후 대화",
        {
          repeatPolicy: "once_raid",
          conditions: raidMission("d04_signpost_flip"),
          metadata: { mission_id: "d04_signpost_flip", branch_mode: "additive" },
        },
      ),
      blockingScene(lines, 4, "STORY_D04_DEFENSE_ARRIVAL", "combat_started", range(330, 331), "선택/분기 메모", {
        repeatPolicy: "once_battle",
        conditions: condition("day4_raid_completed", "eq", true),
        metadata: { requires_story_flag: "raid_d04_signpost_complete" },
      }),
    ],
  };
}

function buildDay05(lines) {
  return {
    schema_version: 1,
    day: 5,
    scenes: [
      blockingScene(lines, 5, "STORY_D05_MANAGEMENT_ENTRY", "management_entered", range(348, 355), "관리 전 대화"),
      blockingScene(lines, 5, "STORY_D05_PRECOMBAT", "precombat_confirmed", range(359, 366), "전투 직전 대화", {
        repeatPolicy: "once_battle",
      }),
      ...combatTimeScenes(lines, 5, 370, "STORY_D05_COMBAT_TIME"),
      blockingScene(lines, 5, "STORY_D05_RESULT_WIN", "result_win", range(381, 388), "승리 후 대화", {
        repeatPolicy: "once_battle",
      }),
      blockingScene(lines, 5, "STORY_D05_RAID_RESULT", "raid_completed", range(394, 396), "선택/분기 메모", {
        repeatPolicy: "once_raid",
        conditions: raidMission("d05_supply_tag"),
        metadata: { mission_id: "d05_supply_tag" },
      }),
    ],
  };
}

function validatePortraitEmotions(days) {
  const charactersPath = path.join(REPO_ROOT, "data", "characters.json");
  const characters = JSON.parse(fs.readFileSync(charactersPath, "utf8"));
  for (const day of days) {
    for (const storyScene of day.scenes) {
      for (const cue of storyScene.cues) {
        if (cue.speaker_id === "NARRATOR") {
          if (cue.portrait_emotion !== "none") {
            fail(`Narrator cue ${cue.id} must use portrait_emotion none`);
          }
          continue;
        }
        const character = characters[cue.speaker_id];
        if (!character) {
          fail(`Unknown character ${cue.speaker_id} in ${cue.id}`);
        }
        const observed = character.portrait?.observed_emotions ?? [];
        if (!observed.includes(cue.portrait_emotion)) {
          fail(`Unsupported portrait emotion ${cue.portrait_emotion} for ${cue.speaker_id} in ${cue.id}`);
        }
      }
    }
  }
}

function buildOutputs() {
  const lines = readSnapshotLines();
  const days = [buildDay01(lines), buildDay02(lines), buildDay03(lines), buildDay04(lines), buildDay05(lines)];
  validatePortraitEmotions(days);
  const dayFiles = days.map((day) => `res://data/story/v122_main/day_${String(day.day).padStart(2, "0")}.json`);
  const manifest = {
    schema_version: 1,
    source_sha256: SOURCE_SHA256,
    source_snapshot: `res://${SNAPSHOT_RELATIVE_PATH}`,
    day_files: dayFiles,
  };
  const outputs = new Map();
  outputs.set(path.join(OUTPUT_DIR, "manifest.json"), `${JSON.stringify(manifest, null, 2)}\n`);
  for (const day of days) {
    outputs.set(
      path.join(OUTPUT_DIR, `day_${String(day.day).padStart(2, "0")}.json`),
      `${JSON.stringify(day, null, 2)}\n`,
    );
  }
  return outputs;
}

function writeOutputs(outputs) {
  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  for (const [outputPath, content] of outputs) {
    fs.writeFileSync(outputPath, content, "utf8");
  }
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
    const actual = fs.readFileSync(outputPath, "utf8");
    if (actual !== expected) {
      console.error(`STALE ${relativePath}`);
      failed = true;
    }
  }
  if (failed) {
    process.exitCode = 1;
    return;
  }
  console.log(`V122_STORY_DAY01_05_GENERATOR_CHECK: PASS (${outputs.size} files)`);
}

function main() {
  const args = process.argv.slice(2);
  const refreshIndex = args.indexOf("--refresh-source");
  if (refreshIndex >= 0) {
    const sourcePath = args[refreshIndex + 1];
    if (!sourcePath) {
      fail("--refresh-source requires a full source Markdown path");
    }
    refreshSnapshot(path.resolve(sourcePath));
  }
  const outputs = buildOutputs();
  if (args.includes("--check")) {
    checkOutputs(outputs);
  } else {
    writeOutputs(outputs);
    console.log(`V122_STORY_DAY01_05_GENERATOR: PASS (${outputs.size} files)`);
  }
}

main();
