class_name TouchControls
extends CanvasLayer

var move := Vector2.ZERO
var look := Vector2.ZERO
var gas := false
var brake := false
var interact_pressed := false
var punch_pressed := false
var handbrake := false
var driving := false

var _stick_id := -1
var _look_id := -1
var _stick_origin := Vector2.ZERO
var _max_radius := 72.0

var _root: Control
var _stick_base: Panel
var _stick_knob: Panel
var _enter_btn: Button
var _gas_btn: Button
var _brake_btn: Button
var _punch_btn: Button
var _hint: Label


func _ready() -> void:
	add_to_group("touch")
	layer = 20
	_build()
	set_driving(false)


func consume_look() -> Vector2:
	var v := look
	look = Vector2.ZERO
	return v


func consume_interact() -> bool:
	var v := interact_pressed
	interact_pressed = false
	return v


func consume_punch() -> bool:
	var v := punch_pressed
	punch_pressed = false
	return v


func _on_action_down() -> void:
	if driving:
		handbrake = true
	else:
		punch_pressed = true


func _on_action_up() -> void:
	handbrake = false


func set_driving(on: bool) -> void:
	driving = on
	if _gas_btn:
		_gas_btn.visible = on
		_brake_btn.visible = on
	if _punch_btn:
		_punch_btn.visible = true
		_punch_btn.text = "E-BRAKE" if on else "PUNCH"
	if _enter_btn:
		_enter_btn.text = "EXIT" if on else "ENTER"


func set_can_interact(on: bool, label := "") -> void:
	if _enter_btn == null:
		return
	_enter_btn.disabled = not on
	_enter_btn.modulate = Color.WHITE if on else Color(1, 1, 1, 0.35)
	if label != "":
		_enter_btn.text = label


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	_stick_base = _circle(Color(0.08, 0.1, 0.14, 0.45), Vector2(150, 150))
	_stick_base.position = Vector2(36, 0)
	_stick_base.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	_stick_base.offset_left = 36
	_stick_base.offset_top = -210
	_stick_base.offset_right = 186
	_stick_base.offset_bottom = -60
	_root.add_child(_stick_base)

	_stick_knob = _circle(Color(0.94, 0.63, 0.19, 0.85), Vector2(64, 64))
	_stick_knob.position = Vector2(43, 43)
	_stick_base.add_child(_stick_knob)

	_enter_btn = _action_button("ENTER", Vector2(-168, -118))
	_enter_btn.pressed.connect(func() -> void: interact_pressed = true)
	_root.add_child(_enter_btn)

	_gas_btn = _action_button("GAS", Vector2(-168, -220))
	_gas_btn.button_down.connect(func() -> void: gas = true)
	_gas_btn.button_up.connect(func() -> void: gas = false)
	_root.add_child(_gas_btn)

	_brake_btn = _action_button("BRAKE", Vector2(-300, -118))
	_brake_btn.button_down.connect(func() -> void: brake = true)
	_brake_btn.button_up.connect(func() -> void: brake = false)
	_root.add_child(_brake_btn)

	_punch_btn = _action_button("PUNCH", Vector2(-300, -220))
	_punch_btn.button_down.connect(_on_action_down)
	_punch_btn.button_up.connect(_on_action_up)
	_root.add_child(_punch_btn)

	_hint = Label.new()
	_hint.text = "Left stick move · drag right to look"
	_hint.add_theme_font_size_override("font_size", 14)
	_hint.add_theme_color_override("font_color", Color(0.85, 0.82, 0.74, 0.55))
	_hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	_hint.offset_left = -200
	_hint.offset_top = -36
	_hint.offset_right = 200
	_hint.offset_bottom = -12
	_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(_hint)


func _circle(color: Color, size: Vector2) -> Panel:
	var p := Panel.new()
	p.custom_minimum_size = size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.corner_radius_top_left = int(size.x)
	sb.corner_radius_top_right = int(size.x)
	sb.corner_radius_bottom_left = int(size.x)
	sb.corner_radius_bottom_right = int(size.x)
	p.add_theme_stylebox_override("panel", sb)
	return p


func _action_button(text: String, bottom_right: Vector2) -> Button:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(120, 86)
	b.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	b.offset_left = bottom_right.x
	b.offset_top = bottom_right.y
	b.offset_right = bottom_right.x + 120
	b.offset_bottom = bottom_right.y + 86
	b.focus_mode = Control.FOCUS_NONE
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.07, 0.09, 0.12, 0.72)
	sb.border_color = Color("f0a030")
	sb.border_width_left = 2
	sb.border_width_top = 2
	sb.border_width_right = 2
	sb.border_width_bottom = 2
	sb.corner_radius_top_left = 12
	sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12
	sb.corner_radius_bottom_right = 12
	b.add_theme_stylebox_override("normal", sb)
	b.add_theme_font_size_override("font_size", 18)
	b.add_theme_color_override("font_color", Color("f0e6c8"))
	return b


func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		_on_touch(event)
	elif event is InputEventScreenDrag:
		_on_drag(event)
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		# Desktop testing of the stick without a touchscreen.
		var fake := InputEventScreenTouch.new()
		fake.index = 0
		fake.pressed = event.pressed
		fake.position = event.position
		_on_touch(fake)
	elif event is InputEventMouseMotion and _stick_id == 0 and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var drag := InputEventScreenDrag.new()
		drag.index = 0
		drag.position = event.position
		_on_drag(drag)


func _on_touch(event: InputEventScreenTouch) -> void:
	var vp := get_viewport().get_visible_rect().size
	if event.pressed:
		if event.position.x < vp.x * 0.42 and _stick_id < 0:
			_stick_id = event.index
			_stick_origin = event.position
			_place_stick(event.position)
		elif event.position.x > vp.x * 0.55 and not _over_buttons(event.position):
			_look_id = event.index
	else:
		if event.index == _stick_id:
			_stick_id = -1
			move = Vector2.ZERO
			_reset_knob()
		if event.index == _look_id:
			_look_id = -1


func _on_drag(event: InputEventScreenDrag) -> void:
	if event.index == _stick_id:
		var delta := event.position - _stick_origin
		if delta.length() > _max_radius:
			delta = delta.limit_length(_max_radius)
		move = delta / _max_radius
		_stick_knob.position = Vector2(43, 43) + delta * 0.55
	elif event.index == _look_id:
		look += event.relative


func _place_stick(pos: Vector2) -> void:
	_stick_base.global_position = pos - _stick_base.size * 0.5
	_reset_knob()


func _reset_knob() -> void:
	if _stick_knob:
		_stick_knob.position = Vector2(43, 43)


func _over_buttons(pos: Vector2) -> bool:
	for b in [_enter_btn, _gas_btn, _brake_btn, _punch_btn]:
		if b and b.visible and b.get_global_rect().has_point(pos):
			return true
	return false
