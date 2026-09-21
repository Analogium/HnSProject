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
	assert_eq(bare.mods().size(), 2, "l'implicite et la chance critique de l'arme")

	var two: Array[StatMod] = [
		StatMod.new("attack_speed", StatMod.Mode.PERCENT, 8.0),
		StatMod.new("crit_chance", StatMod.Mode.FLAT, 0.03),
	]
	var enriched := Item.new(base, two)
	assert_eq(enriched.mods().size(), 3, "la ligne locale n'y est que par la chance de l'arme")
	assert_eq(enriched.explicits.size(), 2, "l'infobulle ne montre que les tirés")
	assert_false(enriched.implicit_line().is_empty(), "et l'implicite à part")


## Une ligne de chance critique sur une arme monte la base de l'arme, et le dit ; ailleurs
## elle reste à la fiche.
func test_a_crit_line_is_local_on_a_weapon_only() -> void:
	var line := StatMod.new("crit_chance", StatMod.Mode.FLAT, 0.03)
	var sword := Item.new(ItemCatalog.by_id("sword"), [line] as Array[StatMod])
	assert_almost_eq(sword.crit_chance(), 0.13, 0.0001, "10 % de l'épée, plus la ligne")
	var sheet: Array[StatMod] = sword.mods().filter(func(m: StatMod) -> bool: return m.stat == "crit_chance")
	assert_eq(sheet.size(), 1, "une seule ligne de critique vers la fiche")
	assert_almost_eq(sheet[0].value, 0.13, 0.0001)
	assert_true(sword.explicit_line(sword.explicits[0]).ends_with(" (local)"))

	var increased := StatMod.new("crit_chance", StatMod.Mode.PERCENT, 100.0)
	var both := Item.new(ItemCatalog.by_id("sword"), [line, increased] as Array[StatMod])
	assert_almost_eq(both.crit_chance(), 0.26, 0.0001, "(10 + 3) × 2 : le plat, puis l'accru")
	assert_true(both.explicit_line(both.explicits[1]).ends_with(" (local)"))
	assert_eq(both.mods().size(), 2, "l'implicite et la base : l'accru local n'atteint pas le lancer")

	var ring := Item.new(ItemCatalog.by_id("ring"), [line] as Array[StatMod])
	assert_false(ring.explicit_line(ring.explicits[0]).ends_with(" (local)"))
	assert_eq(ring.crit_chance(), 0.0, "pas de base hors des armes")


## Une pièce d'armure monte sa propre défense sur place — le plat, puis l'accru — et
## verse le total à la fiche en une ligne.
func test_a_defense_line_is_local_on_its_armour() -> void:
	var flat := StatMod.new("armor", StatMod.Mode.FLAT, 10.0)
	var increased := StatMod.new("armor", StatMod.Mode.PERCENT, 50.0)
	var plate := Item.new(ItemCatalog.by_id("breastplate"), [flat, increased] as Array[StatMod])
	assert_almost_eq(plate.defense(), 45.0, 0.0001, "(20 + 10) × 1,5")
	var sheet: Array[StatMod] = plate.mods().filter(func(m: StatMod) -> bool: return m.stat == "armor")
	assert_eq(sheet.size(), 1, "une seule ligne d'armure vers la fiche")
	assert_almost_eq(sheet[0].value, 45.0, 0.0001)
	assert_true(plate.explicit_line(plate.explicits[1]).ends_with(" (local)"))

	var belt := Item.new(ItemCatalog.by_id("belt"), [flat] as Array[StatMod])
	assert_false(belt.explicit_line(belt.explicits[0]).ends_with(" (local)"))
	assert_eq(belt.defense(), 0.0, "pas de défense hors des armures")


## Un implicite se tire dans la plage de sa base, et la défense locale part de ce tirage.
func test_an_implicit_rolls_within_its_base_range() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for base: ItemBase in ItemCatalog.ALL:
		if not base.implicit_rolls():
			continue
		for i in 20:
			var value := Item.rolled(rng, base, 60).implicit_value()
			assert_between(value, base.implicit_value, base.implicit_roll_max, base.id)
	var plate := Item.new(
		ItemCatalog.by_id("breastplate"),
		[StatMod.new("armor", StatMod.Mode.PERCENT, 50.0)] as Array[StatMod]
	)
	plate.implicit_roll = 1.0
	assert_almost_eq(plate.defense(), 39.0, 0.0001, "26 tirés, × 1,5")


## Gants et bottes existent dans les deux défenses.
func test_gloves_and_boots_come_in_both_defenses() -> void:
	for family in ["gloves", "boots"]:
		var seen := {}
		for base: ItemBase in ItemCatalog.ALL:
			if base.family == family:
				seen[base.defense_stat()] = true
		assert_eq(seen.keys().size(), 2, family)


## Casque, gants, bottes, torse : leur implicite est leur défense, et ils ne tirent
## que la leur.
func test_armour_pieces_roll_only_their_own_defense() -> void:
	for base: ItemBase in ItemCatalog.ALL:
		if not base.family in ["helmet", "gloves", "boots", "chest"]:
			continue
		var own := base.defense_stat()
		assert_false(own.is_empty(), "« %s » doit avoir une défense en implicite" % base.display_name)
		for a in ItemAffixPool.eligible(base, 60):
			if a.stat in ItemBase.LOCAL_DEFENSES:
				assert_eq(a.stat, own, "« %s » tire « %s »" % [base.display_name, a.id])


## **Seule l'arme donne une base** : hors d'une arme, tout ce qui touche la chance
## critique l'accroît — implicite, affixe, nœud de l'arbre, passif de manuel.
func test_no_flat_crit_outside_a_weapon() -> void:
	for base: ItemBase in ItemCatalog.ALL:
		if base.implicit_stat == "crit_chance":
			assert_true(base.implicit_percent, "implicite de « %s »" % base.id)
	for affix: ItemAffix in ItemAffixPool.ALL:
		if affix.stat != "crit_chance" or affix.percent:
			continue
		for base: ItemBase in ItemCatalog.ALL:
			if affix.fits(base):
				assert_eq(base.family, ItemBase.WEAPON_FAMILY, "« %s » plat sur « %s »" % [affix.id, base.id])
	for n in PassiveTree.shared().nodes:
		for m in n.mods():
			if m.stat == "crit_chance":
				assert_ne(m.mode, StatMod.Mode.FLAT, "nœud « %s »" % n.id)


## Chaque arme a sa base, et son type : 10 % à l'attaque, 5 % à l'incantation.
func test_each_weapon_has_its_crit_and_its_kind() -> void:
	for base: ItemBase in ItemCatalog.ALL:
		if base.family != ItemBase.WEAPON_FAMILY:
			assert_eq(base.crit_chance, 0.0, base.id)
			assert_eq(base.allowed_keyword(), "", base.id)
		elif base.tags.has(ItemBase.CASTER_TAG):
			assert_eq(base.crit_chance, 0.05, base.id)
			assert_eq(base.allowed_keyword(), Keywords.SPELL, base.id)
		else:
			assert_eq(base.crit_chance, 0.1, base.id)
			assert_eq(base.allowed_keyword(), Keywords.ATTACK, base.id)


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
