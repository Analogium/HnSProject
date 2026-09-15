extends CanvasLayer

## Le menu d'échappement et ses options. PROCESS_MODE_ALWAYS : en WHEN_PAUSED, il ne
## pourrait plus s'ouvrir une fois le jeu repris.

@onready var root: Control = $Root
@onready var menu: VBoxContainer = $Root/Center/Panel/Menu
@onready var options: VBoxContainer = $Root/Center/Panel/Options
@onready var bars_check: CheckBox = $Root/Center/Panel/Options/Bars
@onready var names_check: CheckBox = $Root/Center/Panel/Options/Names
@onready var subis_check: CheckBox = $Root/Center/Panel/Options/DegatsSubis
@onready var infliges_check: CheckBox = $Root/Center/Panel/Options/DegatsInfliges
@onready var fenetre_btn: Button = $Root/Center/Panel/Options/Fenetre
## Libellé posé par le code, **dans la langue qu'il annonce**.
@onready var langue_btn: Button = $Root/Center/Panel/Options/Langue


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
	subis_check.button_pressed = Settings.degats_subis_visibles
	subis_check.toggled.connect(func(on: bool) -> void: Settings.degats_subis_visibles = on)
	infliges_check.button_pressed = Settings.degats_infliges_visibles
	infliges_check.toggled.connect(func(on: bool) -> void: Settings.degats_infliges_visibles = on)

	# Un bouton qui tourne : une liste déroulante dessinerait par-dessus le menu.
	fenetre_btn.pressed.connect(_changer_fenetre)
	_rafraichir_fenetre()

	# Une ronde, comme la fenêtre.
	langue_btn.pressed.connect(_changer_langue)
	_rafraichir_langue()

	($Root/Center/Panel/Menu/Resume as Button).pressed.connect(close)
	($Root/Center/Panel/Menu/OptionsBtn as Button).pressed.connect(_show_options)
	($Root/Center/Panel/Menu/Retour as Button).pressed.connect(_retour_menu)
	($Root/Center/Panel/Menu/Quit as Button).pressed.connect(_quitter)
	($Root/Center/Panel/Options/Back as Button).pressed.connect(_show_menu)


## Les deux libellés écrits par le code, que Godot ne retraduit pas. La garde : la
## notification arrive aussi à l'entrée dans l'arbre, avant les `@onready`.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_rafraichir_fenetre()
		_rafraichir_langue()


func _unhandled_input(event: InputEvent) -> void:
	if Touches.enfoncee(event) != KEY_ESCAPE:
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
func _retour_menu() -> void:
	Game.sauvegarde_demandee.emit()
	# Dépausé avant de changer de scène : l'arbre reste en pause d'une scène à
	# l'autre, et l'écran de sélection naîtrait figé.
	get_tree().paused = false
	Game.goto_scene("res://ui/selection_personnage.tscn")


func _quitter() -> void:
	Game.sauvegarde_demandee.emit()
	get_tree().quit()


## Relu sur le réglage, qui a pu être borné à l'écran.
func _changer_fenetre() -> void:
	Settings.cycler_echelle()
	_rafraichir_fenetre()


func _rafraichir_fenetre() -> void:
	fenetre_btn.text = Settings.libelle_courant()


func _changer_langue() -> void:
	Settings.cycler_langue()
	_rafraichir_langue()


func _rafraichir_langue() -> void:
	langue_btn.text = Settings.libelle_de_langue_courante()


func _show_menu() -> void:
	menu.visible = true
	options.visible = false


func _show_options() -> void:
	menu.visible = false
	options.visible = true
