# Local checkpoint + Steam Auto-Cloud compatibility

Date: 2026-10-11. DK, Windows, Godot 4.6.3. Branch codex/v1210-safety-dialogue-review. Product code remains 386f29dafe3f39c2f9020c6081c940531ac08de1; previous documentation HEAD was 316fa961ec0ab1ef8edac63f4c379074053ef0b4. No product code or binaries changed during this follow-up. Only two outdated fixed-wording expectations in tools/CampaignSaveLoadSmokeTest.gd were adjusted to check failure notice visibility and the actual temporary-file write error.

## Contract and direct local verification

The agreed design is ordinary local save/load, with Steam Auto-Cloud handling synchronization. There is no separate cloud-save button and no RemoteStorage SDK transition.

Production custom user-dir remains `%APPDATA%\Godot\app_userdata\마왕님, 마왕성 지켜주세요! Demo`. The actual runtime suffix was checked under a disposable APPDATA directory without replacing GameRoot's default filenames or production save-enable flags.

| Primary filename | Meaning |
|---|---|
| campaign_save_v1.json | Legacy format of the same campaign |
| campaign_save_v2.json | Format v2 of the same campaign |
| campaign_save_v3.json | Format v3 of the same campaign |
| campaign_save_v4.json | Format v4 of the same campaign |
| campaign_save_v5.json | Preferred current-format checkpoint |
| quarter_custom_layouts.json | Optional saved custom layouts; absent until created |

All five campaign formats are enabled in production. Save writes the enabled versions and commits v5 last. v5 is preferred for restore; a valid v1 fixture deliberately containing different resources did not override v5. The test resumed saved dialogue before management, which is valid checkpoint restoration; the initial test incorrectly required management immediately and was corrected. The fixture was restored as a coherent five-file set afterward. This is not evidence that mixed Cloud generations are safe in general.

Custom layouts use the same user:// directory, write without a Steam connection, and reload through DataRegistry. Campaign save/load does not alter their bytes. No missing customer layout file was fabricated.

The menu Save action writes a local checkpoint. Combat Save refuses to write; Load restores the previous checkpoint. Save-and-leave blocks after failure and cancelled menus restore the prior pause/input state. No menu claims that local save success proves remote Cloud synchronization. settings.cfg is kept local; per-computer settings and update acknowledgement are not added to the six Cloud rules.

## Results

All numbers below are checks/assertions in one final execution, not scenario counts or repeated-run totals.

| Check | Result | Evidence outside repository |
|---|---|---|
| Production-path/default-filename/local-layout/v5-priority/menu compatibility | PASS, 26 checks / 0 failures | evidence/autocloud-local-compatibility-final.log; evidence/CloudLocalCompatibility.gd |
| Existing continuity/menu/write-failure regression | PASS, 58 checks / 0 failures | evidence/autocloud-continuity-regression.log |
| Campaign save/load compatibility | PASS, 246 assertions | evidence/autocloud-save-regression-final.log |
| Customer file preservation | PASS, 698 original backup hashes unchanged | evidence/personal-save-preservation-autocloud.json |
| Real Steam upload/download / two-PC / offline conflict recovery | NOT_RUN | No second execution host or disposable Steam test session |

The first save regression rerun reported two failures because it searched the old exact Korean wording “자동 저장에 실패”. The new rollback notice and visible warning were present. Tests now search for a failure notice and still require the actual temporary-file error; no product behavior was changed to make the test pass. The final 246 assertions pass. Earlier failing logs are retained as development evidence.

All follow-up saves and divergent fixtures were created under evidence/* APPDATA directories. Customer campaign files were not opened for mutation. No publish, push, merge, Steamworks setting change or public sharing was performed by this local agent. The existing EXE/PCK and review ZIP remain valid for unchanged product code 386f29d.

## Steamworks facts supplied by the parent

These are parent-browser observations, not a successful DK CUA read by this local agent:

- Final publication confirmed; no uncommitted app data for app5267750.
- developer-only=0; hidecloudui=1 and ignoreexternalfiles=1 entries removed and published after separate user approval.
- Six exact paths/filenames, Windows, non-recursive, 10 MiB / 50 files preserved.
- Store Supported Features Steam Cloud remains unchecked with “Must first enable and test Steam Cloud”. Parent intends to complete it after actual synchronization tests.
- Actual two-PC sync remains NOT_RUN.

The parent’s confirmed publication supersedes the earlier handoff’s historical developer-only state. The local agent did not change Steamworks or independently verify the web configuration.

Official reference: https://partner.steamgames.com/doc/features/cloud . Auto-Cloud synchronizes configured files around Steam application launch/exit without requiring Cloud API integration. Published settings may require up to 10 minutes or a Steam client restart. Steam resolves WinAppDataRoaming with Windows APIs, so a child-process-only APPDATA override is not a proof of the actual client sync path. Steam creates steam_autocloud.vdf; the game can ignore it.

## Conditions and minimum actual two-PC procedure

This execution environment exposes DK only. A second real Windows PC/accessible execution session is required; a second folder on DK is not the two-PC test.

Required: the same licensed disposable Steam test account on both PCs, isolated Windows test profiles with no valued campaign in the configured AppData path, Steam Cloud enabled in both clients and for app5267750, online access, and the same build launched as app5267750 through Steam. Ordinary standalone EXE boot verifies local compatibility but not Auto-Cloud hooks. Refresh published settings by client restart or the documented wait. Preserve coherent local/cloud test snapshots before conflict exercises; do not overwrite the customer's campaign to create a fixture. If no disposable licensed account and second PC are available, keep NOT_RUN.

1. On PC A, create a recognizable checkpoint and one optional custom layout, record DAY/time/resources and hashes for all six present files, then exit through the game menu and wait for Steam upload completion. Inspect `%Steam Install%\logs\cloud_log.txt` for app5267750 activity/errors.
2. On clean PC B, let Steam finish downloading before launching. Before a new local save can rewrite timestamps, compare primary-file hashes, then verify Continue restores matching DAY/resources/story state and the custom layout.
3. Save distinct progress on B, exit and wait for upload. Repeat download/hash/Continue verification on A. PASS requires both A→B and B→A.
4. With disposable data and both versions backed up, test offline local save/reconnection and divergent progress. Preserve both candidate sets before resolving any conflict. Verify the selected complete checkpoint restores correctly and v5 is not combined with a different generation of v1–v4.

A failed sync, out-of-quota result, missing configured file or corrupted restore must be investigated before claiming complete Cloud support. Tests must record client status/logs and actual restored state; web publication alone is insufficient.

## Release gates versus recommendations

Cloud-support completion gates: actual Steam client upload/download, two-PC bidirectional restoration, and minimum disposable offline/conflict safety remain unverified. Complete them before declaring the Cloud feature tested or finishing its store indication. Store Cloud display is an unfinished release checklist item, not a local-save code defect.

Game-patch release gate: the review patch is not deployed; remote merge/push and public Steam distribution still require separate authorization. Local code compatibility has no identified new functional blocker after the targeted checks.

Recommendations rather than proven defects: broader human full-campaign/locale/layout playtest, promotion prototype balance judgement, progressed-roster idle measurement, and broader power-loss testing. Recoverable save rollback still does not provide a power-loss-atomic transaction across five files. No recommendation here authorizes changing the accepted Auto-Cloud design or publishing a build.
