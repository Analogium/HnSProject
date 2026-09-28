extends GutTest

## La ville et ce qui y mène : on y arrive en se connectant, le portail d'en haut
## donne une zone, celui qu'on ouvre en zone ramène. Le marchand et le coffre ouvrent
## une seconde grille à côté du sac.

const SEED := 4242

var _zone: Node2D
var _id := ""


func before_each() -> void:
	Game.zone_level = 1
	Game.character = SaveStore.create("Citadine", 1)
	_id = Game.character.id
	# Un coffre à ce test : celui de la session survivrait d'un test à l'autre.
	Game.stash = Stash.new()
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	await wait_process_frames(2)
	# Le sac vide : la baguette de départ occupe sinon la case qu'on vise.
	_zone.player.inventory.clear()


func after_each() -> void:
	await wait_process_frames(1)
	SaveStore.delete(_id)
	DirAccess.remove_absolute(SaveStore.STASH)
	Game.character = null
	Game.stash = null


func _put(id: String, cell: Vector2i) -> Item:
	var item := Item.new(ItemCatalog.by_id(id))
	assert_true(_zone.player.inventory.place(item, cell), "« %s » posé en %s" % [id, cell])
	return item


## Un clic sur le corps d'un objet de la ville, là où il répond.
func _use(target: Interactable) -> void:
	assert_true(target.clicked(target.global_position + Interactable.HIT.get_center()), "le clic l'atteint")


func _center(cell: Vector2i, grid: Inventory = null) -> Vector2:
	return _zone.inventory._rect_of(cell, Vector2i.ONE, grid).get_center()


func test_a_character_arrives_in_town() -> void:
	assert_true(_zone.in_town)
	assert_true(_zone.town.visible)
	assert_eq(_zone.enemy_manager.enemies.size(), 0, "personne à combattre")
	assert_false(_zone.portal.visible, "rien à ouvrir en ville")
	for thing: Interactable in [_zone.merchant, _zone.stash_chest, _zone.town_gate]:
		assert_true(
			_zone.generator.is_walkable(MapGenerator.cell_at(thing.global_position)),
			"%s sur le sol de la ville" % thing.name
		)
	assert_true(_zone.generator.is_walkable(MapGenerator.cell_at(_zone.player.global_position)))


func test_the_gate_leads_to_a_new_zone() -> void:
	_use(_zone.town_gate)
	assert_false(_zone.in_town)
	assert_false(_zone.town.visible, "le marchand reste en ville")
	assert_gt(_zone.enemy_manager.enemies.size(), 0, "une zone peuplée")


func test_a_portal_opened_in_the_zone_leads_to_town() -> void:
	_zone.generate_zone(SEED)
	_zone.open_portal()
	assert_true(_zone.portal.visible)
	_use(_zone.portal)
	assert_true(_zone.in_town)
	assert_false(_zone.portal.visible, "il ne suit pas en ville")
	assert_true(_zone.way_back.visible, "le portail de retour attend en ville")
	_zone.open_portal()
	assert_false(_zone.portal.visible, "et ne s'ouvre pas en ville")


## Arrivé en se connectant, il n'y a nulle part où revenir.
func test_a_first_arrival_has_no_way_back() -> void:
	assert_false(_zone.way_back.visible)


## Le cœur du jalon : la zone quittée par un portail se retrouve telle quelle — sa carte,
## ses ennemis, son butin —, et l'on reparaît où l'on était.
func test_the_way_back_returns_to_the_same_zone() -> void:
	_zone.generate_zone(SEED)
	await wait_process_frames(2)
	var map: MapGenerator = _zone.generator
	var enemies: Array[Enemy] = _zone.enemy_manager.enemies.duplicate()
	var on_the_ground: Array[Node] = _zone.zone_loot.get_children()
	var at: Vector2 = _zone.player.global_position
	_zone.open_portal()
	_use(_zone.portal)

	assert_true(_zone.in_town)
	assert_eq(_zone.enemy_manager.process_mode, Node.PROCESS_MODE_DISABLED, "la zone est figée")
	assert_false(_zone.enemy_manager.visible, "et ne se voit pas depuis la ville")
	_zone.player.global_position = Vector2(200.0, 200.0)

	_use(_zone.way_back)
	assert_false(_zone.in_town)
	assert_same(_zone.generator, map, "la même carte")
	assert_eq(_zone.enemy_manager.enemies, enemies, "les mêmes ennemis")
	assert_eq(_zone.zone_loot.get_children(), on_the_ground, "le même butin au sol")
	assert_eq(_zone.enemy_manager.process_mode, Node.PROCESS_MODE_INHERIT, "qui vivent à nouveau")
	assert_true(_zone.enemy_manager.visible)
	assert_eq(_zone.player.global_position, at, "où l'on avait pris le portail")
	assert_false(_zone.portal.visible, "le portail s'est refermé derrière soi")


## Le sol de la zone se repeint à l'identique : même graine, même tuile à chaque case.
func test_the_zone_floor_comes_back_identical() -> void:
	_zone.generate_zone(SEED)
	var floor_layer: TileMapLayer = _zone.floor_layer
	var before := floor_layer.tile_map_data
	_zone.open_portal()
	_use(_zone.portal)
	_use(_zone.way_back)
	assert_eq(floor_layer.tile_map_data, before)


## Le portail d'en haut donne une zone neuve : celle qu'on avait laissée est abandonnée.
func test_the_gate_abandons_the_left_zone() -> void:
	_zone.generate_zone(SEED)
	var old: Enemy = _zone.enemy_manager.enemies[0]
	_zone.open_portal()
	_use(_zone.portal)
	_use(_zone.town_gate)
	assert_eq(_zone.enemy_manager.process_mode, Node.PROCESS_MODE_INHERIT)
	await wait_process_frames(1)
	assert_false(is_instance_valid(old), "ses ennemis sont partis")
	_zone.open_portal()
	_use(_zone.portal)
	_use(_zone.way_back)
	assert_false(_zone.in_town, "le retour mène à la nouvelle")


## Mourir en ville ne perd pas la zone qui attend.
func test_dying_in_town_keeps_the_left_zone() -> void:
	_zone.generate_zone(SEED)
	_zone.open_portal()
	_use(_zone.portal)
	_zone._respawn()
	assert_true(_zone.way_back.visible)


## Le branchement de l'action, pas seulement la fonction : c'est elle qu'on rebinde.
func test_the_action_opens_the_portal() -> void:
	_zone.generate_zone(SEED)
	var press := InputEventAction.new()
	press.action = "town_portal"
	press.pressed = true
	assert_true(_zone._zone_action(press))
	assert_true(_zone.portal.visible)


## Un portail d'une zone ne survit pas à la suivante.
func test_a_new_zone_closes_the_portal() -> void:
	_zone.generate_zone(SEED)
	_zone.open_portal()
	_zone.generate_zone(SEED + 1)
	assert_false(_zone.portal.visible)


## Mourir en ville y ramène, sans y faire naître d'ennemis.
func test_dying_in_town_stays_in_town() -> void:
	_zone._respawn()
	assert_true(_zone.in_town)
	assert_eq(_zone.enemy_manager.enemies.size(), 0)


## Sous le curseur, un objet de la ville prend le clic gauche : sinon on attaquerait
## le marchand en voulant lui parler.
func test_the_merchant_takes_the_left_click() -> void:
	Interactable.hovered = _zone.merchant
	assert_true(Interactable.takes_the_click("skill_1"))
	assert_false(Interactable.takes_the_click("skill_2"), "le clic droit reste au sort")
	Interactable.hovered = null


## Caché, rien ne répond : le marchand n'existe pas en zone.
func test_a_hidden_object_does_not_answer() -> void:
	_zone.generate_zone(SEED)
	var merchant: Interactable = _zone.merchant
	assert_false(merchant.clicked(merchant.global_position + Interactable.HIT.get_center()))


# --------------------------------------------------------------------------
# Le marchand
# --------------------------------------------------------------------------


func _to_the_stall(cell: Vector2i) -> void:
	var panel: InventoryPanel = _zone.inventory
	panel._take(_center(cell))
	panel._resolve(_center(Vector2i.ZERO, panel._storage), true)


func test_selling_removes_what_the_stall_holds() -> void:
	var ring := _put("ring", Vector2i(2, 1))
	_use(_zone.merchant)
	var panel: InventoryPanel = _zone.inventory
	assert_true(panel.visible, "le sac s'ouvre avec l'étal")
	assert_true(panel.storage_open())

	_to_the_stall(Vector2i(2, 1))
	assert_same(panel._storage.placed[0].data, ring, "posé sur l'étal")
	assert_eq(_zone.player.inventory.placed.size(), 0)

	assert_true(panel._storage_click(panel._sell_rect().get_center()), "le bouton répond")
	assert_eq(panel._storage.placed.size(), 0, "vendu")
	panel.toggle()
	assert_eq(_zone.player.inventory.placed.size(), 0, "et parti pour de bon")


func test_closing_the_stall_gives_back_what_was_not_sold() -> void:
	var ring := _put("ring", Vector2i(2, 1))
	_use(_zone.merchant)
	_to_the_stall(Vector2i(2, 1))
	_zone.inventory.toggle()
	assert_false(_zone.inventory.storage_open())
	assert_eq(_zone.player.inventory.placed.size(), 1, "revenu au sac")
	assert_same(_zone.player.inventory.placed[0].data, ring)


# --------------------------------------------------------------------------
# Le coffre
# --------------------------------------------------------------------------


func test_control_click_moves_between_the_bag_and_the_stash() -> void:
	var ring := _put("ring", Vector2i(2, 1))
	_use(_zone.stash_chest)
	var panel: InventoryPanel = _zone.inventory
	panel._transfer(_center(Vector2i(2, 1)))
	assert_eq(_zone.player.inventory.placed.size(), 0, "sorti du sac")
	assert_same(_zone.stash.tabs[0].placed[0].data, ring, "dans le premier onglet")

	panel._transfer(_center(_zone.stash.tabs[0].placed[0].cell, panel._storage))
	assert_same(_zone.player.inventory.placed[0].data, ring, "et retour")


func test_a_tab_is_chosen_and_kept_on_disk() -> void:
	_put("ring", Vector2i(2, 1))
	_use(_zone.stash_chest)
	var panel: InventoryPanel = _zone.inventory
	assert_true(panel._storage_click(panel._tab_rect(2).get_center()))
	assert_same(panel._storage, _zone.stash.tabs[2], "le troisième onglet est montré")
	panel._transfer(_center(Vector2i(2, 1)))

	_zone.save()
	var reread := SaveStore.read_stash()
	assert_false(reread.unreadable)
	assert_eq(reread.tabs[2].placed.size(), 1, "la bague est rangée sur le disque")
	assert_eq(SaveStore.read(_id).bag.placed.size(), 0, "et n'est plus dans le sac du personnage")


func test_leaving_town_closes_the_stash() -> void:
	_use(_zone.stash_chest)
	_use(_zone.town_gate)
	assert_false(_zone.inventory.visible)
	assert_false(_zone.inventory.storage_open())


## Un coffre illisible ne s'ouvre pas et n'est jamais écrit : le premier objet rangé
## écraserait tout ce que le fichier contient.
func test_an_unreadable_stash_neither_opens_nor_writes() -> void:
	_zone.stash.unreadable = true
	_use(_zone.stash_chest)
	assert_false(_zone.inventory.visible)
	_zone.save()
	assert_false(FileAccess.file_exists(SaveStore.STASH))


## La ville partage les coordonnées de la zone : un ennemi figé doit être **hors de la
## physique**, sinon un coup porté en ville le toucherait à travers la carte.
func test_a_frozen_enemy_cannot_be_struck() -> void:
	_zone.generate_zone(SEED)
	var enemy: Enemy = _zone.enemy_manager.enemies[0]
	await wait_physics_frames(2)
	var world: World2D = _zone.get_world_2d()
	assert_gt(Targets.in_circle(world, enemy.global_position, 8.0).size(), 0, "vivant, il se touche")
	_zone.open_portal()
	_use(_zone.portal)
	await wait_physics_frames(2)
	assert_eq(Targets.in_circle(world, enemy.global_position, 8.0).size(), 0, "figé, plus rien")


func _manuals(container: Node) -> int:
	var n := 0
	for child in container.get_children():
		var on_ground := child as GroundItem
		if on_ground != null and not on_ground.is_queued_for_deletion() and on_ground.data.manual != null:
			n += 1
	return n


## Le manuel de départ n'existe qu'une fois : laissé dans la zone quittée, il n'est pas
## reposé en ville — on en ramasserait deux.
func test_the_starting_manual_is_never_doubled() -> void:
	_zone.generate_zone(SEED)
	await wait_process_frames(2)
	assert_eq(_manuals(_zone.zone_loot), 1, "au sol de la zone")
	_zone.open_portal()
	_use(_zone.portal)
	await wait_process_frames(2)
	assert_eq(_manuals(_zone.town_loot), 0, "pas un second en ville")
	_use(_zone.way_back)
	assert_eq(_manuals(_zone.zone_loot), 1, "le premier attend toujours")


## Le sol de la ville se vide quand on en part : caché, son butin se cliquerait encore.
func test_leaving_town_empties_its_floor() -> void:
	await wait_process_frames(2)
	assert_eq(_manuals(_zone.town_loot), 1, "le manuel de l'arrivée")
	_use(_zone.town_gate)
	assert_eq(_manuals(_zone.town_loot), 0)
