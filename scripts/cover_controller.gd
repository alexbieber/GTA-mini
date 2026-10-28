class_name CoverController
extends RefCounted
## Static geometry validation. Physics and muzzle obstruction remain authoritative.
static func detect(actor: CharacterBody3D) -> Dictionary:
	var from := actor.global_position + Vector3.UP * 0.85
	var direction := -actor.global_basis.z
	var query := PhysicsRayQueryParameters3D.create(from, from + direction * 1.6, 1, [actor.get_rid()])
	var space := actor.get_world_3d().direct_space_state
	var hit := space.intersect_ray(query)
	if not hit or not hit.collider is StaticBody3D or absf(hit.normal.y) > 0.25:
		return {}
	query.from = actor.global_position + Vector3.UP * 1.55
	query.to = query.from + direction * 1.6
	var high := space.intersect_ray(query)
	return {"normal": hit.normal, "point": hit.position, "low": high.is_empty()}

static func retains_contact(actor: CharacterBody3D, normal: Vector3) -> bool:
	var from := actor.global_position + Vector3.UP * 0.8
	var query := PhysicsRayQueryParameters3D.create(from, from - normal * 1.1, 1, [actor.get_rid()])
	var hit := actor.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty() and hit.normal.dot(normal) > 0.85
