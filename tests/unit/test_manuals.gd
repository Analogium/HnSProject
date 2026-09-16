extends GutTest

## Le manuel comme objet : une base du catalogue qui tombe et se ramasse comme le
## reste, un archétype partagé qui dit ce qu'on peut y apprendre, et un état
## **par exemplaire** qui retient ce que celui-ci a appris.
##
## C'est la séparation entre les trois que ces tests défendent. La confondre est
## la faute la plus chère du jalon : les points écrits sur l'archétype partagé
## seraient ceux de tous les manuels de la partie.


func _base() -> ItemBase:
	return ItemCatalog.by_id("manual_lightning")


# --------------------------------------------------------------------------
# La base, dans le catalogue
# --------------------------------------------------------------------------

func test_the_manual_is_a_catalog_base() -> void:
	var base := _base()
	assert_not_null(base, "le manuel se retrouve par son identifiant")
	assert_not_null(base.manual, "et il ouvre un archétype")
	assert_false(base.manual.name.is_empty(), "qui porte un nom lisible")


## L'invariant du §3.2, dans les deux sens. Le sens oublié est celui qui coûte :
## une base non équipable **sans** archétype serait une faute de frappe dans un
## `family`, et elle passerait pour un manuel auprès de toutes les règles qui
## exemptent les manuels.
func test_an_archetype_goes_with_the_manual_family() -> void:
	for base in ItemCatalog.ALL:
		var is_manual: bool = base.family == ItemBase.MANUAL_FAMILY
		assert_eq(
			base.manual != null, is_manual,
			"« %s » : famille « %s » et archétype ne disent pas la même chose"
				% [base.display_name, base.family]
		)
		if not is_manual:
			assert_true(
				EquipmentSlots.equippable_family(base.family),
				"« %s » ne se porte nulle part et n'est pas un manuel" % base.display_name
			)


## Un manuel dont on ne peut rien apprendre à lancer est un objet qui occupe
## quatre cases du sac pour rien. **Ce que porte chaque case** est l'affaire de
## `test_talents.gd`, à qui appartient la règle « une case, une chose ».
func test_each_manual_teaches_at_least_one_skill() -> void:
	for base in ItemCatalog.ALL:
		if base.manual == null:
			continue
		assert_gt(base.manual.cells.size(), 0, "« %s » est vide" % base.display_name)
		assert_gt(
			base.manual.skills().size(), 0,
			"« %s » n'enseigne aucune compétence" % base.manual.name
		)


func test_the_archetype_finds_its_slot_by_id() -> void:
	var arch := _base().manual
	var c := arch.cell_of("swift_bolt")
	assert_not_null(c, "la case existe")
	assert_eq(c.skill.id, "swift_bolt")
	assert_null(arch.cell_of("spell_that_does_not_exist"), "et l'inconnu ne rend rien")
	assert_eq(
		arch.skills().size(), arch.cells.size() - arch.passives().size(),
		"toutes les cases comptent, moins celles des passifs"
	)


# --------------------------------------------------------------------------
# L'exemplaire et son état
# --------------------------------------------------------------------------

func test_a_picked_up_manual_has_its_own_state() -> void:
	var item := Item.new(_base())
	assert_not_null(item.manual, "un manuel naît avec son état")
	assert_eq(item.manual.points_spent(), 0, "blank")
	assert_eq(item.manual.experience, 0)


func test_what_is_not_a_manual_has_no_state() -> void:
	assert_null(Item.new(ItemCatalog.by_id("sword")).manual)


## **Le test de l'étape.** Deux manuels ramassés partagent leur archétype — c'est
## le même fichier du disque — et rien d'autre. Écrire dans l'un ne doit toucher
## ni l'autre, ni le `.tres`, que l'éditeur pourrait graver.
func test_two_manuals_have_independent_points() -> void:
	var a := Item.new(_base())
	var b := Item.new(_base())

	assert_same(a.base.manual, b.base.manual, "le contenu du livre est partagé")
	assert_ne(a.manual, b.manual, "ce qu'on y a appris, non")

	a.manual.points["swift_bolt"] = 3
	a.manual.experience = 400

	assert_eq(a.manual.points_of("swift_bolt"), 3, "le premier a ses points")
	assert_eq(b.manual.points_of("swift_bolt"), 0, "le second n'a rien reçu")
	assert_eq(b.manual.experience, 0, "ni son expérience")

	# L'archétype partagé ne porte aucun état : si la moindre ligne de points y
	# atterrissait un jour, c'est ici qu'on le verrait.
	var fresh := Item.new(_base())
	assert_eq(fresh.manual.points_spent(), 0, "un troisième exemplaire naît vierge")


# --------------------------------------------------------------------------
# Ce qu'un manuel n'est pas
# --------------------------------------------------------------------------

## Il se range, il ne se porte pas. `equip()` doit le rendre intact plutôt que de
## le faire disparaître : un objet refusé ne se perd jamais.
func test_a_manual_equips_nowhere() -> void:
	var item := Item.new(_base())
	assert_eq(EquipmentSlots.free_for(item, {}), "", "aucun emplacement ne l'accepte")
	assert_false(EquipmentSlots.equippable_family(item.base.family))
	for id in EquipmentSlots.ids():
		assert_false(EquipmentSlots.accepts(id, item), "ni « %s »" % id)


## Pas même les affixes universels : un livre qui donnerait « +12 % résistance au
## froid » se lirait comme un bug, et c'est ce que la réserve fait par défaut à
## toute base qu'aucune étiquette n'exclut.
func test_a_manual_receives_no_affix() -> void:
	var base := _base()
	assert_eq(ItemAffixPool.compatibles(base).size(), 0, "aucun affixe compatible")
	assert_eq(ItemAffixPool.eligible(base, 60).size(), 0, "pas même au niveau 60")
	assert_eq(
		ItemAffixPool.roll(RandomNumberGenerator.new(), base, 60).size(), 0,
		"et le tirage n'en invente pas"
	)


## Sa rareté ne vient pas du nombre d'affixes — il n'en a aucun — mais de sa
## version. Le livre de départ est commun ; ses versions plus rares viendront
## au-dessus, et c'est le palier qui le dira.
func test_a_manual_rarity_comes_from_its_version() -> void:
	var item := Item.new(_base())
	assert_eq(item.base.tier, 1, "le manuel de départ est le premier palier")
	assert_eq(item.rarity(), Item.Rarity.COMMON)


# --------------------------------------------------------------------------
# La chute
# --------------------------------------------------------------------------

## Il tombe comme le reste : c'est ce qui a fait choisir d'en faire un objet du
## sac plutôt qu'une collection à part, et donc de ne pas réécrire la chute, le
## ramassage et le rangement une deuxième fois.
func test_a_manual_drops_and_arrives_whole() -> void:
	Game.rng.seed = 90210
	var seen: Item = null
	for i in 4000:
		var item := LootTable.roll(0, 1)
		if item != null and item.manual != null:
			seen = item
			break
	assert_not_null(seen, "un manuel finit par tomber en zone 1")
	if seen == null:
		return
	assert_eq(seen.item_level, 1, "avec le niveau de sa zone, comme tout le reste")
	assert_eq(seen.manual.points_spent(), 0, "et vierge")

	# 2 × 2 dans le sac : il prend de la place, comme un objet.
	var bag := Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)
	assert_true(bag.add(seen), "il se range")
	assert_eq(bag.placed.size(), 1)


# --------------------------------------------------------------------------
# L'expérience et les points (étape 4)
# --------------------------------------------------------------------------

## Une case fabriquée pour le test : le contenu du jeu changera, la règle non.
func _trial_archetype(required_level: int, points_max: int) -> ManualArchetype:
	var c := Skill.new()
	c.id = "trial"
	c.name = "Trial"
	c.required_manual_level = required_level
	var table: Array[float] = []
	for i in points_max:
		table.append(float(i + 1))
	c.damage_per_point = table

	var cell := ManualCell.new()
	cell.skill = c
	var arch := ManualArchetype.new()
	arch.id = "trial"
	arch.name = "Trial"
	arch.cells = [cell] as Array[ManualCell]
	return arch


## Un livre tout juste ramassé a de quoi ouvrir une case. Sans ce premier point,
## sa page ne ferait rien du tout à la première ouverture — ce qui se lit comme
## une panne, pas comme une attente.
func test_a_fresh_manual_already_has_a_point() -> void:
	var m := Manual.new()
	assert_eq(m.level(), 1)
	assert_eq(m.points_gained(), 1)
	assert_eq(m.remaining_points(), 1)


func test_level_and_points_rise_with_experience() -> void:
	var m := Manual.new()
	m.gain_experience(Manual.XP_BASE)
	assert_eq(m.level(), 2, "le premier palier est franchi")
	assert_eq(m.remaining_points(), 2, "et il donne un point de plus")


func test_experience_does_not_go_down() -> void:
	var m := Manual.new()
	m.gain_experience(100)
	m.gain_experience(-500)
	assert_eq(m.experience, 100, "un gain négatif ne retire rien")


func test_invest_places_a_point() -> void:
	var arch := _trial_archetype(1, 5)
	var m := Manual.new()
	assert_true(m.invest(arch, "trial"))
	assert_eq(m.points_of("trial"), 1)
	assert_eq(m.remaining_points(), 0, "le point est dépensé")


## Le garde-fou qui compte : on ne place pas ce qu'on n'a pas gagné.
func test_cannot_place_more_points_than_we_have() -> void:
	var arch := _trial_archetype(1, 5)
	var m := Manual.new()
	assert_true(m.invest(arch, "trial"), "le point du niveau 1")
	assert_false(m.can_invest(arch, "trial"), "et plus rien après")
	assert_false(m.invest(arch, "trial"))
	assert_eq(m.points_of("trial"), 1, "la case n'a pas bougé")


func test_a_slot_maximum_is_not_exceeded() -> void:
	var arch := _trial_archetype(1, 2)
	var m := Manual.new()
	m.gain_experience(999999)   # de quoi payer bien plus que deux points
	assert_true(m.invest(arch, "trial"))
	assert_true(m.invest(arch, "trial"))
	assert_false(m.invest(arch, "trial"), "la case est pleine")
	assert_eq(m.points_of("trial"), 2)
	assert_gt(m.remaining_points(), 0, "il reste des points, mais pas où les mettre")


## Une case qui demande un niveau que le livre n'a pas refuse le point, et le
## rend quand le niveau arrive.
func test_a_locked_slot_refuses_then_accepts() -> void:
	var arch := _trial_archetype(3, 5)
	var m := Manual.new()
	assert_false(m.can_invest(arch, "trial"), "niveau 1, la case demande 3")

	while m.level() < 3:
		m.gain_experience(50)
	assert_true(m.invest(arch, "trial"), "au niveau 3, elle s'ouvre")


## Un identifiant que ce livre-là n'enseigne pas : refusé, même s'il existe
## ailleurs dans le jeu. C'est l'archétype qui décide, pas le catalogue.
func test_no_investing_in_a_missing_slot() -> void:
	var arch := _trial_archetype(1, 5)
	var m := Manual.new()
	assert_false(m.invest(arch, "swift_bolt"), "pas dans ce livre")
	assert_false(m.invest(null, "trial"), "ni sans livre du tout")
	assert_eq(m.points_spent(), 0)
