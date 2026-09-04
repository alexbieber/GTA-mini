class_name ProcTex
extends Object

static var _cache: Dictionary = {}


static func get_tex(id: String) -> ImageTexture:
	if _cache.has(id):
		return _cache[id]
	var img: Image
	match id:
		"asphalt":
			img = _asphalt()
		"road":
			img = _road()
		"sidewalk":
			img = _sidewalk()
		"brick":
			img = _brick(Color("7a4034"), Color("c9b8a4"), false)
		"brick_emit":
			img = _brick(Color("7a4034"), Color("c9b8a4"), true)
		"brick_dark":
			img = _brick(Color("4d2c28"), Color("a89a88"), false)
		"brick_dark_emit":
			img = _brick(Color("4d2c28"), Color("a89a88"), true)
		"concrete":
			img = _concrete(Color("8a8e94"), false)
		"concrete_emit":
			img = _concrete(Color("8a8e94"), true)
		"warehouse":
			img = _corrugated(Color("2a5c5e"), false)
		"warehouse_emit":
			img = _corrugated(Color("2a5c5e"), true)
		"office":
			img = _office(false)
		"office_emit":
			img = _office(true)
		"roof":
			img = _roof()
		"plaster":
			img = _plaster(Color("c4b49a"))
		"plaster_emit":
			img = Image.create(64, 64, false, Image.FORMAT_RGBA8)
			img.fill(Color(0, 0, 0, 1))
		"wood":
			img = _wood()
		"stars":
			img = _stars()
		"water":
			img = _water()
		_:
			img = _concrete(Color("888888"), false)
	var tex := ImageTexture.create_from_image(img)
	_cache[id] = tex
	return tex


static func _asphalt() -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var n := _fbm(x * 0.035, y * 0.035, 4, 11)
			var speckle := _hash(x, y, 3)
			var c := 0.13 + n * 0.07 + speckle * 0.03
			if int(y) % 73 == 0 or int(x * 0.7 + y) % 91 == 0:
				c *= 0.78
			img.set_pixel(x, y, Color(c, c, c * 1.02, 1))
	return img


static func _road() -> Image:
	var s := 256
	var img := _asphalt()
	var paint := Color("d8c98a")
	for y in s:
		for x in s:
			var edge := x < 18 or x > s - 19
			var center := absi(x - s / 2) < 5 and (y % 48) < 26
			if edge or center:
				var p: Color = img.get_pixel(x, y).lerp(paint, 0.82)
				img.set_pixel(x, y, p)
	return img


static func _sidewalk() -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var tile_x := x % 42
			var tile_y := y % 42
			var grout := tile_x < 2 or tile_y < 2
			var n := _fbm(x * 0.08, y * 0.08, 3, 21)
			var c := 0.55 + n * 0.08
			if grout:
				c = 0.38
			img.set_pixel(x, y, Color(c, c * 0.99, c * 0.95, 1))
	return img


static func _brick(brick: Color, mortar: Color, emit_only: bool) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	if not emit_only:
		var bw := 48
		var bh := 20
		for y in s:
			for x in s:
				var row := int(y / bh)
				var xoff := (row % 2) * (bw / 2)
				var lx := (x + xoff) % bw
				var ly := y % bh
				var is_mortar := lx < 3 or ly < 3
				var n := _hash(x, y, 9) * 0.12
				var col := mortar if is_mortar else brick.lightened(n - 0.04)
				if not is_mortar and _hash(int((x + xoff) / bw), row, 17) > 0.82:
					col = col.darkened(0.18)
				img.set_pixel(x, y, col)
	_punch_windows(img, s, 4, 3, Color("1c2430"), Color("f0d090"), 0.38, emit_only)
	return img


static func _concrete(base: Color, emit_only: bool) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	if not emit_only:
		for y in s:
			for x in s:
				var n := _fbm(x * 0.04, y * 0.04, 4, 5)
				var streak := _fbm(x * 0.01, y * 0.12, 2, 8)
				var c := base.darkened(0.15 - n * 0.12 + streak * 0.06)
				img.set_pixel(x, y, c)
	_punch_windows(img, s, 5, 4, Color("15202c"), Color("b8d4e8"), 0.3, emit_only)
	return img


static func _corrugated(base: Color, emit_only: bool) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	if not emit_only:
		for y in s:
			for x in s:
				var rib := absf(sin(x * 0.42))
				var rust := _fbm(x * 0.03, y * 0.03, 3, 31)
				var c := base.lightened(rib * 0.12).lerp(Color("6a3a22"), rust * 0.22)
				img.set_pixel(x, y, c)
	_punch_windows(img, s, 3, 2, Color("0e1418"), Color("f2b24a"), 0.24, emit_only)
	return img


static func _office(emit_only: bool) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	if not emit_only:
		for y in s:
			for x in s:
				var n := _fbm(x * 0.05, y * 0.05, 3, 2)
				img.set_pixel(x, y, Color(0.22 + n * 0.04, 0.24 + n * 0.04, 0.27, 1))
	_punch_windows(img, s, 6, 5, Color("0a1218"), Color("d7e6f4"), 0.58, emit_only)
	return img


static func _roof() -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var n := _hash(x, y, 44)
			var c := 0.16 + n * 0.08
			img.set_pixel(x, y, Color(c, c * 0.95, c * 0.88, 1))
	return img


static func _plaster(base: Color) -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var n := _fbm(x * 0.06, y * 0.06, 3, 19)
			img.set_pixel(x, y, base.darkened(0.08 - n * 0.1))
	return img


static func _wood() -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var grain := sin(x * 0.35 + _fbm(x * 0.02, y * 0.08, 2, 6) * 4.0)
			var c := 0.28 + grain * 0.06
			img.set_pixel(x, y, Color(c * 1.15, c * 0.75, c * 0.45, 1))
	return img


static func _stars() -> Image:
	var s := 512
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var rng := RandomNumberGenerator.new()
	rng.seed = 2026
	for i in 220:
		var x := rng.randi_range(0, s - 1)
		var y := rng.randi_range(0, int(s * 0.62))
		var a := rng.randf_range(0.35, 1.0)
		img.set_pixel(x, y, Color(1, 0.96, 0.88, a))
	return img


static func _water() -> Image:
	var s := 256
	var img := Image.create(s, s, false, Image.FORMAT_RGBA8)
	for y in s:
		for x in s:
			var n := _fbm(x * 0.06, y * 0.06, 4, 41)
			var c := Color("0b2a3c").lerp(Color("1a5a6e"), n)
			img.set_pixel(x, y, c)
	return img


static func _punch_windows(img: Image, s: int, cols: int, rows: int, frame: Color, glow: Color, lit_chance: float, emit_only := false) -> void:
	var cell_w := int(s / cols)
	var cell_h := int(s / rows)
	for r in rows:
		for c in cols:
			var x0 := c * cell_w + 8
			var y0 := r * cell_h + 10
			var x1 := (c + 1) * cell_w - 8
			var y1 := (r + 1) * cell_h - 10
			var lit := _hash(c * 13, r * 7, 77) < lit_chance
			var pane := glow if lit else Color("0d1520")
			if not lit:
				pane = pane.lightened(_hash(c, r, 4) * 0.08)
			for y in range(y0, y1):
				for x in range(x0, x1):
					if x < 0 or y < 0 or x >= s or y >= s:
						continue
					var border := x < x0 + 2 or y < y0 + 2 or x > x1 - 3 or y > y1 - 3
					var mullion := absi(x - (x0 + x1) / 2) < 2
					if emit_only:
						img.set_pixel(x, y, glow if (lit and not border and not mullion) else Color(0, 0, 0, 1))
					else:
						img.set_pixel(x, y, frame if (border or mullion) else pane)


static func _hash(x: int, y: int, salt: int) -> float:
	var n := x * 374761393 + y * 668265263 + salt * 1274126177
	n = (n ^ (n >> 13)) * 1274126177
	return float(n & 0x7fffffff) / 2147483647.0


static func _vnoise(x: float, y: float, salt: int) -> float:
	var x0 := int(floor(x))
	var y0 := int(floor(y))
	var fx := x - float(x0)
	var fy := y - float(y0)
	fx = fx * fx * (3.0 - 2.0 * fx)
	fy = fy * fy * (3.0 - 2.0 * fy)
	var a := _hash(x0, y0, salt)
	var b := _hash(x0 + 1, y0, salt)
	var c := _hash(x0, y0 + 1, salt)
	var d := _hash(x0 + 1, y0 + 1, salt)
	return lerpf(lerpf(a, b, fx), lerpf(c, d, fx), fy)


static func _fbm(x: float, y: float, octaves: int, salt: int) -> float:
	var v := 0.0
	var amp := 0.5
	var freq := 1.0
	for i in octaves:
		v += _vnoise(x * freq, y * freq, salt + i * 19) * amp
		freq *= 2.0
		amp *= 0.5
	return v
