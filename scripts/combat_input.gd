class_name CombatInput
extends RefCounted
## Add defaults only when missing so saved/custom InputMap bindings win.
static func install() -> void:
	var keys := {"move_left": KEY_A, "move_right": KEY_D, "move_forward": KEY_W,
		"move_back": KEY_S, "jump": KEY_SPACE, "sprint": KEY_SHIFT,
		"crouch": KEY_CTRL, "reload": KEY_R, "swap_shoulder": KEY_Q,
		"tactical_sprint": KEY_T, "interact": KEY_E}
	for action in keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventKey.new()
		event.device = 0
		event.physical_keycode = keys[action]
		InputMap.action_add_event(action, event)
	for action in ["fire", "aim"]:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var event := InputEventMouseButton.new()
		event.device = 0
		event.button_index = MOUSE_BUTTON_LEFT if action == "fire" else MOUSE_BUTTON_RIGHT
		InputMap.action_add_event(action, event)
