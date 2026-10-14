class_name Hitscan
extends RefCounted
## Camera chooses target; the physical muzzle ray decides what is hit.
static func cast(world: World3D, camera_origin: Vector3, direction: Vector3, muzzle: Vector3, distance: float, excluded: Array[RID]) -> Dictionary:
	var space := world.direct_space_state
	var target := camera_origin + direction.normalized() * distance
	var query := PhysicsRayQueryParameters3D.create(camera_origin, target, 1 | 4 | 8 | 16, excluded)
	query.hit_from_inside = true
	var camera_hit := space.intersect_ray(query)
	if camera_hit:
		target = camera_hit.position
	query = PhysicsRayQueryParameters3D.create(muzzle, muzzle + (target - muzzle).normalized() * minf(distance, muzzle.distance_to(target)), 1 | 4 | 8 | 16, excluded)
	query.hit_from_inside = true
	var hit := space.intersect_ray(query)
	return {"hit": hit, "end": hit.position if hit else query.to, "origin": muzzle}
