extends GutTest

## Les planches d'effets. Leur promesse est celle qui manquait aux effets tracés
## en polygones, et qu'aucune assertion de forme ne voit : **peu de couleurs et un
## contour**, c'est-à-dire la même langue que les sprites du jeu.

const FIRE := Color(1.00, 0.48, 0.18)


## Quatre quarts de tour ramènent au point de départ : si la rotation perdait une
## colonne, les huit orientations d'un rat seraient huit dessins différents.
func test_four_quarter_turns_come_back_to_the_start() -> void:
	var grid: Array = EffectForge.RAT[0]
	for i in 4:
		grid = EffectForge.turned(grid)
	assert_eq(grid, EffectForge.RAT[0], "le tour complet ne perd rien")


## Un cap tombe sur l'orientation la plus proche, et les angles négatifs
## comme ceux qui dépassent le tour retombent dans les huit.
func test_a_heading_finds_the_nearest_of_the_eight_turns() -> void:
	assert_eq(EffectForge.chip_turn(0.0), 0, "droite")
	assert_eq(EffectForge.chip_turn(TAU / 8.0), 1, "le huitième suivant")
	assert_eq(EffectForge.chip_turn(-TAU / 8.0), 7, "et le précédent, par l'autre bout")
	assert_eq(EffectForge.chip_turn(TAU), 0, "un tour entier revient au départ")
	assert_eq(EffectForge.chip_turn(PI), 4, "le demi-tour est à l'opposé")


func _painted(tex: Texture2D) -> int:
	var image := tex.get_image()
	var n := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				n += 1
	return n


## Les étoiles de l'assommé (jalon 46), à leur côté.
func test_the_stun_stars_are_square() -> void:
	for frame: Array in EffectForge.STUN_STARS:
		assert_eq(frame.size(), EffectForge.STAR_SIDE)
		for row: String in frame:
			assert_eq(row.length(), EffectForge.STAR_SIDE, "largeur de « %s »" % row)


## Les dessins du jalon 49, choisis sur planche : la marmite, le piqué, l'icône de résistance.
func test_the_witch_grids_are_rectangular() -> void:
	for grid: Array in [EffectForge.CAULDRON, EffectForge.CROW_DIVE, StatusIcon.LOWERED]:
		for row: String in grid:
			assert_eq(row.length(), (grid[0] as String).length(), "largeur de « %s »" % row)
	assert_eq(EffectForge.CAULDRON.size(), EffectForge.CAULDRON_HEIGHT)
	assert_eq(EffectForge.CROW_DIVE.size(), EffectForge.CROW_DIVE_HEIGHT)
	for bubbles: Array in EffectForge.CAULDRON_BUBBLES:
		for at: Vector2i in bubbles:
			assert_eq((EffectForge.CAULDRON[at.y] as String)[at.x], "a", "une bulle sur la surface")


## Fabriquée une fois par teinte : l'élément change, la marmite suit, et ses temps diffèrent.
func test_the_cauldron_is_baked_once_per_tint() -> void:
	var frames := EffectForge.cauldron(FIRE)
	assert_same(EffectForge.cauldron(FIRE), frames)
	assert_eq(frames.size(), EffectForge.CAULDRON_BUBBLES.size())
	assert_ne(frames[0].get_image().get_data(), frames[1].get_image().get_data())



## L'œil du Mauvais œil : gardé par rayon, temps et teinte ; fermé, un trait ; ouvert, l'amande.
func test_the_evil_eye_opens_and_is_kept() -> void:
	var shut := Witchcraft.eye(50.0, 0, FIRE)
	var open := Witchcraft.eye(50.0, 2, FIRE)
	assert_same(Witchcraft.eye(50.0, 2, FIRE), open)
	assert_gt(_painted(open.texture), _painted(shut.texture) * 3, "l'œil ouvert couvre son amande")


## Le bord du Chaudron : gardé par teinte, rayon et temps, et sa couronne grandit avec le cercle.
func test_the_cauldron_rim_is_kept_and_follows_the_radius() -> void:
	var rim := EffectForge.cauldron_rim(FIRE, 50, 0)
	assert_same(EffectForge.cauldron_rim(FIRE, 50, 0), rim)
	assert_ne(EffectForge.cauldron_rim(FIRE, 50, 1).texture.get_image().get_data(), rim.texture.get_image().get_data())
	assert_eq(rim.texture.get_width(), 50 * 2 + 9)
	assert_gt(_painted(EffectForge.cauldron_rim(FIRE, 70, 0).texture), _painted(rim.texture))


## Le rat de la Marée (jalon 53) : des grilles rectangulaires, huit caps de deux temps, un quart
## de tour sans perte (les caps se répondent en taille), et rien au-dessus du seuil de glow.
func test_the_rats_run_in_eight_lossless_headings() -> void:
	for grids: Array in [EffectForge.RAT, EffectForge.RAT_DIAG]:
		for grid: Array in grids:
			for row: String in grid:
				assert_eq(row.length(), (grid[0] as String).length())
	var rats := EffectForge.rats(Piper.FUR)
	assert_eq(rats.size(), EffectForge.CHIP_TURNS)
	assert_same(rats, EffectForge.rats(Piper.FUR), "bâtis une fois")
	for i in rats.size():
		assert_eq((rats[i] as Array).size(), 2, "deux temps de course")
	var east := (rats[0][0] as Texture2D).get_size()
	assert_eq((rats[2][0] as Texture2D).get_size(), Vector2(east.y, east.x), "le sud, l'est tourné")
	assert_eq((rats[4][0] as Texture2D).get_size(), east, "l'ouest")
	for heading: Array in rats:
		for frame: Texture2D in heading:
			var img := frame.get_image()
			for y in img.get_height():
				for x in img.get_width():
					assert_lt(img.get_pixel(x, y).get_luminance(), 0.9)


## Les notes de l'Air (jalon 53) : un même cadre pour les deux, sous le seuil de glow.
func test_the_notes_share_a_frame_and_stay_under_the_glow() -> void:
	for grid: Array in EffectForge.NOTES:
		assert_eq(grid.size(), EffectForge.NOTE_HEIGHT)
		for row: String in grid:
			assert_eq(row.length(), EffectForge.NOTE_WIDTH)
	var tint: Color = DamageType.COLORS[DamageType.Kind.NECROTIC]
	assert_same(EffectForge.notes(tint), EffectForge.notes(tint), "bâties une fois")
	for note: Texture2D in EffectForge.notes(tint):
		var img := note.get_image()
		for y in img.get_height():
			for x in img.get_width():
				assert_lt(img.get_pixel(x, y).get_luminance(), 0.9)
