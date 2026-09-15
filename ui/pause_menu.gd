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
@onready var window_btn: Button = $Root/Center/Panel/Options/Window
## Libellé posé par le code, **dans la langue qu'il annonce**.
@onready var language_btn: Button = $Root/Center/Panel/Options/Language


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	options.visible = false

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


## Les deux libellés écrits par le code, que Godot ne retraduit pas. La garde : la
## notification arrive aussi à l'entrée dans l'arbre, avant les `@onready`.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_window()
		_refresh_language()


func _unhandled_input(event: InputEvent) -> void:
	if Keys.pressed_down(event) != KEY_ESCAPE:
		return

	# Échap depuis les options revient au menu.
	if root.visible and options.visible:
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


func _show_menu() -> void:
	menu.visible = true
	options.visible = false


func _show_options() -> void:
	menu.visible = false
	options.visible = true
