extends GutTest

## Les boules d'expérience de l'établi : ce qu'elles valent, et qu'elles récompensent
## en les ramassant, par le chemin d'une mort.


func test_une_boule_vaut_des_grunts_de_la_zone() -> void:
	var grunt: CharacterStats = OrbeDExperience.GRUNT
	assert_almost_eq(
		OrbeDExperience.valeur_pour(1),
		Enemy.xp_de_la_sante(grunt.max_health) * OrbeDExperience.ORBE_EN_GRUNTS, 0.001
	)
	assert_gt(OrbeDExperience.valeur_pour(30), OrbeDExperience.valeur_pour(1), "plus profond, plus riche")


func test_marcher_sur_une_boule_la_ramasse() -> void:
	var joueur: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(joueur)
	var sol := Node2D.new()
	add_child_autofree(sol)
	var orbe := OrbeDExperience.poser(sol, Vector2(60, 0), 20.0, 1)
	await wait_physics_frames(3)
	assert_eq(joueur.xp, 0, "loin du joueur, elle attend")

	joueur.global_position = Vector2(60, 0)
	await wait_physics_frames(3)
	assert_eq(joueur.xp, 20, "au contact, elle récompense")
	assert_false(is_instance_valid(orbe), "et disparaît")


## La zone les pose en couronne, hors de portée de ramassage : sous les pieds, elles
## seraient prises avant d'avoir été vues.
func test_la_zone_pose_les_boules_autour_du_joueur() -> void:
	var zone: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(zone)
	await wait_physics_frames(1)
	zone.lacher_des_orbes(10)
	await wait_process_frames(1)
	var orbes: Array = zone.loot.get_children().filter(func(n: Node) -> bool: return n is OrbeDExperience)
	assert_eq(orbes.size(), 10)
	for orbe: OrbeDExperience in orbes:
		assert_gt(
			orbe.global_position.distance_to(zone.player.global_position), 15.0,
			"hors de portée de ramassage"
		)
		assert_eq(orbe.valeur, OrbeDExperience.valeur_pour(zone.enemy_manager.niveau))
