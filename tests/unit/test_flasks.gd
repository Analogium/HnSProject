extends GutTest

## Les flacons (jalon 32), hors de l'arbre : les bases, ce que leurs lignes locales
## montent, et la règle qui les garde magiques.


func _flask(id: String, lines: Array = []) -> Item:
	return Item.new(ItemCatalog.by_id(id), lines)


func _flasks() -> Array[ItemBase]:
	var out: Array[ItemBase] = []
	for base: ItemBase in ItemCatalog.ALL:
		if base.family == ItemBase.FLASK_FAMILY:
			out.append(base)
	return out


## Une durée nulle diviserait la gorgée par zéro ; une gorgée plus chère que la réserve
## ne se boirait jamais.
func test_each_flask_can_be_drunk() -> void:
	assert_gt(_flasks().size(), 0)
	for base in _flasks():
		assert_gt(base.flask_duration, 0.0, base.id)
		assert_gt(base.flask_charges_per_use, 0, base.id)
		assert_lte(base.flask_charges_per_use, base.flask_charges, base.id)
		# Soit il rend, soit il donne son implicite : jamais rien, jamais les deux.
		assert_ne(base.is_utility_flask(), base.flask_life + base.flask_mana > 0.0, base.id)
		assert_eq(base.is_utility_flask(), not base.implicit_stat.is_empty(), base.id)


func test_a_new_flask_is_full() -> void:
	var flask := _flask("small_life_flask")
	assert_eq(flask.charges, float(flask.charges_max()))
	assert_eq(flask.charges_max(), 21)


func test_local_lines_raise_the_flask_itself() -> void:
	var flask := _flask("small_life_flask", [
		StatMod.new("flask_charges", StatMod.Mode.FLAT, 9.0),
		StatMod.new("flask_charges_used", StatMod.Mode.PERCENT, -30.0),
		StatMod.new("flask_recovery", StatMod.Mode.PERCENT, 50.0),
	])
	assert_eq(flask.charges_max(), 30)
	assert_eq(flask.charges_per_use(), 5, "7 × 0,7 = 4,9, arrondi")
	assert_eq(flask.flask_life(), 90.0)
	assert_eq(flask.mods().size(), 0, "rien de local ne va sur la fiche")


## Ce qui n'est pas local passe par `mods()`, que la fiche ne lit que pendant l'effet.
func test_what_is_not_local_waits_for_the_effect() -> void:
	var flask := _flask("quicksilver_flask", [StatMod.new("armor", StatMod.Mode.PERCENT, 40.0)])
	var stats := []
	for m in flask.mods():
		stats.append(m.stat)
	assert_eq(stats, ["move_speed", "armor"], "l'implicite, puis le suffixe")
	assert_true(flask.implicit_line().ends_with(Texts.t(" pendant l'effet")))


## Le granit donne de l'armure bue : ce n'est pas la défense d'une pièce d'armure,
## que ses affixes monteraient sur place.
func test_a_granite_flask_is_not_armour() -> void:
	var flask := _flask("granite_flask")
	assert_eq(flask.base.defense_stat(), "")
	assert_eq(flask.mods()[0].mode, StatMod.Mode.PERCENT, "l'implicite, tel quel")


func test_a_flask_stays_magic() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 32
	var magic := 0
	for i in 300:
		var flask := Item.rolled(rng, ItemCatalog.by_id("large_life_flask"), 60)
		assert_lte(flask.explicits.size(), Item.MAGIC_MAX)
		if flask.rarity() == Item.Rarity.MAGIC:
			magic += 1
	assert_gt(magic, 0, "encore faut-il qu'il en sorte")

	var one := _flask("small_life_flask")
	assert_true(Currency.apply(ItemCatalog.by_id(Currency.COPPER), one, rng), "le cuivre, oui")
	assert_false(Currency.accepts(ItemCatalog.by_id(Currency.SILVER), one), "l'argent, non")
