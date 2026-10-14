class_name CombatInput
extends RefCounted
## Add defaults only when missing so saved/custom InputMap bindings win.
static func install() -> void:
	var keys := {"move_left": KEY_A, "move_right": KEY_D, "move_forward": KEY_W,
		"move_back": KEY_S, "jump": KEY_SPACE, "sprint": KEY_SHIFT,
		"crouch": KEY_CTRL, "reload": KEY_R, "swap_shoulder": KEY_Q,
		"tactical_sprint": KEY_T, "interact": KEY_E,
		"return_menu": KEY_TAB, "drop_objective": KEY_G}
	keys["cover"] = KEY_C
	keys["weapon_1"] = KEY_1
	keys["weapon_2"] = KEY_2
	keys["weapon_3"] = KEY_3
	keys["graphics_profile"] = KEY_F6
	keys["melee"] = KEY_F
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.device = 0
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	var mouse_buttons := {"fire": MOUSE_BUTTON_LEFT, "aim": MOUSE_BUTTON_RIGHT, "cycle_weapon_up": MOUSE_BUTTON_WHEEL_UP, "cycle_weapon_down": MOUSE_BUTTON_WHEEL_DOWN}
	for action in mouse_buttons:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.device = 0
		event.button_index = mouse_buttons[action]
		InputMap.action_add_event(action, event)
