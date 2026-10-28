extends GutTest

## Les planches d'effets. Leur promesse est celle qui manquait aux effets tracés
## en polygones, et qu'aucune assertion de forme ne voit : **peu de couleurs et un
## contour**, c'est-à-dire la même langue que les sprites du jeu.

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


## Les étoiles de l'assommé (jalon 46), à leur côté.
func test_the_stun_stars_are_square() -> void:
	for frame: Array in EffectForge.STUN_STARS:
		assert_eq(frame.size(), EffectForge.STAR_SIDE)
		for row: String in frame:
			assert_eq(row.length(), EffectForge.STAR_SIDE, "largeur de « %s »" % row)


## L'icône de résistance du jalon 49, choisie sur planche.
func test_the_lowered_icon_is_rectangular() -> void:
	for row: String in StatusIcon.LOWERED:
		assert_eq(row.length(), (StatusIcon.LOWERED[0] as String).length(), "largeur de « %s »" % row)


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
