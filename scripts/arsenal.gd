class_name Arsenal
extends Object

enum Id { NONE, PISTOL, SMG, RIFLE }

static var _data: Dictionary = {}

static func data(id: int) -> WeaponData:
	if _data.has(id):
		return _data[id]
	var paths := {Id.PISTOL: "pistol", Id.SMG: "smg", Id.RIFLE: "rifle"}
	var item := load("res://resources/weapons/%s.tres" % paths.get(id, "pistol")) as WeaponData
	_data[id] = item
	return item


static func spec(id: int) -> Dictionary:
	if id != Id.NONE:
		return data(id).as_dictionary()
	return {"name": "", "dmg": 0.0, "range": 0.0, "rate": 1.0, "spread": 0.0, "ammo": 0, "price": 0}


static func ammo_price() -> int:
	return 80
