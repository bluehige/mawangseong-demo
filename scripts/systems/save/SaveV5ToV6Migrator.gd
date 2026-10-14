extends RefCounted

const V5 = preload("res://scripts/systems/save/SaveV4ToV5Migrator.gd")
const PlotState = preload("res://scripts/map_builder/PlotSaveState.gd")
const TARGET_VERSION := 6
const Expansion = preload("res://scripts/systems/council/CouncilExpansionService.gd")

static func migrate_envelope(input: Dictionary, templates: Dictionary, metrics: Dictionary, u3: Dictionary = {}, u4: Dictionary = {}) -> Dictionary:
	var error := V5.validate_v5(input,templates,metrics,u3,u4)
	if error != "": return {"ok":false,"error":error}
	var output := input.duplicate(true)
	var payload: Dictionary = output.active_run.legacy_payload
	var world: Dictionary = payload.get("world",{})
	var migration := PlotState.migrate(world,int(payload.get("game_state",{}).get("day",1)),output.active_run)
	if not migration.ok: return migration
	output["version"] = 6
	output["migrated_from_version"] = 5
	output.active_run["plot_state"] = migration.state
	output["plot_migration_fallback"] = migration.fallback
	output = convert_council(output)
	return {"ok":true,"error":"","envelope":output,"fallback":migration.fallback}

static func validate_v6(envelope: Dictionary, templates: Dictionary, metrics: Dictionary, u3: Dictionary = {}, u4: Dictionary = {}) -> String:
	if envelope.get("version") != 6: return "Invalid save v6 version"
	var compat := convert_council(envelope)
	compat["version"] = 5
	var error := V5.validate_v5(compat,templates,metrics,u3,u4)
	if error != "": return error
	var state = envelope.active_run.get("plot_state")
	if not state is Dictionary: return "Missing plot state"
	if state.get("grade_index") != PlotState.grade(envelope.active_run.legacy_payload.get("world",{})): return "Plot grade differs from castle stage"
	return PlotState.validate(state)

static func upgrade_legacy(input: Dictionary, templates: Dictionary, metrics: Dictionary, u3: Dictionary, u4: Dictionary) -> Dictionary:
	var output := input.duplicate(true)
	var version := int(output.get("version",0))
	if version < 1 or version > 5: return {"ok":false,"error":"Unsupported legacy save"}
	var migration: Dictionary = {}
	if version == 1:
		var validation := preload("res://scripts/core/CampaignSaveStore.gd").validate_payload(output.get("payload",{}),output.get("summary",{}))
		if validation != "": return {"ok":false,"error":validation}
		output["status"] = "valid"
		migration = preload("res://scripts/core/CampaignSaveMigratorV1ToV2.gd").migrate_inspection(output,templates,metrics)
		if not migration.ok: return migration
		output = migration.envelope
	if version <= 2:
		migration = preload("res://scripts/core/CampaignSaveMigratorV2ToV3.gd").migrate_envelope(output,templates,metrics)
		if not migration.ok: return migration
		output = migration.envelope
	if version <= 3:
		migration = preload("res://scripts/systems/save/SaveV3ToV4Migrator.gd").migrate_envelope(output,templates,metrics,u3)
		if not migration.ok: return migration
		output = migration.envelope
	if version <= 4:
		migration = V5.migrate_envelope(output,templates,metrics,u3,u4)
		if not migration.ok: return migration
		output = migration.envelope
	return migrate_envelope(output,templates,metrics,u3,u4)

static func convert_council(input: Dictionary) -> Dictionary:
	var output := input.duplicate(true)
	if output.get("active_run") is Dictionary:
		output.active_run = Expansion.convert_active(output.active_run)
	for area in [output.get("summary",{}),output.get("active_run",{}).get("legacy_payload",{}),output.get("active_run",{}).get("legacy_payload",{}).get("checkpoint",{})]:
		if area is Dictionary:
			for key in ["screen", "safe_screen", "checkpoint"]:
				if area.get(key) == "upper_floor": area[key] = "management"
	if output.get("profile") is Dictionary:
		var profile: Dictionary = output.profile
		if profile.get("chronicle_update4") is Dictionary:
			profile.chronicle_update4["accessibility"] = preload("res://scripts/systems/chronicle/CouncilChronicleService.gd").normalize_accessibility(profile.chronicle_update4.get("accessibility",{}))
		# Historical IDs continue granting equivalent zone detail; no repeated reward.
		if "E18" in profile.get("update4_endings_seen",[]) or "upper_floor_epilogue_layout" in profile.get("cosmetic_ids",[]):
			var chronicle: Dictionary = profile.get("chronicle",{}).duplicate(true)
			chronicle["zone_detail_unlocked"] = true
			profile["chronicle"] = chronicle
	return output
