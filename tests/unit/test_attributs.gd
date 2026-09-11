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
	st.strength = 10.0
	st.apply_attributes()
	assert_eq(st.max_health, 120.0, "+2 PV par point")
	assert_almost_eq(st.degats_de_force(), 2.0, 0.001, "+0,2 dégât physique aux attaques par point")


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
		for autre in ["max_health", "evasion", "attack_speed", "max_mana", "cast_speed"]:
			if not is_equal_approx(float(st.get(autre)), float(temoin.get(autre))):
				changes += 1
		# Les dégâts de la force ne sont pas un champ de la fiche mais une
		# fourchette versée aux attaques : ils comptent quand même pour deux.
		if not is_equal_approx(st.degats_de_force(), temoin.degats_de_force()):
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


# --------------------------------------------------------------------------
# Les infobulles de statistiques
# --------------------------------------------------------------------------

## Une table indexée par une liste de champs, c'est une entrée oubliée qui donne
## une bulle vide en plein jeu plutôt qu'un échec ici.
func test_chaque_statistique_de_la_fiche_a_son_explication() -> void:
	for groupe in StatsPanel.GROUPS:
		for champ in groupe[1]:
			assert_true(
				StatHelp.has(champ),
				"« %s » s'affiche sur la fiche sans explication" % champ
			)


## Les explications des deux compétences de départ n'écrivent aucun nombre, mais
## elles affirment une famille, une cadence et un coût : c'est vérifié sur les
## compétences elles-mêmes.
func test_l_explication_des_competences_de_depart_dit_vrai() -> void:
	var attaque := CompetenceCatalog.by_id(CompetenceCatalog.ID_ATTAQUE)
	assert_true(attaque.porte(MotsCles.ATTAQUE), "« aux attaques »")
	assert_eq(attaque.cadence, Competence.Cadence.ARME, "« à la cadence de l'arme »")
	assert_eq(attaque.cout_en_mana, 0.0, "« gratuit »")

	var sort_de_depart := CompetenceCatalog.by_id(CompetenceCatalog.ID_TIR)
	assert_true(sort_de_depart.porte(MotsCles.SORT), "« un sort »")
	assert_eq(sort_de_depart.cadence, Competence.Cadence.INCANTATION, "« suit la vitesse d'incantation »")
	assert_gt(sort_de_depart.cout_en_mana, 0.0, "« coûte du mana »")

	for id in [CompetenceCatalog.ID_ATTAQUE, CompetenceCatalog.ID_TIR]:
		assert_eq(StatHelp.lines(id, CharacterStats.new()).size(), 1, "une phrase, sans ligne « ici »")


## Et l'inverse : une explication pour un champ qui n'existe plus ne se verrait
## jamais, et personne ne penserait à la retirer.
func test_aucune_explication_ne_vise_un_champ_inconnu() -> void:
	var fiche := CharacterStats.new()
	for champ in StatHelp.TEXTS:
		assert_true(
			StatMod.LABELS.has(champ), "« %s » n'a pas de nom lisible" % champ
		)
		assert_true(
			fiche.get(champ) != null, "« %s » n'est pas un champ de la fiche" % champ
		)


## La ligne « en ce moment » est calculée depuis la fiche, jamais recopiée : un
## texte qui affirmerait un plafond que le code n'applique pas serait pire que
## pas de texte du tout.
func test_l_explication_dit_ce_que_la_fiche_vaut_vraiment() -> void:
	var fiche := CharacterStats.new()
	fiche.armor = 40.0
	var lignes := StatHelp.lines("armor", fiche)
	assert_eq(lignes.size(), 2, "ce que ça fait, puis ce que ça vaut")
	var attendu := "%d %%" % roundi(fiche.armor_reduction(StatHelp.COUP_LEGER) * 100.0)
	assert_true(lignes[1].contains(attendu), "« %s » attendu dans « %s »" % [attendu, lignes[1]])


func test_les_resistances_annoncent_leur_plafond() -> void:
	var fiche := CharacterStats.new()
	for champ in DamageType.RESIST_FIELDS:
		if champ.is_empty():
			continue
		var lignes := StatHelp.lines(champ, fiche)
		assert_eq(lignes.size(), 2, "« %s »" % champ)
		assert_true(
			lignes[1].contains("%d %%" % roundi(CharacterStats.MAX_RESISTANCE)),
			"le plafond réel apparaît : %s" % lignes[1]
		)


## Une statistique qui se lit directement n'a pas de seconde ligne : inventer
## une phrase pour « 90 de vitesse » n'apprendrait rien.
func test_une_statistique_evidente_n_a_qu_une_ligne() -> void:
	assert_eq(StatHelp.lines("move_speed", CharacterStats.new()).size(), 1)


func test_un_champ_inconnu_ne_rend_rien() -> void:
	assert_eq(StatHelp.lines("chance", CharacterStats.new()).size(), 0)
	assert_false(StatHelp.has("chance"))
