class_name Interactable
extends Node3D

## Ce qui se clique dans le monde sans être du butin : le marchand, le coffre, les
## portails qui relient une zone à la ville ou à la suivante, et les waypoints. Le
## clic gauche l'utilise, n'importe où dans la zone, et ne lance pas d'attaque — le
## même refus que `GroundItem.takes_the_click()`.
##
## Le marchand et l'entraîneur sont des planches 3D (jalon 52). Le coffre, les portails et le
## waypoint étaient tracés en 2D : sans dessin jusqu'à l'étape 3 du jalon 54, leur nom les
## signale. Le nom et la surface qui répond sont à l'écran, sur la projection du pied.

signal used

## À la fin seulement : la scène écrit le rang.
enum Look { MERCHANT, STASH, PORTAL, GATE, WAYPOINT, TRAINER }

@export var look := Look.MERCHANT

## Les clés françaises, traduites au dessin.
const TITLES := {
	Look.MERCHANT: "Marchand", Look.STASH: "Coffre", Look.PORTAL: "Portail", Look.GATE: "Passage",
	Look.WAYPOINT: "Waypoint", Look.TRAINER: "Entraîneur",
}

## La surface qui répond, autour du pied, à l'écran : c'est aussi ce qui s'éclaire au survol.
const HIT := Rect2(-12.0, -30.0, 24.0, 32.0)
const NAME_SIZE := 7
const NAME_GAP := 3.0

## Celui qui est sous le curseur, ou null. En lecture seule.
static var hovered: Interactable

## Une clé française à la place de celle de `TITLES` : le passage qui porte le nom
## de la zone où il mène.
var title := ""
## Le waypoint seulement : activé pour ce personnage.
var lit := false

var _over := false
## Où se dessine le nom : un nœud du canevas, enfant de ce nœud 3D.
var _overlay: Node2D


func _ready() -> void:
	if look in [Look.MERCHANT, Look.TRAINER]:
		var body := ActorSprite.new()
		body.archetype = "merchant" if look == Look.MERCHANT else "trainer"
		add_child(body)
	_overlay = Node2D.new()
	_overlay.draw.connect(_draw_name)
	add_child(_overlay)


## Toujours : retiré sous le curseur, il retiendrait le clic gauche du joueur.
func _exit_tree() -> void:
	if hovered == self:
		hovered = null


func _process(_delta: float) -> void:
	_overlay.position = Flat.on_screen(get_viewport(), global_position)
	_overlay.visible = is_visible_in_tree()
	var over := is_visible_in_tree() and _hit_rect().has_point(get_viewport().get_mouse_position())
	if over:
		hovered = self
	elif hovered == self:
		hovered = null
	_over = over
	_overlay.queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if clicked(get_viewport().get_canvas_transform().affine_inverse() * click.position):
		get_viewport().set_input_as_handled()


## **Le seul chemin** de l'utilisation — la souris n'est qu'un moyen d'y arriver, et
## les tests n'en ont pas.
func clicked(screen_point: Vector2) -> bool:
	if not is_visible_in_tree() or not _hit_rect().has_point(screen_point):
		return false
	used.emit()
	return true


func _hit_rect() -> Rect2:
	return Rect2(Flat.on_screen(get_viewport(), global_position) + HIT.position, HIT.size)


static func takes_the_click(action: String) -> bool:
	return hovered != null and Keybinds.uses_left_click(action)


func _draw_name() -> void:
	# Le nom toujours, comme les PNJ de PoE ; blanc sous la souris, seul signe qu'il se
	# clique.
	var font := ThemeDB.fallback_font
	var size := Game.world_font(NAME_SIZE)
	var text_value := Texts.t(title if not title.is_empty() else TITLES[look])
	var width := font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var at := Vector2(-width * 0.5, HIT.position.y - NAME_GAP).round()
	_overlay.draw_string_outline(font, at, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, 3, Color.BLACK)
	_overlay.draw_string(font, at, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size,
		Color.WHITE if _over else UiPalette.HINT)
