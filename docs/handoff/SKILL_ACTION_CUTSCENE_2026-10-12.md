# Private character skill action review — 2026-10-12

Approved scope: about one second of real character action with a simulation hold; exact policies `한번만 보기` (default), `계속 보기`, `스킬컷씬 끄기`; per skill/duo ID history, settings reset/preview/apply/cancel; manual/automatic/two-member duo actions; preserve original numerical combat effects. This is a private implementation and targeted review, not a release. Public version remains 1.2.11; no version decision, Steam publication, remote push/merge, new SDK, account changes, or Cloud publication occurred.

Implementation checkout: `C:/Users/blueh/Documents/Codex/2026-10-11/task-2/mawangseong-action`, branch `codex/skill-action-cutscenes`. Product checkpoint **748001f05f8222aef6c9324b86018d22dc828191**, preceded by fb48fece (manual/policy) and 6cc85119 (automatic continuation WIP), based on private 562f0d1. Hub registered baseline remains sibling `mawangseong` / 562f0d1; it is not remapped to this worktree. Original desktop project and sibling AGENTS/README changes remain untouched. Local main is absent; origin/main 0ac9fdc7 was read as historical policy and not asserted as current public state.

## Behavior and changed files

- UISettings.gd stores once/always/off and viewed `skill:<ID>` / `duo:<ID>` in existing settings.cfg, preserving unrelated sections. Explicit skip consumes the accepted action once and records a successful viewed scene. Menu/load/scene interruptions resolve an accepted action once but do not record it as viewed. Reset is previewed and restored on cancel. Legacy explicit off is preserved; other legacy modes migrate to default once.
- SkillActionPresentation.gd / SkillActionStage.gd use an independent presentation process. The current actor SpriteFrames are copied at prepare time; existing four attack/skill frames supply poses. Impact/launch occurs at 0.54 seconds, scene ends around 1.0 seconds. No external game art/music or generated portrait limb motion was added. Gameplay buttons/world shortcuts are blocked; menu/pause/speed remain reachable. Numeric contacts are real existing contact events. Support scenes display their actual ally or area instead of an unrelated enemy.
- CombatSceneController.gd prepares captured caster/targets before effect, rejects freed/queued targets before costs, routes generic and TokTok/Koko/Bebe automatic skills, and suspends the original root frame at its actor cursor. Delta/speed/frame tail resume once. An accepted automatic duo can queue during its parent commit and reuse the same hold. The original melee/projectile hit tail resumes after the duo so Leon counter calculations retain original order. TokTok preserves its original requested path and fixes the first collision recipient separately.
- GameRoot.gd handles automatic frame continuation and explicit pause owners, menu/input/settings/history hooks, duo preparation and current two-member display, and load/title cleanup. Unit.gd consumes the saved delta/speed once on resume. CombatDamagePresentation.gd uses the existing Maple numeric pipeline and retires action numbers at scene end so they cannot be attributed to the next scene.

**Projectile boundary:** the action commits a cast/launch at contact time. Real fireball damage stays in the existing projectile arrival callback after combat resumes. The launch scene does not fabricate an early enemy hit. Successful damage/mana/cooldown values, skill probability/rewards and original projectile travel callback were preserved; unlock days, ATK, enemy counts and campaign balance were not changed.

## Fresh targeted results

Engine: task-local Godot **4.6.3.stable.official.7d41c59c4**, SHA256 63B3B2208819714C9677FBFDD8217C5B7DEE8ECF5F383502E826BC9E2227FF5A. GUI tests used actual OpenGL Compatibility on NVIDIA3060Ti. Each process used an evidence-specific APPDATA. Shared godot alias still invokes 4.5.2 and was not modified.

| Test | Result | Evidence in task-2/evidence |
|---|---|---|
| SkillActionManualPrototypeTest | PASS 127, 0 failures | skill-action-final-manual.log |
| SkillActionAutomaticFrameTest | PASS 56, 0 failures | skill-action-final-automatic.log |
| SkillActionLiveAutomaticTest | PASS 11, 0 failures | skill-action-final-live-automatic.log |
| SkillActionDuoTest | PASS 70, 0 failures | skill-action-final-duo.log |
| SkillActionSupportTest | PASS 30, 0 failures | skill-action-final-support.log |
| SkillActionLifecycleTest | PASS 34, 0 failures | skill-action-final-lifecycle.log |
| PlayerContinuityTest | PASS 89, 0 failures | skill-action-continuity.log |
| CampaignSaveLoadSmokeTest | PASS 246 assertions | skill-action-save-compatibility.log |
| Actual exported PCK | PASS 36, 0 failures | skill-action-packed-smoke.log / SkillActionPackSmoke.gd |
| Actual EXE through isolated launcher | PASS exit0, 180-frame default boot, no script errors | skill-action-exe-boot.log |
| Export | PASS exit0 | skill-action-export.log |
| Personal save / old package preservation | PASS 698 originals + 698 backup hashes, 5 old artifacts unchanged, 17 old PNGs retained | skill-action-preservation-final.json |
| Independent focused review | TARGETED_PASS; 3 findings corrected, none unresolved | skill-action-independent-review.md |

The controlled automatic test proves identical complete vectors for off/first once/seen once/always, and a deferred x3 request during an original x1 frame. The live test also runs production root/unit physics and the independent stage process; both automatic scenes held combat_time at 0.0166667 throughout approximately one second. It is a targeted real-time fixture, not a complete campaign playthrough.

Covered risks: duplicate/rapid skip; actual free/queue invalidation; prepared caster despite selection change; fixed support recipient despite external HP change; requested versus first-collision TokTok target deletion; nested automatic duo; original counter order; menu/story/backlog owners during saved automatic frames; skipped/disabled paths; title/load interrupt; history reset/cancel/file reload; old config sections and versioned campaign fixtures. The intentional synthetic settings write-failure injection returned failure and did not claim persisted history; its warning in lifecycle log is expected, and the synthetic configuration was restored.

Earlier failures are retained: manual-after-duo.log had a corrected GDScript type inference error; manual-after-duo-fixed.log used an invalid fixture userdata name and was rerun correctly. Initial duo.log 62/4 failed because the ram fixture used non-walkable coordinates; entrance walkable coordinates yielded 62/0 and the final expanded suite 70/0. Independent review found a saved-frame menu pause defect, a support recipient display defect, and a desired/first-collision specialist invalidation guard gap; all were fixed and directly rechecked. These are not represented as unresolved failures or hidden by the final PASS.

## Artifacts and preservation

New development folder: `task-2/evidence/skill-action-development-build`. Launch through `LaunchPrototype.ps1` to use the package's `prototype_userdata`, keeping normal user data separate. Running the EXE directly uses the normal personal save directory. `development-manifest.json` records product SHA, engine, tests and file hashes. New ZIP and incremental source bundle paths/hashes are in `skill-action-final-result.json`.

New actual action screenshots: `skill-action-final-screenshots/manual` (prepare/attack/impact and settings in three locales) and `duo` (prepare/two actors/real -26 impact). PNG compression occurs after capture to avoid changing the measured scene timing. Old 17 captures, previous static-cut development EXE/PCK/ZIP, public2786be4 ZIP, and the user's desktop duo image are preserved. Current hashes for the 17 old PNGs are recorded; a historical per-image manifest was unavailable, so no retroactive individual hash comparison is claimed.

Save directory remains `%APPDATA%/Godot/app_userdata/마왕님, 마왕성 지켜주세요! Demo`. Backup and isolated runtime storage are local evidence. The five campaign_save_v1~v5.json files remain versions of one campaign, not slots. No new save slot, mid-battle save system, RemoteStorage integration or Cloud setting was introduced.

## Limits / NOT_RUN

Full campaign, all six duo combinations with every crown/promoted/royal skill, low-end hardware, user subjective action/balance evaluation, actual Steam install/update, two-PC bidirectional Cloud and offline/conflict Cloud scenarios are **NOT_RUN**. Browser/Steamworks reread is blocked by this host's previously diagnosed CUA kernel startup error; it was not retried or claimed successful. No public configuration was changed.

The existing native attack/support frames are sufficient for this measured prototype and can be enlarged, but dedicated high-resolution preparation/impact/recovery poses were not supplied or generated. Concrete existing examples are `assets/sprites/uiux3d/goblin_sheet.png`, `goblin_ambush_captain_sheet.png`, `crown_gob_midnight_marshal_sheet.png`, and `assets/sprites/monsters/monster_armored_beetle_attack_down_00.png` through `_03.png`. The director copies whatever current promotion/crown SpriteFrames the live unit actually has; this does not establish bespoke cutscene animations for every form. A visual/art expansion needs the original character-separated pose sequence and a separate decision.

## Trial and recovery

M-ACTION-20261012 started after baseline work. Only these fresh post-start results are new observations. Existing session `cutscene-policy-decision-20261012` is reused. Raw outcome checkpoint records the implementation root/product SHA, direct evidence and independent review; registered criterion/review PASS gates require the central owner to register fresh evidence IDs before promotion. No central registry remap or fabricated token/time/efficiency reduction occurred; unmeasured metrics remain null. Three review findings and their fixes are concrete observations, not proof of a measured comparative productivity gain.

Recovery: use this clean local action branch and product748001f, the private build and incremental bundle. The bundle requires existing baseline562f0d1. A final documentation commit updates this handoff/CURRENT without changing the exported product source. Do not resume from older manual/WIP checkpoints, overwrite user progress, or use the shared4.5.2 engine. Parent can register evidence/update its hub observation and arrange human review; Steam publication remains a separate decision.
