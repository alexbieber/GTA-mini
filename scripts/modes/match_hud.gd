class_name MatchHUD
extends CanvasLayer
var selected_team := 1
var _menu: PanelContainer
var _menu_content: VBoxContainer
var _settings_content: VBoxContainer
var _match: Control
var _results: PanelContainer
var _mode: Label
var _objective: Label
var _stats: Label
var _prompt: Label
var _subtitle: Label
var _result_subtitle: Label
var _banner: Label
var _feed: Label
var _feed_lines: Array[String] = []
var _result_heading: Label
var _result_standings: Label
var _waiting_action := ""
var _binding_button: Button
var reticle: CombatReticle
var _banner_remaining := 0.0
var radar: Radar

func _ready() -> void:
	layer = 10
	_build_match()
	_build_menu()
	_build_results()
	show_start(true)

func game() -> Node:
	return get_tree().current_scene

func label(text: String, size := 18) -> Label:
	var node := Label.new()
	node.text = text
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", Color("f0e6d2"))
	node.add_theme_color_override("font_shadow_color", Color.BLACK)
	node.add_theme_constant_override("shadow_offset_x", 1)
	node.add_theme_constant_override("shadow_offset_y", 1)
	return node

func button(text: String, callback: Callable, parent: Node) -> Button:
	var node := Button.new()
	node.text = text
	node.custom_minimum_size.y = 42
	node.focus_mode = Control.FOCUS_NONE
	if callback.is_valid(): node.pressed.connect(callback)
	parent.add_child(node)
	return node

func panel() -> PanelContainer:
	var node := PanelContainer.new()
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var style := StyleBoxFlat.new()
	style.bg_color = Color("101923")
	style.content_margin_left = 28
	style.content_margin_right = 28
	style.content_margin_top = 28
	style.content_margin_bottom = 28
	node.add_theme_stylebox_override("panel", style)
	add_child(node)
	return node

func centered_box(parent: Node) -> VBoxContainer:
	var center := CenterContainer.new()
	parent.add_child(center)
	var box := VBoxContainer.new()
	box.custom_minimum_size.x = 540
	box.add_theme_constant_override("separation", 12)
	center.add_child(box)
	return box

func _build_menu() -> void:
	_menu = panel()
	var box := centered_box(_menu)
	box.add_child(label("URBANO · ORIGINAL · OFFLINE", 14))
	box.add_child(label("OPERAÇÃO CAOS", 46))
	_menu_content = VBoxContainer.new()
	_menu_content.add_theme_constant_override("separation", 12)
	box.add_child(_menu_content)
	_menu_content.add_child(label("Dois mapas compactos. Combate em terceira pessoa.", 18))
	var team := OptionButton.new()
	team.add_item("FACÇÃO FICTÍCIA · COLETIVO AURORA", 1)
	team.add_item("POLÍCIA", 0)
	team.custom_minimum_size.y = 42
	team.item_selected.connect(func(index: int) -> void: selected_team = team.get_item_id(index))
	_menu_content.add_child(team)
	button("FAVELA ROYALE · 10 PARTICIPANTES", func() -> void: game().start_mode(MatchRules.Mode.BATTLE), _menu_content)
	button("PROTEGE O CORRE! · 5v5", func() -> void: game().start_mode(MatchRules.Mode.CORRE), _menu_content)
	button("CONFIGURAÇÕES", _show_settings, _menu_content)
	button("SAIR", func() -> void: get_tree().quit(), _menu_content)
	_menu_content.add_child(label("Sem conexão online · escolha equipe/personagem acima", 14))
	_settings_content = VBoxContainer.new()
	_settings_content.add_theme_constant_override("separation", 8)
	_settings_content.visible = false
	box.add_child(_settings_content)

func _show_settings() -> void:
	for child in _settings_content.get_children():
		_settings_content.remove_child(child)
		child.queue_free()
	_menu_content.visible = false
	_settings_content.visible = true
	_settings_content.add_child(label("CONFIGURAÇÕES · Compatibility", 24))
	var quality := OptionButton.new()
	for text in ["LOW", "MEDIUM", "HIGH"]: quality.add_item(text)
	quality.select(game().clock.quality)
	quality.item_selected.connect(func(value: int) -> void:
		game().clock.set_quality(value)
		game().save_settings())
	_settings_content.add_child(quality)
	var narrator := CheckButton.new()
	narrator.text = "Locutor da equipe · voz original da Facção / legendas da Polícia"
	narrator.button_pressed = game().matches.announcer.enabled
	narrator.toggled.connect(func(on: bool) -> void:
		game().matches.announcer.set_enabled(on)
		game().save_settings())
	_settings_content.add_child(narrator)
	_settings_content.add_child(label("Volume do locutor", 16))
	var volume := HSlider.new()
	volume.min_value = -40
	volume.max_value = 6
	volume.value = game().matches.announcer.volume_db
	volume.value_changed.connect(func(value: float) -> void:
		game().matches.announcer.volume_db = value
		game().save_settings())
	_settings_content.add_child(volume)
	_settings_content.add_child(label("Sensibilidade do mouse / ADS", 16))
	var mouse := HSlider.new()
	mouse.min_value = 0.001
	mouse.max_value = 0.008
	mouse.step = 0.0001
	mouse.value = game().camera.mouse_sens
	mouse.value_changed.connect(func(value: float) -> void:
		game().camera.mouse_sens = value
		game().save_settings())
	_settings_content.add_child(mouse)
	var ads := HSlider.new()
	ads.min_value = 0.2
	ads.max_value = 1.0
	ads.step = 0.05
	ads.value = game().camera.ads_sensitivity
	ads.value_changed.connect(func(value: float) -> void:
		game().camera.ads_sensitivity = value
		game().save_settings())
	_settings_content.add_child(ads)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size.y = 150
	_settings_content.add_child(scroll)
	var bindings := GridContainer.new()
	bindings.columns = 3
	bindings.add_theme_constant_override("h_separation", 8)
	bindings.add_theme_constant_override("v_separation", 8)
	scroll.add_child(bindings)
	for action in ["move_left", "move_right", "move_forward", "move_back", "jump", "sprint", "crouch", "aim", "fire", "reload", "interact", "swap_shoulder", "tactical_sprint", "drop_objective", "return_menu"]:
		var events := InputMap.action_get_events(action)
		var caption := str(action) + " · " + (events[0].as_text() if not events.is_empty() else "—")
		var binding := button(caption, Callable(), bindings)
		binding.pressed.connect(func() -> void:
			_waiting_action = action
			_binding_button = binding
			binding.text = "Pressione tecla/botão · Esc cancela")
	button("VOLTAR", func() -> void:
		_settings_content.visible = false
		_menu_content.visible = true
		_waiting_action = "", _settings_content)

func capture_binding(event: InputEvent) -> bool:
	if _waiting_action == "": return false
	if (event is InputEventKey or event is InputEventMouseButton) and event.is_pressed():
		if event is InputEventKey and event.keycode == KEY_ESCAPE:
			_waiting_action = ""
			_show_settings()
			return true
		InputMap.action_erase_events(_waiting_action)
		InputMap.action_add_event(_waiting_action, event.duplicate())
		_binding_button.text = _waiting_action + " · " + event.as_text()
		_waiting_action = ""
		game().save_settings()
		return true
	return false

func _build_match() -> void:
	_match = Control.new()
	_match.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_match.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_match)
	reticle = CombatReticle.new()
	reticle.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	reticle.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_match.add_child(reticle)
	radar = Radar.new()
	radar.position = Vector2(18, 18)
	radar.size = Vector2(154, 154)
	_match.add_child(radar)
	_mode = label("", 18)
	_mode.position = Vector2(188, 20)
	_match.add_child(_mode)
	_objective = label("", 16)
	_objective.position = Vector2(188, 48)
	_match.add_child(_objective)
	_stats = label("", 18)
	_stats.position = Vector2(188, 76)
	_match.add_child(_stats)
	_feed = label("", 14)
	_feed.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_feed.position = Vector2(-260, 150)
	_match.add_child(_feed)
	_prompt = label("", 15)
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.position = Vector2(-420, -45)
	_match.add_child(_prompt)
	_subtitle = label("", 23)
	_subtitle.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_subtitle.position = Vector2(-400, -90)
	_match.add_child(_subtitle)
	_banner = label("", 22)
	_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_banner.position = Vector2(-180, 115)
	_match.add_child(_banner)

func _build_results() -> void:
	_results = panel()
	_results.visible = false
	var box := centered_box(_results)
	_result_heading = label("", 32)
	box.add_child(_result_heading)
	_result_subtitle = label("", 20)
	box.add_child(_result_subtitle)
	_result_standings = label("", 14)
	box.add_child(_result_standings)
	button("JOGAR NOVAMENTE", func() -> void: game().matches.restart(), box)
	button("VOLTAR AO MENU", func() -> void: game().matches.return_menu(), box)

func show_start(on: bool) -> void:
	_menu.visible = on
	_match.visible = not on
	if on:
		_menu_content.visible = true
		_settings_content.visible = false

func show_results(on: bool) -> void:
	_results.visible = on
	if not on:
		_feed_lines.clear()
		_feed.text = ""
		_banner.text = ""

func present_results(title: String, score: Array, mode: int, standings := "") -> void:
	_result_heading.text = title + (" · POLÍCIA %d × %d AURORA" % [score[0], score[1]] if mode == MatchRules.Mode.CORRE else " · FAVELA ROYALE")
	_result_standings.text = standings
	show_results(true)

func set_mode_text(text: String) -> void: _mode.text = text
func set_objective(text: String) -> void: _objective.text = text
func set_prompt(text: String) -> void: _prompt.text = text
func set_banner(text: String) -> void:
	_banner.text = text
	_banner_remaining = 2.0 if text != "" else 0.0
func set_subtitle(text: String) -> void:
	_subtitle.text = text
	_result_subtitle.text = text
func set_stats(health: float, _money: int, weapon := "", _speed := -1.0) -> void:
	_stats.text = "HP %d · %s" % [int(health), weapon]
func set_combat(on: bool, ads: bool, speed: float) -> void:
	reticle.visible = on
	reticle.gap = 3.0 if ads else 8.0 + minf(speed, 10.0)
func confirm_hit() -> void: reticle.hit_remaining = 0.15
func set_wanted(_stars: int) -> void: pass
func set_crime(_text: String) -> void: pass
func set_distance(_distance: float, _label: String) -> void: pass
func add_elimination(text: String) -> void:
	_feed_lines.append(text)
	if _feed_lines.size() > 5: _feed_lines.pop_front()
	_feed.text = "\n".join(_feed_lines)

func _process(delta: float) -> void:
	if _banner_remaining > 0.0:
		_banner_remaining = maxf(_banner_remaining - delta, 0.0)
		if _banner_remaining == 0.0: _banner.text = ""
