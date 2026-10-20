# Combat presentation: private development implementation and verification

Date: 2026-10-12 UTC. WORKSTREAM_ID: combat-presentation-prototype.
Repository: bluehige/mawangseong-demo. Steam app5267750. Product: Who Guards the Demon Castle?
Local branch: `codex/combat-presentation-prototype`.
Reviewed product SHA: `4f425f0fade02cd0141ddabd063e6070126e5eb3`.
Stage1/2 product SHA: `ca7d42bb4659b91b1013c418adbaf54c83b65115`.
Starting documentation HEAD:249445d; prior public product:2786be4.

The user authorized implementation of damage-number/contact presentation, representative skill visuals and optional cutins. The earlier read-only restriction was superseded. Balance, probabilities, rewards, mana and cooldown values were preserved. Projectile arrival still resolves its original damage callback. Public deployment, push/merge, version selection, SDK/account changes and SteamCMD authentication were not performed.

## Implemented files and behavior

| Files | Result |
| --- | --- |
| `Unit.gd`, `GameRoot.gd`, `CombatSceneController.gd` | Missing counter/boss-broom/redirect/area-dot/moon/molten/stone contact feedback follows actual damage. Redirect reports the actual protector amount without another damage call. Source/target/contact-kind grouping avoids unrelated events merging. |
| `CombatDamagePresentation.gd`, `UIFont.gd` | Existing MapleStory Bold numeric role, shadow/outline/pop/settle, bounded1.25 emphasis, 32-label pool, bounded screen packing, zoom/window compensation. Crowded lower-priority labels may be suppressed. No invented critical damage. |
| `Unit.gd`, `CombatSceneController.gd` | Quick slash/fireball use a separate presentation timer. Gameplay `skill_anim_timer` remains unchanged. x1/x3 cosmetic VFX complete all frames before removal; speed changes and pauses propagate to effects. Newly created paused effects start frozen. Cosmetic48/64 caps never discard damage-carrying projectiles. |
| `CombatSkillCutin.gd` | Off/simple/full modes; current promotion/crown portrait;1 active+2 pending; bounded64 token history,1.5s global and6s actor-skill spacing,2s stale queue expiry. Cutins ignore focus/input and avoid HUD/damage rectangles. Menu, story, backlog and title clear/suppress them. No simulation pause or reward action. |
| `UISettings.gd`, `GameRoot.gd` | Combat settings in KO/EN/ZH, preview/apply/cancel/reset/persistence. Reduced effects use simple cutins, existing flash reduction and no camera shake. Real settings write failure keeps the settings screen open with retry/cancel feedback. |
| `PrepareSteamBuild.ps1` | Default prefers this workspace's verified4.6.3 binary, retaining the exact engine-version gate and explicit override. Shared `godot.cmd`/4.5.2 binary remains untouched. |
| `CombatPresentationPrototypeTest.gd`, `CombatSkillPresentationTest.gd`, `CombatCutinOptionsTest.gd` | Synthetic contact/skill/cutin/pause/settings, six promotion and six crown fixtures, actual GUI captures and bounded-layout measurement. |

The initial stage document contains the detailed contact and number specification: [stages1–2](COMBAT_PRESENTATION_STAGES12_2026-10-12.md).

## Direct validation

All current runs use `Godot4.6.3.stable.official.7d41c59c4`, with isolated process-local APPDATA. GUI uses Compatibility/OpenGL on NVIDIA3060Ti. Evidence below is in the task workspace's `../evidence/` directory.

| Test / artifact | Status | Evidence |
| --- | --- | --- |
| Final actual GUI: contacts/numbers/representative x1+x3 skills/cutins/promotions/crowns/menu/settings/write failure | PASS317,0 failures | `combat-presentation-cutin-gui-final3.log` |
| Existing continuity actual GUI: backlog/important dialogue/checkpoint/menu/title continue/update notes | PASS89,0 failures | `combat-presentation-continuity-gui.log` |
| Duo phase10 / phase9, current implementation | PASS43+49 | `combat-final-DuoLinksPhase10Test.log`, `combat-final-DuoLinkPhase9Test.log` |
| Contact / VFX catalog / corrected depth script / audio palette | PASS23 /59 /30 /126 | Final contact: `combat-presentation-contact-final.log`; `combat-skills-V122CombatVfxCatalogTest.log`, `combat-skills-depth-corrected.log`, `combat-skills-SkillAudioPaletteTest.log` |
| Actual new exported PCK combat/font/options | PASS25,0 failures | `combat-presentation-packed-smoke.log`, external `CombatPresentationPackSmoke.gd` |
| Actual new exported PCK continuity/menu/promotion/crown assets | PASS44,0 failures | `combat-presentation-packed-continuity.log`, external `V1211PackSmoke.gd` |
| Actual Windows EXE boot | PASS, exit0 | `combat-presentation-exe-boot.log` |
| Isolated private launcher | PASS, exit0; separate userdata created; PowerShell parser0 errors | `LaunchPrototype.ps1 -GameArguments @('--quit-after','120')` |
| Existing visual-profile contract | BASELINE_FAIL,4 assertions | `combat-presentation-baseline-visual-profile-recheck.log`; same spider_tailor/bat_courier inheritance assertions reproduce in unchanged249445d Unit source. Those profile functions/data were not changed here. |
| Whole regression / independent review agent / full campaign | NOT_REQUESTED / NOT_RUN | Follow AGENTS targeted-check scope |
| Low-end hardware / whole-game FPS / human impact-feel evaluation | NOT_RUN | DK synthetic measurement is not certification |
| Actual Steam-installed client / two-PC Cloud / offline-conflict synchronization | NOT_RUN | No new claim of Cloud success or Steam install testing |

Final screenshots: `combat-presentation-final-screenshots/`,17 actual PNG captures. Includes1280x720 and1920x1080 numeric extremes at zoom0.78/1.85, quick slash/fireball/shield atx1/x3, full/simple and promoted cutins, and720p KO/EN/ZH settings. Screenshots were visually inspected. `number_layout_measure.json`:64 repacks of32-label/200-contact synthetic pressure, mean2193.3us/max2887us. This measures numeric layout CPU cost only;18 visible numbers under that crowded fixture. Incoming contact placement and full layout are bounded, with one full layout per presentation tick.

## Failures discovered and repaired

Earlier FAIL logs remain preserved. Adjacent long-number overlap was repaired by rectangle packing. Old polish fixture needed startup acknowledgement and completion of the existing important Leon scene before ordinary bark expectations. A projectile timing assertion was made bounded instead of assuming one slow GUI frame. Parser/type inference errors in cutin duration and Duo tween were corrected. Real settings-write failure uncovered a CanvasLayer-to-Control parent type error; the final test now forces a directory at the synthetic settings path, verifies failure feedback/cancel, then restores the synthetic settings file. Intentional I/O warnings are bracketed by `EXPECTED_SETTINGS_WRITE_FAILURE_BEGIN/END`; no SCRIPT ERROR occurs in the final log.

Initial export failed because isolated APPDATA had no templates. The already-installed exact4.6.3 Windows release template was copied into isolated APPDATA and export succeeded. The private development build uses that release template, rather than claiming a debug template existed. Engine binaries were not downloaded or replaced for this task.

## Development deliverables

`../evidence/combat-presentation-development-build/` contains the actual EXE/PCK, existing third-party/font licenses, README, `development-manifest.json` with source/artifact hashes, and `LaunchPrototype.ps1`. The launcher uses separate `prototype_userdata` beside the package; directly running the EXE uses the normal game path. The displayed project version remains1.2.11. This is a private prototype and is not the immutable public1.2.11 package or a newly approved release candidate.

Private review ZIP: `MawangCastle-CombatPrototype-4f425f0.zip`; size/hash in `combat-presentation-development-zip.json`. Runtime synthetic userdata is excluded. Development PCK584338684bytes, SHA256 `f07427c07f831212f81a703c8cb06e59fccdf5425340d919cf3825249d00e5e7`; EXE104699392bytes, SHA256 `b4eb57c313774883e4c80dc28f3892c6acd67eb37e5dbcca3c4684ac471c42f4`. EXE template is the same as the prior release; changed game code/assets reside in the newly verified PCK.

Public ZIP `MawangCastle-v1.2.11-SteamContent-2786be4.zip` remains615498335bytes, SHA256 `39b60ff263ef53e11c69e51e6816423908e8ae56cd597833a008596bfb6143d2`. The parent previously verified public default Build25870353/Depot5267751/Manifest5824439082666467035; this task did not change or independently re-publish it.

## Preservation and recovery

Personal save backup: `combat-presentation-save-backup/`,698 files. `combat-presentation-save-backup-manifest.json` records copied hashes. Final `combat-presentation-preservation-final.json` confirms all698 original hashes and the public ZIP remain unchanged. The normal Korean APPDATA path was preserved. Tests never use personal progress for destructive cases.

Original desktop worktree `C:\Users\blueh\Desktop\진행중인프로젝트\codex\마왕성` was read only. Its final branch/HEAD/pending paths are recorded in `combat-presentation-original-worktree-final.json`; it remains at e6ae83d on codex/v125-release-candidate with existing mixed user changes. All implementation is in the separate task clone. Generated importer/exporter .import metadata was restored only inside this initially clean isolated clone.

Recovery: use this branch and product SHA4f425f0. The final incremental Git bundle in evidence preserves the local combat workstream and handoff; it requires base249445d, which remains present in this clone. Restore synthetic settings only from their test-specific directories; do not copy them over personal saves. SteamCMD human-login confirmation is still a separate pending workflow and no credentials were read.

## Remaining release-review decisions

Human review of the numeric style/cutins and sustained real-play/low-end behavior remains necessary. The existing four visual-profile assertion mismatch must be reconciled before claiming a complete repository regression pass. No broad balance retuning or waiting-time compression was added during this presentation task. Cloud two-PC validation and actual Steam installation remain separate limitations from earlier continuity work. Public upload/default, source push/merge and any new version need the user's decision.

Review task ID: NOT_REQUESTED
Remaining P1/P2: NOT_ASSESSED_BY_INDEPENDENT_REVIEW; inherited4-assertion visual-profile contract mismatch recorded above.
Final review result: TARGETED_PASS_WITH_BASELINE_FAILURES
Reviewed SHA:4f425f0fade02cd0141ddabd063e6070126e5eb3
