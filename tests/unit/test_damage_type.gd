extends GutTest

## Trois tables indexées par le même enum. Une entrée oubliée à l'ajout d'une
## sixième nature donnerait un accès hors bornes en plein combat, pas ici.


func test_tables_cover_every_nature() -> void:
	var n: int = DamageType.Kind.size()
	assert_eq(DamageType.NAMES.size(), n, "un nom par nature")
	assert_eq(DamageType.COLORS.size(), n, "une couleur par nature")
	assert_eq(DamageType.RESIST_FIELDS.size(), n, "un champ de résistance par nature")


## Le physique est la seule nature sans champ de résistance, et c'est voulu.
func test_only_physical_has_no_field() -> void:
	var st := CharacterStats.new()
	for k in DamageType.Kind.size():
		var field: String = DamageType.RESIST_FIELDS[k]
		if k == DamageType.Kind.PHYSICAL:
			assert_true(field.is_empty(), "le physique n'a pas de champ")
		else:
			assert_false(field.is_empty(), "%s a un champ" % DamageType.NAMES[k])
			assert_not_null(st.get(field), "le champ %s existe" % field)


## L'or est réservé aux critiques et aux élites : aucune nature ne doit s'en
## approcher, sinon un dégât de feu se lirait comme un coup critique.
func test_no_color_is_mistaken_for_gold() -> void:
	var or_crit := HitFeedback.CRIT
	for k in DamageType.Kind.size():
		var c: Color = DamageType.COLORS[k]
		var spread := absf(c.r - or_crit.r) + absf(c.g - or_crit.g) + absf(c.b - or_crit.b)
		assert_gt(spread, 0.35, "%s est distinct de l'or" % DamageType.NAMES[k])


func test_colors_are_distinct_from_each_other() -> void:
	for a in DamageType.Kind.size():
		for b in range(a + 1, DamageType.Kind.size()):
			var this_one: Color = DamageType.COLORS[a]
			var cb: Color = DamageType.COLORS[b]
			var spread := absf(this_one.r - cb.r) + absf(this_one.g - cb.g) + absf(this_one.b - cb.b)
			assert_gt(
				spread, 0.30,
				"%s et %s se distinguent" % [DamageType.NAMES[a], DamageType.NAMES[b]]
			)
