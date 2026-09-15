extends GutTest

## Les formules de mitigation. Elles vivent sur CharacterStats et non sur la
## Hurtbox précisément pour être testables sans moteur : aucun nœud ici.


func test_armor_reduces_by_hit_size() -> void:
	var st := CharacterStats.new()
	st.armor = 60.0
	assert_almost_eq(st.armor_reduction(12.0), 0.5, 0.001, "60 contre un coup de 12")
	assert_almost_eq(st.armor_reduction(120.0), 0.0909, 0.001, "60 contre un coup de 120")


func test_missing_or_negative_armor_does_not_protect() -> void:
	var st := CharacterStats.new()
	assert_eq(st.armor_reduction(10.0), 0.0, "sans armure")
	st.armor = -50.0
	assert_eq(st.armor_reduction(10.0), 0.0, "armure négative")


func test_armor_capped() -> void:
	var st := CharacterStats.new()
	st.armor = 1000000.0
	assert_eq(
		st.armor_reduction(10.0), CharacterStats.MAX_ARMOR_REDUCTION,
		"un coup passe toujours"
	)


func test_evasion() -> void:
	var st := CharacterStats.new()
	assert_eq(st.evade_chance(), 0.0, "sans esquive")
	st.evasion = 60.0
	assert_almost_eq(st.evade_chance(), 0.5, 0.001, "60 d'esquive = une fois sur deux")
	st.evasion = 1000000.0
	assert_eq(st.evade_chance(), CharacterStats.MAX_EVASION, "cap")


func test_resistances_bounded() -> void:
	var st := CharacterStats.new()
	st.res_fire = 200.0
	assert_eq(
		st.resistance(DamageType.Kind.FIRE), CharacterStats.MAX_RESISTANCE, "cap"
	)
	st.res_cold = -500.0
	assert_eq(
		st.resistance(DamageType.Kind.COLD), CharacterStats.MIN_RESISTANCE, "floor_value"
	)


## Le physique ne passe pas par un pourcentage mais par l'armure. L'appelant ne
## doit pas avoir à connaître l'exception.
func test_physical_has_no_resistance() -> void:
	var st := CharacterStats.new()
	assert_eq(st.resistance(DamageType.Kind.PHYSICAL), 0.0)


func test_cadence() -> void:
	var st := CharacterStats.new()
	st.attack_cooldown = 0.45
	assert_almost_eq(st.attack_interval(), 0.45, 0.0001, "cadence de base")
	st.attack_speed = 1.5
	assert_almost_eq(st.attack_interval(), 0.3, 0.0001, "+50 % de cadence")


## Le plancher n'est pas une coquetterie : sans lui, une vitesse nulle fige
## l'attaquant pour toujours au lieu de le ralentir.
func test_cadence_no_division_by_zero() -> void:
	var st := CharacterStats.new()
	st.attack_cooldown = 0.45
	st.attack_speed = 0.0
	assert_almost_eq(st.attack_interval(), 4.5, 0.0001)


# --------------------------------------------------------------------------
# Le niveau de zone (jalon 5, étape 6)
# --------------------------------------------------------------------------

## La vie se compose et les dégâts s\'additionnent : les dégâts du joueur se
## multiplient entre eux, et une vie linéaire se laissait distancer. L\'exposant garde
## les huit fois de la zone 40 d\'avant.
func test_scaling_follows_the_level() -> void:
	var sheet := CharacterStats.new()
	sheet.max_health = 100.0
	sheet.attack_damage = 10.0
	CharacterStats.scale_to_level(sheet, 1)
	assert_almost_eq(sheet.max_health, 100.0, 0.001, "le niveau 1 ne change rien")
	assert_almost_eq(sheet.attack_damage, 10.0, 0.001)

	CharacterStats.scale_to_level(sheet, 40)
	assert_between(sheet.max_health, 780.0, 830.0, "huit fois la vie")
	assert_almost_eq(sheet.attack_damage, 10.0 * (1.0 + 0.12 * 39.0), 0.01, "cinq fois les dégâts")


## Exponentielle, pas linéaire : chaque tranche de soixante niveaux multiplie la vie
## d'autant, là où une droite ne la doublait plus entre 60 et 120.
func test_health_compounds_from_one_level_to_the_next() -> void:
	var vies := []
	for level in [1, 61, 121]:
		var sheet := CharacterStats.new()
		sheet.max_health = 100.0
		CharacterStats.scale_to_level(sheet, level)
		vies.append(sheet.max_health)
	assert_almost_eq(vies[2] / vies[1], vies[1] / vies[0], 0.01, "le même facteur par tranche")
	assert_gt(vies[1] / vies[0], 20.0)


## L'armure et les résistances montent avec la zone (décidé le 15 septembre 2026), en
## s'ajoutant à celles de la fiche ; l'esquive non, sinon une zone profonde serait une
## loterie.
func test_scaling_raises_armor_and_resistances() -> void:
	var sheet := CharacterStats.new()
	sheet.armor = 40.0
	sheet.evasion = 20.0
	sheet.res_fire = 30.0
	CharacterStats.scale_to_level(sheet, 1)
	assert_eq(sheet.armor, 40.0, "rien en zone 1")
	assert_eq(sheet.res_cold, 0.0, "rien en zone 1")

	CharacterStats.scale_to_level(sheet, 60)
	assert_almost_eq(sheet.armor, 40.0 + CharacterStats.ARMOR_PER_LEVEL * 59.0, 0.001)
	assert_almost_eq(sheet.res_fire, 30.0 + CharacterStats.RESISTANCE_PER_LEVEL * 59.0, 0.001)
	for field: String in DamageType.RESIST_FIELDS:
		if not field.is_empty():
			assert_gt(float(sheet.get(field)), 0.0, field)
	assert_eq(sheet.evasion, 20.0, "l'esquive ne monte pas")


## Un niveau nul ou négatif ne doit pas rendre un ennemi plus faible que la
## première zone : c\'est un mauvais réglage, pas une consigne.
func test_an_absurd_level_diminishes_nobody() -> void:
	var sheet := CharacterStats.new()
	sheet.max_health = 100.0
	CharacterStats.scale_to_level(sheet, -3)
	assert_eq(sheet.max_health, 100.0)


## L\'expérience suit le niveau de l\'ennemi **sans borne haute** : une zone qui
## dépasse le personnage paie tout ce qu\'elle vaut, et c\'est le danger qui en
## fait le prix. Elle ne fond que dans l\'autre sens, sur une zone laissée loin
## derrière — sinon moudre la première zone à niveau 60 resterait payant.
func test_experience_only_melts_on_zones_left_behind() -> void:
	assert_eq(Enemy.experience_factor(40, 10), 1.0, "une zone bien au-dessus paie tout")
	assert_eq(Enemy.experience_factor(10, 10), 1.0, "à niveau égal aussi")
	assert_eq(Enemy.experience_factor(5, 10), 1.0, "cinq niveaux de retard sont gratuits")
	assert_almost_eq(Enemy.experience_factor(10, 20), 0.5, 0.001, "dix d\'écart, moitié moins")
	assert_almost_eq(
		Enemy.experience_factor(1, 40), Enemy.XP_FLOOR, 0.001,
		"et la première zone ne rapporte presque plus rien à qui la surplombe"
	)


## Ce que le changement de sens veut dire en jeu : le même ennemi, dans une zone
## profonde, rapporte franchement plus — huit fois ses PV, huit fois son
## expérience. C\'est la promesse du jalon 5 pour le butin, tenue ici pour
## l\'expérience.
func test_a_deep_zone_rewards_more_than_a_starting_zone() -> void:
	var weak := CharacterStats.new()
	weak.max_health = 30.0
	var strong := CharacterStats.new()
	strong.max_health = 30.0
	CharacterStats.scale_to_level(strong, 40)

	var player := 12
	var low_gain := weak.max_health * Enemy.XP_PER_HEALTH * Enemy.experience_factor(1, player)
	var high_gain := strong.max_health * Enemy.XP_PER_HEALTH * Enemy.experience_factor(40, player)
	assert_gt(high_gain, low_gain * 5.0, "la zone 40 rapporte au moins cinq fois plus")


## Les bornes vivent avec la valeur, et non chez les deux écrans qui la
## changent : chacun bornait de son côté, et le jour où le maximum bougera,
## celui qui l\'aurait oublié laisserait engendrer une zone dont aucun affixe ne
## suit — les échelles s\'arrêtent à soixante.
func test_the_zone_level_stays_in_bounds() -> void:
	var before := Game.zone_level
	Game.zone_level = 1
	assert_eq(Game.change_zone_level(-10), Game.MIN_LEVEL, "jamais sous le plancher")
	assert_eq(Game.change_zone_level(5), 6)
	Game.zone_level = Game.MAX_LEVEL
	assert_eq(Game.change_zone_level(10), Game.MAX_LEVEL, "ni au-dessus du plafond")
	Game.zone_level = before
