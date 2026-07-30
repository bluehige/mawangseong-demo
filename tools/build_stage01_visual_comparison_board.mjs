import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const sharp = require("sharp");

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDir, "..");
const outputPath =
  process.argv[2] || "C:\\tmp\\v122_stage01_visual_comparison_board_2026-07-29.png";

const W = 2400;
const H = 3000;
const C = {
  void: "#07060B",
  surface: "#0C0B12",
  panel: "#111019",
  panelSoft: "#17151F",
  line: "#393442",
  text: "#F1E9DC",
  muted: "#A9A0B2",
  brass: "#766044",
  purple: "#8C6AB0",
  gold: "#F0C85B",
  danger: "#B65A59",
  info: "#6F91A8",
  success: "#62A884",
  laneA: "#625477",
  laneB: "#4C6171",
};

function esc(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function svg(width, height, body) {
  return Buffer.from(
    `<svg width="${width}" height="${height}" viewBox="0 0 ${width} ${height}" xmlns="http://www.w3.org/2000/svg">${body}</svg>`,
  );
}

function text(lines, options = {}) {
  const {
    width = 800,
    height = 160,
    x = 0,
    y = 30,
    size = 22,
    weight = 500,
    color = C.text,
    lineHeight = Math.round(size * 1.42),
    anchor = "start",
  } = options;
  const tspans = lines
    .map(
      (line, index) =>
        `<tspan x="${x}" dy="${index === 0 ? 0 : lineHeight}">${esc(line)}</tspan>`,
    )
    .join("");
  return svg(
    width,
    height,
    `<text x="${x}" y="${y}" fill="${color}" font-family="Malgun Gothic, Noto Sans CJK KR, sans-serif" font-size="${size}" font-weight="${weight}" text-anchor="${anchor}">${tspans}</text>`,
  );
}

function sectionLabel(index, title, note = "") {
  return svg(
    2320,
    58,
    `<text x="0" y="36" fill="${C.gold}" font-family="Malgun Gothic, sans-serif" font-size="18" font-weight="800">${esc(index)}</text>
     <text x="44" y="36" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="27" font-weight="800">${esc(title)}</text>
     <text x="2320" y="34" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="15" text-anchor="end">${esc(note)}</text>
     <line x1="0" y1="56" x2="2320" y2="56" stroke="${C.line}" stroke-width="2"/>`,
  );
}

function loadQuarterData() {
  const base = JSON.parse(
    fs.readFileSync(path.join(projectRoot, "data/dungeon_quarter/room_blueprints.json"), "utf8"),
  );
  const dual = JSON.parse(
    fs.readFileSync(path.join(projectRoot, "data/dungeon_quarter/dual_front_blueprints.json"), "utf8"),
  );
  const layout = JSON.parse(
    fs.readFileSync(
      path.join(projectRoot, "data/dungeon_quarter/layouts/stage01_dual_front_01.json"),
      "utf8",
    ),
  );
  return { blueprints: { ...base, ...dual }, layout };
}

function mapGeometry(targetW, targetH) {
  const { blueprints, layout } = loadQuarterData();
  const cells = [];
  const centers = {};
  for (const placed of layout.placed_modules || []) {
    const module = blueprints[placed.module_id];
    if (!module) continue;
    const origin = placed.grid_origin || [0, 0];
    const projectedCells = [];
    for (const local of module.floor_cells || []) {
      const x = origin[0] + local[0];
      const y = origin[1] + local[1];
      cells.push({
        x,
        y,
        instanceId: placed.instance_id,
        moduleType: module.module_type || "",
      });
      projectedCells.push([x, y]);
    }
    if (projectedCells.length > 0) {
      centers[placed.instance_id] = [
        projectedCells.reduce((sum, cell) => sum + cell[0], 0) / projectedCells.length,
        projectedCells.reduce((sum, cell) => sum + cell[1], 0) / projectedCells.length,
      ];
    }
  }

  const halfW = 11;
  const halfH = 5.5;
  const projected = cells.map((cell) => ({
    ...cell,
    px: (cell.x - cell.y) * halfW,
    py: (cell.x + cell.y) * halfH,
  }));
  const minX = Math.min(...projected.map((cell) => cell.px - halfW));
  const maxX = Math.max(...projected.map((cell) => cell.px + halfW));
  const minY = Math.min(...projected.map((cell) => cell.py - halfH));
  const maxY = Math.max(...projected.map((cell) => cell.py + halfH));
  const scale = Math.min((targetW - 80) / (maxX - minX), (targetH - 64) / (maxY - minY));
  const ox = (targetW - (maxX - minX) * scale) * 0.5 - minX * scale;
  const oy = (targetH - (maxY - minY) * scale) * 0.5 - minY * scale;
  return { projected, centers, halfW, halfH, scale, ox, oy };
}

function instanceFill(instanceId, moduleType) {
  if (instanceId === "spike_corridor" || instanceId.startsWith("lane_a")) return C.laneA;
  if (instanceId.startsWith("lane_b")) return C.laneB;
  if (instanceId.includes("approach") || instanceId.includes("entrance")) return "#343947";
  if (instanceId === "throne" || instanceId === "throne_antechamber") return "#53313E";
  if (moduleType === "corridor" || moduleType === "junction") return "#34313E";
  if (instanceId === "treasure") return "#54472F";
  if (instanceId === "recovery") return "#30483F";
  if (instanceId === "barracks") return "#4A4037";
  return "#3E3548";
}

function mapSvg(targetW, targetH, compact = false) {
  const geometry = mapGeometry(targetW, targetH);
  const diamonds = geometry.projected
    .sort((a, b) => a.x + a.y - (b.x + b.y))
    .map((cell) => {
      const cx = cell.px * geometry.scale + geometry.ox;
      const cy = cell.py * geometry.scale + geometry.oy;
      const hw = geometry.halfW * geometry.scale;
      const hh = geometry.halfH * geometry.scale;
      const fill = instanceFill(cell.instanceId, cell.moduleType);
      return `<polygon points="${cx},${cy - hh} ${cx + hw},${cy} ${cx},${cy + hh} ${cx - hw},${cy}" fill="${fill}" stroke="#70697A" stroke-width="${compact ? 0.5 : 0.8}" opacity="0.96"/>`;
    })
    .join("");

  const labels = [
    ["outside_approach", "정문 A", C.info],
    ["outside_approach_b", "균열 B", C.purple],
    ["spike_corridor", "A · 협폭", C.text],
    ["lane_b_front", "B · 광폭", C.text],
    ["throne_antechamber", "전실", C.gold],
    ["throne", "왕좌", C.gold],
  ]
    .map(([id, label, color]) => {
      const center = geometry.centers[id];
      if (!center) return "";
      const px = (center[0] - center[1]) * geometry.halfW * geometry.scale + geometry.ox;
      const py = (center[0] + center[1]) * geometry.halfH * geometry.scale + geometry.oy;
      return `<circle cx="${px}" cy="${py}" r="${compact ? 3.2 : 4.5}" fill="${color}"/>
        <text x="${px + (compact ? 7 : 10)}" y="${py - (compact ? 5 : 7)}" fill="${color}" font-family="Malgun Gothic, sans-serif" font-size="${compact ? 9 : 13}" font-weight="700">${esc(label)}</text>`;
    })
    .join("");

  return `<g>${diamonds}${labels}</g>`;
}

function managementMockup(width, height, compact = false) {
  const topH = compact ? 38 : 46;
  const bottomH = compact ? 66 : 82;
  const drawerW = compact ? 172 : 224;
  const mapTop = topH + 6;
  const mapBottom = height - bottomH - 8;
  const mapW = width - drawerW - 38;
  const mapH = mapBottom - mapTop;
  const drawerX = width - drawerW - 12;
  const map = mapSvg(mapW, mapH, compact);
  const font = compact ? 10 : 13;

  return svg(
    width,
    height,
    `<defs>
       <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
         <stop offset="0" stop-color="#120F19"/>
         <stop offset="0.55" stop-color="#07060B"/>
         <stop offset="1" stop-color="#171020"/>
       </linearGradient>
       <radialGradient id="violetFog">
         <stop offset="0" stop-color="#6C4384" stop-opacity="0.34"/>
         <stop offset="1" stop-color="#07060B" stop-opacity="0"/>
       </radialGradient>
     </defs>
     <rect x="1" y="1" width="${width - 2}" height="${height - 2}" rx="10" fill="url(#bg)" stroke="${C.line}" stroke-width="2"/>
     <ellipse cx="${width * 0.22}" cy="${height * 0.3}" rx="${width * 0.24}" ry="${height * 0.24}" fill="url(#violetFog)"/>
     <ellipse cx="${width * 0.78}" cy="${height * 0.7}" rx="${width * 0.24}" ry="${height * 0.3}" fill="url(#violetFog)" opacity="0.55"/>
     <rect x="8" y="7" width="${width - 16}" height="${topH - 8}" fill="#111019E8"/>
     <text x="22" y="${compact ? 28 : 32}" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="${font}" font-weight="700">금화 1,245</text>
     <text x="${compact ? 150 : 196}" y="${compact ? 28 : 32}" fill="${C.info}" font-family="Malgun Gothic, sans-serif" font-size="${font}">마력 320</text>
     <text x="${compact ? 254 : 356}" y="${compact ? 28 : 32}" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="${font}">식량 18/30</text>
     <text x="${width * 0.57}" y="${compact ? 28 : 32}" fill="${C.brass}" font-family="Malgun Gothic, sans-serif" font-size="${font}" font-weight="700">DAY 01 · 밤</text>
     <text x="${width - 22}" y="${compact ? 28 : 32}" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="${font}" text-anchor="end">왕좌 1500/1500</text>
     <g transform="translate(9 ${mapTop})">${map}</g>
     <rect x="${drawerX}" y="${topH + 20}" width="${drawerW}" height="${height - topH - bottomH - 38}" rx="8" fill="#111019EE" stroke="${C.purple}" stroke-width="${compact ? 1 : 1.5}"/>
     <text x="${drawerX + 16}" y="${topH + 48}" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="${compact ? 11 : 15}" font-weight="800">선택 · 가시 전선 A</text>
     <line x1="${drawerX + 14}" y1="${topH + 62}" x2="${width - 26}" y2="${topH + 62}" stroke="${C.line}"/>
     <text x="${drawerX + 16}" y="${topH + 88}" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="${compact ? 9 : 12}">배치 1/2 · 함정 활성</text>
     <text x="${drawerX + 16}" y="${topH + (compact ? 116 : 126)}" fill="${C.purple}" font-family="Malgun Gothic, sans-serif" font-size="${compact ? 9 : 12}" font-weight="700">전술 · 후퇴선 유지</text>
     <rect x="${drawerX + 14}" y="${topH + (compact ? 138 : 154)}" width="${drawerW - 28}" height="${compact ? 30 : 38}" rx="5" fill="#21182A" stroke="${C.purple}"/>
     <text x="${drawerX + drawerW / 2}" y="${topH + (compact ? 158 : 179)}" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="${compact ? 9 : 12}" text-anchor="middle">전술 변경</text>
     <rect x="8" y="${height - bottomH}" width="${width - 16}" height="${bottomH - 8}" fill="#111019F2" stroke="${C.line}"/>
     <text x="24" y="${height - bottomH + (compact ? 24 : 29)}" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="${compact ? 9 : 12}" font-weight="700">수비대</text>
     ${[0, 1, 2]
       .map(
         (index) =>
           `<circle cx="${compact ? 78 + index * 38 : 104 + index * 54}" cy="${height - bottomH / 2 + 5}" r="${compact ? 12 : 17}" fill="${index === 0 ? "#557BC4" : index === 1 ? "#6C9A4E" : "#B84F45"}" stroke="${index === 0 ? C.gold : C.brass}" stroke-width="${index === 0 ? 2 : 1}"/>`,
       )
       .join("")}
     <rect x="${width - (compact ? 166 : 230)}" y="${height - bottomH + (compact ? 12 : 15)}" width="${compact ? 146 : 206}" height="${compact ? 42 : 52}" rx="6" fill="#3B2810" stroke="${C.gold}" stroke-width="3"/>
     <text x="${width - (compact ? 93 : 127)}" y="${height - bottomH + (compact ? 39 : 48)}" fill="#FFF4CD" font-family="Malgun Gothic, sans-serif" font-size="${compact ? 13 : 18}" font-weight="800" text-anchor="middle">방어 시작</text>
     <text x="${compact ? 220 : 300}" y="${height - 22}" fill="${C.info}" font-family="Malgun Gothic, sans-serif" font-size="${compact ? 8 : 11}">지도는 축소하지 않고 설명·장식을 접는다</text>`,
  );
}

function frameSystemSvg(width, height) {
  const samples = [
    { x: 24, title: "PRIMARY", subtitle: "화면당 하나", stroke: C.gold, fill: "#35250F", sw: 3 },
    { x: 384, title: "TACTICAL", subtitle: "대상·전술 선택", stroke: C.purple, fill: "#21182A", sw: 2 },
    { x: 744, title: "UTILITY / STATUS", subtitle: "정보·보조·취소", stroke: C.brass, fill: "#15141B", sw: 1 },
  ];
  return svg(
    width,
    height,
    `<text x="24" y="32" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="20" font-weight="800">프레임 3등급 · 장식보다 역할</text>
     ${samples
       .map(
         (sample) =>
           `<rect x="${sample.x}" y="58" width="324" height="92" rx="8" fill="${sample.fill}" stroke="${sample.stroke}" stroke-width="${sample.sw}"/>
            <text x="${sample.x + 20}" y="92" fill="${sample.stroke}" font-family="Malgun Gothic, sans-serif" font-size="14" font-weight="800">${sample.title}</text>
            <text x="${sample.x + 20}" y="124" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="17" font-weight="700">${esc(sample.subtitle)}</text>`,
       )
       .join("")}
     <text x="24" y="186" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="14">위험 적갈은 프레임 등급이 아니라 치명 경고·파괴·실패에만 사용</text>
     <line x1="24" y1="214" x2="${width - 24}" y2="214" stroke="${C.line}"/>
     <text x="24" y="248" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="18" font-weight="800">상호작용</text>
     <text x="24" y="282" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="14">80ms 국소 hover · 160ms drawer 진입 · compact 설명 접힘</text>`,
  );
}

function paletteSvg(width, height) {
  const swatches = [
    ["암부", C.void],
    ["패널", C.panel],
    ["어두운 황동", C.brass],
    ["마력 보라", C.purple],
    ["판단 황금", C.gold],
    ["위험 적갈", C.danger],
    ["정보 청회", C.info],
  ];
  return svg(
    width,
    height,
    `<text x="24" y="32" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="20" font-weight="800">팔레트 역할 · 밝은 황금은 하나만</text>
     ${swatches
       .map((swatch, index) => {
         const x = 24 + (index % 4) * 260;
         const y = 60 + Math.floor(index / 4) * 104;
         return `<rect x="${x}" y="${y}" width="236" height="72" rx="6" fill="${swatch[1]}" stroke="${swatch[1] === C.void ? C.line : swatch[1]}"/>
           <text x="${x + 14}" y="${y + 30}" fill="${swatch[1] === C.gold ? "#21180B" : C.text}" font-family="Malgun Gothic, sans-serif" font-size="14" font-weight="800">${esc(swatch[0])}</text>
           <text x="${x + 14}" y="${y + 55}" fill="${swatch[1] === C.gold ? "#4D3915" : "#D8D0DD"}" font-family="Consolas, monospace" font-size="12">${swatch[1]}</text>`;
       })
       .join("")}
     <text x="24" y="282" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="14">석재 경로는 철색·보라 회색 · 현재 판단 지점만 황금 · 위험은 적갈</text>`,
  );
}

async function containImage(assetPath, width, height) {
  return sharp(assetPath)
    .resize({
      width,
      height,
      fit: "contain",
      withoutEnlargement: true,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();
}

function contactCellSvg(width, height, label, status, statusColor, actor = false) {
  return svg(
    width,
    height,
    `<rect x="1" y="1" width="${width - 2}" height="${height - 2}" fill="${C.panelSoft}" stroke="${C.line}"/>
     ${actor ? `<ellipse cx="${width / 2}" cy="${height - 54}" rx="${width * 0.24}" ry="12" fill="#000000" opacity="0.55"/>` : ""}
     <line x1="18" y1="${height - 48}" x2="${width - 18}" y2="${height - 48}" stroke="${C.brass}" stroke-opacity="0.55"/>
     <text x="16" y="${height - 20}" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="15" font-weight="800">${esc(label)}</text>
     <text x="${width - 16}" y="${height - 20}" fill="${statusColor}" font-family="Malgun Gothic, sans-serif" font-size="11" font-weight="800" text-anchor="end">${esc(status)}</text>`,
  );
}

function compositeOrderSvg(width, height) {
  const stages = [
    ["01", "바닥", "#363441"],
    ["02", "접촉 그림자", "#111016"],
    ["03", "선택 링", C.gold],
    ["04", "캐릭터", C.purple],
    ["05", "일반 VFX", "#9B5C4D"],
    ["06", "이름 · 체력", C.info],
    ["07", "치명 경고", C.danger],
  ];
  return svg(
    width,
    height,
    `<text x="24" y="34" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="21" font-weight="800">전투 합성 순서 · 캐릭터 실루엣이 항상 우선</text>
     ${stages
       .map((stage, index) => {
         const x = 24 + index * 316;
         return `<rect x="${x}" y="64" width="276" height="116" rx="7" fill="${C.panelSoft}" stroke="${stage[2]}" stroke-width="${index === 2 ? 2 : 1}"/>
           <text x="${x + 18}" y="94" fill="${stage[2]}" font-family="Consolas, monospace" font-size="13" font-weight="800">${stage[0]}</text>
           <text x="${x + 18}" y="136" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="17" font-weight="800">${esc(stage[1])}</text>
           ${index < stages.length - 1 ? `<path d="M ${x + 282} 122 L ${x + 306} 122" stroke="${C.line}" stroke-width="2"/><path d="M ${x + 300} 116 L ${x + 306} 122 L ${x + 300} 128" fill="none" stroke="${C.line}" stroke-width="2"/>` : ""}`;
       })
       .join("")}
     <text x="24" y="226" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="15">미선택 링 숨김 · 라벨 충돌 회피 · 일반 VFX의 휘도와 면적 제한 · 적아군은 링 형상과 얇은 림라이트로도 구분</text>
     <line x1="24" y1="258" x2="${width - 24}" y2="258" stroke="${C.line}"/>
     <text x="24" y="294" fill="${C.gold}" font-family="Malgun Gothic, sans-serif" font-size="16" font-weight="800">승인 단위</text>
     <text x="126" y="294" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="16">작업면 비율 · 프레임/팔레트 · 환경/캐릭터 기준 · 합성 순서를 함께 확정</text>
     <text x="${width - 24}" y="294" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="14" text-anchor="end">승인 전 런타임 자산 변경 없음</text>`,
  );
}

async function build() {
  const layers = [];
  layers.push({
    input: text(["마왕성 · STAGE 01 VISUAL SYSTEM"], {
      width: W,
      height: 70,
      x: 42,
      y: 46,
      size: 32,
      weight: 900,
      color: C.text,
    }),
    left: 0,
    top: 0,
  });
  layers.push({
    input: text(
      ["이중 전선이 화면의 주인공이고, 현재 판단 지점 하나만 밝은 황금으로 드러난다."],
      { width: W - 84, height: 50, x: 42, y: 29, size: 17, color: C.muted },
    ),
    left: 0,
    top: 65,
  });
  layers.push({
    input: text(["APPROVAL BOARD · 2026-07-29"], {
      width: 500,
      height: 42,
      x: 458,
      y: 27,
      size: 13,
      weight: 700,
      color: C.brass,
      anchor: "end",
    }),
    left: W - 510,
    top: 21,
  });

  layers.push({
    input: sectionLabel("01", "작업면 비교", "1920 full-canvas / 1280 compact"),
    left: 40,
    top: 124,
  });
  layers.push({
    input: text(["1920 · FULL-CANVAS"], {
      width: 1520,
      height: 42,
      x: 0,
      y: 28,
      size: 15,
      weight: 800,
      color: C.gold,
    }),
    left: 40,
    top: 194,
  });
  layers.push({ input: managementMockup(1510, 850, false), left: 40, top: 234 });
  layers.push({
    input: text(["1280 · COMPACT"], {
      width: 800,
      height: 42,
      x: 0,
      y: 28,
      size: 15,
      weight: 800,
      color: C.info,
    }),
    left: 1580,
    top: 194,
  });
  layers.push({ input: managementMockup(780, 439, true), left: 1580, top: 234 });
  layers.push({
    input: text(
      [
        "FULL-CANVAS",
        "• 지도는 상태 레일과 하단 rail 사이 전체",
        "• drawer 진입 시 지도 safe-area 재중심",
        "• Primary는 ‘방어 시작’ 하나",
        "",
        "COMPACT",
        "• 지도·캐릭터 최소 크기는 유지",
        "• drawer가 핵심 지도 영역을 가리지 않음",
        "• 짧은 라벨과 핵심 수치만 노출",
        "",
        "공통",
        "• 두 입구와 왕좌 전실이 한눈에 보임",
        "• 정적 경로는 황금색을 사용하지 않음",
      ],
      {
        width: 760,
        height: 378,
        x: 0,
        y: 26,
        size: 14,
        color: C.text,
        lineHeight: 25,
      },
    ),
    left: 1600,
    top: 688,
  });

  layers.push({
    input: sectionLabel("02", "프레임과 색 역할", "장식보다 상태와 판단"),
    left: 40,
    top: 1118,
  });
  layers.push({
    input: svg(
      2320,
      340,
      `<rect x="0" y="0" width="1110" height="340" fill="${C.surface}" stroke="${C.line}"/>
       <rect x="1130" y="0" width="1190" height="340" fill="${C.surface}" stroke="${C.line}"/>`,
    ),
    left: 40,
    top: 1188,
  });
  layers.push({ input: frameSystemSvg(1080, 310), left: 56, top: 1202 });
  layers.push({ input: paletteSvg(1158, 310), left: 1186, top: 1202 });

  layers.push({
    input: sectionLabel("03", "환경과 캐릭터의 공통 기준", "같은 크기 · 같은 광원 · 같은 발 기준선"),
    left: 40,
    top: 1560,
  });
  layers.push({
    input: text(["STAGE 01 · 환경 6종"], {
      width: 1450,
      height: 42,
      x: 0,
      y: 28,
      size: 17,
      weight: 800,
      color: C.text,
    }),
    left: 40,
    top: 1624,
  });
  layers.push({
    input: text(["DAY 01 · 전투 캐릭터 4종"], {
      width: 830,
      height: 42,
      x: 0,
      y: 28,
      size: 17,
      weight: 800,
      color: C.text,
    }),
    left: 1530,
    top: 1624,
  });

  const roomAssets = [
    ["입구", "assets/props/stage_01/prop_entrance_gate_stage01_SE_back.png", "유지", C.success],
    ["병영", "assets/props/stage_01/prop_weapon_rack_stage01_SE_back.png", "유지", C.success],
    ["회복실", "assets/props/stage_01/prop_recovery_nest_stage01_NW_front.png", "유지", C.success],
    ["보물실", "assets/props/stage_01/prop_treasure_pile_stage01_NW_front.png", "유지", C.success],
    ["건설 슬롯", "assets/props/stage_01/prop_foundation_marks_stage01_NE_back.png", "유지", C.success],
    ["왕좌", "assets/props/stage_01/prop_throne_stage01_SW_back.png", "교체", C.danger],
  ];
  const roomCellW = 454;
  const roomCellH = 330;
  for (let index = 0; index < roomAssets.length; index += 1) {
    const [label, relative, status, statusColor] = roomAssets[index];
    const col = index % 3;
    const row = Math.floor(index / 3);
    const left = 40 + col * (roomCellW + 18);
    const top = 1672 + row * (roomCellH + 18);
    layers.push({
      input: contactCellSvg(roomCellW, roomCellH, label, status, statusColor, false),
      left,
      top,
    });
    layers.push({
      input: await containImage(path.join(projectRoot, relative), roomCellW - 28, 254),
      left: left + 14,
      top: top + 10,
    });
  }

  const actorAssets = [
    ["슬라임", "assets/sprites/monsters/monster_slime_idle_down_00.png"],
    ["고블린", "assets/sprites/monsters/monster_goblin_idle_down_00.png"],
    ["임프", "assets/sprites/monsters/monster_imp_idle_down_00.png"],
    ["수습 용사", "assets/sprites/enemies/enemy_trainee_hero_idle_down_00.png"],
  ];
  const actorCellW = 396;
  const actorCellH = 330;
  for (let index = 0; index < actorAssets.length; index += 1) {
    const [label, relative] = actorAssets[index];
    const col = index % 2;
    const row = Math.floor(index / 2);
    const left = 1530 + col * (actorCellW + 18);
    const top = 1672 + row * (actorCellH + 18);
    layers.push({
      input: contactCellSvg(actorCellW, actorCellH, label, "현행 비교", C.info, true),
      left,
      top,
    });
    layers.push({
      input: await containImage(path.join(projectRoot, relative), 236, 236),
      left: left + 80,
      top: top + 20,
    });
  }
  layers.push({
    input: text(
      [
        "고정 기준",
        "30~35° 하향 투영 · 좌상단 온광 · 보라 환경 반사광",
        "같은 발 기준선 · 낮고 부드러운 접촉 그림자 · 채도 상한",
      ],
      { width: 830, height: 96, x: 0, y: 26, size: 13, color: C.muted, lineHeight: 23 },
    ),
    left: 1530,
    top: 2352,
  });

  layers.push({
    input: sectionLabel("04", "전투 합성 순서", "바닥 → 경고, 실루엣 우선"),
    left: 40,
    top: 2428,
  });
  layers.push({
    input: svg(
      2320,
      350,
      `<rect x="0" y="0" width="2320" height="350" fill="${C.surface}" stroke="${C.line}"/>`,
    ),
    left: 40,
    top: 2498,
  });
  layers.push({ input: compositeOrderSvg(2288, 320), left: 56, top: 2513 });

  layers.push({
    input: svg(
      2320,
      86,
      `<rect x="0" y="0" width="2320" height="86" fill="#18130B" stroke="${C.gold}" stroke-width="2"/>
       <text x="22" y="34" fill="${C.gold}" font-family="Malgun Gothic, sans-serif" font-size="16" font-weight="900">NEXT</text>
       <text x="92" y="34" fill="${C.text}" font-family="Malgun Gothic, sans-serif" font-size="17" font-weight="800">보드 승인 뒤 왕좌 · 4방향 2셀 문턱 · 저채도 복도 표면의 exact guide 제작</text>
       <text x="22" y="64" fill="${C.muted}" font-family="Malgun Gothic, sans-serif" font-size="13">현재 산출물은 방향 승인용이며 게임 코드·데이터·런타임 자산을 변경하지 않는다.</text>`,
    ),
    left: 40,
    top: 2882,
  });

  await sharp({
    create: {
      width: W,
      height: H,
      channels: 4,
      background: C.void,
    },
  })
    .composite(layers)
    .png()
    .toFile(outputPath);

  process.stdout.write(`${outputPath}\n`);
}

await build();
