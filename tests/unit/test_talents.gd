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


func _node(id: String, lines: Array[TalentLine], maximum := 1, parents: Dictionary[String, int] = {}) -> TalentNode:
	var n := TalentNode.new()
	n.id = id
	n.name = id
	n.lines = lines
	n.points_max = maximum
	n.parents = parents
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


## Le livre des règles : une compétence à cinq points et son arbre — une branche et un
## côté reliés au sort, une feuille reliée aux deux, qui demande deux points dans l'un —,
## et un passif.
func _trial_book() -> ManualArchetype:
	var spell := _skill("spell", [10.0, 20.0, 30.0, 40.0, 50.0] as Array[float])
	var branch := _node("branch_spell", [_line("damage", 10.0, true)] as Array[TalentLine], 3)
	var side := _node("side_spell", [_line("radius", 10.0, true)] as Array[TalentLine], 2)
	var leaf := _node(
		"leaf_spell", [_line("projectiles", 1.0)] as Array[TalentLine], 1,
		{"branch_spell": 2, "side_spell": 2} as Dictionary[String, int]
	)
	return _archetype([
		_cell(spell, [branch, side, leaf] as Array[TalentNode]),
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
	for id in ["spell", "guard", "branch_spell", "side_spell", "leaf_spell"]:
		assert_true(arch.knows(id), "« %s » est de ce livre" % id)
	assert_false(arch.knows("swift_bolt"), "une compétence d'un autre livre, non")
	assert_false(arch.knows(""), "ni rien du tout")


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


## Un lien demande ses points dans le parent, pas un seul (jalon 34, les « ••• » de
## Last Epoch).
func test_a_link_asks_for_its_points() -> void:
	var arch := _trial_book()
	var m := _manual(8)
	assert_true(m.invest(arch, "spell"))
	assert_true(m.invest(arch, "branch_spell"))
	assert_false(m.can_invest(arch, "leaf_spell"), "un point sur les deux demandés")
	assert_true(m.invest(arch, "branch_spell"))
	assert_true(m.invest(arch, "leaf_spell"), "le lien est payé")


## **Un seul lien suffit** : c'est ce qui fait un réseau plutôt que des couloirs.
func test_any_link_opens_a_node() -> void:
	var arch := _trial_book()
	var m := _manual(8)
	assert_true(m.invest(arch, "spell"))
	for i in 2:
		assert_true(m.invest(arch, "side_spell"))
	assert_true(m.invest(arch, "leaf_spell"), "par le côté, la branche vide")


func test_a_node_does_not_exceed_its_maximum() -> void:
	var arch := _trial_book()
	var m := _manual(12)
	assert_true(m.invest(arch, "spell"))
	for i in 3:
		assert_true(m.invest(arch, "branch_spell"), "les trois points de la branche")
	assert_false(m.invest(arch, "branch_spell"), "et pas un de plus")


## Chaque arbre a son pool, un point par niveau du livre (jalon 34) : le livre dit
## quels sorts, l'arbre comment ils se jouent.
func test_a_node_is_paid_from_its_own_tree() -> void:
	var arch := _trial_book()
	var cell := arch.cell_of("spell")
	var m := _manual(2)
	assert_true(m.invest(arch, "spell"))
	assert_true(m.invest(arch, "branch_spell"))
	assert_true(m.invest(arch, "branch_spell"))
	assert_eq(m.remaining_points(arch), 1, "le livre n'a payé que la case")
	assert_eq(m.tree_remaining(cell), 0, "l'arbre a payé ses deux nœuds")
	assert_false(m.can_invest(arch, "side_spell"), "et il est vide")
	assert_true(m.invest(arch, "guard"), "le livre, lui, paie encore")


func test_an_unknown_id_accepts_nothing() -> void:
	var arch := _trial_book()
	var m := _manual(6)
	assert_false(m.invest(arch, "spell_that_does_not_exist"))
	assert_false(m.invest(null, "spell"))
	assert_eq(m.points_spent(arch), 0)


# --------------------------------------------------------------------------
# Reprendre
# --------------------------------------------------------------------------

func test_refund_returns_the_point_to_its_tree() -> void:
	var arch := _trial_book()
	var cell := arch.cell_of("spell")
	var m := _manual(4)
	assert_true(m.invest(arch, "spell"))
	assert_true(m.invest(arch, "branch_spell"))
	var remaining_all := m.tree_remaining(cell)

	assert_true(m.refund(arch, "branch_spell"))
	assert_eq(m.points_of("branch_spell"), 0)
	assert_eq(m.tree_remaining(cell), remaining_all + 1, "le point revient")
	assert_false(m.points.has("branch_spell"), "et l'entrée vide disparaît")
	assert_true(m.invest(arch, "side_spell"), "il se replace ailleurs dans l'arbre")


## Depuis le 14 septembre 2026, sur demande : une case et un passif se reprennent
## aussi, et le point revient au livre.
func test_a_slot_and_a_passive_can_be_refunded() -> void:
	var arch := _trial_book()
	var m := _manual(6)
	assert_true(m.invest(arch, "spell"))
	assert_true(m.invest(arch, "guard"))
	var remaining_all := m.remaining_points(arch)
	assert_true(m.refund(arch, "spell"))
	assert_true(m.refund(arch, "guard"))
	assert_eq(m.points_of("spell"), 0)
	assert_eq(m.points_of("guard"), 0)
	assert_eq(m.remaining_points(arch), remaining_all + 2, "les deux points reviennent")


## Une compétence garde un point tant que son arbre en porte : c'est lui qui l'ouvre.
func test_a_skill_keeps_a_point_under_its_tree() -> void:
	var arch := _trial_book()
	var m := _manual(10)
	for id in ["spell", "spell", "branch_spell"]:
		assert_true(m.invest(arch, id), "« %s »" % id)
	assert_true(m.refund(arch, "spell"), "de deux à un")
	assert_false(m.can_refund(arch, "spell"), "l'arbre en dépend")
	assert_true(m.refund(arch, "branch_spell"))
	assert_true(m.refund(arch, "spell"), "arbre vide, la compétence se vide")


## Un lien peut se défaire tant qu'un autre tient le nœud ; le dernier, non.
func test_the_last_link_holding_a_node_stays() -> void:
	var arch := _trial_book()
	var m := _manual(10)
	for id in ["spell", "branch_spell", "branch_spell", "side_spell", "side_spell", "leaf_spell"]:
		assert_true(m.invest(arch, id), "« %s »" % id)
	assert_true(m.refund(arch, "branch_spell"), "le côté tient encore la feuille")
	assert_false(m.can_refund(arch, "side_spell"), "plus rien ne la tiendrait")
	assert_true(m.refund(arch, "leaf_spell"))
	assert_true(m.refund(arch, "side_spell"))


## La relecture rend l'arbre entier quand il ne tient plus — pool dépassé ou nœud
## coupé de ses liens —, et ne touche ni à la case ni au passif.
func test_a_broken_tree_is_released_whole() -> void:
	var arch := _trial_book()
	var m := _manual(2)
	m.points = {"spell": 1, "guard": 1, "branch_spell": 3}
	m.release_broken_trees(arch)
	assert_eq(m.points, {"spell": 1, "guard": 1}, "trois points pour un pool de deux")

	m = _manual(10)
	m.points = {"spell": 1, "branch_spell": 1, "leaf_spell": 1}
	m.release_broken_trees(arch)
	assert_eq(m.points, {"spell": 1}, "un point sur un lien qui en demande deux")

	m.points = {"spell": 1, "branch_spell": 2, "leaf_spell": 1}
	m.release_broken_trees(arch)
	assert_eq(m.points_of("leaf_spell"), 1, "un arbre qui tient reste")


## Reprendre sous un enfant qui porte des points laisserait la branche accrochée
## à un nœud éteint, et le lien dessiné ne voudrait plus rien dire.
func test_cannot_refund_under_an_invested_child() -> void:
	var arch := _trial_book()
	var m := _manual(10)
	for id in ["spell", "branch_spell", "branch_spell", "branch_spell", "side_spell", "leaf_spell"]:
		assert_true(m.invest(arch, id), "« %s »" % id)

	assert_true(m.refund(arch, "branch_spell"), "trois points pour un lien de deux")
	assert_false(m.can_refund(arch, "branch_spell"), "la feuille en dépend")
	assert_true(m.refund(arch, "leaf_spell"), "la feuille, elle, se reprend")
	assert_true(m.refund(arch, "branch_spell"), "et la branche ensuite")


## Un lien se prend dans les deux sens (jalon 39), comme la Vague : le Ressac, ouvert par
## la Course, ouvre les Vagues jumelles qui l'ouvrent aussi. Mais l'un ne tient pas
## l'autre : sans la Course, aucun des deux n'est relié à la compétence.
func test_a_link_is_taken_both_ways_without_holding_itself() -> void:
	var spell := _skill("spell", [10.0, 20.0, 30.0, 40.0, 50.0] as Array[float])
	var edge := _node("edge", [_line("damage", 10.0, true)] as Array[TalentLine], 5)
	var reach := _node("reach", [_line("duration", 10.0, true)] as Array[TalentLine], 4)
	var twins := _node(
		"twins", [_line("radius", 10.0, true)] as Array[TalentLine], 3,
		{"edge": 2} as Dictionary[String, int]
	)
	var backwash := _node(
		"backwash", [_line("period", -10.0, true)] as Array[TalentLine], 1,
		{"reach": 2, "twins": 1} as Dictionary[String, int]
	)
	var arch := _archetype([
		_cell(spell, [edge, reach, twins, backwash] as Array[TalentNode]),
	] as Array[ManualCell])
	var m := _manual(10)
	for id in ["spell", "reach", "reach", "backwash"]:
		assert_true(m.invest(arch, id), "« %s »" % id)
	assert_true(m.is_open(arch, "twins"), "par l'enfant, sans passer par edge")
	assert_true(m.invest(arch, "twins"))
	assert_false(m.can_refund(arch, "reach"), "le Ressac et les Vagues ne se tiennent pas l'un l'autre")
	assert_true(m.invest(arch, "edge"))
	assert_true(m.invest(arch, "edge"))
	assert_true(m.refund(arch, "reach"), "Edge tient désormais les Vagues, qui tiennent le Ressac")


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


## 2 s au premier point, 5 s au troisième : la ligne donne 1,5 par point et 0,5 au premier.
func test_a_first_point_bonus_counts_once() -> void:
	var line := _line(SkillStats.GROUND, 1.5)
	line.first_point_bonus = 0.5
	assert_null(line.modifier(0), "zéro point, rien")
	assert_eq(line.modifier(1).value, 2.0)
	assert_eq(line.modifier(2).value, 3.5)
	assert_eq(line.modifier(3).value, 5.0)


func test_a_talent_line_reads_like_an_item_line() -> void:
	assert_null(_line("armor", 10.0).modifier(0), "zéro point ne donne aucune ligne")
	assert_eq(_line("armor", 10.0).modifier(2).label(), "+20 armure")
	assert_eq(Glossary.plain(_line("damage", 12.0, true).modifier(2).label()), "+24 % de dégâts accrus")
	var more := _line("damage", 12.0, true)
	more.more = true
	assert_eq(Glossary.plain(more.modifier(2).label()), "+24 % de dégâts amplifiés")
	assert_eq(
		Glossary.plain(more.modifier(2).readable_value()), "+24 % amplifiés",
		"la valeur seule, sur la page du manuel"
	)
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
## Les nombres de mécanique (jalon 34) sont des nombres de lancer comme les autres : un
## nœud les allume, zéro sans lui.
func test_a_node_lights_the_mechanic_numbers() -> void:
	var spell := _skill("spell", [10.0] as Array[float])
	var bare := spell.resolve(1, _sheet())
	for field in [SkillStats.PIERCE, SkillStats.SPLITS, SkillStats.GROUND, SkillStats.KILL_BURST]:
		assert_eq(bare.get(field), 0.0, "« %s » éteint sans nœud" % field)
	var node := _node("mech", [
		_line(SkillStats.PIERCE, 2.0), _line(SkillStats.GROUND, 1.5),
		_line("status_chance_increase", 30.0), _line("period", 100.0, true),
	] as Array[TalentLine])
	spell.period = 0.5
	var cast := spell.resolve(1, _sheet(), [], _talents([node]))
	assert_eq(cast.pierce, 2.0)
	assert_eq(cast.ground_duration, 1.5)
	assert_eq(cast.status_chance_increase, 30.0, "la chance d'état, hors de portée avant le jalon 34")
	assert_almost_eq(cast.period, 1.0, 1e-6, "l'intervalle des frappes, doublé")


func test_a_transforming_node_changes_the_shape_and_its_keywords() -> void:
	var spell := _skill("spell", [10.0] as Array[float])
	spell.shape = Skill.Shape.BOLT
	var node := _node("becomes", [] as Array[TalentLine])
	node.transforms = true
	node.shape = Skill.Shape.CROSS
	assert_eq(spell.resolve(1, _sheet()).shape, Skill.Shape.BOLT, "sans le nœud")
	var cast := spell.resolve(1, _sheet(), [], _talents([node]))
	assert_eq(cast.shape, Skill.Shape.CROSS)
	assert_eq(cast.hits, 2, "les coups de sa nouvelle forme")
	assert_false(cast.keywords.has(Keywords.PROJECTILE))
	assert_true(cast.keywords.has(Keywords.MELEE))
	assert_true(spell.keywords().has(Keywords.PROJECTILE), "la compétence, elle, reste un tir")


## Un lancer dérivé — sol, éclat — garde ce qui qualifie un coup et rien de ce qui en
## ferait naître un autre.
func test_a_derived_cast_keeps_the_blow_and_drops_the_mechanics() -> void:
	var spell := _skill("spell", [100.0] as Array[float], DamageType.Kind.FIRE)
	var node := _node("mech", [
		_line(SkillStats.SPLITS, 3.0), _line(SkillStats.GROUND, 2.0),
		_line(SkillStats.KILL_BURST, 20.0), _line("status_chance_increase", 30.0),
	] as Array[TalentLine])
	var cast := spell.resolve(1, _sheet(), [], _talents([node]))
	var ground := cast.ground()
	assert_almost_eq(ground.total_min(), cast.total_min() * SkillStats.GROUND_PART, 1e-4)
	assert_eq(ground.duration, 2.0, "la durée du sol")
	assert_eq(ground.keywords, cast.keywords)
	assert_eq(ground.status_chance_increase, 30.0)
	var shard := cast.shard()
	assert_almost_eq(shard.total_min(), cast.total_min() * SkillStats.SPLIT_PART, 1e-4)
	for derived: SkillStats in [ground, shard]:
		assert_eq(derived.splits, 0.0)
		assert_eq(derived.ground_duration, 0.0)
		assert_eq(derived.kill_burst, 0.0)


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

func _conversion(id: String, toward: DamageType.Kind, lines: Array[TalentLine] = []) -> TalentNode:
	var n := _node(id, lines)
	n.converts = true
	n.converts_to = toward
	return n


## **Tout ou rien** (jalon 34) : la compétence devient de la nature d'arrivée, ses
## dégâts propres entiers, et son mot-clé remplace l'ancien.
func test_a_conversion_changes_the_whole_nature_of_the_skill() -> void:
	var r := _spell(100.0).resolve(
		1, _sheet(), [], _talents([_conversion("n", DamageType.Kind.COLD)])
	)
	assert_eq(r.nature, DamageType.Kind.COLD)
	assert_almost_eq(r.damage_min[DamageType.Kind.COLD], 100.0, 1e-4)
	assert_eq(r.damage_min[DamageType.Kind.LIGHTNING], 0.0, "plus rien de foudre")
	assert_true(r.keywords.has(Keywords.COLD))
	assert_false(r.keywords.has(Keywords.LIGHTNING), "le mot-clé de départ tombe")


## Un sort converti est un sort de sa nouvelle nature, comme un autre : ce qu'un objet
## **ajoute** garde la sienne, et ce sont les affixes de la nature d'arrivée qui mordent.
func test_a_converted_skill_is_like_any_skill_of_its_new_nature() -> void:
	var addition := StatMod.ranged(
		SkillStats.added_stat(DamageType.Kind.LIGHTNING), 20.0, 20.0, Keywords.SPELL
	)
	var of_cold := StatMod.new("damage", StatMod.Mode.PERCENT, 50.0, Keywords.COLD)
	var of_lightning := StatMod.new("damage", StatMod.Mode.PERCENT, 50.0, Keywords.LIGHTNING)
	var r := _spell(100.0).resolve(
		1, _sheet(), [addition, of_cold, of_lightning],
		_talents([_conversion("n", DamageType.Kind.COLD)])
	)
	assert_almost_eq(r.damage_min[DamageType.Kind.COLD], 150.0, 1e-4, "l'affixe de froid mord")
	assert_almost_eq(
		r.damage_min[DamageType.Kind.LIGHTNING], 30.0, 1e-4,
		"l'ajout reste foudre, et l'affixe de foudre ne mord plus"
	)


## L'ordre est celui de la liste fermée, pas celui de la source : deux compétences
## voisines doivent se lire colonne contre colonne.
func test_resolved_keywords_keep_reading_order() -> void:
	var r := _spell(100.0).resolve(1, _sheet(), [], _talents([_conversion("n", DamageType.Kind.FIRE)]))
	assert_eq(Array(r.keywords), [Keywords.PROJECTILE, Keywords.FIRE, Keywords.SPELL])
	assert_eq(r.keywords_label(), "Projectile · Feu · Sort")


## Sans talent, la liste est exactement celle de la compétence. C'est le pendant
## de `test_without_modifier_resolution_returns_the_sheet` : ce jalon ne doit rien
## changer à ce qui se jouait avant lui.
func test_without_talent_keywords_are_those_of_the_skill() -> void:
	for c: Skill in SkillCatalog.ALL:
		var r := c.resolve(c.points_max(), CharacterStats.new())
		assert_eq(Array(r.keywords), Array(c.keywords()), "« %s »" % c.name)
		assert_eq(r.keywords_label(), c.keywords_label())
		assert_eq(r.nature, c.nature, "« %s » : rien n'est converti" % c.name)


# --------------------------------------------------------------------------
# Le contenu du jeu
# --------------------------------------------------------------------------

## Les archétypes du catalogue et des classes, avec leur base pour que l'échec nomme le
## livre.
func _books() -> Array[ItemBase]:
	var out: Array[ItemBase] = []
	for base: ItemBase in ItemCatalog.ALL + Character.class_manual_bases():
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
					n.lines.size() > 0 or n.converts,
					"« %s » ne fait rien du tout" % n.id
				)
				assert_gte(n.points_max, 1, "« %s » n'accepte aucun point" % n.id)


## Un lien vers un nœud hors de l'arbre, ou qui demande plus que le parent n'offre, ne
## s'ouvrirait jamais, et rien à l'écran ne dirait pourquoi.
func test_each_link_can_be_paid_in_the_same_tree() -> void:
	for base in _books():
		for c in base.manual.cells:
			for n in c.talents:
				for parent: String in n.parents:
					assert_ne(parent, n.id, "« %s » est relié à lui-même" % n.id)
					var from_value := c.node_of(parent)
					assert_not_null(from_value, "« %s » est relié à « %s », hors de son arbre" % [n.id, parent])
					if from_value != null:
						assert_between(
							n.parents[parent], 1, from_value.points_max,
							"« %s » demande %d points à « %s »" % [n.id, n.parents[parent], parent]
						)


## Tous les liens mènent à la compétence, **sans boucle** : deux nœuds reliés l'un à
## l'autre se tiendraient ouverts, et l'arbre se reprendrait sous eux.
func test_links_lead_to_the_root() -> void:
	for base in _books():
		for c in base.manual.cells:
			var placed := {}
			var progress := true
			while progress:
				progress = false
				for n in c.talents:
					if not placed.has(n.id) and n.parents.keys().all(func(p: String) -> bool: return placed.has(p)):
						placed[n.id] = true
						progress = true
			for n in c.talents:
				assert_true(placed.has(n.id), "« %s » : ses liens tournent en rond" % n.id)


## Une transformation ne quitte et ne rejoint que ce qui se pose et s'oublie
## (`Skill.TRANSFORMABLE`) : ce qui brûle, la couronne ou les morts-vivants tiennent un
## état chez le lanceur, qu'elle rendrait orphelin.
func test_each_transformation_stays_among_posed_shapes() -> void:
	for base in _books():
		for c in base.manual.cells:
			for n in c.talents:
				if not n.transforms:
					continue
				assert_has(Skill.TRANSFORMABLE, c.skill.shape, "« %s » quitte une forme qui tient" % n.id)
				assert_has(Skill.TRANSFORMABLE, n.shape, "« %s » rejoint une forme qui tient" % n.id)
				assert_ne(n.shape, c.skill.shape, "« %s » ne change rien" % n.id)


## La faute de frappe silencieuse, celle des affixes : une ligne qui vise un
## champ inexistant ne casse rien, le point placé ne fait simplement rien.
## Sur un buff (jalon 34), une ligne qui ne vise pas un nombre du lancer est une ligne
## de ce buff, aux règles d'un passif : un champ de la fiche, ou une portée.
func test_each_node_line_targets_a_cast_number() -> void:
	var sheet := CharacterStats.new()
	for base in _books():
		for c in base.manual.cells:
			var buff := c.skill != null and c.skill.grants_buffs()
			for n in c.talents:
				for l in n.lines:
					var cast_line := l.scope.is_empty() and SkillStats.modifiable(l.stat)
					var buff_line := buff and (
						(not l.scope.is_empty() and SkillStats.modifiable(l.stat))
						or (l.stat in sheet and StatMod.LABELS.has(l.stat))
					)
					assert_true(
						cast_line or buff_line,
						"« %s » vise « %s », ni nombre du lancer, ni ligne de buff" % [n.id, l.stat]
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
## Tout ou rien : un point suffit, et deux conversions dans un arbre se disputeraient la
## nature — la dernière l'emporterait sans que rien ne le dise.
func test_each_conversion_is_one_point_and_alone_in_its_tree() -> void:
	for base in _books():
		for c in base.manual.cells:
			var count := 0
			for n in c.talents:
				if not n.converts:
					continue
				count += 1
				assert_eq(n.points_max, 1, "« %s » : une conversion ne se prend qu'une fois" % n.id)
				assert_ne(
					int(n.converts_to), int(c.skill.nature),
					"« %s » convertit vers la nature qu'elle a déjà" % n.id
				)
			assert_lt(count, 2, "« %s » : deux conversions dans un arbre" % c.identifier())


## **Un manuel ne se remplit plus** (jalon 10) : c'est ce qui fait du livre un
## choix et non une collection à compléter, et c'est la décision qu'un contenu
## ajouté sans y penser déferait. Les manuels de classe en sont exemptés tant qu'ils
## n'ont qu'une compétence et un buff : le surplus est accepté (jalon 28, §1).
func test_no_manual_fills_up_entirely() -> void:
	for base in _books():
		if base in Character.class_manual_bases():
			continue
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


## La nécromancie (jalon 38), le chevalier (jalon 39) et le sacré (jalon 40) : **aucune
## ligne ni aucun nom ne revient d'un arbre à l'autre**. Aux jalons 35 et 36, Engelure, Froid mordant et Bris se payaient quatre fois.
## Seuls les leviers de base y échappent, un par arbre au plus.
const UNIQUE_TREES := ["manual_necrotic", "manual_weapons", "manual_holy"]
const BASE_LEVERS := ["damage", "radius", "duration"]


func test_unique_trees_share_no_line_and_no_name() -> void:
	for base in _books():
		if not base.id in UNIQUE_TREES:
			continue
		var line_owner := {}
		var name_owner := {}
		for c in base.manual.cells:
			var levers := {}
			for n in c.talents:
				assert_false(
					name_owner.has(n.name),
					"« %s » porte le nom de « %s »" % [n.id, name_owner.get(n.name, "")]
				)
				name_owner[n.name] = n.id
				for l in n.lines:
					var key := "%s@%s" % [l.stat, l.scope]
					if l.stat in BASE_LEVERS and l.scope.is_empty():
						# Ni un échange, qui prend, ni le prix d'un nœud qui change le jeu (le
						# Colosse) : ce ne sont pas des seconds leviers.
						if l.value_per_point > 0.0 and n.kind().is_empty():
							assert_false(levers.has(key), "« %s » : deux nœuds de %s" % [n.id, l.stat])
							levers[key] = true
						continue
					assert_false(
						line_owner.has(key) and line_owner[key] != c.identifier(),
						"« %s » vise « %s », déjà visé dans « %s »" % [n.id, key, line_owner.get(key, "")]
					)
					line_owner[key] = c.identifier()


## Un arbre qu'on remplit ne demande aucun choix : chacun offre plus que son pool.
func test_no_tree_fills_up_entirely() -> void:
	for base in _books():
		if base in Character.class_manual_bases():
			continue
		for c in base.manual.cells:
			if c.talents.is_empty():
				continue
			var offered := 0
			for n in c.talents:
				offered += n.points_max
			assert_gt(
				offered, Manual.MAX_LEVEL,
				"« %s » offre %d points pour un pool de %d" % [c.identifier(), offered, Manual.MAX_LEVEL]
			)


## Un nœud qui change le jeu ne se comprend pas à ses lignes : « +24 rayon de l'explosion
## des tués » ne dit ni qui explose, ni quand. Chaque nœud d'un arbre repris le décrit,
## et chaque `{champ}` de sa description existe dans `SkillStats.facts()`.
func test_each_reworked_node_says_what_it_does() -> void:
	for base in _books():
		if base in Character.class_manual_bases():
			continue
		for c in base.manual.cells:
			for n in c.talents:
				assert_false(n.description.is_empty(), "« %s » ne dit pas ce qu'il fait" % n.id)
				assert_false(
					n.displayed_description().contains("{"),
					"« %s » : un chiffre de sa description n'existe pas" % n.id
				)


## « +1 projectile » sur un serpent ferait croire que les affixes de projectile le
## touchent : les nombres de projectile ne se visent que sur un projectile (jalon 34).
func test_projectile_numbers_only_on_a_projectile() -> void:
	for base in _books():
		for c in base.manual.cells:
			for n in c.talents:
				for l in n.lines:
					if l.stat in ["projectiles", "projectile_speed"]:
						assert_true(
							c.skill.worn(Keywords.PROJECTILE),
							"« %s » vise « %s » sur ce qui n'est pas un projectile" % [n.id, l.stat]
						)


## Une perte : ce qui baisse là où monter est un gain, ou ce qui monte là où baisser l'est.
func test_a_loss_is_read_by_what_the_number_is_for() -> void:
	assert_true(StatMod.new("damage", StatMod.Mode.MORE, -10.0).is_loss(), "moins de dégâts")
	assert_false(StatMod.new("damage", StatMod.Mode.MORE, 10.0).is_loss())
	assert_true(StatMod.new("use_time", StatMod.Mode.PERCENT, 60.0).is_loss(), "un geste plus long")
	assert_false(StatMod.new("recharge", StatMod.Mode.PERCENT, -10.0).is_loss(), "une recharge plus courte")
	assert_true(StatMod.new("self_burn", StatMod.Mode.PERCENT, 100.0).is_loss(), "brûler plus")


func test_a_node_says_what_kind_it_is() -> void:
	var numbers := _node("n", [_line("damage", 10.0, true)] as Array[TalentLine])
	assert_eq(numbers.kind(), "", "des nombres, rien à signaler")
	assert_eq(_node("m", [_line(SkillStats.PIERCE, 1.0)] as Array[TalentLine]).kind(), "mécanique")
	var shaped := _node("t", [] as Array[TalentLine])
	shaped.transforms = true
	assert_eq(shaped.kind(), "transformation")

	var freeing := _node("f", [] as Array[TalentLine])
	freeing.frees = true
	assert_eq(freeing.kind(), "mécanique", "l'affranchissement change le jeu")


## L'Armure de givre (jalon 36) : le tombeau n'enferme plus, sur le lancer seulement.
func test_a_freeing_node_unbinds_the_cast() -> void:
	var tomb := SkillCatalog.by_id("frost_tomb")
	assert_true(tomb.resolve(1, null).binds_caster)
	var node := _node("f", [] as Array[TalentLine])
	node.frees = true
	var invested := InvestedTalent.new(node, 1)
	assert_false(tomb.resolve(1, null, [], [invested]).binds_caster)
	assert_true(tomb.binds_caster, "la compétence ne change pas")


## Et sa recharge est fixe : ni ligne ni récupération ne la bougent.
func test_a_freed_cast_has_a_fixed_recharge() -> void:
	var tomb := SkillCatalog.by_id("frost_tomb")
	var stats := CharacterStats.new()
	stats.cooldown_recovery = 80.0
	var node := _node("f", [_line("recharge", -50.0, true)] as Array[TalentLine])
	node.frees = true
	var cast := tomb.resolve(1, stats, [], [InvestedTalent.new(node, 1)])
	assert_eq(cast.recharge, SkillStats.FREED_RECHARGE)
	assert_eq(cast.interval, SkillStats.FREED_RECHARGE)


## Les trois formes du chevalier (jalon 39) sont portées par les vrais nœuds : les tests
## de forme passent par un nœud d'essai, et un Ressac sans forme n'y paraissait pas.
func test_the_knight_transformations_carry_their_shapes() -> void:
	var expected := {
		"heavy_strike_shatter": Skill.Shape.SLAM,
		"wave_slash_backwash": Skill.Shape.BOOMERANG,
		"slicing_dash_war_leap": Skill.Shape.LEAP,
	}
	for c in ItemCatalog.by_id("manual_weapons").manual.cells:
		for n in c.talents:
			if expected.has(n.id):
				assert_true(n.transforms, n.id)
				assert_eq(n.shape, expected[n.id], n.id)
				expected.erase(n.id)
	assert_true(expected.is_empty(), "introuvables : %s" % [expected.keys()])


func test_the_holy_transformations_carry_their_shapes() -> void:
	var expected := {
		"holy_strike_cross": Skill.Shape.HOLY_CROSS,
		"sacred_pillar_drift": Skill.Shape.DRIFT,
	}
	for c in ItemCatalog.by_id("manual_holy").manual.cells:
		for n in c.talents:
			if expected.has(n.id):
				assert_true(n.transforms, n.id)
				assert_eq(n.shape, expected[n.id], n.id)
				expected.erase(n.id)
	assert_true(expected.is_empty(), "introuvables : %s" % [expected.keys()])
