extends GutTest

## Les planches d'effets. Leur promesse est celle qui manquait aux effets tracés
## en polygones, et qu'aucune assertion de forme ne voit : **peu de couleurs et un
## contour**, c'est-à-dire la même langue que les sprites du jeu.

const FIRE := Color(1.00, 0.48, 0.18)


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


## L'Orbe gelée (jalon 44) : une fabrication par position de la facette, et un demi-tour
## suffit — la neuvième retombe sur la première.
func test_the_frozen_orb_is_built_once_per_facet() -> void:
	var tint: Color = DamageType.COLORS[DamageType.Kind.COLD]
	assert_same(Frost.orb(tint, 2), Frost.orb(tint, 2))
	assert_same(Frost.orb(tint, Frost.ORB_TURNS), Frost.orb(tint, 0))
	assert_false(Frost.orb(tint, 1).get_image().is_invisible())


## L'os des Lanceurs d'os (jalon 45) : une cuisson pour la partie, quatre temps, et le
## debout est le couché tourné — même nombre de pixels, rien de perdu.
func test_the_bone_tumbles_in_four_lossless_beats() -> void:
	for grid: Array in [EffectForge.BONE_FLAT, EffectForge.BONE_SLANT]:
		for row: String in grid:
			assert_eq(row.length(), (grid[0] as String).length(), "grille rectangulaire")
	var frames := EffectForge.bones()
	assert_eq(frames, EffectForge.bones(), "deux appels, une cuisson")
	assert_eq(frames.size(), 4)
	assert_eq(_painted(frames[0]), _painted(frames[2]), "le quart de tour ne perd aucun pixel")
	assert_eq(_painted(frames[1]), _painted(frames[3]), "le miroir non plus")
	assert_eq((frames[2] as Texture2D).get_size(), Vector2((frames[0] as Texture2D).get_height(), (frames[0] as Texture2D).get_width()))


## La créature fabriquée à la taille (jalon 45) : une cuisson par taille, assise puis tassée,
## posées sur la même rangée ; l'amalgame a ses six yeux.
func test_a_grown_crawler_is_forged_once_per_size() -> void:
	var tint := DamageType.COLORS[DamageType.Kind.NECROTIC]
	var frames := EffectForge.grown_crawlers(tint, 11, false)
	assert_eq(frames, EffectForge.grown_crawlers(tint, 11, false), "deux appels, une cuisson")
	assert_eq((frames[0] as Texture2D).get_size(), Vector2(11, 11))
	assert_eq((frames[1] as Texture2D).get_size(), Vector2(13, 11), "tassée : plus large de deux")
	var plain: PackedByteArray = (EffectForge.grown_crawlers(tint, 13, false)[0] as Texture2D).get_image().get_data()
	var amalgam: PackedByteArray = (EffectForge.grown_crawlers(tint, 13, true)[0] as Texture2D).get_image().get_data()
	assert_ne(plain, amalgam, "l'amalgame n'est pas la créature agrandie")


func _painted(tex: Texture2D) -> int:
	var image := tex.get_image()
	var n := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				n += 1
	return n


## Les étoiles du chevalier (jalon 46) : l'impact de l'estoc et l'assommé, à leur côté.
func test_the_knight_stars_are_square() -> void:
	for frame: Array in EffectForge.THRUST_STAR + EffectForge.STUN_STARS:
		assert_eq(frame.size(), EffectForge.STAR_SIDE)
		for row: String in frame:
			assert_eq(row.length(), EffectForge.STAR_SIDE, "largeur de « %s »" % row)


## La spirale du derviche : fabriquée une fois par cap, et un demi-tour la redonne.
func test_the_dervish_spiral_is_built_once_per_half_turn() -> void:
	var tint := Color(1.0, 0.98, 0.88)
	var first := Slash.spiral(tint, 3)
	assert_same(Slash.spiral(tint, 3), first, "gardée")
	assert_same(Slash.spiral(tint, 3 + Slash.TURNS / 2), first, "symétrique d'un demi-tour")
	assert_ne(Slash.spiral(tint, 4).texture.get_image().get_data(), first.texture.get_image().get_data())


# --------------------------------------------------------------------------
# Le sacré (jalon 48)
# --------------------------------------------------------------------------

const HOLY := Color(1.00, 0.72, 0.80)


func test_the_hammer_grid_is_rectangular() -> void:
	for row: String in EffectForge.HAMMER:
		assert_eq(row.length(), (EffectForge.HAMMER[0] as String).length(), "« %s »" % row)


## Huit orientations, chacune fabriquée une fois : un huitième de tour près revient à la même.
func test_the_hammer_is_built_once_per_eighth_of_a_turn() -> void:
	var up := Holy.hammer(HOLY, -PI * 0.5)
	assert_same(Holy.hammer(HOLY, -PI * 0.5 + 0.2), up)
	assert_ne(Holy.hammer(HOLY, 0.0), up, "un quart de tour plus loin")


## Le sol consacré : un cercle du cœur au bord, des dalles tramées dedans, et une fois par rayon.
func test_the_consecrated_ground_is_rimmed_and_kept() -> void:
	var ground := Holy.consecrated(HOLY, 20)
	assert_same(Holy.consecrated(HOLY, 20), ground)
	var img := ground.get_image()
	# L'image garde huit bits par canal.
	var rim := img.get_pixel(40, 20)
	var expected := Holy.halo(HOLY)
	assert_almost_eq(Vector4(rim.r, rim.g, rim.b, rim.a), Vector4(expected.r, expected.g, expected.b, 1.0), Vector4.ONE / 255.0, "le bord")
	var tiled := 0
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.0 and img.get_pixel(x, y).a < 1.0:
				tiled += 1
	assert_gt(tiled, 0, "des dalles")


## Les pièces des Chaînes du jugement : gardées par cap et par sorte ; l'anneau a son trou,
## qui laisse voir le sol.
func test_chain_links_are_baked_per_turn_and_kind() -> void:
	var ring := Holy.link(HOLY, 4, Holy.Link.RING)
	assert_same(Holy.link(HOLY, 4, Holy.Link.RING), ring)
	assert_ne(Holy.link(HOLY, 4, Holy.Link.BAR), ring)
	assert_ne(Holy.link(HOLY, 12, Holy.Link.RING).get_image().get_data(), ring.get_image().get_data())
	var flat := Holy.link(HOLY, 0, Holy.Link.RING).get_image()
	assert_eq(flat.get_pixel(6, 6).a, 0.0, "le trou")
	assert_gt(flat.get_pixel(9, 6).a, 0.0, "l'anneau")


## Les rayons de gloire du souffle sacré : gardés par rayon et par temps, et chaque temps a
## son dessin — ils s'ouvrent, puis leur pied rattrape leur pointe.
func test_glory_rays_are_baked_per_radius_and_frame() -> void:
	var first := Holy.glory(HOLY, 30, 0)
	assert_same(Holy.glory(HOLY, 30, 0), first)
	assert_ne(Holy.glory(HOLY, 30, 3).get_image().get_data(), first.get_image().get_data())
	assert_eq(Holy.glory(HOLY, 60, 0).get_width(), 60 * 2 + 7, "la planche suit le rayon")


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
