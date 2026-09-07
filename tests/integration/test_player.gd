extends GutTest

## Le joueur monté dans l'arbre : réserve de mana, régénérations, équipement et
## recalcul de la fiche. Rien de tout ça n'existe hors scène.

var _p: Player


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	# Un parent dédié pour les tirs : sans lui ils naissent sous le script de
	# test et y restent après coup, ce que GUT signale en enfants non libérés.
	var tirs := Node2D.new()
	add_child_autofree(tirs)
	_p.projectile_parent = tirs
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
	_p._shoot()
	assert_eq(_p.mana, avant - _p.bolt_mana_cost, "le coût exact, pas un de plus")


func test_reserve_insuffisante_refuse_le_tir() -> void:
	_p._set_mana(2.0)
	_p._shoot()
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
