# Native contract profile verification and old assertion resolution

2026-10-12 UTC. Branch `codex/combat-presentation-prototype`.
Test-only source SHA: `cd8aea76d356a4986f69d544e04f37a1003ca43e`.
Product code/assets remain the verified4f425f0 implementation. Existing development ZIP/EXE/PCK and original17 screenshots were preserved; no rebuild/version selection/Steam publish/push/merge was performed.

The parent requested actual current resource/progression/GUI verification before changing the four inherited assertions. The actual GUI was verified first; only then were the obsolete test expectations updated.

## Findings

Both spider_tailor (실키 / 거미 재단사) and bat_courier (포포 / 박쥐 배달부) intentionally render their own384px logical native RGBA atlas in `assets/sprites/uiux3d/`. Their old update4 sheet paths are registered `legacy_runtime_path` aliases. Exact current and legacy inputs resolve to the same species-specific native profile. Current texture/packing data contain complete idle/down2 and move/attack/skill4 frame sets, visible alpha content and the registered scales. No product art/profile/logic defect was found in these checks.

In the actual map, sprite materials are the existing `prepared_maze_actor_depth.gdshader` for wall occlusion. Requiring `material == null` for a full GameRoot actor would be incorrect; the test confirms the expected depth shader and `chroma_key=false`. Standalone Unit contract tests still require no chroma material. The two actors were visually inspected in the GUI, with separated positions, plausible physical size, visible native body and correct own art. Actualx1/x3 child animation playback advances.

Neither monster has an ordinary evolution-rule branch. Each has two tactical specializations. The GUI fixture calls the real specialization choice handlers for silky_stair_warden and popo_royal_express and confirms their own behavior handlers. Existing service regressions cover their tactical effects. There is no spider crown in the current catalog. Popo's supported DAY23 crown is crown_popo_grand_night_courier: the actual confirmation handler consumes the existing two-seal cost, updates the active run, selects its own crown atlas/complete frames and current crown portrait. Crown suppression restores the current base atlas/portrait. No new promotion or balance behavior was invented.

## Corrected assertions

`V122CombatVisualRuntimeProfileContractTest.gd` now tests the two migrated native actors separately: own profile key, exact native and old alias paths, equal alias resolution, explicit native state, actual own sprite/no chroma, scale, alpha and all16 native frame contracts. Only those two entries were removed from `preserved_unprofiled_forms`. Its safeguards for other promoted/crown forms and unknown species remain intact.

New `NativeContractProfileGUIReviewTest.gd/.tscn/.uid` exercises actual GameRoot actors, GUI/cutins, specialization selection and supported crown activation/suppression using isolated synthetic saves. It writes to a new screenshot directory, never over the earlier17 review images.

## Direct checks

| Check | Final result | Evidence under task `../evidence/` |
| --- | --- | --- |
| Corrected visual profile contract | PASS; old4 failures resolved | `native-profile-contract-recheck.log` |
| Actual native actor/progression/crown GUI | PASS140,0 failures | `native-contract-profile-gui-final2.log` |
| Silky service / Popo service | PASS24 /20 | `native-profile-SilkyCombatPhase13Test.log`, `native-profile-PopoCombatPhase15Test.log` |
| Crown contract behavior | PASS29 | `native-profile-CrownContractMonstersPhase28Test.log` |
| Current native art/portraits/bond/VFX/SFX presentation | PASS37 | `native-profile-presentation-regression.log` |
| Actual preserved PCK duo impact capture | PASS10,0 failures | `duo-impact-packed-capture.log` |

New actual GUI screenshots: `native-contract-profile-final-screenshots/`,9 PNGs: base idle/move/attack/skill/down; base Silky/Popo cutins; crowned/suppressed Popo. Pixels of the actual base and crown GUI were inspected. Existing37-check presentation regression's CPU-composed context fixtures are not claimed as game screenshots.

Earlier FAIL logs remain preserved. The first GUI fixture incorrectly required null material in the map and was corrected only after identifying the expected wall-depth shader with chroma disabled. A new test string-inference parse error was repaired with explicit String types; the final contract is error-free. The exact owned hung parse-error process was verified by executable/scene command and stopped; other apps/processes were untouched.

## Requested actual duo still

`../evidence/Duo-Molten-Carapace-Actual-Impact-0120ms.png` is a byte-identical selected viewport frame from the verified development PCK. It shows **용융 갑각포**, **핀+톡톡**, at **0.119902s after actual activation**,x1,1920x1080. The synthetic DAY18 fixture prepares gauge100, while the actual activation handler consumes the use and damages three real enemies1000→974. No image synthesis/compositing/editing was used. Capture report and fixture: `DUO_IMPACT_STILL_REVIEW_20261012.md`, `DuoImpactPackedCapture.gd` and isolated `duo_impact_review_20261012/.../captures/capture-report.json`.

The round badge hides casters/impact area and the two-member action is hard to read. Proposal only: brief shared initiation, move the badge away from the target, then synchronize a directional impact with actual damage. Inspect the bright pink fringe in the current impact palette. No new visual enhancement was implemented for the still. Library attachment's existing prepare-unavailable failure was not retried or bypassed. The absolute local PNG path is provided for authorized Naver Mail delivery by the parent; no mail was sent here.

## Preservation / runnable artifact

`native-profile-preservation-final.json` reconfirms original698 personal save hashes unchanged; public ZIP SHA25639b60ff2…, private ZIP8519eed3… and private PCKf07427c0… unchanged. All new runtime tests use isolated process-local APPDATA. The original17 PNG directory remains intact. Import-generated metadata was restored in the isolated clone.

Run the unchanged verified `C:\Users\blueh\Documents\Codex\2026-10-11\task-2\evidence\combat-presentation-development-build\LaunchPrototype.ps1` in PowerShell. Its sibling EXE is the latest verified product execution artifact and the launcher keeps review progress separate from personal saves. The earlier packaged README's four-failure note is superseded by this test-only verification; the immutable package itself was preserved.

Concurrent unrelated `AGENTS.md` and `README.md` edits adding dev-work-hub instructions appeared at04:02:25UTC. They were read and preserved, not staged or reverted by this task. They are not part of the reviewed product/test SHA. No central-hub command or new outside-workspace workflow was executed. This checkout therefore may retain those unrelated uncommitted changes after our explicit commits.

Whole regression/independent review/full campaign/human feel/low-end/actual Steam install/two-PC Cloud remain NOT_RUN or NOT_REQUESTED. This resolves the four specific inherited assertions, not every possible product defect.

Review task ID: NOT_REQUESTED
Remaining P1/P2: NOT_ASSESSED_BY_INDEPENDENT_REVIEW; no unresolved failures in these direct checks.
Final review result: TARGETED_PASS
Reviewed SHA: cd8aea76d356a4986f69d544e04f37a1003ca43e
