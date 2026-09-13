extends "res://scripts/ui/ManagementWorkspaceUI.gd"

func build_form() -> void:
	root.onboarding_name_input=null
	root.onboarding_name_random_button=null
	root.onboarding_name_confirm_button=null
	root.onboarding_name_tip_overlay=null
	root.onboarding_bati_comment_label=null
	var screen: Control=root._onboarding_screen_panel(Color("#050407ff"))
	screen.name="NameEntryScreen"
	root._onboarding_add_scene_illustration(screen,Rect2(0,0,1920,1080),root.ONBOARDING_START_SCENE)
	copy(screen,"새로운 마왕의 첫날",Rect2(120,120,580,70),40,GOLD,"NameEntryKicker")
	var portrait: TextureRect=hud.texture(screen,root._onboarding_speaker_portrait_path("CHR_BATI","dry"),Rect2(110,245,600,490))
	portrait.name="NameEntryBati"
	portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	var note: Panel=hud.child_panel(screen,Rect2(100,758,630,190),INK,LINE,1)
	copy(note,LanguageSettings.text("name.speaker.bati"),Rect2(28,20,570,36),24,GOLD)
	root.onboarding_bati_comment_label=copy(note,root._onboarding_name_screen_comment(),Rect2(28,65,570,100),24,PAPER,"NameEntryFeedback")
	var form: Panel=hud.child_panel(screen,Rect2(790,120,1030,828),INK,LINE,1)
	form.name="NameEntryForm"
	copy(form,LanguageSettings.text("name.title"),Rect2(60,48,910,68),40,PAPER,"NameEntryTitle")
	copy(form,LanguageSettings.text("name.prompt.touch" if UISettings.is_touch_ui() else "name.prompt.desktop"),Rect2(60,135,910,60),26,MUTED,"NameEntryPrompt")
	var input:=LineEdit.new()
	input.name="NameInput"
	input.position=Vector2(60,244)
	input.size=Vector2(910,92)
	input.placeholder_text=LanguageSettings.text("name.placeholder")
	input.max_length=0
	input.add_theme_font_override("font",UIFont.font_for_role(UIFont.ROLE_EMPHASIS))
	input.add_theme_font_size_override("font_size",UISettings.scaled_font_size(30))
	input.add_theme_color_override("font_color",PAPER)
	input.add_theme_color_override("font_placeholder_color",MUTED)
	input.add_theme_stylebox_override("normal",hud.flat_style(INK.darkened(0.3),LINE,1))
	input.add_theme_stylebox_override("focus",hud.flat_style(INK,GOLD,2))
	input.text_submitted.connect(Callable(root,"_onboarding_name_submitted"))
	input.text_changed.connect(Callable(root,"_onboarding_name_changed"))
	form.add_child(input)
	root.onboarding_name_input=input
	root.register_tutorial_target("NameInput",Rect2(850,364,910,92))
	copy(form,"마왕명 · 앞뒤 공백을 제외하고 1~12자",Rect2(60,352,910,52),22,MUTED,"NameLengthHint")
	root.onboarding_name_random_button=button(form,LanguageSettings.text("name.action.random"),Rect2(60,450,340,80),Callable(root,"_onboarding_random_name"),"RandomNameButton")
	root.onboarding_name_confirm_button=button(form,LanguageSettings.text("name.action.confirm"),Rect2(430,450,540,80),Callable(root,"_onboarding_confirm_name"),"ConfirmNameButton","primary")
	input.focus_next=input.get_path_to(root.onboarding_name_random_button)
	root.onboarding_name_random_button.focus_previous=root.onboarding_name_random_button.get_path_to(input)
	root.onboarding_name_random_button.focus_next=root.onboarding_name_random_button.get_path_to(root.onboarding_name_confirm_button)
	root.onboarding_name_confirm_button.focus_previous=root.onboarding_name_confirm_button.get_path_to(root.onboarding_name_random_button)
	copy(form,"Enter · 이름 확정     Tab · 다음 항목",Rect2(60,548,910,42),20,MUTED,"NameEntryKeys")
	if not TutorialGuidanceHistory.has_dismissed(TutorialGuidanceHistory.NAME_ENTRY_GUIDE_ID) and UISettings.tutorial_guidance_level==UISettings.TUTORIAL_GUIDANCE_FULL:
		var guide:=Control.new()
		guide.name="NameEntryGuideCard"
		guide.position=Vector2(60,620)
		guide.size=Vector2(910,170)
		guide.mouse_filter=Control.MOUSE_FILTER_IGNORE
		form.add_child(guide)
		root.onboarding_name_tip_overlay=guide
		copy(guide,LanguageSettings.text("name.guide.body"),Rect2(0,0,650,132),22,MUTED,"NameEntryGuideBody")
		button(guide,LanguageSettings.text("name.guide.dismiss"),Rect2(680,22,230,72),Callable(root,"_onboarding_dismiss_name_entry_tip"),"NameGuideDismiss")
	if not UISettings.is_touch_ui(): root.call_deferred("_focus_onboarding_name_input")
