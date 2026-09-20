extends GutTest

## Les planches d'effets. Leur promesse est celle qui manquait aux effets tracés
## en polygones, et qu'aucune assertion de forme ne voit : **peu de couleurs et un
## contour**, c'est-à-dire la même langue que les sprites du jeu.

const FIRE := Color(1.00, 0.48, 0.18)


## Une grille mal alignée décale toute la colonne suivante sans rien casser : le
## pixel se pose, simplement ailleurs.
func test_every_flame_frame_is_rectangular() -> void:
	for frame: Array in EffectForge.FLAME:
		assert_eq(frame.size(), EffectForge.FLAME_HEIGHT, "hauteur de la grille")
		for row: String in frame:
			assert_eq(row.length(), EffectForge.FLAME_WIDTH, "largeur de « %s »" % row)


## Le contour est ce qui rattache un effet au décor : les sprites en ont, les
## polygones n'en avaient aucun. `PixelCanvas` le pose autour de la silhouette,
## donc il suffit de vérifier qu'il est arrivé — plus sombre que le plus sombre
## de la rampe.
func test_a_flame_is_outlined_and_uses_few_colours() -> void:
	var image: Image = EffectForge.flames(FIRE)[0].get_image()
	var floor_of_ramp: Color = ArtPalette.ramp(FIRE)[0]
	var seen := {}
	var outlined := 0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a < 0.5:
				continue
			seen[c.to_html(false)] = true
			if c.get_luminance() < floor_of_ramp.get_luminance():
				outlined += 1
	assert_gt(outlined, 10, "la langue porte un contour")
	assert_lt(seen.size(), 13, "et deux rampes de cinq tons, contour compris")


## Une aura la redemande soixante fois par seconde.
func test_a_sheet_is_built_once() -> void:
	assert_eq(EffectForge.flames(FIRE), EffectForge.flames(FIRE), "deux appels, une planche")


## Le halo tramé n'a que ses paliers : un dégradé continu le trahirait.
func test_the_scorch_is_dithered_into_steps() -> void:
	var image: Image = EffectForge.scorch(FIRE, 20).get_image()
	var alphas := {}
	for y in image.get_height():
		for x in image.get_width():
			alphas[snappedf(image.get_pixel(x, y).a, 0.001)] = true
	assert_lt(alphas.size(), EffectForge.SCORCH_STEPS + 2, "trois paliers et le vide")


## La planche de la boule de feu : six temps dessinés à la main, donc six grilles
## qu'un décalage d'un caractère suffit à tordre sans rien casser.
func test_every_ball_frame_is_rectangular() -> void:
	for frame: Array in EffectForge.BALL:
		assert_eq(frame.size(), EffectForge.BALL_SIZE, "hauteur de la grille")
		for row: String in frame:
			assert_eq(row.length(), EffectForge.BALL_SIZE, "largeur de « %s »" % row)
	for frame: Array in EffectForge.PUFF:
		assert_eq(frame.size(), EffectForge.PUFF_SIZE, "hauteur de la bouffée")
		for row: String in frame:
			assert_eq(row.length(), EffectForge.PUFF_SIZE, "largeur de « %s »" % row)


## Les six temps doivent **différer**, sinon l'animation est une image fixe payée
## six fois — et rien dans le dessin ne le dirait.
func test_the_ball_actually_changes_from_frame_to_frame() -> void:
	var seen := {}
	for frame: Array in EffectForge.BALL:
		seen["".join(PackedStringArray(frame))] = true
	assert_eq(seen.size(), EffectForge.BALL.size(), "six temps distincts")


## Les deux dernières planches : l'éclat du souffle et la brûlure au sol. Une
## grille mal alignée décale toute la colonne suivante sans rien casser.
func test_flash_and_burn_grids_are_rectangular() -> void:
	for frame: Array in EffectForge.FLASH:
		assert_eq(frame.size(), EffectForge.FLASH_SIZE, "hauteur de l'éclat")
		for row: String in frame:
			assert_eq(row.length(), EffectForge.FLASH_SIZE, "largeur de « %s »" % row)
	for mark: Array in EffectForge.BURN:
		assert_eq(mark.size(), EffectForge.BURN_HEIGHT, "hauteur de la brûlure")
		for row: String in mark:
			assert_eq(row.length(), EffectForge.BURN_WIDTH, "largeur de « %s »" % row)


## La brûlure est **plus sombre que le sol**, sinon elle se lit comme une lueur et
## non comme une trace. Le sol du jeu est à 0,21 de luminance (`TilesetBuilder`).
func test_a_burn_is_darker_than_the_floor() -> void:
	var image: Image = EffectForge.burns()[0].get_image()
	var brightest := 0.0
	for y in image.get_height():
		for x in image.get_width():
			var c := image.get_pixel(x, y)
			if c.a > 0.5:
				brightest = maxf(brightest, c.get_luminance())
	assert_lt(brightest, 0.21, "la cendre reste sous le sol")


## Les grilles de la glace. Une ligne mal alignée décale toute la colonne suivante
## sans rien casser : le pixel se pose, simplement ailleurs.
func test_every_ice_grid_is_rectangular() -> void:
	var grids := {
		"cristal": [EffectForge.SPIKE, EffectForge.SPIKE_WIDTH, EffectForge.SPIKE_HEIGHT],
		"petit cristal": [
			EffectForge.SPIKE_SMALL, EffectForge.SMALL_SPIKE_WIDTH, EffectForge.SMALL_SPIKE_HEIGHT
		],
		"éclat": [EffectForge.CHIP, EffectForge.CHIP_SIZE, EffectForge.CHIP_SIZE],
		"éclat en biais": [EffectForge.CHIP_DIAG, EffectForge.CHIP_SIZE, EffectForge.CHIP_SIZE],
		"flocon": [EffectForge.FLAKE, EffectForge.FLAKE_SIZE, EffectForge.FLAKE_SIZE],
		"tombeau": [EffectForge.TOMB, EffectForge.TOMB_WIDTH, EffectForge.TOMB_HEIGHT],
	}
	for name: String in grids:
		var grid: Array = grids[name][0]
		assert_eq(grid.size(), grids[name][2], "hauteur du %s" % name)
		for row: String in grid:
			assert_eq(row.length(), grids[name][1], "largeur de « %s » (%s)" % [row, name])


## Quatre quarts de tour ramènent au point de départ : si la rotation perdait une
## colonne, les huit orientations d'un éclat seraient huit dessins différents.
func test_four_quarter_turns_come_back_to_the_start() -> void:
	var grid: Array = EffectForge.CHIP
	for i in 4:
		grid = EffectForge.turned(grid)
	assert_eq(grid, EffectForge.CHIP, "le tour complet ne perd rien")


## Le cap d'un éclat tombe sur l'orientation la plus proche, et les angles négatifs
## comme ceux qui dépassent le tour retombent dans les huit.
func test_a_heading_finds_the_nearest_of_the_eight_turns() -> void:
	assert_eq(EffectForge.chip_turn(0.0), 0, "droite")
	assert_eq(EffectForge.chip_turn(TAU / 8.0), 1, "le huitième suivant")
	assert_eq(EffectForge.chip_turn(-TAU / 8.0), 7, "et le précédent, par l'autre bout")
	assert_eq(EffectForge.chip_turn(TAU), 0, "un tour entier revient au départ")
	assert_eq(EffectForge.chip_turn(PI), 4, "le demi-tour est à l'opposé")


## Huit orientations qui se ressemblent seraient huit fois la même image payée
## huit fois — et un tourbillon dont les éclats ne tournent pas.
func test_the_eight_chips_all_differ() -> void:
	var seen := {}
	for tex: Texture2D in EffectForge.chips(Color(0.50, 0.88, 1.00)):
		seen[tex.get_image().get_data().hex_encode()] = true
	assert_eq(seen.size(), EffectForge.CHIP_TURNS, "huit dessins distincts")
