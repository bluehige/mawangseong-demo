# 1.2.11 final verification and Steam release handoff

This supersedes the private b0e0a79 candidate record for current work, without replacing historical reports or binaries. Product commit: `2786be4dff4fea5d21797f33311042e096f781c6`. Public 1.2.10 hotfix `515ed745d4ce731f7bafb31ee1f9381470794d72` remains an ancestor. Remote main was freshly read as `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b` on 2026-10-11.

The user explicitly approved public 1.2.11 Steam deployment, including the promoted reply-image correction. Implementation, upload, default activation and actual server verification must be reported separately. New authentication, credentials or account-security changes are not authorized. The parent owns the logged-in Steamworks browser; avoid duplicate web uploads.

## Completed changes

- Earlier private candidate: caption continuity/important story delivery, safe five-version checkpoint controls, common menu, session dialogue backlog, offline version notes, speed preference and promotion contribution visibility. See previous dated handoffs for details.
- Countdown freezes inside the menu. Modal keyboard input remains usable and focus stays inside the visible modal. Failed acknowledgement persistence no longer traps the user; the next session may show the notes again. Screen transitions clear discarded update-modal input state.
- Actual reply portraits now follow existing six promotion branches and six active crown forms, using the same crown selection and suppression as combat. Current-form neutral art handles emotions lacking a dedicated variant. Existing evolution/crown art fits the frame without side cropping. No replacement assets were generated; all 24 promotion and 24 crown portrait/variant/combat paths exist.
- The interactive map-editor panel consumes its empty surface so it cannot initiate world dragging underneath. Touch assertions use live canvas geometry.
- Regression fixtures now use 1.2.11/assigned Steam IDs, acknowledge the actual startup note, and explicitly fix balance measurement to x1 while gameplay retains the user's speed preference. Unlock days, base attack, enemy count and waves were not changed.

## Evidence and honest scope

Evidence paths are relative to the parent task workspace, outside this repository. Counts are assertions, not unique scenario totals.

| Verification | Result | Evidence |
|---|---|---|
| First completed full catalog, commit34d6f0e | FAIL: 156/162 pass, six failures retained | evidence/v1211-full-core-first-complete.json/.md |
| Exact final product full catalog2786be4 | RUNNING at this record; never infer success | evidence/v1211-full-final-runner.log |
| Promoted reply GUI, actual catalog replies, six branches, six crowns, emotion fallback/suppression and six save/Continue round trips | PASS373 / 0 failures | evidence/v1211-portrait-catalog-gui.log; tmp/promotion_portraits/catalog_*.png |
| Final shared menu/backlog/notes/save failure GUI | PASS89 / 0 failures | evidence/v1211-continuity-after-portrait.log |
| All authored story scenes forced render/consume/backlog hold | PASS1082, 216 scenes / 1622 cues | evidence/v1211-all-story-after-portrait.log |
| Actual six-branch upgraded skill execution and contribution | PASS35 | evidence/v1211-promotion-functional.log/.json |
| Balance fixtures with explicit x1 | PASS eight assertion groups | evidence/v1211-balance-x1-recheck.log |
| Touch GUI/map-editor integration | PASS80 | evidence/v1211-mobile-final.log |
| Readiness/current version/assigned IDs | PASS85 | evidence/v1211-readiness-recheck.log |
| Command button/input regression | PASS | evidence/v1211-command-recheck.log |
| Actual first-play EN input | PASS33 | evidence/v1211-firstplay-recheck.log |
| BGM isolated rerun | PASS77; first full run had one Stage04 one-frame failure | evidence/v1211-bgm-recheck.log |
| Steam compiled PCK menu/notes/six promotion textures/six crown assets | PASS44 | evidence/v1211-steam-pack-smoke.log |
| Independent read-only final portrait/editor review | No concrete P1/P2; no runtime/customer-data access | Parent task continuity_review messages |

The initial six failures were audio timing, obsolete readiness expectations, discarded update-modal state affecting command/first-play input, map-editor pointer blocking and x3 balance measurement. The original report remains FAIL even after individual corrected reruns. A fresh complete final run is in progress.

Forced story branch facts and hand-authored balance/skill rosters do not prove a legally earned continuous DAY1–30 campaign or human fun/balance quality. Continuous earned playthrough and human promotion evaluation remain NOT_RUN. Synthetic portrait fixture initialization errors and an incorrect touch launcher flag are retained in earlier logs; final named/seeded fixtures and correct flags pass.

## Release and Cloud status

Final Steam preset export from the clean product commit succeeded using Godot4.6.3 official7d41c59c4. Candidate content: evidence/v1211-steam-release-candidate, six files with the existing executable names and three legal notices plus provenance. FileVersion/ProductVersion1.2.11.0. The earlier b0e0a79 ZIP is immutable historical evidence.

UPLOAD: NOT_RUN. DEFAULT1.2.11: NOT_RUN. Existing authenticated SteamCMD/SDK was not found through the command/project-owned locations checked; recent releases used Steamworks Web Uploads. The parent browser must receive the final ZIP, compare the six server file sizes/SHA1 and testable build, activate exactly that BuildID on default, then reload canonical Builds and confirm actual BuildID/version. Current rollback baseline observed by the parent is Build25808943 / Manifest7359545829337152740 (1.2.10). Do not repeat authentication or ask the sleeping user for action.

Parent browser separately confirmed Auto-Cloud six exact nonrecursive Windows files published/developer-only0. Store Cloud-supported feature remains unchecked pending actual verification. Real Steam client two-PC A→B/B→A, offline/conflict behavior remains NOT_RUN. No RemoteStorage SDK, save schema/path or new slot system was introduced. `%APPDATA%\Godot\app_userdata\마왕님, 마왕성 지켜주세요! Demo` remains pinned; v1–v5 are versions of one campaign and must stay coherent. See the earlier Auto-Cloud handoff for a disposable-account two-PC procedure.

Customer userdata was backed up before implementation; 698 hashes passed preservation before this final follow-up. All new tests use isolated APPDATA and synthetic progress. Original user checkout/worktrees remain untouched. Final preservation, artifact hashes, tag/integration and publication status will be recorded after completion. No unrelated project was touched.
