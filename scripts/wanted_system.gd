class_name WantedSystem
extends Node

const MAX_STARS := 5

var heat := 0.0
var stars := 0
var last_crime := ""
var last_seen := Vector3.ZERO
var in_sight := false
var _decay := 0.0
var _search := 0.0
var _crime_cd := 0.0
var just_ranked := 0


func report(crime: String, witnessed: bool) -> int:
	if _crime_cd > 0.0 and crime == last_crime:
		return 0
	var add := 0.0
	match crime:
		"jack":
			add = 22.0 if witnessed else 0.0
		"jack_mission":
			add = 42.0
		"jack_cop":
			add = 48.0
		"hit_ped":
			add = 26.0 if witnessed else 8.0
		"ram_civ":
			add = 18.0 if witnessed else 0.0
		"ram_cop":
			add = 30.0
		"assault":
			add = 20.0 if witnessed else 0.0
		"assault_cop":
			add = 40.0
		"alarm":
			add = 16.0 if witnessed else 0.0
		"gunfire":
			add = 28.0 if witnessed else 8.0
		"shoot_cop":
			add = 52.0
		"trespass":
			add = 24.0 if witnessed else 10.0
		"steal_arms":
			add = 36.0
		"steal_jet":
			add = 44.0
		_:
			add = 12.0 if witnessed else 0.0
	if add <= 0.0:
		return 0
	var before := stars
	heat = minf(heat + add, 100.0)
	_refresh_stars()
	last_crime = crime
	_crime_cd = 0.65
	_decay = 0.0
	just_ranked = stars - before
	return just_ranked


func clear() -> void:
	heat = 0.0
	stars = 0
	_decay = 0.0
	_search = 0.0
	in_sight = false
	last_crime = ""
	just_ranked = 0


func tick(delta: float, seen: bool, pos: Vector3) -> void:
	_crime_cd = maxf(_crime_cd - delta, 0.0)
	in_sight = seen
	if seen:
		last_seen = pos
		_decay = 0.0
		_search = 11.0
		return
	if heat <= 0.0:
		_search = 0.0
		return
	_search = maxf(_search - delta, 0.0)
	_decay += delta
	if _decay >= 2.4:
		heat = maxf(heat - (6.5 + float(stars)), 0.0)
		_decay = 0.0
		_refresh_stars()


func _refresh_stars() -> void:
	stars = clampi(int(heat / 20.0), 0, MAX_STARS)
	if heat > 0.0 and stars == 0:
		stars = 1


func searching() -> bool:
	return stars > 0 and (not in_sight) and _search > 0.0


func cop_count() -> int:
	if stars <= 0:
		return 2
	return mini(2 + stars, 5)


func label() -> String:
	match last_crime:
		"jack", "jack_mission":
			return "GRAND THEFT"
		"jack_cop":
			return "STOLEN UNIT"
		"hit_ped":
			return "HIT AND RUN"
		"ram_civ":
			return "RECKLESS DRIVING"
		"ram_cop":
			return "ASSAULT ON POLICE"
		"assault":
			return "ASSAULT"
		"assault_cop":
			return "ASSAULT ON POLICE"
		"alarm":
			return "VEHICLE ALARM"
		"gunfire":
			return "GUNFIRE"
		"shoot_cop":
			return "SHOTS AT POLICE"
		"trespass":
			return "BASE TRESPASS"
		"steal_arms":
			return "ARMS THEFT"
		"steal_jet":
			return "AIRCRAFT THEFT"
		_:
			return ""


static func has_los(world: World3D, from: Vector3, to: Vector3) -> bool:
	var q := PhysicsRayQueryParameters3D.create(from + Vector3(0, 1.5, 0), to + Vector3(0, 1.2, 0), 1)
	return world.direct_space_state.intersect_ray(q).is_empty()
