extends GutTest

## La géométrie du panneau : ce qu'on voit et ce qu'on clique doivent être au
## même endroit.
##
## Ces tests existent parce que la fenêtre a changé de largeur et que ses deux
## grilles sont maintenant centrées, chacune de son côté. Un décalage entre le
## dessin et le calcul de la case sous le curseur ne se voit pas — on croit
## simplement que le clic « n'a pas marché ».

var _panel: InventoryPanel
var _player: Player


func before_each() -> void:
	_player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_player)
	# Le panneau vit dans la scène de zone et n'a pas de scène propre : on monte
	# le Control et le Label de titre que son @onready attend.
	_panel = InventoryPanel.new()
	var title_text := Label.new()
	title_text.name = "Title"
	_panel.add_child(title_text)
	add_child_autofree(_panel)
	await wait_process_frames(1)
	_panel.bind(_player)


## Le cœur d'une case du sac retombe sur cette case. Sans ça, prendre un objet
## en attraperait un autre — ou rien.
func test_the_click_finds_the_drawn_cell() -> void:
	for cell in [Vector2i(0, 0), Vector2i(4, 2), Vector2i(9, 4), Vector2i(8, 2)]:
		var center: Vector2 = _panel._rect_of(cell, Vector2i.ONE).get_center()
		assert_eq(_panel._cell_at(center), cell, "case %s" % cell)


## Le sac est centré dans une fenêtre plus large que lui : un point à gauche de
## son bord n'est plus la colonne 0, c'est le dehors.
func test_outside_the_bag_gives_no_valid_cell() -> void:
	var inside := _panel._rect_of(Vector2i(0, 0), Vector2i.ONE)
	assert_eq(_panel._cell_at(inside.position - Vector2(4.0, 0.0)).x, -1, "à gauche du sac")
	assert_lt(_panel._cell_at(Vector2(0.0, 0.0)).y, 0, "au-dessus du sac")


func test_the_click_finds_the_drawn_slot() -> void:
	for i in EquipmentSlots.count():
		var center: Vector2 = _panel._slot_rect(i).get_center()
		assert_eq(
			_panel._slot_at(center), i,
			"emplacement %d (%s)" % [i, EquipmentSlots.ids()[i]]
		)


## Le portrait n'est pas un emplacement : cliquer dessus ne doit rien attraper.
func test_the_portrait_is_not_clickable() -> void:
	assert_eq(_panel._slot_at(_panel._doll_area_rect().get_center()), -1)


## Les deux grilles tiennent dans le panneau, et le panneau dans le cadrage.
func test_the_panel_stays_in_frame() -> void:
	var size_value: Vector2 = _panel._panel_size()
	assert_lte(size_value.x, 640.0, "width")
	assert_lte(size_value.y, 360.0, "hauteur : la fenêtre déborderait de l'écran")
	assert_gte(size_value.x, _panel._equip_size().x, "la grille du personnage tient dedans")


## Le sac ouvert ne doit pas rendre sourds les panneaux ouverts à côté : il ne
## répond que des clics tombés sur lui. L'objet **tenu à la main** fait
## exception — c'est en le lâchant au-dehors qu'on le jette au sol.
func test_the_bag_only_takes_its_clicks() -> void:
	var inside: Vector2 = _panel._rect_of(Vector2i(0, 0), Vector2i.ONE).get_center()
	assert_true(_panel._owns_click(inside))
	assert_false(_panel._owns_click(Vector2(-40.0, 20.0)), "à gauche du sac")

	_panel._held = Item.new(ItemCatalog.by_id("sword"))
	assert_true(
		_panel._owns_click(Vector2(-40.0, 20.0)),
		"un objet en main possède le geste jusqu'au lâcher"
	)


# --------------------------------------------------------------------------
# Déplacer, échanger, jeter
# --------------------------------------------------------------------------


func _put(id: String, cell: Vector2i) -> Item:
	var item := Item.new(ItemCatalog.by_id(id))
	assert_true(_player.inventory.place(item, cell), "« %s » posé en %s" % [id, cell])
	return item


## Le geste au centre d'une case : prendre là, relâcher ici.
func _drag(from: Vector2i, to: Vector2i) -> void:
	_panel._take(_panel._rect_of(from, Vector2i.ONE).get_center())
	_panel._resolve(_panel._rect_of(to, Vector2i.ONE).get_center(), true)


## Une case libre : l'objet s'y pose, et rien d'autre ne bouge.
func test_an_item_moves_to_a_free_cell() -> void:
	var ring := _put("ring", Vector2i(0, 0))
	_drag(Vector2i(0, 0), Vector2i(5, 3))
	assert_eq(_player.inventory.index_at(Vector2i(0, 0)), Inventory.EMPTY, "l'ancienne case est libre")
	assert_same(_player.inventory.placed[_player.inventory.index_at(Vector2i(5, 3))].data, ring)
	assert_null(_panel._held, "et la main est vide")


## Deux objets de même taille permutent : chacun prend la place de l'autre, et la
## main reste vide. C'est le geste courant — ranger son sac.
func test_two_items_of_the_same_size_swap() -> void:
	var ring := _put("ring", Vector2i(0, 0))
	var other := _put("signet_ring", Vector2i(5, 3))
	_drag(Vector2i(0, 0), Vector2i(5, 3))

	var bag := _player.inventory
	assert_same(bag.placed[bag.index_at(Vector2i(5, 3))].data, ring, "l'anneau est arrivé")
	assert_same(bag.placed[bag.index_at(Vector2i(0, 0))].data, other, "et l'autre a pris sa place")
	assert_null(_panel._held, "la main est vide")


## Tailles différentes : l'échange tient quand même, tant que le délogé entre dans
## la place que l'autre vient de quitter.
func test_two_items_of_different_sizes_still_swap() -> void:
	var ring := _put("ring", Vector2i(0, 0))
	var chest := _put("breastplate", Vector2i(4, 0))
	_drag(Vector2i(4, 0), Vector2i(0, 0))

	var bag := _player.inventory
	assert_same(bag.placed[bag.index_at(Vector2i(0, 0))].data, chest, "le plastron s'est posé")
	assert_same(bag.placed[bag.index_at(Vector2i(4, 0))].data, ring, "et l'anneau a pris sa place")
	assert_null(_panel._held, "la main est vide")


## La place quittée ne suffit pas au délogé — un voisin la borde : il passe en main
## plutôt que d'être perdu, et c'est au joueur de lui trouver un coin.
func test_an_item_that_no_longer_fits_comes_back_to_the_hand() -> void:
	var ring := _put("ring", Vector2i(0, 0))
	# Le plastron fait 2 × 3 : ce voisin lui interdit la case que l'anneau quitte.
	_put("signet_ring", Vector2i(1, 0))
	var chest := _put("breastplate", Vector2i(4, 0))
	_drag(Vector2i(0, 0), Vector2i(4, 0))

	var bag := _player.inventory
	assert_same(bag.placed[bag.index_at(Vector2i(4, 0))].data, ring, "l'anneau s'est posé")
	assert_same(_panel._held, chest, "et le plastron est en main")
	assert_eq(bag.index_at(Vector2i(0, 0)), Inventory.EMPTY, "la case quittée reste libre")


## Deux objets sous la pose : on ne déloge pas deux objets pour en poser un. Rien ne
## bouge, et l'objet tenu retourne d'où il vient.
func test_nothing_moves_when_two_items_are_in_the_way() -> void:
	var chest := _put("breastplate", Vector2i(4, 0))
	_put("ring", Vector2i(0, 0))
	_put("signet_ring", Vector2i(1, 0))
	_drag(Vector2i(4, 0), Vector2i(0, 0))

	var bag := _player.inventory
	assert_eq(bag.placed.size(), 3, "les trois sont toujours là")
	assert_same(bag.placed[bag.index_at(Vector2i(4, 0))].data, chest, "le plastron est rentré")
	assert_null(_panel._held)


## Ctrl + clic droit : au sol, sans passer par la main ni par un emplacement.
func test_control_right_click_drops_to_the_ground() -> void:
	var ring := _put("ring", Vector2i(2, 1))
	var dropped: Array[Item] = []
	_panel.drop_requested.connect(func(item: Item) -> void: dropped.append(item))

	_panel._hover = Vector2i(2, 1)
	_panel._hover_slot = -1
	_panel._right_click(true)

	assert_eq(dropped, [ring] as Array[Item], "il est parti au sol")
	assert_eq(_player.inventory.placed.size(), 0, "et il a quitté le sac")
	assert_null(_panel._held, "sans passer par la main")


## Le branchement, et pas seulement la fonction : c'est `ctrl_pressed` de
## l'événement qui décide, et une modification perdue en chemin ferait simplement
## équiper au lieu de jeter — sans rien signaler.
func test_the_control_modifier_travels_with_the_event() -> void:
	_panel.visible = true
	var ring := _put("ring", Vector2i(2, 1))
	var dropped: Array[Item] = []
	_panel.drop_requested.connect(func(item: Item) -> void: dropped.append(item))

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_RIGHT
	click.pressed = true
	click.ctrl_pressed = true
	# En coordonnées de l'écran : c'est ce que reçoit `_input`, et `make_input_local`
	# les ramène dans le panneau — le chemin qu'on vient vérifier.
	click.position = (
		_panel.get_global_transform_with_canvas()
		* _panel._rect_of(Vector2i(2, 1), Vector2i.ONE).get_center()
	)
	_panel._input(click)

	assert_eq(dropped, [ring] as Array[Item], "Ctrl a bien voyagé jusqu'au geste")


## Sans Ctrl, le clic droit équipe : le raccourci ne doit pas manger le geste
## d'avant.
func test_right_click_without_control_still_equips() -> void:
	var ring := _put("ring", Vector2i(2, 1))
	_panel._hover = Vector2i(2, 1)
	_panel._hover_slot = -1
	_panel._right_click(false)

	assert_eq(_player.inventory.placed.size(), 0, "il a quitté le sac")
	assert_same(_player.equipped("ring_left"), ring, "pour le doigt")
