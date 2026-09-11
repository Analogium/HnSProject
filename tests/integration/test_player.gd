extends GutTest

## Le joueur monté dans l'arbre : réserve de mana, régénérations, équipement et
## recalcul de la fiche. Rien de tout ça n'existe hors scène.

var _p: Player
## Retenu et pas seulement branché : le test des dégâts de sort a besoin d'aller
## regarder le tir qui vient d'en sortir.
var _tirs: Node2D


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	# Un parent dédié pour les tirs : sans lui ils naissent sous le script de
	# test et y restent après coup, ce que GUT signale en enfants non libérés.
	_tirs = Node2D.new()
	add_child_autofree(_tirs)
	_p.projectile_parent = _tirs
	await wait_physics_frames(1)


## Les valeurs sont exprimées à partir des constantes de dérivation et non en
## dur : un recalibrage des attributs ne doit pas faire échouer un test qui ne
## parle pas de calibrage.
func test_reserve_pleine_a_la_naissance() -> void:
	var attendu := 50.0 + 10.0 * CharacterStats.MANA_PER_INTELLIGENCE
	assert_eq(_p.stats.max_mana, attendu, "réserve de base plus l'intelligence")
	assert_eq(_p.mana, _p.stats.max_mana, "pleine")
	assert_eq(_p.health, _p.stats.max_health, "en pleine santé")


func test_le_tir_coute_du_mana() -> void:
	var avant := _p.mana
	_p.lancer(1)
	assert_eq(
		_p.mana, avant - CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR).cout_en_mana,
		"le coût exact, pas un de plus"
	)


## La nature du tir est écrite à deux endroits tant que la bille porte la sienne :
## sur la compétence, et sur la scène du projectile. Elles disent aujourd'hui la
## même chose, et ce test est ce qui l'exige — le jour où la compétence deviendra
## seule à décider, il tombera de lui-même.
func test_la_nature_du_tir_ne_diverge_pas_de_celle_de_la_bille() -> void:
	# Hors de l'arbre : montée, la bille avancerait et se libérerait toute seule.
	var bille: Projectile = load("res://actors/projectiles/player_bolt.tscn").instantiate()
	var nature: int = bille.damage_type
	bille.free()
	assert_eq(
		CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR).nature, nature,
		"« %s » et la bille annoncent la même nature" % CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR).nom
	)


func test_reserve_insuffisante_refuse_le_tir() -> void:
	_p._set_mana(2.0)
	_p.lancer(1)
	assert_eq(_p.mana, 2.0, "ni tir, ni prélèvement partiel")


func test_regenerations() -> void:
	_p._set_mana(10.0)
	_p._regen(1.0)
	assert_eq(_p.mana, 14.0, "4 de mana par seconde")
	_p._set_health(50.0)
	_p._regen(1.0)
	assert_eq(_p.health, 51.0, "1 PV par seconde")


func test_la_regeneration_ne_depasse_pas_le_plafond() -> void:
	_p._regen(10.0)
	assert_eq(_p.health, _p.stats.max_health)
	assert_eq(_p.mana, _p.stats.max_mana)


## La hurtbox reçoit la fiche courante, pas une copie périmée : recompute_stats
## en fabrique une neuve à chaque équipement.
func test_la_hurtbox_suit_la_fiche() -> void:
	assert_eq(_p.hurtbox.stats, _p.stats, "à la naissance")
	_p.equip(Item.new(load("res://resources/items/plastron.tres")))
	assert_eq(_p.hurtbox.stats, _p.stats, "après un équipement")
	_p.unequip("chest")
	assert_eq(_p.hurtbox.stats, _p.stats, "après un retrait")


func test_la_baguette_accelere_l_incantation_pas_la_lame() -> void:
	var recharge := _p.stats.attack_cooldown
	var incantation := _p.stats.cast_speed
	_p.equip(Item.new(load("res://resources/items/baguette.tres")))
	# Un pourcentage, donc il multiplie ce que l'intelligence a déjà donné.
	assert_almost_eq(_p.stats.cast_speed, incantation * 1.15, 0.001, "+15 %")
	assert_eq(_p.stats.attack_cooldown, recharge, "le corps à corps est intact")


## Le cœur du système d'équipement : un objet retiré ne laisse rien derrière lui,
## parce que recompute_stats repart toujours de la ressource du disque.
func test_un_objet_retire_ne_laisse_rien() -> void:
	var pv := _p.stats.max_health
	var mod := StatMod.new("armor", StatMod.Mode.FLAT, 40.0)
	_p.equip(Item.new(load("res://resources/items/plastron.tres"), [mod]))
	assert_eq(_p.stats.armor, 40.0)
	_p.unequip("chest")
	assert_eq(_p.stats.armor, 0.0)
	assert_eq(_p.stats.max_health, pv, "l'implicite est parti aussi")


## Retirer un plastron baisse le plafond : la vie courante doit le suivre, sinon
## la barre déborde et le joueur garde des PV qu'il n'a plus.
func test_les_pv_repassent_sous_le_nouveau_plafond() -> void:
	var sans_plastron := _p.stats.max_health
	_p.equip(Item.new(load("res://resources/items/plastron.tres")))
	_p._set_health(_p.stats.max_health)
	assert_gt(_p.health, sans_plastron, "le plastron a bien relevé le plafond")
	_p.unequip("chest")
	assert_eq(_p.health, sans_plastron, "la vie redescend avec le plafond")


## La ressource du disque n'est jamais écrite : aucun .tres du projet n'est
## resource_local_to_scene, l'y toucher contaminerait toutes les parties.
func test_la_fiche_du_disque_reste_intacte() -> void:
	_p.equip(Item.new(
		load("res://resources/items/plastron.tres"),
		[StatMod.new("max_health", StatMod.Mode.PERCENT, 50.0)]
	))
	var disque: CharacterStats = load("res://resources/stats/player_stats.tres")
	assert_eq(disque.max_health, 100.0, "le fichier n'a pas bougé")
	assert_ne(_p.stats, disque, "la copie de travail est distincte")


func test_le_sac_plein_laisse_l_objet_au_sol() -> void:
	var plastron: ItemBase = load("res://resources/items/plastron.tres")
	while _p.inventory.add(Item.new(plastron)):
		pass
	assert_false(_p.pick_up(Item.new(plastron)), "refusé, donc il reste au sol")


## Les attributs de départ arrivent bien dans la fiche, dérivation comprise.
func test_les_attributs_de_depart_sont_derives() -> void:
	assert_eq(_p.stats.strength, 10.0)
	assert_eq(
		_p.stats.max_health, 100.0 + 10.0 * CharacterStats.HEALTH_PER_STRENGTH,
		"PV de base plus ce que la force rapporte"
	)
	assert_eq(
		_p.stats.max_mana, 50.0 + 10.0 * CharacterStats.MANA_PER_INTELLIGENCE,
		"réserve de base plus ce que l'intelligence rapporte"
	)
	assert_gt(_p.stats.evasion, 0.0, "la dextérité donne enfin une source à l'esquive")


func test_une_montee_de_niveau_donne_des_points() -> void:
	assert_eq(_p.unspent_points, 0, "aucun point au départ")
	_p.gain_xp(_p.xp_to_next)
	assert_eq(_p.level, 2)
	assert_eq(_p.unspent_points, Player.POINTS_PER_LEVEL)


func test_placer_un_point_change_la_fiche() -> void:
	_p.gain_xp(_p.xp_to_next)
	var avant := _p.stats.max_health
	assert_true(_p.spend_point("strength"))
	assert_eq(_p.unspent_points, Player.POINTS_PER_LEVEL - 1)
	assert_eq(_p.stats.strength, 11.0)
	assert_eq(_p.stats.max_health, avant + CharacterStats.HEALTH_PER_STRENGTH)


func test_on_ne_place_pas_ce_qu_on_n_a_pas() -> void:
	assert_false(_p.spend_point("strength"), "aucun point disponible")
	_p.gain_xp(_p.xp_to_next)
	assert_false(_p.spend_point("charisme"), "attribut inconnu")
	assert_eq(_p.unspent_points, Player.POINTS_PER_LEVEL, "rien n'a été consommé")


## La répartition survit à un recalcul : elle est tenue sur le joueur et non sur
## `stats`, qui est reconstruite de zéro à chaque équipement.
func test_la_repartition_survit_a_un_equipement() -> void:
	_p.gain_xp(_p.xp_to_next)
	_p.spend_point("dexterity")
	var esquive := _p.stats.evasion
	_p.equip(Item.new(load("res://resources/items/plastron.tres")))
	_p.unequip("chest")
	assert_eq(_p.stats.dexterity, 11.0, "le point placé est toujours là")
	assert_eq(_p.stats.evasion, esquive)


## L'ordre du recalcul : les attributs doivent être définitifs avant qu'on en
## dérive quoi que ce soit, sinon un objet qui donne de la force ne rapporterait
## pas les points de vie correspondants.
func test_un_objet_qui_donne_de_la_force_donne_les_pv_qui_vont_avec() -> void:
	var avant := _p.stats.max_health
	_p.equip(Item.new(
		load("res://resources/items/plastron.tres"),
		[StatMod.new("strength", StatMod.Mode.FLAT, 20.0)]
	))
	assert_eq(_p.stats.strength, 30.0)
	assert_eq(
		_p.stats.max_health,
		avant + 20.0 + 20.0 * CharacterStats.HEALTH_PER_STRENGTH,
		"l'implicite du plastron, plus ce que les 20 de force rapportent"
	)


## Et la dérivation doit précéder les pourcentages, pour qu'un « +10 % PV »
## multiplie aussi ce que la force a donné.
func test_un_pourcentage_multiplie_aussi_les_pv_de_la_force() -> void:
	_p.equip(Item.new(
		load("res://resources/items/plastron.tres"),
		[StatMod.new("max_health", StatMod.Mode.PERCENT, 100.0)]
	))
	var attendu := (
		100.0 + 10.0 * CharacterStats.HEALTH_PER_STRENGTH + 20.0
	) * 2.0
	assert_eq(_p.stats.max_health, attendu, "base, force et implicite, tous doublés")


## Monter la force relève le plafond de vie : la barre doit suivre, sinon elle
## affiche un maximum que le joueur n'a pas.
func test_placer_un_point_ne_casse_pas_les_barres() -> void:
	_p.gain_xp(_p.xp_to_next)
	_p._set_health(10.0)
	_p.spend_point("strength")
	assert_eq(_p.health, 10.0, "la vie courante ne bouge pas")
	assert_lt(_p.health, _p.stats.max_health, "mais le plafond a monté")


# --------------------------------------------------------------------------
# Emplacements et familles (jalon 4)
# --------------------------------------------------------------------------

## Une base fabriquée en mémoire : les bases des dix familles arrivent à l'étape
## suivante du jalon, la règle d'équipement doit tenir avant elles.
func _bague(nom: String) -> Item:
	var base := ItemBase.new()
	base.id = "test_" + nom
	base.family = "ring"
	base.display_name = nom
	base.kind = "sword"
	return Item.new(base)


## Le défaut que le jalon 4 vient corriger : avant, le second anneau écrasait le
## premier — silencieusement, puisque rien ne disait que le doigt était pris.
func test_deux_anneaux_tiennent_sur_deux_doigts() -> void:
	var a := _bague("un")
	var b := _bague("deux")
	assert_null(_p.equip(a), "rien à remplacer")
	assert_null(_p.equip(b), "le second n'en remplace aucun")
	assert_eq(_p.equipped("ring_left"), a)
	assert_eq(_p.equipped("ring_right"), b)
	assert_eq(_p.equipment.size(), 2)


## Lâché sur un emplacement précis, l'objet y va — même si l'autre doigt est
## libre. Sans ça, le panneau ne pourrait pas viser la main droite.
func test_un_emplacement_impose_est_respecte() -> void:
	var a := _bague("un")
	_p.equip(a, "ring_right")
	assert_eq(_p.equipped("ring_right"), a)
	assert_null(_p.equipped("ring_left"), "le doigt gauche est resté libre")


func test_un_emplacement_impose_de_la_mauvaise_famille_est_refuse() -> void:
	var a := _bague("un")
	assert_eq(_p.equip(a, "amulet"), a, "rendu tel quel, jamais perdu")
	assert_eq(_p.equipment.size(), 0)


func test_un_objet_sans_famille_est_rendu_intact() -> void:
	var base := ItemBase.new()
	base.family = ""
	var caillou := Item.new(base)
	assert_eq(_p.equip(caillou), caillou)
	assert_eq(_p.equipment.size(), 0)


## Les deux doigts pris, on remplace celui de gauche et l'ancien revient à
## l'appelant : c'est lui qui décide s'il retourne au sac ou au sol.
func test_le_troisieme_anneau_rend_celui_qu_il_remplace() -> void:
	var a := _bague("un")
	_p.equip(a)
	_p.equip(_bague("deux"))
	assert_eq(_p.equip(_bague("trois")), a, "le premier doigt est rendu")
	assert_eq(_p.equipment.size(), 2, "toujours deux anneaux portés")


## Les dix emplacements entrent tous dans le calcul, pas seulement les deux
## d'avant : un bonus porté à un doigt doit se voir sur la fiche.
func test_un_anneau_compte_dans_la_fiche() -> void:
	var base := ItemBase.new()
	base.id = "test_anneau_armure"
	base.family = "ring"
	base.implicit_stat = "armor"
	base.implicit_value = 12.0
	var avant := _p.stats.armor
	_p.equip(Item.new(base))
	assert_eq(_p.stats.armor, avant + 12.0, "l'implicite de l'anneau est entré")
	_p.unequip("ring_left")
	assert_eq(_p.stats.armor, avant, "et il repart avec lui")


## L'invariant que l'affichage trahissait : la vie ne dépasse jamais le
## maximum, quel que soit le chemin qui a modifié la fiche. Le modèle était
## sain — c'était le texte qui mentait — et ce test est là pour qu'il le reste.
func test_la_vie_ne_depasse_jamais_le_maximum() -> void:
	var plastron := Item.new(load("res://resources/items/plastron.tres"))
	_p.equip(plastron)
	assert_lte(_p.health, _p.stats.max_health, "après avoir équipé")

	_p.gain_xp(3000)
	assert_lte(_p.health, _p.stats.max_health, "après plusieurs niveaux")

	_p.spend_point("strength")
	assert_lte(_p.health, _p.stats.max_health, "après un point de force")

	_p.unequip("chest")
	assert_lte(_p.health, _p.stats.max_health, "et après avoir retiré le plastron")

	_p._regen(100.0)
	assert_eq(_p.health, _p.stats.max_health, "la régénération s'arrête pile au plafond")


## Le tir reçoit ce que l'équipement ajoute aux sorts. C'est cette ligne qui rend
## une arme d'incantation offensive : sans elle, une baguette n'aurait rien à
## donner à un sort.
func test_le_tir_recoit_ce_que_l_equipement_ajoute_aux_sorts() -> void:
	_p.equip(Item.new(ItemCatalog.by_id("baguette"), [
		StatMod.fourchette("degats_foudre", 33.0, 33.0, MotsCles.SORT),
	]))
	_p.lancer(1)
	assert_eq(_tirs.get_child_count(), 1, "un tir est parti")
	var tir := _tirs.get_child(0) as Projectile
	assert_not_null(tir)
	assert_eq(tir._parts[DamageType.Kind.LIGHTNING], 7.0 + 33.0, "sa table, plus la baguette")


## La force ajoute ses dégâts physiques aux attaques, et à elles seules : le Trait
## est un sort.
func test_la_force_ajoute_du_physique_aux_attaques_seulement() -> void:
	assert_gt(_p.stats.degats_de_force(), 0.0, "la fiche de départ a de la force")
	var attaque := _p.resoudre(CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE), 1)
	assert_almost_eq(
		attaque.degats_min[DamageType.Kind.PHYSICAL], 12.0 + _p.stats.degats_de_force(), 0.0001
	)
	assert_eq(_p.resoudre(CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR), 1).degats_min[DamageType.Kind.PHYSICAL], 0.0)


## **La séparation des deux familles**, vue depuis le joueur : une épée ajoute ses
## dégâts à l'Attaque, et le Trait n'en voit rien.
func test_une_epee_ajoute_ses_degats_a_l_attaque_et_pas_au_trait() -> void:
	var epee := ItemCatalog.by_id("epee")
	var attaque_avant := _p.resoudre(CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE), 1)
	var tir_avant := _p.resoudre(CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR), 1).total_max()
	_p.equip(Item.new(epee))
	var attaque := _p.resoudre(CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE), 1)
	assert_almost_eq(attaque.total_min(), attaque_avant.total_min() + epee.implicit_value, 0.0001)
	assert_almost_eq(attaque.total_max(), attaque_avant.total_max() + epee.implicit_value_max, 0.0001)
	assert_eq(_p.resoudre(CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR), 1).total_max(), tir_avant, "le Trait n'a rien reçu")


## Le personnage et les manuels montent sur la **même fonction**, avec leurs
## propres constantes. Deux exponentielles écrites côte à côte finiraient par
## diverger d'un arrondi, et personne ne saurait laquelle est la bonne.
func test_la_courbe_du_personnage_est_la_courbe_partagee() -> void:
	for niveau in [1, 2, 7, 30]:
		assert_eq(
			_p._needed_for(niveau),
			Progression.cout_du_niveau(niveau, Player.XP_BASE, Player.XP_POWER),
			"le palier %d" % niveau
		)


# --------------------------------------------------------------------------
# La barre de compétences (jalon 6, étape 6)
# --------------------------------------------------------------------------

func _livre_travaille() -> Item:
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.gagner_experience(999999)
	livre.manuel.investir(livre.base.manuel, "eclair_vif")
	return livre


## Ce qu'on peut poser dans une case : les deux attaques de départ, et ce qu'on a
## réellement appris dans les livres à l'étude. Une case à zéro point n'y est pas
## — on ne propose pas de mettre sous les doigts ce qui ne fait rien.
func test_ce_qu_on_peut_poser_dans_une_case() -> void:
	var noms := []
	for c in _p.competences_disponibles():
		noms.append(c.id)
	assert_eq(noms, [CompetenceCatalog.ID_ATTAQUE, CompetenceCatalog.ID_TIR], "les deux de départ")

	_p.etudier(_livre_travaille())
	noms = []
	for c in _p.competences_disponibles():
		noms.append(c.id)
	assert_true(noms.has("eclair_vif"), "la case où l'on a mis un point")
	assert_false(noms.has("nova_de_foudre"), "mais pas celles restées vides")


func test_les_points_d_une_competence_viennent_du_livre_qui_l_enseigne() -> void:
	assert_eq(_p.points_de_competence("eclair_vif"), 0, "aucun livre à l'étude")
	assert_eq(
		_p.points_de_competence(CompetenceCatalog.ID_ATTAQUE), 1,
		"les attaques de départ ne s'apprennent pas"
	)
	_p.etudier(_livre_travaille())
	assert_eq(_p.points_de_competence("eclair_vif"), 1)


## Le lancement porte lui-même ses quatre refus : aucun appelant n'a à les
## refaire, et c'est ce qui permet à la touche, à la barre et aux tests de passer
## par le même chemin.
func test_lancer_refuse_ce_qu_on_n_a_pas_appris() -> void:
	_p.barre.poser(2, "eclair_vif")
	assert_false(_p.lancer(2), "la compétence n'est dans aucun livre à l'étude")
	assert_eq(_tirs.get_child_count(), 0)

	_p.etudier(_livre_travaille())
	assert_true(_p.lancer(2), "le livre à l'étude la rend lançable")
	assert_eq(_tirs.get_child_count(), 1)


func test_lancer_refuse_une_case_vide_et_une_recharge_en_cours() -> void:
	assert_false(_p.lancer(4), "la cinquième case est vide")
	assert_true(_p.lancer(1), "le tir part")
	assert_false(_p.lancer(1), "et ne repart pas tant qu'il se recharge")


## L'éventail : trois projectiles pour une salve, huit pour une nova, et un seul
## qui part droit devant quoi qu'annonce la dispersion.
func test_une_salve_part_en_eventail() -> void:
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.gagner_experience(999999)
	livre.manuel.investir(livre.base.manuel, "salve_d_eclairs")
	_p.etudier(livre)
	_p.stats.max_mana = 999.0
	_p._set_mana(999.0)

	_p.barre.poser(3, "salve_d_eclairs")
	assert_true(_p.lancer(3))
	assert_eq(_tirs.get_child_count(), 3, "trois traits")

	var angles := []
	for tir in _tirs.get_children():
		angles.append(snappedf(rad_to_deg((tir as Projectile)._dir.angle()), 0.1))
	assert_eq(angles.size(), 3)
	assert_ne(angles[0], angles[1], "et ils ne partent pas tous au même endroit")


## Et l'autre bout : un projectile unique part **exactement** dans la visée.
##
## Le test manquait, et la répartition en éventail traitait le cas à part pour
## cette raison. Il tient maintenant tout seul — pas nul et départ nul font une
## rotation qui ne tourne pas — mais c'était vrai sans que rien ne le vérifie, et
## une dispersion recopiée par erreur sur le trait de base ferait tirer à côté de
## la souris sans qu'aucune assertion ne s'en aperçoive.
func test_un_trait_seul_part_droit_dans_la_visee() -> void:
	_p.facing = Vector2(0.6, -0.8)
	assert_true(_p.lancer(1), "le tir de départ")
	assert_eq(_tirs.get_child_count(), 1, "un seul trait")
	assert_eq(
		(_tirs.get_child(0) as Projectile)._dir, _p.facing,
		"la direction de la visée, au bit près"
	)


# --------------------------------------------------------------------------
# Le lancer passe par la résolution (jalon 7, étape 3)
# --------------------------------------------------------------------------

## Un point dans chaque case du manuel de la foudre.
func _livre_ouvert_partout() -> Item:
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.gagner_experience(999999)
	for case in livre.base.manuel.cases:
		livre.manuel.investir(livre.base.manuel, case.competence.id)
	return livre


## Les tirs lancés jusqu'ici, retirés tout de suite : le test suivant compte ceux
## de son propre lancer.
func _vider_les_tirs() -> void:
	for tir in _tirs.get_children():
		_tirs.remove_child(tir)
		tir.free()


## **Le test qui garantit que l'étape n'a rien changé au jeu** : sans rien porter,
## chaque sort part avec exactement les nombres de sa fiche — combien de traits, à
## quelle vitesse, pour quels dégâts, quel coût et quelle recharge.
func test_chaque_sort_part_avec_les_nombres_de_sa_fiche() -> void:
	_p.etudier(_livre_ouvert_partout())
	_p.stats.max_mana = 999.0

	for id in [CompetenceCatalog.ID_TIR, "eclair_vif", "salve_d_eclairs", "fulguration", "nova_de_foudre"]:
		var c := CompetenceCatalog.by_id(id)
		var points := _p.points_de_competence(id)
		assert_gt(points, 0, "« %s » est apprise" % c.nom)
		_p.barre.poser(4, id)
		_p._recharges[4] = 0.0
		_p._set_mana(999.0)
		_vider_les_tirs()

		assert_true(_p.lancer(4), "« %s » part" % c.nom)
		assert_eq(_tirs.get_child_count(), c.projectiles, "« %s » : traits" % c.nom)
		for tir: Projectile in _tirs.get_children():
			assert_eq(tir._parts[c.nature], c.degats(points, _p.stats), "« %s » : dégâts" % c.nom)
			assert_eq(
				DamageInfo.en_parts(tir._parts, Vector2.ZERO).amount, c.degats(points, _p.stats),
				"« %s » : et aucune autre nature" % c.nom
			)
			assert_eq(tir.speed, c.vitesse_de_projectile, "« %s » : vitesse" % c.nom)
		assert_eq(_p.mana, 999.0 - c.cout_en_mana, "« %s » : coût" % c.nom)
		# À la précision d'un réel sur 32 bits, qui est celle de `_recharges` : la
		# valeur rangée n'est pas celle calculée au bit près, et elle ne l'était pas
		# davantage avant la résolution.
		assert_almost_eq(
			_p.recharge_restante(4), c.intervalle(_p.stats), 1e-6, "« %s » : recharge" % c.nom
		)


func test_un_tir_porte_d_un_projectile_de_plus_en_sort_deux() -> void:
	_p.mods_de_competence.assign([
		StatMod.new("projectiles", StatMod.Mode.FLAT, 1.0, MotsCles.PROJECTILE),
	])
	assert_true(_p.lancer(1), "le tir de départ")
	assert_eq(_tirs.get_child_count(), 2, "deux traits")
	var a := (_tirs.get_child(0) as Projectile)._dir
	var b := (_tirs.get_child(1) as Projectile)._dir
	assert_almost_eq(
		rad_to_deg(absf(a.angle_to(b))), StatsDeCompetence.ECART_MINIMAL, 0.01,
		"et ils ne partent pas l'un sur l'autre"
	)


## Une fourchette ajoutée se tire **par trait** : trois traits d'une salve ne
## portent pas le même froid, sinon ils se liraient comme un coup recopié.
func test_chaque_trait_tire_sa_fourchette() -> void:
	var livre := Item.new(ItemCatalog.by_id("manuel_foudre"))
	livre.manuel.gagner_experience(999999)
	livre.manuel.investir(livre.base.manuel, "salve_d_eclairs")
	_p.etudier(livre)
	_p.stats.max_mana = 999.0
	_p._set_mana(999.0)
	_p.mods_de_competence.assign([
		StatMod.fourchette("degats_froid", 1.0, 1000.0, MotsCles.SORT),
	])

	_p.barre.poser(3, "salve_d_eclairs")
	assert_true(_p.lancer(3))
	var froids := {}
	for tir: Projectile in _tirs.get_children():
		froids[tir._parts[DamageType.Kind.COLD]] = true
	assert_eq(froids.size(), 3, "trois traits, trois tirages")


## Un coup d'épée tire **une** fois : tous les ennemis de l'arc reçoivent la même
## valeur. Critique coupé, pour ne comparer que le tirage de la fourchette.
func test_un_coup_d_epee_frappe_tout_l_arc_de_la_meme_valeur() -> void:
	_p.stats.crit_chance = 0.0
	_p.mods_de_competence.assign([
		StatMod.fourchette("degats_feu", 1.0, 1000.0, MotsCles.ATTAQUE),
	])
	assert_true(_p.lancer(0), "le coup de base")

	var recus: Array[float] = []
	for i in 2:
		var cible := Hurtbox.new()
		add_child_autofree(cible)
		cible.damaged.connect(
			func(info: DamageInfo) -> void: recus.append(info.parts[DamageType.Kind.FIRE])
		)
		_p._on_hitbox_area_entered(cible)
	assert_eq(recus.size(), 2, "les deux cibles sont touchées")
	assert_eq(recus[0], recus[1], "par la même valeur")
	assert_gt(recus[0], 0.0, "et le feu ajouté est bien dedans")
	# Le geste attend la fin de son arc et le gel d'impact : on le laisse finir
	# plutôt que de libérer le joueur au milieu.
	await wait_seconds(0.4)


# --------------------------------------------------------------------------
# L'affixe porté (jalon 7, étape 4)
# --------------------------------------------------------------------------

func _baguette(affixes: Array[String]) -> Item:
	var mods: Array = []
	for id in affixes:
		var affixe := ItemAffixPool.by_id(id)
		mods.append(affixe.modificateur(affixe.tiers[0].max_value))
	return Item.new(ItemCatalog.by_id("baguette"), mods)


func test_un_objet_porte_ajoute_son_projectile_et_le_retirer_le_reprend() -> void:
	var tir := CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR)
	assert_eq(_p.resoudre(tir, 1).nombre_de_projectiles(), 1, "à mains nues")
	_p.equip(_baguette(["fourchu"] as Array[String]))
	assert_eq(_p.resoudre(tir, 1).nombre_de_projectiles(), 3, "le T1 de « fourchu » : +2")
	_p.unequip("weapon")
	assert_eq(_p.resoudre(tir, 1).nombre_de_projectiles(), 1, "et il repart avec l'objet")


## **La confusion des deux familles**, vue depuis le joueur : un objet dont tous
## les affixes visent un mot-clé ne change **aucun** champ de la fiche. S'il en
## changeait un, le bonus compterait deux fois — et seulement pour certaines
## compétences.
func test_un_affixe_porte_n_ecrit_rien_sur_la_fiche() -> void:
	_p.equip(_baguette([] as Array[String]))
	var nue := _champs(_p.stats)
	_p.equip(_baguette(["fourchu", "sifflant", "orageux"] as Array[String]))
	assert_eq_deep(_champs(_p.stats), nue)
	assert_eq(_p.mods_de_competence.size(), 1 + 3, "la force, et les trois partent au lancer")


## Tous les champs d'une fiche, pour la comparer à une autre sans en oublier un.
func _champs(fiche: CharacterStats) -> Dictionary:
	var out := {}
	for propriete in fiche.get_property_list():
		if propriete["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE:
			out[propriete["name"]] = fiche.get(propriete["name"])
	return out


## Retirer un livre du râtelier vide les cases qui pointaient dessus : une case
## qui annonce un sort inlançable se découvre au pire moment.
func test_ranger_un_livre_vide_les_cases_qui_le_designaient() -> void:
	_p.etudier(_livre_travaille())
	_p.barre.poser(2, "eclair_vif")
	_p.cesser_d_etudier(0)
	assert_eq(_p.barre.id_de(2), "", "la case est vide")
	assert_eq(_p.barre.id_de(0), CompetenceCatalog.ID_ATTAQUE, "les attaques de départ restent")


## Mais pas si un autre livre du râtelier l'enseigne encore : la question est
## « la sait-on toujours », pas « d'où venait-elle ».
func test_un_second_livre_garde_la_case_pleine() -> void:
	_p.etudier(_livre_travaille(), 0)
	_p.etudier(_livre_travaille(), 1)
	_p.barre.poser(2, "eclair_vif")
	_p.cesser_d_etudier(0)
	assert_eq(_p.barre.id_de(2), "eclair_vif", "l'autre livre l'enseigne toujours")
