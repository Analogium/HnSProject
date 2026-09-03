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

var _lines: Array = []   # [texte, couleur, demi-largeur]
var _font: Font


func _ready() -> void:
	# Comme la barre de vie : le parent est Y-trié, un enfant placé plus haut
	# que le corps se dessinerait derrière lui.
	z_index = 50
	_font = ThemeDB.fallback_font
	visible = false
	Settings.changed.connect(_refresh)


## Appelée une fois, à l'apparition de l'ennemi.
func set_affixes(affixes: Array[Affix]) -> void:
	_lines.clear()
	if _font != null:
		for a in affixes:
			var affix: Affix = a
			var text: String = affix.display_name
			var c := affix.tint
			c.v = maxf(c.v, MIN_TEXT_VALUE)
			_lines.append([
				text,
				c,
				_font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE).x * 0.5,
			])
	_refresh()


func _refresh() -> void:
	visible = Settings.show_affix_names and not _lines.is_empty()
	if visible:
		queue_redraw()


func _draw() -> void:
	for i in _lines.size():
		var line: Array = _lines[i]
		# Le premier affixe en haut de la pile, le dernier au ras de la tête :
		# on lit de haut en bas comme partout ailleurs.
		var y := roundf(OFFSET_Y - float(_lines.size() - 1 - i) * LINE_H)
		var pos := Vector2(roundf(-float(line[2])), y)
		# Contour noir : sur un sol clair comme sur un mur sombre, le nom doit
		# tenir sans qu'on ait à choisir sa couleur selon le décor.
		draw_string_outline(
			_font, pos, line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, 1, Color(0, 0, 0, 0.95)
		)
		draw_string(_font, pos, line[0], HORIZONTAL_ALIGNMENT_LEFT, -1, SIZE, line[1])
