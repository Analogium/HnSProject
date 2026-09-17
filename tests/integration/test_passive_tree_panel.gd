extends GutTest

## Le panneau de l'arbre : un clic prend là où le nœud est dessiné, un glissement
## déplace la vue sans rien prendre, un clic droit reprend.

var _p: Player
var _panel: PassiveTreePanel


func before_each() -> void:
	_p = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_p)
	_panel = PassiveTreePanel.new()
	add_child_autofree(_panel)
	_panel.size = Vector2(640, 360)
	_panel.bind(_p)
	_panel.toggle()
	_p.level = 5
	await wait_physics_frames(1)


func after_each() -> void:
	Game.grab_ui_input(_panel, false)


func _button(at: Vector2, pressed: bool, index := MOUSE_BUTTON_LEFT) -> void:
	var e := InputEventMouseButton.new()
	e.button_index = index
	e.pressed = pressed
	e.position = at
	_panel._gui_input(e)


func _move(from: Vector2, to: Vector2) -> void:
	var e := InputEventMouseMotion.new()
	e.position = to
	e.relative = to - from
	_panel._gui_input(e)


func _at(id: String) -> Vector2:
	return _panel.screen_position(_p.passive_tree.node(id))


func test_a_click_takes_the_drawn_node() -> void:
	_button(_at("int_1"), true)
	_button(_at("int_1"), false)
	assert_eq(_p.passives, PackedStringArray(["int_1"]))


## `screen_position()` et `node_at()` doivent rester d'accord à chaque cran : au large,
## une tolérance restée en pixels du cran normal prendrait le voisin.
func test_a_click_finds_its_node_at_each_zoom() -> void:
	_panel.zoom_by(-5)
	for step in PassiveTreePanel.ZOOMS.size():
		for id in ["int_1", "spells_4", "storm_mind"]:
			assert_eq(_panel.node_at(_at(id)).id, id, "cran %d" % step)
		_panel.zoom_by(1)


func test_the_zoom_keeps_the_center_of_the_frame() -> void:
	var from := _at("int_1")
	_button(from, true)
	_move(from, from + Vector2(40, 0))
	_button(from + Vector2(40, 0), false)
	var center := _panel.size * 0.5
	var before := _at("storm_mind") - center
	_panel.zoom_by(1)
	assert_almost_eq(_at("storm_mind") - center, before * 1.5, Vector2(0.01, 0.01))


func test_a_drag_moves_the_view_and_takes_nothing() -> void:
	var from := _at("int_1")
	_button(from, true)
	_move(from, from + Vector2(40, 0))
	_button(from + Vector2(40, 0), false)
	assert_eq(_p.passives.size(), 0)
	assert_eq(_at("int_1"), from + Vector2(40, 0), "la vue a suivi")


func test_a_right_click_releases() -> void:
	_p.take_passive("int_1")
	_button(_at("int_1"), true, MOUSE_BUTTON_RIGHT)
	assert_eq(_p.passives.size(), 0)
