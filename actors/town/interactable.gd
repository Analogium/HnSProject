class_name Interactable
extends Node2D

## Ce qui se clique dans le monde sans être du butin : le marchand, le coffre, les
## portails qui relient une zone à la ville ou à la suivante, et les waypoints. Le
## clic gauche l'utilise, n'importe où dans la zone, et ne lance pas d'attaque — le
## même refus que `GroundItem.takes_the_click()`.
##
## Dessin provisoire, à reprendre par `/dessiner-un-effet` : le marchand emprunte le
## guerrier en grilles, le coffre, les portails et le waypoint sont tracés.

signal used

## À la fin seulement : la scène écrit le rang.
enum Look { MERCHANT, STASH, PORTAL, GATE, WAYPOINT }

@export var look := Look.MERCHANT

## Les clés françaises, traduites au dessin.
const TITLES := {
	Look.MERCHANT: "Marchand", Look.STASH: "Coffre", Look.PORTAL: "Portail", Look.GATE: "Passage",
	Look.WAYPOINT: "Waypoint",
}

## La surface qui répond, autour du pied : c'est aussi ce qui s'éclaire au survol.
const HIT := Rect2(-12.0, -30.0, 24.0, 32.0)
const NAME_SIZE := 7
const NAME_GAP := 3.0
const CHEST := Color(0.45, 0.30, 0.17)
const CHEST_BAND := Color(0.72, 0.60, 0.30)
const PORTAL := Color(0.35, 0.60, 1.0)
## Doré : il ne mène pas où mène le bleu.
const GATE := Color(1.0, 0.72, 0.30)
const STONE := Color(0.30, 0.26, 0.24)
const RUNE_OFF := Color(0.45, 0.40, 0.36)
const RUNE_ON := Color(0.40, 0.85, 1.0)

## Celui qui est sous le curseur, ou null. En lecture seule.
static var hovered: Interactable

## Une clé française à la place de celle de `TITLES` : le passage qui porte le nom
## de la zone où il mène.
var title := ""
## Le waypoint seulement : activé pour ce personnage.
var lit := false

var _over := false
var _t := 0.0


func _ready() -> void:
	if look == Look.MERCHANT:
		var body := AnimatedSprite2D.new()
		body.sprite_frames = SpriteForge.frames("player", 3, "none")
		body.offset = SpriteForge.offset_of("player")
		body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		body.play("idle_down")
		add_child(body)


## Toujours : retiré sous le curseur, il retiendrait le clic gauche du joueur.
func _exit_tree() -> void:
	if hovered == self:
		hovered = null


func _process(delta: float) -> void:
	_t += delta
	var over := is_visible_in_tree() and HIT.has_point(to_local(get_global_mouse_position()))
	if over:
		hovered = self
	elif hovered == self:
		hovered = null
	_over = over
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	var click := event as InputEventMouseButton
	if click == null or not click.pressed or click.button_index != MOUSE_BUTTON_LEFT:
		return
	if clicked(get_viewport().get_canvas_transform().affine_inverse() * click.position):
		get_viewport().set_input_as_handled()


## **Le seul chemin** de l'utilisation — la souris n'est qu'un moyen d'y arriver, et
## les tests n'en ont pas.
func clicked(world_point: Vector2) -> bool:
	if not is_visible_in_tree() or not HIT.has_point(to_local(world_point)):
		return false
	used.emit()
	return true


static func takes_the_click(action: String) -> bool:
	return hovered != null and Keybinds.uses_left_click(action)


func _draw() -> void:
	match look:
		Look.STASH:
			draw_rect(Rect2(-11.0, -14.0, 22.0, 14.0), CHEST)
			draw_rect(Rect2(-11.0, -14.0, 22.0, 14.0), Color.BLACK, false, 1.0)
			draw_rect(Rect2(-11.0, -10.0, 22.0, 2.0), CHEST_BAND)
			draw_rect(Rect2(-2.0, -9.0, 4.0, 4.0), CHEST_BAND)
		Look.PORTAL, Look.GATE:
			var hue := PORTAL if look == Look.PORTAL else GATE
			var pulse := 1.0 + 0.08 * sin(_t * 4.0)
			draw_set_transform(Vector2(0.0, -14.0), 0.0, Vector2(0.7, 1.0) * pulse)
			Glow.draw_blob(self, Vector2.ZERO, 14.0, Color(hue, 0.5))
			Glow.draw_ring(self, Vector2.ZERO, 14.0, hue)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		Look.WAYPOINT:
			# Une dalle vue de trois quarts, et son anneau de runes qui s'allume.
			draw_set_transform(Vector2(0.0, -4.0), 0.0, Vector2(1.0, 0.5))
			draw_circle(Vector2.ZERO, 14.0, STONE)
			draw_arc(Vector2.ZERO, 14.0, 0.0, TAU, 32, Color.BLACK, 1.0)
			if lit:
				Glow.draw_blob(self, Vector2.ZERO, 11.0, Color(RUNE_ON, 0.35 + 0.1 * sin(_t * 3.0)))
			Glow.draw_ring(self, Vector2.ZERO, 9.0, RUNE_ON if lit else RUNE_OFF)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)

	# Le nom toujours, comme les PNJ de PoE ; blanc sous la souris, seul signe qu'il se
	# clique.
	var font := ThemeDB.fallback_font
	var size := Game.world_font(NAME_SIZE)
	var text_value := Texts.t(title if not title.is_empty() else TITLES[look])
	var width := font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	var at := Vector2(-width * 0.5, HIT.position.y - NAME_GAP).round()
	draw_string_outline(font, at, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, 3, Color.BLACK)
	draw_string(font, at, text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size,
		Color.WHITE if _over else UiPalette.HINT)
