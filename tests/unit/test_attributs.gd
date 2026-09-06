extends GutTest

## Les trois attributs et ce qu'ils gouvernent. Un attribut qui ne dérive rien
## serait une ligne de plus sur la fiche et rien d'autre — c'est précisément ce
## que ces tests empêchent de devenir vrai en silence.


func test_les_attributs_sont_nuls_par_defaut() -> void:
	var st := CharacterStats.new()
	for champ in CharacterStats.ATTRIBUTES:
		assert_eq(float(st.get(champ)), 0.0, "%s à zéro : un grunt n'en a pas" % champ)


func test_la_force_donne_vie_et_degats() -> void:
	var st := CharacterStats.new()
	st.max_health = 100.0
	st.attack_damage = 12.0
	st.strength = 10.0
	st.apply_attributes()
	assert_eq(st.max_health, 120.0, "+2 PV par point")
	assert_almost_eq(st.attack_damage, 14.0, 0.001, "+0,2 dégât par point")


func test_la_dexterite_donne_esquive_et_cadence() -> void:
	var st := CharacterStats.new()
	st.dexterity = 10.0
	st.apply_attributes()
	assert_eq(st.evasion, 15.0, "+1,5 d'esquive par point")
	assert_almost_eq(st.attack_speed, 1.04, 0.0001, "+0,4 point de % par point")


## L'esquive n'avait aucune source depuis le jalon 2 ; c'est la dextérité qui la
## lui donne enfin.
func test_la_dexterite_rend_l_esquive_reellement_utile() -> void:
	var st := CharacterStats.new()
	st.dexterity = 40.0
	st.apply_attributes()
	assert_gt(st.evade_chance(), 0.4, "40 de dextérité protègent réellement")


func test_l_intelligence_donne_mana_et_incantation() -> void:
	var st := CharacterStats.new()
	st.max_mana = 50.0
	st.intelligence = 10.0
	st.apply_attributes()
	assert_eq(st.max_mana, 65.0, "+1,5 de mana par point")
	assert_almost_eq(st.cast_speed, 1.04, 0.0001, "+0,4 point de % par point")


## Chaque attribut doit toucher **deux** choses. Un attribut qui n'en gouverne
## qu'une est un alias pour la statistique qu'il pilote, et autant modifier
## celle-ci directement.
func test_chaque_attribut_gouverne_deux_statistiques() -> void:
	var temoin := CharacterStats.new()
	temoin.apply_attributes()
	for champ in CharacterStats.ATTRIBUTES:
		var st := CharacterStats.new()
		st.set(champ, 20.0)
		st.apply_attributes()
		var changes := 0
		for autre in ["max_health", "attack_damage", "evasion", "attack_speed",
				"max_mana", "cast_speed"]:
			if not is_equal_approx(float(st.get(autre)), float(temoin.get(autre))):
				changes += 1
		assert_eq(changes, 2, "%s gouverne exactement deux statistiques" % champ)


## Appelée deux fois, elle compterait les bonus deux fois. C'est la même règle
## que pour recompute_stats, dont elle est un morceau.
func test_la_derivation_ne_s_applique_qu_une_fois() -> void:
	var a := CharacterStats.new()
	a.strength = 10.0
	a.apply_attributes()
	var b := CharacterStats.new()
	b.strength = 10.0
	b.apply_attributes()
	b.apply_attributes()
	assert_ne(a.max_health, b.max_health, "deux appels ne donnent pas le même résultat")


func test_les_trois_attributs_ont_un_libelle() -> void:
	for champ in CharacterStats.ATTRIBUTES:
		assert_true(StatMod.LABELS.has(champ), "libellé pour %s" % champ)


## Une entrée oubliée dans la liste ferait que ni la fiche ni le recalcul ne
## verraient le nouvel attribut.
func test_la_liste_des_attributs_correspond_aux_champs() -> void:
	var st := CharacterStats.new()
	for champ in CharacterStats.ATTRIBUTES:
		assert_not_null(st.get(champ), "le champ %s existe" % champ)
	assert_eq(CharacterStats.ATTRIBUTES.size(), 3)


## La fiche doit tenir entière dans la hauteur du cadrage. Ajouter un groupe ou
## une statistique fait déborder la dernière ligne sur l'aide du bas — c'est
## arrivé en ajoutant les attributs, et ça ne se voit que sur une capture.
func test_la_fiche_tient_dans_sa_hauteur() -> void:
	var hauteur: float = ProjectSettings.get_setting(
		"display/window/size/viewport_height"
	)
	var disponible := hauteur - StatsPanel.FOOTER
	assert_lt(
		StatsPanel.content_height(), disponible,
		"%.0f px de contenu pour %.0f disponibles" % [
			StatsPanel.content_height(), disponible
		]
	)
