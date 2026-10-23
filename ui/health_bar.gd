class_name HealthBar
extends Node2D

## La barre de vie d'un acteur, dessinée à la volée : cachée à pleine vie, redessinée
## seulement quand la vie change, coupée à la racine quand le réglage est décoché.
##
## À l'écran, au-dessus de son corps 3D (jalon 54) : elle suit sa projection tant
## qu'elle se montre.

const WIDTH := 18.0
const HEIGHT := 3.0
## Au-dessus de la bande où montent les nombres de dégâts (−13 à −26).
const OFFSET_Y := -28.0

## Ce que le corps dépasse le guerrier par le haut (`SpriteForge.head_room()`).
var lift := 0.0

const BACK := Color(0.05, 0.04, 0.07, 0.85)
const EDGE := Color(0.02, 0.02, 0.03, 0.95)
const FULL := Color(0.42, 0.78, 0.32)
const LOW := Color(0.85, 0.26, 0.22)
## Le seuil rouge, où l'on décide de reculer.
const LOW_RATIO := 0.35

## Les icônes d'état, entre la barre et l'étiquette d'affixe : leur contour se
## chevauche d'un pixel.
const ICON_GAP := 1.0

var _ratio := 1.0
var _kinds: Array[int] = []
## Les natures dont la résistance est entamée : une icône chacune, après celles des états.
var _opened: Array[int] = []
## Les rats accrochés (jalon 53) : leur nombre s'écrit à gauche de leur icône.
var _rats := 0
var _shown := false


func _ready() -> void:
	Settings.changed.connect(_refresh)
	_refresh()


func _process(_delta: float) -> void:
	var body := get_parent() as Node3D
	if body == null:
		return
	visible = _shown and body.is_visible_in_tree()
	# Où le corps se voit, interpolé entre deux pas : sinon la barre tremble sur lui.
	var seen := body.get_global_transform_interpolated().origin
	position = Flat.on_screen(get_viewport(), seen, SpriteForge.CENTER_ABOVE_FEET - OFFSET_Y + lift)


## Appelée par l'acteur à chaque changement de vie, et une fois à la naissance.
func set_health(current: float, maximum: float) -> void:
	var r := StatMod.ratio(current, maximum)
	if is_equal_approx(r, _ratio):
		return
	_ratio = r
	_refresh()


## Appelée par l'acteur quand un état apparaît ou prend fin, jamais à chaque image.
func show_states(states: StatusEffects) -> void:
	_kinds = states.kinds()
	_opened = states.opened()
	_rats = states.rats()
	_refresh()


## Les icônes tiennent la barre visible à pleine vie : un ennemi remonté à fond
## reste transi, et c'est justement ce qu'on regarde.
func _refresh() -> void:
	_shown = Settings.show_health_bars and _ratio > 0.0 \
			and (_ratio < 1.0 or not _kinds.is_empty() or not _opened.is_empty())
	visible = _shown
	set_process(_shown)
	if _shown:
		queue_redraw()


func _draw() -> void:
	# Coordonnées entières : pas de bavure.
	var x := roundf(-WIDTH * 0.5)
	var y := 0.0

	if _ratio < 1.0:
		draw_rect(Rect2(x - 1.0, y - 1.0, WIDTH + 2.0, HEIGHT + 2.0), EDGE)
		draw_rect(Rect2(x, y, WIDTH, HEIGHT), BACK)
		draw_rect(
			Rect2(x, y, roundf(WIDTH * _ratio), HEIGHT),
			LOW if _ratio <= LOW_RATIO else FULL
		)

	var side := float(StatusIcon.SIDE)
	var step := side + ICON_GAP
	# Le compteur chevauche le contour de l'icône des rats, d'un pixel avant et après.
	var counter := StatusIcon.count(_rats) if _rats > 0 else null
	var extra := float(counter.get_width()) - 2.0 if counter != null else 0.0
	var px := roundf(-(float(_kinds.size() + _opened.size()) * step - ICON_GAP + extra) * 0.5)
	var py := y - side - 1.0
	for kind in _kinds:
		if kind == StatusEffects.Kind.RATS and counter != null:
			px += extra
			draw_texture(StatusIcon.texture(kind), Vector2(px, py))
			draw_texture(counter, Vector2(px - extra, py + side - float(counter.get_height()) + 2.0))
		else:
			draw_texture(StatusIcon.texture(kind), Vector2(px, py))
		px += step
	for nature in _opened:
		draw_texture(StatusIcon.lowered(nature), Vector2(px, py))
		px += step
