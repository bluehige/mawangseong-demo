import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const sharp = require("sharp");

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDir, "..");
const outputPath = process.argv[2] || "C:\\tmp\\v122_phase4_stage01_review_board.png";
const screenshotPath =
  process.argv[3] ||
  "C:\\Users\\LDK-6248\\AppData\\Local\\Temp\\codex-clipboard-3c15671b-a40f-4c77-8d76-ed77de29ce4c.png";

const width = 1920;
const height = 1760;
const background = "#08070d";
const panel = "#100e16";
const panelSoft = "#17131f";
const line = "#5f536a";
const text = "#f3eadc";
const muted = "#bdb3c6";
const gold = "#ffe4a0";
const brass = "#8d6a3a";
const purple = "#9e7bd1";
const danger = "#e56a72";
const info = "#6ea6d8";
const success = "#58c997";

function escapeXml(value) {
  return String(value)
    .replaceAll("&", "&amp;")
    .replaceAll("<", "&lt;")
    .replaceAll(">", "&gt;")
    .replaceAll('"', "&quot;");
}

function textSvg(lines, options = {}) {
  const {
    width: svgWidth = 800,
    height: svgHeight = 200,
    x = 0,
    y = 34,
    size = 24,
    color = text,
    weight = 600,
    lineHeight = Math.round(size * 1.45),
    align = "start",
  } = options;
  const anchor = align === "center" ? "middle" : align === "end" ? "end" : "start";
  const tspans = lines
    .map(
      (lineValue, index) =>
        `<tspan x="${x}" dy="${index === 0 ? 0 : lineHeight}">${escapeXml(lineValue)}</tspan>`,
    )
    .join("");
  return Buffer.from(`
    <svg width="${svgWidth}" height="${svgHeight}" xmlns="http://www.w3.org/2000/svg">
      <text x="${x}" y="${y}" fill="${color}" font-family="Malgun Gothic, Noto Sans CJK KR, sans-serif"
        font-size="${size}" font-weight="${weight}" text-anchor="${anchor}">${tspans}</text>
    </svg>
  `);
}

function panelSvg(panelWidth, panelHeight, stroke = line, fill = panel) {
  return Buffer.from(`
    <svg width="${panelWidth}" height="${panelHeight}" xmlns="http://www.w3.org/2000/svg">
      <rect x="1" y="1" width="${panelWidth - 2}" height="${panelHeight - 2}" rx="12"
        fill="${fill}" stroke="${stroke}" stroke-width="2"/>
    </svg>
  `);
}

function cellKey(cell) {
  return `${cell[0]},${cell[1]}`;
}

function routeSchematicSvg(svgWidth, svgHeight) {
  const blueprints = JSON.parse(
    fs.readFileSync(path.join(projectRoot, "data/dungeon_quarter/room_blueprints.json"), "utf8"),
  );
  const layout = JSON.parse(
    fs.readFileSync(path.join(projectRoot, "data/dungeon_quarter/starting_layout.json"), "utf8"),
  );

  const moduleColors = {
    throne: "#5a283a",
    barracks: "#4d4639",
    recovery: "#344a3f",
    entrance: "#3e4050",
    treasure: "#5b4a2c",
    slot_01: "#40314d",
    spike_corridor: "#51445f",
    outside_approach: "#465264",
  };
  const cells = [];
  const corridorSockets = [];
  for (const placed of layout.placed_modules) {
    const module = blueprints[placed.module_id];
    if (!module) continue;
    const origin = placed.grid_origin || [0, 0];
    for (const local of module.floor_cells || []) {
      cells.push({
        x: origin[0] + local[0],
        y: origin[1] + local[1],
        instanceId: placed.instance_id,
        corridor: ["corridor", "junction"].includes(module.module_type),
      });
    }
    for (const socket of module.sockets || []) {
      corridorSockets.push({
        x: origin[0] + socket.cell[0],
        y: origin[1] + socket.cell[1],
        instanceId: placed.instance_id,
      });
    }
  }

  const halfW = 9.4;
  const halfH = 4.7;
  const projected = cells.map((cell) => ({
    ...cell,
    sx: (cell.x - cell.y) * halfW,
    sy: (cell.x + cell.y) * halfH,
  }));
  const minX = Math.min(...projected.map((cell) => cell.sx - halfW));
  const maxX = Math.max(...projected.map((cell) => cell.sx + halfW));
  const minY = Math.min(...projected.map((cell) => cell.sy - halfH));
  const maxY = Math.max(...projected.map((cell) => cell.sy + halfH));
  const availableW = svgWidth - 54;
  const availableH = svgHeight - 92;
  const scale = Math.min(availableW / (maxX - minX), availableH / (maxY - minY));
  const offsetX = (svgWidth - (maxX - minX) * scale) * 0.5 - minX * scale;
  const offsetY = 62 + (availableH - (maxY - minY) * scale) * 0.5 - minY * scale;

  const diamonds = projected
    .sort((a, b) => a.x + a.y - (b.x + b.y))
    .map((cell) => {
      const cx = cell.sx * scale + offsetX;
      const cy = cell.sy * scale + offsetY;
      const hw = halfW * scale;
      const hh = halfH * scale;
      const fill = moduleColors[cell.instanceId] || "#3c3742";
      const stroke = cell.corridor ? "#8e7aa4" : "#706578";
      return `<polygon points="${cx},${cy - hh} ${cx + hw},${cy} ${cx},${cy + hh} ${cx - hw},${cy}"
        fill="${fill}" stroke="${stroke}" stroke-width="0.8"/>`;
    })
    .join("");

  const connectedRefs = new Set(
    layout.connections.flatMap((connection) => [connection.from, connection.to]),
  );
  const socketMarks = corridorSockets
    .filter((socket) =>
      [...connectedRefs].some((ref) => ref.startsWith(`${socket.instanceId}:`)),
    )
    .map((socket) => {
      const sx = (socket.x - socket.y) * halfW * scale + offsetX;
      const sy = (socket.x + socket.y) * halfH * scale + offsetY;
      return `<circle cx="${sx}" cy="${sy}" r="2.4" fill="${gold}" opacity="0.82"/>`;
    })
    .join("");

  return Buffer.from(`
    <svg width="${svgWidth}" height="${svgHeight}" xmlns="http://www.w3.org/2000/svg">
      <rect width="${svgWidth}" height="${svgHeight}" rx="10" fill="${panelSoft}"/>
      <text x="24" y="34" fill="${text}" font-family="Malgun Gothic, sans-serif"
        font-size="20" font-weight="700">실제 데이터 기반 이동 구조 · 28×26</text>
      <text x="${svgWidth - 24}" y="34" fill="${muted}" font-family="Malgun Gothic, sans-serif"
        font-size="13" text-anchor="end">방 5×5 · 복도 2셀 · floor=walkable</text>
      ${diamonds}
      ${socketMarks}
      <rect x="22" y="${svgHeight - 28}" width="14" height="8" fill="#51445f"/>
      <text x="44" y="${svgHeight - 20}" fill="${muted}" font-family="Malgun Gothic, sans-serif"
        font-size="12">복도 / 실제 이동 셀</text>
      <circle cx="${svgWidth - 178}" cy="${svgHeight - 24}" r="4" fill="${gold}"/>
      <text x="${svgWidth - 166}" y="${svgHeight - 20}" fill="${muted}" font-family="Malgun Gothic, sans-serif"
        font-size="12">접합 소켓</text>
    </svg>
  `);
}

async function thumbnail(assetPath, boxWidth, boxHeight) {
  return sharp(assetPath)
    .resize({
      width: boxWidth,
      height: boxHeight,
      fit: "contain",
      withoutEnlargement: true,
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();
}

async function build() {
  const composites = [];

  composites.push({
    input: textSvg(["STAGE 01 · 성 배경과 공간 연결 기준 보드"], {
      width,
      height: 78,
      x: 48,
      y: 45,
      size: 31,
      color: gold,
      weight: 800,
    }),
    left: 0,
    top: 0,
  });
  composites.push({
    input: textSvg(
      ["목표: 보이는 길과 실제 이동 셀을 일치시키고, 방을 모듈 섬이 아닌 하나의 성으로 읽히게 한다."],
      { width: 1824, height: 46, x: 48, y: 28, size: 17, color: muted, weight: 500 },
    ),
    left: 0,
    top: 66,
  });

  composites.push({ input: panelSvg(1214, 636), left: 36, top: 116 });
  composites.push({ input: panelSvg(626, 636), left: 1268, top: 116 });

  if (fs.existsSync(screenshotPath)) {
    const screenshot = sharp(screenshotPath);
    const metadata = await screenshot.metadata();
    const cropLeft = Math.min(230, Math.max(0, (metadata.width || 1830) - 1180));
    const cropTop = Math.min(34, Math.max(0, (metadata.height || 969) - 620));
    const cropWidth = Math.min(1190, (metadata.width || 1830) - cropLeft);
    const cropHeight = Math.min(620, (metadata.height || 969) - cropTop);
    const currentMap = await screenshot
      .extract({ left: cropLeft, top: cropTop, width: cropWidth, height: cropHeight })
      .resize({ width: 1180, height: 602, fit: "cover", position: "attention" })
      .png()
      .toBuffer();
    composites.push({ input: currentMap, left: 53, top: 133 });
  }

  composites.push({
    input: textSvg(
      [
        "현재 진단",
        "",
        "1. 런타임 기준은 한 장 배경이 아니라 셀 조립식 지도",
        "2. 논리 이동과 렌더 모두 같은 88개 복도 셀을 사용",
        "3. 문제는 연결 여부보다 접합부의 재질·명암 단절",
        "4. 황금 경로·문턱이 성 공간보다 UI 표시처럼 보임",
        "5. 왕좌만 픽셀 밀도가 달라 가장 큰 화풍 이탈",
        "",
        "불변 조건",
        "",
        "• 28×26 마스터 그리드 유지",
        "• 방 5×5 / 복도 2셀 폭 유지",
        "• 이동·충돌·AI·밸런스 데이터 변경 금지",
        "• Stage 01 시각 레이어만 수정",
      ],
      {
        width: 580,
        height: 590,
        x: 24,
        y: 34,
        size: 17,
        color: text,
        weight: 500,
        lineHeight: 31,
      },
    ),
    left: 1288,
    top: 136,
  });

  composites.push({
    input: textSvg(["Stage 01 현재 런타임 랜드마크 · 동일 크기 비교"], {
      width: 1180,
      height: 52,
      x: 0,
      y: 34,
      size: 23,
      color: text,
      weight: 700,
    }),
    left: 42,
    top: 778,
  });
  composites.push({
    input: textSvg(["초록: 유지", "적색: 우선 교체"], {
      width: 360,
      height: 44,
      x: 340,
      y: 28,
      size: 14,
      color: muted,
      weight: 500,
      align: "end",
    }),
    left: 834,
    top: 784,
  });

  const assets = [
    ["입구", "assets/props/stage_01/prop_entrance_gate_stage01_SE_back.png", "KEEP", success],
    ["병영", "assets/props/stage_01/prop_weapon_rack_stage01_SE_back.png", "KEEP", success],
    ["회복실", "assets/props/stage_01/prop_recovery_nest_stage01_NW_front.png", "KEEP", success],
    ["보물실", "assets/props/stage_01/prop_treasure_pile_stage01_NW_front.png", "KEEP", success],
    ["건설 슬롯", "assets/props/stage_01/prop_foundation_marks_stage01_NE_back.png", "KEEP", success],
    ["왕좌", "assets/props/stage_01/prop_throne_stage01_SW_back.png", "REPLACE", danger],
  ];
  const cardWidth = 372;
  const cardHeight = 402;
  const startX = 36;
  const startY = 832;
  for (let index = 0; index < assets.length; index += 1) {
    const [label, relativePath, status, statusColor] = assets[index];
    const col = index % 3;
    const row = Math.floor(index / 3);
    const left = startX + col * (cardWidth + 18);
    const top = startY + row * (cardHeight + 16);
    composites.push({ input: panelSvg(cardWidth, cardHeight, statusColor, panelSoft), left, top });
    const image = await thumbnail(path.join(projectRoot, relativePath), cardWidth - 34, 316);
    composites.push({ input: image, left: left + 17, top: top + 14 });
    composites.push({
      input: textSvg([label], {
        width: 220,
        height: 52,
        x: 0,
        y: 31,
        size: 18,
        color: text,
        weight: 700,
      }),
      left: left + 18,
      top: top + 336,
    });
    composites.push({
      input: textSvg([status], {
        width: 120,
        height: 52,
        x: 112,
        y: 31,
        size: 14,
        color: statusColor,
        weight: 800,
        align: "end",
      }),
      left: left + cardWidth - 140,
      top: top + 336,
    });
  }

  composites.push({ input: panelSvg(626, 882), left: 1268, top: 778 });
  composites.push({ input: routeSchematicSvg(586, 500), left: 1288, top: 802 });
  composites.push({
    input: textSvg(
      [
        "추천 제작 범위 · Option A",
        "",
        "1. 왕좌를 입구와 같은 회화형 밀도로 재제작",
        "2. N/E/S/W 2셀 문턱 transition 4종",
        "3. 직선·코너·교차 복도 표면을 저채도 석재로 통일",
        "4. 방/복도 높이와 폐색 그림자를 같은 규칙으로 고정",
        "5. 암벽·보라 안개 불규칙 가장자리 마스크 추가",
        "",
        "제외",
        "전체 배경 한 장 재제작 · 방 위치 변경 · collider 변경",
        "",
        "승인 후에만 실제 자산 생성·런타임 연결 진행",
      ],
      {
        width: 566,
        height: 330,
        x: 0,
        y: 30,
        size: 16,
        color: text,
        weight: 500,
        lineHeight: 25,
      },
    ),
    left: 1300,
    top: 1320,
  });

  await sharp({
    create: {
      width,
      height,
      channels: 4,
      background,
    },
  })
    .composite(composites)
    .png()
    .toFile(outputPath);

  process.stdout.write(`${outputPath}\n`);
}

await build();
