extends GutTest

## Le filtre de butin, à la Last Epoch : la plus haute règle qui vise l'objet décide,
## ses conditions sont toutes requises, et ce qu'aucune ne vise s'affiche.


func _ring(affixes: Array) -> Item:
	var explicits := []
	for pair: Array in affixes:
		explicits.append(RolledAffix.new(pair[0], pair[1], ItemAffixPool.by_id(pair[0]).at_top(0)))
	return Item.new(ItemCatalog.by_id("ring"), explicits)


func _rule(action: LootFilter.Action) -> LootFilter.Rule:
	var rule := LootFilter.Rule.new()
	rule.action = action
	return rule


func test_the_highest_matching_rule_decides() -> void:
	var filter := LootFilter.new()
	var magic := _ring([["keen", 1]])
	assert_null(filter.rule_for(magic), "sans règle, rien ne décide : l'objet s'affiche")

	var show_rings := _rule(LootFilter.Action.SHOW)
	show_rings.families = ["ring"]
	var hide_all := _rule(LootFilter.Action.HIDE)
	filter.rules = [show_rings, hide_all]
	assert_eq(filter.rule_for(magic), show_rings, "la règle du dessus l'emporte")
	assert_eq(filter.rule_for(Item.new(ItemCatalog.by_id("sword"))), hide_all, "le reste tombe sur le « tout masquer »")

	filter.move(1, -1)
	assert_eq(filter.rule_for(magic), hide_all, "remontée, c'est elle qui décide")


func test_every_condition_must_hold() -> void:
	var rule := _rule(LootFilter.Action.HIDE)
	rule.rarities = [Item.Rarity.MAGIC]
	rule.families = ["ring"]
	assert_true(rule.matches(_ring([["keen", 1]])), "anneau magique")
	assert_false(rule.matches(_ring([["keen", 1], ["vigorous", 1], ["regenerating", 1]])), "pas le rare")
	assert_false(rule.matches(Item.new(ItemCatalog.by_id("sword"), [RolledAffix.new("precise", 1, ItemAffixPool.by_id("precise").at_top(0))])),
		"pas l'épée magique")


## Au moins `min_count` des affixes choisis, chacun au palier voulu ou mieux (1 est
## le meilleur).
func test_affixes_count_at_their_tier() -> void:
	var rule := _rule(LootFilter.Action.SHOW)
	rule.affixes = ["vigorous", "regenerating"]
	rule.min_count = 2
	var both := _ring([["vigorous", 2], ["regenerating", 4]])
	assert_true(rule.matches(both), "les deux, tous paliers")
	assert_false(rule.matches(_ring([["vigorous", 1]])), "un seul ne suffit pas")
	rule.best_tier = 3
	assert_false(rule.matches(both), "T4 est plus faible que T3")
	rule.min_count = 1
	assert_true(rule.matches(both), "T2 suffit pour un sur deux")


## Le fichier est du JSON : ce qui en revient doit dire la même chose, et ce qu'on y
## a gâché à la main retombe sur le défaut au lieu de casser la lecture.
func test_rules_survive_the_disk() -> void:
	var rule := _rule(LootFilter.Action.RECOLOR)
	rule.color = LootFilter.COLORS[3]
	rule.rarities = [Item.Rarity.RARE]
	rule.families = ["amulet", "ring"]
	rule.affixes = ["vigorous"]
	rule.best_tier = 2
	var filter := LootFilter.new()
	filter.rules = [rule]

	var reread := LootFilter.from_list(JSON.parse_string(JSON.stringify(filter.to_list())))
	assert_eq(reread.rules.size(), 1)
	assert_eq(reread.rules[0].to_dict(), rule.to_dict())

	var damaged := LootFilter.from_list([{"action": "brûler", "color": "?", "rarities": ["mythique", "magic"], "families": [3, "hat"], "min_count": "deux"}, "règle"])
	assert_eq(damaged.rules.size(), 1, "ce qui n'est pas une règle est laissé")
	var kept: LootFilter.Rule = damaged.rules[0]
	assert_eq(kept.action, LootFilter.Action.SHOW)
	assert_eq(kept.rarities, [Item.Rarity.MAGIC] as Array[int])
	assert_true(kept.families.is_empty())
	assert_eq(kept.min_count, 1)


func test_the_settings_carry_the_filter() -> void:
	var before := Settings.to_dict()
	var hide := _rule(LootFilter.Action.HIDE)
	Settings.from_dict({"loot_filter_on": true, "loot_filter": [hide.to_dict()]})
	var ring := _ring([])
	assert_eq(Settings.loot_rule(ring).action, LootFilter.Action.HIDE)
	Settings.loot_filter_on = false
	assert_null(Settings.loot_rule(ring), "éteint, le filtre ne décide plus rien")
	Settings.from_dict({"affix_names": true})
	assert_eq(Settings.loot_filter.rules.size(), 1, "un fichier sans filtre garde les règles")
	Settings.from_dict(before)


## Un type ajouté au catalogue sans sa case ne se viserait jamais.
func test_each_item_family_can_be_targeted() -> void:
	for raw in ItemCatalog.ALL:
		var base: ItemBase = raw
		assert_true(LootFilter.FAMILIES.has(base.family), "« %s » (%s) sans case au filtre" % [base.family, base.id])


## Le résumé d'une règle est ce qu'on lit dans la liste : il dit l'action et les conditions.
func test_a_rule_reads_in_the_list() -> void:
	var menu: GDScript = load("res://ui/pause_menu.gd")
	var rule := _rule(LootFilter.Action.HIDE)
	assert_eq(menu.rule_summary(rule), "Masquer : tout")
	rule.rarities = [Item.Rarity.MAGIC]
	rule.families = ["ring", "amulet", "belt"]
	rule.affixes = ["vigorous", "regenerating"]
	assert_eq(menu.rule_summary(rule), "Masquer : Magique · 3 types · 1 sur 2 affixes")


## Ce que la page propose pour des types choisis : ce que le tirage peut leur donner.
func test_only_possible_affixes_are_offered() -> void:
	var rings := LootFilter.possible_affixes(["ring"] as Array[String])
	assert_true(rings.has(ItemAffixPool.by_id("keen")), "le tranchant tombe sur un anneau")
	assert_false(rings.has(ItemAffixPool.by_id("precise")), "la précision est d'arme")
	var both := LootFilter.possible_affixes(["ring", "weapon"] as Array[String])
	assert_true(both.has(ItemAffixPool.by_id("precise")), "deux types : l'union")
	assert_true(LootFilter.possible_affixes(["currency"] as Array[String]).is_empty(), "une pièce n'en porte aucun")
	assert_eq(LootFilter.possible_affixes([] as Array[String]).size(), ItemAffixPool.ALL.size(), "sans type, tous")
