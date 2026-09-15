extends GutTest

## La table de butin. Les chiffres testés ici sont ceux que le document de jalon
## annonce — 20 % de base, +10 % par affixe porté. Si le code s'en écarte, c'est
## le document qui devient faux, et personne ne s'en apercevrait en jouant.


func test_quantity_grows_with_affixes() -> void:
	assert_eq(LootTable.quantity_for(0), 1.0, "un ennemi ordinaire")
	assert_almost_eq(LootTable.quantity_for(2), 1.2, 0.0001, "+10 % par affixe")


## Le taux réel, mesuré et non déclaré. Fenêtre large : on vérifie l'ordre de
## grandeur promis, pas la qualité du générateur.
func test_the_base_drop_rate() -> void:
	Game.rng.seed = 424242
	var dropped := 0
	for i in 20000:
		if LootTable.roll(0, 1) != null:
			dropped += 1
	var rate := float(dropped) / 20000.0
	assert_between(rate, 0.185, 0.215, "0,20 attendu, mesuré %.3f" % rate)


func test_an_elite_drops_more_often() -> void:
	Game.rng.seed = 909
	var ordinary := 0
	var elite := 0
	for i in 20000:
		if LootTable.roll(0, 1) != null:
			ordinary += 1
		if LootTable.roll(3, 1) != null:
			elite += 1
	assert_gt(elite, ordinary, "%d contre %d" % [elite, ordinary])


## Le piège que la classe Item existe précisément pour éviter : rendre la
## ressource du disque ferait de toutes les épées du jeu le même objet, et y
## écrire un affixe l'écrirait dans epee.tres.
func test_each_drop_is_a_fresh_copy() -> void:
	Game.rng.seed = 77
	var seen_all := []
	while seen_all.size() < 30:
		var item := LootTable.roll(6, 1)
		if item != null:
			assert_false(item in seen_all, "deux chutes ne partagent pas d'objet")
			seen_all.append(item)
	var disk: ItemBase = load("res://resources/items/sword.tres")
	assert_eq(disk.implicit_value, 2.0, "epee.tres n'a pas été écrit")


## L'implicite de la base et les affixes tirés sortent par le même canal : c'est
## cette liste que le calcul des statistiques du joueur consomme.
func test_mods_combine_implicit_and_affixes() -> void:
	var base: ItemBase = load("res://resources/items/sword.tres")
	var bare := Item.new(base)
	assert_eq(bare.mods().size(), 1, "l'implicite seul")

	var two: Array[StatMod] = [
		StatMod.new("attack_speed", StatMod.Mode.PERCENT, 8.0),
		StatMod.new("crit_chance", StatMod.Mode.FLAT, 0.03),
	]
	var enriched := Item.new(base, two)
	assert_eq(enriched.mods().size(), 3, "l'implicite plus ses deux affixes")
	assert_eq(enriched.explicits.size(), 2, "l'infobulle ne montre que les tirés")
	assert_false(enriched.implicit_line().is_empty(), "et l'implicite à part")


# --------------------------------------------------------------------------
# Le niveau d'objet (jalon 5)
# --------------------------------------------------------------------------

## Le niveau de la zone est estampillé sur ce qui y tombe, et c'est le seul
## robinet du jalon : il décidera des tiers d'affixes que l'objet a pu recevoir.
func test_what_drops_carries_the_zone_level() -> void:
	Game.rng.seed = 5150
	var seen_all := 0
	for i in 400:
		var item := LootTable.roll(0, 37)
		if item == null:
			continue
		seen_all += 1
		assert_eq(item.item_level, 37, "« %s » porte le niveau de sa zone" % item.display_name())
	assert_gt(seen_all, 0, "encore faut-il que quelque chose soit tombé")


## Le niveau du personnage n'entre nulle part dans la chaîne : deux zones de
## niveaux différents ne donnent pas les mêmes objets, quoi que fasse le joueur.
func test_two_zones_give_two_item_levels() -> void:
	Game.rng.seed = 31
	var low := 0
	var top := 0
	for i in 200:
		var a := LootTable.roll(0, 5)
		var b := LootTable.roll(0, 50)
		if a != null:
			low = a.item_level
		if b != null:
			top = b.item_level
	assert_eq(low, 5)
	assert_eq(top, 50)


## Le cas limite du filtre de disponibilité : aucune base ne peut tomber, donc
## rien ne tombe. Vérifie surtout le **sens** de la comparaison — inversée, elle
## laisserait passer exactement l'inverse de ce qu'on veut, et personne ne le
## verrait tant que toutes les bases valent 1.
func test_nothing_drops_when_no_base_is_available() -> void:
	Game.rng.seed = 12
	for i in 200:
		assert_null(LootTable.roll(6, 0), "aucune base n'existe au niveau 0")
