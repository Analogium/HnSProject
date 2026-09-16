class_name RichText

## Une ligne qui peut porter des termes du glossaire : dessinée, mesurée et pliée **ici
## seulement**. Une largeur prise sur la chaîne brute compterait les caractères de
## marque. Le terme est la police courante épaissie, dans la couleur de la ligne.

## Assez pour se lire en gras à 8 px sans empâter les lettres.
const EMBOLDEN := 0.6

static var _bold := {}


class Piece:
	var text_value: String
	var is_term: bool

	func _init(p_text: String, p_term: bool) -> void:
		text_value = p_text
		is_term = p_term


## La même police, épaissie ; une seule par police.
static func bold(font: Font) -> Font:
	if not _bold.has(font):
		var variation := FontVariation.new()
		variation.base_font = font
		variation.variation_embolden = EMBOLDEN
		_bold[font] = variation
	return _bold[font]


## Les morceaux de la ligne, termes à part, marques retirées.
static func pieces(text_value: String) -> Array[Piece]:
	var out: Array[Piece] = []
	var at := 0
	while at < text_value.length():
		var start := text_value.find(Glossary.START, at)
		if start < 0:
			out.append(Piece.new(text_value.substr(at), false))
			break
		if start > at:
			out.append(Piece.new(text_value.substr(at, start - at), false))
		var separator := text_value.find(Glossary.SEPARATOR, start)
		var end := text_value.find(Glossary.END, separator)
		if separator < 0 or end < 0:
			out.append(Piece.new(Glossary.plain(text_value.substr(start)), false))
			break
		out.append(Piece.new(text_value.substr(separator + 1, end - separator - 1), true))
		at = end + 1
	return out


static func width(font: Font, text_value: String, size_value: int) -> float:
	var total := 0.0
	for piece in pieces(text_value):
		total += (bold(font) if piece.is_term else font).get_string_size(
			piece.text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_value
		).x
	return total


## `at` est la ligne de base, comme pour `draw_string()`.
static func draw(
	canvas: CanvasItem, font: Font, at: Vector2, text_value: String, size_value: int, tint: Color
) -> void:
	var x := at.x
	for piece in pieces(text_value):
		var used := bold(font) if piece.is_term else font
		canvas.draw_string(
			used, Vector2(x, at.y), piece.text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_value, tint
		)
		x += used.get_string_size(piece.text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_value).x


## Calée à droite d'une colonne qui finit en `right`.
static func draw_right(
	canvas: CanvasItem, font: Font, at: Vector2, right: float, text_value: String,
	size_value: int, tint: Color
) -> void:
	draw(canvas, font, Vector2(right - width(font, text_value, size_value), at.y), text_value, size_value, tint)


## Coupe aux espaces seulement : un terme ne contient pas d'espace, il reste entier.
static func fold(font: Font, text_value: String, max_width: float, size_value: int) -> PackedStringArray:
	var out := PackedStringArray()
	var current_one := ""
	for word in text_value.split(" ", false):
		var trial := word if current_one.is_empty() else current_one + " " + word
		if width(font, trial, size_value) > max_width and not current_one.is_empty():
			out.append(current_one)
			current_one = word
		else:
			current_one = trial
	if not current_one.is_empty():
		out.append(current_one)
	return out
