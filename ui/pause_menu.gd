extends CanvasLayer

## Le menu d'échappement, et les options qu'il abrite.
##
## PROCESS_MODE_ALWAYS et non WHEN_PAUSED : en mode « pendant la pause », le
## menu ne traiterait plus rien une fois le jeu repris, donc il ne pourrait plus
## jamais s'ouvrir. Il doit vivre dans les deux états.
##
## Échap sert de « retour » dans la forge, la carte de réglage et la scène de
## stress. Pas de conflit : ce sont des aperçus de débogage, ce menu n'existe que
## dans la zone jouée.

@onready var root: Control = $Root
@onready var menu: VBoxContainer = $Root/Center/Panel/Menu
@onready var options: VBoxContainer = $Root/Center/Panel/Options
@onready var bars_check: CheckBox = $Root/Center/Panel/Options/Bars
@onready var names_check: CheckBox = $Root/Center/Panel/Options/Names


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

	($Root/Center/Panel/Menu/Resume as Button).pressed.connect(close)
	($Root/Center/Panel/Menu/OptionsBtn as Button).pressed.connect(_show_options)
	($Root/Center/Panel/Menu/Retour as Button).pressed.connect(_retour_menu)
	($Root/Center/Panel/Menu/Quit as Button).pressed.connect(_quitter)
	($Root/Center/Panel/Options/Back as Button).pressed.connect(_show_menu)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	if (event as InputEventKey).keycode != KEY_ESCAPE:
		return

	# Échap depuis les options revient au menu plutôt que de tout fermer : sinon
	# on ressort du jeu sans savoir si le réglage a été pris en compte.
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


## Les deux sorties passent par le même signal : quitter le jeu et revenir au
## menu doivent écrire la partie, et un seul des deux chemins qui l'oublie suffit
## à perdre une session.
func _retour_menu() -> void:
	Game.sauvegarde_demandee.emit()
	# Dépausé avant de changer de scène : l'arbre reste en pause d'une scène à
	# l'autre, et l'écran de sélection naîtrait figé.
	get_tree().paused = false
	Game.goto_scene("res://ui/selection_personnage.tscn")


func _quitter() -> void:
	Game.sauvegarde_demandee.emit()
	get_tree().quit()


func _show_menu() -> void:
	menu.visible = true
	options.visible = false


func _show_options() -> void:
	menu.visible = false
	options.visible = true
