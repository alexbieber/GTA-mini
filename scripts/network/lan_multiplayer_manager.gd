class_name LanMultiplayerManager
extends Node
## ENet listen server, lobby and intent-only client protocol. No Node RPC payloads.
signal lobby_changed(members: Dictionary)
signal status_changed(message: String)
signal match_entered(mode: int)
signal snapshot_received(snapshot: Dictionary)
const RemoteBody = preload("res://scripts/network/lan_remote_player.gd")
const DEFAULT_PORT := 27841
const MAX_PLAYERS := 10
const PROTOCOL := 1
const SNAPSHOT_INTERVAL := 0.1
var game: Node3D
var members: Dictionary = {}
var peer_slots: Dictionary = {}
var local_participant := 0
var active := false
var match_active := false
var status := "Offline"
var rejected_packets := 0
var accepted_shots := 0
var _name := "Jogador"
var _team := 1
var _snapshot_time := 0.0
var _input_time := 0.0
var _sequence := 0
var _sequences: Dictionary = {}
var _action_times: Dictionary = {}
var _last_snapshot := -1
var _snapshot_sequence := 0
var _client_finished := false
var _closing := false

func _ready() -> void:
	multiplayer.peer_connected.connect(_peer_connected)
	multiplayer.peer_disconnected.connect(_peer_disconnected)
	multiplayer.connected_to_server.connect(_connected)
	multiplayer.connection_failed.connect(_connection_failed)
	multiplayer.server_disconnected.connect(_server_disconnected)

func is_server() -> bool:
	return active and multiplayer.is_server()

func is_client() -> bool:
	return active and not multiplayer.is_server()

func host(port := DEFAULT_PORT, player_name := "Host", team := 1) -> Error:
	leave()
	if port < 1024 or port > 65535: return ERR_INVALID_PARAMETER
	var transport := ENetMultiplayerPeer.new()
	var result := transport.create_server(port, MAX_PLAYERS - 1)
	if result != OK:
		_set_status("Não foi possível abrir a porta LAN: %s" % error_string(result))
		return result
	multiplayer.multiplayer_peer = transport
	active = true
	members[1] = {"name": player_name.left(24), "team": clampi(team, 0, 1), "ready": false}
	_set_status("Lobby LAN aberto na porta %d" % port)
	lobby_changed.emit(members.duplicate(true))
	return OK

func join(address: String, port := DEFAULT_PORT, player_name := "Jogador", team := 1) -> Error:
	leave()
	if address.strip_edges().is_empty() or port < 1024 or port > 65535: return ERR_INVALID_PARAMETER
	_name = player_name.left(24)
	_team = clampi(team, 0, 1)
	var transport := ENetMultiplayerPeer.new()
	var result := transport.create_client(address, port)
	if result != OK: return result
	multiplayer.multiplayer_peer = transport
	active = true
	_set_status("Conectando a %s:%d…" % [address, port])
	return OK

func leave() -> void:
	_closing = true
	if active:
		multiplayer.multiplayer_peer.close()
		multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	active = false
	match_active = false
	members.clear()
	peer_slots.clear()
	_sequences.clear()
	_action_times.clear()
	_sequence = 0
	_snapshot_sequence = 0
	_last_snapshot = -1
	_client_finished = false
	if game and game.get("matches"):
		game.matches.set_process(true)
	_closing = false
	_set_status("Offline")

func choose_team(team: int) -> void:
	if team not in [0, 1] or not active or match_active: return
	if is_server():
		members[1].team = team
		_broadcast_lobby()
	else: _lobby_request.rpc_id(1, PROTOCOL, _name, team, false)

func set_ready(ready: bool) -> void:
	if not active or match_active: return
	if is_server():
		members[1].ready = ready
		_broadcast_lobby()
	else:
		var own: Dictionary = members.get(multiplayer.get_unique_id(), {})
		_lobby_request.rpc_id(1, PROTOCOL, _name, int(own.get("team", _team)), ready)

func start_match(mode: int) -> bool:
	if not is_server() or match_active or game == null or mode not in [MatchRules.Mode.CORRE, MatchRules.Mode.BATTLE]: return false
	var capacity := 10 if mode == MatchRules.Mode.CORRE else 8
	if members.size() > capacity: return false
	var teams := [0, 0]
	for member in members.values():
		if not member.ready: return false
		teams[int(member.team)] += 1
	if mode == MatchRules.Mode.CORRE and (teams[0] > 5 or teams[1] > 5):
		_set_status("Cada equipe aceita até cinco jogadores.")
		return false
	game.matches.player_team = members[1].team
	game.matches.start(mode)
	peer_slots[1] = 0
	var used := [0]
	for peer_id in members:
		if peer_id == 1: continue
		var slot := -1
		for id in game.matches.actors:
			if used.has(id): continue
			if mode == MatchRules.Mode.CORRE and game.matches.rules.participants[id].team != members[peer_id].team: continue
			slot = id
			break
		if slot < 0:
			_set_status("Não há vaga para a equipe selecionada.")
			return false
		used.append(slot)
		peer_slots[peer_id] = slot
		_replace_bot(slot)
		game.matches.rules.participants[slot].name = members[peer_id].name
	game.matches.rules.participants[0].name = members[1].name
	match_active = true
	_client_finished = false
	if not game.matches.bus.occurred.is_connected(_relay_event): game.matches.bus.occurred.connect(_relay_event)
	for peer_id in peer_slots:
		if peer_id != 1: _begin_match.rpc_id(peer_id, mode, peer_slots[peer_id], members[peer_id].team)
	_set_status("Partida LAN em andamento")
	match_entered.emit(mode)
	return true

func _replace_bot(slot: int) -> void:
	var previous: Player = game.matches.actors[slot]
	var actor: Player = RemoteBody.new()
	actor.uniform_color = MatchArena.team_color(game.matches.rules.participants[slot].team)
	game.matches.arena.add_child(actor)
	actor.global_position = previous.global_position
	actor.vitality.reset()
	actor.configure_tactical(game.matches.tactical_config)
	actor.vitality.armor = previous.vitality.armor
	actor.owned_weapons.assign(previous.owned_weapons)
	actor.ammo = previous.ammo.duplicate()
	actor.magazines = previous.magazines.duplicate()
	actor.weapon = previous.weapon
	actor.locked = true
	game.matches.actors[slot] = actor
	previous.get_parent().remove_child(previous)
	previous.queue_free()

func _connected() -> void:
	_lobby_request.rpc_id(1, PROTOCOL, _name, _team, false)
	_set_status("Conectado ao lobby LAN")

func _peer_connected(_peer_id: int) -> void:
	pass # Admission waits for a validated protocol message.

func _peer_disconnected(peer_id: int) -> void:
	if not is_server(): return
	members.erase(peer_id)
	if peer_slots.has(peer_id) and match_active:
		var id: int = peer_slots[peer_id]
		game.matches.rules.eliminate(id, -1)
		game.matches.rules.participants[id].respawn = -1.0
		game.matches._remove_actor(id)
	peer_slots.erase(peer_id)
	_broadcast_lobby()

func _connection_failed() -> void:
	leave()
	_set_status("Conexão LAN falhou; confirme IP e porta do host.")

func _server_disconnected() -> void:
	if _closing: return
	leave()
	if game and game.matches.competitive(): game.matches.return_menu()
	_set_status("O host encerrou a conexão LAN.")

func _set_status(message: String) -> void:
	status = message
	status_changed.emit(message)

func _broadcast_lobby() -> void:
	if not is_server(): return
	lobby_changed.emit(members.duplicate(true))
	_lobby_state.rpc(members)

@rpc("any_peer", "call_remote", "reliable")
func _lobby_request(protocol: int, player_name: String, team: int, ready: bool) -> void:
	if not is_server(): return
	var sender := multiplayer.get_remote_sender_id()
	if protocol != PROTOCOL or team not in [0, 1] or sender <= 1 or match_active or (not members.has(sender) and members.size() >= MAX_PLAYERS):
		rejected_packets += 1
		multiplayer.multiplayer_peer.disconnect_peer(sender)
		return
	members[sender] = {"name": player_name.strip_edges().left(24), "team": team, "ready": ready}
	_broadcast_lobby()

@rpc("authority", "call_remote", "reliable")
func _lobby_state(roster: Dictionary) -> void:
	if not is_client(): return
	members = roster.duplicate(true)
	lobby_changed.emit(members.duplicate(true))

@rpc("authority", "call_remote", "reliable")
func _begin_match(mode: int, slot: int, team: int) -> void:
	if not is_client() or game == null: return
	local_participant = slot
	game.matches.player_team = team
	game.matches.start(mode)
	game.matches.set_process(false)
	for actor: Player in game.matches.actors.values(): actor.set_physics_process(false)
	match_active = true
	_client_finished = false
	_last_snapshot = -1
	_set_status("Partida LAN: servidor controla movimento e combate")
	match_entered.emit(mode)

func _process(delta: float) -> void:
	if not active or not match_active or game == null: return
	if is_client():
		_input_time -= delta
		if _input_time <= 0.0:
			_input_time = 1.0 / 30.0
			send_intent(Input.get_vector("move_left", "move_right", "move_forward", "move_back"), Vector2(game.camera.yaw, game.camera.pitch), Input.is_action_pressed("sprint"), Input.is_action_pressed("aim"), Input.is_action_pressed("fire"))
	else:
		for id in peer_slots.values():
			if id == 0: continue
			var actor = game.matches.actors.get(id)
			if actor is LanRemotePlayer and actor.fire_intent and actor.weapon != Arsenal.Id.NONE and Arsenal.data(actor.weapon).automatic: _fire(id)
		_snapshot_time -= delta
		if _snapshot_time <= 0.0:
			_snapshot_time = SNAPSHOT_INTERVAL
			_snapshot_sequence += 1
			_snapshot.rpc(_snapshot_sequence, make_snapshot())

func send_intent(move: Vector2, view: Vector2, sprint: bool, aim: bool, fire: bool) -> void:
	if not is_client() or not match_active: return
	_sequence += 1
	_intent.rpc_id(1, _sequence, move, view, sprint, aim, fire)

@rpc("any_peer", "call_remote", "unreliable_ordered", 1)
func _intent(sequence: int, move: Vector2, view: Vector2, sprint: bool, aim: bool, fire: bool) -> void:
	if not is_server(): return
	accept_intent(multiplayer.get_remote_sender_id(), sequence, move, view, sprint, aim, fire)

func accept_intent(peer_id: int, sequence: int, move: Vector2, view: Vector2, sprint: bool, aim: bool, fire: bool) -> bool:
	if not match_active or not peer_slots.has(peer_id) or peer_id == 1 or sequence <= int(_sequences.get(peer_id, -1)) or not move.is_finite() or not view.is_finite() or move.length_squared() > 1.21 or absf(view.y) > 1.5:
		rejected_packets += 1
		return false
	_sequences[peer_id] = sequence
	var actor = game.matches.actors.get(peer_slots[peer_id])
	if not actor is LanRemotePlayer: return false
	actor.move_intent = move.limit_length()
	actor.view_yaw = wrapf(view.x, -PI, PI)
	actor.view_pitch = clampf(view.y, -1.45, 1.45)
	actor.sprint_intent = sprint
	actor.aim_intent = aim
	actor.fire_intent = fire
	actor.last_input_ms = Time.get_ticks_msec()
	return true

func submit_action(action: String, value := 0) -> void:
	if is_client() and match_active: _action.rpc_id(1, action, value)

@rpc("any_peer", "call_remote", "reliable", 2)
func _action(action: String, value: int) -> void:
	if not is_server(): return
	accept_action(multiplayer.get_remote_sender_id(), action, value)

func accept_action(peer_id: int, action: String, value: int) -> bool:
	if not match_active or not peer_slots.has(peer_id) or peer_id == 1 or game.matches.rules.state != MatchRules.State.ACTIVE:
		rejected_packets += 1
		return false
	var id: int = peer_slots[peer_id]
	var actor: Player = game.matches.actors[id]
	if not game.matches.rules.participants[id].alive or actor.locked: return false
	var now := Time.get_ticks_msec()
	var limiter := "%d:%s" % [peer_id, action]
	if now - int(_action_times.get(limiter, -1000)) < 40: return false
	_action_times[limiter] = now
	match action:
		"fire": return _fire(id)
		"reload": return actor.request_reload()
		"jump": actor.request_jump()
		"crouch": actor.request_crouch()
		"cover": return actor.request_cover()
		"plate": return actor.request_plate()
		"tactical_sprint": return actor.request_tactical_sprint()
		"melee": return game.matches.melee(id)
		"drop": return game.matches.rules.drop(id)
		"weapon": return actor.select_weapon(value)
		"cycle": actor.cycle_weapon(clampi(value, -1, 1))
		"interact":
			if game.matches.zone: return game.matches._collect_loot(id)
			for item in game.matches.rules.objectives.values():
				if game.matches.rules.interact(id, item.id): return true
			var team: int = game.matches.rules.participants[id].team
			if actor.global_position.distance_to(game.matches.arena.bases[team]) < 5.0 and game.matches.rules.carried_by(id) == null:
				actor.ammo[actor.weapon] = maxi(int(actor.ammo.get(actor.weapon, 0)), 120)
				actor.add_plates(game.matches.tactical_config.plate_capacity)
				return true
			return false
		_:
			rejected_packets += 1
			return false
	return true

func _fire(id: int) -> bool:
	if game.matches.rules.state != MatchRules.State.ACTIVE or not game.matches.rules.participants[id].alive: return false
	var actor: LanRemotePlayer = game.matches.actors[id] as LanRemotePlayer
	if actor == null: return false
	var eye := actor.global_position + Vector3.UP * (0.95 if actor.crouched else 1.55)
	var basis := Basis(Vector3.UP, actor.view_yaw) * Basis(Vector3.RIGHT, actor.view_pitch)
	var result := WeaponSystem.fire(game, actor, id, eye, -basis.z)
	if not result.fired: return false
	for trace in result.get("traces", []): _shot_effect.rpc(id, actor.weapon, trace.from, trace.to, trace.impacted)
	if not result.hits.is_empty(): _hit_confirm.rpc_id(_peer_for_slot(id))
	accepted_shots += 1
	return true

func _peer_for_slot(slot: int) -> int:
	for peer_id in peer_slots:
		if peer_slots[peer_id] == slot: return peer_id
	return 1

@rpc("authority", "call_remote", "unreliable", 5)
func _hit_confirm() -> void:
	if is_client() and game: game.hud.confirm_hit()

func make_snapshot() -> Dictionary:
	var result: Dictionary = game.matches.rules.snapshot()
	result.countdown = game.matches.rules.countdown
	result.actors = {}
	for id in game.matches.actors:
		var actor: Player = game.matches.actors[id]
		result.actors[id] = {"position": actor.global_position, "rotation": actor.rotation.y, "velocity": actor.velocity, "health": actor.health, "armor": actor.vitality.armor, "plates": actor.armor_plates, "stamina": actor.stamina, "weapon": actor.weapon, "owned": actor.owned_weapons.duplicate(), "ammo": actor.ammo.duplicate(), "magazines": actor.magazines.duplicate(), "reload": actor.reload_remaining, "plate": actor.plate_remaining, "aiming": actor.aiming, "crouched": actor.crouched, "locked": actor.locked, "visible": actor.visible, "sprinting": actor.sprinting, "slide": actor.slide_remaining, "tactical": actor.tactical_remaining, "vault": actor.vault_remaining, "combat": actor.combat_remaining, "movement_state": actor.movement_state}
	result.loot = []
	for item in game.matches._loot: result.loot.append(item.available)
	if game.matches.zone:
		var zone = game.matches.zone
		result.zone = {"center": zone.center, "radius": zone.radius, "phase": zone.phase, "remaining": zone.remaining, "closing": zone.closing, "next_center": zone.next_center, "next_radius": zone.next_radius}
	return result

func _client_id(server_id: int) -> int:
	if server_id == local_participant: return 0
	if server_id == 0: return local_participant
	return server_id

@rpc("authority", "call_remote", "unreliable_ordered", 3)
func _snapshot(sequence: int, state: Dictionary) -> void:
	if not is_client() or not match_active or sequence <= _last_snapshot: return
	_last_snapshot = sequence
	apply_snapshot(state)
	snapshot_received.emit(state)

func apply_snapshot(state: Dictionary) -> void:
	var rules: MatchRules = game.matches.rules
	rules.state = int(state.state)
	rules.score = state.score.duplicate()
	rules.remaining = state.remaining
	rules.elapsed = state.elapsed
	rules.countdown = state.countdown
	rules.winner = _client_id(state.winner) if rules.mode == MatchRules.Mode.BATTLE and state.winner >= 0 else int(state.winner)
	rules.participants.clear()
	for server_id in state.participants:
		var member: Dictionary = state.participants[server_id].duplicate(true)
		var id := _client_id(server_id)
		member.id = id
		rules.participants[id] = member
	for server_id in state.actors:
		var id := _client_id(server_id)
		if not game.matches.actors.has(id): continue
		var actor: Player = game.matches.actors[id]
		var data: Dictionary = state.actors[server_id]
		actor.global_position = data.position
		actor.rotation.y = data.rotation
		actor.velocity = data.velocity
		actor.health = data.health
		actor.vitality.armor = data.armor
		actor.armor_plates = data.plates
		actor.stamina = data.stamina
		actor.weapon = data.weapon
		actor.owned_weapons.assign(data.owned)
		actor.ammo = data.ammo.duplicate()
		actor.magazines = data.magazines.duplicate()
		actor.reload_remaining = data.reload
		actor.plate_remaining = data.plate
		actor.aiming = data.aiming
		actor.sprinting = data.sprinting
		actor.slide_remaining = data.slide
		actor.tactical_remaining = data.tactical
		actor.vault_remaining = data.vault
		actor.combat_remaining = data.combat
		actor.movement_state = data.movement_state
		actor.set_crouched(data.crouched)
		actor.locked = data.locked
		actor.visible = data.visible
		actor._update_skin()
		if actor._visual: actor._visual.scale.y = actor._visual_scale.y * (0.65 if actor.crouched else 1.0)
		if actor._gun: actor._gun.visible = actor.weapon != Arsenal.Id.NONE and not actor.first_person_visual
	rules.objectives.clear()
	for data in state.objectives:
		var objective := ObjectiveState.new()
		for key in data: objective.set(key, data[key])
		objective.carrier = _client_id(objective.carrier) if objective.carrier >= 0 else -1
		rules.objectives[objective.id] = objective
	game.matches.arena.sync_objectives(rules.objectives)
	for i in mini(state.loot.size(), game.matches._loot.size()):
		game.matches._loot[i].available = state.loot[i]
		game.matches._loot[i].mesh.visible = state.loot[i]
	if state.has("zone") and game.matches.zone:
		for key in state.zone: game.matches.zone.set(key, state.zone[key])
		game.matches.arena.sync_zone(game.matches.zone.center, game.matches.zone.radius)
	game.matches._update_hud()
	if rules.state == MatchRules.State.FINISHED and not _client_finished:
		_client_finished = true
		game.matches._on_event("MATCH_FINISHED", {"winner": rules.winner, "mode": rules.mode})

func _relay_event(event: String, payload: Dictionary) -> void:
	if is_server() and match_active and event != "MATCH_FINISHED": _match_event.rpc(event, payload)

@rpc("authority", "call_remote", "reliable", 4)
func _match_event(event: String, payload: Dictionary) -> void:
	if not is_client() or not match_active: return
	var mapped := payload.duplicate(true)
	for key in ["participant", "killer", "victim"]:
		if mapped.has(key) and mapped[key] >= 0: mapped[key] = _client_id(mapped[key])
	game.matches.announcer.on_event(event, mapped)
	if event == "ELIMINATION":
		game.hud.add_elimination("%s → %s" % [payload.killer_name, payload.victim_name])
		if mapped.killer == 0: game.hud.set_banner("ELIMINAÇÃO CONFIRMADA")

@rpc("authority", "call_remote", "unreliable", 5)
func _shot_effect(id: int, weapon: int, from: Vector3, to: Vector3, impacted: bool) -> void:
	if not is_client() or not match_active: return
	game.shot_effects.emit_shot(from, to, impacted)
	if id == local_participant: game.camera.kick(Arsenal.data(weapon))
