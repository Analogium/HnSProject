extends GutTest

## Le râtelier et la page : ce qu'on voit et ce qu'on clique doivent être au même
## endroit, et les conditions de l'investissement doivent tenir même lorsqu'on
## clique là où il ne faut pas.
##
## Depuis le jalon 10, la page a deux vues — la grille des cases et l'arbre d'une
## compétence — et **ce qui tombe dans un test, c'est le passage de l'une à
## l'autre** : une vue qui reste ouverte sur un livre rangé dessine les nœuds
## d'un manuel qui n'est plus là.

var _panel: ManualPanel
var _player: Player


func before_each() -> void:
	_player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_player)
	# Le panneau vit dans la scène de zone et n'a pas de scène propre : on lui
	# donne la place qu'il y occupe, lue dans la scène et non recopiée. La fiche se
	# borne à l'écran d'après cette place ; une place inventée validerait un
	# panneau qui n'est pas celui du jeu.
	_panel = ManualPanel.new()
	var frame := _frame_in_zone()
	_panel.position = frame.position
	_panel.size = frame.size
	add_child_autofree(_panel)
	await wait_process_frames(1)
	_panel.bind(_player)
	_panel.visible = true


func _frame_in_zone() -> Rect2:
	var state := (load("res://world/zone.tscn") as PackedScene).get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != "Manuals":
			continue
		var edges := {}
		for j in state.get_node_property_count(i):
			edges[state.get_node_property_name(i, j)] = state.get_node_property_value(i, j)
		return Rect2(
			edges["offset_left"], edges["offset_top"],
			edges["offset_right"] - edges["offset_left"], edges["offset_bottom"] - edges["offset_top"]
		)
	return Rect2()


func _book() -> Item:
	return Item.new(ItemCatalog.by_id("manual_lightning"))


## Un livre au râtelier, avec de quoi payer : la plupart de ces tests regardent
## des conditions, pas la courbe d'expérience.
func _rich_book() -> Item:
	var book := _book()
	book.manual.gain_experience(999999)
	_player.study(book)
	return book


## La case d'une compétence du manuel de la foudre, celle dont l'arbre sert de
## terrain d'essai.
func _bolt_cell() -> ManualCell:
	return ItemCatalog.by_id("manual_lightning").manual.cell_of("swift_bolt")


func _click_on(point: Vector2, button := MOUSE_BUTTON_LEFT) -> void:
	_panel._track(point)
	if button == MOUSE_BUTTON_LEFT:
		_panel._left_click()
	else:
		_panel._right_click()


# --------------------------------------------------------------------------
# Le râtelier
# --------------------------------------------------------------------------

## Le cœur d'un dos de livre retombe sur ce dos-là. Un décalage entre le dessin
## et le calcul ne se voit pas : on croit que le clic « n'a pas marché ».
func test_the_click_finds_the_drawn_slot() -> void:
	for i in Rack.SLOT_COUNT:
		_panel._track(_panel._slot_rect(i).get_center())
		assert_eq(_panel._hover_slot, i, "emplacement %d" % i)


func test_outside_slots_nothing_is_hovered() -> void:
	_panel._track(Vector2(_panel.size.x - 2.0, 2.0))
	assert_eq(_panel._hover_slot, -1)
	assert_eq(_panel._hover_cell, -1)


func test_the_click_chooses_the_slot() -> void:
	_player.study(_book(), 2)
	_panel._track(_panel._slot_rect(2).get_center())
	_panel._hover_slot = 2
	_panel._selected = 2
	assert_not_null(_panel._book(), "la page est celle du livre choisi")
	_panel._selected = 0
	assert_null(_panel._book(), "et l'emplacement vide n'ouvre rien")


## Ranger rend le livre au sac, avec ses points : c'est toute la promesse du
## jalon 6 — un manuel emporte sa progression.
func test_storing_returns_the_book_to_the_bag_with_its_points() -> void:
	var book := _rich_book()
	_panel._invest("swift_bolt")
	_panel._store(0)

	assert_null(_player.rack.at(0), "le râtelier est libre")
	assert_eq(_player.inventory.placed.size(), 1, "et le livre est dans le sac")
	assert_eq(book.manual.points_of("swift_bolt"), 1, "avec ce qu'il a appris")


## Le sac plein, le livre tombe plutôt que de s'évaporer.
func test_a_book_stored_without_room_is_discarded() -> void:
	var book := _book()
	_player.study(book)
	# Bouché avec des objets d'**une** case : cinquante anneaux remplissent la
	# grille exactement. Des plastrons n'y arriveraient pas — cinq y entrent et
	# laissent deux rangées libres, largement de quoi ranger un livre.
	for i in Inventory.DEFAULT_COLS * Inventory.DEFAULT_ROWS:
		assert_true(
			_player.inventory.add(Item.new(ItemCatalog.by_id("ring"))),
			"le sac accepte les cinquante"
		)

	var discarded: Array[Item] = []
	_panel.drop_requested.connect(func(item: Item) -> void: discarded.append(item))
	_panel._store(0)

	assert_eq(discarded.size(), 1, "il est tombé au sol")
	assert_same(discarded[0], book, "et c'est bien lui")


# --------------------------------------------------------------------------
# La grille
# --------------------------------------------------------------------------

## Tout ce que la page dessine tient dans la fenêtre. Aucune assertion ne voit un
## carré qui déborde ; celle-ci le calcule avec **les mêmes fonctions** que le
## dessin, sinon elle validerait sa propre copie.
func test_slots_and_nodes_fit_in_the_panel() -> void:
	var frame := Rect2(
		0.0, _panel._page_top(), _panel.size.x, _panel._help_top() - _panel._page_top()
	)
	for base: ItemBase in ItemCatalog.ALL:
		if base.manual == null:
			continue
		for cell: ManualCell in base.manual.cells:
			assert_true(
				frame.encloses(_panel._cell_rect(cell.position)),
				"« %s » : la case %s sort de la page" % [cell.identifier(), cell.position]
			)
			for node: TalentNode in cell.talents:
				assert_true(
					frame.encloses(_panel._node_rect(node.position)),
					"« %s » : le nœud %s sort de la page" % [node.id, node.position]
				)
	assert_true(frame.encloses(_panel._root_rect()), "et la racine d'un arbre y tient")


## Le clic sur une case de compétence **ouvre son arbre** : c'est là que se
## placent ses points depuis le jalon 10.
func test_clicking_a_skill_opens_its_tree() -> void:
	_rich_book()
	_click_on(_panel._cell_rect(_bolt_cell().position).get_center())
	assert_not_null(_panel._open_cell(), "l'arbre est ouvert")
	assert_eq(_panel._open_cell().skill.id, "swift_bolt")


## Un passif n'a rien à orienter : le clic y place un point directement.
func test_clicking_a_passive_places_a_point() -> void:
	var book := _rich_book()
	var cell := book.base.manual.cells[4]
	assert_not_null(cell.passive, "la cinquième case du manuel de la foudre est son passif")

	_click_on(_panel._cell_rect(cell.position).get_center())
	assert_null(_panel._open_cell(), "un passif n'ouvre pas de vue")
	assert_eq(book.manual.points_of(cell.passive.id), 1)


func test_a_click_in_the_void_places_nothing() -> void:
	var book := _rich_book()
	_click_on(Vector2(_panel.size.x - 3.0, _panel._help_top() - 2.0))
	_panel._invest("spell_that_does_not_exist")
	assert_eq(book.manual.points_spent(), 0)


## Sans livre à l'emplacement ouvert, aucun clic ne peut rien faire.
func test_without_book_the_panel_does_nothing() -> void:
	_panel._invest("swift_bolt")
	assert_null(_panel._book())
	assert_null(_panel._open_cell())


# --------------------------------------------------------------------------
# L'arbre
# --------------------------------------------------------------------------

func _open_tree() -> Item:
	var book := _rich_book()
	_click_on(_panel._cell_rect(_bolt_cell().position).get_center())
	return book


## La racine **est** la case de la compétence : c'est le seul endroit où ses
## points se placent, et le clic doit y tomber comme sur la grille.
func test_clicking_the_root_places_a_skill_point() -> void:
	var book := _open_tree()
	_click_on(_panel._root_rect().get_center())
	assert_eq(book.manual.points_of("swift_bolt"), 1)


func test_the_click_finds_the_drawn_node() -> void:
	_open_tree()
	var talents := _bolt_cell().talents
	for i in talents.size():
		_panel._track(_panel._node_rect(talents[i].position).get_center())
		assert_eq(_panel._hover_node, i, "« %s »" % talents[i].id)
		assert_false(_panel._hover_root, "et ce n'est pas la racine")


## Le clic dans un nœud place un point, et c'est `Manual` qui décide : sans point
## dans la compétence, le nœud refuse.
func test_clicking_a_node_places_a_point_when_the_tree_allows() -> void:
	var book := _open_tree()
	var branch := _bolt_cell().talents[0]

	_click_on(_panel._node_rect(branch.position).get_center())
	assert_eq(book.manual.points_of(branch.id), 0, "aucun point dans la compétence")

	_click_on(_panel._root_rect().get_center())
	_click_on(_panel._node_rect(branch.position).get_center())
	assert_eq(book.manual.points_of(branch.id), 1, "la compétence ouverte, le nœud accepte")


## Le clic droit reprend un point là où le clic gauche en ajoute un.
func test_right_click_refunds_a_node_point() -> void:
	var book := _open_tree()
	var branch := _bolt_cell().talents[0]
	_click_on(_panel._root_rect().get_center())
	_click_on(_panel._node_rect(branch.position).get_center())
	var remaining_all := book.manual.remaining_points()

	_click_on(_panel._node_rect(branch.position).get_center(), MOUSE_BUTTON_RIGHT)
	assert_eq(book.manual.points_of(branch.id), 0, "le point est reparti")
	assert_eq(book.manual.remaining_points(), remaining_all + 1, "et il est replaçable")

	_click_on(_panel._root_rect().get_center(), MOUSE_BUTTON_RIGHT)
	assert_eq(book.manual.points_of("swift_bolt"), 0, "la racine rend le point de la compétence")
	assert_not_null(_panel._open_cell(), "sans quitter l'arbre")


## Sur la grille, le clic droit reprend le point d'un passif, et celui d'une
## compétence sans ouvrir son arbre.
func test_right_click_on_the_grid_refunds_a_point() -> void:
	var book := _rich_book()
	var arch := book.base.manual
	var passive: Passive = arch.passives()[0]
	assert_true(_player.invest(0, passive.id))
	assert_true(_player.invest(0, "swift_bolt"))
	for i in arch.cells.size():
		var cell: ManualCell = arch.cells[i]
		if cell.identifier() in [passive.id, "swift_bolt"]:
			_click_on(_panel._cell_rect(cell.position).get_center(), MOUSE_BUTTON_RIGHT)
	assert_eq(book.manual.points_of(passive.id), 0)
	assert_eq(book.manual.points_of("swift_bolt"), 0)
	assert_null(_panel._open_cell(), "la grille reste la grille")


## Une compétence retombée à zéro sort de la barre : une case grisée qui annonce un
## sort inlançable se découvre au pire moment.
func test_a_skill_refunded_to_zero_leaves_the_bar() -> void:
	_rich_book()
	assert_true(_player.invest(0, "swift_bolt"))
	_player.bar.put(2, "swift_bolt")
	assert_true(_player.refund(0, "swift_bolt"))
	assert_eq(_player.bar.id_of(2), "", "la case s'est vidée")


## Le clic droit à côté d'un nœud revient à la grille : le geste du retour est
## celui qui range, et il n'y a pas une touche de plus à connaître.
func test_right_click_beside_returns_to_the_grid() -> void:
	_open_tree()
	_click_on(Vector2(_panel.size.x - 3.0, _panel._help_top() - 2.0), MOUSE_BUTTON_RIGHT)
	assert_null(_panel._open_cell(), "on est revenu sur la grille")


func test_escape_closes_the_tree_before_the_window() -> void:
	_open_tree()
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	_panel._input(key)
	assert_null(_panel._open_cell(), "l'arbre s'est refermé")
	assert_true(_panel.visible, "et la fenêtre est restée ouverte")


## **Le piège du jalon.** Ranger le livre dont l'arbre est ouvert laisserait la
## vue dessiner les nœuds d'un manuel qui n'est plus au râtelier.
func test_storing_the_book_closes_its_tree() -> void:
	_open_tree()
	_panel._store(0)
	assert_null(_panel._open_cell())
	assert_null(_panel._book())


## Choisir un autre livre referme l'arbre : celui du premier ne veut rien dire
## sur la page du second.
func test_changing_book_closes_the_tree() -> void:
	_open_tree()
	_player.study(Item.new(ItemCatalog.by_id("manual_weapons")), 1)
	_click_on(_panel._slot_rect(1).get_center())
	assert_eq(_panel._selected, 1)
	assert_null(_panel._open_cell())


# --------------------------------------------------------------------------
# Les fiches
# --------------------------------------------------------------------------

## Les valeurs des lignes de la fiche qui portent cet intitulé, dans leur ordre.
## Sur le texte sans marque : un terme du glossaire s'y lit comme un mot.
## L'intitulé se cherche **sous la majuscule que la fiche lui pose** : les tests
## l'écrivent comme le contenu l'écrit, en minuscule, et la règle de capitalisation est
## celle de `SheetLine` (jalon 20).
func _values(lines: Array, label_of: String) -> PackedStringArray:
	var wanted := RichText.capitalized(label_of)
	var out := PackedStringArray()
	for line: ManualPanel.SheetLine in lines:
		if Glossary.plain(line.label_of) == wanted:
			out.append(Glossary.plain(line.value))
	return out


func _sheet_of(book: Item, skill_id: String) -> Array:
	return _panel._skill_sheet(
		book.manual, SkillCatalog.by_id(skill_id)
	).lines


## Ce qu'un lancer pose sur son lanceur se lit **sous le nom de son buff**, et sa durée
## avec lui : c'est la durée du buff, pas celle d'une trace au sol (jalon 20).
func test_a_granted_buff_reads_under_its_name() -> void:
	var book := _rich_book()
	book.manual.invest(book.base.manual, "storm_dash")
	var lines := _sheet_of(book, "storm_dash")
	var buff: SkillBuff = SkillCatalog.by_id("storm_dash").buffs[0]

	var under := PackedStringArray()
	for line: ManualPanel.SheetLine in lines:
		if line.heading == buff.displayed_name():
			under.append(Glossary.plain(line.label_of))
	assert_gt(under.size(), 1, "le bloc porte le nom du buff et ses lignes")
	assert_true(under.has(RichText.capitalized(Texts.t("durée"))), "sa durée y est")
	assert_eq(_values(lines, "durée").size(), 1, "et nulle part ailleurs")


## Un déplacement ne touche personne : sa fiche n'annonce ni dégâts, ni forme, ni
## moyenne — **même l'arme à la main**, dont les fourchettes entrent dans tout ce qui
## porte « sort ». Le lancer les porte, la fiche ne les montre pas.
func test_a_movement_skill_shows_no_damage() -> void:
	var book := _rich_book()
	book.manual.invest(book.base.manual, "storm_dash")
	_player.skill_mods.assign([
		StatMod.ranged("damage_cold", 30.0, 70.0, Keywords.SPELL),
		StatMod.new("targets", StatMod.Mode.FLAT, 1.0, Keywords.SPELL),
	])
	var cast := _player.resolve(SkillCatalog.by_id("storm_dash"), 1)
	assert_gt(cast.total_max(), 0.0, "le lancer, lui, porte ce que l'équipement ajoute")

	var lines := _sheet_of(book, "storm_dash")
	for label_of in ["ajoutés", "par coup", "chance critique", "cibles", "moyenne par lancer"]:
		assert_eq(_values(lines, label_of).size(), 0, "« %s » n'a rien à faire là" % label_of)
	assert_eq(_values(lines, "coût").size(), 1, "le coût reste")
	assert_eq(_values(lines, "durée").size(), 1, "et la durée de son buff")


## Chaque intitulé commence par une majuscule : une fiche tout en minuscules se lit
## comme un fichier de réglage.
func test_every_line_starts_with_a_capital() -> void:
	var book := _rich_book()
	book.manual.invest(book.base.manual, "swift_bolt")
	for line: ManualPanel.SheetLine in _sheet_of(book, "swift_bolt"):
		var plain := Glossary.plain(line.label_of)
		assert_false(plain.is_empty(), "un intitulé vide")
		assert_eq(plain[0], plain[0].to_upper(), "« %s »" % plain)


## **La fiche passe par le même chemin que le lancer** (jalon 7, étape 5). Avec un
## « +1 projectile » porté, elle en annonce deux — et ce sont bien deux traits qui
## partent. Lue sur la compétence, elle en aurait annoncé un.
func test_the_sheet_announces_what_really_leaves() -> void:
	var book := _rich_book()
	book.manual.invest(book.base.manual, "swift_bolt")
	assert_eq(_values(_sheet_of(book, "swift_bolt"), "projectiles"), PackedStringArray(["1"]))

	_player.equip(Item.new(
		ItemCatalog.by_id("wand"), [ItemAffixPool.by_id("forked").modifier(1.0)]
	))
	assert_eq(
		_values(_sheet_of(book, "swift_bolt"), "projectiles"), PackedStringArray(["2"]),
		"la fiche en annonce deux"
	)

	var bolts := Node2D.new()
	add_child_autofree(bolts)
	_player.projectile_parent = bolts
	_player.bar.put(2, "swift_bolt")
	assert_true(_player.cast_slot(2))
	assert_eq(bolts.get_child_count(), 2, "et deux partent")


## Et elle annonce aussi ce qu'un **nœud** change : c'est le même chemin, et un
## talent lu dans le dessin rouvrirait la faille que le jalon 7 a fermée.
func test_the_sheet_announces_what_a_node_changes() -> void:
	var book := _rich_book()
	# La fourche demande deux points dans la compétence et un dans sa branche :
	# l'ordre compte, et c'est `Manual` qui refuserait le raccourci.
	for id in ["swift_bolt", "swift_bolt", "swift_bolt_overload", "swift_bolt_fork"]:
		assert_true(book.manual.invest(book.base.manual, id), "« %s »" % id)

	var lines := _sheet_of(book, "swift_bolt")
	assert_eq(
		_values(lines, "projectiles"), PackedStringArray(["2"]),
		"le nœud de fourche en ajoute un"
	)
	assert_eq(
		_values(lines, "dégâts amplifiés"), PackedStringArray(["+12 %"]),
		"et la surcharge multiplie les dégâts : un nœud donne du « plus » (jalon 14)"
	)


## Jalon 14 : ce qu'un objet ajoute contre un état se lit à part du coup, et les
## niveaux en bonus à côté des points placés.
func test_the_sheet_announces_levels_and_damage_against_a_state() -> void:
	var book := _rich_book()
	assert_true(book.manual.invest(book.base.manual, "swift_bolt"))
	_player.skill_mods.assign([
		StatMod.new(SkillStats.LEVELS, StatMod.Mode.FLAT, 2.0, Keywords.LIGHTNING),
		StatMod.new(
			SkillStats.against_stat(StatusEffects.Kind.NUMB), StatMod.Mode.PERCENT, 30.0, Keywords.SPELL
		),
	])
	var lines := _sheet_of(book, "swift_bolt")
	assert_eq(_values(lines, "points"), PackedStringArray(["1 / 5 (+2)"]))
	assert_eq(_values(lines, "dégâts accrus contre les engourdis"), PackedStringArray(["+30 %"]))


## La chance critique d'un sort est celle du coup : l'arme, sa ligne locale et les accrus.
func test_the_sheet_announces_the_crit_of_the_skill() -> void:
	var book := _rich_book()
	assert_true(book.manual.invest(book.base.manual, "swift_bolt"))
	_player.equip(Item.new(
		ItemCatalog.by_id("wand"), [StatMod.new("crit_chance", StatMod.Mode.FLAT, 0.03)]
	))
	_player.skill_mods.assign([StatMod.new("crit_chance", StatMod.Mode.PERCENT, 50.0, Keywords.SPELL)])
	var lines := _sheet_of(book, "swift_bolt")
	assert_eq(_values(lines, "chance critique"), PackedStringArray(["12 %"]), "(5 + 3) × 1,5")
	assert_eq(_values(lines, "dégâts critiques"), PackedStringArray(["200 %"]))


## Un nœud de conversion dit ce qu'il déplace et où : c'est la ligne qui explique
## à quelle résistance le coup s'oppose désormais.
func test_the_sheet_announces_the_conversion() -> void:
	var book := _rich_book()
	for id in ["swift_bolt", "swift_bolt", "swift_bolt", "swift_bolt_glacial_bolt"]:
		assert_true(book.manual.invest(book.base.manual, id), "« %s »" % id)

	assert_eq(
		_values(_sheet_of(book, "swift_bolt"), "converti"), PackedStringArray(["50 % en froid"])
	)


## La fiche d'un passif dit ce qu'il donne, **avec les mots de l'infobulle d'un
## objet** : « +20 armure » doit se lire pareil, qu'il vienne d'un plastron ou
## d'un livre.
func test_a_passive_sheet_says_what_it_gives() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_weapons"))
	book.manual.gain_experience(999999)
	_player.study(book)
	var passive: Passive = book.base.manual.passives()[0]
	for i in 2:
		assert_true(book.manual.invest(book.base.manual, passive.id))

	var sheet := _panel._passive_sheet(book.manual, passive)
	assert_eq(sheet.title_text, passive.displayed_name())
	assert_eq(sheet.subtitle, "toujours actif", "ce qu'il faut savoir de lui avant ses nombres")
	assert_eq(_values(sheet.lines, "points"), PackedStringArray(["2 / %d" % passive.points_max]))
	assert_eq(_values(sheet.lines, "armure"), PackedStringArray(["+24"]), "deux points de douze")


## La fiche d'un nœud fermé dit **ce qu'il demande**, et c'est le manuel qui le
## dit — la page ne porte aucune condition.
func test_a_node_sheet_says_what_it_requires() -> void:
	var book := _rich_book()
	var cell := _bolt_cell()
	var branch := cell.talents[0]
	var leaf := cell.talents[1]

	assert_eq(
		_values(_panel._node_sheet(book.manual, cell, branch).lines, "demande"),
		PackedStringArray(["1 point dans la compétence"])
	)
	book.manual.invest(book.base.manual, "swift_bolt")
	book.manual.invest(book.base.manual, "swift_bolt")
	assert_eq(
		_values(_panel._node_sheet(book.manual, cell, leaf).lines, "demande"),
		PackedStringArray(["le talent « %s »" % branch.displayed_name()]),
		"le parent d'abord : c'est la condition qu'on peut satisfaire tout de suite"
	)

	book.manual.invest(book.base.manual, branch.id)
	assert_eq(
		_values(_panel._node_sheet(book.manual, cell, leaf).lines, "demande").size(), 0,
		"ouverte, elle ne demande plus rien"
	)


## Un nœud qui donne un mot-clé le dit : c'est ce qui le distingue d'un nœud de
## conversion simple, et ça vaut un point de plus.
func test_a_node_sheet_announces_the_keyword_it_gives() -> void:
	var book := _rich_book()
	var cell := ItemCatalog.by_id("manual_weapons").manual.cell_of("heavy_strike")
	var burning_blade := cell.node_of("heavy_strike_burning_blade")
	var lines := _panel._node_sheet(book.manual, cell, burning_blade).lines

	assert_eq(_values(lines, "mot-clé"), PackedStringArray(["Feu"]))
	assert_eq(_values(lines, "converti"), PackedStringArray(["40 % en feu"]))


## **Chaque ligne vient de la résolution du lancer** : un sort à trois natures et
## plusieurs projectiles, lu ligne à ligne contre `Player.resolve()` au même
## nombre de points.
func test_each_line_comes_from_the_cast_resolution() -> void:
	var book := _rich_book()
	for i in 2:
		book.manual.invest(book.base.manual, "swift_bolt")
	_player.equip(Item.new(ItemCatalog.by_id("wand"), [
		ItemAffixPool.by_id("cold_to_spells").modifier(3.0, 7.0),
		ItemAffixPool.by_id("fire_to_spells").modifier(2.0, 5.0),
		ItemAffixPool.by_id("forked").modifier(1.0),
		ItemAffixPool.by_id("stormy").modifier(20.0),
	]))
	var bolt := SkillCatalog.by_id("swift_bolt")
	var cast := _player.resolve(bolt, 2)
	var lines := _sheet_of(book, "swift_bolt")

	assert_eq(_values(lines, "points"), PackedStringArray(["2 / %d" % bolt.points_max()]))
	assert_eq(_values(lines, "coût"), PackedStringArray(["%d mana" % roundi(cast.mana_cost)]))
	assert_eq(_values(lines, "recharge"), PackedStringArray(["%.2f s" % cast.interval]))
	assert_eq(
		_values(lines, "de base"), PackedStringArray(["%d foudre" % roundi(cast.base_damage)])
	)
	assert_eq(
		_values(lines, "ajoutés"), PackedStringArray(["3–7 froid", "2–5 feu"]),
		"une ligne par nature ajoutée, dans l'ordre des natures"
	)
	assert_eq(_values(lines, "intelligence"), PackedStringArray(), "aucun attribut ne multiplie")
	assert_eq(_values(lines, "dégâts accrus"), PackedStringArray(["+20 %"]))
	assert_eq(_values(lines, "par projectile"), PackedStringArray([
		"%d–%d" % [roundi(cast.total_min()), roundi(cast.total_max())]
	]))
	assert_eq(
		_values(lines, "projectiles"), PackedStringArray([str(cast.projectile_count())])
	)
	assert_eq(cast.projectile_count(), bolt.projectiles + 1, "le trait et son projectile de plus")
	assert_eq(
		_values(lines, "écart"), PackedStringArray(["%d°" % roundi(cast.spread_in_degrees)])
	)
	assert_eq(
		_values(lines, "vitesse"),
		PackedStringArray(["%d px/s" % roundi(cast.projectile_speed)])
	)
	assert_eq(
		_values(lines, "moyenne par lancer"),
		PackedStringArray([str(roundi(cast.average_per_cast()))])
	)
	assert_eq(
		_values(lines, "par seconde"),
		PackedStringArray([str(roundi(cast.average_per_second()))])
	)
	# Ce que les moyennes supposent est passé **dans le titre de leur groupe** (jalon 20) :
	# la note sous elles coûtait une ligne à la fiche la plus haute du jeu.
	assert_eq(_values(lines, "si tout touche, avant défenses").size(), 0, "plus de note")
	assert_false(
		String(ManualPanel.GROUP_TITLES[ManualPanel.Group.ESTIMATE]).is_empty(),
		"et ce qu'elle suppose se lit sur le titre du groupe"
	)


## Une nature sans dégâts n'a pas de ligne : rien d'équipé, rien d'ajouté ; un
## anneau de feu, et seule la ligne du feu apparaît.
func test_a_nature_without_damage_has_no_line() -> void:
	var book := _book()
	_player.study(book)
	var bare := _sheet_of(book, "swift_bolt")
	assert_eq(_values(bare, "ajoutés").size(), 0, "rien d'équipé, rien d'ajouté")
	assert_eq(_values(bare, "dégâts accrus").size(), 0)
	assert_eq(_values(bare, "écart").size(), 0, "un trait droit n'a pas d'écart")
	assert_eq(_values(bare, "converti").size(), 0, "et rien n'est converti")

	_player.equip(Item.new(
		ItemCatalog.by_id("ring"), [ItemAffixPool.by_id("fire_to_spells").modifier(2.0, 5.0)]
	))
	assert_eq(_values(_sheet_of(book, "swift_bolt"), "ajoutés"), PackedStringArray(["2–5 feu"]))


## Une case verrouillée dit ce qu'elle demande, et montre les nombres du premier
## point plutôt que zéro.
func test_a_locked_slot_says_what_it_requires() -> void:
	var book := _book()
	_player.study(book)
	# Parmi celles qui frappent : un buff n'a pas de table de dégâts, donc pas de ligne
	# « de base » à lire sous son verrou.
	var high: Skill = null
	for skill in book.base.manual.skills():
		if skill.damage_per_point.is_empty():
			continue
		if high == null or skill.required_manual_level > high.required_manual_level:
			high = skill
	assert_lt(book.manual.level(), high.required_manual_level, "un livre neuf ne l'ouvre pas")

	var lines := _sheet_of(book, high.id)
	assert_eq(
		_values(lines, "verrouillée"),
		PackedStringArray(["niveau %d du manuel" % high.required_manual_level])
	)
	assert_eq(_values(lines, "points"), PackedStringArray(["0 / %d" % high.points_max()]))
	assert_eq(
		_values(lines, "de base"),
		PackedStringArray(["%d foudre" % roundi(high.damage_per_point[0])]), "le premier point"
	)
	assert_eq(
		_values(_sheet_of(book, "swift_bolt"), "verrouillée").size(), 0,
		"une case ouverte ne se dit pas verrouillée"
	)


## La fiche reste dans le cadrage et au-dessus des jauges du HUD, **quoi que l'on
## survole** : une case, un passif, un nœud. Mesurée avec le cadre du dessin, sur
## les fiches les plus longues qu'on sache monter — les six natures ajoutées, un
## accroissement, un projectile de plus, et un livre neuf dont les cases hautes
## sont verrouillées.
func test_the_sheet_stays_in_frame() -> void:
	var mods: Array[StatMod] = [
		ItemAffixPool.by_id("forked").modifier(1.0),
		ItemAffixPool.by_id("stormy").modifier(20.0),
	]
	for nature: String in DamageType.IDS:
		mods.append(ItemAffixPool.by_id("%s_to_spells" % nature).modifier(20.0, 60.0))
	_player.equip(Item.new(ItemCatalog.by_id("wand"), mods))

	var base_screen := Vector2(Settings.base_size())
	var framing := Rect2(0.0, 0.0, base_screen.x, Hud.gauges_top(base_screen.y))
	var measured := 0
	for model: ItemBase in ItemCatalog.ALL:
		if model.manual == null:
			continue
		var book := Item.new(model)
		_player.rack.remove(0)
		_player.study(book, 0)
		for cell: ManualCell in model.manual.cells:
			_measure(
				_panel._cell_sheet(book.manual, cell),
				_panel._cell_rect(cell.position), framing, cell.identifier()
			)
			measured += 1
			for node: TalentNode in cell.talents:
				_measure(
					_panel._node_sheet(book.manual, cell, node),
					_panel._node_rect(node.position), framing, node.id
				)
				measured += 1
	assert_gt(measured, 0, "encore faut-il qu'il y ait des cases")


func _measure(sheet: ManualPanel.Sheet, anchor: Rect2, framing: Rect2, what: String) -> void:
	var r: Rect2 = _panel._sheet_rect(anchor, _panel._sheet_height(sheet))
	var on_screen := Rect2(r.position + _panel.global_position, r.size)
	assert_true(
		framing.encloses(on_screen), "« %s » : la fiche %s sort de %s" % [what, on_screen, framing]
	)


# --------------------------------------------------------------------------
# Le dessin
# --------------------------------------------------------------------------

## Le dessin traverse ses états sans se plaindre : un emplacement vide, une
## grille, un passif, un arbre à moitié rempli. Ce que ça **donne à l'œil** est du
## ressort de la capture ; ce qu'on vérifie ici, c'est qu'aucun de ces chemins ne
## plante.
func test_drawing_goes_through_its_states() -> void:
	_panel.queue_redraw()
	await wait_process_frames(1)

	var book := _rich_book()
	for i in 9:
		book.manual.invest(book.base.manual, "swift_bolt")
	for cell in book.base.manual.cells:
		_panel._track(_panel._cell_rect(cell.position).get_center())
		_panel.queue_redraw()
		await wait_process_frames(1)

	_click_on(_panel._cell_rect(_bolt_cell().position).get_center())
	for node in _bolt_cell().talents:
		book.manual.invest(book.base.manual, node.id)
		_panel._track(_panel._node_rect(node.position).get_center())
		_panel.queue_redraw()
		await wait_process_frames(1)
	_panel._track(_panel._root_rect().get_center())
	_panel.queue_redraw()
	await wait_process_frames(1)

	assert_eq(
		book.manual.points_of("swift_bolt"), 5,
		"la case est pleine : c'est l'état qu'on vient de dessiner"
	)
	assert_gt(book.manual.points_of("swift_bolt_overload"), 0, "et l'arbre est entamé")


## **Plusieurs fenêtres ouvertes doivent toutes répondre.** Un panneau qui
## consomme les clics tombés au-dehors rend sourds tous les autres : c'était le
## cas du sac, qui prenait tout dès qu'il était ouvert.
func test_a_click_outside_is_left_to_other_panels() -> void:
	assert_true(_panel._owns_click(_panel._slot_rect(1).get_center()), "sur un dos")
	assert_false(_panel._owns_click(Vector2(-30.0, 40.0)), "à gauche de la fenêtre")
	assert_false(
		_panel._owns_click(Vector2(_panel.size.x + 30.0, _panel.size.y * 0.5)),
		"à droite, là où le sac est ouvert"
	)
