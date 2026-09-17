extends GutTest

## Ce que l'ordre des enfants de `UI` décide, et que rien d'autre ne dit : l'arbre de
## passifs peint un fond plein sur tout l'écran, donc tout panneau ouvert par-dessus
## doit être **après lui** dans la scène. Ouverts ensemble, ils se superposent.

var _zone: Node2D


func before_each() -> void:
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	await wait_physics_frames(1)


func test_the_passive_tree_is_drawn_under_the_other_panels() -> void:
	var under: int = _zone.passive_tree.get_index()
	for panel: Control in [_zone.inventory, _zone.stats_panel, _zone.manuals, _zone.workbench]:
		assert_gt(panel.get_index(), under, "%s passerait sous l'arbre" % panel.name)


func test_the_panels_open_together_over_the_tree() -> void:
	for panel: Control in [_zone.passive_tree, _zone.inventory, _zone.stats_panel, _zone.manuals]:
		panel.toggle()
	for panel: Control in [_zone.passive_tree, _zone.inventory, _zone.stats_panel, _zone.manuals]:
		assert_true(panel.visible, "%s s'est refermé" % panel.name)


## Le compte de points non placés du bandeau : il suit le niveau **et** les prises.
func test_the_hud_counts_the_unspent_tree_points() -> void:
	var player: Player = _zone.player
	assert_eq(_zone.hud._points_left, 0, "niveau 1, aucun point")

	player.gain_xp(player.xp_to_next)
	await wait_physics_frames(1)
	assert_eq(_zone.hud._points_left, 1, "un niveau, un point")

	player.take_passive("int_1")
	await wait_physics_frames(1)
	assert_eq(_zone.hud._points_left, 0, "le point placé ne se compte plus")
