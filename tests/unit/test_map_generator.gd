extends GutTest

## Les conversions case <-> pixels. Une seule définition dans le projet, et
## c'est celle-ci — trois copies divergentes avaient été supprimées.


func test_aller_retour_case_pixels() -> void:
	for x in range(-4, 5):
		for y in range(-4, 5):
			var cell := Vector2i(x, y)
			assert_eq(MapGenerator.cell_at(MapGenerator.cell_center(cell)), cell)


## Le centre est bien au centre, pas au coin : un ennemi posé au coin démarre à
## cheval sur un mur.
func test_le_centre_est_decale_d_une_demi_case() -> void:
	var t := float(MapGenerator.TILE)
	assert_eq(MapGenerator.cell_center(Vector2i.ZERO), Vector2(t * 0.5, t * 0.5))


func test_une_seule_taille_de_tuile() -> void:
	assert_eq(MapGenerator.TILE, TilesetBuilder.TILE)
