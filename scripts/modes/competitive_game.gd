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
var master_volume := 1.0
var _pending_shot := 0.0
var _last_sprint_press := -1000

func _ready() -> void:
	CombatInput.install()
	clock = ArenaLighting.new()
	add_child(clock)
	camera = CameraRig.new()
	camera.add_to_group("camera_rig")
	add_child(camera)
	camera.arm_length = 5.0
	camera.set_first_person(true)
	camera.camera().far = 280.0
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
	if player: player.set_first_person_visual(false)
	camera.follow = null
	camera._view_model.visible = false
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
	if event.is_action_pressed("armor_plate"):
		player.request_plate()
	if event.is_action_pressed("camera_view"):
		camera.set_first_person(not camera.first_person)
		save_settings()
	if event.is_action_pressed("sprint") and not event.is_echo():
		var now := Time.get_ticks_msec()
		if now - _last_sprint_press < 300: player.request_tactical_sprint()
		_last_sprint_press = now
	if event.is_action_pressed("reload"):
		player.request_reload()
	if event.is_action_pressed("interact"):
		matches.interact_player()
	if event.is_action_pressed("melee"):
		matches.melee(0)
	if event.is_action_pressed("drop_objective"):
		matches.rules.drop(0)
	if event.is_action_pressed("swap_shoulder"):
		camera.shoulder *= -1.0
	if event.is_action_pressed("fire"):
		_firing = true
		_try_fire()
	if event.is_action_released("fire"):
		_firing = false
	if event.is_action_pressed("cycle_weapon_up"): player.cycle_weapon(1)
	if event.is_action_pressed("cycle_weapon_down"): player.cycle_weapon(-1)
	for action in {"weapon_1": Arsenal.Id.PISTOL, "weapon_2": Arsenal.Id.SMG, "weapon_3": Arsenal.Id.RIFLE, "weapon_4": Arsenal.Id.SHOTGUN}:
		if event.is_action_pressed(action):
			player.select_weapon({"weapon_1": Arsenal.Id.PISTOL, "weapon_2": Arsenal.Id.SMG, "weapon_3": Arsenal.Id.RIFLE, "weapon_4": Arsenal.Id.SHOTGUN}[action])
	if event.is_action_pressed("graphics_profile"):
		clock.set_quality((clock.quality + 1) % 3)
		save_settings()
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				matches.return_menu()

func _process(delta: float) -> void:
	if player == null or not matches.competitive(): return
	var look := touch.consume_look()
	if look != Vector2.ZERO: camera.add_look(look, true)
	if touch.consume_jump(): player.request_jump()
	if touch.consume_interact(): matches.interact_player()
	if touch.consume_punch(): matches.melee(0)
	if touch.plate_pressed:
		touch.plate_pressed = false
		player.request_plate()
	if touch.view_pressed:
		touch.view_pressed = false
		camera.set_first_person(not camera.first_person)
		save_settings()
	if touch.reload_pressed:
		touch.reload_pressed = false
		player.request_reload()
	if touch.crouch_pressed:
		touch.crouch_pressed = false
		player.request_crouch()
	if touch.cover_pressed:
		touch.cover_pressed = false
		player.request_cover()
	if touch.firing and not touch.was_firing: _try_fire()
	touch.was_firing = touch.firing
	if (_firing or touch.firing) and player.weapon != Arsenal.Id.NONE and Arsenal.data(player.weapon).automatic:
		_try_fire()
	if _pending_shot > 0.0:
		_pending_shot = maxf(_pending_shot - delta, 0.0)
		_try_fire()

func _try_fire() -> void:
	if player == null or matches.rules.state != MatchRules.State.ACTIVE:
		return
	var cam := camera.camera()
	var shot := WeaponSystem.fire(self, player, 0, cam.global_position, -cam.global_basis.z)
	if not shot.fired:
		if player.sprint_to_fire_remaining > 0.0: _pending_shot = 0.25
		return
	_pending_shot = 0.0

func _load_settings() -> void:
	if _settings.load("user://competitive_settings.cfg") != OK: return
	clock.set_quality(int(_settings.get_value("settings", "quality", 0)))
	matches.announcer.enabled = bool(_settings.get_value("settings", "announcer", true))
	matches.announcer.volume_db = float(_settings.get_value("settings", "voice_db", -6.0))
	camera.mouse_sens = float(_settings.get_value("settings", "mouse_sens", 0.0032))
	camera.ads_sensitivity = float(_settings.get_value("settings", "ads_sens", 0.55))
	set_master_volume(float(_settings.get_value("settings", "master_volume", 1.0)))
	camera.set_first_person(bool(_settings.get_value("settings", "first_person", true)))
	camera.first_person_fov = clampf(float(_settings.get_value("settings", "fov", 86.0)), 70.0, 110.0)
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
	_settings.set_value("settings", "master_volume", master_volume)
	_settings.set_value("settings", "first_person", camera.first_person)
	_settings.set_value("settings", "fov", camera.first_person_fov)
	for action in MatchHUD.ACTION_LABELS:
		_settings.set_value("bindings", action, InputMap.action_get_events(action))
	_settings.save("user://competitive_settings.cfg")

func set_master_volume(value: float) -> void:
	master_volume = clampf(value, 0.0, 1.0)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), linear_to_db(maxf(master_volume, 0.0001)))

func reset_trigger() -> void:
	_firing = false
	_pending_shot = 0.0
	_last_sprint_press = -1000
