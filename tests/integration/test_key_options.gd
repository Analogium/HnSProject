extends GutTest

## L'onglet des touches : cliquer une action, appuyer, et le jeu répond à la
## nouvelle touche. Aucun test ne pilote un vrai clavier ; l'appui passe par
## `_input` appelé à la main, comme partout ailleurs dans cette campagne.

var _zone: Zone
var _menu: CanvasLayer


func before_each() -> void:
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	_menu = _zone.get_node("PauseMenu")
	await wait_physics_frames(1)


## La table du moteur et le disque sont globaux : rendus dans l'état où on les a
## trouvés, sinon l'échec voyage jusqu'au test suivant.
func after_each() -> void:
	Settings.control_mode = Keybinds.MOUSE
	Settings.reset_key_binds()
	Settings.control_mode = Keybinds.KEYBOARD
	Settings.reset_key_binds()
	get_tree().paused = false


func _press(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = code
	key.pressed = true
	return key


## Une ligne par action, dans l'ordre de la table : la liste n'est écrite qu'une
## fois, et l'onglet la suit.
func test_the_tab_shows_one_row_per_action() -> void:
	_menu.open()
	_menu._show_keys()
	assert_true(_menu.keys.visible, "l'onglet est ouvert")
	var rows: Array = _menu._key_buttons()
	assert_eq(rows.size(), Keybinds.ACTIONS.size(), "une ligne par action, colonnes confondues")
	var first: Button = rows[0]
	assert_string_contains(first.text, Keybinds.label_of(String(first.name)))
	assert_string_contains(first.text, Keybinds.key_label(String(first.name)))


## Le geste entier : la ligne, la touche, et la zone qui répond à la nouvelle.
func test_a_captured_key_rebinds_the_action() -> void:
	_menu.open()
	_menu._show_keys()
	_menu._capture("panel_inventory")
	_menu._input(_press(KEY_J))

	assert_eq(Settings.key_binds.get("panel_inventory", ""), "key:%d" % KEY_J, "le choix est écrit")
	assert_eq(Keybinds.key_label("panel_inventory"), "J", "la table du moteur suit")

	_menu.close()
	_zone._unhandled_input(_press(KEY_J))
	assert_true(_zone.inventory.visible, "et la zone ouvre le sac sur la nouvelle touche")
	_zone._unhandled_input(_press(KEY_I))
	assert_true(_zone.inventory.visible, "l'ancienne ne fait plus rien")


## Échap sort de la capture sans rien changer : c'est la sortie de secours, et on ne
## la bind pas — une action qui l'aurait mangée enfermerait le joueur.
func test_escape_cancels_the_capture() -> void:
	_menu.open()
	_menu._show_keys()
	_menu._capture("panel_inventory")
	_menu._input(_press(KEY_ESCAPE))

	assert_eq(_menu._capturing, "", "la capture est finie")
	assert_false(Settings.key_binds.has("panel_inventory"), "et rien n'a été écrit")
	assert_eq(Keybinds.key_label("panel_inventory"), "I")


## Le relâchement du clic qui ouvre la capture n'est pas la touche voulue : sans ce
## tri, l'action se rebinderait sur lui-même à l'instant où on la choisit.
func test_a_mouse_release_is_not_a_choice() -> void:
	_menu.open()
	_menu._show_keys()
	_menu._capture("panel_inventory")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	_menu._input(release)
	assert_eq(_menu._capturing, "panel_inventory", "on attend toujours")

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_MIDDLE
	click.pressed = true
	_menu._input(click)
	assert_eq(Keybinds.key_label("panel_inventory"), Texts.t("clic M"), "un bouton se bind")


## « Rétablir » rend tout à `project.godot`, y compris ce qu'un échange avait
## déplacé.
func test_reset_gives_every_key_back() -> void:
	Settings.bind("panel_inventory", _press(KEY_C))
	assert_eq(Keybinds.key_label("panel_character"), "I", "l'échange a eu lieu")

	Settings.reset_key_binds()
	assert_eq(Keybinds.key_label("panel_inventory"), "I")
	assert_eq(Keybinds.key_label("panel_character"), "C")
	assert_eq(Settings.key_binds, {}, "et plus rien n'est écrit dans les réglages")


## Jalon 54 : un onglet par façon de jouer. Le choisir la met en place, avec ses touches ;
## chacune garde les siennes, et revenir à l'autre les retrouve.
func test_each_control_mode_keeps_its_own_keys() -> void:
	_menu.open()
	_menu._show_keys()
	_menu._choose_mode(Keybinds.MOUSE)
	assert_eq(Settings.control_mode, Keybinds.MOUSE, "l'onglet choisit la façon de jouer")
	var rows: Array = _menu._key_buttons()
	assert_eq(rows.size(), Keybinds.actions_of(Keybinds.MOUSE).size() + 1, "les actions, plus le déplacement")
	assert_true((rows[0] as Button).disabled, "le déplacement au clic gauche ne se change pas")
	_menu._capture("skill_2")
	_menu._input(_press(KEY_J))
	assert_eq(Keybinds.key_label("skill_2"), "J")

	_menu._choose_mode(Keybinds.KEYBOARD)
	assert_eq(_menu._key_buttons().size(), Keybinds.ACTIONS.size(), "ZQSD revient")
	assert_eq(Keybinds.key_label("skill_2"), Texts.t("clic D"), "avec ses touches à lui")
	assert_eq(Settings.key_binds, {}, "rien n'y a été écrit")

	_menu._choose_mode(Keybinds.MOUSE)
	assert_eq(Keybinds.key_label("skill_2"), "J", "et la souris retrouve les siennes")
