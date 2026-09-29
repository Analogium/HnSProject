extends GutTest

## Les conversions case <-> pixels. Une seule définition dans le projet, et
## c'est celle-ci — trois copies divergentes avaient été supprimées.


func test_round_trip_cell_pixels() -> void:
	for x in range(-4, 5):
		for y in range(-4, 5):
			var cell := Vector2i(x, y)
			assert_eq(MapGenerator.cell_at(MapGenerator.cell_center(cell)), cell)


## Le centre est bien au centre, pas au coin : un ennemi posé au coin démarre à
## cheval sur un mur.
func test_the_center_is_offset_by_half_a_cell() -> void:
	var t := float(MapGenerator.TILE)
	assert_eq(MapGenerator.cell_center(Vector2i.ZERO), Vector2(t * 0.5, t * 0.5))


func test_a_single_tile_size() -> void:
	assert_eq(MapGenerator.TILE, TilesetBuilder.TILE)


## La route va de l'entrée — le sol le plus à l'ouest — à la sortie, pas à pas sur
## du sol, et la sortie est la case la plus loin à pied : rien ne la raccourcit.
func test_the_road_walks_from_entry_to_the_farthest_cell() -> void:
	for seed_value in [4242, 777, 1]:
		var map := MapGenerator.new()
		map.generate(seed_value)
		var road := map.road
		assert_gt(road.size(), 40, "graine %d : une vraie traversée" % seed_value)
		for cell in map.floor_cells:
			assert_true(cell.x >= road[0].x, "rien plus à l'ouest que l'entrée")
		for i in road.size():
			assert_true(map.is_walkable(road[i]), "graine %d : %s sur du sol" % [seed_value, road[i]])
			if i > 0:
				assert_eq((road[i] - road[i - 1]).length_squared(), 1, "un pas à la fois")
		var from_entry := map._distances(road[0])
		assert_eq(road.size() - 1, from_entry[road.back()], "le plus court chemin, sans détour")
		assert_eq(from_entry[road.back()], from_entry.values().max(), "la case la plus loin")
		assert_eq(map.get_spawn_cell(), road[0], "on arrive par l'entrée")
		assert_true(road.has(map.waypoint_cell()), "le waypoint est sur la route")


func test_the_town_has_no_road() -> void:
	var town := MapGenerator.town(24, 16)
	assert_true(town.road.is_empty())
	assert_eq(town.get_spawn_cell(), town.center_cell())
