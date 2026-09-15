extends GutTest

## Les boules d'expérience de l'établi : ce qu'elles valent, et qu'elles récompensent
## en les ramassant, par le chemin d'une mort.


func test_an_orb_is_worth_grunts_of_the_zone() -> void:
	var grunt: CharacterStats = ExperienceOrb.GRUNT
	assert_almost_eq(
		ExperienceOrb.value_for(1),
		Enemy.xp_from_health(grunt.max_health) * ExperienceOrb.ORB_IN_GRUNTS, 0.001
	)
	assert_gt(ExperienceOrb.value_for(30), ExperienceOrb.value_for(1), "plus profond, plus riche")


func test_walking_over_an_orb_picks_it_up() -> void:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	var ground := Node2D.new()
	add_child_autofree(ground)
	var orb := ExperienceOrb.put(ground, Vector2(60, 0), 20.0, 1)
	await wait_physics_frames(3)
	assert_eq(player.xp, 0, "loin du joueur, elle attend")

	player.global_position = Vector2(60, 0)
	await wait_physics_frames(3)
	assert_eq(player.xp, 20, "au contact, elle récompense")
	assert_false(is_instance_valid(orb), "et disparaît")


## La zone les pose en couronne, hors de portée de ramassage : sous les pieds, elles
## seraient prises avant d'avoir été vues.
func test_the_zone_places_orbs_around_the_player() -> void:
	var zone: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(zone)
	await wait_physics_frames(1)
	zone.drop_orbs(10)
	await wait_process_frames(1)
	var orbs: Array = zone.loot.get_children().filter(func(n: Node) -> bool: return n is ExperienceOrb)
	assert_eq(orbs.size(), 10)
	for orb: ExperienceOrb in orbs:
		assert_gt(
			orb.global_position.distance_to(zone.player.global_position), 15.0,
			"hors de portée de ramassage"
		)
		assert_eq(orb.value, ExperienceOrb.value_for(zone.enemy_manager.level))
