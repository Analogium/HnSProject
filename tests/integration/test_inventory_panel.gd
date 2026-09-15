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
