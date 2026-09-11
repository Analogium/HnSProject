class_name AffixTag
extends Node2D

## Les noms d'affixes d'un ennemi, empilés au-dessus de sa tête.
##
## Chaque nom est écrit dans la couleur de son affixe : c'est ce qui apprend au
## joueur à lire la teinte seule. Sur un élite, les deux lignes gardent leur
## couleur propre là où le sprite passe au doré — le texte rend l'information
## « lesquels » que la teinte d'élite abandonne.
##
## Aucun _process, et un seul _draw : les affixes sont tirés à l'apparition et
## ne changent plus. Le texte est mesuré une fois, à ce moment-là.

## Au-dessus de la barre de vie (−28), elle-même au-dessus des nombres de dégâts.
const OFFSET_Y := -37.0
const LINE_H := 9.0
const SIZE := 8

## Luminosité minimale du texte. La teinte du sprite peut être volontairement
## sombre — Colossal est une terre brûlée, choisie pour ne pas se confondre avec
## l'or de l'élite — mais un texte sombre sur un sol sombre ne se lit pas. On
## relève la valeur sans toucher à la teinte : le nom reste de la même famille
## de couleur que le corps, et il devient lisible.
const MIN_TEXT_VALUE := 0.80

## Une ligne de l'étiquette. Une petite classe et non un tableau indexé à la
## main : `line[2]` obligeait à compter les colonnes pour retrouver la
## demi-largeur, là où `ligne.half` se relit. Il y en a au plus deux par ennemi,
## donc rien à gagner à les empaqueter.
class Ligne:
	var text: String
	var tint: Color
	## Demi-largeur du texte, mesurée une fois à la création : la re-mesurer à
	## chaque image coûterait plus cher que tout le reste du dessin.
	var half: float


var _lines: Array[Ligne] = []
## Les affixes tels qu'on les a reçus. Gardés pour pouvoir **re-mesurer** : un
## changement de langue donne des noms d'une autre longueur, et une demi-largeur
## d'avant décentrerait l'étiquette.
var _affixes: Array[Affix] = []
var _font: Font


func _ready() -> void:
	# Comme la barre de vie : le parent est Y-trié, un enfant placé plus haut
	# que le corps se dessinerait derrière lui.
	z_index = 50
	_font = ThemeDB.fallback_font
	visible = false
	Settings.changed.connect(_refresh)


## La langue a changé : les noms sont d'une autre longueur, et une demi-largeur
## mesurée avant décentrerait l'étiquette. On remesure donc tout, depuis les
## affixes gardés.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		set_affixes(_affixes)


## Appelée à l'apparition de l'ennemi, et de nouveau à chaque changement de
## langue.
func set_affixes(affixes: Array[Affix]) -> void:
	_affixes = affixes
	_lines.clear()
	if _font != null:
		for affix in affixes:
			var ligne := Ligne.new()
			ligne.text = affix.nom_affiche()
			ligne.tint = affix.tint
			ligne.tint.v = maxf(ligne.tint.v, MIN_TEXT_VALUE)
			ligne.half = _font.get_string_size(
				ligne.text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE
			).x * 0.5
			_lines.append(ligne)
	_refresh()


func _refresh() -> void:
	visible = Settings.show_affix_names and not _lines.is_empty()
	if visible:
		queue_redraw()


func _draw() -> void:
	for i in _lines.size():
		var ligne := _lines[i]
		# Le premier affixe en haut de la pile, le dernier au ras de la tête :
		# on lit de haut en bas comme partout ailleurs.
		var y := roundf(OFFSET_Y - float(_lines.size() - 1 - i) * LINE_H)
		var pos := Vector2(roundf(-ligne.half), y)
		# Contour noir : sur un sol clair comme sur un mur sombre, le nom doit
		# tenir sans qu'on ait à choisir sa couleur selon le décor.
		draw_string_outline(
			_font, pos, ligne.text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 1,
			Color(0, 0, 0, 0.95)
		)
		draw_string(
			_font, pos, ligne.text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, ligne.tint
		)
