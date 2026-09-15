extends GutTest

## La barre des cinq cases : ce qu'on clique, ce qu'on y pose, et ce que les
## touches annoncent.

const SIZE := Vector2(154.0, 40.0)

var _bar: SkillBarPanel
var _player: Player


func before_each() -> void:
	_player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_player)
	_bar = SkillBarPanel.new()
	_bar.size = SIZE
	add_child_autofree(_bar)
	await wait_process_frames(1)
	_bar.bind(_player)


func _worked_book() -> Item:
	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	book.manual.gain_experience(999999)
	book.manual.invest(book.base.manual, "swift_bolt")
	book.manual.invest(book.base.manual, "chain_lightning")
	return book


func test_the_click_finds_the_drawn_cell() -> void:
	for i in SkillBar.SLOT_COUNT:
		_bar._track(_bar._slot_rect(i).get_center())
		assert_eq(_bar._hover, i, "case %d" % i)


## Les cinq cases tiennent dans la fenêtre qu'on leur donne : une sixième case
## dessinée hors du cadre ne se verrait pas, elle serait simplement incliquable.
func test_slots_fit_in_the_bar() -> void:
	var last_one: Rect2 = _bar._slot_rect(SkillBar.SLOT_COUNT - 1)
	assert_lte(last_one.end.x, SIZE.x, "la dernière case sort par la droite")
	assert_lte(last_one.end.y + SkillBarPanel.KEY_H, SIZE.y, "le libellé de touche déborde")


## Le libellé vient de la carte d'entrées, jamais d'une liste réécrite ici :
## deux vérités sur une touche, et la barre annonce un geste qui ne marche plus.
func test_labels_come_from_the_input_map() -> void:
	assert_eq(SkillBarPanel.key_label(0), "clic G")
	assert_eq(SkillBarPanel.key_label(1), "clic D")
	for i in [2, 3, 4]:
		assert_false(
			SkillBarPanel.key_label(i).is_empty(),
			"la case %d n'annonce aucune touche" % (i + 1)
		)


## Le menu propose de vider — l'entrée sans compétence —, puis ce qu'on peut poser.
func test_the_menu_offers_clearing_then_the_skills() -> void:
	var entries := _bar._entries()
	assert_eq(entries.size(), 3, "vider, le coup d'épée, le tir")
	assert_null(entries[0], "la première entrée vide la case")
	assert_eq(entries[1].id, SkillCatalog.ID_ATTACK)
	assert_eq(entries[2].id, SkillCatalog.ID_BOLT)

	_player.study(_worked_book())
	assert_eq(_bar._entries().size(), 5, "et les deux cases apprises")


## Le clic retombe sur l'entrée dessinée, **icône comprise** : c'est sur l'image
## qu'on vise d'abord, et une icône qui déborderait sur la voisine poserait la
## compétence d'à côté.
func test_the_menu_click_lands_on_the_drawn_entry() -> void:
	_player.study(_worked_book())
	_bar._open(2)
	for i in _bar._entries().size():
		var icon: Rect2 = _bar._entry_icon(i)
		assert_true(_bar._menu_rect(i).encloses(icon), "l'icône de l'entrée %d déborde" % i)
		for point in [
			_bar._menu_rect(i).get_center(), icon.get_center(),
			icon.position + Vector2.ONE, icon.end - Vector2.ONE,
		]:
			_bar._track(point)
			assert_eq(_bar._hover_menu, i, "entrée %d, point %s" % [i, point])


## Le haut de la barre à l'écran, lu dans la scène de zone : elle est ancrée en bas
## à droite, et c'est de là que le menu monte.
func _bar_top_in_zone() -> float:
	var state := (load("res://world/zone.tscn") as PackedScene).get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != "Bar":
			continue
		var properties := {}
		for j in state.get_node_property_count(i):
			properties[state.get_node_property_name(i, j)] = state.get_node_property_value(i, j)
		return (
			float(properties.get("anchor_top", 0.0)) * float(Settings.base_size().y)
			+ float(properties["offset_top"])
		)
	return -INF


## Le menu monte au-dessus de la barre et tient dans le cadrage, livre entier
## appris : une entrée coupée par le haut de l'écran serait une compétence qu'on
## ne pose jamais.
func test_the_menu_stays_in_frame() -> void:
	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	book.manual.gain_experience(999999)
	for skill in book.base.manual.skills():
		book.manual.invest(book.base.manual, skill.id)
	_player.study(book)
	var entries := _bar._entries().size()
	assert_eq(entries, 3 + book.base.manual.skills().size(), "tout le livre est proposé")

	var top := _bar_top_in_zone() + _bar._menu_frame(entries).position.y
	assert_gte(top, 0.0, "le menu sort par le haut de l'écran")


func test_opening_and_closing_the_menu_takes_and_returns_the_mouse() -> void:
	_bar._open(2)
	assert_eq(_bar._menu, 2)
	assert_true(Game.ui_grabs_input, "le menu prend la souris")
	_bar._close()
	assert_eq(_bar._menu, -1)
	assert_false(Game.ui_grabs_input, "et la rend en se refermant")


func test_assign_places_the_chosen_skill() -> void:
	_bar._open(4)
	# Entrée 0 : vider. Entrée 1 : la première compétence disponible.
	_bar._assign(1)
	assert_eq(_player.bar.id_of(4), SkillCatalog.ID_ATTACK)


## Une compétence déjà posée ailleurs se **déplace** : deux cases qui lancent la
## même chose sont deux touches perdues.
func test_an_already_placed_skill_moves() -> void:
	assert_eq(_player.bar.id_of(0), SkillCatalog.ID_ATTACK, "la barre de départ")
	_bar._open(3)
	_bar._assign(1)   # le coup d'épée, déjà en case 0
	assert_eq(_player.bar.id_of(3), SkillCatalog.ID_ATTACK, "il est arrivé ici")
	assert_eq(_player.bar.id_of(0), "", "et il a quitté sa case d'avant")


func test_the_first_entry_clears_the_slot() -> void:
	_bar._open(0)
	_bar._assign(0)
	assert_eq(_player.bar.id_of(0), "", "la case est vide")


## Le dessin traverse ses états sans se plaindre : une case vide, une case
## chargée, une recharge en cours et un menu ouvert.
func test_drawing_goes_through_its_states() -> void:
	_player.study(_worked_book())
	_player.bar.put(2, "swift_bolt")
	_player.cast_slot(1)
	_bar._open(2)
	_bar._track(_bar._menu_rect(1).get_center())
	_bar.queue_redraw()
	await wait_process_frames(1)
	assert_gt(_player._recharges[1], 0.0, "une recharge est bien en cours")


## La barre ne répond que des clics tombés sur elle — sauf le menu ouvert, qui
## est modal et se referme par un clic au-dehors.
func test_the_bar_only_takes_its_clicks() -> void:
	assert_true(_bar._owns_click(_bar._slot_rect(0).get_center()))
	assert_false(_bar._owns_click(Vector2(-40.0, 10.0)), "à gauche de la barre")

	_bar._open(0)
	assert_true(_bar._owns_click(Vector2(-40.0, 10.0)), "le menu ouvert prend l'écran")
