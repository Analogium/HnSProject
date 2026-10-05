extends GutTest

## La matière de la sorcière (jalon 41) : le corbeau et la poupée dessinés, le sceau de
## la Catalyse fabriqué au rayon du lancer et gardé.

const FIRE := Color(0.95, 0.45, 0.15)


## Une grille mal alignée décale toute la colonne suivante sans rien casser.
func test_the_witch_grids_are_rectangular_and_inked() -> void:
	for pair: Array in [
		[EffectForge.CROW, EffectForge.CROW_WIDTH, EffectForge.CROW_HEIGHT, EffectForge.CROW_INK],
		[[EffectForge.DOLL], EffectForge.DOLL_WIDTH, EffectForge.DOLL_HEIGHT, EffectForge.DOLL_INK],
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


func test_the_doll_and_the_sigil_are_built_once() -> void:
	assert_eq(EffectForge.doll(FIRE), EffectForge.doll(FIRE))
	assert_eq(Witchcraft.sigil(36.0, 1), Witchcraft.sigil(36.0, 1))


## Le sceau s'ouvre et tourne : un temps ne ressemble pas au suivant.
func test_the_sigil_changes_from_step_to_step() -> void:
	assert_ne(
		Witchcraft.sigil(36.0, 0).texture.get_image().get_data(),
		Witchcraft.sigil(36.0, 1).texture.get_image().get_data()
	)


## Son cœur est une lumière : au-dessus du seuil de glow.
func test_the_sigil_core_is_bright() -> void:
	var piece := Witchcraft.sigil(36.0, Witchcraft.STEPS - 1)
	var center := Vector2i(-piece.offset)
	assert_gt(piece.texture.get_image().get_pixelv(center).get_luminance(), 0.9)
