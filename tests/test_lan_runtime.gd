extends SceneTree
## Execute concurrently in two native processes: -- host / -- client.
var checks := 0
var failures := 0
var game: Node3D
var network: LanMultiplayerManager
var role := "host"
var elapsed := 0.0
var steps: Dictionary = {}
var start_z := 8.0
var remote_id := -1
var snapshots := 0
var client_initial_position := Vector3.ZERO
var client_moved := false
var client_ammo_changed := false
var client_flag_carried := false
var client_finished := false
var last_intent := 0

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty(): role = args[0]
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS [%s]: %s" % [role, label])
	else:
		failures += 1
		push_error("FAIL [%s]: %s" % [role, label])

func run() -> void:
	game = load("res://scenes/competitive_main.tscn").instantiate()
	game.name = "LanRuntimeGame"
	root.add_child(game)
	current_scene = game
	await process_frame
	# Dedicated test node uses identical RPC paths in host and client processes.
	network = LanMultiplayerManager.new()
	network.game = game
	network.name = "LanRuntimeNetwork"
	game.add_child(network)
	network.snapshot_received.connect(on_snapshot)
	network.match_entered.connect(on_match)
	if role == "host":
		check(network.host(27847, "Host teste", 1) == OK, "host ENet listening")
		network.set_ready(true)
	else:
		check(network.join("127.0.0.1", 27847, "Cliente teste", 0) == OK, "client opens ENet transport")
		network.lobby_changed.connect(func(members: Dictionary) -> void:
			var own: Dictionary = members.get(network.multiplayer.get_unique_id(), {})
			if not own.is_empty() and not own.ready: network.set_ready(true))
	while elapsed < 15.0:
		await process_frame
		elapsed += root.get_process_delta_time()
		if role == "host": tick_host()
		else: tick_client()
		if steps.has("done"): break
	if not steps.has("done"): check(false, "two-process test completed before deadline")
	network.leave()
	if game.matches.competitive(): game.matches.return_menu()
	print("LAN_RUNTIME_%s_RESULT: %d checks, %d failures, %d snapshots" % [role.to_upper(), checks, failures, snapshots])
	root.remove_child(game)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)

func on_match(_mode: int) -> void:
	if role == "client":
		network.set_process(false) # Test sends a deterministic intent stream instead of keyboard polling.
		check(network.is_client() and network.local_participant != 0, "remote begin assigns participant independently of host")

func tick_host() -> void:
	if not network.match_active:
		if network.members.size() != 2: return
		for member in network.members.values():
			if not member.ready: return
		game.matches.rules.config = game.matches.rules.config.duplicate()
		game.matches.rules.config.countdown_seconds = 0.15
		game.matches.rules.config.respawn_seconds = 0.3
		check(network.start_match(MatchRules.Mode.CORRE), "ready remote client starts CTF")
		for peer_id in network.peer_slots:
			if peer_id != 1: remote_id = network.peer_slots[peer_id]
		for id in game.matches.actors:
			var actor: Player = game.matches.actors[id]
			if id != remote_id: actor.set_physics_process(false)
		game.player.global_position = Vector3(0, 0.1, 0)
		game.player.vitality.regeneration_per_second = 0.0
		game.player.vitality.armor = 0.0
		game.matches.actors[remote_id].global_position = Vector3(0, 0.1, start_z)
		return
	var time: float = game.matches.rules.elapsed
	if time > 3.0 and not steps.has("combat"):
		steps.combat = true
		var remote: Player = game.matches.actors[remote_id]
		check(remote.global_position.z < start_z - 0.5, "client intent moves collision body on server")
		check(network.accepted_shots >= 1 and game.player.health < 100.0, "remote shot spends server ammo and damages real host body")
		check(int(remote.magazines[remote.weapon]) < Arsenal.data(remote.weapon).magazine_size, "server retains authoritative magazine count")
		check(network.rejected_packets >= 1, "malicious client combat request rejected")
		remote.global_position = game.matches.rules.objectives["1:flag"].position
		game.matches.rules.participants[remote_id].position = remote.global_position
	if time > 4.6 and not steps.has("flag"):
		steps.flag = true
		check(game.matches.rules.carried_by(remote_id) != null, "remote E interaction captures enemy flag on server")
		game.matches.actors[remote_id].global_position = game.matches.arena.bases[0]
	if time > 5.3 and not steps.has("score"):
		steps.score = true
		check(game.matches.rules.score[0] == 1, "server scores flag returned to own protected base")
		game.matches.apply_hit(-1, game.matches.actors[remote_id], 1000.0, true)
	if time > 6.0 and not steps.has("respawn"):
		steps.respawn = true
		check(game.matches.rules.participants[remote_id].alive and game.matches.rules.participants[remote_id].deaths == 1, "network participant eliminates and respawns on authority")
		game.matches.rules.finish(0)
	if time > 6.0 and elapsed > 10.0 and not steps.has("done"):
		check(network.members.size() == 2, "both peers remain connected through round end")
		steps.done = true

func tick_client() -> void:
	if not network.match_active: return
	var time: float = game.matches.rules.elapsed
	if Time.get_ticks_msec() - last_intent > 33:
		last_intent = Time.get_ticks_msec()
		network.send_intent(Vector2(0, -1) if time < 0.8 else Vector2.ZERO, Vector2(0.0, 0.03), time < 0.8, true, false)
	if time > 1.2 and not steps.has("shoot1"):
		steps.shoot1 = true
		network.submit_action("fire")
		network.submit_action("damage", 99999)
	if time > 1.8 and not steps.has("shoot2"):
		steps.shoot2 = true
		network.submit_action("fire")
	if time > 3.5 and not steps.has("interact"):
		steps.interact = true
		network.submit_action("interact")
	if client_finished and elapsed > 9.0:
		check(snapshots >= 30, "client receives regular authority snapshots over ENet")
		check(client_moved, "client local proxy follows server-owned movement")
		check(client_ammo_changed, "client HUD inventory receives spent ammunition")
		check(client_flag_carried, "flag carrier ID remaps to local participant on client")
		check(game.matches.rules.score[0] == 1, "client receives authoritative team score")
		check(game.matches.rules.winner == 0 and game.matches.rules.state == MatchRules.State.FINISHED, "client receives final victory state")
		steps.done = true

func on_snapshot(state: Dictionary) -> void:
	snapshots += 1
	if client_initial_position == Vector3.ZERO: client_initial_position = game.player.global_position
	if game.player.global_position.distance_to(client_initial_position) > 0.5: client_moved = true
	if game.player.weapon != Arsenal.Id.NONE and game.player.magazines[game.player.weapon] < Arsenal.data(game.player.weapon).magazine_size: client_ammo_changed = true
	if game.matches.rules.carried_by(0) != null: client_flag_carried = true
	if state.state == MatchRules.State.FINISHED: client_finished = true
