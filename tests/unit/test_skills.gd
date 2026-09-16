extends GutTest

## La compétence hors de tout : la fiche, sa table de dégâts, et la formule qui
## en sort un nombre. Aucun manuel, aucune interface, aucun arbre de scène — au
## jalon 6, c'est la seule règle qui décide de ce que fait un coup.

## Une fiche neutre, dont chaque test ne règle que ce qu'il regarde. Les valeurs
## par défaut de CharacterStats peuvent changer, et un test qui les subit
## mesurerait autre chose que ce qu'il annonce.
func _sheet() -> CharacterStats:
	var f := CharacterStats.new()
	f.strength = 0.0
	f.dexterity = 0.0
	f.intelligence = 0.0
	return f


## Une compétence de test, écrite ici et non lue sur le disque : le contenu du
## jeu changera, la formule non.
func _skill(table: Array[float]) -> Skill:
	var c := Skill.new()
	c.id = "trial"
	c.name = "Trial"
	c.damage_per_point = table
	return c


# --------------------------------------------------------------------------
# Le catalogue
# --------------------------------------------------------------------------

func test_each_skill_has_an_id() -> void:
	for c in SkillCatalog.ALL:
		assert_false(c.id.is_empty(), "« %s » n'a pas d'identifiant" % c.name)
		assert_false(c.name.is_empty(), "« %s » n'a pas de nom lisible" % c.id)


## Deux compétences de même identifiant, c'est une barre sauvegardée qui rappelle
## l'une pour l'autre au chargement suivant.
func test_ids_are_unique() -> void:
	var seen_all := {}
	for c in SkillCatalog.ALL:
		assert_false(seen_all.has(c.id), "« %s » est écrit deux fois" % c.id)
		seen_all[c.id] = true


func test_a_skill_is_found_by_its_id() -> void:
	var c := SkillCatalog.by_id(SkillCatalog.ID_ATTACK)
	assert_not_null(c)
	assert_eq(c.id, SkillCatalog.ID_ATTACK)


## Une barre sauvegardée peut citer une compétence retirée du projet depuis. Ce
## n'est pas une erreur de programmation, c'est un cas de jeu : la case se vide.
func test_a_vanished_skill_returns_null() -> void:
	assert_null(SkillCatalog.by_id("spell_that_does_not_exist"))


## Une table vide, c'est une compétence qui ne fait jamais rien : elle ne se
## découvre qu'en la lançant, et elle ressemble alors à une panne.
func test_each_skill_has_what_it_takes_to_deal_damage() -> void:
	for c in SkillCatalog.ALL:
		assert_gt(c.points_max(), 0, "« %s » n'a aucun point dans sa table" % c.name)


## Un tir à vitesse nulle naît et reste sur place. Il ne se découvre qu'en le
## lançant, et il ressemble alors à une panne du lanceur plutôt qu'à un oubli
## dans le `.tres`.
func test_each_skill_casting_projectiles_has_a_speed() -> void:
	for c in SkillCatalog.ALL:
		if c.worn(Keywords.PROJECTILE):
			assert_gt(c.projectile_speed, 0.0, "« %s » lance des traits immobiles" % c.name)


# --------------------------------------------------------------------------
# Les mots-clés (jalon 7)
# --------------------------------------------------------------------------

## **La faute de frappe silencieuse** : un `projectiles` au pluriel dans un `.tres`
## ne casse rien, le sort ne reçoit simplement jamais son bonus. C'est la raison
## d'être de la liste fermée, et ce test en est la porte.
##
## Les fautes se comptent au lieu de s'affirmer une à une : aucune compétence ne
## déclare plus rien depuis que la forme donne `projectile`, et un test qui ne
## parcourt qu'une liste vide n'affirme rien du tout.
func test_each_declared_keyword_belongs_to_the_list() -> void:
	var faults := PackedStringArray()
	for c in SkillCatalog.ALL:
		for id in c.declared_keywords:
			if not Keywords.exists(id):
				faults.append("« %s » déclare « %s »" % [c.name, id])
	assert_eq(faults.size(), 0, "hors de la liste : %s" % ", ".join(faults))


## La nature et la cadence disent déjà `lightning` et `spell`. Les écrire aussi dans
## la déclaration, c'est deux vérités sur la même chose : le jour où la nature
## change, l'une des deux ment.
func test_do_not_declare_what_nature_or_cadence_already_say() -> void:
	var deduced := (
		Skill.KEYWORD_OF_CADENCE.values() + Skill.KEYWORD_OF_NATURE.values()
		+ Skill.KEYWORD_OF_SHAPE.values()
	)
	var faults := PackedStringArray()
	for c in SkillCatalog.ALL:
		for id in c.declared_keywords:
			if deduced.has(id):
				faults.append("« %s » déclare « %s »" % [c.name, id])
	assert_eq(faults.size(), 0, "se déduit déjà : %s" % ", ".join(faults))


## Le joueur lit un libellé, jamais un identifiant. Et une déduction qui visait un
## mot hors de la liste donnerait un mot-clé que la fiche ne sait pas nommer.
func test_each_keyword_has_a_label_and_each_deduction_targets_the_list() -> void:
	for id in Keywords.LABELS:
		assert_false(String(Keywords.LABELS[id]).is_empty(), "« %s » n'a pas de libellé" % id)
	for id in (
		Skill.KEYWORD_OF_CADENCE.values() + Skill.KEYWORD_OF_NATURE.values()
		+ Skill.KEYWORD_OF_SHAPE.values()
	):
		assert_true(Keywords.exists(id), "la déduction donne « %s », hors de la liste" % id)


func test_a_lightning_skill_carries_lightning_without_writing_it() -> void:
	var c := _skill([1.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	assert_true(c.declared_keywords.is_empty(), "rien n'est déclaré")
	assert_true(c.worn(Keywords.LIGHTNING))


func test_cadence_gives_spell_or_attack() -> void:
	var c := _skill([1.0] as Array[float])
	c.cadence = Skill.Cadence.CAST
	assert_true(c.worn(Keywords.SPELL), "une incantation est un sort")
	assert_false(c.worn(Keywords.ATTACK))
	c.cadence = Skill.Cadence.WEAPON
	assert_true(c.worn(Keywords.ATTACK), "un geste à la cadence de l'arme est une attaque")
	assert_false(c.worn(Keywords.SPELL))


## Aucun modificateur ne vise le froid : une compétence de froid ne doit donc pas
## l'afficher. Un mot-clé montré est une promesse, et celle-ci ne serait pas tenue.
func test_a_nature_nothing_targets_gives_no_keyword() -> void:
	var c := _skill([1.0] as Array[float])
	c.nature = DamageType.Kind.COLD
	assert_eq(Array(c.keywords()), [Keywords.SPELL])


func test_a_bolt_carries_projectile_and_a_sword_swing_does_not() -> void:
	assert_true(SkillCatalog.by_id(SkillCatalog.ID_BOLT).worn(Keywords.PROJECTILE))
	assert_false(SkillCatalog.by_id(SkillCatalog.ID_ATTACK).worn(Keywords.PROJECTILE))


## `projectile` se déduit de la forme (jalon 11), et d'elle seule : une chaîne ou
## un nuage n'en sont pas, et un affixe de projectile ne doit pas les servir.
func test_the_shape_gives_projectile() -> void:
	var c := _skill([1.0] as Array[float])
	for shape in Skill.Shape.values():
		c.shape = shape
		assert_eq(
			c.worn(Keywords.PROJECTILE),
			shape in [Skill.Shape.BOLT, Skill.Shape.BALL],
			"forme %s" % Skill.Shape.keys()[shape]
		)


## Une forme à qui manque son nombre ne plante pas : un nuage sans durée disparaît
## à sa pose, une chaîne à une cible est un éclair. Ça se découvre en jouant, et
## ressemble à une panne.
func test_each_shape_has_the_numbers_it_needs() -> void:
	for c: Skill in SkillCatalog.ALL:
		var lasts := c.shape in [Skill.Shape.CLOUD, Skill.Shape.SNAKE, Skill.Shape.ORBIT]
		var strike_at_interval := lasts or c.shape == Skill.Shape.AURA
		var covers := c.shape in [Skill.Shape.BALL, Skill.Shape.CLOUD, Skill.Shape.AURA]
		if lasts:
			assert_gt(c.duration, 0.0, "« %s » : une durée" % c.name)
		if strike_at_interval:
			assert_gt(c.period, 0.0, "« %s » : une période" % c.name)
		if covers:
			assert_gt(c.radius, 0.0, "« %s » : un rayon" % c.name)
		if c.shape == Skill.Shape.CHAIN:
			assert_gte(c.targets, 2, "« %s » : une chaîne saute" % c.name)
		if c.shape == Skill.Shape.ORBIT:
			assert_gte(c.simultaneous, 1, "« %s » : un maximum" % c.name)
		if c.shape == Skill.Shape.AURA:
			assert_gt(c.self_burn, 0.0, "« %s » : son prix" % c.name)


## L'ordre est celui de la liste, pas celui de la déclaration ni celui de la
## déduction : deux compétences voisines doivent se lire colonne contre colonne.
func test_the_sheet_writes_keywords_in_list_order() -> void:
	assert_eq(
		SkillCatalog.by_id("swift_bolt").keywords_label(),
		"Projectile · Foudre · Sort"
	)
	assert_eq(SkillCatalog.by_id(SkillCatalog.ID_ATTACK).keywords_label(), "Attaque")


# --------------------------------------------------------------------------
# La résolution (jalon 7)
# --------------------------------------------------------------------------

func _projectile(count: int, dispersion := 0.0) -> Skill:
	var c := _skill([10.0] as Array[float])
	c.declared_keywords = PackedStringArray([Keywords.PROJECTILE])
	c.projectiles = count
	c.spread_in_degrees = dispersion
	return c


func _mod(stat: String, mode: StatMod.Mode, value: float, scope := Keywords.PROJECTILE) -> StatMod:
	return StatMod.new(stat, mode, value, scope)


## **Le test qui garantit que la résolution ne change pas le jeu** : sans
## modificateur, chaque compétence du catalogue rend exactement les nombres de sa
## fiche. Une borne mal placée dans `finalize()` le ferait tomber ici plutôt
## qu'en jouant.
func test_without_modifier_resolution_returns_the_sheet() -> void:
	var sheet := CharacterStats.new()
	for c in SkillCatalog.ALL:
		var points: int = c.points_max()
		var r: SkillStats = c.resolve(points, sheet)
		assert_eq(r.damage_min[c.nature], c.damage(points), "« %s » : dégâts" % c.name)
		assert_eq(r.total_min(), c.damage(points), "« %s » : dans sa seule nature" % c.name)
		assert_eq(r.total_max(), r.total_min(), "« %s » : sans objet, aucune fourchette" % c.name)
		assert_eq(r.projectile_count(), maxi(c.projectiles, 1), "« %s » : projectiles" % c.name)
		assert_eq(r.spread_in_degrees, c.spread_in_degrees, "« %s » : dispersion" % c.name)
		assert_eq(r.projectile_speed, c.projectile_speed, "« %s » : vitesse" % c.name)
		assert_eq(r.mana_cost, c.mana_cost, "« %s » : coût" % c.name)
		assert_eq(r.interval, c.interval(sheet), "« %s » : intervalle" % c.name)


func _shape(shape: Skill.Shape) -> Skill:
	var c := _skill([10.0] as Array[float])
	c.shape = shape
	return c


func test_resolution_copies_the_shape_numbers() -> void:
	var c := _shape(Skill.Shape.CLOUD)
	c.duration = 3.0
	c.radius = 30.0
	c.period = 0.5
	c.targets = 3
	c.simultaneous = 2
	c.self_burn = 0.03
	var r := c.resolve(1, _sheet())
	assert_eq(r.duration, 3.0)
	assert_eq(r.radius, 30.0)
	assert_eq(r.period, 0.5)
	assert_eq(r.target_count(), 3)
	assert_eq(r.max_simultaneous(), 2)
	assert_eq(r.self_burn, 0.03)
	assert_eq(r.hits, 1)
	assert_false(r.sustained)


func test_a_modifier_changes_the_shape_numbers() -> void:
	var c := _shape(Skill.Shape.CLOUD)
	c.duration = 3.0
	c.radius = 30.0
	c.targets = 3
	var r := c.resolve(1, _sheet(), [
		_mod("duration", StatMod.Mode.PERCENT, 50.0, Keywords.SPELL),
		_mod("radius", StatMod.Mode.PERCENT, 20.0, Keywords.SPELL),
		_mod("targets", StatMod.Mode.FLAT, 1.0, Keywords.SPELL),
	])
	assert_almost_eq(r.duration, 4.5, 0.0001)
	assert_almost_eq(r.radius, 36.0, 0.0001)
	assert_eq(r.target_count(), 4)


## Court-circuit retire une cible : il ne doit pas faire une chaîne qui ne touche
## personne.
func test_a_chain_keeps_its_first_target_and_an_orbit_its_place() -> void:
	var c := _shape(Skill.Shape.ORBIT)
	c.simultaneous = 1
	var r := c.resolve(1, _sheet(), [
		_mod("targets", StatMod.Mode.FLAT, -3.0, Keywords.SPELL),
		_mod("simultaneous", StatMod.Mode.FLAT, -5.0, Keywords.SPELL),
	])
	assert_eq(r.target_count(), 1)
	assert_eq(r.max_simultaneous(), 1)


func test_the_estimate_counts_the_hits_of_a_cast() -> void:
	var chain := _shape(Skill.Shape.CHAIN)
	chain.targets = 3
	assert_eq(chain.resolve(1, _sheet()).average_per_cast(), 30.0, "trois cibles")

	var cross := _shape(Skill.Shape.CROSS)
	assert_eq(cross.resolve(1, _sheet()).average_per_cast(), 20.0, "deux coups")

	var cloud := _shape(Skill.Shape.CLOUD)
	cloud.duration = 3.0
	cloud.period = 0.5
	cloud.cooldown = 2.0
	var r := cloud.resolve(1, _sheet())
	assert_eq(r.average_per_cast(), 60.0, "six frappes dans la durée")
	assert_eq(r.average_per_second(), 30.0)


## 3 × 1,25 ne tombe pas pile sur un multiple de 0,5 : sans marge, le nuage
## prolongé perdrait une frappe à l'arrondi.
func test_strikes_of_an_extended_duration_are_not_lost_to_rounding() -> void:
	var cloud := _shape(Skill.Shape.CLOUD)
	cloud.duration = 3.0
	cloud.period = 0.5
	var r := cloud.resolve(1, _sheet(), [_mod("duration", StatMod.Mode.PERCENT, 25.0, Keywords.SPELL)])
	assert_eq(r.strikes_over_duration(), 7)


## La brûlure d'une aura se répartit comme ses dégâts : la conversion y compte.
func test_the_distribution_follows_parts_and_conversion() -> void:
	var aura := _shape(Skill.Shape.AURA)
	aura.nature = DamageType.Kind.FIRE
	var whole := aura.resolve(1, _sheet()).distribution()
	assert_eq(whole[DamageType.Kind.FIRE], 1.0)

	var node := TalentNode.new()
	node.converts_to = DamageType.Kind.NECROTIC
	node.converted_part_per_point = 0.5
	var converted_one := aura.resolve(1, _sheet(), [], [InvestedTalent.new(node, 1)]).distribution()
	assert_almost_eq(converted_one[DamageType.Kind.FIRE], 0.5, 0.0001)
	assert_almost_eq(converted_one[DamageType.Kind.NECROTIC], 0.5, 0.0001)
	var sum := 0.0
	for part in converted_one:
		sum += part
	assert_almost_eq(sum, 1.0, 0.0001)


## Sans dégâts, tout va à la nature de la compétence : une répartition vide ne dirait
## contre quoi se défendre.
func test_a_distribution_without_damage_goes_to_the_nature() -> void:
	var aura := _skill([0.0] as Array[float])
	aura.nature = DamageType.Kind.COLD
	assert_eq(aura.resolve(1, _sheet()).distribution()[DamageType.Kind.COLD], 1.0)


func test_an_aura_is_only_estimated_per_second() -> void:
	var aura := _shape(Skill.Shape.AURA)
	aura.period = 0.5
	aura.cooldown = 1.0
	var r := aura.resolve(1, _sheet())
	assert_true(r.sustained)
	assert_eq(r.average_per_cast(), 0.0, "elle n'a pas de fin")
	assert_eq(r.average_per_second(), 20.0, "un coup par demi-seconde")


## Une épée par intervalle d'arme en ferait vingt à la fois sur le papier.
func test_an_orbit_is_estimated_bounded_by_its_maximum() -> void:
	var orbit := _shape(Skill.Shape.ORBIT)
	orbit.cadence = Skill.Cadence.WEAPON
	orbit.duration = 5.0
	orbit.period = 0.5
	orbit.simultaneous = 3
	assert_eq(orbit.resolve(1, _sheet()).average_per_second(), 60.0, "trois épées, deux coups par seconde")


func test_one_more_projectile() -> void:
	var r := _projectile(1).resolve(1, _sheet(), [_mod("projectiles", StatMod.Mode.FLAT, 1.0)])
	assert_eq(r.projectile_count(), 2)


## Deux objets identiques donnent le même sort quel que soit l'ordre dans lequel
## on les porte — la règle de `StatMod.apply_all`, pour la même raison.
func test_flats_apply_before_percentages() -> void:
	var flat := _mod("projectiles", StatMod.Mode.FLAT, 1.0)
	var percent_value := _mod("projectiles", StatMod.Mode.PERCENT, 50.0)
	var c := _projectile(2, 90.0)
	assert_eq(
		c.resolve(1, _sheet(), [flat, percent_value]).projectile_count(), 5,
		"(2 + 1) × 1,5 = 4,5, arrondi à 5 — et non 2 × 1,5 + 1 = 4"
	)
	assert_eq(
		c.resolve(1, _sheet(), [percent_value, flat]).projectile_count(), 5,
		"dans l'autre ordre aussi"
	)


## En « plus » : deux accrus s'additionneraient (3 × 2) et n'exerceraient pas l'arrondi.
func test_the_projectile_count_is_rounded_at_the_end() -> void:
	var mods := [
		_mod("projectiles", StatMod.Mode.MORE, 50.0),
		_mod("projectiles", StatMod.Mode.MORE, 50.0),
	]
	assert_eq(
		_projectile(3, 90.0).resolve(1, _sheet(), mods).projectile_count(), 7,
		"3 × 1,5 × 1,5 = 6,75, arrondi une fois — arrondi à chaque étape, on aurait 8"
	)


func test_a_modifier_whose_keyword_is_not_carried_does_nothing() -> void:
	var sword := _skill([10.0] as Array[float])
	sword.cadence = Skill.Cadence.WEAPON
	var r := sword.resolve(1, _sheet(), [
		_mod("projectiles", StatMod.Mode.FLAT, 1.0),
		_mod("damage", StatMod.Mode.PERCENT, 50.0, Keywords.LIGHTNING),
	])
	assert_eq(r.projectile_count(), 1, "une épée ne lance rien")
	assert_eq(r.total_min(), 10.0, "et une épée physique n'est pas de la foudre")


## Un modificateur sans portée appartient à la fiche, qui l'a déjà appliqué :
## le reprendre ici le compterait deux fois.
func test_a_sheet_modifier_does_not_touch_the_skill() -> void:
	var r := _projectile(1).resolve(1, _sheet(), [
		StatMod.new("projectiles", StatMod.Mode.FLAT, 3.0),
	])
	assert_eq(r.projectile_count(), 1)


func test_damage_of_a_targeted_nature_rises() -> void:
	var c := _skill([10.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	var r := c.resolve(1, _sheet(), [_mod("damage", StatMod.Mode.PERCENT, 50.0, Keywords.LIGHTNING)])
	assert_eq(r.damage_min[DamageType.Kind.LIGHTNING], 15.0)


## Le coût a sa propre voie — la réserve. Un modificateur qui le viserait par un
## mot-clé est écarté, et c'est le test de la réserve d'affixes qui refuse de
## l'écrire.
func test_only_named_things_are_modified() -> void:
	var c := _projectile(1)
	c.mana_cost = 8.0
	var r := c.resolve(1, _sheet(), [_mod("mana_cost", StatMod.Mode.FLAT, -8.0)])
	assert_eq(r.mana_cost, 8.0)


## Deux traits partis du même angle se superposent : on en voit un, et il frappe
## deux fois. Le premier projectile ajouté à un trait droit ouvre donc un écart.
func test_two_bolts_never_leave_on_top_of_each_other() -> void:
	var plus_one := [_mod("projectiles", StatMod.Mode.FLAT, 1.0)]
	assert_eq(
		_projectile(1, 0.0).resolve(1, _sheet(), plus_one).spread_in_degrees,
		SkillStats.MIN_SPREAD, "un trait droit s'ouvre"
	)
	assert_eq(
		_projectile(3, 24.0).resolve(1, _sheet(), plus_one).spread_in_degrees, 24.0,
		"une salve déjà assez large garde la sienne"
	)


## Au-delà du tour complet, le lanceur prendrait l'éventail pour une couronne.
func test_spread_does_not_exceed_a_full_turn() -> void:
	var r := _projectile(8, 360.0).resolve(1, _sheet(), [
		_mod("projectiles", StatMod.Mode.FLAT, 60.0),
	])
	assert_eq(r.spread_in_degrees, 360.0)


# --------------------------------------------------------------------------
# Les dégâts par nature, en fourchette (jalon 8)
# --------------------------------------------------------------------------

func _addition(nature: DamageType.Kind, low: float, top: float, scope := Keywords.SPELL) -> StatMod:
	return StatMod.ranged(SkillStats.added_stat(nature), low, top, scope)


## Le froid ajouté à un sort de foudre reste du froid : c'est ce qui le laisse
## passer quand l'ennemi résiste à la foudre.
func test_an_added_range_goes_into_its_nature() -> void:
	var c := _skill([10.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	var r := c.resolve(1, _sheet(), [_addition(DamageType.Kind.COLD, 3.0, 7.0)])
	assert_eq(r.damage_min[DamageType.Kind.LIGHTNING], 10.0, "la foudre du sort")
	assert_eq(r.damage_max[DamageType.Kind.LIGHTNING], 10.0, "sans fourchette")
	assert_eq(r.damage_min[DamageType.Kind.COLD], 3.0, "et le froid à part")
	assert_eq(r.damage_max[DamageType.Kind.COLD], 7.0)


## « +50 % dégâts (Foudre) » vise la compétence, pas la part : le froid qu'elle
## porte est multiplié avec sa foudre.
func test_a_damage_percentage_multiplies_every_part() -> void:
	var c := _skill([10.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	var r := c.resolve(1, _sheet(), [
		_addition(DamageType.Kind.COLD, 4.0, 8.0),
		_mod("damage", StatMod.Mode.PERCENT, 50.0, Keywords.LIGHTNING),
	])
	assert_eq(r.damage_min[DamageType.Kind.LIGHTNING], 15.0)
	assert_eq(r.damage_min[DamageType.Kind.COLD], 6.0)
	assert_eq(r.damage_max[DamageType.Kind.COLD], 12.0)


## La décomposition que la fiche du manuel affiche **refait** les dégâts du
## lancer : la base et les ajouts, multipliés par l'accroissement.
## Si elle s'en écartait, la fiche écrirait des lignes dont la somme n'est pas le
## coup qui part.
func test_the_breakdown_rebuilds_the_damage() -> void:
	var c := _skill([10.0] as Array[float])
	c.nature = DamageType.Kind.LIGHTNING
	var r := c.resolve(1, _sheet(), [
		_addition(DamageType.Kind.COLD, 4.0, 8.0),
		_addition(DamageType.Kind.LIGHTNING, 1.0, 3.0),
		_mod("damage", StatMod.Mode.PERCENT, 50.0, Keywords.LIGHTNING),
		_mod("damage", StatMod.Mode.PERCENT, 10.0, Keywords.SPELL),
	])
	assert_eq(r.base_damage, 10.0, "la ligne de la table, avant tout multiplicateur")
	assert_eq(r.added_min[DamageType.Kind.COLD], 4.0)
	assert_eq(r.added_max[DamageType.Kind.LIGHTNING], 3.0, "la foudre ajoutée, à part de la base")
	# Jalon 14 : la règle a changé, les accrus s'additionnent (1,65 avant).
	assert_almost_eq(r.increased, 1.60, 1e-6, "50 % + 10 % : les accrus s'additionnent")
	assert_eq(r.more, 1.0, "aucun « plus » porté")

	var factor := r.increased * r.more
	for nature in DamageType.Kind.size():
		var base := r.base_damage if nature == c.nature else 0.0
		assert_almost_eq(
			r.damage_min[nature], (base + r.added_min[nature]) * factor, 1e-4,
			"borne basse, %s" % DamageType.NAMES[nature]
		)
		assert_almost_eq(
			r.damage_max[nature], (base + r.added_max[nature]) * factor, 1e-4,
			"borne haute, %s" % DamageType.NAMES[nature]
		)


## L'estimation d'un lancer : le milieu de chaque fourchette, fois les projectiles,
## puis ramenée à la seconde par l'intervalle.
func test_a_cast_estimate_is_the_average_of_its_projectiles() -> void:
	var r := SkillStats.new()
	r.place_the_base(DamageType.Kind.LIGHTNING, 10.0)
	r.add_to(DamageType.Kind.COLD, 2.0, 6.0)
	r.projectiles = 3.0
	r.interval = 0.5
	assert_almost_eq(r.average_per_cast(), 42.0, 1e-4, "14 en moyenne, trois fois")
	assert_almost_eq(r.average_per_second(), 84.0, 1e-4, "deux lancers par seconde")
	r.interval = 0.0
	assert_eq(r.average_per_second(), 0.0, "sans intervalle, pas d'infini")


## Et elle dit vrai : c'est la moyenne de ce que les tirages font réellement. Un
## tirage local, pour ne rien prendre au fil de `Game.rng`.
func test_the_estimate_matches_the_average_of_rolls() -> void:
	var r := SkillStats.new()
	r.add_to(DamageType.Kind.COLD, 3.0, 7.0)
	r.add_to(DamageType.Kind.FIRE, 1.0, 9.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var sum := 0.0
	for i in 20000:
		for part in r.roll(rng):
			sum += part
	assert_almost_eq(sum / 20000.0, r.average_per_cast(), 0.1, "10 attendus")


## Une fourchette ajoutée aux attaques ne touche pas un sort, et l'inverse.
func test_a_range_only_touches_its_family() -> void:
	var spell := _skill([10.0] as Array[float])
	var r := spell.resolve(1, _sheet(), [_addition(DamageType.Kind.FIRE, 5.0, 9.0, Keywords.ATTACK)])
	assert_eq(r.total_max(), 10.0, "un sort n'est pas une attaque")


func test_a_hit_rolls_within_its_bounds() -> void:
	var r := SkillStats.new()
	r.add_to(DamageType.Kind.COLD, 3.0, 7.0)
	r.add_to(DamageType.Kind.LIGHTNING, 10.0, 10.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	for i in 200:
		var parts := r.roll(rng)
		assert_between(parts[DamageType.Kind.COLD], 3.0, 7.0)
		assert_eq(parts[DamageType.Kind.LIGHTNING], 10.0, "une part sans fourchette ne varie pas")


## **Invariant 3.** Le nombre de tirages ne dépend que des fourchettes ouvertes,
## jamais de ce qui sort : sinon chaque coup décalerait les tirages suivants d'un
## nombre différent.
func test_a_hit_rolls_once_per_open_range() -> void:
	var r := SkillStats.new()
	r.add_to(DamageType.Kind.COLD, 3.0, 7.0)
	r.add_to(DamageType.Kind.FIRE, 1.0, 2.0)
	r.add_to(DamageType.Kind.LIGHTNING, 10.0, 10.0)
	for seed_value in [1, 2, 3]:
		var rolled := RandomNumberGenerator.new()
		rolled.seed = seed_value
		var indicator := RandomNumberGenerator.new()
		indicator.seed = seed_value
		r.roll(rolled)
		indicator.randf()
		indicator.randf()
		assert_eq(rolled.state, indicator.state, "deux fourchettes ouvertes, deux tirages (graine %d)" % seed_value)


# --------------------------------------------------------------------------
# La formule
# --------------------------------------------------------------------------

## Une compétence non apprise n'est pas une compétence faible : elle n'existe
## pas. Sans ce zéro, une case vide de la barre lancerait un sort gratuit.
func test_zero_point_returns_nothing() -> void:
	var c := _skill([10.0, 20.0] as Array[float])
	assert_eq(c.damage(0), 0.0)
	assert_eq(c.damage(-3), 0.0, "et un nombre négatif non plus")


func test_each_point_gives_its_line_value() -> void:
	var c := _skill([10.0, 25.0, 45.0] as Array[float])
	var f := _sheet()
	assert_eq(c.damage(1), 10.0, "le premier point")
	assert_eq(c.damage(2), 25.0, "le deuxième")
	assert_eq(c.damage(3), 45.0, "le troisième")
	assert_eq(c.points_max(), 3, "et la table dit combien la case accepte")


## Demander plus de points que la table n'en contient rend le dernier, jamais une
## erreur d'indice : l'appelant qui se trompe doit obtenir le meilleur coup, pas
## interrompre un combat.
func test_beyond_the_last_point_the_last_is_kept() -> void:
	var c := _skill([10.0, 25.0] as Array[float])
	assert_eq(c.damage(9), 25.0)


## Aucun attribut ne multiplie les dégâts d'une compétence (retiré le 15 septembre
## 2026) : la force et l'intelligence donnent leurs réserves, pas un pourcentage.
func test_no_attribute_multiplies_damage() -> void:
	var c := _skill([10.0] as Array[float])
	var f := _sheet()
	f.intelligence = 100.0
	f.strength = 100.0
	assert_eq(c.resolve(1, f).total_min(), 10.0)


# --------------------------------------------------------------------------
# Les deux attaques de départ, qui ne doivent pas changer de valeur
# --------------------------------------------------------------------------

## Le coup d'épée rend douze, exactement : ce que la fiche du joueur lui donnait
## avant que ce nombre n'entre dans sa table. Le critique n'est pas dedans : il vit
## dans `DamageInfo.roll()`, et une compétence ne le retire ni ne le double.
func test_the_basic_hit_deals_the_former_damage() -> void:
	var c := SkillCatalog.by_id(SkillCatalog.ID_ATTACK)
	assert_eq(c.damage(1), 12.0)
	assert_eq(c.mana_cost, 0.0, "et il reste gratuit")


## Et le tir, sept : les dégâts de sort de l'ancienne fiche.
func test_the_bolt_deals_the_former_damage() -> void:
	var c := SkillCatalog.by_id(SkillCatalog.ID_BOLT)
	assert_eq(c.damage(1), 7.0)
	assert_gt(c.mana_cost, 0.0, "et il coûte toujours du mana")



# --------------------------------------------------------------------------
# Les icônes
# --------------------------------------------------------------------------

## Une image de cette taille, unie, pour éprouver la mise au cadre sans dépendre
## d'un fichier du disque : le tuyau doit marcher avant qu'une seule illustration
## n'existe.
func _image(w: int, h: int) -> Texture2D:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0.7, 0.5, 1.0))
	return ImageTexture.create_from_image(img)


func _with_icon(id: String, tex: Texture2D) -> Skill:
	SkillIcon.forget()
	var c := Skill.new()
	c.id = id
	c.icon = tex
	return c


## Sans image, pas d'icône — et ce n'est pas une erreur. C'est l'état de toutes
## les compétences tant qu'aucune n'a été produite, et la barre doit alors
## retomber sur son disque de couleur au lieu de laisser une case vide.
func test_a_skill_without_image_has_no_icon() -> void:
	assert_null(SkillIcon.texture(null), "aucune compétence")
	assert_null(
		SkillIcon.texture(SkillCatalog.by_id(SkillCatalog.ID_ATTACK)),
		"une compétence sans image"
	)


## Une illustration générée fait mille pixels de côté, pas vingt-quatre. Sans
## cette réduction elle sortirait de sa case et recouvrirait ses voisines.
func test_a_large_image_is_brought_back_to_the_frame() -> void:
	var tex := SkillIcon.texture(_with_icon("large", _image(512, 512)))
	assert_not_null(tex)
	assert_eq(tex.get_size(), Vector2(SkillIcon.SIDE, SkillIcon.SIDE))


## Les proportions sont gardées : une image large et basse ramenée dans un carré
## deviendrait autre chose que ce qu'on a dessiné.
func test_reduction_keeps_proportions() -> void:
	var tex := SkillIcon.texture(_with_icon("large", _image(400, 200)))
	assert_eq(tex.get_size(), Vector2(24.0, 12.0))


## Une image déjà petite n'est **pas** agrandie ici : c'est la case qui le fera,
## et la barre et la page de manuel n'ont pas la même taille. L'agrandir au
## chargement figerait un facteur qui ne vaut que pour l'une des deux.
func test_a_small_image_stays_intact() -> void:
	var tex := SkillIcon.texture(_with_icon("petite", _image(16, 16)))
	assert_eq(tex.get_size(), Vector2(16.0, 16.0))


## Le facteur d'agrandissement est **entier**, sinon certaines lignes de pixels
## sont doublées et pas d'autres : la trame de l'icône se met à onduler, et ça ne
## se voit qu'à l'écran.
func test_the_zoom_factor_is_an_integer_and_fits_the_slot() -> void:
	var twelve := _image(12, 12)
	assert_eq(SkillIcon.factor(twelve, 26.0), 2, "deux fois douze tient dans vingt-six")
	assert_eq(SkillIcon.factor(twelve, 34.0), 2, "et trois fois, non")
	var twenty_four := _image(24, 24)
	assert_eq(SkillIcon.factor(twenty_four, 26.0), 1)
	assert_eq(SkillIcon.factor(null, 26.0), 1, "et sans icône, on n'agrandit rien")


## L'image fournie n'est jamais retouchée : c'est une ressource du disque, et la
## redimensionner sur place l'écrirait pour toutes les parties suivantes de la
## session (invariant 2).
func test_the_provided_image_is_not_modified() -> void:
	var source := _image(96, 96)
	SkillIcon.texture(_with_icon("intact", source))
	assert_eq(source.get_size(), Vector2(96.0, 96.0), "la source garde sa taille")


## Le cadre des icônes ne doit **jamais** dépasser la plus petite case qui les
## dessine : `factor()` ne descend pas en dessous de 1, donc une icône plus
## grande que sa case y serait dessinée telle quelle et déborderait sur ses
## voisines. On ne lirait plus la grille, et ça ne se verrait qu'à l'écran.
func test_the_icon_frame_fits_the_smallest_slot() -> void:
	assert_lte(float(SkillIcon.SIDE), SkillBarPanel.SLOT, "la case de la barre")
	assert_lte(float(SkillIcon.SIDE), ManualPanel.CELL, "la case du manuel")
