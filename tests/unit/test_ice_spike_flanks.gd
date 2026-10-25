extends GutTest

## Les éclats des Pics de glace partent de part et d'autre du lancer : visé vers le haut de l'écran,
## à gauche et à droite ; visé à droite, en haut et en bas. Un flanc qui en a plusieurs les ouvre en
## éventail autour de la perpendiculaire.


func test_aimed_up_they_fly_left_and_right() -> void:
	var directions := IceSpikes.flanks(Vector3.FORWARD, 2)
	assert_almost_eq(directions[0], -directions[1], Vector3.ONE * 0.001, "un de chaque côté")
	assert_almost_eq(absf(directions[0].x), 1.0, 0.001)


func test_aimed_right_they_fly_up_and_down() -> void:
	for direction in IceSpikes.flanks(Vector3.RIGHT, 2):
		assert_almost_eq(absf(direction.z), 1.0, 0.001)


func test_more_shards_fan_out_on_each_side() -> void:
	var directions := IceSpikes.flanks(Vector3.RIGHT, 4)
	var across := Flat.orthogonal(Vector3.RIGHT)
	var on_one := directions.filter(func(d: Vector3) -> bool: return d.dot(across) > 0.0)
	assert_eq(on_one.size(), 2, "deux par flanc")
	assert_almost_eq(on_one[0].angle_to(across), IceSpikes.FLANK_FAN * 0.5, 0.001, "en éventail")
	assert_almost_eq(on_one[0].angle_to(on_one[1]), IceSpikes.FLANK_FAN, 0.001)
	for direction in directions:
		assert_lt(absf(direction.dot(Vector3.RIGHT)), 0.2, "jamais le long du lancer")


func test_an_odd_count_still_flanks() -> void:
	var directions := IceSpikes.flanks(Vector3.FORWARD, 3)
	assert_eq(directions.size(), 3)
	for direction in directions:
		assert_lt(absf(direction.z), 0.2)
