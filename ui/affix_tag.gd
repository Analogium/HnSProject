class_name AffixTag
extends Node2D

## Les noms d'affixes d'un ennemi, chacun dans sa couleur : c'est ce qui apprend la
## teinte, et un élite doré garde ainsi ses deux noms. Mesurés une fois, et à chaque
## changement de langue.

## Au-dessus des icônes d'état (−38 à −30), elles-mêmes au-dessus de la barre de vie.
const OFFSET_Y := -41.0
const LINE_H := 9.0
const SIZE := 8

## Luminosité minimale du texte, sans toucher à la teinte : une couleur sombre sur un
## sol sombre ne se lit pas.
const MIN_TEXT_VALUE := 0.80

## Une ligne : `line.half` se relit, `line[2]` non.
class Line:
	var text: String
	var tint: Color
	## Mesurée une fois : la re-mesurer coûterait plus que tout le dessin.
	var half: float


var _lines: Array[Line] = []
## Gardés pour re-mesurer quand la langue change.
var _affixes: Array[Affix] = []
var _font: Font


func _ready() -> void:
	# z_index : le parent est Y-trié.
	z_index = 50
	_font = ThemeDB.fallback_font
	visible = false
	Settings.changed.connect(_refresh)


## Des noms d'une autre longueur : on remesure depuis les affixes gardés.
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
			var line := Line.new()
			line.text = affix.displayed_name()
			line.tint = affix.tint
			line.tint.v = maxf(line.tint.v, MIN_TEXT_VALUE)
			line.half = _font.get_string_size(
				line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.world_font(SIZE)
			).x * 0.5
			_lines.append(line)
	_refresh()


func _refresh() -> void:
	visible = Settings.show_affix_names and not _lines.is_empty()
	if visible:
		queue_redraw()


func _draw() -> void:
	for i in _lines.size():
		var line := _lines[i]
		# Le premier en haut, le dernier au ras de la tête.
		var y := roundf(OFFSET_Y - float(_lines.size() - 1 - i) * LINE_H / Game.WORLD_ZOOM)
		var pos := Vector2(roundf(-line.half), y)
		# Contour noir : lisible sur tous les sols.
		draw_string_outline(
			_font, pos, line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.world_font(SIZE), 1,
			Color(0, 0, 0, 0.95)
		)
		draw_string(
			_font, pos, line.text, HORIZONTAL_ALIGNMENT_LEFT, -1, Game.world_font(SIZE), line.tint
		)
