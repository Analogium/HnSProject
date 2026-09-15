extends GutTest

## La courbe d'expérience, partagée par le personnage et les manuels. Deux
## modèles la lisent — l'un défalque à chaque montée, l'autre garde son total —
## et c'est la même forme dessous.

const BASE := 90.0
const POWER := 1.25
const MAX := 20


func test_the_cost_rises_with_the_level() -> void:
	var previous := 0
	for level in range(1, MAX + 1):
		var cost := Progression.level_cost(level, BASE, POWER)
		assert_gt(cost, previous, "le niveau %d coûte plus que le précédent" % level)
		previous = cost


## Un niveau qui n'a pas de coût serait un niveau gratuit, et la boucle qui
## additionne les paliers tournerait sans jamais avancer.
func test_the_first_level_costs_the_base() -> void:
	assert_eq(Progression.level_cost(1, BASE, POWER), roundi(BASE))
	assert_eq(Progression.level_cost(0, BASE, POWER), roundi(BASE), "borné à 1")


func test_the_level_is_deduced_from_experience() -> void:
	assert_eq(Progression.reached_level(0, BASE, POWER, MAX), 1, "on naît au niveau 1")
	var cost1 := Progression.level_cost(1, BASE, POWER)
	assert_eq(Progression.reached_level(cost1 - 1, BASE, POWER, MAX), 1, "un point trop peu")
	assert_eq(Progression.reached_level(cost1, BASE, POWER, MAX), 2, "pile le compte")
	var cost2 := Progression.level_cost(2, BASE, POWER)
	assert_eq(Progression.reached_level(cost1 + cost2, BASE, POWER, MAX), 3)


## Sans plafond, une expérience aberrante lue dans un fichier ferait tourner la
## boucle longtemps pour rendre un nombre qui ne veut rien dire.
func test_the_level_is_bounded() -> void:
	assert_eq(Progression.reached_level(999999999, BASE, POWER, MAX), MAX)
	assert_eq(Progression.reached_level(-50, BASE, POWER, MAX), 1, "et par le bas")


## Ce que la barre du haut de la page affiche : l'avancement dans le niveau en
## cours, et ce que ce niveau coûte en tout.
func test_progress_says_where_we_stand() -> void:
	var cost1 := Progression.level_cost(1, BASE, POWER)
	assert_eq(Progression.progress(0, BASE, POWER, MAX), Vector2i(0, cost1))
	assert_eq(Progression.progress(10, BASE, POWER, MAX), Vector2i(10, cost1))

	var cost2 := Progression.level_cost(2, BASE, POWER)
	assert_eq(
		Progression.progress(cost1 + 5, BASE, POWER, MAX), Vector2i(5, cost2),
		"passé un niveau, on repart de zéro sur le suivant"
	)


## Au plafond, la jauge n'a plus rien à promettre : mieux vaut la dessiner vide
## qu'avec un dénominateur inventé.
func test_at_cap_progress_promises_nothing() -> void:
	assert_eq(Progression.progress(999999999, BASE, POWER, MAX), Vector2i.ZERO)
