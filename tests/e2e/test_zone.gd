extends GutTest

## La partie qui joue toute seule : l'équivalent d'un Playwright. On charge la
## vraie zone, on la peuple, on se bat six cents images de physique avec les
## panneaux ouverts, et on regarde si quoi que ce soit casse.
##
## Lent (une vingtaine de secondes). C'est le prix d'un test qui traverse tout :
## génération, pilote d'ennemis, physique, mitigation, butin, interface.

const SEED := 4242
const FRAMES := 600
## Mesuré à la mise en place. Un écart franc signale une régression de
## génération ; ce n'est pas une valeur à ajuster quand le test échoue.
const EXPECTED_ENEMIES := 69

var _zone: Node2D
## Compteur de morts. Une variable membre et non une locale capturée par la
## lambda : en GDScript les closures capturent **par valeur**, et un compteur
## local incrémenté depuis un signal resterait à zéro.
var _deaths := 0


func before_each() -> void:
	# L'autoload survit d'un test à l'autre : un niveau laissé derrière soi
	# donnerait des ennemis mis à l'échelle dans les tests suivants, et une
	# mesure de combat qui n'aurait plus rien à voir avec ce qu'elle mesure.
	Game.zone_level = 1
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	await wait_physics_frames(1)
	_zone.generate_zone(SEED)
	_deaths = 0


## Une même graine doit redonner exactement la même zone : c'est ce qui permet
## de reproduire un bug de génération à partir d'un seul nombre.
##
## L'empreinte est prise **avant toute image de physique**. Une image plus tard,
## les corps se sont déjà repoussés les uns les autres et on mesurerait le
## tassement du tas, pas le placement — deux choses différentes, dont une seule
## est promise.
func test_a_seed_gives_the_same_zone_again() -> void:
	assert_eq(_zone.enemy_manager.enemies.size(), EXPECTED_ENEMIES)
	var first := _footprint()
	for i in 3:
		_zone.generate_zone(SEED)
		assert_eq(_footprint(), first, "relance %d identique" % (i + 1))


## Une carte neuve remplace l'ancienne **tout de suite**, collisions comprises.
## Les couches de tuiles ne reconstruisent les leurs qu'en fin d'image : le joueur
## posé sur l'apparition neuve chevauchait encore un mur de l'ancienne carte, et la
## physique l'en éjectait de seize pixels. Le cas était apparu par hasard, selon la
## graine qu'un test précédent laissait à `Game.rng` ; il est construit ici exprès.
func test_a_new_map_does_not_push_the_player_out_of_an_old_wall() -> void:
	var spawn_point: Vector2i = _zone.generator.get_spawn_cell()
	var walled_seed := -1
	for seed_value in range(1, 500):
		var trial := MapGenerator.new()
		trial.generate(seed_value)
		# Un vrai mur, dans les bornes : une case hors de la carte n'a pas de
		# collision, et le test passerait sans rien prouver.
		if (
			spawn_point.x < trial.width and spawn_point.y < trial.height
			and trial.grid[spawn_point.y][spawn_point.x] != MapGenerator.FLOOR
		):
			walled_seed = seed_value
			break
	assert_gt(walled_seed, 0, "une carte dont un mur couvre l'apparition de la graine %d" % SEED)

	_zone.generate_zone(walled_seed)
	# Les murs de cette carte-là entrent dans la physique avant qu'on la remplace.
	await wait_process_frames(2)
	_zone.generate_zone(SEED)
	var expected := MapGenerator.cell_center(spawn_point)
	assert_eq(_zone.player.global_position, expected, "posé sur l'apparition")
	# Sa première résolution de physique, jouée **tout de suite**. Attendre l'image
	# suivante ne prouverait rien : selon que le moteur enchaîne d'abord une image
	# de physique ou la fin d'image, les murs périmés ont déjà disparu ou non — et
	# ce test passait sans le correctif.
	_zone.player.velocity = Vector2.ZERO
	_zone.player.move_and_slide()
	assert_almost_eq(
		_zone.player.global_position, expected, Vector2.ONE,
		"aucun mur de l'ancienne carte ne le repousse"
	)


## Sans ce test, le précédent passerait aussi sur une génération cassée qui
## rendrait toujours la même chose.
func test_two_seeds_give_two_zones() -> void:
	var a := _footprint()
	_zone.generate_zone(SEED + 1)
	assert_ne(_footprint(), a)


func test_six_hundred_frames_of_dense_combat() -> void:
	var em: EnemyManager = _zone.enemy_manager
	var player: Player = _zone.player

	# On compte les morts par signal et non par différence de taille de liste :
	# si le joueur tombe, la zone se recharge et se repeuple, et une soustraction
	# annoncerait tranquillement zéro mort après un combat entier.
	for e in em.enemies:
		e.died.connect(func(_e: Enemy) -> void: _deaths += 1)

	# Les deux panneaux ouverts pendant tout le test : leur dessin doit encaisser
	# un combat complet, équipements et morts compris.
	_zone.stats_panel.toggle()
	_zone.inventory.toggle()

	for i in FRAMES:
		if not em.enemies.is_empty() and i % 40 == 0:
			var target: Enemy = em.enemies[0]
			if is_instance_valid(target):
				player.global_position = target.global_position + Vector2(10, 0)
		if not player.is_dead:
			# Les deux premières cases de la barre : le coup d'épée et le tir.
			# `cast_slot()` porte lui-même la recharge, la réserve et la compétence
			# apprise — l'appeler à chaque image ne lance rien de trop.
			player.cast_slot(0)
			player.cast_slot(1)

		# On ne se fie pas au hasard du contact : la fenêtre de la hitbox dépend
		# d'un timer réel, donc le nombre de coups qui portent varie d'un
		# lancement à l'autre. On force des dégâts de chaque nature pour que la
		# mitigation soit réellement traversée.
		var nature: DamageType.Kind = (i % DamageType.Kind.size()) as DamageType.Kind
		# Sur une copie : tuer un ennemi le retire de la liste qu'on parcourt.
		var targets := em.enemies.duplicate()
		for k in mini(3, targets.size()):
			var e: Enemy = targets[k]
			if is_instance_valid(e) and not e.is_dead:
				e.hurtbox.take_damage(DamageInfo.new(
					9.0, e.global_position + Vector2(6, 0), 0.0, false, nature
				))
		# Le joueur encaisse aussi, mais un coup sur dix : à chaque image il
		# mourrait au bout de quelques secondes, et le test mesurerait surtout le
		# rechargement de zone.
		if not player.is_dead and i % 10 == 0:
			player.hurtbox.take_damage(DamageInfo.new(
				2.0, player.global_position + Vector2(6, 0), 0.0, false, nature
			))

		# Un objet équipé puis retiré en plein combat : c'est là que le recalcul
		# de la fiche et la hurtbox peuvent se désynchroniser.
		if i % 97 == 0:
			player.equip(Item.new(
				load("res://resources/items/breastplate.tres"),
				[StatMod.new("armor", StatMod.Mode.FLAT, 30.0)]
			))
		elif i % 97 == 48:
			player.unequip("chest")

		await wait_physics_frames(1)

	gut.p("  %d ennemis tués, joueur niveau %d, %.0f PV, %.0f mana" % [
		_deaths, player.level, player.health, player.mana
	])
	assert_gt(_deaths, 0, "le combat a réellement eu lieu")
	assert_eq(player.hurtbox.stats, player.stats, "la hurtbox est restée liée")
	assert_gt(player.level, 1, "les morts ont rapporté de l'expérience")
	assert_between(player.mana, 0.0, player.stats.max_mana, "la réserve reste bornée")


## Par défaut la zone du test courant, mais on peut lui en donner une autre :
## comparer deux zones est exactement ce que le test du niveau vient faire.
func _footprint(zone: Node2D = _zone) -> int:
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
func test_an_enemy_behind_a_wall_gets_closer() -> void:
	_zone.kill_all()
	var player: Player = _zone.player
	var gen: MapGenerator = _zone.generator

	# Une case praticable loin du joueur, mais pas à vue : on prend la plus
	# éloignée du champ de vision direct parmi celles à bonne distance.
	var start := Vector2i(-1, -1)
	for cell in gen.floor_cells:
		var d := MapGenerator.cell_center(cell).distance_to(player.global_position)
		if d > 180.0 and d < 320.0:
			start = cell
			break
	assert_ne(start, Vector2i(-1, -1), "une case de départ a été trouvée")

	var grunt: Enemy = _zone.enemy_manager.spawn(
		load("res://actors/enemies/grunt.tscn"), MapGenerator.cell_center(start)
	)
	grunt.is_aggro = true
	var before: float = grunt.global_position.distance_to(player.global_position)

	# Le joueur ne bouge pas : on veut mesurer la poursuite, pas une rencontre.
	player.set_physics_process(false)
	await wait_physics_frames(240)

	var after: float = grunt.global_position.distance_to(player.global_position)
	assert_lt(
		after, before - 60.0,
		"le grunt s'est rapproché de %.0f px (de %.0f à %.0f)" % [before - after, before, after]
	)


# --------------------------------------------------------------------------
# Le niveau de zone (jalon 5, étape 6)
# --------------------------------------------------------------------------

## Le chemin complet du §2, de bout en bout : l\'écran de réglage pose le niveau
## sur l\'autoload, la zone le lit en naissant, les ennemis en héritent, et ce
## qu\'ils lâchent le porte.
func test_a_zone_takes_the_level_chosen_before_entering() -> void:
	Game.zone_level = 30
	var zone: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(zone)
	await wait_physics_frames(1)

	assert_eq(zone.enemy_manager.level, 30, "la zone a lu l\'autoload")
	var enemy: Enemy = zone.enemy_manager.enemies[0]
	assert_eq(enemy.level, 30, "et ses ennemis sont nés dedans")
	var weak: CharacterStats = load("res://resources/stats/grunt_stats.tres")
	assert_gt(enemy.stats.max_health, weak.max_health * 3.0, "nettement plus dur")

	# Le butin est un tirage : on tue toute la zone et on regarde ce qui reste
	# au sol. Soixante-neuf morts à 20 % de chance, il en tombe forcément.
	for e in zone.enemy_manager.enemies.duplicate():
		if is_instance_valid(e):
			e.die()
	await wait_physics_frames(2)

	var items_data := 0
	for l in zone.loot.get_children():
		items_data += 1
		assert_eq(
			l.data.item_level, 30,
			"« %s » porte le niveau de sa zone" % l.data.display_name()
		)
	assert_gt(items_data, 0, "au moins un objet est tombé")


## Le niveau n\'entre pas dans la graine, et c\'est ce qui permettra d\'équilibrer :
## deux zones de même graine et de niveaux différents ont les mêmes murs, les
## mêmes paquets aux mêmes cases, les mêmes silhouettes. Seule l\'échelle des
## ennemis change.
func test_the_level_does_not_change_the_map() -> void:
	var at_level_1 := _footprint()

	Game.zone_level = 45
	var zone: Node2D = load("res://world/zone.tscn").instantiate()
	add_child_autofree(zone)
	await wait_physics_frames(1)
	zone.generate_zone(SEED)

	assert_eq(_footprint(zone), at_level_1, "même graine, même carte, mêmes ennemis placés")
	assert_gt(
		zone.enemy_manager.enemies[0].stats.max_health,
		_zone.enemy_manager.enemies[0].stats.max_health,
		"seule leur échelle a changé"
	)


## Le niveau se choisit **dans la zone**, et prend effet à la génération
## suivante. Changer celui de la zone en cours donnerait une population mêlée :
## les ennemis sont mis à l\'échelle en naissant, ceux déjà debout ne bougeraient
## plus.
func test_the_chosen_level_takes_effect_at_the_next_generation() -> void:
	var before: float = _zone.enemy_manager.enemies[0].stats.max_health
	Game.change_zone_level(20)

	assert_eq(_zone.enemy_manager.level, 1, "la zone sous les pieds ne change pas")
	assert_eq(
		_zone.enemy_manager.enemies[0].stats.max_health, before,
		"ni les ennemis déjà debout"
	)

	_zone.generate_zone(SEED)
	assert_eq(_zone.enemy_manager.level, 21, "la zone suivante, si")
	assert_gt(
		_zone.enemy_manager.enemies[0].stats.max_health, before * 2.0,
		"et ses ennemis sont nés dedans"
	)
