class_name HealthBar
extends Node2D

## La barre de vie d'un acteur, dessinée à la volée — pas de texture, comme le
## reste du projet.
##
## Trois règles, toutes dictées par le nombre d'acteurs à l'écran :
##
## - cachée à pleine vie. Trois cents barres pleines encombrent la vue sans rien
##   dire ; une barre qui apparaît est déjà une information ;
## - redessinée quand la vie change, jamais à chaque image. Aucun _process ;
## - coupée à la racine quand le réglage est décoché — visible = false, donc
##   Godot ne l'appelle plus du tout, au lieu d'une barre transparente qui
##   continuerait de coûter.

const WIDTH := 18.0
const HEIGHT := 3.0
## Au-dessus de la zone que traversent les nombres de dégâts. Ceux-ci naissent
## à -13 et montent d'une douzaine de pixels ; en dessous de -26, la barre leur
## coupe le passage et les deux deviennent illisibles.
const OFFSET_Y := -28.0

const BACK := Color(0.05, 0.04, 0.07, 0.85)
const EDGE := Color(0.02, 0.02, 0.03, 0.95)
const FULL := Color(0.42, 0.78, 0.32)
const LOW := Color(0.85, 0.26, 0.22)
## En dessous, la barre passe au rouge : c'est le seuil où l'on décide de
## reculer, il doit se voir sans lire la longueur.
const LOW_RATIO := 0.35

## Une pastille par état, dans la couleur de sa nature, entre la barre et
## l'étiquette d'affixe.
const PASTILLE := 3.0
const ECART_DE_PASTILLE := 3.0

var _ratio := 1.0
var _couleurs: Array[Color] = []


func _ready() -> void:
	# z_index et non l'ordre de l'arbre : le parent est Y-trié, donc un enfant
	# placé plus haut que le corps se dessinerait derrière lui.
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
	_couleurs = etats.couleurs()
	_refresh()


## Les pastilles tiennent la barre visible à pleine vie : un ennemi remonté à fond
## reste transi, et c'est justement ce qu'on regarde.
func _refresh() -> void:
	visible = Settings.show_health_bars and _ratio > 0.0 and (_ratio < 1.0 or not _couleurs.is_empty())
	if visible:
		queue_redraw()


func _draw() -> void:
	# Coordonnées entières : une barre à cheval sur deux pixels bave et trahit le
	# rendu pixel art.
	var x := roundf(-WIDTH * 0.5)
	var y := roundf(OFFSET_Y)

	if _ratio < 1.0:
		draw_rect(Rect2(x - 1.0, y - 1.0, WIDTH + 2.0, HEIGHT + 2.0), EDGE)
		draw_rect(Rect2(x, y, WIDTH, HEIGHT), BACK)
		draw_rect(
			Rect2(x, y, roundf(WIDTH * _ratio), HEIGHT),
			LOW if _ratio <= LOW_RATIO else FULL
		)

	var pas := PASTILLE + ECART_DE_PASTILLE
	var px := roundf(-(float(_couleurs.size()) * pas - ECART_DE_PASTILLE) * 0.5)
	var py := y - PASTILLE - 3.0
	for couleur in _couleurs:
		draw_rect(Rect2(px - 1.0, py - 1.0, PASTILLE + 2.0, PASTILLE + 2.0), EDGE)
		draw_rect(Rect2(px, py, PASTILLE, PASTILLE), couleur)
		px += pas
