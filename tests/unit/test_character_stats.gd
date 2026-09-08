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


# --------------------------------------------------------------------------
# Le niveau de zone (jalon 5, étape 6)
# --------------------------------------------------------------------------

## La mise à l\'échelle est linéaire, et c\'est un choix : une courbe
## exponentielle demande un exposant qu\'on ne saura pas régler avant d\'avoir
## joué, et se trompe d\'un facteur dix à la soixantième marche.
func test_la_mise_a_l_echelle_suit_le_niveau() -> void:
	var fiche := CharacterStats.new()
	fiche.max_health = 100.0
	fiche.attack_damage = 10.0
	CharacterStats.mettre_a_l_echelle(fiche, 1)
	assert_almost_eq(fiche.max_health, 100.0, 0.001, "le niveau 1 ne change rien")
	assert_almost_eq(fiche.attack_damage, 10.0, 0.001)

	CharacterStats.mettre_a_l_echelle(fiche, 40)
	assert_almost_eq(fiche.max_health, 100.0 * (1.0 + 0.18 * 39.0), 0.01, "huit fois la vie")
	assert_almost_eq(fiche.attack_damage, 10.0 * (1.0 + 0.12 * 39.0), 0.01, "cinq fois les dégâts")


## Ni l\'armure ni les résistances ne montent : le joueur n\'a aucun moyen de
## percer une armure, et la faire croître transformerait une zone profonde en
## mur plutôt qu\'en danger.
func test_la_mise_a_l_echelle_ne_touche_pas_aux_defenses() -> void:
	var fiche := CharacterStats.new()
	fiche.armor = 40.0
	fiche.evasion = 20.0
	fiche.res_fire = 30.0
	CharacterStats.mettre_a_l_echelle(fiche, 60)
	assert_eq(fiche.armor, 40.0)
	assert_eq(fiche.evasion, 20.0)
	assert_eq(fiche.res_fire, 30.0)


## Un niveau nul ou négatif ne doit pas rendre un ennemi plus faible que la
## première zone : c\'est un mauvais réglage, pas une consigne.
func test_un_niveau_absurde_ne_diminue_personne() -> void:
	var fiche := CharacterStats.new()
	fiche.max_health = 100.0
	CharacterStats.mettre_a_l_echelle(fiche, -3)
	assert_eq(fiche.max_health, 100.0)


## Cinq niveaux d\'avance sans pénalité, puis la récompense fond. Sans ce
## plafond, une zone de niveau 40 donnerait huit fois l\'expérience — elle dérive
## des PV, qui viennent d\'être multipliés par huit — et la zone profonde
## deviendrait le chemin le plus court plutôt qu\'un risque.
func test_l_experience_fond_quand_la_zone_depasse_le_personnage() -> void:
	assert_eq(Enemy.facteur_d_experience(1, 10), 1.0, "une zone plus basse ne pénalise pas")
	assert_eq(Enemy.facteur_d_experience(10, 10), 1.0, "à niveau égal non plus")
	assert_eq(Enemy.facteur_d_experience(15, 10), 1.0, "cinq niveaux d\'avance sont gratuits")
	assert_almost_eq(Enemy.facteur_d_experience(20, 10), 0.5, 0.001, "dix d\'écart, moitié moins")
	assert_almost_eq(
		Enemy.facteur_d_experience(40, 1), Enemy.XP_PLANCHER, 0.001,
		"et un gouffre ne rapporte presque plus rien"
	)


## Les bornes vivent avec la valeur, et non chez les deux écrans qui la
## changent : chacun bornait de son côté, et le jour où le maximum bougera,
## celui qui l\'aurait oublié laisserait engendrer une zone dont aucun affixe ne
## suit — les échelles s\'arrêtent à soixante.
func test_le_niveau_de_zone_reste_dans_ses_bornes() -> void:
	var avant := Game.niveau_de_zone
	Game.niveau_de_zone = 1
	assert_eq(Game.changer_niveau_de_zone(-10), Game.NIVEAU_MIN, "jamais sous le plancher")
	assert_eq(Game.changer_niveau_de_zone(5), 6)
	Game.niveau_de_zone = Game.NIVEAU_MAX
	assert_eq(Game.changer_niveau_de_zone(10), Game.NIVEAU_MAX, "ni au-dessus du plafond")
	Game.niveau_de_zone = avant
