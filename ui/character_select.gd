class_name CharacterSelect
extends Control

## L'écran d'accueil : choisir, créer, supprimer un personnage. Il ne connaît que
## `SaveStore` et `Character`, pose le choix sur `Game` et change de scène. Chaque
## personnage a **sa** silhouette animée.

enum State { LIST, CREATION, DELETION }

const LINE := 34.0
## Cinq lignes, puis la liste défile (hauteur du cadrage).
const VISIBLE_ROWS := 5
const LIST_W := 340.0
const LIST_Y := 56.0

## Création et suppression au même endroit, une à la fois.
const MODAL := Rect2(170.0, 74.0, 300.0, 196.0)

const BACKGROUND := Color(0.055, 0.051, 0.075)
const SELECTED := Color(0.20, 0.19, 0.26)
const ACCENT := Color(0.55, 0.75, 1.0)
## Entrée illisible : rouge éteint, une entrée hors service et non une alerte.
const DAMAGED := Color(0.72, 0.42, 0.42)

const FONT_SIZE := 8
const NAME_SIZE := 10

## Les vignettes de création : taille, écart, hauteur de leur centre.
const THUMBNAIL := Vector2(34.0, 36.0)
const THUMBNAIL_STEP := 56.0
const THUMBNAIL_Y := 104.0

## Le mot à retaper pour un personnage sans nom lisible. **Traduit**, et lu des deux
## côtés par `_word_to_type()`.
const UNNAMED_WORD := "SUPPRIMER"

## Refus d'une saisie : rouge franc, il répond à un geste.
const ERROR_COLOR := Color(0.92, 0.45, 0.42)

@onready var title_text: Label = $Title
@onready var help: Label = $Help
@onready var message: Label = $Message
@onready var actions: Control = $Actions
@onready var play_button: Button = $Actions/Play
@onready var new_button: Button = $Actions/New
@onready var delete_button: Button = $Actions/Delete

@onready var creation: Control = $Creation
@onready var name_field: LineEdit = $Creation/Name
@onready var creation_error: Label = $Creation/Error

@onready var deletion: Control = $Deletion
@onready var warning: Label = $Deletion/Warning
@onready var confirmation_field: LineEdit = $Deletion/Confirmation
@onready var deletion_error: Label = $Deletion/Error

@onready var silhouettes: Node2D = $Silhouettes

var _characters: Array[Character] = []
var _index := 0
## Premier personnage affiché : la liste défile quand la sélection sort du cadre.
var _first := 0
var _state := State.LIST
var _silhouette := 0
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Couleurs d'ici et non du `.tscn`, qui ne suivrait pas la palette.
	title_text.add_theme_color_override("font_color", UiPalette.TEXT)
	help.add_theme_color_override("font_color", UiPalette.HINT)
	message.add_theme_color_override("font_color", ACCENT)
	($Creation/Title as Label).add_theme_color_override("font_color", UiPalette.TEXT)
	($Creation/Silhouette as Label).add_theme_color_override("font_color", UiPalette.HINT)
	warning.add_theme_color_override("font_color", UiPalette.TEXT)
	for caption in [creation_error, deletion_error]:
		caption.add_theme_color_override("font_color", ERROR_COLOR)

	play_button.pressed.connect(_play)
	new_button.pressed.connect(_open_creation)
	delete_button.pressed.connect(_open_deletion)
	($Creation/Create as Button).pressed.connect(_create)
	($Creation/Cancel as Button).pressed.connect(_back_to_list)
	($Deletion/Confirm as Button).pressed.connect(_delete)
	($Deletion/Cancel as Button).pressed.connect(_back_to_list)
	name_field.text_submitted.connect(func(_t: String) -> void: _create())
	confirmation_field.text_submitted.connect(func(_t: String) -> void: _delete())

	# La langue se change dès l'accueil, avant de connaître les options.
	_language_button().pressed.connect(_change_language)
	_refresh_language()

	reload()


## Liste dessinée à la main. La garde : la notification arrive aussi à l'entrée dans
## l'arbre.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_language()
		_refresh()


func _language_button() -> Button:
	return $Language as Button


func _change_language() -> void:
	Settings.cycle_language()
	_refresh_language()


## Le libellé s'écrit dans la langue qu'il annonce, et n'est donc jamais traduit.
func _refresh_language() -> void:
	_language_button().text = Settings.current_language_label()


## Publique : le test relit l'écran après avoir posé des personnages.
func reload() -> void:
	_characters = SaveStore.list_all()
	_index = clampi(_index, 0, maxi(_characters.size() - 1, 0))
	_state = State.LIST
	_refresh()


func selection() -> Character:
	if _index < 0 or _index >= _characters.size():
		return null
	return _characters[_index]


func _unhandled_input(event: InputEvent) -> void:
	var key := Keys.pressed_down(event)
	if key == KEY_NONE:
		return

	if _state != State.LIST:
		if key == KEY_ESCAPE:
			_back_to_list()
			get_viewport().set_input_as_handled()
		return

	match key:
		KEY_UP: _move(-1)
		KEY_DOWN: _move(1)
		KEY_ENTER, KEY_KP_ENTER: _play()
		KEY_N: _open_creation()
		KEY_DELETE: _open_deletion()
		KEY_ESCAPE: get_tree().quit()
		_: return
	get_viewport().set_input_as_handled()


## Clic : choisir ; double-clic : jouer.
func _gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	var click := event as InputEventMouseButton
	if not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return

	if _state == State.CREATION:
		_silhouette_click(click.position)
		return
	if _state != State.LIST:
		return

	var frame := _list_rect()
	if not frame.has_point(click.position):
		return
	var line := _first + int((click.position.y - frame.position.y) / LINE)
	if line < 0 or line >= _characters.size():
		return
	_index = line
	if click.double_click:
		_play()
	else:
		_refresh()


func _move(step: int) -> void:
	if _characters.is_empty():
		return
	_index = clampi(_index + step, 0, _characters.size() - 1)
	_refresh()


func _play() -> void:
	var p := selection()
	if p == null:
		_say(Texts.t("Aucun personnage. [N] pour en créer un."))
		return
	if p.unreadable:
		_say(Texts.t("Cette sauvegarde ne se lit pas. Son fichier est toujours là."))
		return
	Game.character = p
	Game.goto_scene("res://world/zone.tscn")


func _open_creation() -> void:
	_state = State.CREATION
	_silhouette = 0
	name_field.text = ""
	creation_error.text = ""
	_say("")
	_refresh()
	name_field.grab_focus()


func _create() -> void:
	var name := name_field.text.strip_edges()
	if not Character.valid_name(name):
		creation_error.text = Texts.t("Nom vide ou trop long (%d au plus).") % Character.NAME_MAX
		return

	var p := SaveStore.create(name, _silhouette)
	if p == null:
		creation_error.text = Texts.t("Écriture impossible sur le disque.")
		return

	reload()
	# Sur le personnage créé : retomber ailleurs ferait croire à un échec.
	for i in _characters.size():
		if _characters[i].id == p.id:
			_index = i
	_refresh()
	_say(Texts.t("« %s » créé.") % p.name)


func _open_deletion() -> void:
	var p := selection()
	if p == null:
		return
	_state = State.DELETION
	confirmation_field.text = ""
	deletion_error.text = ""
	warning.text = "\n".join([
		Texts.t("Supprimer « %s » définitivement ?") % _displayed_name(p),
		"",
		Texts.t("Tapez %s pour confirmer.") % _word_to_type(p),
	])
	_say("")
	_refresh()
	confirmation_field.grab_focus()


## Retaper à l'identique : la seule action qui détruit des heures de jeu.
func _delete() -> void:
	var p := selection()
	if p == null:
		_back_to_list()
		return
	if confirmation_field.text.strip_edges() != _word_to_type(p):
		deletion_error.text = Texts.t("Ce n'est pas ce qui était demandé.")
		return

	var name := _displayed_name(p)
	if not SaveStore.delete(p.id):
		deletion_error.text = Texts.t("Suppression impossible.")
		return
	reload()
	_say(Texts.t("« %s » supprimé.") % name)


func _back_to_list() -> void:
	_state = State.LIST
	# Sans ça, le champ garde le clavier et les flèches ne défilent plus la liste.
	name_field.release_focus()
	confirmation_field.release_focus()
	_refresh()


## **Le seul endroit** qui dit le mot : consigne et vérification passent par ici.
func _word_to_type(p: Character) -> String:
	return p.name if not p.name.is_empty() else Texts.t(UNNAMED_WORD)


func _displayed_name(p: Character) -> String:
	if not p.name.is_empty():
		return p.name
	return Texts.t("sauvegarde illisible")


func _say(text_value: String) -> void:
	message.text = text_value


func _list_rect() -> Rect2:
	return Rect2(
		(size.x - LIST_W) * 0.5, LIST_Y, LIST_W, LINE * float(VISIBLE_ROWS)
	)


func _refresh() -> void:
	# Le défilement suit la sélection, dans les deux sens.
	_first = clampi(_first, maxi(_index - VISIBLE_ROWS + 1, 0), _index)
	_first = clampi(_first, 0, maxi(_characters.size() - VISIBLE_ROWS, 0))

	var as_list := _state == State.LIST
	actions.visible = as_list
	help.visible = as_list
	creation.visible = _state == State.CREATION
	deletion.visible = _state == State.DELETION

	var selected := selection()
	play_button.disabled = selected == null or selected.unreadable
	delete_button.disabled = selected == null

	title_text.text = Texts.t("PERSONNAGES") if as_list else ""
	_place_silhouettes()
	queue_redraw()


## Des sprites qui s'animent seuls, refaits à chaque rafraîchissement : les planches
## sont en cache.
func _place_silhouettes() -> void:
	for child in silhouettes.get_children():
		child.queue_free()

	if _state == State.CREATION:
		for v in SpriteForge.VARIANTS:
			_silhouette_a(_thumbnail_rect(v).get_center(), v)
		return

	if _state != State.LIST:
		return

	var frame := _list_rect()
	for i in range(_first, mini(_first + VISIBLE_ROWS, _characters.size())):
		var p := _characters[i]
		if p.unreadable:
			continue
		_silhouette_a(
			Vector2(frame.position.x + 24.0, frame.position.y + LINE * float(i - _first) + LINE * 0.5),
			p.silhouette
		)


func _silhouette_a(center: Vector2, variant_index: int) -> void:
	var s := AnimatedSprite2D.new()
	s.sprite_frames = SpriteForge.frames("player", posmod(variant_index, SpriteForge.VARIANTS))
	s.position = center
	s.play("idle_down")
	silhouettes.add_child(s)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)

	if _state == State.LIST:
		_paint_list()
	else:
		draw_rect(MODAL, UiPalette.BACK_FULL)
		draw_rect(MODAL, UiPalette.BORDER, false, 1.0)
		if _state == State.CREATION:
			_paint_silhouette_choice()


func _paint_list() -> void:
	var frame := _list_rect()
	draw_rect(frame, UiPalette.BACK_FULL)
	draw_rect(frame, UiPalette.BORDER, false, 1.0)

	if _characters.is_empty():
		draw_string(
			_font, frame.position + Vector2(0.0, frame.size.y * 0.5),
			Texts.t("Aucun personnage pour l'instant."), HORIZONTAL_ALIGNMENT_CENTER,
			frame.size.x, NAME_SIZE, UiPalette.HINT
		)
		return

	for i in range(_first, mini(_first + VISIBLE_ROWS, _characters.size())):
		_paint_line(_characters[i], frame, i)

	# La barre de défilement n'apparaît que s'il y a de quoi défiler.
	if _characters.size() > VISIBLE_ROWS:
		var top := frame.size.y * float(_first) / float(_characters.size())
		var height := frame.size.y * float(VISIBLE_ROWS) / float(_characters.size())
		draw_rect(
			Rect2(frame.end.x - 3.0, frame.position.y + top, 2.0, height), UiPalette.BORDER
		)


func _paint_line(p: Character, frame: Rect2, i: int) -> void:
	var y := frame.position.y + LINE * float(i - _first)
	var line := Rect2(frame.position.x + 1.0, y + 1.0, frame.size.x - 2.0, LINE - 2.0)

	if i == _index:
		draw_rect(line, SELECTED)
		draw_rect(Rect2(line.position, Vector2(2.0, line.size.y)), ACCENT)

	var x := frame.position.x + 46.0
	if p.unreadable:
		draw_string(
			_font, Vector2(x, y + 16.0), Texts.t("sauvegarde illisible"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_SIZE, DAMAGED
		)
		draw_string(
			_font, Vector2(x, y + 27.0), p.id,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT
		)
		return

	draw_string(
		_font, Vector2(x, y + 16.0), p.name,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, NAME_SIZE, UiPalette.TEXT
	)
	draw_string(
		_font, Vector2(x, y + 27.0), Texts.t("niveau %d") % p.level,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT
	)
	draw_string(
		_font, Vector2(frame.position.x, y + 27.0), Texts.t("joué le %s") % p.played_on,
		HORIZONTAL_ALIGNMENT_RIGHT, frame.size.x - 10.0, FONT_SIZE, UiPalette.LABEL
	)


## **Le seul endroit** qui sait où est une vignette : sprite, cadre et clic le lisent.
func _thumbnail_rect(variant_index: int) -> Rect2:
	var x0 := MODAL.position.x + MODAL.size.x * 0.5 - THUMBNAIL_STEP * 1.5
	return Rect2(
		x0 + THUMBNAIL_STEP * float(variant_index) - THUMBNAIL.x * 0.5,
		MODAL.position.y + THUMBNAIL_Y - THUMBNAIL.y * 0.5,
		THUMBNAIL.x, THUMBNAIL.y
	)


## Le cadre de la silhouette choisie ; les sprites sont posés ailleurs.
func _paint_silhouette_choice() -> void:
	for v in SpriteForge.VARIANTS:
		var box := _thumbnail_rect(v)
		draw_rect(box, SELECTED if v == _silhouette else UiPalette.BACK_FULL)
		draw_rect(box, ACCENT if v == _silhouette else UiPalette.BORDER, false, 1.0)


## À la souris sur les vignettes : un bouton dessinerait son cadre sur le sprite.
func _silhouette_click(position_locale: Vector2) -> void:
	for v in SpriteForge.VARIANTS:
		if _thumbnail_rect(v).has_point(position_locale):
			_silhouette = v
			_refresh()
			return
