class_name TacticalOverlay
extends Control
var health := 100.0
var maximum := 100.0
var armor := 0.0
var armor_maximum := 150.0
var flash := 0.0
var indicators: Array[Dictionary] = []

func damage(direction: Vector2, gas: bool) -> void:
	flash = 0.35
	if direction.length_squared() > 0.01:
		if indicators.size() >= 4: indicators.pop_front()
		indicators.append({"direction": direction, "life": 0.8, "gas": gas})

func reset() -> void:
	flash = 0.0
	indicators.clear()

func _process(delta: float) -> void:
	flash = maxf(flash - delta, 0.0)
	for item in indicators: item.life -= delta
	indicators = indicators.filter(func(item: Dictionary) -> bool: return item.life > 0.0)
	queue_redraw()

func _draw() -> void:
	var base := Vector2(28, size.y - 94)
	var plate_width := 72.0
	for i in 3:
		var rect := Rect2(base + Vector2(i * (plate_width + 5), -18), Vector2(plate_width, 8))
		draw_rect(rect, Color(0.06, 0.09, 0.13, 0.9))
		rect.size.x *= clampf(armor / maxf(armor_maximum / 3.0, 0.01) - i, 0.0, 1.0)
		draw_rect(rect, Color("64c4dd"))
	draw_rect(Rect2(base, Vector2(226, 7)), Color(0.06, 0.09, 0.13, 0.9))
	draw_rect(Rect2(base, Vector2(226 * clampf(health / maxf(maximum, 0.01), 0.0, 1.0), 7)), Color("e7e8df"))
	var redness := maxf(flash, (1.0 - health / maxf(maximum * 0.4, 0.01)) * 0.3)
	if redness > 0.0:
		var tint := Color(0.7, 0.05, 0.02, redness)
		for rect in [Rect2(0, 0, size.x, 6), Rect2(0, size.y - 6, size.x, 6), Rect2(0, 0, 6, size.y), Rect2(size.x - 6, 0, 6, size.y)]:
			draw_rect(rect, tint)
	for item in indicators:
		var direction: Vector2 = item.direction
		var point := size * 0.5 + direction * 88.0
		var side := direction.orthogonal() * 13.0
		draw_colored_polygon(PackedVector2Array([point + direction * 12, point - direction * 5 + side, point - direction * 5 - side]), Color(1.0, 0.22, 0.12, minf(item.life * 2.0, 0.85)))
