extends Node3D

enum Phase { TITLE, STEAL, HEAT, DELIVER, FREE, BUSTED, WASTED }

var phase: Phase = Phase.TITLE
var money := 420
var packages_left := 3
var _stolen := false
var _bust_timer := 0.0
var _end_timer := 0.0
var _spray_cd := 0.0
var _last_wanted := 0

var city: City
var clock: DayNight
var heat: WantedSystem
var player: Player
var camera: CameraRig
var hud: GameHUD
var touch: TouchControls
var coupe: Vehicle
var active_vehicle: Vehicle
var active_aircraft: Aircraft
var cops: Array[Vehicle] = []
var _crate_taken: Array[Vector3] = []
var _base_cd := 0.0
var _firing := false
var beacon: MeshInstance3D
var last_seen_mark: Marker3D
var roads: RoadGraph


func get_wanted() -> int:
	return heat.stars if heat else 0


func radar_objective() -> Vector3:
	match phase:
		Phase.STEAL:
			return coupe.global_position if coupe else Vector3.ZERO
		Phase.DELIVER:
			return city.garage_pos
		Phase.HEAT:
			return Vector3.ZERO
		_:
			if packages_left > 0:
				return city.package_spawns[0] if city.package_spawns.size() else Vector3.ZERO
			return Vector3.ZERO


func _ready() -> void:
	randomize()
	city = City.new()
	add_child(city)
	city.build()
	roads = city.make_graph()

	clock = DayNight.new()
	add_child(clock)
	clock.bind(city)

	heat = WantedSystem.new()
	add_child(heat)

	last_seen_mark = Marker3D.new()
	add_child(last_seen_mark)

	camera = CameraRig.new()
	camera.add_to_group("camera_rig")
	add_child(camera)

	hud = GameHUD.new()
	add_child(hud)

	touch = TouchControls.new()
	touch.visible = false
	add_child(touch)

	player = Player.new()
	add_child(player)
	player.global_position = city.player_spawn
	player.locked = true
	camera.follow = player

	coupe = Vehicle.new()
	coupe.kind = Vehicle.Kind.COUPE
	add_child(coupe)
	coupe.setup(Vehicle.Kind.COUPE, city.coupe_spawn, city.coupe_facing)
	coupe.bind_graph(roads)

	for parked in city.parked_spawns:
		var v := Vehicle.new()
		v.kind = Vehicle.Kind.PARKED
		add_child(v)
		v.setup(Vehicle.Kind.PARKED, parked["pos"], parked["yaw"])
		v.bind_graph(roads)

	for i in city.cop_spawns.size():
		_make_cop(city.cop_spawns[i], i)

	for i in city.traffic_spawns.size():
		var t := Vehicle.new()
		t.kind = Vehicle.Kind.CIVILIAN
		add_child(t)
		var spec: Dictionary = city.traffic_spawns[i]
		t.setup(Vehicle.Kind.CIVILIAN, spec["pos"], spec["yaw"])
		t.patrol = city.patrol
		t.patrol_i = (i + 2) % city.patrol.size()
		t.bind_graph(roads)

	_spawn_peds()
	_spawn_pickups()
	_spawn_base_units()
	_make_beacon()
	clock.apply(false)
	hud.set_time_of_day(false)
	_sync_hud()


func _make_cop(pos: Vector3, idx: int) -> Vehicle:
	var cop := Vehicle.new()
	cop.kind = Vehicle.Kind.COP
	add_child(cop)
	cop.setup(Vehicle.Kind.COP, pos, PI)
	cop.patrol = city.patrol
	cop.patrol_i = idx % city.patrol.size()
	cop.chase_slot = idx
	cop.bind_graph(roads)
	cops.append(cop)
	return cop


func _spawn_peds() -> void:
	const PEDS_PER_PATH := 6
	for path_i in city.sidewalk_paths.size():
		var raw: Array = city.sidewalk_paths[path_i]
		var typed: Array[Vector3] = []
		for p in raw:
			typed.append(p)
		for n in PEDS_PER_PATH:
			var ped := Pedestrian.new()
			add_child(ped)
			ped.setup(typed, n, PEDS_PER_PATH)


func _spawn_base_units() -> void:
	for spec in city.military_spawns:
		var v := Vehicle.new()
		v.kind = Vehicle.Kind.MILITARY
		add_child(v)
		v.setup(Vehicle.Kind.MILITARY, spec["pos"], spec["yaw"])
		v.bind_graph(roads)
	for spec in city.aircraft_spawns:
		var jet := Aircraft.new()
		add_child(jet)
		jet.setup(spec["pos"], spec["yaw"])
	var patrol_base: Array[Vector3] = [
		city.base_pos + Vector3(-16, 0.15, 12),
		city.base_pos + Vector3(16, 0.15, 16),
		city.base_pos + Vector3(10, 0.15, -8),
		city.base_pos + Vector3(-12, 0.15, -4),
	]
	for n in 4:
		var ped := Pedestrian.new()
		ped.is_officer = true
		add_child(ped)
		ped.setup(patrol_base, n, 4)


func _spawn_pickups() -> void:
	for pos in city.package_spawns:
		var pk := WorldPickup.new()
		add_child(pk)
		pk.setup(WorldPickup.Kind.PACKAGE, pos, 180)
	for pos in city.health_spawns:
		var hp := WorldPickup.new()
		add_child(hp)
		hp.setup(WorldPickup.Kind.HEALTH, pos, 40)


func begin() -> void:
	if phase != Phase.TITLE:
		return
	phase = Phase.STEAL
	player.locked = false
	touch.visible = DisplayServer.is_touchscreen_available()
	hud.show_start(false)
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_sync_hud()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_N:
		clock.toggle()
		hud.set_time_of_day(clock.is_night)
	if phase == Phase.TITLE:
		if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
			begin()
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera.add_look(event.relative)
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if not DisplayServer.is_touchscreen_available() and phase not in [Phase.TITLE, Phase.BUSTED, Phase.WASTED]:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if event is InputEventKey and event.pressed and event.keycode == KEY_E:
		_try_interact()
	if event is InputEventKey and event.pressed and event.keycode == KEY_F:
		_try_punch()
	if event is InputEventKey and event.pressed and event.keycode == KEY_R and phase in [Phase.BUSTED, Phase.WASTED]:
		_respawn()
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_firing = true
		_try_fire()
	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_firing = false
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
		player.cycle_weapon(1)
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		player.cycle_weapon(-1)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_weapon_or_buy(Arsenal.Id.PISTOL)
			KEY_2:
				_weapon_or_buy(Arsenal.Id.SMG)
			KEY_3:
				_weapon_or_buy(Arsenal.Id.RIFLE)
			KEY_4:
				if city.near_gun_shop(player.global_position) and not player.in_vehicle:
					_buy_ammo()


func _process(delta: float) -> void:
	var look := touch.consume_look()
	if look != Vector2.ZERO:
		camera.add_look(look, true)
	if touch.consume_interact():
		if phase == Phase.TITLE:
			begin()
		elif phase in [Phase.BUSTED, Phase.WASTED]:
			_respawn()
		else:
			_try_interact()
	if touch.consume_punch():
		_try_punch()

	if phase in [Phase.BUSTED, Phase.WASTED]:
		_end_timer += delta
		return
	if phase == Phase.TITLE:
		return

	_spray_cd = maxf(_spray_cd - delta, 0.0)
	_update_crimes(delta)
	_update_wanted(delta)
	_update_cops()
	_update_civilians()
	_update_mission()
	_check_services()
	_check_busted(delta)
	_check_wasted()
	_update_beacon()
	_update_base(delta)
	if _firing and player.weapon == Arsenal.Id.SMG:
		_try_fire()
	_sync_hud()


func _try_interact() -> void:
	if player.locked:
		return
	if active_aircraft:
		_exit_aircraft()
		return
	if active_vehicle:
		_exit_vehicle()
		return
	if city.near_bar(player.global_position):
		_use_bar()
		return
	if _try_crate():
		return
	var jet := _nearest_aircraft()
	if jet:
		_enter_aircraft(jet)
		return
	var nearest := _nearest_enterable()
	if nearest:
		_enter_vehicle(nearest)


func _try_punch() -> void:
	if player.locked or player.in_vehicle:
		return
	var officer := player.try_punch_officer()
	if officer:
		_report("assault_cop", officer.global_position)
		_scare_nearby(officer.global_position)
		return
	var hit := player.try_punch()
	if hit:
		_scare_nearby(hit.global_position)
		_report("assault", hit.global_position)


func _nearest_enterable() -> Vehicle:
	var best: Vehicle = null
	var best_d := 4.6
	for node in get_tree().get_nodes_in_group("vehicles"):
		var v := node as Vehicle
		if v == null or v.occupied or v.wrecked:
			continue
		var d := player.global_position.distance_to(v.global_position)
		if d < best_d:
			best_d = d
			best = v
	return best


func _enter_vehicle(v: Vehicle) -> void:
	var driver := v.eject_driver()
	if driver:
		player.locked = true
		get_tree().create_timer(0.28).timeout.connect(func() -> void:
			if is_instance_valid(player):
				player.locked = false
		)
	active_vehicle = v
	v.occupied = true
	v.ai_enabled = false
	v.fleeing = false
	player.in_vehicle = true
	player.set_hidden(true)
	camera.follow = v
	camera.set_vehicle_mode(true)
	touch.set_driving(true)
	if v.kind == Vehicle.Kind.COUPE and not _stolen:
		_stolen = true
		v.stolen = true
		_report("jack_mission", v.global_position)
		phase = Phase.HEAT
	elif v.kind == Vehicle.Kind.COP:
		_report("jack_cop", v.global_position)
	elif v.kind == Vehicle.Kind.PARKED:
		_report("alarm", v.global_position)
	elif v.kind == Vehicle.Kind.MILITARY:
		_report("trespass", v.global_position)
	else:
		_report("jack", v.global_position)


func _nearest_aircraft() -> Aircraft:
	var best: Aircraft = null
	var best_d := 9.5
	for node in get_tree().get_nodes_in_group("aircraft"):
		var jet := node as Aircraft
		if jet == null or not jet.can_board(player):
			continue
		var d := player.global_position.distance_to(jet.global_position)
		if d < best_d:
			best_d = d
			best = jet
	return best


func _enter_aircraft(jet: Aircraft) -> void:
	active_aircraft = jet
	jet.occupied = true
	player.in_vehicle = true
	player.set_hidden(true)
	camera.follow = jet
	camera.set_aircraft_mode(true)
	touch.set_driving(true)
	_report("steal_jet", jet.global_position)


func _exit_aircraft() -> void:
	if active_aircraft == null:
		return
	if abs(active_aircraft.speed) > 8.0 or active_aircraft.global_position.y > 3.5:
		hud.set_prompt("Land and slow down to exit")
		return
	var jet := active_aircraft
	player.global_position = jet.global_position + jet.global_transform.basis.x * 4.2 + Vector3(0, 0.2, 0)
	player.rotation.y = jet.rotation.y
	jet.occupied = false
	player.in_vehicle = false
	player.set_hidden(false)
	active_aircraft = null
	camera.follow = player
	camera.set_aircraft_mode(false)
	touch.set_driving(false)


func _use_bar() -> void:
	if money < 40:
		hud.set_banner("BAR  ·  $40 needed")
		get_tree().create_timer(1.4).timeout.connect(func() -> void: hud.set_banner(""))
		return
	money -= 40
	player.heal(40.0)
	player.stamina = 100.0
	hud.set_banner("WHISKEY  -$40")
	get_tree().create_timer(1.5).timeout.connect(func() -> void: hud.set_banner(""))


func _try_crate() -> bool:
	for pos in city.crate_spawns:
		if pos in _crate_taken:
			continue
		if player.global_position.distance_to(pos) < 2.4:
			_crate_taken.append(pos)
			player.give_weapon(Arsenal.Id.RIFLE, 60)
			_report("steal_arms", pos)
			hud.set_banner("SERVICE RIFLE")
			get_tree().create_timer(1.6).timeout.connect(func() -> void: hud.set_banner(""))
			return true
	return false


func _weapon_or_buy(id: int) -> void:
	if city.near_gun_shop(player.global_position) and not player.in_vehicle:
		_buy_weapon(id)
	else:
		player.select_weapon(id)


func _buy_weapon(id: int) -> void:
	var spec := Arsenal.spec(id)
	var price: int = spec["price"]
	if player.owned_weapons.has(id):
		_buy_ammo()
		return
	if money < price:
		hud.set_banner("$%d needed" % price)
		get_tree().create_timer(1.3).timeout.connect(func() -> void: hud.set_banner(""))
		return
	money -= price
	player.give_weapon(id)
	hud.set_banner("%s  -$%d" % [spec["name"], price])
	get_tree().create_timer(1.5).timeout.connect(func() -> void: hud.set_banner(""))


func _buy_ammo() -> void:
	if player.weapon == Arsenal.Id.NONE:
		hud.set_banner("Buy a gun first")
		get_tree().create_timer(1.2).timeout.connect(func() -> void: hud.set_banner(""))
		return
	if money < Arsenal.ammo_price():
		hud.set_banner("$80 needed")
		get_tree().create_timer(1.2).timeout.connect(func() -> void: hud.set_banner(""))
		return
	money -= Arsenal.ammo_price()
	player.add_ammo(int(Arsenal.spec(player.weapon)["ammo"]))
	hud.set_banner("AMMO  -$80")
	get_tree().create_timer(1.3).timeout.connect(func() -> void: hud.set_banner(""))


func _try_fire() -> void:
	if player.locked or player.in_vehicle or phase in [Phase.TITLE, Phase.BUSTED, Phase.WASTED]:
		return
	var spec := player.spend_shot()
	if spec.is_empty():
		return
	var cam := camera.camera()
	if cam == null:
		return
	var origin := cam.global_position
	var dir := -cam.global_transform.basis.z
	dir += cam.global_transform.basis.x * randf_range(-spec["spread"], spec["spread"])
	dir += cam.global_transform.basis.y * randf_range(-spec["spread"], spec["spread"])
	dir = dir.normalized()
	var dest := origin + dir * float(spec["range"])
	var q := PhysicsRayQueryParameters3D.create(origin, dest, 1 | 4 | 8 | 16)
	q.exclude = [player.get_rid()]
	var hit := get_world_3d().direct_space_state.intersect_ray(q)
	var end := dest
	if hit:
		end = hit.position
		var col = hit.collider
		if col is Pedestrian:
			var ped := col as Pedestrian
			ped.knock_down()
			_scare_nearby(ped.global_position)
			if ped.is_officer:
				_report("shoot_cop", ped.global_position)
			else:
				_report("gunfire", ped.global_position)
		elif col is Vehicle:
			var v := col as Vehicle
			v.apply_damage(float(spec["dmg"]))
			if v.kind == Vehicle.Kind.COP:
				_report("shoot_cop", v.global_position)
			else:
				_report("gunfire", v.global_position)
		else:
			_report("gunfire", end)
	else:
		_report("gunfire", player.global_position)
	_tracer(origin + dir * 1.2, end)
	camera.add_shake(0.035)


func _tracer(from: Vector3, to: Vector3) -> void:
	var mesh := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var mat := Palette.mat(Color("fff2c0"), 0.0, 0.2, Color("fff2c0"), 6.0)
	im.surface_begin(Mesh.PRIMITIVE_LINES, mat)
	im.surface_add_vertex(from)
	im.surface_add_vertex(to)
	im.surface_end()
	mesh.mesh = im
	add_child(mesh)
	get_tree().create_timer(0.06).timeout.connect(mesh.queue_free)


func _update_base(delta: float) -> void:
	_base_cd = maxf(_base_cd - delta, 0.0)
	if _base_cd > 0.0 or player.in_vehicle:
		return
	if city.on_base(player.global_position):
		_base_cd = 6.0
		_report("trespass", player.global_position)


func _exit_vehicle() -> void:
	if active_vehicle == null:
		return
	if abs(active_vehicle.speed) > 6.0:
		return
	var v := active_vehicle
	player.global_position = v.global_position + v.global_transform.basis.x * 1.8 + Vector3(0, 0.1, 0)
	player.rotation.y = v.rotation.y
	v.occupied = false
	if v.kind == Vehicle.Kind.COP or v.kind == Vehicle.Kind.CIVILIAN:
		v.ai_enabled = true
	player.in_vehicle = false
	player.set_hidden(false)
	active_vehicle = null
	camera.follow = player
	camera.set_vehicle_mode(false)
	touch.set_driving(false)


func _report(crime: String, pos: Vector3) -> void:
	var added := heat.report(crime, _witnessed(pos))
	if added > 0:
		hud.set_crime(heat.label())


func _witnessed(pos: Vector3) -> bool:
	for cop in cops:
		if cop.global_position.distance_to(pos) < 46.0 and WantedSystem.has_los(get_world_3d(), cop.global_position, pos):
			return true
	for node in get_tree().get_nodes_in_group("peds"):
		var ped := node as Pedestrian
		if ped and not ped.downed and ped.global_position.distance_to(pos) < 11.0:
			return true
	return false


func _update_crimes(_delta: float) -> void:
	if active_vehicle == null:
		return
	if active_vehicle.last_impact > 8.0:
		camera.add_shake(active_vehicle.last_impact * 0.012)
		player.take_damage(active_vehicle.last_impact * 0.15)
		active_vehicle.last_impact = 0.0
	if abs(active_vehicle.speed) < 7.0:
		return
	for node in get_tree().get_nodes_in_group("peds"):
		var ped := node as Pedestrian
		if ped == null or ped.downed:
			continue
		if active_vehicle.global_position.distance_to(ped.global_position) < 1.9:
			ped.knock_down()
			_scare_nearby(ped.global_position)
			_report("hit_ped", ped.global_position)
			active_vehicle.apply_damage(10.0)
			player.take_damage(4.0)
	for i in range(active_vehicle.get_slide_collision_count()):
		var col := active_vehicle.get_slide_collision(i)
		var other := col.get_collider()
		if other is Vehicle:
			var ov := other as Vehicle
			if ov.kind == Vehicle.Kind.COP and abs(active_vehicle.speed) > 8.0:
				_report("ram_cop", active_vehicle.global_position)
			elif ov.kind != Vehicle.Kind.COP and abs(active_vehicle.speed) > 10.0:
				_report("ram_civ", active_vehicle.global_position)
				ov.fleeing = true


func _scare_nearby(pos: Vector3) -> void:
	for node in get_tree().get_nodes_in_group("peds"):
		var ped := node as Pedestrian
		if ped and pos.distance_to(ped.global_position) < 16.0:
			ped.scare(pos)


func _update_wanted(delta: float) -> void:
	var seen := _cops_can_see()
	heat.tick(delta, seen, _tracked().global_position)
	if heat.stars != _last_wanted:
		if heat.stars > _last_wanted:
			hud.page("DISPATCH  ·  %s  ·  %d units" % [heat.label(), heat.cop_count()])
			_scare_nearby(_tracked().global_position)
		_last_wanted = heat.stars
		if heat.stars == 0:
			hud.set_crime("")


func _cops_can_see() -> bool:
	var target := _tracked()
	var world := get_world_3d()
	for cop in cops:
		var d := cop.global_position.distance_to(target.global_position)
		if d > 52.0:
			continue
		if not WantedSystem.has_los(world, cop.global_position, target.global_position):
			continue
		var to := (target.global_position - cop.global_position)
		to.y = 0.0
		var fwd := -cop.global_transform.basis.z
		fwd.y = 0.0
		if d < 14.0 or fwd.dot(to.normalized()) > 0.12:
			return true
	for node in get_tree().get_nodes_in_group("foot_cops"):
		var foot := node as Pedestrian
		if foot and not foot.downed and foot.global_position.distance_to(player.global_position) < 16.0:
			if WantedSystem.has_los(world, foot.global_position, player.global_position):
				return true
	return false


func _update_cops() -> void:
	var need := heat.cop_count()
	while cops.size() < need:
		var spawn: Vector3 = city.patrol[cops.size() % city.patrol.size()]
		var me := _tracked().global_position
		if spawn.distance_to(me) < 22.0:
			spawn = city.patrol[(cops.size() + 3) % city.patrol.size()]
		_make_cop(spawn, cops.size())
	var target := _tracked()
	last_seen_mark.global_position = heat.last_seen
	for cop in cops:
		if cop.occupied:
			continue
		cop.ai_enabled = true
		cop.chase_slot = cops.find(cop)
		if heat.stars <= 0:
			cop.chase_target = null
		elif heat.in_sight:
			cop.chase_target = target
			cop.ai_max_speed = 56.0 + float(heat.stars) * 2.4
		elif heat.searching():
			cop.chase_target = last_seen_mark
		else:
			cop.chase_target = null


func _update_civilians() -> void:
	var hot := heat.stars > 0
	for node in get_tree().get_nodes_in_group("vehicles"):
		var v := node as Vehicle
		if v == null or v.occupied:
			continue
		if v.kind == Vehicle.Kind.CIVILIAN or v.kind == Vehicle.Kind.PARKED:
			if hot and v.kind == Vehicle.Kind.CIVILIAN:
				v.fleeing = true
				v.ai_enabled = true


func _tracked() -> Node3D:
	if active_aircraft:
		return active_aircraft
	if active_vehicle:
		return active_vehicle
	return player


func _update_mission() -> void:
	if phase == Phase.HEAT and heat.stars == 0 and _stolen:
		phase = Phase.DELIVER
	elif phase == Phase.DELIVER and heat.stars > 0:
		phase = Phase.HEAT
	if _stolen and city.garage_contains(coupe) and heat.stars == 0 and phase == Phase.DELIVER:
		phase = Phase.FREE
		money += 800
		player.locked = false
		hud.set_banner("DROP COMPLETE  +$800")
		get_tree().create_timer(2.4).timeout.connect(func() -> void: hud.set_banner(""))


func _check_services() -> void:
	if active_vehicle == null or _spray_cd > 0.0:
		return
	if city.spray_contains(active_vehicle) and abs(active_vehicle.speed) < 3.0:
		if money >= 200:
			money -= 200
			heat.clear()
			active_vehicle.repair()
			_spray_cd = 4.0
			hud.set_banner("RESPRAY  -$200")
			get_tree().create_timer(1.8).timeout.connect(func() -> void: hud.set_banner(""))
		else:
			hud.set_prompt("Spray shop  ·  $200 needed")


func _check_busted(delta: float) -> void:
	if heat.stars <= 0 or player.in_vehicle or active_aircraft:
		_bust_timer = 0.0
		return
	var close := false
	for cop in cops:
		if cop.global_position.distance_to(player.global_position) < 2.8:
			close = true
			break
	for node in get_tree().get_nodes_in_group("foot_cops"):
		var foot := node as Pedestrian
		if foot and not foot.downed and foot.global_position.distance_to(player.global_position) < 1.55:
			close = true
			_bust_timer += delta * 0.6
	if close:
		_bust_timer += delta
		if _bust_timer >= 1.35:
			_set_down(Phase.BUSTED, "BUSTED")
	else:
		_bust_timer = 0.0


func _check_wasted() -> void:
	if player.health <= 0.0 and phase not in [Phase.BUSTED, Phase.WASTED]:
		_set_down(Phase.WASTED, "WASTED")


func _set_down(p: Phase, banner: String) -> void:
	phase = p
	player.locked = true
	if active_vehicle:
		active_vehicle.occupied = false
		active_vehicle.speed = 0.0
		active_vehicle = null
	if active_aircraft:
		active_aircraft.occupied = false
		active_aircraft.speed = 0.0
		active_aircraft = null
	player.in_vehicle = false
	player.set_hidden(false)
	touch.set_driving(false)
	camera.set_aircraft_mode(false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.set_banner(banner)
	_end_timer = 0.0


func _respawn() -> void:
	var fine := 250 if phase == Phase.BUSTED else 150
	money = maxi(money - fine, 0)
	heat.clear()
	player.health = 100.0
	player.stamina = 100.0
	player.locked = false
	if phase == Phase.BUSTED:
		player.global_position = city.station_pos + Vector3(0, 0.2, 4)
	else:
		player.global_position = city.hospital_pos + Vector3(0, 0.2, 4)
	camera.follow = player
	camera.set_vehicle_mode(false)
	phase = Phase.FREE if _stolen else Phase.STEAL
	hud.set_banner("")
	if not DisplayServer.is_touchscreen_available():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	hud.set_crime("")


func collect_pickup(kind: int, amount: int) -> void:
	if kind == WorldPickup.Kind.HEALTH:
		player.heal(float(amount))
		hud.set_banner("HEALTH")
	elif kind == WorldPickup.Kind.CASH:
		money += amount
		hud.set_banner("+$%d" % amount)
	elif kind == WorldPickup.Kind.PACKAGE:
		money += amount
		packages_left = maxi(packages_left - 1, 0)
		hud.set_banner("PACKAGE  +$%d" % amount)
	get_tree().create_timer(1.4).timeout.connect(func() -> void: hud.set_banner(""))


func _sync_hud() -> void:
	hud.set_wanted(heat.stars)
	var spd := -1.0
	if active_aircraft:
		spd = absf(active_aircraft.speed)
	elif active_vehicle:
		spd = absf(active_vehicle.speed)
	hud.set_stats(player.health, money, player.weapon_label(), spd)
	var near := _nearest_enterable()
	var jet := _nearest_aircraft()
	if active_aircraft:
		var can_land: bool = abs(active_aircraft.speed) <= 8.0 and active_aircraft.global_position.y <= 3.5
		touch.set_can_interact(can_land, "EXIT")
		if can_land:
			hud.set_prompt("E  ·  EXIT JET    WASD fly    mouse pitch")
		else:
			hud.set_prompt("Land and slow down to exit    HP %d" % int(active_aircraft.hp))
	elif active_vehicle:
		var can_exit: bool = abs(active_vehicle.speed) <= 6.0
		touch.set_can_interact(can_exit, "EXIT")
		if city.spray_contains(active_vehicle):
			hud.set_prompt("Hold still  ·  respray $200")
		elif can_exit:
			hud.set_prompt("E  ·  EXIT    Space  ·  e-brake    HP %d" % int(active_vehicle.hp))
		else:
			hud.set_prompt("Slow down to exit")
	elif city.near_gun_shop(player.global_position):
		touch.set_can_interact(false, "BUY")
		hud.set_prompt("1 pistol $250   2 SMG $600   3 rifle $900   4 ammo $80")
	elif city.near_bar(player.global_position):
		touch.set_can_interact(true, "DRINK")
		hud.set_prompt("E  ·  WHISKEY $40  ·  heals you")
	elif city.near_base_gate(player.global_position):
		touch.set_can_interact(false, "BASE")
		hud.set_prompt("Drive through the open BASE gate  ·  amber arch")
	elif jet:
		touch.set_can_interact(true, "FLY")
		hud.set_prompt("E  ·  BOARD  " + jet.display_name)
	elif city.near_crate(player.global_position) and not player.in_vehicle:
		touch.set_can_interact(true, "TAKE")
		hud.set_prompt("E  ·  TAKE  RIFLE CRATE")
	elif near:
		touch.set_can_interact(true, "ENTER")
		hud.set_prompt("E  ·  GET IN  " + near.display_name + "    click  ·  SHOOT")
	else:
		touch.set_can_interact(false, "ENTER")
		var gun := "    click  ·  SHOOT" if player.weapon != Arsenal.Id.NONE else ""
		hud.set_prompt(("F  ·  PUNCH" + gun) if phase != Phase.TITLE else "")

	match phase:
		Phase.TITLE:
			hud.set_objective("")
			hud.set_distance(-1.0, "")
		Phase.STEAL:
			hud.set_objective("Steal the amber coupe")
			hud.set_distance(player.global_position.distance_to(coupe.global_position), "COUPE")
		Phase.HEAT:
			hud.set_objective("Lose the harbor units")
			hud.set_distance(-1.0, "")
		Phase.DELIVER:
			hud.set_objective("Drop the coupe at the warehouse")
			hud.set_distance(_tracked().global_position.distance_to(city.garage_pos), "WAREHOUSE")
		Phase.FREE:
			if packages_left > 0:
				hud.set_objective("District open  ·  north streets  ·  BASE gate  ·  %d packages" % packages_left)
				hud.set_distance(_tracked().global_position.distance_to(city.base_pos), "BASE")
			else:
				hud.set_objective("District open  ·  ARMS / BAR / BASE on the radar")
				hud.set_distance(_tracked().global_position.distance_to(city.base_pos), "BASE")
		Phase.BUSTED:
			hud.set_objective("Busted  ·  you lose $250")
			hud.set_prompt("R  ·  RELEASE")
			touch.set_can_interact(true, "OUT")
		Phase.WASTED:
			hud.set_objective("Wasted  ·  hospital bill $150")
			hud.set_prompt("R  ·  WAKE UP")
			touch.set_can_interact(true, "UP")


func _make_beacon() -> void:
	beacon = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.38
	sphere.height = 0.76
	beacon.mesh = sphere
	beacon.material_override = Palette.mat(Palette.amber(), 0.15, 0.25, Palette.amber(), 4.5)
	beacon.visible = false
	add_child(beacon)


func _update_beacon() -> void:
	if beacon == null:
		return
	var dest := radar_objective()
	if dest == Vector3.ZERO:
		beacon.visible = false
		return
	beacon.visible = true
	dest.y += 2.7 + sin(float(Time.get_ticks_msec()) * 0.004) * 0.28
	beacon.global_position = dest
