extends GutTest

## La matière nécrotique (jalon 26) : ses planches dessinées, et les deux anneaux qu'elle
## rastérise en jeu — le mur de gaz et le cercle maudit —, gardés en cache.

const NECRO := Color(0.52, 0.78, 0.32)


func _assert_grids(grids: Array, width: int, height: int, name: String) -> void:
	for grid: Array in grids:
		assert_eq(grid.size(), height, "%s : hauteur" % name)
		for row: String in grid:
			assert_eq(row.length(), width, "%s : largeur de « %s »" % [name, row])


## Une grille mal alignée décale toute la colonne suivante sans rien casser.
func test_every_necrotic_grid_is_rectangular() -> void:
	_assert_grids(EffectForge.PLAGUE, EffectForge.PLAGUE_WIDTH, EffectForge.PLAGUE_HEIGHT, "crâne")
	_assert_grids(EffectForge.RIFT, EffectForge.RIFT_WIDTH, EffectForge.RIFT_HEIGHT, "faille")
	_assert_grids(EffectForge.CRAWLER, EffectForge.CRAWLER_SIZE, EffectForge.CRAWLER_SIZE, "créature")
	_assert_grids(EffectForge.EYE, EffectForge.EYE_WIDTH, EffectForge.EYE_HEIGHT, "œil")
	_assert_grids([EffectForge.SPORE], EffectForge.SPORE_SIZE, EffectForge.SPORE_SIZE, "spore")
	for fume: Array in EffectForge.FUMES:
		_assert_grids([fume], (fume[0] as String).length(), fume.size(), "fumée")


## Chaque caractère des grilles a son encre : un caractère inconnu laisse un trou.
func test_every_necrotic_character_has_its_ink() -> void:
	for grids: Array in [EffectForge.PLAGUE, EffectForge.RIFT, EffectForge.CRAWLER, EffectForge.EYE, [EffectForge.SPORE]]:
		for grid: Array in grids:
			for row: String in grid:
				for ch in row:
					assert_true(ch == "." or EffectForge.INK_SHADE.has(ch), "« %s » sans encre" % ch)


## Les orbites palpitent : un crâne qui ne change pas d'un temps à l'autre est un
## autocollant qui glisse.
func test_the_plague_skull_changes_from_frame_to_frame() -> void:
	var frames := EffectForge.plagues(NECRO)
	assert_ne(frames[0].get_image().get_data(), frames[2].get_image().get_data())


## La dissolution par masque natif ôte **exactement** les pixels que l'ancienne boucle
## ôtait : le damier de Bayer, pixel pour pixel.
func test_dissolve_removes_the_bayer_pixels_and_no_others() -> void:
	for gone in [0.1, 0.3, 0.5, 0.8, 1.0]:
		var img := Image.create_empty(37, 23, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		EffectForge.dissolve(img, gone)
		for y in img.get_height():
			for x in img.get_width():
				var removed: bool = float(EffectForge.BAYER[y % 4][x % 4]) / 16.0 < gone
				assert_eq(img.get_pixel(x, y).a, 0.0 if removed else 1.0, "%d,%d à %.1f" % [x, y, gone])


## Plus grand que le masque de départ : il grandit au lieu de lire hors de ses bords.
func test_dissolve_handles_what_exceeds_the_starting_mask() -> void:
	var side := EffectForge.MASK_SIDE + 50
	var img := Image.create_empty(side, 9, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	EffectForge.dissolve(img, 0.5)
	assert_eq(img.get_pixel(side - 1, 0).a, 0.0 if EffectForge.BAYER[0][(side - 1) % 4] < 8 else 1.0)


## Une Déferlante relancée ne rastérise plus rien.
func test_the_rings_are_built_once() -> void:
	assert_eq(Necrotic.miasma(NECRO, 48.0, 0.5), Necrotic.miasma(NECRO, 48.0, 0.5))
	assert_eq(Necrotic.ring(NECRO, 48.0, 0.0), Necrotic.ring(NECRO, 48.0, 0.0))
	assert_ne(Necrotic.miasma(NECRO, 48.0, 0.0), Necrotic.miasma(NECRO, 48.0, 0.9), "un cran de plus, une autre forme")


## Les quadrants pavent l'anneau **sans se recouvrir** : deux planches cernées qui se
## recouvrent montrent leurs contours l'une dans l'autre.
func test_the_quadrants_tile_without_overlapping() -> void:
	for pieces: Array in [Necrotic.miasma(NECRO, 48.0, 0.8), Necrotic.ring(NECRO, 48.0, 0.0)]:
		var rects: Array[Rect2] = []
		for piece: EffectForge.Piece in pieces:
			rects.append(Rect2(piece.offset, Vector2(piece.texture.get_size())))
		assert_eq(rects.size(), 4, "quatre quadrants")
		for i in rects.size():
			for j in range(i + 1, rects.size()):
				assert_false(rects[i].intersects(rects[j]), "%s et %s" % [rects[i], rects[j]])
