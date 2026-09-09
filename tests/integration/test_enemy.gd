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


# --------------------------------------------------------------------------
# Ce qu'une mort rapporte aux manuels (jalon 6, étape 4)
# --------------------------------------------------------------------------

## Un joueur, son pilote d'ennemis et un grunt prêt à mourir. Le manager est
## monté nu : sans carte ni champ de flux, ce qui suffit à `report_kill`.
func _scene_de_mise_a_mort() -> Array:
	var joueur: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(joueur)
	var manager := EnemyManager.new()
	add_child_autofree(manager)
	manager.target = joueur
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(grunt)
	await wait_physics_frames(1)
	return [joueur, manager, grunt]


func _livre() -> Item:
	return Item.new(ItemCatalog.by_id("manuel_foudre"))


## Le râtelier est le seul endroit où un manuel apprend.
func test_les_manuels_du_ratelier_apprennent_de_chaque_mort() -> void:
	var scene := await _scene_de_mise_a_mort()
	var joueur: Player = scene[0]
	var manager: EnemyManager = scene[1]
	var grunt: Enemy = scene[2]

	var etudie := _livre()
	joueur.ratelier.poser(0, etudie)
	manager.report_kill(grunt)
	# Une image avant de conclure : la chute d'un objet passe par
	# `add_child.call_deferred()` (invariant 4), et sans elle le GroundItem est
	# créé sans jamais entrer dans l'arbre — donc jamais libéré.
	await wait_physics_frames(1)

	assert_gt(etudie.manuel.experience, 0, "le livre à l'étude a appris")
	assert_eq(
		etudie.manuel.experience, joueur.xp,
		"du même montant que son porteur, non divisé"
	)


## Celui qui dort dans le sac ne gagne rien : c'est ce qui donne son poids au
## choix des trois.
func test_un_manuel_dans_le_sac_n_apprend_rien() -> void:
	var scene := await _scene_de_mise_a_mort()
	var joueur: Player = scene[0]
	var manager: EnemyManager = scene[1]
	var grunt: Enemy = scene[2]

	var range := _livre()
	joueur.pick_up(range)
	manager.report_kill(grunt)
	# Une image avant de conclure : la chute d'un objet passe par
	# `add_child.call_deferred()` (invariant 4), et sans elle le GroundItem est
	# créé sans jamais entrer dans l'arbre — donc jamais libéré.
	await wait_physics_frames(1)

	assert_eq(range.manuel.experience, 0)
	assert_gt(joueur.xp, 0, "le personnage, lui, a bien gagné")


## Trois manuels reçoivent chacun le tout : un deuxième livre doit être une
## ouverture, pas un handicap.
func test_trois_manuels_recoivent_chacun_le_tout() -> void:
	var scene := await _scene_de_mise_a_mort()
	var joueur: Player = scene[0]
	var manager: EnemyManager = scene[1]
	var grunt: Enemy = scene[2]

	var livres := [_livre(), _livre(), _livre()]
	for i in livres.size():
		joueur.ratelier.poser(i, livres[i])
	manager.report_kill(grunt)
	# Une image avant de conclure : la chute d'un objet passe par
	# `add_child.call_deferred()` (invariant 4), et sans elle le GroundItem est
	# créé sans jamais entrer dans l'arbre — donc jamais libéré.
	await wait_physics_frames(1)

	for livre in livres:
		assert_eq(livre.manuel.experience, joueur.xp, "chacun le montant entier")


## Ce que le personnage gagne n'a pas bougé d'un point : le manuel est une
## seconde récompense, jamais un prélèvement sur la première.
func test_le_personnage_gagne_exactement_ce_qu_il_gagnait() -> void:
	var scene := await _scene_de_mise_a_mort()
	var joueur: Player = scene[0]
	var manager: EnemyManager = scene[1]
	var grunt: Enemy = scene[2]

	var attendu := maxi(roundi(
		grunt.xp_value() * Enemy.facteur_d_experience(manager.niveau, joueur.level)
	), 1)
	joueur.ratelier.poser(0, _livre())
	manager.report_kill(grunt)
	# Une image avant de conclure : la chute d'un objet passe par
	# `add_child.call_deferred()` (invariant 4), et sans elle le GroundItem est
	# créé sans jamais entrer dans l'arbre — donc jamais libéré.
	await wait_physics_frames(1)

	assert_eq(joueur.xp, attendu, "la règle d'avant, inchangée")
