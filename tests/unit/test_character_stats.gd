extends GutTest

## Les formules de mitigation. Elles vivent sur CharacterStats et non sur la
## Hurtbox précisément pour être testables sans moteur : aucun nœud ici.


func test_armure_reduit_selon_la_taille_du_coup() -> void:
	var st := CharacterStats.new()
	st.armor = 60.0
	assert_almost_eq(st.armor_reduction(12.0), 0.5, 0.001, "60 contre un coup de 12")
	assert_almost_eq(st.armor_reduction(120.0), 0.0909, 0.001, "60 contre un coup de 120")


func test_armure_absente_ou_negative_ne_protege_pas() -> void:
	var st := CharacterStats.new()
	assert_eq(st.armor_reduction(10.0), 0.0, "sans armure")
	st.armor = -50.0
	assert_eq(st.armor_reduction(10.0), 0.0, "armure négative")


func test_armure_plafonnee() -> void:
	var st := CharacterStats.new()
	st.armor = 1000000.0
	assert_eq(
		st.armor_reduction(10.0), CharacterStats.MAX_ARMOR_REDUCTION,
		"un coup passe toujours"
	)


func test_esquive() -> void:
	var st := CharacterStats.new()
	assert_eq(st.evade_chance(), 0.0, "sans esquive")
	st.evasion = 60.0
	assert_almost_eq(st.evade_chance(), 0.5, 0.001, "60 d'esquive = une fois sur deux")
	st.evasion = 1000000.0
	assert_eq(st.evade_chance(), CharacterStats.MAX_EVASION, "plafond")


func test_resistances_bornees() -> void:
	var st := CharacterStats.new()
	st.res_fire = 200.0
	assert_eq(
		st.resistance(DamageType.Kind.FIRE), CharacterStats.MAX_RESISTANCE, "plafond"
	)
	st.res_cold = -500.0
	assert_eq(
		st.resistance(DamageType.Kind.COLD), CharacterStats.MIN_RESISTANCE, "plancher"
	)


## Le physique ne passe pas par un pourcentage mais par l'armure. L'appelant ne
## doit pas avoir à connaître l'exception.
func test_le_physique_n_a_pas_de_resistance() -> void:
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
func test_cadence_pas_de_division_par_zero() -> void:
	var st := CharacterStats.new()
	st.attack_cooldown = 0.45
	st.attack_speed = 0.0
	assert_almost_eq(st.attack_interval(), 4.5, 0.0001)
