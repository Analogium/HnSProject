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
			if joueur._attack_cd <= 0.0:
				joueur._swing()
			if joueur._bolt_cd <= 0.0:
				joueur._shoot()

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


func _empreinte() -> int:
	var h := 0
	for e in _zone.enemy_manager.enemies:
		h = hash([h, Vector2i(e.global_position.round()), e.affixes.size()])
	return h
