class_name HealthBar
extends Node2D

## La barre de vie d'un acteur, dessinée à la volée : cachée à pleine vie, redessinée
## seulement quand la vie change, coupée à la racine quand le réglage est décoché.

const WIDTH := 18.0
const HEIGHT := 3.0
## Au-dessus de la bande où montent les nombres de dégâts (−13 à −26).
const OFFSET_Y := -28.0

const BACK := Color(0.05, 0.04, 0.07, 0.85)
const EDGE := Color(0.02, 0.02, 0.03, 0.95)
const FULL := Color(0.42, 0.78, 0.32)
const LOW := Color(0.85, 0.26, 0.22)
## Le seuil rouge, où l'on décide de reculer.
const LOW_RATIO := 0.35

## Les icônes d'état, entre la barre et l'étiquette d'affixe : leur contour se
## chevauche d'un pixel.
const ECART_D_ICONE := 1.0

var _ratio := 1.0
var _sortes: Array[int] = []


func _ready() -> void:
	# z_index : le parent est Y-trié, l'enfant passerait derrière le corps.
	z_index = 50
	Settings.changed.connect(_refresh)
	_refresh()


## Appelée par l'acteur à chaque changement de vie, et une fois à la naissance.
func set_health(current: float, maximum: float) -> void:
	var r := StatMod.ratio(current, maximum)
	if is_equal_approx(r, _ratio):
		return
	_ratio = r
	_refresh()


## Appelée par l'acteur quand un état apparaît ou prend fin, jamais à chaque image.
func montrer_les_etats(etats: Etats) -> void:
	_sortes = etats.sortes()
	_refresh()


## Les icônes tiennent la barre visible à pleine vie : un ennemi remonté à fond
## reste transi, et c'est justement ce qu'on regarde.
func _refresh() -> void:
	visible = Settings.show_health_bars and _ratio > 0.0 and (_ratio < 1.0 or not _sortes.is_empty())
	if visible:
		queue_redraw()


func _draw() -> void:
	# Coordonnées entières : pas de bavure.
	var x := roundf(-WIDTH * 0.5)
	var y := roundf(OFFSET_Y)

	if _ratio < 1.0:
		draw_rect(Rect2(x - 1.0, y - 1.0, WIDTH + 2.0, HEIGHT + 2.0), EDGE)
		draw_rect(Rect2(x, y, WIDTH, HEIGHT), BACK)
		draw_rect(
			Rect2(x, y, roundf(WIDTH * _ratio), HEIGHT),
			LOW if _ratio <= LOW_RATIO else FULL
		)

	var cote := float(IconeDEtat.COTE)
	var pas := cote + ECART_D_ICONE
	var px := roundf(-(float(_sortes.size()) * pas - ECART_D_ICONE) * 0.5)
	var py := y - cote - 1.0
	for sorte in _sortes:
		draw_texture(IconeDEtat.texture(sorte), Vector2(px, py))
		px += pas
