extends GutTest

## La partie qui joue toute seule : l'équivalent d'un Playwright. On charge la
## vraie zone, on la peuple, on se bat six cents images de physique avec les
## panneaux ouverts, et on regarde si quoi que ce soit casse.
##
## Lent (une vingtaine de secondes). C'est le prix d'un test qui traverse tout :
## génération, pilote d'ennemis, physique, mitigation, butin, interface.

const GRAINE := 4242
const IMAGES := 600
## Mesuré à la mise en place. Un écart franc signale une régression de
## génération ; ce n'est pas une valeur à ajuster quand le test échoue.
const ENNEMIS_ATTENDUS := 69

var _zone: Node2D
## Compteur de morts. Une variable membre et non une locale capturée par la
## lambda : en GDScript les closures capturent **par valeur**, et un compteur
## local incrémenté depuis un signal resterait à zéro.
var _morts := 0


func before_each() -> void:
	# L'autoload survit d'un test à l'autre : un niveau laissé derrière soi
	# donnerait des ennemis mis à l'échelle dans les tests suivants, et une
	# mesure de combat qui n'aurait plus rien à voir avec ce qu'elle mesure.
	Game.niveau_de_zone = 1
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	await wait_physics_frames(1)
	_zone.generate_zone(GRAINE)
	_morts = 0


## Une même graine doit redonner exactement la même zone : c'est ce qui permet
## de reproduire un bug de génération à partir d'un seul nombre.
##
## L'empreinte est prise **avant toute image de physique**. Une image plus tard,
## les corps se sont déjà repoussés les uns les autres et on mesurerait le
## tassement du tas, pas le placement — deux choses différentes, dont une seule
## est promise.
func test_une_graine_redonne_la_meme_zone() -> void:
	assert_eq(_zone.enemy_manager.enemies.size(), ENNEMIS_ATTENDUS)
	var premier := _empreinte()
	for i in 3:
		_zone.generate_zone(GRAINE)
		assert_eq(_empreinte(), premier, "relance %d identique" % (i + 1))


## Sans ce test, le précédent passerait aussi sur une génération cassée qui
## rendrait toujours la même chose.
func test_deux_graines_donnent_deux_zones() -> void:
	var a := _empreinte()
	_zone.generate_zone(GRAINE + 1)
	assert_ne(_empreinte(), a)


func test_six_cents_images_de_combat_dense() -> void:
	var em: EnemyManager = _zone.enemy_manager
	var joueur: Player = _zone.player

	# On compte les morts par signal et non par différence de taille de liste :
	# si le joueur tombe, la zone se recharge et se repeuple, et une soustraction
	# annoncerait tranquillement zéro mort après un combat entier.
	for e in em.enemies:
		e.died.connect(func(_e: Enemy) -> void: _morts += 1)

	# Les deux panneaux ouverts pendant tout le test : leur dessin doit encaisser
	# un combat complet, équipements et morts compris.
	_zone.stats_panel.toggle()
	_zone.inventory.toggle()

	for i in IMAGES:
		if not em.enemies.is_empty() and i % 40 == 0:
			var cible: Enemy = em.enemies[0]
			if is_instance_valid(cible):
				joueur.global_position = cible.global_position + Vector2(10, 0)
		if not joueur.is_dead:
			# Les deux premières cases de la barre : le coup d'épée et le tir.
			# `lancer()` porte lui-même la recharge, la réserve et la compétence
			# apprise — l'appeler à chaque image ne lance rien de trop.
			joueur.lancer(0)
			joueur.lancer(1)

		# On ne se fie pas au hasard du contact : la fenêtre de la hitbox dépend
		# d'un timer réel, donc le nombre de coups qui portent varie d'un
		# lancement à l'autre. On force des dégâts de chaque nature pour que la
		# mitigation soit réellement traversée.
		var nature: DamageType.Kind = (i % DamageType.Kind.size()) as DamageType.Kind
		# Sur une copie : tuer un ennemi le retire de la liste qu'on parcourt.
		var cibles := em.enemies.duplicate()
		for k in mini(3, cibles.size()):
			var e: Enemy = cibles[k]
			if is_instance_valid(e) and not e.is_dead:
				e.hurtbox.take_damage(DamageInfo.new(
					9.0, e.global_position + Vector2(6, 0), 0.0, false, nature
				))
		# Le joueur encaisse aussi, mais un coup sur dix : à chaque image il
		# mourrait au bout de quelques secondes, et le test mesurerait surtout le
		# rechargement de zone.
		if not joueur.is_dead and i % 10 == 0:
			joueur.hurtbox.take_damage(DamageInfo.new(
				2.0, joueur.global_position + Vector2(6, 0), 0.0, false, nature
			))

		# Un objet équipé puis retiré en plein combat : c'est là que le recalcul
		# de la fiche et la hurtbox peuvent se désynchroniser.
		if i % 97 == 0:
			joueur.equip(Item.new(
				load("res://resources/items/plastron.tres"),
				[StatMod.new("armor", StatMod.Mode.FLAT, 30.0)]
			))
		elif i % 97 == 48:
			joueur.unequip("chest")

		await wait_physics_frames(1)

	gut.p("  %d ennemis tués, joueur niveau %d, %.0f PV, %.0f mana" % [
		_morts, joueur.level, joueur.health, joueur.mana
	])
	assert_gt(_morts, 0, "le combat a réellement eu lieu")
	assert_eq(joueur.hurtbox.stats, joueur.stats, "la hurtbox est restée liée")
	assert_gt(joueur.level, 1, "les morts ont rapporté de l'expérience")
	assert_between(joueur.mana, 0.0, joueur.stats.max_mana, "la réserve reste bornée")


## Par défaut la zone du test courant, mais on peut lui en donner une autre :
## comparer deux zones est exactement ce que le test du niveau vient faire.
func _empreinte(zone: Node2D = _zone) -> int:
	var h := 0
	for e in zone.enemy_manager.enemies:
		h = hash([h, Vector2i(e.global_position.round()), e.affixes.size()])
	return h


## Le défaut que le champ de flux vient corriger, joué dans la vraie zone : un
## grunt lâché derrière une paroi fonçait dedans et y restait jusqu'à ce qu'on
## vienne le chercher.
##
## On mesure la distance parcourue vers le joueur, pas l'arrivée : un ennemi qui
## se rapproche franchement a contourné, celui qui pousse contre la pierre reste
## où il est.
func test_un_ennemi_derriere_un_mur_se_rapproche() -> void:
	_zone.kill_all()
	var joueur: Player = _zone.player
	var gen: MapGenerator = _zone.generator

	# Une case praticable loin du joueur, mais pas à vue : on prend la plus
	# éloignée du champ de vision direct parmi celles à bonne distance.
	var depart := Vector2i(-1, -1)
	for cell in gen.floor_cells:
		var d := MapGenerator.cell_center(cell).distance_to(joueur.global_position)
		if d > 180.0 and d < 320.0:
			depart = cell
			break
	assert_ne(depart, Vector2i(-1, -1), "une case de départ a été trouvée")

	var grunt: Enemy = _zone.enemy_manager.spawn(
		load("res://actors/enemies/grunt.tscn"), MapGenerator.cell_center(depart)
	)
	grunt.is_aggro = true
	var avant: float = grunt.global_position.distance_to(joueur.global_position)

	# Le joueur ne bouge pas : on veut mesurer la poursuite, pas une rencontre.
	joueur.set_physics_process(false)
	await wait_physics_frames(240)

	var apres: float = grunt.global_position.distance_to(joueur.global_position)
	assert_lt(
		apres, avant - 60.0,
		"le grunt s'est rapproché de %.0f px (de %.0f à %.0f)" % [avant - apres, avant, apres]
	)


# --------------------------------------------------------------------------
# Le niveau de zone (jalon 5, étape 6)
# --------------------------------------------------------------------------

## Le chemin complet du §2, de bout en bout : l\'écran de réglage pose le niveau
## sur l\'autoload, la zone le lit en naissant, les ennemis en héritent, et ce
## qu\'ils lâchent le porte.
func test_une_zone_prend_le_niveau_choisi_avant_d_y_entrer() -> void:
	Game.niveau_de_zone = 30
	var zone: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(zone)
	await wait_physics_frames(1)

	assert_eq(zone.enemy_manager.niveau, 30, "la zone a lu l\'autoload")
	var ennemi: Enemy = zone.enemy_manager.enemies[0]
	assert_eq(ennemi.niveau, 30, "et ses ennemis sont nés dedans")
	var faible: CharacterStats = load("res://resources/stats/grunt_stats.tres")
	assert_gt(ennemi.stats.max_health, faible.max_health * 3.0, "nettement plus dur")

	# Le butin est un tirage : on tue toute la zone et on regarde ce qui reste
	# au sol. Soixante-neuf morts à 20 % de chance, il en tombe forcément.
	for e in zone.enemy_manager.enemies.duplicate():
		if is_instance_valid(e):
			e.die()
	await wait_physics_frames(2)

	var objets := 0
	for l in zone.loot.get_children():
		objets += 1
		assert_eq(
			l.data.item_level, 30,
			"« %s » porte le niveau de sa zone" % l.data.display_name()
		)
	assert_gt(objets, 0, "au moins un objet est tombé")


## Le niveau n\'entre pas dans la graine, et c\'est ce qui permettra d\'équilibrer :
## deux zones de même graine et de niveaux différents ont les mêmes murs, les
## mêmes paquets aux mêmes cases, les mêmes silhouettes. Seule l\'échelle des
## ennemis change.
func test_le_niveau_ne_change_pas_la_carte() -> void:
	var au_niveau_1 := _empreinte()

	Game.niveau_de_zone = 45
	var zone: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(zone)
	await wait_physics_frames(1)
	zone.generate_zone(GRAINE)

	assert_eq(_empreinte(zone), au_niveau_1, "même graine, même carte, mêmes ennemis placés")
	assert_gt(
		zone.enemy_manager.enemies[0].stats.max_health,
		_zone.enemy_manager.enemies[0].stats.max_health,
		"seule leur échelle a changé"
	)


## Le niveau se choisit **dans la zone**, et prend effet à la génération
## suivante. Changer celui de la zone en cours donnerait une population mêlée :
## les ennemis sont mis à l\'échelle en naissant, ceux déjà debout ne bougeraient
## plus.
func test_le_niveau_choisi_prend_effet_a_la_generation_suivante() -> void:
	var avant: float = _zone.enemy_manager.enemies[0].stats.max_health
	Game.changer_niveau_de_zone(20)

	assert_eq(_zone.enemy_manager.niveau, 1, "la zone sous les pieds ne change pas")
	assert_eq(
		_zone.enemy_manager.enemies[0].stats.max_health, avant,
		"ni les ennemis déjà debout"
	)

	_zone.generate_zone(GRAINE)
	assert_eq(_zone.enemy_manager.niveau, 21, "la zone suivante, si")
	assert_gt(
		_zone.enemy_manager.enemies[0].stats.max_health, avant * 2.0,
		"et ses ennemis sont nés dedans"
	)
