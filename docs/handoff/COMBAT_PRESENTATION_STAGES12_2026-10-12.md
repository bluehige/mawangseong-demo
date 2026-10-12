# Combat presentation development: stages 1–2

## Metadata
- Date: 2026-10-12 UTC.
- Target: development changes; no new version approved. Project version remains1.2.11.
- Branch: `codex/combat-presentation-prototype`.
- Baseline: docs HEAD249445d, public product2786be4; public Steam Build25870353 retained (parent-verified).
- Tested code commit: `ca7d42bb4659b91b1013c418adbaf54c83b65115`.
- Remote push, release tag and public deployment: none.

## Completed
Missing feedback now follows actual damage for Leon counters, boss broom hits, redirected protection damage, hunger/devouring pulses, moon hunt, molten impact/burn and stone march. No damage formulas, mana/cooldowns, reward handlers or random rates were changed. Redirected damage adds a presentation signal after the existing recursive damage call; it never repeats the call.

Runtime numbers merge only the same target/source/contact kind within0.10 presentation seconds. Legacy visual probes retain their previous0.15 simulation-second API window. Final mitigated damage display remains distinct from HP-loss contribution accounting and is not relabeled as a fabricated critical hit.

MapleStory Bold is reused for numeric typography in all three locales, with its existing bundled notice preserved. Numbers add a bounded pop/settle movement, outline and shadow, dynamic text width, physical-screen size compensation, safe-screen rectangle packing and recycling. Up to32 active numeric entries are admitted. Weak overflow cannot evict a stronger skill number; crowding can suppress lower-priority visual entries while gameplay/contact events remain intact. No tween is allocated per number.

## Changed files
`scripts/game/CombatSceneController.gd`, `scripts/game/GameRoot.gd`, `scripts/units/Unit.gd`, `scripts/ui/UIFont.gd`, new `scripts/ui/CombatDamagePresentation.gd/.uid`; new `tools/tests/CombatPresentationPrototypeTest.gd/.tscn`; existing head-anchor and polish test fixtures.

No graphics/audio/font binaries, story/catalog data, version, personal saves or public package were replaced. The original Desktop checkout remains untouched. Its upload config still has0/0 IDs; it is not this worktree.

## Validation
| Check | Result | Evidence under workspace `../evidence/` |
|---|---|---|
| Actual Compatibility GUI, 720p/1080p, zoom0.78/1.85, grouping/overflow/pause/three-locale glyphs | PASS191 | `combat-presentation-stages12-gui-final.log`, `combat-presentation-stages12-screenshots/` |
| Earlier focused headless route/number check | PASS93 | `combat-presentation-stages12-headless.log` |
| Existing contact synchronization | PASS23 | `combat-presentation-contact.log` |
| Boss/broom mechanics | PASS31 | `combat-presentation-BebePhase11Test.log` |
| Duo mechanics | PASS43+49 | `combat-presentation-DuoLinksPhase10Test.log`, `combat-presentation-DuoLinkPhase9Test.log` |
| Head-anchor contract | PASS12 | `combat-presentation-anchor-contract.log` |
| Existing actual GUI polish regression, corrected fixture | PASS122 | `combat-presentation-polish-regression-gui-final.log` |
| Low-end PC / human impact-feel evaluation / full campaign | NOT_RUN | No claim of certification |

The first visual capture exposed adjacent long-number overlap; it is preserved in `combat-presentation-pre-layout/` and was corrected with screen-rectangle packing. The old polish test first stalled headlessly on `frame_post_draw`, then failed because it expected ordinary shield bark before the existing important Leon scene. Initial FAIL logs are preserved. Only its fixture was updated to acknowledge current startup notes, isolate and finish that important scene before asserting the ordinary bark. Production story policy was unchanged.

The synthetic200-hit/32-entry layout measurement on this DK machine had mean2208.5us and max2393us across64 repacks, with18 visible entries under that deliberately crowded fixture. This is layout CPU cost, not whole-game FPS or a low-end result. Full repacking occurs once per tick; incoming hits place only their own number. Diagnostic counters distinguish numeric overflow from rectangle-placement declines.

## Preservation / recovery
Personal save backup: `../evidence/combat-presentation-save-backup/`,698 files, every copied SHA256 matched. Manifest: `combat-presentation-save-backup-manifest.json`. All game tests use isolated APPDATA under evidence. Public1.2.11 ZIP/PCK/EXE remain immutable. Importer-generated .import edits were restored only in this initially clean isolated checkout before checkpointing.

## Next
Implement representative quick-slash/fireball/slime-shield visual-only improvements and x3 VFX frame completion. Preserve projectile arrival damage callback and gameplay-facing skill_anim_timer. Then implement off/simple/full cutins, current-form portraits, bounded queues, menu/story/input protection, persistent settings/reduction option and development package verification. SteamCMD human-login confirmation is a separate pending workflow; do not authenticate or upload during this work.

Review task ID: NOT_REQUESTED
Remaining P1/P2: N/A
Final review result: TARGETED_PASS
Reviewed SHA: ca7d42bb4659b91b1013c418adbaf54c83b65115
