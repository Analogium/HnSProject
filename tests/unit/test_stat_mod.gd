extends GutTest

## L'unité d'affichage d'une statistique et l'ordre d'application des
## modificateurs. Les deux se voient immédiatement à l'écran quand ils sont
## faux, mais seulement si on regarde le bon objet au bon moment.


func test_unites_d_affichage() -> void:
	assert_eq(StatMod.format("crit_chance", 0.05), "5 %", "fraction lue en %")
	assert_eq(StatMod.format("attack_speed", 1.1), "110 %", "multiplicateur lu en %")
	assert_eq(StatMod.format("crit_multiplier", 2.0), "200 %")
	assert_eq(StatMod.format("res_fire", 40.0), "40 %", "déjà en points de %")
	assert_eq(StatMod.format("max_health", 120.0), "120", "sans unité")
	assert_eq(StatMod.format("attack_damage", 6.5, true), "+6.5", "signe et décimale")
	assert_eq(StatMod.format("attack_damage", 6.0, true), "+6", "pas de décimale inutile")


## Confondre les deux familles donnerait « 7500 % de résistance au feu ».
func test_les_deux_familles_d_unites_ne_se_melangent_pas() -> void:
	for s in StatMod.SCALED:
		assert_false(s in StatMod.PERCENT_POINTS, "%s n'est que dans une famille" % s)


func test_libelles() -> void:
	assert_eq(StatMod.new("armor", StatMod.Mode.FLAT, 25.0).label(), "+25 armure")
	assert_eq(
		StatMod.new("attack_speed", StatMod.Mode.PERCENT, 8.0).label(),
		"+8 % vitesse d'attaque"
	)
	assert_eq(StatMod.new("res_fire", StatMod.Mode.FLAT, 20.0).label(), "+20 % rés. feu")


## Le cœur de l'affaire : deux objets identiques doivent donner le même
## personnage quel que soit l'ordre où on les équipe.
func test_les_plats_avant_les_pourcentages() -> void:
	var mods: Array[StatMod] = [
		StatMod.new("max_health", StatMod.Mode.PERCENT, 50.0),
		StatMod.new("max_health", StatMod.Mode.FLAT, 100.0),
	]
	var a := CharacterStats.new()
	a.max_health = 100.0
	StatMod.apply_all(a, mods)

	var inverse: Array[StatMod] = [mods[1], mods[0]]
	var b := CharacterStats.new()
	b.max_health = 100.0
	StatMod.apply_all(b, inverse)

	assert_eq(a.max_health, 300.0, "(100 + 100) x 1,5")
	assert_eq(b.max_health, a.max_health, "l'ordre d'équipement ne change rien")
