extends GutTest

## La courbe d'expérience, partagée par le personnage et les manuels. Deux
## modèles la lisent — l'un défalque à chaque montée, l'autre garde son total —
## et c'est la même forme dessous.

const BASE := 90.0
const PUISSANCE := 1.25
const MAX := 20


func test_le_cout_monte_avec_le_niveau() -> void:
	var precedent := 0
	for niveau in range(1, MAX + 1):
		var cout := Progression.cout_du_niveau(niveau, BASE, PUISSANCE)
		assert_gt(cout, precedent, "le niveau %d coûte plus que le précédent" % niveau)
		precedent = cout


## Un niveau qui n'a pas de coût serait un niveau gratuit, et la boucle qui
## additionne les paliers tournerait sans jamais avancer.
func test_le_premier_niveau_coute_la_base() -> void:
	assert_eq(Progression.cout_du_niveau(1, BASE, PUISSANCE), roundi(BASE))
	assert_eq(Progression.cout_du_niveau(0, BASE, PUISSANCE), roundi(BASE), "borné à 1")


func test_le_niveau_se_deduit_de_l_experience() -> void:
	assert_eq(Progression.niveau_atteint(0, BASE, PUISSANCE, MAX), 1, "on naît au niveau 1")
	var cout1 := Progression.cout_du_niveau(1, BASE, PUISSANCE)
	assert_eq(Progression.niveau_atteint(cout1 - 1, BASE, PUISSANCE, MAX), 1, "un point trop peu")
	assert_eq(Progression.niveau_atteint(cout1, BASE, PUISSANCE, MAX), 2, "pile le compte")
	var cout2 := Progression.cout_du_niveau(2, BASE, PUISSANCE)
	assert_eq(Progression.niveau_atteint(cout1 + cout2, BASE, PUISSANCE, MAX), 3)


## Sans plafond, une expérience aberrante lue dans un fichier ferait tourner la
## boucle longtemps pour rendre un nombre qui ne veut rien dire.
func test_le_niveau_est_borne() -> void:
	assert_eq(Progression.niveau_atteint(999999999, BASE, PUISSANCE, MAX), MAX)
	assert_eq(Progression.niveau_atteint(-50, BASE, PUISSANCE, MAX), 1, "et par le bas")


## Ce que la barre du haut de la page affiche : l'avancement dans le niveau en
## cours, et ce que ce niveau coûte en tout.
func test_l_avancement_dit_ou_l_on_en_est() -> void:
	var cout1 := Progression.cout_du_niveau(1, BASE, PUISSANCE)
	assert_eq(Progression.avancement(0, BASE, PUISSANCE, MAX), Vector2i(0, cout1))
	assert_eq(Progression.avancement(10, BASE, PUISSANCE, MAX), Vector2i(10, cout1))

	var cout2 := Progression.cout_du_niveau(2, BASE, PUISSANCE)
	assert_eq(
		Progression.avancement(cout1 + 5, BASE, PUISSANCE, MAX), Vector2i(5, cout2),
		"passé un niveau, on repart de zéro sur le suivant"
	)


## Au plafond, la jauge n'a plus rien à promettre : mieux vaut la dessiner vide
## qu'avec un dénominateur inventé.
func test_au_plafond_l_avancement_ne_promet_rien() -> void:
	assert_eq(Progression.avancement(999999999, BASE, PUISSANCE, MAX), Vector2i.ZERO)
