# Limited actual-engine role/balance probe

Observed 2026-10-12. Eight final synthetic battle fixtures completed, exit0, zero harness failures; **40 comparison-integrity checks PASS**. This is a narrow measurement, not human balance approval or a natural campaign playthrough.

## Frozen runtime and method

- Runtime product: `aab19e40edc77b5b9baa52e47cdd360232e578a4`, private exported `development-build/MawangCastle.pck`, version1.2.11. PCK SHA256 `9CC1499464EE0EC889E881542715F1843414500BBAC240A3A82B43E7DCEA1205` matches the pre-existing manifest.
- Godot4.6.3 official7d41c59c4, actual OpenGL3.3/NVIDIA591.86 **GeForce RTX3060Ti**, 1280x720. Every engine used `--main-pack`; source imports/product files were not written.
- Isolated APPDATA: task workspace `evidence/first-defense-review-balance`. No personal-save fixture, user process manipulation, deployment or remote Git operation.
- Starting geometry/facilities/room directives: the preserved `first-defense-review-6618c09/baseline-valid/day1-precombat-fixture.json`. It is the first-defense castle, intentionally held constant even for the DAY30 stress wave. This is not the natural DAY30 castle/upgrades/region/rival progression.
- Each group used seed20261012, identical actual generated schedule and actual spawned enemy HP/attack/defense, three actors, identical initial slot positions and facility/room data. Seed initializes RNG equally; differing actions can consume subsequent RNG differently.
- Base party: Gob/Imp/Pudding. Replace Gob's exact roster slot/zone with Silky or Popo; the other two stay unchanged. Different species retain their actual base statistics, AI, ranges and native available skills. This is a roster-slot comparison, not proof that a rescue/support character and a melee damage dealer have identical roles.
- Same assigned level per group: DAY1 level1, DAY30 level6. **Training purchases0 means no training button/resource investment was simulated; levels were assigned by fixture**, not earned with equivalent campaign EXP. Acquisition/promotion/crown costs were separately excluded. Starting resources1245gold/320mana/18food/620infamy and throne1500 were equal. No combat HP damage or invented effects were injected.
- DAY30 ordinary core actors used existing first promotion forms; Silky/Popo used native basic forms. All ordinary specialization fields were empty. Story/tutorial blockers were disabled solely for unattended battle completion. Native automatic skill selection ran; no manual combat commands or casts were issued. Speedx3, cutscene policyoff avoids presentation-only time confounds.

## Final observed results

Every final case won, all3 actors survived, throne1500 remained, and treasure loss0. Time is actual simulated combat seconds. Damage is the engine's `damage_dealt`, computed from enemy HP-before minus HP-after, excluding overkill; facility damage is not counted as actor damage.

| Fixture | DAY / level | Time | Final allied HP | Actor HP damage | Rescue / royal casts |
|---|---:|---:|---:|---:|---:|
| Core3 | 1 / 1 | 24.35s | 403/440 (91.59%) | 409 | 0 / 0 |
| Gob slot → Silky | 1 / 1 | 20.55s | 397/428 (92.76%) | 439 | 0 / 0 |
| Gob slot → Popo | 1 / 1 | 17.25s | 353/410 (86.10%) | 477 | 0 / 0 |
| Core3, first promotions | 30 / 6 | 62.65s | 625/814 (76.78%) | 2650 | 0 / 0 |
| Gob slot → Silky | 30 / 6 | 63.15s | 656/802 (81.80%) | 2684 | 0 / 0 |
| Gob slot → Popo | 30 / 6 | 63.00s | 626/784 (79.85%) | 2659 | 0 / 0 |
| Core3 + forced Pudding crown | 30 / 6 | 63.15s | 694/867 (80.05%) | 2597 | 0 / 0 |
| Popo slot + forced Popo crown | 30 / 6 | 62.95s | 585/767 (76.27%) | 2642 | 0 / 0 |

DAY1 spawned3 actual enemies (aggregate maxHP567); DAY30 spawned9 (aggregate maxHP2731), identical within groups. Silky rescue counters and Pudding royal-use counters remained0. The observed Silky-party allies did not reach its <=35% HP trigger; the forced crowned Pudding party did not reach its <=70% same-room trigger. Therefore these runs measured ordinary damage/movement/mitigation and crown stat differences, **not rescue or royal protection effectiveness**.

Facility `recovery_healing` was observed0 in all cases. Skill-specific effective healing, rescue-shield prevented damage and royal prevented damage are **NOT_MEASURED**. The recorded `damage_absorbed` contribution mixes HP loss and prevented pressure, so the summary names it `pressure_handled_contribution`; it must not be described as HP damage received or protection attributable to a particular skill. Net HP loss and final HP are separate observed quantities.

## Crown eligibility limitation

The two battle crowns were directly assigned runtime state: **FORCED_ROYAL_FIXTURES**, not earned/legitimately confirmed crowns. Level6/bond80/DAY30 were supplied, but specialization and seal payment were absent; Popo also lacked mastery2. Actual service checks correctly rejected these battle fixtures:

- Pudding: `specialization,seal_cost`.
- Popo: `specialization,species_mastery,seal_cost`.

Separate data-only prerequisite fixtures supplied valid specialization, two seals and explicit mastery; `candidate_check` and `confirm` then passed and consumed2seals. Those eligible fixtures were **not battle-tested**. Natural acquisition, mastery generation and normal unlock progression remain **NOT_RUN**. Crown comparison rows therefore cannot establish a reachable player balance advantage/disadvantage. Pudding branch inheritance and Popo royal action are still unsupported.

## What this supports for patch versus DLC

The tested missing-skill rosters still won this narrow setup; DAY30 clear times differ by <=0.50s for the three ordinary parties. There is **no measured defeat-rate disadvantage here** and no measured strength for the eight missing effects. One fixed seed/setup, different base kits and no triggered rescue are insufficient to establish overall equivalence, superiority or lack of need.

`stitch_stairway`, `night_relay`, `echo_alarm` occupy the already-present basic Silky/Popo kit. Restoring those roles belongs with existing-character completion/maintenance on product grounds; this measurement does not justify moving them behind a paid DLC or compensating with blanket attack/unlock changes. Runtime threshold/floor/reveal prerequisites still need explicit scope and tests. The five other royal effects (`royal_no_second_cut`, `tricolor_demonfire`, `royal_shared_umbrella`, `royal_emergency_plating`, `royal_urgent_courier`) need their actual prerequisites/definitions and gameplay connection before power or pricing conclusions. This probe supplies **no evidence that paid DLC is required or balanced**. The companion read-only design audit supplies the individual implementation/dependency judgment.

Human fun/fairness/replay motivation, natural campaign/royal acquisition and counterfactual power of unimplemented actions: **NOT_RUN / NOT_MEASURED**. No extra battle groups or product balance changes were added after this bounded probe.

## Evidence and excluded pilot

- Final raw8 cases/log: `balance-role-probe-final/balance-role-probe.json`, per-case JSONs, `balance-role-probe-final-engine.log` (no SCRIPT ERROR/ERROR/WARNING markers).
- Compact metrics/integrity/audit: `balance-role-probe-summary.json`; summary generation `SummarizeBalanceRoleProbe.ps1`.
- Crown actual rejection and separate eligible data-only fixture: `balance-role-probe-final/crown-eligibility-audit.json`, `balance-crown-eligibility.log`.
- External executable harnesses: `BalanceRoleProbe.gd`, `BalanceCrownEligibilityProbe.gd`. These write only authorized evidence/isolated userdata.
- Actual GPU captures directly inspected: `balance-role-probe-final/early_core-actual-combat.png`, `late_silky-actual-combat.png`, `late_popo_crown-actual-combat.png`. Visible native party/current-form art, combat damage and unavailable-skill notices; no fabricated rescue/protection image.
- Excluded pilot preserved: `BalanceRoleProbe-pilot.gd`, `balance-role-probe-engine.log`, `balance-role-probe/`. Pilot replacement erased/appended the Gob slot, changing front actor spawn order; its numbers are not the adopted comparison. Its DAY23 wave was too weak to trigger support, so final stress fixtures use actual DAY30 schedule with corrected slot ordering. This retry was the same bounded comparison, not a larger campaign suite.

The separate writer later changed DAY2 room selection (product979adcd) and exported a new build. Those changes are **not** the runtime measured here; the immutable aab PCK remains the measurement basis.
