extends GutTest

## La matière de la sorcière (jalon 41) : le corbeau dessiné ; les Glyphes (jalon 49), leurs
## fils et leur Sceau, fabriqués une fois et gardés.

const FIRE := Color(0.95, 0.45, 0.15)


## Une grille mal alignée décale toute la colonne suivante sans rien casser.
func test_the_witch_grids_are_rectangular_and_inked() -> void:
	for pair: Array in [
		[EffectForge.CROW, EffectForge.CROW_WIDTH, EffectForge.CROW_HEIGHT, EffectForge.CROW_INK],
	]:
		for grid: Array in pair[0]:
			assert_eq(grid.size(), pair[2])
			for row: String in grid:
				assert_eq(row.length(), pair[1], "« %s »" % row)
				for ch in row:
					assert_true(ch == "." or (pair[3] as Dictionary).has(ch), "« %s » sans encre" % ch)


## Vers la gauche, le même corbeau renversé pixel pour pixel : un miroir ne perd rien.
func test_the_crow_looking_left_is_its_exact_mirror() -> void:
	var sides := EffectForge.crow()
	for frame in EffectForge.CROW.size():
		var right: Image = (sides[0][frame] as Texture2D).get_image()
		right.flip_x()
		assert_eq(right.get_data(), (sides[1][frame] as Texture2D).get_image().get_data())
	assert_ne(
		(sides[0][0] as Texture2D).get_image().get_data(),
		(sides[0][1] as Texture2D).get_image().get_data(), "deux battements"
	)


## Chaque morceau des Glyphes est fabriqué une fois, puis gardé.
func test_the_glyph_pieces_are_built_once() -> void:
	assert_eq(Witchcraft.glyph(16, FIRE, true, 1), Witchcraft.glyph(16, FIRE, true, 1))
	assert_eq(Witchcraft.seal(FIRE), Witchcraft.seal(FIRE))
	assert_eq(
		Witchcraft.thread(Vector2i(80, 30), FIRE, Color.CYAN, 16.0, false),
		Witchcraft.thread(Vector2i(80, 30), FIRE, Color.CYAN, 16.0, false)
	)


## Armé, l'anneau est plein et ses crans tournent d'un temps à l'autre ; non armé, plus sombre.
func test_an_armed_glyph_turns_and_outshines_the_unarmed_one() -> void:
	var a := Witchcraft.glyph(16, FIRE, true, 0).texture.get_image()
	var b := Witchcraft.glyph(16, FIRE, true, 1).texture.get_image()
	assert_ne(a.get_data(), b.get_data())
	assert_gt(_ink(a), _ink(Witchcraft.glyph(16, FIRE, false, 0).texture.get_image()))


## Le fil vif est plus clair que le fil au repos, au même tracé.
func test_a_lit_thread_is_brighter() -> void:
	var calm := Witchcraft.thread(Vector2i(80, 30), FIRE, Color.CYAN, 16.0, false).texture.get_image()
	var lit := Witchcraft.thread(Vector2i(80, 30), FIRE, Color.CYAN, 16.0, true).texture.get_image()
	assert_eq(_ink(calm), _ink(lit), "le même tracé")
	assert_gt(_light(lit), _light(calm))


## Le triangle tramé ne mord pas sur les glyphes de ses coins.
func test_the_weave_leaves_the_corners_bare() -> void:
	var corners: Array[Vector2i] = [Vector2i.ZERO, Vector2i(90, 0), Vector2i(45, 78)]
	var piece := Witchcraft.weave(corners, [FIRE, Color.CYAN, Color.VIOLET] as Array[Color], 16.0)
	var img := piece.texture.get_image()
	var origin := Vector2i(-piece.offset)
	assert_gt(_ink(img), 0, "la surface se trame")
	for c in corners:
		var p := origin + c
		if p.x < img.get_width() and p.y < img.get_height():
			assert_eq(img.get_pixelv(p).a, 0.0, "un coin reste nu")


func _ink(img: Image) -> int:
	var n := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0:
				n += 1
	return n


func _light(img: Image) -> float:
	var total := 0.0
	for y in img.get_height():
		for x in img.get_width():
			total += img.get_pixel(x, y).get_luminance() * img.get_pixel(x, y).a
	return total
