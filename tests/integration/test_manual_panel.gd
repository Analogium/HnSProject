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


## Le manuel de la classe ne se range pas : le clic droit sur son dos ne fait rien, et
## son dos tient dans la fenêtre avec les trois autres.
func test_the_class_manual_does_not_leave_its_slot() -> void:
	var own := Item.new(Character.CLASSES[Character.WITCH]["manual"])
	_player.rack.seat(own)
	_click_on(_panel._slot_rect(Rack.CLASS_SLOT).get_center(), MOUSE_BUTTON_RIGHT)
	assert_same(_player.rack.at(Rack.CLASS_SLOT), own, "toujours là")
	assert_eq(_player.inventory.placed.size(), 0, "rien n'est venu au sac")
	assert_true(
		Rect2(Vector2.ZERO, _panel.size).encloses(_panel._slot_rect(Rack.CLASS_SLOT)),
		"son dos tient dans la fenêtre"
	)
	_click_on(_panel._slot_rect(Rack.CLASS_SLOT).get_center())
	assert_same(_panel._book(), own, "et il s'ouvre comme les autres")


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
func _page() -> Rect2:
	return Rect2(0.0, _panel._page_top(), _panel.size.x, _panel._help_top() - _panel._page_top())


## Les cases dans la page de la grille ; les nœuds, et la grille d'arbre entière, dans
## la fenêtre élargie d'un arbre ouvert (jalon 34) — vers la gauche, le sac est à droite.
func test_slots_and_nodes_fit_in_the_panel() -> void:
	var grid := _page()
	var right := _panel.position.x + _panel.size.x
	_panel._opened = "swift_bolt"
	var tree := _page()
	assert_gt(tree.size.y, grid.size.y, "l'arbre ouvert agrandit la fenêtre")
	assert_eq(_panel.size.x, ManualPanel.TREE_W, "et l'élargit")
	assert_eq(_panel.position.x + _panel.size.x, right, "sans avancer sur le sac")
	for base: ItemBase in ItemCatalog.ALL + Character.class_manual_bases():
		if base.manual == null:
			continue
		for cell: ManualCell in base.manual.cells:
			assert_true(
				grid.encloses(_panel._cell_rect(cell.position)),
				"« %s » : la case %s sort de la page" % [cell.identifier(), cell.position]
			)
			for node: TalentNode in cell.talents:
				assert_true(
					absi(node.position.x) <= ManualPanel.TREE_SPAN.x
						and absi(node.position.y) <= ManualPanel.TREE_SPAN.y,
					"« %s » : le nœud %s sort de la grille" % [node.id, node.position]
				)
	for corner in [-ManualPanel.TREE_SPAN, ManualPanel.TREE_SPAN]:
		assert_true(tree.encloses(_panel._node_rect(corner)), "le coin %s de la grille tient" % corner)
	assert_true(tree.encloses(_panel._root_rect()), "et la racine d'un arbre y tient")
	_panel._opened = ""
	assert_eq(_page().size, grid.size, "refermé, elle reprend sa place")
	assert_eq(_panel.position.x + _panel.size.x, right)


## Deux nœuds sur la même case se cachent, et un lien qui passe sous un troisième se lit
## comme passant par lui (« Mue → Couvée » lu « Mue → Vif → Couvée », capture du jalon 34).
func test_nodes_and_links_do_not_overlap() -> void:
	_panel._opened = "swift_bolt"
	var half := ManualPanel.NODE * 0.5 + 1.0
	for base: ItemBase in ItemCatalog.ALL + Character.class_manual_bases():
		if base.manual == null:
			continue
		for cell: ManualCell in base.manual.cells:
			var taken := {Vector2i.ZERO: "la compétence"}
			for node: TalentNode in cell.talents:
				assert_false(taken.has(node.position), "« %s » est posé sur %s" % [node.id, taken.get(node.position)])
				taken[node.position] = node.id
			for node: TalentNode in cell.talents:
				var ends: Array[Vector2i] = []
				if node.parents.is_empty():
					ends.append(Vector2i.ZERO)
				for parent: String in node.parents:
					ends.append(cell.node_of(parent).position)
				for from_cell: Vector2i in ends:
					var a := _panel._node_rect(from_cell).get_center()
					var b := _panel._node_rect(node.position).get_center()
					for at: Vector2i in taken:
						if at == from_cell or at == node.position:
							continue
						var c := _panel._node_rect(at).get_center()
						var near := Geometry2D.get_closest_point_to_segment(c, a, b)
						# Le nœud est carré : l'écart se mesure sur l'axe le plus lâche.
						assert_gt(
							maxf(absf(near.x - c.x), absf(near.y - c.y)), half, "« %s » : son lien passe sous « %s »" % [node.id, taken[at]]
						)
	_panel._opened = ""


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
	assert_eq(book.manual.points_spent(book.base.manual), 0)


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
	var remaining_all := book.manual.tree_remaining(_bolt_cell())

	_click_on(_panel._node_rect(branch.position).get_center(), MOUSE_BUTTON_RIGHT)
	assert_eq(book.manual.points_of(branch.id), 0, "le point est reparti")
	assert_eq(book.manual.tree_remaining(_bolt_cell()), remaining_all + 1, "et il est replaçable")

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


## Une compétence adossée aux PV le **dit** : son taux, et ce qu'il ajoute sur cette
## fiche-là. Sans cette ligne, « de base » monte avec la vie du personnage sans que rien
## ne l'explique (jalon 20).
func test_a_skill_backed_by_life_says_so() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_fire"))
	book.manual.gain_experience(999999)
	_player.rack.remove(0)
	_player.study(book, 0)
	book.manual.invest(book.base.manual, "immolation")

	var aura := SkillCatalog.by_id("immolation")
	var values := _values(_sheet_of(book, "immolation"), "adossé aux PV")
	assert_eq(values.size(), 1, "la ligne y est")
	assert_string_contains(
		values[0], str(roundi(_player.stats.max_health * aura.health_scaling)),
		"avec ce qu'elle donne sur cette fiche"
	)
	assert_eq(
		_values(_sheet_of(book, "fireball"), "adossé aux PV").size(), 0,
		"et rien pour ce qui ne s'y adosse pas"
	)


## Une compétence qui transit mieux le **dit**, et dit ce que ça donne : son accru, puis
## la chance qui en sort sur cette fiche-là, les accrus du porteur compris. Sans les deux
## nombres, « +50 % » n'a pas de point de départ (jalon 21).
func test_a_skill_that_chills_better_says_by_how_much() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_cold"))
	book.manual.gain_experience(999999)
	_player.rack.remove(0)
	_player.study(book, 0)
	book.manual.invest(book.base.manual, "ice_nova")

	var nova := SkillCatalog.by_id("ice_nova")
	var values := _values(_sheet_of(book, "ice_nova"), StatMod.LABELS["chill_chance"])
	assert_eq(values.size(), 1, "la ligne y est")
	assert_string_contains(values[0], "50", "son accru")
	assert_string_contains(values[0], "30", "et les 30 % qu'il donne sur une chance de 20")

	# Le passif du livre accroît la même chance : les deux s'additionnent, donc la
	# seconde valeur monte sans que la première bouge.
	for i in 4:
		assert_true(_player.invest(0, "frostbite"))
	var with_passive := _values(_sheet_of(book, "ice_nova"), StatMod.LABELS["chill_chance"])
	assert_string_contains(with_passive[0], "50", "l'accru de la compétence ne bouge pas")
	assert_string_contains(with_passive[0], "38", "20 × (1 + 0,50 + 0,40)")

	assert_eq(
		_values(_sheet_of(book, "ice_spike"), StatMod.LABELS["chill_chance"]).size(), 0,
		"et rien pour ce qui ne transit pas mieux"
	)
	assert_gt(nova.status_chance_increase, 0.0)


## Un état **sans statistique** qui l'accroisse se dit aussi : le tir de foudre du
## Projectile élémentaire engourdit à 60 %, et sa fiche le taisait quand celles du feu et
## de la glace l'écrivaient (jalon 28).
func test_a_better_numbing_is_said_too() -> void:
	var book := Item.new(Character.CLASSES[Character.WITCH]["manual"])
	book.manual.gain_experience(999999)
	_player.rack.seat(book)
	book.manual.invest(book.base.manual, "elemental_projectile")
	var label_of: String = StatusEffects.UNWORN_CHANCES[StatusEffects.Kind.NUMB]
	_player._turns["elemental_projectile"] = 2
	var values := _values(_sheet_of(book, "elemental_projectile"), label_of)
	assert_eq(values.size(), 1, "la ligne y est, au tour de la foudre")
	assert_string_contains(values[0], "200", "son accru")
	assert_string_contains(values[0], "60", "et les 60 % qu'il donne sur une chance de 20")
	_player._turns["elemental_projectile"] = 0
	assert_eq(_values(_sheet_of(book, "elemental_projectile"), label_of).size(), 0, "pas au tour du feu")


# --------------------------------------------------------------------------
# La fenêtre des déclenchements (touche des détails)
# --------------------------------------------------------------------------

func _studied(base_id: String, skill_id: String) -> Item:
	var book := Item.new(ItemCatalog.by_id(base_id))
	book.manual.gain_experience(999999)
	_player.rack.remove(0)
	_player.study(book, 0)
	assert_true(_player.invest(0, skill_id), skill_id)
	return book


func _triggers(skill_id: String) -> Array:
	return _panel._trigger_sheet(SkillCatalog.by_id(skill_id)).lines


## **La vraie chance** : des dégâts de feu ajoutés par l'arme donnent au pic de glace
## une chance d'embraser, **entière** (jalon 34), sans rien ôter à celle de transir — la
## fenêtre lit le coup résolu, pas la compétence.
func test_the_details_follow_what_the_hit_really_carries() -> void:
	_studied("manual_cold", "ice_spike")
	var chill := StatusEffects.name(StatusEffects.Kind.CHILL)
	var ignite := StatusEffects.name(StatusEffects.Kind.IGNITE)
	assert_eq(_values(_triggers("ice_spike"), chill), PackedStringArray(["20 %"]), "tout le coup est froid")
	assert_eq(_values(_triggers("ice_spike"), ignite).size(), 0, "et rien n'embrase")

	_player.equip(Item.new(ItemCatalog.by_id("wand"), [
		ItemAffixPool.by_id("fire_to_spells").modifier(20.0, 60.0)
	]))
	var cast := _player.resolve(SkillCatalog.by_id("ice_spike"), 1)
	var shares := cast.distribution()
	assert_gt(cast.crit_chance, 0.0, "la baguette porte une chance critique")
	assert_eq(
		_values(_triggers("ice_spike"), Texts.t("coup critique")),
		PackedStringArray([StatMod.percentage(roundi(cast.crit_chance * 100.0))]),
		"le critique du lancer, celui que la fiche annonce"
	)
	assert_gt(shares[DamageType.Kind.FIRE], 0.0)
	var fire := _values(_triggers("ice_spike"), ignite)
	assert_eq(fire, PackedStringArray(["20 %"]), "le feu ajouté embrase, quelle que soit sa part")
	assert_eq(_values(_triggers("ice_spike"), chill), PackedStringArray(["20 %"]), "et le froid garde sa chance")


## Le tour de la foudre du Projectile élémentaire : 20 % fois 1 + 200 %.
func test_the_details_read_the_next_turn() -> void:
	var book := Item.new(Character.CLASSES[Character.WITCH]["manual"])
	book.manual.gain_experience(999999)
	_player.rack.seat(book)
	assert_true(_player.invest(Rack.CLASS_SLOT, "elemental_projectile"))
	_player._turns["elemental_projectile"] = 2
	var numb := StatusEffects.name(StatusEffects.Kind.NUMB)
	assert_eq(_values(_triggers("elemental_projectile"), numb), PackedStringArray(["60 %"]))


## Une malédiction pose son état sans tirage ; la Peste décompose, et chaque à-coup de
## sa décomposition peut pourrir.
func test_curses_and_ticks_are_listed() -> void:
	_studied("manual_necrotic", "putrid_curse")
	var cursed := StatusEffects.name(StatusEffects.Kind.CURSED)
	assert_eq(_values(_triggers("putrid_curse"), cursed), PackedStringArray(["100 %"]))

	_studied("manual_necrotic", "plague")
	var lines := _triggers("plague")
	assert_eq(_values(lines, StatusEffects.name(StatusEffects.Kind.DECAY)).size(), 1, "la décomposition")
	var ticking := lines.filter(func(l: ManualPanel.SheetLine) -> bool: return l.group == ManualPanel.Group.ON_TICK)
	assert_eq(ticking.size(), 1, "et la pourriture de ses à-coups")
	assert_eq(Glossary.plain(ticking[0].value), StatMod.percentage(roundi(StatusEffects.tick_rot_chance(1.0) * 100.0)))


## Une attaque dit ce qu'elle rapporte à la mort quand un buff à charges est appris ; un
## sort, non.
func test_a_kill_trigger_shows_on_attacks_only() -> void:
	var book := Item.new(Character.CLASSES[Character.SWIFTBLADE]["manual"])
	book.manual.gain_experience(999999)
	_player.rack.seat(book)
	assert_true(_player.invest(Rack.CLASS_SLOT, "quick_strike"))
	assert_true(_player.invest(Rack.CLASS_SLOT, "bloodlust"))
	var frenzy: String = SkillCatalog.by_id("bloodlust").buffs[0].displayed_name()
	assert_eq(_values(_triggers("quick_strike"), frenzy), PackedStringArray(["100 %"]))
	assert_eq(_values(_triggers("bolt"), frenzy).size(), 0, "le tir est un sort")


## La fenêtre tient dans le cadrage au-dessus des jauges, **de l'autre côté du panneau**
## que la fiche : l'une ne cache jamais l'autre. Pour chaque compétence de chaque livre.
func test_the_details_stay_in_frame_beside_the_sheet() -> void:
	var base_screen := Vector2(Settings.base_size())
	var framing := Rect2(0.0, 0.0, base_screen.x, Hud.gauges_top(base_screen.y))
	var measured := 0
	for model: ItemBase in ItemCatalog.ALL + Character.class_manual_bases():
		if model.manual == null:
			continue
		var book := Item.new(model)
		book.manual.gain_experience(999999)
		_player.rack.remove(0)
		_player.study(book, 0)
		for cell: ManualCell in model.manual.cells:
			if cell.skill == null:
				continue
			var anchor := _panel._cell_rect(cell.position)
			var details := _panel._trigger_sheet(cell.skill)
			if details.lines.is_empty():
				continue
			var sheet := _panel._cell_sheet(book.manual, cell)
			var main := _panel._sheet_rect(anchor, _panel._sheet_height(sheet))
			var aside := _panel._sheet_rect(anchor, _panel._sheet_height(details), true)
			var on_screen := Rect2(aside.position + _panel.global_position, aside.size)
			assert_true(framing.encloses(on_screen), "« %s » : les détails sortent du cadrage" % cell.skill.id)
			assert_false(main.intersects(aside), "« %s » : les détails couvrent la fiche" % cell.skill.id)
			measured += 1
	assert_gt(measured, 20, "toutes les compétences qui touchent")


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


## Converti, le sort **est** de sa nouvelle nature (jalon 34) : ses dégâts de base s'y
## écrivent, et le nœud dit ce qu'il devient.
func test_the_sheet_announces_the_conversion() -> void:
	var book := _rich_book()
	for id in ["swift_bolt", "swift_bolt", "swift_bolt", "swift_bolt_glacial_bolt"]:
		assert_true(book.manual.invest(book.base.manual, id), "« %s »" % id)

	var base := _values(_sheet_of(book, "swift_bolt"), "de base")
	assert_eq(base.size(), 1)
	assert_true(base[0].ends_with("froid"), base[0])
	var node := book.base.manual.node_of("swift_bolt_glacial_bolt")
	var sheet := _panel._node_sheet(book.manual, book.base.manual.cell_of("swift_bolt"), node)
	assert_eq(_values(sheet.lines, "devient"), PackedStringArray(["Froid"]))


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
		PackedStringArray(["« %s » à 1" % branch.displayed_name()]),
		"le lien et ce qu'il demande"
	)

	book.manual.invest(book.base.manual, branch.id)
	assert_eq(
		_values(_panel._node_sheet(book.manual, cell, leaf).lines, "demande").size(), 0,
		"ouverte, elle ne demande plus rien"
	)


## Un nœud de conversion dit ce que la compétence devient : c'est ce mot-clé qui fait
## mordre l'équipement de la nature d'arrivée.
func test_a_node_sheet_announces_what_the_skill_becomes() -> void:
	var book := _rich_book()
	var cell := ItemCatalog.by_id("manual_weapons").manual.cell_of("heavy_strike")
	var burning_blade := cell.node_of("heavy_strike_burning_blade")
	var lines := _panel._node_sheet(book.manual, cell, burning_blade).lines

	assert_eq(_values(lines, "devient"), PackedStringArray(["Feu"]))


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
	assert_eq(
		_values(lines, "temps d'incantation"), PackedStringArray(["%.2f s" % cast.use_time]),
		"un sort sans recharge n'annonce que son geste"
	)
	assert_eq(_values(lines, "recharge"), PackedStringArray(), "et pas de recharge")
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
	for model: ItemBase in ItemCatalog.ALL + Character.class_manual_bases():
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


## Tout ce qui manque, pas le premier seulement : la compétence, puis chacun des liens de
## l'Hydre — un seul suffit, le second se lit « ou » (jalon 34).
func test_a_node_sheet_lists_everything_it_requires() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_fire"))
	book.manual.gain_experience(999999)
	_player.study(book)
	var cell := book.base.manual.cell_of("hell_snake")
	var hydra := cell.node_of("hell_snake_hydra")
	var lines := _panel._node_sheet(book.manual, cell, hydra).lines
	assert_eq(_values(lines, "demande").size(), 2, "la compétence et le premier lien")
	assert_eq(_values(lines, "ou").size(), 1, "et l'autre lien")
	assert_true(book.manual.invest(book.base.manual, "hell_snake"))
	lines = _panel._node_sheet(book.manual, cell, hydra).lines
	assert_eq(_values(lines, "demande"), PackedStringArray(["« Couvée » à 2"]))


## Ce qu'une transformation de l'arbre ne lit pas est écrit sur le nœud, avant qu'on paie :
## rien à traverser pour un météore.
func test_a_node_says_what_a_transformation_ignores() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_fire"))
	var cell := book.base.manual.cell_of("fireball")
	var piercing := _panel._node_sheet(book.manual, cell, cell.node_of("fireball_piercing"))
	assert_eq(_values(piercing.lines, "sans effet avec"), PackedStringArray(["Météore"]))
	var splits := _panel._node_sheet(book.manual, cell, cell.node_of("fireball_fragmentation"))
	assert_eq(_values(splits.lines, "sans effet avec").size(), 0, "les éclats jaillissent de l'impact")


## Ce qu'un échange coûte s'écrit en rouge ; ce qu'il donne, non.
func test_a_trade_writes_its_loss_in_red() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_fire"))
	_player.study(book)
	var cell := book.base.manual.cell_of("immolation")
	var phoenix := cell.node_of("immolation_phoenix")
	var lines := _panel._node_sheet(book.manual, cell, phoenix).lines
	var tints := {}
	for l in lines:
		if l.group == ManualPanel.Group.EFFECT:
			tints[l.label_of] = l.tint
	assert_eq(tints.values().count(ManualPanel.LOSS), 1, "la brûlure doublée, et elle seule")

