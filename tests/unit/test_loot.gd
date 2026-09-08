extends GutTest

## La table de butin. Les chiffres testés ici sont ceux que le document de jalon
## annonce — 20 % de base, +10 % par affixe porté. Si le code s'en écarte, c'est
## le document qui devient faux, et personne ne s'en apercevrait en jouant.


func test_la_quantite_croit_avec_les_affixes() -> void:
	assert_eq(LootTable.quantity_for(0), 1.0, "un ennemi ordinaire")
	assert_almost_eq(LootTable.quantity_for(2), 1.2, 0.0001, "+10 % par affixe")


## Le taux réel, mesuré et non déclaré. Fenêtre large : on vérifie l'ordre de
## grandeur promis, pas la qualité du générateur.
func test_le_taux_de_chute_de_base() -> void:
	Game.rng.seed = 424242
	var tombes := 0
	for i in 20000:
		if LootTable.roll(0, 1) != null:
			tombes += 1
	var taux := float(tombes) / 20000.0
	assert_between(taux, 0.185, 0.215, "0,20 attendu, mesuré %.3f" % taux)


func test_un_elite_lache_plus_souvent() -> void:
	Game.rng.seed = 909
	var ordinaire := 0
	var elite := 0
	for i in 20000:
		if LootTable.roll(0, 1) != null:
			ordinaire += 1
		if LootTable.roll(3, 1) != null:
			elite += 1
	assert_gt(elite, ordinaire, "%d contre %d" % [elite, ordinaire])


## Le piège que la classe Item existe précisément pour éviter : rendre la
## ressource du disque ferait de toutes les épées du jeu le même objet, et y
## écrire un affixe l'écrirait dans epee.tres.
func test_chaque_chute_est_un_exemplaire_neuf() -> void:
	Game.rng.seed = 77
	var vus := []
	while vus.size() < 30:
		var item := LootTable.roll(6, 1)
		if item != null:
			assert_false(item in vus, "deux chutes ne partagent pas d'objet")
			vus.append(item)
	var disque: ItemBase = load("res://resources/items/epee.tres")
	assert_eq(disque.implicit_value, 4.0, "epee.tres n'a pas été écrit")


## L'implicite de la base et les affixes tirés sortent par le même canal : c'est
## cette liste que le calcul des statistiques du joueur consomme.
func test_les_mods_reunissent_implicite_et_affixes() -> void:
	var base: ItemBase = load("res://resources/items/epee.tres")
	var nu := Item.new(base)
	assert_eq(nu.mods().size(), 1, "l'implicite seul")

	var deux: Array[StatMod] = [
		StatMod.new("attack_speed", StatMod.Mode.PERCENT, 8.0),
		StatMod.new("crit_chance", StatMod.Mode.FLAT, 0.03),
	]
	var enrichi := Item.new(base, deux)
	assert_eq(enrichi.mods().size(), 3, "l'implicite plus ses deux affixes")
	assert_eq(enrichi.explicits.size(), 2, "l'infobulle ne montre que les tirés")
	assert_false(enrichi.implicit_line().is_empty(), "et l'implicite à part")


# --------------------------------------------------------------------------
# Le niveau d'objet (jalon 5)
# --------------------------------------------------------------------------

## Le niveau de la zone est estampillé sur ce qui y tombe, et c'est le seul
## robinet du jalon : il décidera des tiers d'affixes que l'objet a pu recevoir.
func test_ce_qui_tombe_porte_le_niveau_de_la_zone() -> void:
	Game.rng.seed = 5150
	var vus := 0
	for i in 400:
		var item := LootTable.roll(0, 37)
		if item == null:
			continue
		vus += 1
		assert_eq(item.item_level, 37, "« %s » porte le niveau de sa zone" % item.display_name())
	assert_gt(vus, 0, "encore faut-il que quelque chose soit tombé")


## Le niveau du personnage n'entre nulle part dans la chaîne : deux zones de
## niveaux différents ne donnent pas les mêmes objets, quoi que fasse le joueur.
func test_deux_zones_donnent_deux_niveaux_d_objet() -> void:
	Game.rng.seed = 31
	var bas := 0
	var haut := 0
	for i in 200:
		var a := LootTable.roll(0, 5)
		var b := LootTable.roll(0, 50)
		if a != null:
			bas = a.item_level
		if b != null:
			haut = b.item_level
	assert_eq(bas, 5)
	assert_eq(haut, 50)


## Le cas limite du filtre de disponibilité : aucune base ne peut tomber, donc
## rien ne tombe. Vérifie surtout le **sens** de la comparaison — inversée, elle
## laisserait passer exactement l'inverse de ce qu'on veut, et personne ne le
## verrait tant que toutes les bases valent 1.
func test_rien_ne_tombe_quand_aucune_base_n_est_disponible() -> void:
	Game.rng.seed = 12
	for i in 200:
		assert_null(LootTable.roll(6, 0), "aucune base n'existe au niveau 0")
