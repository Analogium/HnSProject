extends GutTest

## L'objet au sol depuis le jalon 19 : son nom est son bouton. Ce qui est vérifié
## ici, c'est qu'on ne ramasse **que** par là — le contact ne prend plus rien — et
## que la prise de souris se rend, sans quoi le joueur ne frapperait plus jamais.


## Un réglage statique : éteint par un test qui échoue, il ferait échouer les
## suivants loin de sa cause.
func after_each() -> void:
	GroundItem.show_labels(true)


func _drop(player: Player, item: Item, at: Vector2) -> GroundItem:
	var ground := Node2D.new()
	add_child_autofree(ground)
	var drop := GroundItem.spawn(ground, at, item, player)
	await wait_process_frames(1)
	return drop


func _player() -> Player:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	return player


func _sword() -> Item:
	return Item.new(ItemCatalog.by_id("sword"), [
		RolledAffix.new("keen", 1, ItemAffixPool.by_id("keen").at_top(0)),
	])


func test_clicking_the_name_picks_it_up() -> void:
	var player := _player()
	var item := _sword()
	var drop: GroundItem = await _drop(player, item, Vector2(60, 0))

	assert_false(
		drop.clicked(drop.global_position), "sous l'étiquette, le clic ne prend rien"
	)
	assert_true(drop.clicked(drop.name_rect().get_center()), "sur le nom, si")
	await wait_process_frames(1)
	assert_false(is_instance_valid(drop), "et il quitte le sol")
	assert_eq(player.inventory.placed.size(), 1, "il est dans le sac")


## Le contact ne prend plus rien : marcher sur un objet le laisse au sol, quel que
## soit le temps qu'on y passe.
func test_walking_over_it_leaves_it_there() -> void:
	var player := _player()
	var drop: GroundItem = await _drop(player, _sword(), Vector2(60, 0))

	player.global_position = drop.global_position
	await wait_physics_frames(6)
	assert_true(is_instance_valid(drop), "toujours au sol")
	assert_eq(player.inventory.placed.size(), 0, "et le sac est vide")


## Sac plein, le clic échoue et l'objet reste cliquable : c'est ce qu'on veut après
## avoir lu son nom et décidé de faire de la place.
func test_a_full_bag_leaves_it_on_the_ground() -> void:
	var player := _player()
	var drop: GroundItem = await _drop(player, _sword(), Vector2(60, 0))
	while player.inventory.add(Item.new(ItemCatalog.by_id("sword"))):
		pass

	assert_false(drop.clicked(drop.name_rect().get_center()), "refusé")
	await wait_process_frames(1)
	assert_true(is_instance_valid(drop), "et il reste à cliquer")


## L'étiquette porte le nom composé, celui qu'on lit avant de décider.
func test_the_label_carries_the_composed_name() -> void:
	var player := _player()
	var item := _sword()
	var drop: GroundItem = await _drop(player, item, Vector2(60, 0))

	assert_gt(drop.name_rect().size.x, 0.0, "l'étiquette est mesurée")
	# Le nom décide de la largeur : un objet commun tient dans moins de place.
	var plain: GroundItem = await _drop(player, Item.new(ItemCatalog.by_id("sword")), Vector2(90, 0))
	assert_lt(plain.name_rect().size.x, drop.name_rect().size.x, "« %s » contre « %s »" % [
		plain.data.display_name(), item.display_name()
	])


## Un paquet mort au même endroit : les étiquettes montent jusqu'à ne plus se
## recouvrir, sinon le nom qu'on clique n'est pas celui qu'on lit.
func test_labels_never_cover_each_other() -> void:
	var player := _player()
	var ground := Node2D.new()
	add_child_autofree(ground)
	var drops: Array[GroundItem] = []
	for i in 8:
		# Serrés comme un paquet d'ennemis, pas empilés à l'identique : c'est le cas
		# qui se produit en jouant.
		drops.append(GroundItem.spawn(
			ground, Vector2(300.0 + i * 3.0, 260.0 + i * 2.0), _sword(), player
		))
	await wait_process_frames(2)

	for i in drops.size():
		for k in range(i + 1, drops.size()):
			assert_false(
				drops[i].name_rect().intersects(drops[k].name_rect()),
				"« %d » et « %d » se recouvrent" % [i, k]
			)
		assert_lt(
			drops[i].name_rect().end.y, drops[i].global_position.y,
			"et chacune reste au-dessus de son objet"
		)


## Une étiquette montée reste celle qu'on clique : le rectangle qui reçoit le clic
## est celui qui se dessine, pas la place naturelle.
func test_a_lifted_label_is_the_one_clicked() -> void:
	var player := _player()
	var ground := Node2D.new()
	add_child_autofree(ground)
	var under := GroundItem.spawn(ground, Vector2(300, 260), _sword(), player)
	var over := GroundItem.spawn(ground, Vector2(302, 260), _sword(), player)
	await wait_process_frames(2)

	var lifted: GroundItem = over if over.name_rect().position.y < under.name_rect().position.y else under
	assert_true(lifted.clicked(lifted.name_rect().get_center()), "le clic suit l'étiquette montée")


## Éteints, les noms disparaissent et plus rien ne se ramasse — l'étiquette est le
## bouton. Rallumés, ils se rangent à nouveau : c'est ce geste qui démêle une pile
## qui débordait de l'écran.
func test_the_labels_switch_off_and_on() -> void:
	var player := _player()
	var ground := Node2D.new()
	add_child_autofree(ground)

	GroundItem.show_labels(false)
	var under := GroundItem.spawn(ground, Vector2(300, 260), _sword(), player)
	var over := GroundItem.spawn(ground, Vector2(302, 260), _sword(), player)
	await wait_process_frames(2)
	assert_true(under.name_rect().intersects(over.name_rect()), "éteints, rien n'est rangé")
	assert_false(under.clicked(under.name_rect().get_center()), "et rien ne se ramasse")
	assert_eq(player.inventory.placed.size(), 0)

	GroundItem.show_labels(true)
	await wait_process_frames(2)
	assert_false(under.name_rect().intersects(over.name_rect()), "rallumés, ils se rangent")
	assert_true(under.clicked(under.name_rect().get_center()), "et redeviennent cliquables")


## Ramassé sous le curseur, l'objet emporterait la prise de souris qu'il tenait, et
## le joueur ne lancerait plus rien.
func test_it_gives_the_mouse_back_when_it_leaves() -> void:
	var player := _player()
	var drop: GroundItem = await _drop(player, _sword(), Vector2(60, 0))
	Game.grab_ui_input(drop, true)
	assert_true(Game.ui_grabs_input, "la souris est prise")

	drop.queue_free()
	await wait_process_frames(1)
	assert_false(Game.ui_grabs_input, "et rendue en partant")
