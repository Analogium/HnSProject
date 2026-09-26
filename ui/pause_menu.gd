extends CanvasLayer

## Le menu d'échappement et ses options. PROCESS_MODE_ALWAYS : en WHEN_PAUSED, il ne
## pourrait plus s'ouvrir une fois le jeu repris.

@onready var root: Control = $Root
@onready var menu: VBoxContainer = $Root/Center/Panel/Menu
@onready var options: VBoxContainer = $Root/Center/Panel/Options
@onready var bars_check: CheckBox = $Root/Center/Panel/Options/Bars
@onready var names_check: CheckBox = $Root/Center/Panel/Options/Names
@onready var taken_check: CheckBox = $Root/Center/Panel/Options/DamageTaken
@onready var dealt_check: CheckBox = $Root/Center/Panel/Options/DamageDealt
@onready var dps_check: CheckBox = $Root/Center/Panel/Options/DpsMeter
@onready var window_btn: Button = $Root/Center/Panel/Options/Window
## Libellé posé par le code, **dans la langue qu'il annonce**.
@onready var language_btn: Button = $Root/Center/Panel/Options/Language
@onready var keys: VBoxContainer = $Root/Center/Panel/Keys
## Une ligne par action, posées par le code depuis `Keybinds.ACTIONS` : la liste est
## déjà écrite là-bas, et seize nœuds dans la scène la répéteraient.
##
## **Deux colonnes** : seize lignes en une seule dépassent du cadre de 360 px, et le
## bouton « Retour » se retrouve hors de l'écran.
@onready var key_rows: HBoxContainer = $Root/Center/Panel/Keys/Rows

## L'action dont on attend la touche, vide hors capture. Un seul champ : deux lignes
## ne peuvent pas écouter en même temps.
var _capturing := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	options.visible = false
	keys.visible = false
	_build_key_rows()

	# La valeur est posée avant la connexion : dans l'autre sens, l'initialisation
	# émettrait un toggled et réécrirait le réglage avec lui-même.
	bars_check.button_pressed = Settings.show_health_bars
	bars_check.toggled.connect(func(on: bool) -> void: Settings.show_health_bars = on)
	names_check.button_pressed = Settings.show_affix_names
	names_check.toggled.connect(func(on: bool) -> void: Settings.show_affix_names = on)
	taken_check.button_pressed = Settings.damage_taken_visible
	taken_check.toggled.connect(func(on: bool) -> void: Settings.damage_taken_visible = on)
	dealt_check.button_pressed = Settings.damage_dealt_visible
	dealt_check.toggled.connect(func(on: bool) -> void: Settings.damage_dealt_visible = on)
	dps_check.button_pressed = Settings.dps_meter_visible
	dps_check.toggled.connect(func(on: bool) -> void: Settings.dps_meter_visible = on)
	_bind_opacity($Root/Center/Panel/Options/SpellOpacity, "spell_opacity")
	_bind_opacity($Root/Center/Panel/Options/EnemyOpacity, "enemy_attack_opacity")

	# Un bouton qui tourne : une liste déroulante dessinerait par-dessus le menu.
	window_btn.pressed.connect(_change_window)
	_refresh_window()

	# Une ronde, comme la fenêtre.
	language_btn.pressed.connect(_change_language)
	_refresh_language()

	($Root/Center/Panel/Menu/Resume as Button).pressed.connect(close)
	($Root/Center/Panel/Menu/OptionsBtn as Button).pressed.connect(_show_options)
	($Root/Center/Panel/Menu/Return as Button).pressed.connect(_back_to_menu)
	($Root/Center/Panel/Menu/Quit as Button).pressed.connect(_quit)
	($Root/Center/Panel/Options/Back as Button).pressed.connect(_show_menu)
	($Root/Center/Panel/Options/KeysBtn as Button).pressed.connect(_show_keys)
	($Root/Center/Panel/Keys/Back as Button).pressed.connect(_show_options)
	($Root/Center/Panel/Keys/Reset as Button).pressed.connect(func() -> void:
		Settings.reset_key_binds()
		_refresh_key_rows()
	)


## Un curseur de 0 à 100 sur un réglage de 0 à 1, et son pourcentage à côté.
func _bind_opacity(row: Control, setting: String) -> void:
	var slider: HSlider = row.get_node("Slider")
	var percent: Label = row.get_node("Percent")
	slider.value = Settings.get(setting) * 100.0
	percent.text = StatMod.percentage(slider.value)
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set(setting, value / 100.0)
		percent.text = StatMod.percentage(value)
	)


## Les deux libellés écrits par le code, que Godot ne retraduit pas. La garde : la
## notification arrive aussi à l'entrée dans l'arbre, avant les `@onready`.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_window()
		_refresh_language()
		_refresh_key_rows()


## En capture, la touche suivante est prise **ici**, avant tout le monde : dans
## `_unhandled_input`, un panneau ou la zone auraient répondu à l'ancienne action
## avant qu'on la remplace.
func _input(event: InputEvent) -> void:
	if _capturing.is_empty() or not _wants(event):
		return
	get_viewport().set_input_as_handled()
	# Échap annule : c'est la sortie de secours, et on ne la bind pas.
	if Keys.pressed_down(event) != KEY_ESCAPE:
		Settings.bind(_capturing, event)
	_capturing = ""
	_refresh_key_rows()


func _unhandled_input(event: InputEvent) -> void:
	if Keys.pressed_down(event) != KEY_ESCAPE:
		return

	# Échap depuis une sous-page revient d'un cran.
	if root.visible and keys.visible:
		_show_options()
	elif root.visible and options.visible:
		_show_menu()
	elif root.visible:
		close()
	else:
		open()

	get_viewport().set_input_as_handled()


func open() -> void:
	root.visible = true
	_show_menu()
	get_tree().paused = true


func close() -> void:
	root.visible = false
	get_tree().paused = false


## Les deux sorties passent par le même signal : chacune doit écrire la partie.
func _back_to_menu() -> void:
	Game.save_requested.emit()
	# Dépausé avant de changer de scène : l'arbre reste en pause d'une scène à
	# l'autre, et l'écran de sélection naîtrait figé.
	get_tree().paused = false
	Game.goto_scene("res://ui/character_select.tscn")


func _quit() -> void:
	Game.save_requested.emit()
	get_tree().quit()


## Relu sur le réglage, qui a pu être borné à l'écran.
func _change_window() -> void:
	Settings.cycle_scale()
	_refresh_window()


func _refresh_window() -> void:
	window_btn.text = Settings.current_label()


func _change_language() -> void:
	Settings.cycle_language()
	_refresh_language()


func _refresh_language() -> void:
	language_btn.text = Settings.current_language_label()


## Les trois pages sont exclusives, et chacune le dit **en entier** : `open()` repasse
## par le menu, et une page laissée visible s'afficherait par-dessus lui.
func _show_menu() -> void:
	_show_page(menu)


func _show_options() -> void:
	_show_page(options)


func _show_keys() -> void:
	_show_page(keys)
	_refresh_key_rows()


func _show_page(shown: Control) -> void:
	for page: Control in [menu, options, keys]:
		page.visible = page == shown
	# Quitter la page des touches finit la capture : la garder ouverte ferait manger
	# la première touche de la page suivante.
	_capturing = ""


# --------------------------------------------------------------------------
# L'onglet des touches
# --------------------------------------------------------------------------


## Un bouton par action, dans l'ordre de la table. Construit une fois : seul le
## libellé change ensuite.
func _build_key_rows() -> void:
	var columns := key_rows.get_children()
	var half := int(ceilf(Keybinds.ACTIONS.size() / float(columns.size())))
	var placed := 0
	for action: String in Keybinds.ACTIONS:
		var row := Button.new()
		row.name = action
		row.custom_minimum_size = Vector2(170.0, 0.0)
		row.add_theme_font_size_override("font_size", 9)
		row.pressed.connect(_capture.bind(action))
		columns[mini(placed / half, columns.size() - 1)].add_child(row)
		placed += 1
	_refresh_key_rows()


func _refresh_key_rows() -> void:
	for row: Button in _key_buttons():
		var action := String(row.name)
		# Les points de suspension ne se traduisent pas.
		var written := "…" if action == _capturing else Keybinds.key_label(action)
		row.text = "%s   %s" % [Keybinds.label_of(action), written]


## Les lignes des deux colonnes, dans l'ordre de la table.
func _key_buttons() -> Array[Node]:
	var out: Array[Node] = []
	for column: Node in key_rows.get_children():
		out.append_array(column.get_children())
	return out


func _capture(action: String) -> void:
	_capturing = action
	_refresh_key_rows()


## Ce qu'une capture accepte : une touche enfoncée, ou un des trois boutons de
## souris. Le relâchement du clic qui a ouvert la capture n'en est pas un — sans ce
## tri, l'action se rebinderait sur lui-même à l'instant où on la choisit.
func _wants(event: InputEvent) -> bool:
	if Keys.pressed_down(event) != KEY_NONE:
		return true
	var click := event as InputEventMouseButton
	return click != null and click.pressed and Keybinds.MOUSE_LABELS.has(click.button_index)
