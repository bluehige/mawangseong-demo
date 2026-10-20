# Private 1.2.11 version review

Date: 2026-10-11. DK Windows, Godot 4.6.3 official7d41c59c4. Repository bluehige/mawangseong-demo, app5267750, Who Guards the Demon Castle. Branch codex/v1210-safety-dialogue-review remains the isolated workstream; its historical name does not set the product version.

## Version and scope

The approved continuity maintenance changes are now private candidate **1.2.11**. Project version, Title/Settings labels, offline notes/acknowledgement and current Windows export metadata agree. FileVersion and ProductVersion are **1.2.11.0**. The new notes contain five completed items, including promotion contribution visibility and speed preference. Earlier release records remain historical records.

Base for this version follow-up: 8b4d2a265418307a4480937014aadfdb85eae5ef. Product SHA: b0e0a791b134e424115f546f4b1b058a0ec315da. Public hotfix 515ed745d4ce731f7bafb31ee1f9381470794d72 is an ancestor (merge-base --is-ancestor exit0); its day-one feedback behavior was regression-tested. Parent browser observed public Build25808943, described as v1.2.10 same-version hotfix. No new public game version was published here.

Preserved: Steam app5267750; `%APPDATA%\Godot\app_userdata\마왕님, 마왕성 지켜주세요! Demo`; campaign_save_v1.json through v5.json and quarter_custom_layouts.json contract; previous update records; existing player settings and explicit speed opt-out. Old update acknowledgement remains a test fixture; it does not hide new 1.2.11 notes. No schema migration or RemoteStorage SDK was introduced.

Changed files in the product commit: project.godot; export_presets.cfg; scripts/ui/PlayerContinuityUI.gd; scripts/game/GameRoot.gd; tools/tests/PlayerContinuityTest.gd; tools/tests/PlayerFeedbackHotfixTest.gd; tools/tests/DayOneFeedbackHotfixTest.gd; README.md; docs/PRODUCT_VERSIONING.md; docs/releases/V1_2_11_REVIEW_NOTES.md. Subsequent changes are this handoff/CURRENT documentation only.

## Verification

Counts are checks/assertions in each final run, not unique scenario totals. Evidence paths below are relative to the parent task workspace, outside the repository.

| Test | Result | Evidence |
|---|---|---|
| PlayerContinuityTest, real GUI, versions/old acknowledgement/menu/backlog/save failures | PASS, 62 checks / 0 failures | evidence/v1211-continuity-gui.log |
| DayOneFeedbackHotfixTest, public hotfix/speed regression | PASS, 309 checks | evidence/v1211-day1-regression.log |
| PlayerFeedbackHotfixTest, input regression | PASS, 136 checks | evidence/v1211-input-regression.log |
| CampaignSaveLoadSmokeTest | PASS, 246 assertions | evidence/v1211-save-regression.log |
| Synthetic prior-1.2.10 save/settings compatibility | PASS, 11 checks | evidence/v1211-upgrade-compatibility.log; V1211UpgradeCompatibility.gd |
| Production local Cloud path/default filenames/layout/v5 priority | PASS, 26 checks | evidence/v1211-cloud-local-compatibility.log; CloudLocalCompatibility.gd |
| Windows export and PE version metadata | PASS, 1.2.11.0 | evidence/v1211-build-hashes.json; v1211-development-build/build-provenance.json |
| Exported PCK actual GUI | PASS, 14 checks / 0 failures | evidence/v1211-pack-gui.log; V1211PackSmoke.gd |
| Exported standalone EXE boot | PASS, exit0 | evidence/v1211-exe-boot.log |
| Customer data preservation | PASS, 698 original file hashes unchanged | evidence/v1211-customer-file-preservation.json |
| Actual Steam upload/download, two-PC bidirectional sync, offline/conflict | NOT_RUN | No second execution host/disposable Steam test session |
| Full campaign and subjective promotion balance | NOT_RUN | Targeted verification requested |

Actual 1280x720 OpenGL screenshots: evidence/v1211-screenshots (menu, backlog, captions, promotion, KO/EN/ZH updates, settings version). KO/EN/ZH five-note panels and the version label were visually inspected; automated captures do not replace a full layout/playthrough review. The exported PCK exercises product code from the package, not just source scenes.

A synthetic prior-version six-file set loaded correctly, retained DAY/resources/custom layout, was not rewritten merely by startup, and remained valid after a new write and repeated Continue. No personal progress was used as a fixture. Customer data was backed up before implementation and remained hash-identical afterward.

## Artifacts and recovery

Private EXE/PCK: evidence/v1211-development-build. Review ZIP: evidence/MawangCastle-v1.2.11-review-b0e0a79.zip. It contains the two binaries, review README and build provenance, not personal saves. Old 1.2.10 review artifacts and Library images are retained unchanged.

ZIP SHA256: 91508D92CE23E0A5A78A68877AB06177923FAEAAB006FB2C9F63C8EAF66BDEC5 (658394811 bytes).

EXE SHA256: DD562A07855D0CCED116F58E1E727250F45A0D3BF0822B96A17635240DB09845 (104699392 bytes).

PCK SHA256: 03E9FD5C308FC6972CE74C81CF0EB2B276E91BD9124E918E4129930A96C336CC (584315056 bytes).

Original DK checkout/worktrees and their user changes were not modified. Own-clone Godot import changes from export were restored after successful packaging; source product commit and final docs commit are recovery points. No remote push/merge, tag, public Steam build, account-security change or local-agent Steamworks publication occurred.

## Cloud state and release limits

[Earlier local compatibility handoff](V1210_AUTOCLOUD_LOCAL_COMPATIBILITY_2026-10-11.md) distinguishes parent browser observations from this agent's failed DK browser access. Parent separately confirmed six Windows non-recursive rules, 10 MiB/50 files, developer-only0, removed hidecloudui/ignoreexternalfiles entries and no uncommitted app data. These changes had separate user approval. Store Cloud feature remained unchecked pending actual testing. Local path tests and standalone boot are not Steam client synchronization evidence.

Actual A→B and B→A restoration plus disposable offline/conflict tests remain Cloud completion gates. Use two real Windows hosts, same licensed disposable Steam account/build, isolated profiles and coherent backups; inspect actual cloud_log.txt and restored state. Preserve both candidate sets before resolving conflicts. Do not mix current v5 with older lower-version campaign files. Do not use valued customer progress for destructive tests.

Recoverable save rollback is not power-loss atomic across five files. Backlog is session-only. Promotion/backline prototype balance and progressed-roster idle measurement require actual play/user judgement; no blanket stats/unlock/enemy or wait compression changes were committed. Public distribution or source push/merge requires a separate decision.

## Review metadata

- Review task: NOT_REQUESTED (targeted affected verification requested)
- Reviewed SHA: b0e0a791b134e424115f546f4b1b058a0ec315da
- Reviewed range: 8b4d2a265418307a4480937014aadfdb85eae5ef..b0e0a791b134e424115f546f4b1b058a0ec315da
- Remaining P1/P2: N/A; no independent full review requested
- Final review result: TARGETED_PASS

Implementation records: [continuity changes](V1210_CONTINUITY_REVIEW_2026-10-11.md), [local Cloud compatibility](V1210_AUTOCLOUD_LOCAL_COMPATIBILITY_2026-10-11.md), [current completed release notes](../releases/V1_2_11_REVIEW_NOTES.md).
