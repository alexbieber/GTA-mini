extends SceneTree
var checks := 0
var failures := 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: " + label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	var game = load("res://scenes/competitive_main.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	var network := LanMultiplayerManager.new()
	network.game = game
	network.name = "AuthorityTestNetwork"
	game.add_child(network)
	check(network.host(27849, "Host", 1) == OK, "ENet host creates native UDP authority")
	check(not network.start_match(MatchRules.Mode.CORRE), "unready lobby cannot start")
	network.set_ready(true)
	check(network.start_match(MatchRules.Mode.CORRE), "ready lobby starts team map with bot fill")
	network.set_process(false)
	# Isolated malicious-message fixture: no nonexistent network peer RPC is sent.
	network.members[2] = {"name": "Remote", "team": 0, "ready": true}
	var slot := 5
	network.peer_slots[2] = slot
	network._replace_bot(slot)
	check(game.matches.actors[slot] is LanRemotePlayer and game.matches.rules.participants[slot].team == 0, "peer owns a remote body in selected team")
	game.matches.rules.tick(4.0)
	for actor: Player in game.matches.actors.values(): actor.set_physics_process(false)
	check(not network.accept_intent(33, 1, Vector2.ZERO, Vector2.ZERO, false, false, false), "unregistered sender cannot control a player")
	check(not network.accept_intent(2, 1, Vector2(999, 0), Vector2.ZERO, false, false, false), "server rejects invalid movement magnitude")
	check(not network.accept_intent(2, 1, Vector2.ZERO, Vector2(NAN, 0), false, false, false), "server rejects non-finite aim")
	check(network.accept_intent(2, 1, Vector2(0, -1), Vector2.ZERO, true, false, false), "valid intent updates server-owned remote input")
	check(not network.accept_intent(2, 1, Vector2.ZERO, Vector2.ZERO, false, false, false), "replayed movement sequence is rejected")
	check(not network.accept_action(2, "damage", 10000), "client cannot declare damage")
	check(not network.accept_action(2, "position", 10000), "client cannot teleport")
	check(not network.accept_action(2, "score", 10000), "client cannot declare points")
	check(not network.accept_action(2, "weapon", 999), "unowned weapon cannot be equipped")
	var actor: Player = game.matches.actors[slot]
	actor.magazines[actor.weapon] = 0
	check(not network.accept_action(2, "fire", 0), "empty magazine prevents a network shot")
	check(network.accept_action(2, "reload", 0), "server accepts reload with actual reserve")
	var before := int(actor.ammo[actor.weapon])
	actor.tick_combat(4.0)
	check(actor.magazines[actor.weapon] > 0 and actor.ammo[actor.weapon] < before, "network reload transfers ammunition only after server timer")
	var snapshot := network.make_snapshot()
	check(snapshot.actors[slot].magazines == actor.magazines and snapshot.actors[slot].armor == actor.vitality.armor, "snapshot includes authoritative ammunition and armor")
	check(snapshot.objectives.size() == 2 and snapshot.participants.size() == 10, "snapshot carries both flags and all participants")
	var flag_id := "1:flag"
	var flag: ObjectiveState = game.matches.rules.objectives[flag_id]
	check(not network.accept_action(2, "interact", 0) and flag.state == ObjectiveState.Status.AT_BASE, "remote interaction cannot steal distant flag")
	actor.global_position = flag.position
	game.matches.rules.participants[slot].position = actor.global_position
	network._action_times.clear()
	check(network.accept_action(2, "interact", 0) and flag.carrier == slot, "server validates nearby enemy flag interaction")
	var peer_members := network.members.duplicate(true)
	network.leave()
	game.matches.return_menu()
	await process_frame
	check(not network.active and not network.match_active and network.members.is_empty(), "leaving restores offline transport and clears lobby")
	check(peer_members.size() == 2, "lobby record is copied before cleanup")
	print("LAN_AUTHORITY_RESULT: %d checks, %d failures" % [checks, failures])
	root.remove_child(game)
	game.queue_free()
	await create_timer(0.3).timeout
	quit(1 if failures else 0)

