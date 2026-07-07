# Evolution System Reference Options - 2026-07-07

## Goal

Monster evolution should be the long-term payoff for growth, but it must not break the tutorial balance that was just stabilized.

Beginner explanation:

- Evolution means a monster changes into a stronger or more specialized form.
- A branch means the player chooses one of two or more future roles.
- A catalyst means a special material used to trigger evolution.
- A promotion means the unit keeps its identity but unlocks higher stats, skills, or a new passive.
- Fusion means two units or traits are combined into one stronger unit.

## Similar Game References

- Pokemon: evolution uses many triggers, including level, trade, friendship, time, held item, location, region, and unique conditions.
  - Reference: https://bulbapedia.bulbagarden.net/wiki/Methods_of_Evolution
- Monster Sanctuary: evolution is catalyst-based and often works as a role change rather than a pure upgrade.
  - Reference: https://monster-sanctuary.fandom.com/wiki/Evolution
- Siralim Ultimate: deep creature collection with fusion mechanics and many specialization systems.
  - Reference: https://thylacinestudios.com/
- Dungeon Maker: close genre reference for dungeon defense with many monsters, traps, facilities, and fusion/unique monster categories.
  - Reference: https://play.google.com/store/apps/details?id=com.GameCoaster.DungeonMaker
  - Reference: https://duma-eng.fandom.com/wiki/Fusion_Monsters
- The Battle Cats: true forms are delayed unit upgrades that can improve stats and change abilities, with later material-gated forms.
  - Reference: https://battle-cats.fandom.com/wiki/True_Form
- Arknights: promotion increases level/stat caps and unlocks skills/talents through material gates.
  - Reference: https://arknights.fandom.com/wiki/Promotion
- Legend of Keepers: close loop reference for dungeon management, traps, monsters, roguelite runs, and defending against heroes.
  - Reference: https://store.steampowered.com/app/978520/Legend_of_Keepers_Career_of_a_Dungeon_Manager/

## Options For This Game

### Option A: Linear Evolution

Each monster has one fixed next form.

Example:

- Slime -> Iron Slime
- Goblin -> Goblin Captain
- Imp -> Flame Imp

Good:

- Fastest to implement.
- Easiest for new players.
- Lowest UI and balance risk.

Bad:

- Less player choice.
- Can become a simple stat race.
- Later invasions may need bigger enemy numbers to keep up.

Best use:

- If the next milestone is a quick playable prototype.

## Option B: Branching Role Evolution

Each monster chooses one of two role paths.

Example:

- Slime -> Gate Bulwark for blocking, or Gel Alchemist for recovery/slow support.
- Goblin -> Ambush Captain for trap synergy, or Loot Raider for reward/risk play.
- Imp -> Flame Adept for area damage, or Hex Binder for debuff/control.

Good:

- Strong choice and replay value.
- Fits room roles and directives.
- Lets future invasions counter specific strategies without only raising enemy HP.

Bad:

- Requires more UI, data, icons, balance work, and eventually more art.
- If branches are not clear, beginners may feel they made a wrong choice.

Best use:

- Recommended first full version.

## Option C: Catalyst Evolution

Evolution needs a special story/invasion material.

Example:

- `slime_core` from the first boss defense.
- `raider_badge` from a thief invasion.
- `ember_contract` from a fire-themed invasion.

Good:

- Makes story wins and invasion rewards feel important.
- Naturally controls when evolution enters balance.
- Can combine with Option B.

Bad:

- Needs reward tables and clear UI for missing materials.

Best use:

- Recommended as the unlock condition for Option B.

## Option D: Promotion-Style Evolution

The monster keeps its form but unlocks a higher growth tier, new passive, or skill upgrade.

Good:

- Very cheap to implement.
- Good before full evolution art exists.
- Easy to explain as "first awakening".

Bad:

- Feels less exciting than a new form.
- Needs strong UI feedback to feel like evolution.

Best use:

- Recommended MVP if art scope is tight.

## Option E: Fusion Lab

Two monsters or traits are combined to create a special form.

Good:

- Huge long-term depth.
- Excellent for late-game collection and build crafting.

Bad:

- Too complex for the next tutorial step.
- Can destroy balance if trait inheritance is not tightly limited.
- Requires rules for sacrifice, duplicates, inherited skills, and refunds.

Best use:

- Post-demo or chapter 2+ feature, not the immediate next implementation.

## Recommendation

Use a hybrid:

1. First playable: Promotion-style evolution with data prepared for branches.
2. First full version: Branching role evolution unlocked by catalysts.
3. Later system: Fusion Lab for rare late-game monsters and repeat invasion rewards.

This gives the player an immediate growth endpoint without forcing the game into a complex fusion economy too early.

## First Playable Scope

Implement only one evolution stage.

Requirements:

- Monster level 3 or 4.
- One chapter material from story defense.
- Gold or mana cost.
- Evolution screen reachable from monster management.

Effects:

- Primary stat +15-25%.
- Secondary stat +5-10%.
- One passive or skill upgrade.
- One role tag, such as `blocker`, `trap_synergy`, `fire_aoe`, or `control`.

Do not:

- Do not multiply all stats heavily.
- Do not add fusion yet.
- Do not make enemies scale directly from player level in the first story chapter.

## Balance Direction

Chapter 1:

- No evolution required.
- Teach EXP, level, skills, and result growth review.

Chapter 2:

- Expect one evolved monster.
- Add enemy role counters, not only higher HP.

Chapter 3:

- Expect two or three evolved monsters.
- Introduce enemies that pressure specific rooms or punish one-dimensional builds.

Repeat invasions:

- Use optional modifiers and growth-responsive scaling here.
- Keep main story scaling mostly chapter-based so players feel rewarded for evolving.

