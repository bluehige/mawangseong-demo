# 1.2.10 continuity implementation — private development review

## 1. Metadata / recovery point

- Date: 2026-10-11, DK Windows, Godot 4.6.3 official 7d41c59c4.
- Product: Who Guards the Demon Castle? / bluehige/mawangseong-demo / Steam app5267750.
- Workspace: `C:\Users\blueh\Documents\Codex\2026-10-11\task-2\mawangseong`.
- Branch: `codex/v1210-safety-dialogue-review`.
- Base: latest clean local player-feedback branch `b88252e9eb8081a9456a5f8feb1cc97c14266aae` (product ancestor 515ed745d4ce731f7bafb31ee1f9381470794d72).
- Product commit: `386f29dafe3f39c2f9020c6081c940531ac08de1`.
- Remote main fetched/read: `0ac9fdc7f1a5f3d2e8cc23ca2ec771873094c53b`; local historical main b06be967 is older. No merge, push, tag, PR, upload or publish performed.
- Installed version remains 1.2.10. Private update acknowledgement ID: 1.2.10-continuity-20261011. This is a review build, not a new public release.
- Original desktop repository remains on codex/v125-release-candidate@e6ae83d with its existing modifications. The newer uiux_v2 handoff edit and untracked handoff.txt were preserved. Source clones/worktrees were not reset or edited.

## 2. Authorized scope and outcome

User approved subtitles/checkpoint safety/menu/Cloud verification, then backlog/update notes, then promotion visibility and remembered speed. Implementation and development builds are complete for the items below. Current Steamworks reading and two-PC Cloud sync remain NOT_RUN; balance adoption remains a separate playtest decision.

## 3. Completed behavior and cause

- Caption causes: CombatStoryFeed previously cleared on a settings excursion; it also discarded an already displayed scene after 12 simulated seconds, before real reading time elapsed at x3. Settings now retains the reader/queue, and visible scenes finish reading. Pending ordinary reactions retain priority replacement, maximum four entries and 12-second expiry.
- Four authored important scenes (DAY12, DAY23, DAY30 Leon and oath) now use the retained blocking reader instead of the disposable feed. No story text or IDs changed. Blocking pauses restore the previous combat pause state.
- Common screen button / ESC menu exposes Resume, Save, Load, Settings, Title, Quit. Settings links back to these controls after cancelling unapplied settings. Story progression freezes under menus, settings and the backlog. Window-close requests use the same loss confirmation.
- Single campaign checkpoint displays DAY, checkpoint and local save time. Combat saving explicitly refuses to write and explains restoring the pre-battle checkpoint. No multi-slot or mid-battle save was added.
- All enabled campaign format versions are snapshotted before a save. Recoverable v1–v5 write failures restore the complete previous primary-file set; v5 is still written last and loaded first. A successfully recovered checkpoint remains available. Save-and-title / save-and-quit stop after a failed write. Cancel restores prior pause state; title/continue repeats restore without duplicate resources. Leaving combat for title does not mark a council battle complete.
- Read-only session backlog records displayed cues and speaker/day/text; opening it suspends auto/manual progression, closing it resumes the previous auto choice with fresh reading time. Reading does not rerun scene choices or reward actions. It is separate from scene/archive replay and is not persisted across application restarts.
- Offline update notes contain four implemented changes; acknowledgement persists in settings.cfg, does not repeat, and Title can reopen them. Actual installed version is displayed. Korean, English and Chinese new surfaces were inspected.
- Existing promotion skill/appearance/VFX/AI were retained. Ambush Captain explanation states the existing Quick Slash multiplier 1.90→2.15 and move +5%; first successful upgraded slash displays actual damage, and battle log accumulates its actual contribution. No unlock day, attack stat or enemy-count changes.
- Speed persistence already existed behind a setting. New/reset settings now remember chosen speed by default; existing saved explicit opt-out is preserved, and tutorial x1 remains protected. x2/x3 persistence, restart, cancellation and opt-out regressions pass.
- Duplicate thief targeting was reproduced with live actors. An opt-in developer prototype (`-- --prototype-ambush-backline`) makes only the captain prefer engineer/healer/priest/investigator when no thief is present; default targeting is unchanged. It requires balance/user evaluation before default adoption.
- Runtime idle observation: fresh roster DAY12, story disabled to isolate combat, x3, 56.05 simulated seconds / 18.769 real seconds, 8/8 enemies spawned. Only enemy-free future-wave gap was 0.05 simulated seconds at start. This fixture provides no evidence for idle compression. No wave/timer compression was enabled; a progressed-roster sample is needed before a useful prototype.

## 4. Changed files

| Files | Change |
|---|---|
| scripts/ui/PlayerContinuityUI.gd | Backlog, common menu, confirmations, offline notes, promotion feedback |
| scripts/core/CampaignSaveBundleGuard.gd | Recoverable full-format checkpoint rollback |
| scripts/game/GameRoot.gd | Save/menu/input/story/settings/window-close integration |
| scripts/story/CombatStoryFeed.gd, StoryDialoguePresenter.gd | Retained captions and recording displayed cues |
| scripts/ui/TitleWorkspaceUI.gd, MonsterWorkspaceUI.gd | Actual version, history reopen, promotion explanation |
| scripts/core/UISettings.gd | New-settings speed retention default |
| scripts/game/CombatSceneController.gd | Actual slash damage hook, developer-only targeting prototype |
| data/story/v122_main/day_12.json, day_23.json, day_30.json | Four important-scene metadata flags |
| tools/tests/PlayerContinuityTest.*, CombatIdleMeasureTest.*, DayOneFeedbackHotfixTest.gd | Related UI/safety/prototype/runtime tests |

## 5. Assets

No graphics/audio were generated or replaced. Build/capture/import cache files were excluded from commits. Automatic .import rewrites were restored only in the isolated clone.

## 6. Validation

Evidence root outside repository: `C:\Users\blueh\Documents\Codex\2026-10-11\task-2\evidence`.

| Check | Result | Evidence |
|---|---|---|
| PlayerContinuityTest, actual OpenGL GUI 1280×720 | PASS, 58 checks / 0 failures | continuity-gui-release.log; screenshots/ |
| DayOneFeedbackHotfixTest (speed, settings, names/resources) | PASS, 309 checks / 0 failures | regression-day1-final.log |
| PlayerFeedbackHotfixTest (rapid input/dialogue controls) | PASS, 136 checks / 0 failures | regression-player-feedback.log |
| V122StoryRuntimeIntegrationTest | PASS, 58 assertions | regression-story.log |
| CampaignSaveLoadSmokeTest | PASS, 246 assertions | regression-save.log |
| CombatIdleMeasureTest | PASS, runtime observation 2 checks | idle-measurement.log; idle-measurement.json |
| Windows Desktop export, final source | PASS | export-development-final.log |
| Exported PCK GUI continuity smoke | PASS, 13 checks / 0 failures, clean final log | pack-smoke-gui.log; screenshots/pack-menu.png |
| Exported EXE headless boot | PASS, exit0, no startup errors | exe-boot.log |
| Original personal-save preservation | PASS, 698 backed-up files have identical SHA256 | personal-save-preservation.json |
| git diff --check | PASS | Local verification |
| DK Chrome Steamworks current Auto-Cloud read | NOT_RUN, CUA kernel/platform launcher fails before browser inventory | See section 7 |
| Two-PC upload/download, offline/conflict recovery | NOT_RUN, no second PC/browser session | See section 7 |
| Full campaign, subjective promotion/idle playtest | NOT_RUN | Required before balance adoption |
| Full regression / independent full review | NOT_REQUESTED | Related tests only |

The latest GUI checks cover multiple previously shown dialogue lines, history auto/manual freeze and state/reward invariance, six buttons, exact settings return, five-format save, injected late-format failure and byte rollback, failure-blocked title/quit, three title/continue cycles, combat no-write, pause cancellation, feed priority/cap/expiry, settings/x3 retention, important scene delivery, actual promoted slash and opt-in targeting. Expected injected failure warnings in the source test logs are part of the test.

- Review task ID: NOT_REQUESTED
- Reviewed SHA: 386f29dafe3f39c2f9020c6081c940531ac08de1
- Review range: b88252e9eb8081a9456a5f8feb1cc97c14266aae..386f29dafe3f39c2f9020c6081c940531ac08de1
- Remaining P1/P2: N/A
- Final review result: TARGETED_PASS

## 7. Cloud, save backup and remaining risks

Exact user path retained: `%APPDATA%\Godot\app_userdata\마왕님, 마왕성 지켜주세요! Demo`.
Five `campaign_save_v1.json`…`campaign_save_v5.json` are format versions of one campaign, NOT slots. v5 has load priority. Required Auto-Cloud primary-file set is these five plus `quarter_custom_layouts.json`; syncing only a subset risks mixed checkpoints. The original local folder had all five campaign files; quarter_custom_layouts.json was absent. It was not fabricated.

Historical handoff says six Auto-Cloud entries were published with developer-only testing enabled (10 MiB/50 files), dynamic sync off, storefront Cloud indication off; two-PC test unfinished. Those are historical statements, not current DK Steamworks observations. CUA initial inventory failed with a missing Windows launcher/platform directory; retry failed with the trusted Node process exiting. Neither current paths nor developer-only state were read today. No Steamworks settings changed, and no RemoteStorage system was added.

Official behavior reference: https://partner.steamgames.com/doc/features/cloud — Auto-Cloud synchronizes selected disk files around application launch/exit. Current app configuration and a real second PC must be checked separately. Before any developer-only removal/publication, report observed six paths/current flags and both-direction results to the parent and obtain the separate release decision.

Preserve a complete six-file backup before cross-PC or offline/conflict work. For an unresolved Cloud conflict, preserve both local and remote versions and choose a coherent campaign set based on verified checkpoint/day/time; do not mix v5 with stale lower versions. Do not destructively test the user's progress or change Cloud account/security settings.

Save rollback handles recoverable process write failures. It is not a power-loss-atomic transaction across five files and cannot prove Steam conflict/power-loss safety. Restore staging failures are reported and block save-and-leave; they were not induced with actual disk corruption. No alternate-PC Cloud sync was exercised. Legacy error detail may remain Korean in a multilingual UI. Session history is memory-only. Full council/endgame menu paths and subjective readability at every layout were not exhaustively played.

## 8. Next decisions

1. Restore browser tooling and read app5267750 Steamworks Auto-Cloud six paths and developer-only/published state, preserving current settings. Then run two-PC bidirectional/offline/conflict tests with disposable data and backups.
2. Human test actual campaign pacing/promotions at DAY12/23, rapid reading, menus/settings, load/exit and text sizes. Evaluate developer-only rear-support prototype; collect progressed-roster idle gaps before compression. Do not blanket-change unlocks/stats/enemy counts.
3. Parent can inspect the private standalone review build for IndieSight preparation. No keys, Curator Connect message, review copy delivery or public release was performed here.
4. Any remote push/merge, public Steam build or developer-only Cloud removal requires a separate decision.

## 9. Working tree / artifacts

Product and tests locally committed; handoff/CURRENT documented in the following docs-only commit. Captures: evidence/screenshots. Standalone EXE/PCK: evidence/development-build. Hashes: evidence/development-build-hashes.json. Personal backup: evidence/save-backup-original + save-backup-manifest.json; never distribute it. Original worktrees and unrelated Dongkyusei/IU projects were not edited.

## 10. Checklist

- [x] Approved implementation items above completed and tested.
- [x] Relevant source tests and actual GUI/pack/export checks recorded.
- [x] Personal saves backed up and hash-preserved.
- [x] No new assets, source/user changes preserved, no remote/public actions.
- [x] CURRENT.md linked to this recovery point.
- [ ] Current Steamworks / two-PC Cloud validation.
- [ ] Full play/user balance assessment and release approval.
