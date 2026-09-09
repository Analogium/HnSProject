extends GutTest

## La compétence hors de tout : la fiche, sa table de dégâts, et la formule qui
## en sort un nombre. Aucun manuel, aucune interface, aucun arbre de scène — au
## jalon 6, c'est la seule règle qui décide de ce que fait un coup.

## Une fiche neutre, dont chaque test ne règle que ce qu'il regarde. Les valeurs
## par défaut de CharacterStats ne conviennent pas : elles portent déjà des
## dégâts et une intelligence, et un test qui les subit mesure autre chose que ce
## qu'il annonce.
func _fiche() -> CharacterStats:
	var f := CharacterStats.new()
	f.attack_damage = 0.0
	f.spell_damage = 0.0
	f.strength = 0.0
	f.dexterity = 0.0
	f.intelligence = 0.0
	return f


## Une compétence de test, écrite ici et non lue sur le disque : le contenu du
## jeu changera, la formule non.
func _competence(table: Array[float]) -> Competence:
	var c := Competence.new()
	c.id = "essai"
	c.nom = "Essai"
	c.degats_par_point = table
	return c


# --------------------------------------------------------------------------
# Le catalogue
# --------------------------------------------------------------------------

func test_chaque_competence_a_un_identifiant() -> void:
	for c in CompetenceCatalog.ALL:
		assert_false(c.id.is_empty(), "« %s » n'a pas d'identifiant" % c.nom)
		assert_false(c.nom.is_empty(), "« %s » n'a pas de nom lisible" % c.id)


## Deux compétences de même identifiant, c'est une barre sauvegardée qui rappelle
## l'une pour l'autre au chargement suivant.
func test_les_identifiants_sont_uniques() -> void:
	var vus := {}
	for c in CompetenceCatalog.ALL:
		assert_false(vus.has(c.id), "« %s » est écrit deux fois" % c.id)
		vus[c.id] = true


func test_on_retrouve_une_competence_par_son_identifiant() -> void:
	var c := CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE)
	assert_not_null(c)
	assert_eq(c.id, CompetenceCatalog.ID_ATTAQUE)


## Une barre sauvegardée peut citer une compétence retirée du projet depuis. Ce
## n'est pas une erreur de programmation, c'est un cas de jeu : la case se vide.
func test_une_competence_disparue_rend_null() -> void:
	assert_null(CompetenceCatalog.by_id("sort_qui_n_existe_pas"))


## Une table vide, c'est une compétence qui ne fait jamais rien : elle ne se
## découvre qu'en la lançant, et elle ressemble alors à une panne.
func test_chaque_competence_a_de_quoi_faire_des_degats() -> void:
	for c in CompetenceCatalog.ALL:
		assert_gt(c.points_max(), 0, "« %s » n'a aucun point dans sa table" % c.nom)


## Un nom de champ mal orthographié dans un `.tres` rend zéro sans rien dire, et
## la compétence paraît simplement faible. C'est ce test qui l'attrape, pas une
## partie.
func test_chaque_competence_vise_des_champs_reels() -> void:
	var fiche := CharacterStats.new()
	for c in CompetenceCatalog.ALL:
		if not c.stat_de_base.is_empty():
			assert_true(
				fiche.get(c.stat_de_base) != null,
				"« %s » part de « %s », qui n'est pas dans la fiche" % [c.nom, c.stat_de_base]
			)
		if not c.attribut.is_empty():
			assert_true(
				CharacterStats.ATTRIBUTES.has(c.attribut),
				"« %s » monte avec « %s », qui n'est pas un attribut" % [c.nom, c.attribut]
			)


# --------------------------------------------------------------------------
# La formule
# --------------------------------------------------------------------------

## Une compétence non apprise n'est pas une compétence faible : elle n'existe
## pas. Sans ce zéro, une case vide de la barre lancerait un sort gratuit.
func test_zero_point_ne_rend_rien() -> void:
	var c := _competence([10.0, 20.0] as Array[float])
	assert_eq(c.degats(0, _fiche()), 0.0)
	assert_eq(c.degats(-3, _fiche()), 0.0, "et un nombre négatif non plus")


func test_chaque_point_donne_la_valeur_de_sa_ligne() -> void:
	var c := _competence([10.0, 25.0, 45.0] as Array[float])
	var f := _fiche()
	assert_eq(c.degats(1, f), 10.0, "le premier point")
	assert_eq(c.degats(2, f), 25.0, "le deuxième")
	assert_eq(c.degats(3, f), 45.0, "le troisième")
	assert_eq(c.points_max(), 3, "et la table dit combien la case accepte")


## Demander plus de points que la table n'en contient rend le dernier, jamais une
## erreur d'indice : l'appelant qui se trompe doit obtenir le meilleur coup, pas
## interrompre un combat.
func test_au_dela_du_dernier_point_on_garde_le_dernier() -> void:
	var c := _competence([10.0, 25.0] as Array[float])
	assert_eq(c.degats(9, _fiche()), 25.0)


## Le terme qui garde vivants les affixes du jalon 5 : sans lui, « dégâts de
## sort » et l'implicite du grimoire ne toucheraient aucune compétence.
func test_la_statistique_de_la_fiche_s_ajoute_aux_degats_de_base() -> void:
	var c := _competence([10.0] as Array[float])
	c.stat_de_base = "spell_damage"
	var f := _fiche()
	f.spell_damage = 7.0
	assert_eq(c.degats(1, f), 17.0)


## « +4 % par point d'intelligence », lu sur la fiche **finale** : c'est ce qui
## fait qu'un anneau ramassé en zone 40 change une compétence, et donc que les
## jalons 4 et 5 nourrissent celui-ci au lieu de vivre à côté.
func test_l_attribut_multiplie_les_degats() -> void:
	var c := _competence([100.0] as Array[float])
	c.attribut = "intelligence"
	c.pourcentage_par_attribut = 4.0
	var f := _fiche()
	assert_eq(c.degats(1, f), 100.0, "sans intelligence, la base seule")
	f.intelligence = 10.0
	assert_eq(c.degats(1, f), 140.0, "dix points d'intelligence, quarante pour cent")


## L'échelle s'applique **après** l'addition, et pas seulement à la table : sinon
## les dégâts de sort d'un objet échapperaient à l'attribut, et deux joueurs de
## même fiche n'auraient pas les mêmes nombres selon l'ordre du calcul.
func test_l_echelle_porte_aussi_sur_la_statistique_de_la_fiche() -> void:
	var c := _competence([50.0] as Array[float])
	c.stat_de_base = "spell_damage"
	c.attribut = "intelligence"
	c.pourcentage_par_attribut = 10.0
	var f := _fiche()
	f.spell_damage = 50.0
	f.intelligence = 5.0
	assert_eq(c.degats(1, f), 150.0, "(50 + 50) × 1,5")


## Un attribut non nommé ne multiplie rien. C'est l'état des deux attaques de
## départ, et c'est ce qui les fait sortir exactement les nombres d'avant.
func test_sans_attribut_nomme_rien_ne_multiplie() -> void:
	var c := _competence([10.0] as Array[float])
	var f := _fiche()
	f.intelligence = 100.0
	f.strength = 100.0
	assert_eq(c.degats(1, f), 10.0)


# --------------------------------------------------------------------------
# Les deux attaques de départ, qui ne doivent pas changer de valeur
# --------------------------------------------------------------------------

## Le coup d'épée rend les dégâts de la fiche, exactement. Le critique n'est pas
## dedans : il vit dans `DamageInfo.roll()`, et une compétence ne le retire ni ne
## le double.
func test_le_coup_de_base_rend_les_degats_de_la_fiche() -> void:
	var c := CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE)
	var f := _fiche()
	f.attack_damage = 12.0
	assert_eq(c.degats(1, f), 12.0)
	assert_eq(c.cout_en_mana, 0.0, "et il reste gratuit")


func test_le_tir_rend_les_degats_de_sort_de_la_fiche() -> void:
	var c := CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR)
	var f := _fiche()
	f.spell_damage = 33.0
	assert_eq(c.degats(1, f), 33.0)
	assert_gt(c.cout_en_mana, 0.0, "et il coûte toujours du mana")


## Les deux attaques de départ ne montent avec aucun attribut, et ce n'est pas un
## oubli : la force et l'intelligence nourrissent déjà `attack_damage` et la
## réserve par `apply_attributes()`. Les compter ici les paierait deux fois, et
## les nombres du jalon 1 cesseraient d'être ceux du jalon 6.
func test_les_attaques_de_depart_ne_montent_avec_aucun_attribut() -> void:
	for id in [CompetenceCatalog.ID_ATTAQUE, CompetenceCatalog.ID_TIR]:
		var c := CompetenceCatalog.by_id(id)
		assert_true(
			c.attribut.is_empty(),
			"« %s » monterait deux fois avec « %s »" % [c.nom, c.attribut]
		)
