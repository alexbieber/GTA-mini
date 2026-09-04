class_name Arsenal
extends Object

enum Id { NONE, PISTOL, SMG, RIFLE }


static func spec(id: int) -> Dictionary:
	match id:
		Id.PISTOL:
			return {"name": "PISTOL", "dmg": 22.0, "range": 42.0, "rate": 0.28, "spread": 0.012, "ammo": 36, "price": 250}
		Id.SMG:
			return {"name": "SMG", "dmg": 14.0, "range": 34.0, "rate": 0.09, "spread": 0.028, "ammo": 80, "price": 600}
		Id.RIFLE:
			return {"name": "RIFLE", "dmg": 34.0, "range": 70.0, "rate": 0.16, "spread": 0.008, "ammo": 48, "price": 900}
		_:
			return {"name": "", "dmg": 0.0, "range": 0.0, "rate": 1.0, "spread": 0.0, "ammo": 0, "price": 0}


static func ammo_price() -> int:
	return 80
