class_name Hud
extends Control

## L'affichage tête haute : le niveau et la progression vers le suivant.
##
## Branché par signal et non par lecture à chaque image — la barre ne bouge
## qu'aux morts d'ennemis, soit quelques fois par seconde au plus fort d'un
## combat, contre soixante lectures par seconde en interrogeant le joueur.
##
## Dessinée à la volée, comme les barres de vie et la trace du swing : le projet
## n'a aucune texture, ce n'est pas cette barre qui va en introduire une.

const MARGIN := 12.0
const HEIGHT := 3.0
const BOTTOM := 8.0

const BACK := Color(0.06, 0.05, 0.08, 0.90)
const EDGE := Color(0.02, 0.02, 0.03, 0.95)
## Le bleu du joueur, celui de sa tunique : la barre est sa progression à lui.
## L'or reste réservé aux critiques et aux élites.
const FILL := Color(0.24, 0.45, 0.86)
const FLASH := Color(1.0, 0.94, 0.76)
const FLASH_TIME := 0.45

@onready var level_label: Label = $Level
@onready var amount_label: Label = $Amount

var _ratio := 0.0
var _flash := 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)
	_refresh_labels(0, 0, 1)


## Appelée par la scène, qui est la seule à connaître les deux nœuds.
func bind(player: Player) -> void:
	player.xp_changed.connect(_on_xp_changed)
	player.leveled_up.connect(_on_leveled_up)
	_on_xp_changed(player.xp, player.xp_to_next, player.level)


func _on_xp_changed(current: int, needed: int, level: int) -> void:
	_ratio = 0.0 if needed <= 0 else clampf(float(current) / float(needed), 0.0, 1.0)
	_refresh_labels(current, needed, level)
	queue_redraw()


func _on_leveled_up(_level: int) -> void:
	_flash = FLASH_TIME
	set_process(true)


## Ne tourne que pendant l'éclat de montée de niveau, puis s'éteint.
func _process(delta: float) -> void:
	_flash -= delta
	if _flash <= 0.0:
		_flash = 0.0
		set_process(false)
	queue_redraw()


## Niveau à gauche, compte à droite, barre en dessous : les trois se lisent
## comme une seule ligne, et le chiffre exact reste disponible sans encombrer le
## centre de l'écran.
func _refresh_labels(current: int, needed: int, level: int) -> void:
	level_label.text = "Niv. %d" % level
	amount_label.text = "%d exp / %d exp" % [current, needed]


func _draw() -> void:
	var w := roundf(size.x - MARGIN * 2.0)
	var x := roundf(MARGIN)
	var y := roundf(size.y - BOTTOM - HEIGHT)
	if w <= 0.0:
		return

	draw_rect(Rect2(x - 1.0, y - 1.0, w + 2.0, HEIGHT + 2.0), EDGE)
	draw_rect(Rect2(x, y, w, HEIGHT), BACK)

	var fill := FILL
	if _flash > 0.0:
		fill = FILL.lerp(FLASH, _flash / FLASH_TIME)
	draw_rect(Rect2(x, y, roundf(w * _ratio), HEIGHT), fill)
