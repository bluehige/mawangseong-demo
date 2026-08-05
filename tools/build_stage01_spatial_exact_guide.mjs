import fs from "node:fs";
import path from "node:path";
import { createRequire } from "node:module";
import { fileURLToPath } from "node:url";

const require = createRequire(import.meta.url);
const sharp = require("sharp");

const scriptDir = path.dirname(fileURLToPath(import.meta.url));
const projectRoot = path.resolve(scriptDir, "..");
const guidePath = path.join(
  projectRoot,
  "docs/design/v122/guides/stage01_spatial_exact_guide.json",
);
const outputDir =
  process.argv[2] || "C:\\tmp\\v122_stage01_spatial_exact_guides_2026-07-29";

const C = {
  void: "#07060B",
  surface: "#100E16",
  panel: "#17141E",
  line: "#4B4355",
  grid: "#8F849A",
  text: "#F1E9DC",
  muted: "#A9A0B2",
  gold: "#F0C85B",
  purple: "#8C6AB0",
  corridor: "#506779",
  room: "#60496F",
  danger: "#B65A59",
  success: "#62A884",
};

function readJson(relativePath) {
  return JSON.parse(fs.readFileSync(path.join(projectRoot, relativePath), "utf8"));
}

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

function assert(condition, message) {
  if (!condition) throw new Error(message);
}

function assertClose(actual, expected, message, epsilon = 0.00001) {
  assert(Math.abs(actual - expected) <= epsilon, `${message}: ${actual} != ${expected}`);
}

function assertPoint(actual, expected, message) {
  assert(actual.length === 2 && expected.length === 2, `${message}: invalid point`);
  assertClose(actual[0], expected[0], `${message}.x`);
  assertClose(actual[1], expected[1], `${message}.y`);
}

function sameCell(a, b) {
  return a[0] === b[0] && a[1] === b[1];
}

function cellCenter(cell, projection) {
  return [
    (cell[0] - cell[1]) * projection.half_tile[0],
    (cell[0] + cell[1]) * projection.half_tile[1],
  ];
}

function cellDiamond(cell, projection) {
  const center = cellCenter(cell, projection);
  return projection.cell_diamond_relative_vertices.map((point) => [
    center[0] + point[0],
    center[1] + point[1],
  ]);
}

function edgePoints(cell, side, projection) {
  const diamond = cellDiamond(cell, projection);
  const indices = {
    N: [0, 1],
    E: [1, 2],
    S: [2, 3],
    W: [3, 0],
  }[side];
  assert(indices, `unsupported side ${side}`);
  return [diamond[indices[0]], diamond[indices[1]]];
}

function cellsForGrid(width, height) {
  const result = [];
  for (let y = 0; y < height; y += 1) {
    for (let x = 0; x < width; x += 1) result.push([x, y]);
  }
  return result;
}

function boundsForCells(cells, projection) {
  const points = cells.flatMap((cell) => cellDiamond(cell, projection));
  const xs = points.map((point) => point[0]);
  const ys = points.map((point) => point[1]);
  const minX = Math.min(...xs);
  const minY = Math.min(...ys);
  const maxX = Math.max(...xs);
  const maxY = Math.max(...ys);
  return [minX, minY, maxX - minX, maxY - minY];
}

function toCanvas(point, canvas) {
  return [
    canvas.iso_origin[0] + point[0] * canvas.guide_scale,
    canvas.iso_origin[1] + point[1] * canvas.guide_scale,
  ];
}

function pointsAttr(points) {
  return points.map((point) => `${point[0]},${point[1]}`).join(" ");
}

function chainEdges(cells, side, projection) {
  const edges = cells.map((cell) => edgePoints(cell, side, projection));
  const keys = (point) => `${point[0]},${point[1]}`;
  const adjacency = new Map();
  for (const [a, b] of edges) {
    if (!adjacency.has(keys(a))) adjacency.set(keys(a), []);
    if (!adjacency.has(keys(b))) adjacency.set(keys(b), []);
    adjacency.get(keys(a)).push(b);
    adjacency.get(keys(b)).push(a);
  }
  const endpointKey = [...adjacency.keys()].find((key) => adjacency.get(key).length === 1);
  assert(endpointKey, `cannot chain ${side} edges`);
  const result = [endpointKey.split(",").map(Number)];
  let previous = "";
  let current = endpointKey;
  while (true) {
    const next = adjacency
      .get(current)
      .map(keys)
      .find((candidate) => candidate !== previous);
    if (!next) break;
    result.push(next.split(",").map(Number));
    previous = current;
    current = next;
  }
  return result;
}

function polylineEquivalent(actual, expected) {
  if (actual.length !== expected.length) return false;
  const forward = actual.every((point, index) => sameCell(point, expected[index]));
  const reverse = actual.every((point, index) =>
    sameCell(point, expected[expected.length - 1 - index]),
  );
  return forward || reverse;
}

function pairAdjacentCells(roomCells, corridorCells, projection) {
  return roomCells.map((roomCell) => {
    const roomCenter = cellCenter(roomCell, projection);
    const sorted = corridorCells
      .map((corridorCell) => {
        const corridorCenter = cellCenter(corridorCell, projection);
        return {
          corridorCell,
          distance:
            (roomCenter[0] - corridorCenter[0]) ** 2 +
            (roomCenter[1] - corridorCenter[1]) ** 2,
        };
      })
      .sort((a, b) => a.distance - b.distance);
    return [roomCell, sorted[0].corridorCell];
  });
}

function validateGuide(guide, layout, blueprints, gradeRules) {
  assert(
    layout.template_id === guide.layout_template_id,
    `layout id drift: ${layout.template_id}`,
  );
  assert(
    JSON.stringify(layout.tile_size) === JSON.stringify(guide.projection.tile_size),
    "layout tile size drift",
  );

  const thronePlaced = layout.placed_modules.find(
    (entry) => entry.instance_id === guide.runtime_alignment.throne_instance_id,
  );
  const pathPlaced = layout.placed_modules.find(
    (entry) => entry.instance_id === guide.runtime_alignment.throne_path_instance_id,
  );
  assert(thronePlaced, "throne instance missing");
  assert(pathPlaced, "throne path instance missing");
  assert(
    thronePlaced.module_id === guide.runtime_alignment.throne_module_id,
    "throne module drift",
  );
  assert(
    pathPlaced.module_id === guide.runtime_alignment.throne_path_module_id,
    "throne path module drift",
  );
  assert(
    sameCell(thronePlaced.grid_origin, guide.runtime_alignment.throne_grid_origin),
    "throne origin drift",
  );
  assert(
    sameCell(pathPlaced.grid_origin, guide.runtime_alignment.throne_path_grid_origin),
    "throne path origin drift",
  );

  const throneModule = blueprints[thronePlaced.module_id];
  assert(throneModule, "throne blueprint missing");
  assert(
    sameCell(throneModule.footprint, guide.throne.room_grid_size),
    "throne footprint drift",
  );
  const throneSlot = throneModule.object_slots.find(
    (entry) => entry.id === guide.throne.object_id,
  );
  assert(throneSlot, "throne object slot missing");
  assert(throneSlot.facing === guide.throne.facing, "throne facing drift");
  assert(
    sameCell(throneSlot.cell, guide.throne.object_anchor_cell),
    "throne anchor drift",
  );

  const socketCells = guide.throne.paired_socket_ids.map((socketId) => {
    const socket = throneModule.sockets.find((entry) => entry.id === socketId);
    assert(socket, `missing throne socket ${socketId}`);
    assert(socket.side === "S", `throne socket ${socketId} is not S`);
    return socket.cell;
  });
  assert(
    socketCells.every((cell, index) => sameCell(cell, guide.throne.paired_socket_cells[index])),
    "throne paired socket cells drift",
  );
  for (const pair of guide.runtime_alignment.throne_connection_pairs) {
    assert(
      layout.connections.some(
        (connection) => connection.from === pair.from && connection.to === pair.to,
      ),
      `missing throne connection ${pair.from} -> ${pair.to}`,
    );
  }

  const footprintBounds = boundsForCells(cellsForGrid(5, 5), guide.projection);
  footprintBounds.forEach((value, index) =>
    assertClose(value, guide.throne.native_footprint_bounds[index], "throne bounds"),
  );
  const throneSeam = chainEdges(
    guide.throne.paired_socket_cells,
    "S",
    guide.projection,
  );
  assert(
    polylineEquivalent(throneSeam, guide.throne.native_socket_edge_polyline),
    "throne socket edge polyline drift",
  );

  const patchBounds = boundsForCells(cellsForGrid(2, 2), guide.projection);
  patchBounds.forEach((value, index) =>
    assertClose(value, guide.thresholds.native_patch_bounds[index], "threshold bounds"),
  );
  for (const [side, variant] of Object.entries(guide.thresholds.variants)) {
    const seam = chainEdges(variant.room_cells, variant.room_side, guide.projection);
    assert(
      polylineEquivalent(seam, variant.native_seam_polyline),
      `${side} threshold seam drift`,
    );
  }

  const activeGrid = gradeRules.grades[layout.castle_grade].active_rect.slice(2);
  assert(
    sameCell(activeGrid, guide.non_authoring_runtime_reference.stage01_active_grid),
    "Stage 01 active grid drift",
  );
  const [tileW, tileH] = guide.projection.tile_size;
  const rawWidth = (activeGrid[0] + activeGrid[1]) * tileW * 0.5;
  const rawHeight = (activeGrid[0] + activeGrid[1]) * tileH * 0.5;
  const frame = guide.non_authoring_runtime_reference.quarter_view_frame;
  const visualScale = Math.max(
    0.42,
    Math.min(1.9, Math.min(frame[2] / rawWidth, frame[3] / rawHeight)),
  );
  assertClose(
    visualScale,
    guide.non_authoring_runtime_reference.current_visual_scale,
    "runtime reference scale",
  );
}

function throneGuideSvg(guide) {
  const canvas = guide.throne.authoring_canvas;
  const [width, height] = canvas.size;
  const cellPolygons = cellsForGrid(5, 5)
    .map((cell) => {
      const points = cellDiamond(cell, guide.projection).map((point) =>
        toCanvas(point, canvas),
      );
      const selected = guide.throne.paired_socket_cells.some((socketCell) =>
        sameCell(cell, socketCell),
      );
      return `<polygon points="${pointsAttr(points)}" fill="${
        selected ? "#F0C85B38" : "#8C6AB01A"
      }" stroke="${selected ? C.gold : C.grid}" stroke-width="${
        selected ? 4 : 1.5
      }"/>`;
    })
    .join("");
  const vertices = guide.throne.native_footprint_vertices.map((point) =>
    toCanvas(point, canvas),
  );
  const seam = guide.throne.native_socket_edge_polyline.map((point) =>
    toCanvas(point, canvas),
  );
  const anchor = toCanvas(cellCenter(guide.throne.object_anchor_cell, guide.projection), canvas);
  const arrowEnd = [anchor[0] - 180, anchor[1] + 90];
  const [top, right, bottom, left] = vertices;

  return svg(
    width,
    height,
    `<defs>
       <marker id="arrow" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto">
         <path d="M0,0 L12,6 L0,12 z" fill="${C.purple}"/>
       </marker>
     </defs>
     ${cellPolygons}
     <polyline points="${pointsAttr([top, right, bottom])}" fill="none" stroke="${C.room}" stroke-width="12" stroke-linecap="round"/>
     <polyline points="${pointsAttr([left, top])}" fill="none" stroke="${C.room}" stroke-width="12" stroke-linecap="round"/>
     <line x1="${bottom[0]}" y1="${bottom[1]}" x2="${seam[2][0]}" y2="${seam[2][1]}" stroke="${C.room}" stroke-width="12" stroke-linecap="round"/>
     <line x1="${seam[0][0]}" y1="${seam[0][1]}" x2="${left[0]}" y2="${left[1]}" stroke="${C.room}" stroke-width="12" stroke-linecap="round"/>
     <polyline points="${pointsAttr(seam)}" fill="none" stroke="#100C0E" stroke-width="30" stroke-linecap="round" stroke-linejoin="round"/>
     <polyline points="${pointsAttr(seam)}" fill="none" stroke="${C.gold}" stroke-width="10" stroke-linecap="round" stroke-linejoin="round"/>
     <circle cx="${anchor[0]}" cy="${anchor[1]}" r="14" fill="${C.void}" stroke="${C.purple}" stroke-width="5"/>
     <line x1="${anchor[0]}" y1="${anchor[1]}" x2="${arrowEnd[0]}" y2="${arrowEnd[1]}" stroke="${C.purple}" stroke-width="8" marker-end="url(#arrow)"/>
     <rect x="32" y="32" width="960" height="952" fill="none" stroke="#F1E9DC55" stroke-width="2" stroke-dasharray="12 10"/>`,
  );
}

function thresholdGuideSvg(guide, side) {
  const variant = guide.thresholds.variants[side];
  const canvas = guide.thresholds.authoring_canvas;
  const [width, height] = canvas.size;
  const allCells = cellsForGrid(2, 2);
  const cellPolygons = allCells
    .map((cell) => {
      const points = cellDiamond(cell, guide.projection).map((point) =>
        toCanvas(point, canvas),
      );
      const isRoom = variant.room_cells.some((roomCell) => sameCell(roomCell, cell));
      return `<polygon points="${pointsAttr(points)}" fill="${
        isRoom ? "#8C6AB060" : "#50677970"
      }" stroke="${C.grid}" stroke-width="4"/>`;
    })
    .join("");
  const seam = variant.native_seam_polyline.map((point) => toCanvas(point, canvas));
  const pairs = pairAdjacentCells(
    variant.room_cells,
    variant.corridor_cells,
    guide.projection,
  );
  const bridges = pairs
    .map(([roomCell, corridorCell]) => {
      const start = toCanvas(cellCenter(roomCell, guide.projection), canvas);
      const end = toCanvas(cellCenter(corridorCell, guide.projection), canvas);
      return `<line x1="${start[0]}" y1="${start[1]}" x2="${end[0]}" y2="${end[1]}" stroke="#F1E9DC55" stroke-width="5" stroke-dasharray="12 10"/>`;
    })
    .join("");
  const center = toCanvas([0, 32], canvas);
  const vector = variant.native_outward_vector;
  const length = Math.hypot(vector[0], vector[1]);
  const arrowEnd = [
    center[0] + (vector[0] / length) * 180,
    center[1] + (vector[1] / length) * 180,
  ];

  return svg(
    width,
    height,
    `<defs>
       <marker id="arrow" markerWidth="12" markerHeight="12" refX="10" refY="6" orient="auto">
         <path d="M0,0 L12,6 L0,12 z" fill="${C.gold}"/>
       </marker>
     </defs>
     ${cellPolygons}
     ${bridges}
     <polyline points="${pointsAttr(seam)}" fill="none" stroke="#100C0E" stroke-width="34" stroke-linecap="round" stroke-linejoin="round"/>
     <polyline points="${pointsAttr(seam)}" fill="none" stroke="${C.gold}" stroke-width="12" stroke-linecap="round" stroke-linejoin="round"/>
     <line x1="${center[0]}" y1="${center[1]}" x2="${arrowEnd[0]}" y2="${arrowEnd[1]}" stroke="${C.gold}" stroke-width="8" marker-end="url(#arrow)"/>
     <rect x="96" y="224" width="832" height="576" fill="none" stroke="#F1E9DC55" stroke-width="2" stroke-dasharray="12 10"/>`,
  );
}

function multilineText(lines, x, y, options = {}) {
  const {
    size = 24,
    weight = 500,
    color = C.text,
    lineHeight = Math.round(size * 1.5),
    anchor = "start",
  } = options;
  return `<text x="${x}" y="${y}" fill="${color}" font-family="Malgun Gothic, Noto Sans CJK KR, sans-serif" font-size="${size}" font-weight="${weight}" text-anchor="${anchor}">${lines
    .map(
      (line, index) =>
        `<tspan x="${x}" dy="${index === 0 ? 0 : lineHeight}">${esc(line)}</tspan>`,
    )
    .join("")}</text>`;
}

async function resizedPng(filePath, width, height) {
  return sharp(filePath)
    .resize({
      width,
      height,
      fit: "contain",
      background: { r: 0, g: 0, b: 0, alpha: 0 },
    })
    .png()
    .toBuffer();
}

async function buildBoard(guide, files) {
  const W = 2400;
  const H = 2200;
  const layers = [
    {
      input: svg(
        W,
        H,
        `<rect width="${W}" height="${H}" fill="${C.void}"/>
         <rect x="36" y="36" width="2328" height="2128" rx="20" fill="${C.surface}" stroke="${C.line}" stroke-width="2"/>
         ${multilineText(["STAGE 01 · EXACT PROJECTION GUIDE", "왕좌 5×5 · N/E/S/W 2셀 문턱"], 78, 102, { size: 34, weight: 900, lineHeight: 48 })}
         ${multilineText(["런타임 좌표에서 직접 추출 · 런타임 자산/코드 미변경"], 2320, 114, { size: 18, color: C.muted, anchor: "end" })}
         <line x1="78" y1="184" x2="2322" y2="184" stroke="${C.line}" stroke-width="2"/>
         <rect x="78" y="226" width="1040" height="918" rx="14" fill="${C.panel}" stroke="${C.line}"/>
         <rect x="1142" y="226" width="1180" height="918" rx="14" fill="${C.panel}" stroke="${C.line}"/>
         ${multilineText(["01  왕좌 제작 기준"], 106, 274, { size: 25, weight: 800, color: C.gold })}
         ${multilineText(["좌표 계약", "", "• 셀 128×64 · half 64×32", "• 5×5 투영면 640×320", "• 원본 guide 1024×1024", "• 원본 바닥 다이아몬드 960×480", "• 오브젝트 anchor [2,2]", "", "입구 계약", "", "• facing SW", "• open_mask 04 · S만 개방", "• socket [2,4] + [3,4]", "• 남쪽 개구부만 황금 seam", "• N/E/W는 막힌 암벽", "", "제작 금지", "", "• 화면 scale 0.42를 원본에 bake 금지", "• 5×5 밖의 가짜 보행 바닥 금지", "• 정면 직사각형/픽셀아트 왕좌 금지"], 1190, 294, { size: 23, lineHeight: 38 })}
         <line x1="78" y1="1192" x2="2322" y2="1192" stroke="${C.line}" stroke-width="2"/>
         ${multilineText(["02  4방향 문턱 제작 기준"], 78, 1244, { size: 25, weight: 800, color: C.gold })}
         ${multilineText(["보라 = 방 · 청회 = 복도 · 황금 = 정확한 2셀 seam · 화살표 = 방 밖 방향"], 2322, 1244, { size: 17, color: C.muted, anchor: "end" })}
         <rect x="78" y="1284" width="548" height="646" rx="12" fill="${C.panel}" stroke="${C.line}"/>
         <rect x="644" y="1284" width="548" height="646" rx="12" fill="${C.panel}" stroke="${C.line}"/>
         <rect x="1210" y="1284" width="548" height="646" rx="12" fill="${C.panel}" stroke="${C.line}"/>
         <rect x="1776" y="1284" width="546" height="646" rx="12" fill="${C.panel}" stroke="${C.line}"/>
         <rect x="78" y="1974" width="2244" height="138" rx="10" fill="#17120B" stroke="${C.gold}" stroke-width="2"/>
         ${multilineText(["고정 수치", "2×2 patch 256×128 · socket 1칸 edge 71.554 · 2칸 opening 143.108 · N/W back · E/S front"], 106, 2022, { size: 20, weight: 800, lineHeight: 34 })}
         ${multilineText(["NEXT  이 guide를 입력 기준으로 왕좌 → 문턱 4종 → 저채도 복도 표면 순서로 생성"], 106, 2088, { size: 18, color: C.muted })}`,
      ),
      left: 0,
      top: 0,
    },
    {
      input: await resizedPng(files.throne, 820, 820),
      left: 188,
      top: 302,
    },
  ];

  const thresholdX = [108, 674, 1240, 1806];
  for (let index = 0; index < files.thresholds.length; index += 1) {
    const entry = files.thresholds[index];
    const variant = guide.thresholds.variants[entry.side];
    layers.push({
      input: await resizedPng(entry.path, 488, 488),
      left: thresholdX[index],
      top: 1338,
    });
    layers.push({
      input: svg(
        488,
        90,
        `${multilineText(
          [`${entry.side} · ${variant.render_layer.toUpperCase()} LAYER`, `room ${variant.room_side} ↔ corridor ${variant.corridor_side}`],
          244,
          30,
          { size: 18, weight: 800, lineHeight: 28, anchor: "middle" },
        )}`,
      ),
      left: thresholdX[index],
      top: 1822,
    });
  }

  await sharp({
    create: { width: W, height: H, channels: 4, background: C.void },
  })
    .composite(layers)
    .png()
    .toFile(files.board);
}

async function main() {
  const guide = JSON.parse(fs.readFileSync(guidePath, "utf8"));
  const layout = readJson("data/dungeon_quarter/layouts/stage01_dual_front_01.json");
  const roomBlueprints = readJson("data/dungeon_quarter/room_blueprints.json");
  const dualBlueprints = readJson("data/dungeon_quarter/dual_front_blueprints.json");
  const gradeRules = readJson("data/dungeon_quarter/castle_grade_rules.json");
  const blueprints = { ...roomBlueprints, ...dualBlueprints };

  validateGuide(guide, layout, blueprints, gradeRules);
  fs.mkdirSync(outputDir, { recursive: true });

  const files = {
    throne: path.join(outputDir, "v122_stage01_throne_5x5_exact_guide.png"),
    thresholds: [],
    board: path.join(outputDir, "v122_stage01_spatial_exact_guide_board_2026-07-29.png"),
  };

  await sharp(throneGuideSvg(guide)).png().toFile(files.throne);
  for (const side of ["N", "E", "S", "W"]) {
    const filePath = path.join(
      outputDir,
      `v122_stage01_threshold_${side}_2cell_exact_guide.png`,
    );
    await sharp(thresholdGuideSvg(guide, side)).png().toFile(filePath);
    files.thresholds.push({ side, path: filePath });
  }
  await buildBoard(guide, files);

  const summary = {
    contract_id: guide.contract_id,
    output_dir: outputDir,
    board: files.board,
    throne: files.throne,
    thresholds: Object.fromEntries(files.thresholds.map((entry) => [entry.side, entry.path])),
    assertions: "PASS",
  };
  process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`);
}

await main();
