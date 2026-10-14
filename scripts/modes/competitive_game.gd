extends Node3D
## Lightweight entry point: no City, traffic, civilians, HDRIs or parked cars.
enum Phase { TITLE, STEAL, HEAT, DELIVER, FREE, BUSTED, WASTED }
const competitive_only := true
var phase := Phase.TITLE
var money := 0
var player: Player
var camera: CameraRig
var touch: TouchControls
var hud: MatchHUD
var clock: ArenaLighting
var matches: MatchManager
var shot_effects: ShotEffects
var active_vehicle: Node3D
var active_aircraft: Node3D
var _firing := false
var _settings := ConfigFile.new()

func _ready() -> void:
	CombatInput.install()
	clock = ArenaLighting.new()
	add_child(clock)
	camera = CameraRig.new()
	camera.add_to_group("camera_rig")
	add_child(camera)
	camera.set_process(false)
	touch = TouchControls.new()
	touch.visible = false
	add_child(touch)
	shot_effects = ShotEffects.new()
	add_child(shot_effects)
	matches = MatchManager.new()
	matches.game = self
	add_child(matches)
	hud = MatchHUD.new()
	add_child(hud)
	matches.announcer.subtitle_changed.connect(hud.set_subtitle)
	_load_settings()
	hud.show_start(true)

func ensure_player() -> void:
	if player != null:
		return
	player = Player.new()
	player.uniform_color = MatchArena.team_color(0) if matches.player_team == 0 else Color.WHITE
	add_child(player)
	player.locked = true
	camera.follow = player
	camera.set_process(true)

func release_player() -> void:
	camera.follow = null
	camera.set_process(false)
	if player:
		remove_child(player)
		player.queue_free()
		player = null

func start_mode(mode: int) -> void:
	if mode not in [MatchRules.Mode.CORRE, MatchRules.Mode.BATTLE]: return
	matches.player_team = hud.selected_team
	matches.start(mode)

func get_wanted() -> int:
	return 0

func _tracked() -> Node3D:
	return player

func radar_objective() -> Vector3:
	if not matches.competitive(): return Vector3.ZERO
	if matches.zone: return matches.zone.center
	return matches.arena.bases[matches.player_team] if matches.rules.carried_by(0) else matches.arena.bases[1 - matches.player_team]

func _unhandled_input(event: InputEvent) -> void:
	if hud.capture_binding(event):
		return
	if event.is_action_pressed("return_menu") and matches.competitive():
		matches.return_menu()
		return
	if not matches.competitive() or player == null:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera.add_look(event.relative)
	if event.is_action_pressed("jump"):
		player.request_jump()
	if event.is_action_pressed("reload"):
		player.request_reload()
	if event.is_action_pressed("interact"):
		matches.interact_player()
	if event.is_action_pressed("drop_objective"):
		matches.rules.drop(0)
	if event.is_action_pressed("swap_shoulder"):
		camera.shoulder *= -1.0
	if event.is_action_pressed("fire"):
		_firing = true
		_try_fire()
	if event.is_action_released("fire"):
		_firing = false
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP: player.cycle_weapon(1)
		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN: player.cycle_weapon(-1)
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: player.select_weapon(Arsenal.Id.PISTOL)
			KEY_2: player.select_weapon(Arsenal.Id.SMG)
			KEY_3: player.select_weapon(Arsenal.Id.RIFLE)
			KEY_F6:
				clock.set_quality((clock.quality + 1) % 3)
				save_settings()
			KEY_ESCAPE:
				matches.return_menu()

func _process(_delta: float) -> void:
	if player == null or not matches.competitive(): return
	var look := touch.consume_look()
	if look != Vector2.ZERO: camera.add_look(look, true)
	if touch.consume_jump(): player.request_jump()
	if touch.consume_interact(): matches.interact_player()
	if touch.reload_pressed:
		touch.reload_pressed = false
		player.request_reload()
	if touch.crouch_pressed:
		touch.crouch_pressed = false
		player.request_crouch()
	if touch.firing and not touch.was_firing: _try_fire()
	touch.was_firing = touch.firing
	if (_firing or touch.firing) and player.weapon != Arsenal.Id.NONE and Arsenal.data(player.weapon).automatic:
		_try_fire()

func _try_fire() -> void:
	if player == null or matches.rules.state != MatchRules.State.ACTIVE:
		return
	var shot := player.spend_shot()
	if shot.is_empty(): return
	var data := Arsenal.data(player.weapon)
	var cam := camera.camera()
	var spread := data.spread * (data.ads_spread_multiplier if player.aiming else 1.0)
	if player.velocity.length() > 0.5: spread *= data.moving_spread_multiplier
	var direction := -cam.global_basis.z + cam.global_basis.x * randf_range(-spread, spread) + cam.global_basis.y * randf_range(-spread, spread)
	var muzzle := player.global_position + Vector3.UP * (0.95 if player.crouched else 1.4)
	var result := Hitscan.cast(get_world_3d(), cam.global_position, direction, muzzle, data.effective_range, [player.get_rid()])
	var hit: Dictionary = result.hit
	if hit and hit.collider is Player:
		var height: float = hit.position.y - hit.collider.global_position.y
		var multiplier := data.head_multiplier if height > 1.3 else (data.limb_multiplier if height < 0.6 else 1.0)
		if matches.apply_hit(0, hit.collider, data.damage * multiplier):
			hud.confirm_hit()
			if height > 1.3: matches.bus.publish("HEADSHOT", {"participant": 0})
	shot_effects.emit_shot(muzzle, result.end)
	camera.kick(data)

func _load_settings() -> void:
	if _settings.load("user://competitive_settings.cfg") != OK: return
	clock.set_quality(int(_settings.get_value("settings", "quality", 0)))
	matches.announcer.enabled = bool(_settings.get_value("settings", "announcer", true))
	matches.announcer.volume_db = float(_settings.get_value("settings", "voice_db", -6.0))
	camera.mouse_sens = float(_settings.get_value("settings", "mouse_sens", 0.0032))
	camera.ads_sensitivity = float(_settings.get_value("settings", "ads_sens", 0.55))
	if not _settings.has_section("bindings"): return
	for action in _settings.get_section_keys("bindings"):
		if InputMap.has_action(action):
			InputMap.action_erase_events(action)
			for event in _settings.get_value("bindings", action): InputMap.action_add_event(action, event)

func save_settings() -> void:
	_settings.set_value("settings", "quality", clock.quality)
	_settings.set_value("settings", "announcer", matches.announcer.enabled)
	_settings.set_value("settings", "voice_db", matches.announcer.volume_db)
	_settings.set_value("settings", "mouse_sens", camera.mouse_sens)
	_settings.set_value("settings", "ads_sens", camera.ads_sensitivity)
	for action in ["move_left", "move_right", "move_forward", "move_back", "jump", "sprint", "aim", "fire", "reload", "crouch", "swap_shoulder", "tactical_sprint", "interact", "drop_objective", "return_menu"]:
		_settings.set_value("bindings", action, InputMap.action_get_events(action))
	_settings.save("user://competitive_settings.cfg")
