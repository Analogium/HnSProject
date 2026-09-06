extends GutTest

## Les ennemis, et le pilote unique qui les tick.


func test_la_hurtbox_de_l_ennemi_porte_sa_fiche() -> void:
	var e: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(e)
	assert_eq(e.hurtbox.stats, e.stats)


## Les affixes dupliquent la fiche avant de la modifier : sans ça, un Colossal
## rendrait tous les grunts de la session deux fois plus résistants.
func test_l_affixage_ne_touche_pas_la_ressource_partagee() -> void:
	var disque: CharacterStats = load("res://resources/stats/grunt_stats.tres")
	var avant := disque.max_health
	for i in 12:
		var e: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
		e.position = Vector2(i * 37, i * 53)   # le tirage se déduit de la case
		add_child_autofree(e)
	assert_eq(disque.max_health, avant, "grunt_stats.tres est intact")


func test_blinde_donne_de_l_armure() -> void:
	var blinde: Affix = load("res://resources/affixes/blinde.tres")
	assert_gt(blinde.armor, 0.0)


## Nulle par défaut, la régénération ne doit rien faire du tout.
func test_sans_regeneration_la_vie_ne_bouge_pas() -> void:
	var e: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(e)
	var pv := e.health
	e.regen(1.0)
	assert_eq(e.health, pv)


func test_le_manager_pose_et_retire() -> void:
	var m := EnemyManager.new()
	add_child_autofree(m)
	var scene: PackedScene = load("res://actors/enemies/grunt.tscn")
	for i in 5:
		assert_not_null(m.spawn(scene, Vector2(i * 40, 0)))
	assert_eq(m.enemies.size(), 5)
	m.clear()
	await wait_physics_frames(2)
	assert_eq(m.enemies.size(), 0, "un vidage ne laisse personne")
