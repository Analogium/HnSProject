extends GutTest

## Les passifs et les arbres de talents : ce qu'une case porte, ce qu'un point y
## fait, ce qu'il faut pour l'y mettre, et ce qu'un nœud change au lancer.
##
## Deux moitiés, et elles ne se mélangent pas. **Les règles** sont vérifiées sur
## des archétypes fabriqués ici : le contenu du jeu changera, la règle non. **Le
## contenu** est parcouru depuis le catalogue : c'est la moitié qui refuse le nœud
## ajouté de travers, et aucune partie ne le montrerait avant plusieurs heures.


# --------------------------------------------------------------------------
# De quoi fabriquer un livre
# --------------------------------------------------------------------------

func _sheet() -> CharacterStats:
	var f := CharacterStats.new()
	f.strength = 0.0
	f.dexterity = 0.0
	f.intelligence = 0.0
	return f


func _line(stat: String, value: float, percentage := false, scope := "", top := 0.0) -> TalentLine:
	var l := TalentLine.new()
	l.stat = stat
	l.value_per_point = value
	l.value_max_per_point = top
	l.percentage = percentage
	l.scope = scope
	return l


func _skill(id: String, table: Array[float], nature := DamageType.Kind.LIGHTNING) -> Skill:
	var c := Skill.new()
	c.id = id
	c.name = id
	c.nature = nature
	c.damage_per_point = table
	return c


func _node(id: String, lines: Array[TalentLine], required := 1, maximum := 1, parent := "") -> TalentNode:
	var n := TalentNode.new()
	n.id = id
	n.name = id
	n.lines = lines
	n.required_points = required
	n.points_max = maximum
	n.parent = parent
	return n


func _passive(id: String, lines: Array[TalentLine], level := 1, maximum := 3) -> Passive:
	var p := Passive.new()
	p.id = id
	p.name = id
	p.lines = lines
	p.required_manual_level = level
	p.points_max = maximum
	return p


func _cell(worn: Resource, talents: Array[TalentNode] = []) -> ManualCell:
	var c := ManualCell.new()
	if worn is Skill:
		c.skill = worn
	else:
		c.passive = worn
	c.talents = talents
	return c


func _archetype(cells: Array[ManualCell]) -> ManualArchetype:
	var a := ManualArchetype.new()
	a.id = "trial"
	a.name = "Trial"
	a.cells = cells
	return a


## Le livre des règles : une compétence à cinq points avec deux nœuds — l'un
## enfant de l'autre — et un passif.
func _trial_book() -> ManualArchetype:
	var spell := _skill("spell", [10.0, 20.0, 30.0, 40.0, 50.0] as Array[float])
	var branch := _node("branch_spell", [_line("damage", 10.0, true)] as Array[TalentLine], 1, 3)
	var leaf := _node(
		"leaf_spell", [_line("projectiles", 1.0)] as Array[TalentLine], 2, 1, "branch_spell"
	)
	return _archetype([
		_cell(spell, [branch, leaf] as Array[TalentNode]),
		_cell(_passive("guard", [_line("armor", 10.0)] as Array[TalentLine], 2, 3)),
	] as Array[ManualCell])


## Un manuel au niveau voulu, avec de quoi payer. L'expérience est donnée par
## paquets plutôt que calculée : la courbe changera, le test non.
func _manual(level: int) -> Manual:
	var m := Manual.new()
	while m.level() < level:
		m.gain_experience(200)
	return m


func _talents(nodes: Array, points := 1) -> Array:
	var out := []
	for n: TalentNode in nodes:
		out.append(InvestedTalent.new(n, points))
	return out


# --------------------------------------------------------------------------
# Ce qu'une case porte
# --------------------------------------------------------------------------

func test_a_slot_says_what_it_holds() -> void:
	var arch := _trial_book()
	assert_eq(arch.cells[0].identifier(), "spell")
	assert_eq(arch.cells[0].points_max(), 5, "la compétence le déduit de sa table")
	assert_eq(arch.cells[1].identifier(), "guard")
	assert_eq(arch.cells[1].points_max(), 3, "le passif le déclare")
	assert_eq(arch.cells[1].required_level(), 2)


func test_the_archetype_finds_the_three_kinds() -> void:
	var arch := _trial_book()
	assert_not_null(arch.cell_of("spell"), "la case d'une compétence")
	assert_not_null(arch.passive_of("guard"), "un passif")
	assert_not_null(arch.node_of("leaf_spell"), "un nœud")
	assert_eq(arch.cell_of_node("leaf_spell").skill.id, "spell", "et la case qui le porte")

	assert_null(arch.cell_of("guard"), "un passif n'est pas une compétence")
	assert_null(arch.passive_of("spell"), "ni l'inverse")
	assert_eq(arch.skills().size(), 1, "une seule compétence")
	assert_eq(arch.passives().size(), 1, "et un seul passif")


## La question que se pose la relecture d'une sauvegarde : les trois sortes
## partagent le dictionnaire de points, et ce qu'aucune ne reconnaît est jeté.
func test_the_book_recognizes_its_three_kinds_of_ids() -> void:
	var arch := _trial_book()
	for id in ["spell", "guard", "branch_spell", "leaf_spell"]:
		assert_true(arch.knows(id), "« %s » est de ce livre" % id)
	assert_false(arch.knows("swift_bolt"), "une compétence d'un autre livre, non")
	assert_false(arch.knows(""), "ni rien du tout")


func test_a_node_knows_its_children() -> void:
	var cell := _trial_book().cells[0]
	assert_eq(cell.children_of("branch_spell").size(), 1, "la branche porte la feuille")
	assert_eq(cell.children_of("branch_spell")[0].id, "leaf_spell")
	assert_eq(cell.children_of("leaf_spell").size(), 0, "et la feuille ne porte rien")
	assert_eq(cell.children_of("").size(), 1, "les nœuds sans parent partent de la compétence")


# --------------------------------------------------------------------------
# Ce qu'un point coûte et ce qu'il demande
# --------------------------------------------------------------------------

func test_a_passive_is_invested_like_a_slot() -> void:
	var arch := _trial_book()
	var m := _manual(1)
	assert_false(m.can_invest(arch, "guard"), "niveau 1, le passif demande 2")

	m = _manual(2)
	assert_true(m.invest(arch, "guard"))
	assert_true(m.invest(arch, "guard"))
	assert_eq(m.points_of("guard"), 2)


func test_a_passive_does_not_exceed_its_maximum() -> void:
	var arch := _trial_book()
	var m := _manual(12)
	for i in 3:
		assert_true(m.invest(arch, "guard"), "les trois points du passif")
	assert_false(m.invest(arch, "guard"), "et pas un de plus")
	assert_eq(m.points_of("guard"), 3)


## **Un arbre s'achète après le sort, jamais à sa place.** Sans cette condition,
## un manuel neuf pourrait mettre son premier point dans un nœud d'une compétence
## qu'il ne sait pas encore lancer.
func test_a_node_requires_points_in_its_skill() -> void:
	var arch := _trial_book()
	var m := _manual(4)
	assert_false(m.can_invest(arch, "branch_spell"), "aucun point dans le sort")
	assert_true(m.invest(arch, "spell"), "un point dans le sort")
	assert_true(m.invest(arch, "branch_spell"), "et la branche s'ouvre")


func test_a_node_requires_its_parent() -> void:
	var arch := _trial_book()
	var m := _manual(8)
	for i in 2:
		assert_true(m.invest(arch, "spell"))
	assert_false(m.can_invest(arch, "leaf_spell"), "la branche est vide")
	assert_true(m.invest(arch, "branch_spell"))
	assert_true(m.invest(arch, "leaf_spell"), "la branche portant un point, la feuille s'ouvre")


func test_a_node_does_not_exceed_its_maximum() -> void:
	var arch := _trial_book()
	var m := _manual(12)
	assert_true(m.invest(arch, "spell"))
	for i in 3:
		assert_true(m.invest(arch, "branch_spell"), "les trois points de la branche")
	assert_false(m.invest(arch, "branch_spell"), "et pas un de plus")


## Les points sortent du même sac que les cases : c'est ce qui fait du manuel un
## choix plutôt qu'une collection à compléter.
func test_a_node_is_paid_with_manual_points() -> void:
	var arch := _trial_book()
	var m := _manual(2)
	assert_eq(m.remaining_points(), 2)
	assert_true(m.invest(arch, "spell"))
	assert_true(m.invest(arch, "branch_spell"))
	assert_eq(m.remaining_points(), 0, "les deux points sont dépensés")
	assert_false(m.can_invest(arch, "branch_spell"), "et plus rien n'entre nulle part")
	assert_false(m.can_invest(arch, "guard"))


func test_an_unknown_id_accepts_nothing() -> void:
	var arch := _trial_book()
	var m := _manual(6)
	assert_false(m.invest(arch, "spell_that_does_not_exist"))
	assert_false(m.invest(null, "spell"))
	assert_eq(m.points_spent(), 0)


# --------------------------------------------------------------------------
# Reprendre
# --------------------------------------------------------------------------

func test_refund_returns_the_point_to_the_book() -> void:
	var arch := _trial_book()
	var m := _manual(4)
	assert_true(m.invest(arch, "spell"))
	assert_true(m.invest(arch, "branch_spell"))
	var remaining_all := m.remaining_points()

	assert_true(m.refund(arch, "branch_spell"))
	assert_eq(m.points_of("branch_spell"), 0)
	assert_eq(m.remaining_points(), remaining_all + 1, "le point revient")
	assert_false(m.points.has("branch_spell"), "et l'entrée vide disparaît")
	assert_true(m.invest(arch, "guard"), "il se replace ailleurs dans le même livre")


## Depuis le 14 septembre 2026, sur demande : une case et un passif se reprennent
## aussi, et le point revient au livre.
func test_a_slot_and_a_passive_can_be_refunded() -> void:
	var arch := _trial_book()
	var m := _manual(6)
	assert_true(m.invest(arch, "spell"))
	assert_true(m.invest(arch, "guard"))
	var remaining_all := m.remaining_points()
	assert_true(m.refund(arch, "spell"))
	assert_true(m.refund(arch, "guard"))
	assert_eq(m.points_of("spell"), 0)
	assert_eq(m.points_of("guard"), 0)
	assert_eq(m.remaining_points(), remaining_all + 2, "les deux points reviennent")


## Une compétence ne descend pas sous ce que demande un de ses nœuds investis : le
## nœud garderait des points qu'on ne pourrait plus y placer.
func test_a_skill_does_not_go_below_its_nodes() -> void:
	var arch := _trial_book()
	var m := _manual(10)
	for id in ["spell", "spell", "branch_spell", "leaf_spell"]:
		assert_true(m.invest(arch, id), "« %s »" % id)
	assert_false(m.can_refund(arch, "spell"), "la feuille demande deux points")
	assert_true(m.refund(arch, "leaf_spell"))
	assert_true(m.refund(arch, "spell"), "la branche n'en demande qu'un")
	assert_false(m.refund(arch, "spell"), "et elle porte encore le sien")
	assert_true(m.refund(arch, "branch_spell"))
	assert_true(m.refund(arch, "spell"), "arbre vide, la compétence se vide")


## Reprendre sous un enfant qui porte des points laisserait la branche accrochée
## à un nœud éteint, et le lien dessiné ne voudrait plus rien dire.
func test_cannot_refund_under_an_invested_child() -> void:
	var arch := _trial_book()
	var m := _manual(10)
	for id in ["spell", "spell", "branch_spell", "leaf_spell"]:
		assert_true(m.invest(arch, id), "« %s »" % id)

	assert_false(m.can_refund(arch, "branch_spell"), "la feuille en dépend")
	assert_true(m.refund(arch, "leaf_spell"), "la feuille, elle, se reprend")
	assert_true(m.refund(arch, "branch_spell"), "et la branche ensuite")


func test_cannot_refund_what_has_no_point() -> void:
	var arch := _trial_book()
	var m := _manual(4)
	assert_false(m.refund(arch, "branch_spell"), "rien n'y est placé")
	assert_false(m.refund(arch, "unknown"))
	assert_false(m.refund(null, "branch_spell"))


# --------------------------------------------------------------------------
# Ce que le manuel rend au lancer
# --------------------------------------------------------------------------

func test_only_invested_nodes_count() -> void:
	var arch := _trial_book()
	var m := _manual(10)
	assert_eq(m.invested_talents(arch, "spell").size(), 0, "un livre neuf n'a aucun talent")

	for id in ["spell", "spell", "branch_spell", "branch_spell"]:
		m.invest(arch, id)
	var talents := m.invested_talents(arch, "spell")
	assert_eq(talents.size(), 1, "le seul nœud investi")
	assert_eq(talents[0].node.id, "branch_spell")
	assert_eq(talents[0].points, 2, "avec ses deux points")
	assert_eq(m.invested_talents(arch, "guard").size(), 0, "un passif n'a pas d'arbre")


func test_a_passive_lines_follow_its_points() -> void:
	var arch := _trial_book()
	var m := _manual(8)
	assert_eq(m.passive_mods(arch).size(), 0, "zéro point, aucune ligne")

	m.invest(arch, "guard")
	m.invest(arch, "guard")
	var mods := m.passive_mods(arch)
	assert_eq(mods.size(), 1)
	assert_eq(mods[0].stat, "armor")
	assert_eq(mods[0].value, 20.0, "deux points à dix")


func test_a_talent_line_reads_like_an_item_line() -> void:
	assert_null(_line("armor", 10.0).modifier(0), "zéro point ne donne aucune ligne")
	assert_eq(_line("armor", 10.0).modifier(2).label(), "+20 armure")
	assert_eq(_line("damage", 12.0, true).modifier(2).label(), "+24 % dégâts")
	var more := _line("damage", 12.0, true)
	more.more = true
	assert_eq(more.modifier(2).label(), "24 % de dégâts en plus")
	assert_eq(more.modifier(2).readable_value(), "24 % en plus", "la valeur seule, sur la page du manuel")
	assert_eq(
		_line("damage_fire", 4.0, false, "", 9.0).modifier(2).label(),
		"ajoute 8 à 18 dégâts de feu",
		"une fourchette monte par ses deux bornes, et sans portée elle ne nomme personne"
	)
	assert_eq(
		_line("damage_fire", 4.0, false, Keywords.SPELL, 9.0).modifier(1).label(),
		"ajoute 4 à 9 dégâts de feu aux sorts", "celle d'un passif dit sa famille"
	)


# --------------------------------------------------------------------------
# Ce qu'un nœud change au lancer
# --------------------------------------------------------------------------

func _spell(base: float) -> Skill:
	var c := _skill("spell", [base] as Array[float])
	c.declared_keywords = PackedStringArray([Keywords.PROJECTILE])
	c.projectile_speed = 200.0
	return c


func test_a_node_adds_damage_and_projectiles() -> void:
	var c := _spell(100.0)
	var n := _node("n", [
		_line("damage", 25.0, true), _line("projectiles", 1.0)
	] as Array[TalentLine])
	var r := c.resolve(1, _sheet(), [], _talents([n]))
	assert_almost_eq(r.total_min(), 125.0, 1e-4)
	assert_eq(r.projectile_count(), 2)
	assert_almost_eq(r.increased, 1.25, 1e-6, "et la fiche sait le dire")


## Le « plus » d'un nœud multiplie **après** la somme des accrus des objets : deux
## sources qui se multiplient entre elles, pas une de plus dans le même total.
func test_a_more_node_multiplies_the_sum_of_increased() -> void:
	var c := _spell(100.0)
	var line := _line("damage", 25.0, true)
	line.more = true
	var r := c.resolve(1, _sheet(), [
		StatMod.new("damage", StatMod.Mode.PERCENT, 50.0, Keywords.SPELL),
		StatMod.new("damage", StatMod.Mode.PERCENT, 10.0, Keywords.PROJECTILE),
	], _talents([_node("n", [line] as Array[TalentLine])]))
	assert_almost_eq(r.increased, 1.60, 1e-6)
	assert_almost_eq(r.more, 1.25, 1e-6)
	assert_almost_eq(r.total_min(), 200.0, 1e-4, "100 × 1,60 × 1,25")


## **Un nœud ne vise que sa compétence** : ses lignes n'ont pas de portée, et
## c'est tout ce qui les distingue de celles d'un objet. Un coup d'arc qui ne
## porte ni `projectile` ni `lightning` reçoit quand même les siennes.
func test_a_node_acts_without_keyword() -> void:
	var sword := _skill("sword", [10.0] as Array[float], DamageType.Kind.PHYSICAL)
	sword.cadence = Skill.Cadence.WEAPON
	var n := _node("n", [_line("damage", 50.0, true)] as Array[TalentLine])
	assert_almost_eq(sword.resolve(1, _sheet(), [], _talents([n])).total_min(), 15.0, 1e-4)


func test_a_node_adds_a_range_in_its_nature() -> void:
	var c := _spell(100.0)
	var n := _node("n", [_line("damage_fire", 4.0, false, "", 9.0)] as Array[TalentLine])
	var r := c.resolve(1, _sheet(), [], _talents([n], 2))
	assert_eq(r.added_min[DamageType.Kind.FIRE], 8.0, "deux points de 4 à 9")
	assert_eq(r.added_max[DamageType.Kind.FIRE], 18.0)
	assert_eq(r.total_max(), 118.0)


func test_a_node_can_cost_damage() -> void:
	var c := _spell(100.0)
	var n := _node("n", [
		_line("damage", -25.0, true), _line("projectiles", 2.0)
	] as Array[TalentLine])
	var r := c.resolve(1, _sheet(), [], _talents([n]))
	assert_almost_eq(r.total_min(), 75.0, 1e-4, "l'échange est le seul point qui fait baisser")
	assert_eq(r.projectile_count(), 3)
	assert_eq(
		r.spread_in_degrees, SkillStats.MIN_SPREAD * 2.0,
		"et trois traits ne partent pas l'un sur l'autre"
	)


# --------------------------------------------------------------------------
# La conversion
# --------------------------------------------------------------------------

func _conversion(id: String, toward: DamageType.Kind, part: float, lines: Array[TalentLine] = []) -> TalentNode:
	var n := _node(id, lines)
	n.converts_to = toward
	n.converted_part_per_point = part
	return n


func test_a_node_converts_a_share_of_damage() -> void:
	var r := _spell(100.0).resolve(
		1, _sheet(), [], _talents([_conversion("n", DamageType.Kind.COLD, 0.5)])
	)
	assert_almost_eq(r.damage_min[DamageType.Kind.LIGHTNING], 50.0, 1e-4, "la moitié reste")
	assert_almost_eq(r.damage_min[DamageType.Kind.COLD], 50.0, 1e-4, "l'autre part")
	assert_almost_eq(r.total_min(), 100.0, 1e-4, "et rien ne se perd en route")
	assert_almost_eq(r.conversions[DamageType.Kind.COLD], 0.5, 1e-4, "la fiche sait le dire")


## Convertie **après** les ajouts : la foudre qu'un anneau ajoute à un sort de
## foudre part avec le reste. Convertie avant, le même objet donnerait deux
## résultats selon l'ordre dans lequel ses lignes arrivent.
func test_conversion_carries_what_an_item_adds() -> void:
	var addition := StatMod.ranged(
		SkillStats.added_stat(DamageType.Kind.LIGHTNING), 20.0, 20.0, Keywords.SPELL
	)
	var r := _spell(100.0).resolve(
		1, _sheet(), [addition], _talents([_conversion("n", DamageType.Kind.FIRE, 1.0)])
	)
	assert_almost_eq(r.damage_min[DamageType.Kind.LIGHTNING], 0.0, 1e-4, "plus rien de foudre")
	assert_almost_eq(r.damage_min[DamageType.Kind.FIRE], 120.0, 1e-4, "les cent vingt sont du feu")


## Un ajout de chaque nature : la conversion prend sa part de toutes. À moitié, chacune
## garde la moitié de ce qu'elle portait ; entière, il ne reste que la nature d'arrivée.
func test_conversion_carries_additions_of_every_nature() -> void:
	var additions: Array[StatMod] = []
	for nature in DamageType.Kind.size():
		additions.append(StatMod.ranged(
			SkillStats.added_stat(nature as DamageType.Kind), 10.0, 10.0, Keywords.SPELL
		))
	var cold := DamageType.Kind.COLD

	# 110 de foudre, 10 de froid, 10 de chacune des quatre autres : 160.
	var half := _spell(100.0).resolve(1, _sheet(), additions, _talents([_conversion("n", cold, 0.5)]))
	assert_almost_eq(half.damage_min[DamageType.Kind.LIGHTNING], 55.0, 1e-4, "la base et son ajout, à moitié")
	for nature in [DamageType.Kind.PHYSICAL, DamageType.Kind.FIRE, DamageType.Kind.NECROTIC, DamageType.Kind.HOLY]:
		assert_almost_eq(half.damage_min[nature], 5.0, 1e-4, "%s : son ajout, à moitié" % DamageType.NAMES[nature])
	assert_almost_eq(half.damage_min[cold], 85.0, 1e-4, "son ajout et la moitié de tout le reste")
	assert_almost_eq(half.total_min(), 160.0, 1e-4)

	var whole := _spell(100.0).resolve(1, _sheet(), additions, _talents([_conversion("n", cold, 1.0)]))
	for nature in DamageType.Kind.size():
		if nature != cold:
			assert_eq(whole.damage_min[nature], 0.0, "%s : plus rien" % DamageType.NAMES[nature])
	assert_almost_eq(whole.damage_min[cold], 160.0, 1e-4)
	assert_almost_eq(whole.conversions[cold], 1.0, 1e-4)


## Deux conversions vers deux natures : la seconde, entière, emporte aussi ce que la
## première avait converti.
func test_a_full_conversion_carries_the_previous_one() -> void:
	var nodes := [
		_conversion("a", DamageType.Kind.COLD, 0.5), _conversion("b", DamageType.Kind.FIRE, 1.0)
	]
	var r := _spell(100.0).resolve(1, _sheet(), [], _talents(nodes))
	assert_almost_eq(r.damage_min[DamageType.Kind.FIRE], 100.0, 1e-4)
	assert_eq(r.damage_min[DamageType.Kind.COLD], 0.0)
	assert_eq(r.conversions[DamageType.Kind.COLD], 0.0, "la fiche n'annonce plus de froid")
	assert_almost_eq(r.conversions[DamageType.Kind.FIRE], 1.0, 1e-4)


func test_two_conversions_take_their_share_of_what_remains() -> void:
	var nodes := [
		_conversion("a", DamageType.Kind.FIRE, 0.5), _conversion("b", DamageType.Kind.FIRE, 0.5)
	]
	var r := _spell(100.0).resolve(1, _sheet(), [], _talents(nodes))
	assert_almost_eq(r.damage_min[DamageType.Kind.FIRE], 75.0, 1e-4, "deux fois la moitié")
	assert_almost_eq(r.damage_min[DamageType.Kind.LIGHTNING], 25.0, 1e-4)
	assert_almost_eq(
		r.conversions[DamageType.Kind.FIRE], 0.75, 1e-4, "et la fiche annonce 75 %, pas 100 %"
	)


func test_a_conversion_never_exceeds_the_whole() -> void:
	var r := _spell(100.0).resolve(
		1, _sheet(), [], _talents([_conversion("n", DamageType.Kind.FIRE, 0.8)], 3)
	)
	assert_almost_eq(r.damage_min[DamageType.Kind.FIRE], 100.0, 1e-4, "trois points à 80 %")
	assert_almost_eq(r.total_min(), 100.0, 1e-4)


## Le multiplicateur passe sur les deux natures : converti avant ou après, le
## total est le même — et c'est ce qui laisse l'ordre libre.
func test_conversion_and_multipliers_commute() -> void:
	var r := _spell(100.0).resolve(
		1, _sheet(), [StatMod.new("damage", StatMod.Mode.PERCENT, 20.0, Keywords.SPELL)],
		_talents([_conversion("n", DamageType.Kind.FIRE, 0.5)])
	)
	assert_almost_eq(r.total_min(), 120.0, 1e-4, "100 × 1,2")
	assert_almost_eq(r.damage_min[DamageType.Kind.FIRE], 60.0, 1e-4, "moitié-moitié")
	assert_almost_eq(r.damage_min[DamageType.Kind.LIGHTNING], 60.0, 1e-4)


# --------------------------------------------------------------------------
# Les mots-clés qu'un nœud donne
# --------------------------------------------------------------------------

## Le nœud le plus cher de son arbre : il ne convertit pas seulement les dégâts,
## il fait mordre l'équipement de la nature d'arrivée.
func test_a_node_can_give_the_keyword_of_its_target_nature() -> void:
	var ardent := StatMod.new("damage", StatMod.Mode.PERCENT, 50.0, Keywords.FIRE)
	var c := _spell(100.0)
	assert_almost_eq(
		c.resolve(1, _sheet(), [ardent]).total_min(), 100.0, 1e-4,
		"sans le nœud, un affixe de feu ne mord pas sur un sort de foudre"
	)

	var n := _conversion("n", DamageType.Kind.FIRE, 1.0)
	n.added_keywords = PackedStringArray([Keywords.FIRE])
	var r := c.resolve(1, _sheet(), [ardent], _talents([n]))
	assert_almost_eq(r.total_min(), 150.0, 1e-4, "avec lui, oui")
	assert_true(r.keywords.has(Keywords.FIRE), "et la fiche l'affiche")
	assert_true(r.keywords.has(Keywords.LIGHTNING), "sans perdre celui de la compétence")


## L'ordre est celui de la liste fermée, pas celui de la source : deux compétences
## voisines doivent se lire colonne contre colonne.
func test_resolved_keywords_keep_reading_order() -> void:
	var n := _conversion("n", DamageType.Kind.FIRE, 1.0)
	n.added_keywords = PackedStringArray([Keywords.FIRE])
	var r := _spell(100.0).resolve(1, _sheet(), [], _talents([n]))
	assert_eq(
		Array(r.keywords), [Keywords.PROJECTILE, Keywords.LIGHTNING, Keywords.FIRE, Keywords.SPELL]
	)
	assert_eq(r.keywords_label(), "Projectile · Foudre · Feu · Sort")


## Sans talent, la liste est exactement celle de la compétence. C'est le pendant
## de `test_without_modifier_resolution_returns_the_sheet` : ce jalon ne doit rien
## changer à ce qui se jouait avant lui.
func test_without_talent_keywords_are_those_of_the_skill() -> void:
	for c: Skill in SkillCatalog.ALL:
		var r := c.resolve(c.points_max(), CharacterStats.new())
		assert_eq(Array(r.keywords), Array(c.keywords()), "« %s »" % c.name)
		assert_eq(r.keywords_label(), c.keywords_label())
		for part in r.conversions:
			assert_eq(part, 0.0, "« %s » : rien n'est converti" % c.name)


# --------------------------------------------------------------------------
# Le contenu du jeu
# --------------------------------------------------------------------------

## Les archétypes du catalogue, avec leur base pour que l'échec nomme le livre.
func _books() -> Array[ItemBase]:
	var out: Array[ItemBase] = []
	for base: ItemBase in ItemCatalog.ALL:
		if base.manual != null:
			out.append(base)
	return out


## Une case qui porte les deux aurait deux compteurs pour un seul identifiant ;
## une case qui ne porte rien est un trou sur la page, et seulement là.
func test_each_slot_holds_one_thing_only() -> void:
	for base in _books():
		for c in base.manual.cells:
			var worn := int(c.skill != null) + int(c.passive != null)
			assert_eq(
				worn, 1,
				"« %s » : une case porte %d chose(s)" % [base.manual.name, worn]
			)
			if c.passive != null:
				assert_eq(
					c.talents.size(), 0,
					"« %s » : un passif n'a pas d'arbre à orienter" % c.passive.name
				)


## **Le piège qui ne se voit pas** : cases, passifs et nœuds partagent le
## dictionnaire de points du manuel. Deux identifiants égaux, et le point placé
## dans l'un s'affiche sur l'autre.
func test_a_book_ids_are_unique() -> void:
	for base in _books():
		var seen_all := {}
		for c in base.manual.cells:
			for id in [c.identifier()] + c.talents.map(func(n: TalentNode) -> String: return n.id):
				assert_false(
					seen_all.has(id), "« %s » : « %s » est écrit deux fois" % [base.manual.name, id]
				)
				assert_false(String(id).is_empty(), "« %s » : un identifiant vide" % base.manual.name)
				seen_all[id] = true


func test_each_node_has_a_name_and_effects() -> void:
	for base in _books():
		for c in base.manual.cells:
			for n in c.talents:
				assert_false(n.name.is_empty(), "« %s » n'a pas de nom lisible" % n.id)
				assert_true(
					n.lines.size() > 0 or n.converts(),
					"« %s » ne fait rien du tout" % n.id
				)
				assert_gte(n.points_max, 1, "« %s » n'accepte aucun point" % n.id)


## Un nœud dont le parent n'est pas dans le même arbre ne s'ouvrirait jamais, et
## rien à l'écran ne dirait pourquoi.
func test_each_parent_exists_in_the_same_tree() -> void:
	for base in _books():
		for c in base.manual.cells:
			for n in c.talents:
				if n.parent.is_empty():
					continue
				assert_ne(n.parent, n.id, "« %s » est son propre parent" % n.id)
				assert_not_null(
					c.node_of(n.parent),
					"« %s » dépend de « %s », qui n'est pas dans son arbre" % [n.id, n.parent]
				)


## Un arbre dont tous les nœuds ont un parent est un arbre fermé : rien n'y
## accroche le premier point.
func test_each_tree_has_a_root_and_stays_reachable() -> void:
	for base in _books():
		for c in base.manual.cells:
			if c.talents.is_empty():
				continue
			var roots := 0
			for n in c.talents:
				if n.parent.is_empty():
					roots += 1
				assert_between(
					n.required_points, 1, c.points_max(),
					"« %s » demande %d points dans une case qui en accepte %d"
						% [n.id, n.required_points, c.points_max()]
				)
			assert_gt(roots, 0, "« %s » : aucun nœud ne part de la compétence" % c.identifier())


## La faute de frappe silencieuse, celle des affixes : une ligne qui vise un
## champ inexistant ne casse rien, le point placé ne fait simplement rien.
func test_each_node_line_targets_a_cast_number() -> void:
	for base in _books():
		for c in base.manual.cells:
			for n in c.talents:
				for l in n.lines:
					assert_true(
						l.scope.is_empty(),
						"« %s » : un nœud ne vise que sa compétence" % n.id
					)
					assert_true(
						SkillStats.modifiable(l.stat),
						"« %s » vise « %s », qui n'est pas un nombre de lancer" % [n.id, l.stat]
					)


func test_each_passive_line_targets_the_sheet_or_a_keyword() -> void:
	var sheet := CharacterStats.new()
	for base in _books():
		for passive in base.manual.passives():
			assert_false(passive.name.is_empty(), "« %s » n'a pas de nom lisible" % passive.id)
			assert_gt(passive.lines.size(), 0, "« %s » ne donne rien" % passive.id)
			assert_gte(passive.points_max, 1, "« %s » n'accepte aucun point" % passive.id)
			for l in passive.lines:
				if l.scope.is_empty():
					assert_true(
						sheet.get(l.stat) != null and StatMod.LABELS.has(l.stat),
						"« %s » vise « %s », qui n'est pas sur la fiche" % [passive.id, l.stat]
					)
					continue
				assert_true(
					Keywords.exists(l.scope),
					"« %s » vise le mot-clé « %s », hors de la liste" % [passive.id, l.scope]
				)
				assert_true(
					SkillStats.modifiable(l.stat),
					"« %s » vise « %s » sur un mot-clé" % [passive.id, l.stat]
				)


## `projectile`, `attack` et `spell` décident du chemin que prend le lancer : un
## nœud qui les donnerait ferait partir un tir d'une compétence dont la fiche
## annonce un coup d'arc.
func test_a_node_gives_only_one_nature_keyword() -> void:
	var natures := Skill.KEYWORD_OF_NATURE.values()
	for base in _books():
		for c in base.manual.cells:
			for n in c.talents:
				for id in n.added_keywords:
					assert_true(
						natures.has(id),
						"« %s » donne « %s », qui n'est pas un mot-clé de nature" % [n.id, id]
					)


func test_each_conversion_targets_another_nature() -> void:
	for base in _books():
		for c in base.manual.cells:
			for n in c.talents:
				if not n.converts():
					continue
				assert_between(
					n.converted_part_per_point, 0.01, 1.0,
					"« %s » convertit une part hors des bornes" % n.id
				)
				assert_ne(
					int(n.converts_to), int(c.skill.nature),
					"« %s » convertit vers la nature qu'elle a déjà" % n.id
				)


## **Un manuel ne se remplit plus** (jalon 10) : c'est ce qui fait du livre un
## choix et non une collection à compléter, et c'est la décision qu'un contenu
## ajouté sans y penser déferait.
func test_no_manual_fills_up_entirely() -> void:
	for base in _books():
		var destinations := 0
		for c in base.manual.cells:
			destinations += c.points_max()
			for n in c.talents:
				destinations += n.points_max
		assert_gt(
			destinations, Manual.MAX_LEVEL,
			"« %s » offre %d points de destination pour %d gagnés"
				% [base.manual.name, destinations, Manual.MAX_LEVEL]
		)
