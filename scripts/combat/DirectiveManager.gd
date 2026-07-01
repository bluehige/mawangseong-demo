extends RefCounted
class_name DirectiveManager

static func directive_label(directive: String) -> String:
	match directive:
		"defense":
			return "사수"
		"all_out":
			return "총공격"
		"survival":
			return "생존 우선"
		"entry_block":
			return "입구 봉쇄"
		"trap_lure":
			return "함정 유도"
		"retreat":
			return "후퇴 유도"
		_:
			return "기본"

