extends GutTest

## Les trois attributs et ce qu'ils gouvernent. Un attribut qui ne dérive rien
## serait une ligne de plus sur la fiche et rien d'autre — c'est précisément ce
## que ces tests empêchent de devenir vrai en silence.


func test_attributes_are_zero_by_default() -> void:
	var st := CharacterStats.new()
	for field in CharacterStats.ATTRIBUTES:
		assert_eq(float(st.get(field)), 0.0, "%s à zéro : un grunt n'en a pas" % field)


func test_strength_gives_health_and_damage() -> void:
	var st := CharacterStats.new()
	st.max_health = 100.0
	st.strength = 10.0
	st.apply_attributes()
	assert_eq(st.max_health, 120.0, "+2 PV par point")
	assert_almost_eq(st.strength_damage(), 2.0, 0.001, "+0,2 dégât physique aux attaques par point")


func test_dexterity_gives_evasion_and_attack_speed() -> void:
	var st := CharacterStats.new()
	st.dexterity = 10.0
	st.apply_attributes()
	assert_eq(st.evasion, 15.0, "+1,5 d'esquive par point")
	assert_almost_eq(st.attack_speed, 1.04, 0.0001, "+0,4 point de % par point")


## L'esquive n'avait aucune source depuis le jalon 2 ; c'est la dextérité qui la
## lui donne enfin.
func test_dexterity_makes_evasion_really_useful() -> void:
	var st := CharacterStats.new()
	st.dexterity = 40.0
	st.apply_attributes()
	assert_gt(st.evade_chance(), 0.4, "40 de dextérité protègent réellement")


func test_intelligence_gives_mana_and_regeneration() -> void:
	var st := CharacterStats.new()
	st.max_mana = 50.0
	st.intelligence = 10.0
	st.apply_attributes()
	assert_eq(st.max_mana, 65.0, "+1,5 de mana par point")
	assert_almost_eq(st.mana_regen, 0.5, 0.0001, "+0,05 mana par seconde et par point")


## La cadence des sorts s'achète : une arme d'incantation, un nœud de l'arbre. Un
## attribut qui la donnerait la ferait monter toute seule, et plus personne n'irait
## la chercher.
func test_no_attribute_gives_cast_speed() -> void:
	for field in CharacterStats.ATTRIBUTES:
		var st := CharacterStats.new()
		st.set(field, 40.0)
		st.apply_attributes()
		assert_eq(st.cast_speed, 1.0, "%s ne touche pas à la vitesse d'incantation" % field)


## Chaque attribut doit toucher **deux** choses. Un attribut qui n'en gouverne
## qu'une est un alias pour la statistique qu'il pilote, et autant modifier
## celle-ci directement.
func test_each_attribute_governs_two_stats() -> void:
	var indicator := CharacterStats.new()
	indicator.apply_attributes()
	for field in CharacterStats.ATTRIBUTES:
		var st := CharacterStats.new()
		st.set(field, 20.0)
		st.apply_attributes()
		var changes := 0
		for other in ["max_health", "evasion", "attack_speed", "max_mana", "mana_regen", "cast_speed"]:
			if not is_equal_approx(float(st.get(other)), float(indicator.get(other))):
				changes += 1
		# Les dégâts de la force ne sont pas un champ de la fiche mais une
		# fourchette versée aux attaques : ils comptent quand même pour deux.
		if not is_equal_approx(st.strength_damage(), indicator.strength_damage()):
			changes += 1
		assert_eq(changes, 2, "%s gouverne exactement deux statistiques" % field)


## Appelée deux fois, elle compterait les bonus deux fois. C'est la même règle
## que pour recompute_stats, dont elle est un morceau.
func test_derivation_applies_only_once() -> void:
	var a := CharacterStats.new()
	a.strength = 10.0
	a.apply_attributes()
	var b := CharacterStats.new()
	b.strength = 10.0
	b.apply_attributes()
	b.apply_attributes()
	assert_ne(a.max_health, b.max_health, "deux appels ne donnent pas le même résultat")


func test_the_three_attributes_have_a_label() -> void:
	for field in CharacterStats.ATTRIBUTES:
		assert_true(StatMod.LABELS.has(field), "libellé pour %s" % field)


## Une entrée oubliée dans la liste ferait que ni la fiche ni le recalcul ne
## verraient le nouvel attribut.
func test_the_attribute_list_matches_the_fields() -> void:
	var st := CharacterStats.new()
	for field in CharacterStats.ATTRIBUTES:
		assert_not_null(st.get(field), "le champ %s existe" % field)
	assert_eq(CharacterStats.ATTRIBUTES.size(), 3)


## La fiche doit tenir entière dans la hauteur du cadrage. Ajouter un groupe ou
## une statistique fait déborder la dernière ligne sur l'aide du bas — c'est
## arrivé en ajoutant les attributs, et ça ne se voit que sur une capture.
func test_the_sheet_fits_its_height() -> void:
	var height: float = ProjectSettings.get_setting(
		"display/window/size/viewport_height"
	)
	var available_one := height - StatsPanel.FOOTER
	assert_lt(
		StatsPanel.content_height(), available_one,
		"%.0f px de contenu pour %.0f disponibles" % [
			StatsPanel.content_height(), available_one
		]
	)


# --------------------------------------------------------------------------
# Les infobulles de statistiques
# --------------------------------------------------------------------------

## Une table indexée par une liste de champs, c'est une entrée oubliée qui donne
## une bulle vide en plein jeu plutôt qu'un échec ici.
func test_each_sheet_stat_has_its_explanation() -> void:
	for group in StatsPanel.GROUPS:
		for field in group[1]:
			assert_true(
				StatHelp.has(field),
				"« %s » s'affiche sur la fiche sans explication" % field
			)


## Les explications des deux compétences de départ n'écrivent aucun nombre, mais
## elles affirment une famille, une cadence et un coût : c'est vérifié sur les
## compétences elles-mêmes.
func test_the_starting_skills_explanation_is_true() -> void:
	var attack := SkillCatalog.by_id(SkillCatalog.ID_ATTACK)
	assert_true(attack.worn(Keywords.ATTACK), "« aux attaques »")
	assert_eq(attack.cadence, Skill.Cadence.WEAPON, "« à la cadence de l'arme »")
	assert_eq(attack.mana_cost, 0.0, "« gratuit »")

	var starting_spell := SkillCatalog.by_id(SkillCatalog.ID_BOLT)
	assert_true(starting_spell.worn(Keywords.SPELL), "« un sort »")
	assert_eq(starting_spell.cadence, Skill.Cadence.CAST, "« suit la vitesse d'incantation »")
	assert_gt(starting_spell.mana_cost, 0.0, "« coûte du mana »")

	for id in [SkillCatalog.ID_ATTACK, SkillCatalog.ID_BOLT]:
		assert_eq(StatHelp.lines(id, CharacterStats.new()).size(), 1, "une phrase, sans ligne « ici »")


## Et l'inverse : une explication pour un champ qui n'existe plus ne se verrait
## jamais, et personne ne penserait à la retirer.
func test_no_explanation_targets_an_unknown_field() -> void:
	var sheet := CharacterStats.new()
	for field in StatHelp.TEXTS:
		assert_true(
			StatMod.LABELS.has(field), "« %s » n'a pas de nom lisible" % field
		)
		assert_true(
			sheet.get(field) != null, "« %s » n'est pas un champ de la fiche" % field
		)


## La ligne « en ce moment » est calculée depuis la fiche, jamais recopiée : un
## texte qui affirmerait un plafond que le code n'applique pas serait pire que
## pas de texte du tout.
func test_the_explanation_says_what_the_sheet_is_really_worth() -> void:
	var sheet := CharacterStats.new()
	sheet.armor = 40.0
	var lines := StatHelp.lines("armor", sheet)
	assert_eq(lines.size(), 2, "ce que ça fait, puis ce que ça vaut")
	var expected := "%d %%" % roundi(sheet.armor_reduction(StatHelp.LIGHT_HIT) * 100.0)
	assert_true(lines[1].contains(expected), "« %s » attendu dans « %s »" % [expected, lines[1]])


func test_resistances_announce_their_cap() -> void:
	var sheet := CharacterStats.new()
	for field in DamageType.RESIST_FIELDS:
		if field.is_empty():
			continue
		var lines := StatHelp.lines(field, sheet)
		assert_eq(lines.size(), 2, "« %s »" % field)
		assert_true(
			lines[1].contains("%d %%" % roundi(CharacterStats.MAX_RESISTANCE)),
			"le plafond réel apparaît : %s" % lines[1]
		)


## Une statistique qui se lit directement n'a pas de seconde ligne : inventer
## une phrase pour « 90 de vitesse » n'apprendrait rien.
func test_an_obvious_stat_has_only_one_line() -> void:
	assert_eq(StatHelp.lines("move_speed", CharacterStats.new()).size(), 1)


func test_an_unknown_field_returns_nothing() -> void:
	assert_eq(StatHelp.lines("chance", CharacterStats.new()).size(), 0)
	assert_false(StatHelp.has("chance"))
