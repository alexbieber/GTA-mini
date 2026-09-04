class_name GameHUD
extends CanvasLayer

var _title: Label
var _brief: Label
var _start: Button
var _objective: Label
var _stars: Label
var _prompt: Label
var _banner: Label
var _dist: Label
var _start_panel: ColorRect
var _time_chip: Button
var _day_btn: Button
var _night_btn: Button
var _tag: Label
var _health: Label
var _money: Label
var _crime: Label
var _weapon: Label
var _speed: Label
var radar: Radar


func _ready() -> void:
	layer = 10
	_build()
	show_start(true)
	set_banner("")
	set_prompt("")
	set_time_of_day(true)


func show_start(on: bool) -> void:
	_start_panel.visible = on
	_time_chip.visible = not on
	if radar:
		radar.visible = not on
	if _health:
		_health.visible = not on
		_money.visible = not on
	if _weapon:
		_weapon.visible = not on
	if _speed:
		_speed.visible = not on


func set_objective(text: String) -> void:
	_objective.text = text


func set_wanted(stars: int) -> void:
	if stars <= 0:
		_stars.text = ""
		return
	_stars.text = "HEAT  " + "◆".repeat(stars) + "◇".repeat(maxi(0, 5 - stars))


func set_prompt(text: String) -> void:
	_prompt.text = text


func set_banner(text: String) -> void:
	_banner.text = text
	_banner.visible = text != ""


func set_stats(health: float, money: int, weapon := "", speed := -1.0) -> void:
	if _health:
		_health.text = "HP  %d" % int(health)
		_health.add_theme_color_override("font_color", Color("ff6a6a") if health < 30.0 else Color("8eecc0"))
	if _money:
		_money.text = "$%d" % money
	if _weapon:
		_weapon.text = weapon
	if _speed:
		_speed.text = "" if speed < 0.0 else "%d MPH" % int(speed * 2.4)


func set_crime(text: String) -> void:
	if _crime:
		_crime.text = text


func page(text: String) -> void:
	set_crime(text)


func set_distance(meters: float, label: String) -> void:
	if meters < 0.0:
		_dist.text = ""
		return
	_dist.text = "%s  ·  %dm" % [label, int(round(meters))]


func set_time_of_day(night: bool) -> void:
	if _time_chip:
		_time_chip.text = "NIGHT" if night else "DAY"
	if _tag:
		_tag.text = "HARBOR DISTRICT  ·  " + ("NIGHT SHIFT" if night else "DAY RUN")
	if _day_btn:
		_day_btn.modulate = Color(1, 1, 1, 0.45 if night else 1.0)
		_night_btn.modulate = Color(1, 1, 1, 1.0 if night else 0.45)
	if _start_panel:
		_start_panel.color = Color(0.04, 0.05, 0.08, 0.78) if night else Color(0.72, 0.82, 0.9, 0.55)


func _build() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	_objective = _label(18, Color("f0e6c8"))
	_objective.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_objective.offset_left = 188
	_objective.offset_top = 20
	_objective.offset_right = 820
	_objective.offset_bottom = 52
	root.add_child(_objective)

	_health = _label(16, Color("8eecc0"))
	_health.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_health.offset_left = 188
	_health.offset_top = 48
	_health.offset_right = 360
	_health.offset_bottom = 72
	root.add_child(_health)

	_money = _label(20, Color("f0d060"))
	_money.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_money.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_money.offset_left = -280
	_money.offset_top = 18
	_money.offset_right = -24
	_money.offset_bottom = 46
	root.add_child(_money)

	_weapon = _label(15, Color("d8e6f0"))
	_weapon.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_weapon.offset_left = 188
	_weapon.offset_top = 72
	_weapon.offset_right = 420
	_weapon.offset_bottom = 96
	root.add_child(_weapon)

	_speed = _label(16, Color("f0e6c8"))
	_speed.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_speed.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_speed.offset_left = -200
	_speed.offset_top = 128
	_speed.offset_right = -24
	_speed.offset_bottom = 154
	root.add_child(_speed)

	_dist = _label(15, Color(0.94, 0.63, 0.19, 0.9))
	_dist.set_anchors_preset(Control.PRESET_TOP_LEFT)
	_dist.offset_left = 188
	_dist.offset_top = 96
	_dist.offset_right = 520
	_dist.offset_bottom = 120
	root.add_child(_dist)

	_crime = _label(14, Color("ff8a6a"))
	_crime.set_anchors_preset(Control.PRESET_TOP_WIDE)
	_crime.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crime.offset_top = 18
	_crime.offset_bottom = 42
	root.add_child(_crime)

	radar = Radar.new()
	radar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	radar.offset_left = 18
	radar.offset_top = 18
	radar.offset_right = 172
	radar.offset_bottom = 172
	root.add_child(radar)

	_stars = _label(22, Color("ff5a5a"))
	_stars.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_stars.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_stars.offset_left = -360
	_stars.offset_top = 48
	_stars.offset_right = -24
	_stars.offset_bottom = 82
	root.add_child(_stars)

	_time_chip = Button.new()
	_time_chip.text = "NIGHT"
	_time_chip.focus_mode = Control.FOCUS_NONE
	_time_chip.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_time_chip.offset_left = -150
	_time_chip.offset_top = 88
	_time_chip.offset_right = -24
	_time_chip.offset_bottom = 124
	_style_chip(_time_chip)
	_time_chip.pressed.connect(_toggle_time)
	root.add_child(_time_chip)

	_prompt = _label(16, Color(0.94, 0.63, 0.19))
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_prompt.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_prompt.offset_left = -240
	_prompt.offset_top = -150
	_prompt.offset_right = 240
	_prompt.offset_bottom = -120
	root.add_child(_prompt)

	_banner = _label(42, Palette.amber())
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.set_anchors_preset(Control.PRESET_CENTER)
	_banner.offset_left = -420
	_banner.offset_top = -40
	_banner.offset_right = 420
	_banner.offset_bottom = 40
	root.add_child(_banner)

	_start_panel = ColorRect.new()
	_start_panel.color = Color(0.04, 0.05, 0.08, 0.78)
	_start_panel.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_start_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_start_panel)

	var col := VBoxContainer.new()
	col.set_anchors_preset(Control.PRESET_CENTER)
	col.offset_left = -340
	col.offset_top = -210
	col.offset_right = 340
	col.offset_bottom = 230
	col.add_theme_constant_override("separation", 12)
	_start_panel.add_child(col)

	_tag = _label(14, Color(0.94, 0.63, 0.19, 0.8))
	_tag.text = "HARBOR DISTRICT  ·  NIGHT SHIFT"
	_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_tag)

	_title = _label(64, Color("f0e6c8"))
	_title.text = "NIGHT DROP"
	_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_title)

	_brief = _label(18, Color(0.88, 0.86, 0.78, 0.95))
	_brief.text = "Steal the coupe. Lose the heat. Make the drop.\nThen the district stays open: gun shop, bar,\narmy base, An-2s, and traffic that looks like cars."
	_brief.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(_brief)

	var modes := HBoxContainer.new()
	modes.alignment = BoxContainer.ALIGNMENT_CENTER
	modes.add_theme_constant_override("separation", 12)
	col.add_child(modes)
	_day_btn = _mode_button("DAY")
	_night_btn = _mode_button("NIGHT")
	_day_btn.pressed.connect(func() -> void: _set_time(false))
	_night_btn.pressed.connect(func() -> void: _set_time(true))
	modes.add_child(_day_btn)
	modes.add_child(_night_btn)

	_start = Button.new()
	_start.text = "START THE DROP"
	_start.custom_minimum_size = Vector2(0, 56)
	_start.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color("f0a030")
	sb.corner_radius_top_left = 8
	sb.corner_radius_top_right = 8
	sb.corner_radius_bottom_left = 8
	sb.corner_radius_bottom_right = 8
	_start.add_theme_stylebox_override("normal", sb)
	_start.add_theme_color_override("font_color", Color("0b1020"))
	_start.add_theme_font_size_override("font_size", 20)
	_start.pressed.connect(_on_start)
	col.add_child(_start)

	var keys := _label(13, Color(0.78, 0.76, 0.68, 0.8))
	keys.text = "WASD  ·  mouse  ·  E enter  ·  click shoot  ·  1-3 guns  ·  N day/night"
	keys.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(keys)


func _mode_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 42)
	b.focus_mode = Control.FOCUS_NONE
	_style_chip(b)
	return b


func _style_chip(b: Button) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.12, 0.82)
	sb.border_color = Color("f0a030")
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(8)
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_color_override("font_color", Color("f0e6c8"))
	b.add_theme_font_size_override("font_size", 16)


func _toggle_time() -> void:
	var clock := get_tree().get_first_node_in_group("day_night") as DayNight
	if clock:
		clock.toggle()
		set_time_of_day(clock.is_night)


func _set_time(night: bool) -> void:
	var clock := get_tree().get_first_node_in_group("day_night") as DayNight
	if clock:
		clock.apply(night)
		set_time_of_day(night)


func _on_start() -> void:
	var game := get_tree().current_scene
	if game and game.has_method("begin"):
		game.begin()


func _label(size: int, color: Color) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.55))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	return l
