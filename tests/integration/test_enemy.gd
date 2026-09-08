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


# --------------------------------------------------------------------------
# Le niveau de zone (jalon 5, étape 6)
# --------------------------------------------------------------------------

## Le manager pose le niveau **avant** l\'entrée dans l\'arbre : c\'est _ready qui
## met la fiche à l\'échelle, et le poser après donnerait un ennemi de niveau 1
## portant une étiquette de niveau 40.
func test_un_ennemi_nait_au_niveau_de_sa_zone() -> void:
	var m := EnemyManager.new()
	m.niveau = 40
	add_child_autofree(m)
	var scene: PackedScene = load("res://actors/enemies/grunt.tscn")
	var faible: CharacterStats = load("res://resources/stats/grunt_stats.tres")

	var e := m.spawn(scene, Vector2(500, 500))
	assert_eq(e.niveau, 40)
	assert_gt(e.stats.max_health, faible.max_health * 7.0, "huit fois la vie, affixes en plus")
	assert_eq(e.health, e.stats.max_health, "et il naît en pleine santé")


## Le piège que la mise à l\'échelle rouvre : la fiche d\'un archétype est un
## `.tres` partagé par tous ses exemplaires, et aucun n\'est
## resource_local_to_scene. Écrire dedans multiplierait la vie de **tous** les
## grunts de la session — et l\'éditeur pourrait graver le résultat dans le
## fichier. Le même test existe pour les affixes ; celui-ci garde l\'autre
## écrivain.
func test_la_mise_a_l_echelle_ne_touche_pas_la_ressource_partagee() -> void:
	var disque: CharacterStats = load("res://resources/stats/grunt_stats.tres")
	var avant := disque.max_health
	var m := EnemyManager.new()
	m.niveau = 55
	add_child_autofree(m)
	var scene: PackedScene = load("res://actors/enemies/grunt.tscn")
	for i in 8:
		m.spawn(scene, Vector2(i * 41, i * 67))
	assert_eq(disque.max_health, avant, "grunt_stats.tres est intact")


## Les scènes sans niveau — l\'arène de réglage, le banc de stress — laissent le
## manager à 1, et leurs ennemis doivent rester exactement ce qu\'ils étaient.
func test_sans_niveau_pose_l_ennemi_reste_au_premier() -> void:
	var m := EnemyManager.new()
	add_child_autofree(m)
	var e := m.spawn(load("res://actors/enemies/grunt.tscn"), Vector2(300, 300))
	var disque: CharacterStats = load("res://resources/stats/grunt_stats.tres")
	assert_eq(e.niveau, 1)
	assert_almost_eq(e.stats.max_health, disque.max_health, 0.001)
