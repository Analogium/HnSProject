extends GutTest

## Les pièces de monnaie (jalon 29) : ce que chacune accepte, ce qu'elle fait, et
## qu'elle tombe.

const LEVEL := 60

var _rng := RandomNumberGenerator.new()


func before_each() -> void:
	_rng.seed = 2929


## Un anneau de niveau 60 à `count` affixes distincts, tirés comme au butin.
func _ring(count: int) -> Item:
	var base := ItemCatalog.by_id("ring")
	var pool := ItemAffixPool.eligible(base, LEVEL)
	return Item.new(base, ItemAffixPool.draw(_rng, pool, count, LEVEL), LEVEL)


func _coin(id: String) -> ItemBase:
	return ItemCatalog.by_id(id)


func _ids(item: Item) -> Dictionary:
	var out := {}
	for r in item.explicits:
		out[r.affix_id] = true
	return out


## Une pièce ajoutée au catalogue sans poids ne tomberait jamais, et un poids sans
## base ferait tomber null.
func test_each_coin_has_a_weight_and_each_weight_a_coin() -> void:
	var coins := 0
	for base in ItemCatalog.ALL:
		if base.family != ItemBase.CURRENCY_FAMILY:
			continue
		coins += 1
		assert_has(Currency.DROP_WEIGHTS, base.id, "« %s » a un poids" % base.id)
		assert_ne(Currency.effect(base), "", "« %s » dit ce qu'elle fait" % base.id)
		assert_eq(base.grid_size, Vector2i.ONE, "« %s » tient dans une case" % base.id)
	assert_eq(coins, Currency.DROP_WEIGHTS.size())
	for id in Currency.DROP_WEIGHTS:
		assert_not_null(ItemCatalog.by_id(id), "« %s » est au catalogue" % id)


## Comme dans PoE : en profondeur, les pièces rares tombent plus souvent, et les
## communes ni plus ni moins — à quantité égale, le niveau ne leur retire rien.
func test_deeper_zones_add_rare_coins_without_taking_common_ones() -> void:
	var flat := Currency.drop_weights(1)
	var deep := Currency.drop_weights(120)
	var ids := Currency.DROP_WEIGHTS.keys()
	for i in ids.size():
		assert_eq(flat[i], 100 * Currency.DROP_WEIGHTS[ids[i]], "%s au niveau 1" % ids[i])
	assert_eq(deep[0], flat[0], "le cuivre ne bouge pas")
	assert_eq(deep[1], flat[1], "le bronze ne bouge pas")
	for i in range(2, ids.size()):
		assert_gt(float(deep[i]) / flat[i], float(deep[i - 1]) / flat[i - 1], ids[i])

	var counts := [{}, {}]
	var levels := [1, 120]
	Game.rng.seed = 2929
	for pass_ in 2:
		for i in 60000:
			var item := LootTable.roll(0, levels[pass_])
			if Currency.is_coin(item):
				counts[pass_][item.base.id] = counts[pass_].get(item.base.id, 0) + 1
	# Par chute à quantité égale : le niveau 120 multiplie la chance par 2,19.
	var quantity := LootTable.quantity_for(0, 120)
	var copper: float = counts[1][Currency.COPPER] / quantity / counts[0][Currency.COPPER]
	assert_between(copper, 0.93, 1.07, "le cuivre par chute, mesuré ×%.2f" % copper)
	var diamond: float = counts[1].get(Currency.DIAMOND, 0) / quantity / counts[0].get(Currency.DIAMOND, 1)
	assert_between(diamond, 4.0, 7.5, "le diamant par chute, ×5,76 attendu, mesuré ×%.2f" % diamond)


func test_coins_drop_with_their_zone_level() -> void:
	Game.rng.seed = 29
	var seen := {}
	for i in 4000:
		var item := LootTable.roll(0, 12)
		if Currency.is_coin(item):
			seen[item.base.id] = true
			assert_eq(item.item_level, 12)
	assert_gt(seen.size(), 2, "plusieurs pièces différentes tombent")
	for level in [1, 30, 60]:
		for base in ItemCatalog.available(level):
			assert_ne(base.family, ItemBase.CURRENCY_FAMILY, "pas parmi les bases de chute")


func test_copper_makes_a_normal_item_magic() -> void:
	var ring := _ring(0)
	assert_true(Currency.apply(_coin(Currency.COPPER), ring, _rng))
	assert_eq(ring.explicits.size(), 1)
	assert_false(Currency.accepts(_coin(Currency.COPPER), ring), "plus sur un objet magique")


func test_bronze_rerolls_a_magic_item() -> void:
	var sizes := {}
	for i in 60:
		var ring := _ring(1)
		assert_true(Currency.apply(_coin(Currency.BRONZE), ring, _rng))
		assert_eq(ring.rarity(), Item.Rarity.MAGIC, "reste magique")
		sizes[ring.explicits.size()] = true
	assert_eq(sizes.size(), 2, "un ou deux affixes, les deux sortent")
	assert_false(Currency.accepts(_coin(Currency.BRONZE), _ring(0)))
	assert_false(Currency.accepts(_coin(Currency.BRONZE), _ring(3)))


## Un seul affixe de plus, même sur un objet qui n'en a qu'un : il est rare à deux.
func test_silver_makes_a_magic_item_rare_with_one_more_affix() -> void:
	for count in [1, 2]:
		var ring := _ring(count)
		var before := _ids(ring)
		assert_true(Currency.apply(_coin(Currency.SILVER), ring, _rng))
		assert_eq(ring.rarity(), Item.Rarity.RARE, "depuis %d affixe(s)" % count)
		assert_eq(ring.explicits.size(), count + 1)
		for id in before:
			assert_has(_ids(ring), id, "les affixes d'avant restent")
	assert_false(Currency.accepts(_coin(Currency.SILVER), _ring(0)))


## Rare à deux affixes, il prend ce que prend un rare et refuse ce que prend un magique.
func test_a_two_affix_rare_is_treated_as_rare() -> void:
	var ring := _ring(1)
	Currency.apply(_coin(Currency.SILVER), ring, _rng)
	assert_false(Currency.accepts(_coin(Currency.BRONZE), ring))
	assert_false(Currency.accepts(_coin(Currency.SILVER), ring))
	assert_true(Currency.accepts(_coin(Currency.PLATINUM), ring))
	assert_true(Currency.apply(_coin(Currency.GOLD), ring, _rng))
	assert_gt(ring.explicits.size(), Item.MAGIC_MAX, "l'or garde son fonctionnement : 3 à 6")


# --------------------------------------------------------------------------
# Les piles
# --------------------------------------------------------------------------

func _coins(id: String, count: int) -> Item:
	var coins := Item.new(_coin(id))
	coins.count = count
	return coins


func test_each_coin_stacks_and_nothing_else_does() -> void:
	for base in ItemCatalog.ALL:
		var stacks: bool = base.stack_max > 1
		assert_eq(stacks, base.family == ItemBase.CURRENCY_FAMILY, "« %s »" % base.id)


## Ramassée, une pièce rejoint sa pile ; ce qui déborde prend une nouvelle case.
func test_a_picked_coin_joins_its_stack() -> void:
	var bag := Inventory.new(4, 1)
	var full := _coin(Currency.COPPER).stack_max
	bag.add(_coins(Currency.COPPER, full - 2))
	bag.add(_coins(Currency.BRONZE, 1))
	assert_true(bag.add(_coins(Currency.COPPER, 5)))
	assert_eq(bag.placed.size(), 3, "deux piles de cuivre, une de bronze")
	assert_eq(bag.placed[0].data.count, full)
	assert_eq(bag.placed[2].data.count, 3)


## Sac plein : la pile a pris ce qu'elle pouvait, le reste attend au sol.
func test_a_full_bag_keeps_the_rest() -> void:
	var bag := Inventory.new(1, 1)
	var full := _coin(Currency.COPPER).stack_max
	bag.add(_coins(Currency.COPPER, full - 1))
	var ground := _coins(Currency.COPPER, 4)
	assert_false(bag.add(ground))
	assert_eq(ground.count, 3, "un seul a trouvé sa place")


func test_two_swords_never_stack() -> void:
	var sword := Item.new(ItemCatalog.by_id("sword"))
	assert_eq(sword.absorb(Item.new(ItemCatalog.by_id("sword"))), 0)


func test_spending_takes_one_then_the_cell() -> void:
	var bag := Inventory.new(2, 1)
	bag.add(_coins(Currency.GOLD, 2))
	bag.spend_one(Vector2i.ZERO)
	assert_eq(bag.placed[0].data.count, 1)
	bag.spend_one(Vector2i.ZERO)
	assert_eq(bag.placed.size(), 0)


func test_gold_rerolls_a_rare_item_into_three_to_six() -> void:
	var sizes := {}
	for i in 300:
		var ring := _ring(4)
		assert_true(Currency.apply(_coin(Currency.GOLD), ring, _rng))
		assert_eq(ring.rarity(), Item.Rarity.RARE)
		assert_eq(_ids(ring).size(), ring.explicits.size(), "affixes distincts")
		sizes[ring.explicits.size()] = true
	assert_true(sizes.has(3) and sizes.has(5), "plus ou moins qu'avant : %s" % [sizes.keys()])
	assert_false(Currency.accepts(_coin(Currency.GOLD), _ring(2)))


func test_the_affix_cap_is_the_last_count_weight() -> void:
	assert_eq(ItemAffixPool.MAX_COUNT, ItemAffixPool.COUNT_WEIGHTS.size() - 1)


func test_platinum_adds_one_affix_up_to_six() -> void:
	var ring := _ring(3)
	for count in range(4, ItemAffixPool.MAX_COUNT + 1):
		assert_true(Currency.apply(_coin(Currency.PLATINUM), ring, _rng))
		assert_eq(ring.explicits.size(), count)
	assert_eq(_ids(ring).size(), ItemAffixPool.MAX_COUNT, "affixes distincts")
	assert_false(Currency.apply(_coin(Currency.PLATINUM), ring, _rng), "plein à six")
	assert_false(Currency.accepts(_coin(Currency.PLATINUM), _ring(2)))


## Même affixe, même palier : seule la valeur bouge.
func test_diamond_rerolls_values_inside_their_tier() -> void:
	var ring := _ring(4)
	var before := ring.explicits.duplicate()
	var moved := false
	for i in 10:
		assert_true(Currency.apply(_coin(Currency.DIAMOND), ring, _rng))
		for j in before.size():
			assert_eq(ring.explicits[j].affix_id, before[j].affix_id)
			assert_eq(ring.explicits[j].tier, before[j].tier)
			var tier: ItemAffixTier = ItemAffixPool.by_id(before[j].affix_id).tiers[before[j].tier - 1]
			assert_between(ring.explicits[j].mod.value, tier.min_value, tier.max_value)
			moved = moved or ring.explicits[j].mod.value != before[j].mod.value
	assert_true(moved, "au moins une valeur a changé")
	assert_false(Currency.accepts(_coin(Currency.DIAMOND), _ring(0)), "rien à changer")


## Sans provenance, on ne sait pas dans quel palier tirer.
func test_diamond_leaves_an_orphan_line_alone() -> void:
	var line := StatMod.new("armor", StatMod.Mode.FLAT, 7.0)
	var ring := Item.new(ItemCatalog.by_id("ring"), [line], LEVEL)
	assert_false(Currency.accepts(_coin(Currency.DIAMOND), ring))


## Ce qui ne porte pas d'affixes ne prend aucune pièce : un manuel au palier 2 est
## « magique » par sa rareté, pas par ses affixes.
func test_no_coin_applies_to_a_manual_or_a_coin() -> void:
	var manual := Item.new(ItemCatalog.by_id("manual_lightning"), [], LEVEL)
	var copper := Item.new(_coin(Currency.COPPER), [], LEVEL)
	for id in Currency.DROP_WEIGHTS:
		assert_false(Currency.accepts(_coin(id), manual), "%s sur un manuel" % id)
		assert_false(Currency.accepts(_coin(id), copper), "%s sur une pièce" % id)
		assert_false(Currency.accepts(_coin(id), null), "%s sur rien" % id)
