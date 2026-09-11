extends CanvasLayer

## Le menu d'échappement, et les options qu'il abrite.
##
## PROCESS_MODE_ALWAYS et non WHEN_PAUSED : en mode « pendant la pause », le
## menu ne traiterait plus rien une fois le jeu repris, donc il ne pourrait plus
## jamais s'ouvrir. Il doit vivre dans les deux états.

@onready var root: Control = $Root
@onready var menu: VBoxContainer = $Root/Center/Panel/Menu
@onready var options: VBoxContainer = $Root/Center/Panel/Options
@onready var bars_check: CheckBox = $Root/Center/Panel/Options/Bars
@onready var names_check: CheckBox = $Root/Center/Panel/Options/Names
@onready var fenetre_btn: Button = $Root/Center/Panel/Options/Fenetre
## Le bouton de langue. Son libellé n'est pas écrit dans la scène : il est
## toujours posé par le code, et **dans la langue qu'il annonce** — un joueur
## perdu dans une langue qu'il ne lit pas doit reconnaître la sienne.
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

	# Un bouton qui tourne plutôt qu'une liste déroulante : il y a quatre valeurs
	# au plus, le libellé dit toujours celle qu'on a, et une liste déroulante
	# dessinerait sa fenêtre par-dessus le menu de pause.
	fenetre_btn.pressed.connect(_changer_fenetre)
	_rafraichir_fenetre()

	# Une ronde, comme la fenêtre : deux langues aujourd'hui, et le bouton dira la
	# troisième sans qu'on y revienne.
	langue_btn.pressed.connect(_changer_langue)
	_rafraichir_langue()

	($Root/Center/Panel/Menu/Resume as Button).pressed.connect(close)
	($Root/Center/Panel/Menu/OptionsBtn as Button).pressed.connect(_show_options)
	($Root/Center/Panel/Menu/Retour as Button).pressed.connect(_retour_menu)
	($Root/Center/Panel/Menu/Quit as Button).pressed.connect(_quitter)
	($Root/Center/Panel/Options/Back as Button).pressed.connect(_show_menu)


## Les deux libellés que le code écrit lui-même : Godot retraduit les textes posés
## dans la scène, pas ceux-là. Celui de la fenêtre change de langue, celui de la
## langue change de langue **et** de sens.
##
## La garde n'est pas une précaution : cette notification arrive **aussi à
## l'entrée dans l'arbre**, avant que les `@onready` soient posés. Sans elle, le
## menu écrit dans un bouton qui n'existe pas encore, à chaque zone chargée.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_rafraichir_fenetre()
		_rafraichir_langue()


func _unhandled_input(event: InputEvent) -> void:
	if Touches.enfoncee(event) != KEY_ESCAPE:
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


## Le libellé se relit sur le réglage plutôt que de retenir ce qu'on a cliqué :
## la valeur peut avoir été bornée à l'écran de la machine, et un bouton qui
## annonce ×4 pendant que la fenêtre est en ×3 est pire que pas de bouton.
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
