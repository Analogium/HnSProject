extends GutTest

## Trois tables indexées par le même enum. Une entrée oubliée à l'ajout d'une
## sixième nature donnerait un accès hors bornes en plein combat, pas ici.


func test_les_tables_couvrent_toutes_les_natures() -> void:
	var n: int = DamageType.Kind.size()
	assert_eq(DamageType.NAMES.size(), n, "un nom par nature")
	assert_eq(DamageType.COLORS.size(), n, "une couleur par nature")
	assert_eq(DamageType.RESIST_FIELDS.size(), n, "un champ de résistance par nature")


## Le physique est la seule nature sans champ de résistance, et c'est voulu.
func test_seul_le_physique_n_a_pas_de_champ() -> void:
	var st := CharacterStats.new()
	for k in DamageType.Kind.size():
		var champ: String = DamageType.RESIST_FIELDS[k]
		if k == DamageType.Kind.PHYSICAL:
			assert_true(champ.is_empty(), "le physique n'a pas de champ")
		else:
			assert_false(champ.is_empty(), "%s a un champ" % DamageType.NAMES[k])
			assert_not_null(st.get(champ), "le champ %s existe" % champ)


## L'or est réservé aux critiques et aux élites : aucune nature ne doit s'en
## approcher, sinon un dégât de feu se lirait comme un coup critique.
func test_aucune_couleur_ne_confond_avec_l_or() -> void:
	var or_crit := HitFeedback.CRIT
	for k in DamageType.Kind.size():
		var c: Color = DamageType.COLORS[k]
		var ecart := absf(c.r - or_crit.r) + absf(c.g - or_crit.g) + absf(c.b - or_crit.b)
		assert_gt(ecart, 0.35, "%s est distinct de l'or" % DamageType.NAMES[k])


func test_les_couleurs_sont_distinctes_entre_elles() -> void:
	for a in DamageType.Kind.size():
		for b in range(a + 1, DamageType.Kind.size()):
			var ca: Color = DamageType.COLORS[a]
			var cb: Color = DamageType.COLORS[b]
			var ecart := absf(ca.r - cb.r) + absf(ca.g - cb.g) + absf(ca.b - cb.b)
			assert_gt(
				ecart, 0.30,
				"%s et %s se distinguent" % [DamageType.NAMES[a], DamageType.NAMES[b]]
			)
