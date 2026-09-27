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

	filter.move_to(1, 0)
	assert_eq(filter.rule_for(magic), hide_all, "remontée, c'est elle qui décide")
	hide_all.enabled = false
	assert_eq(filter.rule_for(magic), show_rings, "éteinte, elle laisse décider la suivante")


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
	rule.bases = ["ring"]
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
	var rule := _rule(LootFilter.Action.HIDE)
	assert_eq(LootFilterPanel.rule_summary(rule), "Masquer : tout")
	rule.rarities = [Item.Rarity.MAGIC]
	rule.families = ["ring", "amulet", "belt"]
	rule.affixes = ["vigorous", "regenerating"]
	assert_eq(LootFilterPanel.rule_summary(rule), "Masquer : Magique · 3 types · 1 sur 2 affixes")


func _families(families: Array, bases := []) -> LootFilter.Rule:
	var rule := LootFilter.Rule.new()
	rule.families.assign(families)
	rule.bases.assign(bases)
	return rule


## Ce que la page propose pour des types choisis : ce que le tirage peut leur donner.
func test_only_possible_affixes_are_offered() -> void:
	var rings := LootFilter.possible_affixes(_families(["ring"]))
	assert_true(rings.has(ItemAffixPool.by_id("keen")), "le tranchant tombe sur un anneau")
	assert_false(rings.has(ItemAffixPool.by_id("precise")), "la précision est d'arme")
	var both := LootFilter.possible_affixes(_families(["ring", "weapon"]))
	assert_true(both.has(ItemAffixPool.by_id("precise")), "deux types : l'union")
	assert_true(LootFilter.possible_affixes(_families(["currency"])).is_empty(), "une pièce n'en porte aucun")
	assert_eq(LootFilter.possible_affixes(_families([])).size(), ItemAffixPool.ALL.size(), "sans type, tous")


## Une base resserre la règle : l'objet doit en être une, et les affixes proposés
## sont les siens, plus ceux de tout son type.
func test_bases_narrow_the_rule() -> void:
	var rule := _families([], ["sword"])
	assert_true(rule.matches(Item.new(ItemCatalog.by_id("sword"))))
	assert_false(rule.matches(Item.new(ItemCatalog.by_id("dagger"))), "une autre arme ne compte pas")
	var sword_affixes := LootFilter.possible_affixes(rule)
	var wand_only := LootFilter.possible_affixes(_families([], ["wand"])).filter(
		func(a: ItemAffix) -> bool: return not sword_affixes.has(a))
	assert_false(wand_only.is_empty(), "une baguette porte des affixes qu'une épée n'a pas")
	assert_lt(sword_affixes.size(), LootFilter.possible_affixes(_families(["weapon"])).size(),
		"l'épée seule en propose moins que toutes les armes")

	var rings := LootFilter.possible_bases(["ring"] as Array[String])
	assert_eq(rings.map(func(b: ItemBase) -> String: return b.family), ["ring", "ring", "ring"], "les bases du type, et elles seules")
	assert_true(rings[0].required_level <= rings[1].required_level, "rangées par palier")

	var reread := LootFilter.Rule.from_dict({"bases": ["sword", "épée disparue"]})
	assert_eq(reread.bases, ["sword"] as Array[String], "une base retirée du jeu est oubliée à la lecture")


## Le code redonne le filtre ; ce qui n'en est pas un — autre texte, base64 abîmé,
## code tronqué au copier-coller — est refusé sans erreur du moteur.
func test_a_filter_travels_as_a_code() -> void:
	var rule := _rule(LootFilter.Action.RECOLOR)
	rule.color = LootFilter.COLORS[5]
	rule.families = ["ring"]
	rule.bases = ["signet_ring"]
	rule.affixes = ["vigorous"]
	var filter := LootFilter.new()
	filter.rules = [rule, _rule(LootFilter.Action.HIDE)]
	var code := filter.to_code()
	assert_true(code.begins_with(LootFilter.CODE_PREFIX))

	var back := LootFilter.from_code("  " + code.insert(20, "\n") + "\n")
	assert_not_null(back, "les blancs d'un copier-coller ne comptent pas")
	assert_eq(back.to_list(), filter.to_list(), "le même filtre revient")

	assert_null(LootFilter.from_code("bonjour"), "un texte quelconque")
	assert_null(LootFilter.from_code(LootFilter.CODE_PREFIX + "@@@@"), "un base64 abîmé")
	assert_null(LootFilter.from_code(code.left(code.length() / 2 / 4 * 4)), "un code tronqué")
	assert_null(LootFilter.from_code(LootFilter.CODE_PREFIX + Marshalls.utf8_to_base64("{}")), "du JSON qui n'est pas une liste")


## Plusieurs filtres, un seul qui décide : ajouter le rend actif, le dernier ne se
## supprime pas, et le disque garde tout — l'ancienne forme à un filtre comprise.
func test_several_filters_are_kept() -> void:
	var before := Settings.to_dict()
	Settings.from_dict({"loot_filter": []})
	assert_eq(Settings.loot_filters.size(), 1, "l'ancienne forme donne un filtre")
	assert_false(Settings.loot_filter.name.is_empty(), "nommé d'office")

	var hide := LootFilter.new()
	hide.name = "Fin de partie"
	hide.rules = [_rule(LootFilter.Action.HIDE)]
	Settings.add_loot_filter(hide)
	assert_eq(Settings.loot_filter, hide, "le filtre ajouté décide")
	assert_eq(Settings.loot_rule(_ring([])).action, LootFilter.Action.HIDE)
	Settings.choose_loot_filter(0)
	assert_null(Settings.loot_rule(_ring([])), "revenu au premier, vide : rien ne décide")

	var reread: Dictionary = JSON.parse_string(JSON.stringify(Settings.to_dict()))
	Settings.from_dict({"loot_filter": []})
	Settings.from_dict(reread)
	assert_eq(Settings.loot_filters.size(), 2)
	assert_eq(Settings.loot_filters[1].name, "Fin de partie", "le nom revient")
	assert_eq(Settings.loot_filter_index, 0, "et le choix aussi")

	Settings.remove_loot_filter(0)
	assert_eq(Settings.loot_filter.name, "Fin de partie", "supprimer passe au suivant")
	Settings.remove_loot_filter(0)
	assert_eq(Settings.loot_filters.size(), 1, "le dernier reste : le sol a toujours un filtre")
	Settings.from_dict(before)


## Le code emporte le nom ; un code des débuts, une liste nue, se lit encore.
func test_the_code_carries_the_name() -> void:
	var filter := LootFilter.new()
	filter.name = "Anneaux de vie"
	filter.rules = [_rule(LootFilter.Action.SHOW)]
	assert_eq(LootFilter.from_code(filter.to_code()).name, "Anneaux de vie")
	var early := LootFilter.CODE_PREFIX + Marshalls.utf8_to_base64(JSON.stringify(filter.to_list()))
	assert_eq(LootFilter.from_code(early).rules.size(), 1, "les premiers codes se lisent")
	assert_ne(filter.duplicated().rules[0], filter.rules[0], "une copie ne partage pas ses règles")
