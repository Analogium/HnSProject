extends GutTest

## Échap dans la zone : il ferme d'abord ce qui est ouvert, et n'ouvre le menu de
## pause que si rien ne l'était.
##
## Aucun test ne pilote un vrai clavier : l'appui passe par `_input` et
## `_unhandled_input` appelés à la main, dans l'ordre où Godot les distribue — la
## zone avant le menu, qui est son dernier enfant.

var _zone: Node2D
var _menu: CanvasLayer


func before_each() -> void:
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	_menu = _zone.get_node("PauseMenu")
	await wait_physics_frames(1)


func after_each() -> void:
	get_tree().paused = false


## Le menu ne reçoit la touche que si la zone n'a rien fermé. Décidé sur ce que rend
## `close_interfaces()` et non sur `is_input_handled()` : hors d'une vraie
## distribution, ce drapeau garde la valeur du test précédent, et le menu ne
## recevait jamais la touche.
func _escape() -> void:
	var key := InputEventKey.new()
	key.keycode = KEY_ESCAPE
	key.pressed = true
	if not _zone.close_interfaces():
		_menu._unhandled_input(key)


func test_escape_closes_open_panels_without_opening_the_menu() -> void:
	_zone.inventory.toggle()
	_zone.manuals.toggle()
	_zone.workbench.toggle()
	_escape()
	assert_false(_zone.inventory.visible, "le sac s'est fermé")
	assert_false(_zone.manuals.visible, "les manuels aussi")
	assert_false(_zone.workbench.visible, "et l'établi")
	assert_false(_menu.root.visible, "sans ouvrir le menu")
	assert_false(Game.ui_grabs_input, "et la souris est rendue au jeu")


## La fiche ne prend jamais la souris : c'est la visibilité qui compte, sinon Échap la
## laisserait ouverte.
func test_escape_closes_the_sheet() -> void:
	_zone.stats_panel.toggle()
	_escape()
	assert_false(_zone.stats_panel.visible)
	assert_false(_menu.root.visible)


func test_escape_closes_the_passive_tree() -> void:
	_zone.passive_tree.toggle()
	assert_true(Game.ui_grabs_input, "l'arbre prend la souris")
	_escape()
	assert_false(_zone.passive_tree.visible)
	assert_false(_menu.root.visible, "sans ouvrir le menu")
	assert_false(Game.ui_grabs_input, "et la rend")


func test_escape_without_panel_opens_the_menu() -> void:
	_escape()
	assert_true(_menu.root.visible)
