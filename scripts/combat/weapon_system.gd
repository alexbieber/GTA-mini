class_name WeaponSystem
extends RefCounted
## The same authoritative shot path serves local input and LAN remote actors.
static func fire(game: Node3D, shooter: Player, participant: int, origin: Vector3, direction: Vector3) -> Dictionary:
	var shot := shooter.spend_shot()
	if shot.is_empty(): return {"fired": false, "hits": [], "traces": []}
	var data := Arsenal.data(shooter.weapon)
	var spread := data.spread * (data.ads_spread_multiplier if shooter.aiming else 1.0)
	if shooter.velocity.length() > 0.5: spread *= data.moving_spread_multiplier
	var forward := direction.normalized()
	var right := forward.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.1: right = Vector3.RIGHT
	var up := right.cross(forward).normalized()
	var muzzle := shooter.global_position + Vector3.UP * (0.95 if shooter.crouched else 1.4)
	var targets: Array[int] = []
	var traces: Array[Dictionary] = []
	for pellet in data.pellet_count:
		var ray := (forward + right * randf_range(-spread, spread) + up * randf_range(-spread, spread)).normalized()
		var result := Hitscan.cast(game.get_world_3d(), origin, ray, muzzle, data.effective_range, [shooter.get_rid()])
		var hit: Dictionary = result.hit
		if hit and hit.collider is Player:
			var height: float = hit.position.y - hit.collider.global_position.y
			var head := 0.82 if hit.collider.crouched else 1.3
			var multiplier := data.head_multiplier if height > head else (data.limb_multiplier if height < 0.4 else 1.0)
			if game.matches.apply_hit(participant, hit.collider, data.damage_at(muzzle.distance_to(hit.position)) * multiplier):
				var target: int = game.matches.participant_for(hit.collider)
				if not targets.has(target): targets.append(target)
				if height > head: game.matches.bus.publish("HEADSHOT", {"participant": participant})
		game.shot_effects.emit_shot(muzzle, result.end, not hit.is_empty())
		traces.append({"from": muzzle, "to": result.end, "impacted": not hit.is_empty()})
	if participant == 0: game.camera.kick(data)
	game.matches.bus.publish("SHOT_FIRED", {"participant": participant, "position": muzzle})
	return {"fired": true, "hits": targets, "traces": traces}
