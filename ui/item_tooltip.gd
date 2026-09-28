class_name ItemTooltip
extends RefCounted

## L'infobulle d'un objet : ses lignes, sa taille, son dessin. Le sac et le banc du
## filtre de butin la dessinent tous deux ; chacun la pose à côté de ce qu'il montre.

## Fond d'UiPalette, cadre de la rareté. La ligne d'implicite :
const IMPLICIT := Color(0.62, 0.60, 0.68)
## L'étiquette d'une propriété et la note du bas, effacées : ce ne sont pas des
## bonus. La valeur, elle, sort en clair — c'est ce qu'on vient lire.
const LABEL := Color(0.46, 0.44, 0.52)
const VALUE := Color(0.88, 0.86, 0.94)
## Ce qui sépare l'étiquette de sa valeur. La ponctuation est **dans** l'étiquette
## traduite : le français met une espace devant le deux-points, l'anglais non.
const PROP_GAP := 3.0
## La colonne des paliers sous la touche « détails », plus sourde : une note de bas de page.
const TIER := Color(0.55, 0.53, 0.62)
## Gouttière entre un affixe et son palier.
const TIER_GAP := 10.0
const EXPLICIT := Color(0.55, 0.75, 1.0)
const PAD := 5.0
const LINE := 9.0
## Le bandeau du nom, collé au cadre comme celui de PoE : c'est lui qui donne le
## haut de l'infobulle, sans marge au-dessus.
const BAND := 14.0
const BAND_ALPHA := 0.17
## La hauteur d'un trait de séparation, gouttières comprises.
const RULE := 6.0
const MIN_W := 74.0
const FONT_SIZE := 8
const TITLE_SIZE := 9


## Une ligne d'infobulle. Les blocs — nom, propriétés, exigences, implicite, affixes
## — se construisent en liste, puis se mesurent et se dessinent en la relisant : deux
## passes écrites à la main divergeaient à chaque ligne ajoutée.
class Line:
	## `MOD` est une ligne d'affixe, la seule qui porte une colonne de palier ; c'est
	## ce qui la sépare d'un `TEXT`.
	enum Kind { TITLE, PROPERTY, TEXT, MOD, RULE }

	var kind: Kind
	## Le texte, ou l'étiquette d'une propriété.
	var text := ""
	## La valeur d'une propriété, mise en avant derrière son étiquette.
	var value := ""
	## Le palier d'un affixe sous la touche « détails », calé à droite de l'infobulle. Vide partout
	## ailleurs, et sur un affixe ramassé avant les paliers.
	var aside := ""
	var tint := Color.WHITE
	var value_tint := Color.WHITE

	func _init(p_kind: Kind, p_text := "", p_tint := Color.WHITE) -> void:
		kind = p_kind
		text = p_text
		tint = p_tint

	static func property(label_text: String, value_text: String, value_color: Color) -> Line:
		var line := Line.new(Kind.PROPERTY, label_text, ItemTooltip.LABEL)
		line.value = value_text
		line.value_tint = value_color
		return line


## Les lignes dans l'ordre où elles se lisent. Un bloc vide ne laisse pas de trait
## derrière lui : c'est `_block()` qui en décide. `detailed` : la touche « détails »
## tenue, qui ajoute les paliers.
static func lines(item: Item, detailed: bool) -> Array[Line]:
	var out: Array[Line] = []
	out.append(Line.new(Line.Kind.TITLE, item.display_name(), item.color()))

	# Ce que la base est, avant ce qu'elle a tiré : la chance critique d'une arme, la
	# défense d'une armure. En avant quand une ligne locale l'a montée, en clair sinon.
	var properties: Array[Line] = []
	if item.base.family == ItemBase.WEAPON_FAMILY:
		var raised := not is_equal_approx(item.crit_chance(), item.base.crit_chance)
		properties.append(Line.property(
			Texts.t("Chance critique de base :"),
			StatMod.format(SkillStats.CRIT_CHANCE, item.crit_chance()),
			EXPLICIT if raised else VALUE
		))
	var defense := item.base.defense_stat()
	if not defense.is_empty():
		var raised := not is_equal_approx(item.defense(), item.implicit_value())
		properties.append(Line.property(
			Texts.t("Armure :") if defense == "armor" else Texts.t("Esquive :"),
			StatMod.format(defense, item.defense()),
			EXPLICIT if raised else VALUE
		))
	if item.is_flask():
		properties.append_array(_flask_properties(item))
	_block(out, properties)

	# Ni niveau ni affixes : sa pile, ce qu'elle fait, et comment.
	if Currency.is_coin(item):
		_block(out, [Line.property(
			Texts.t("Pile :"), "%d / %d" % [item.count, item.base.stack_max], VALUE
		)] as Array[Line])
		_block(out, [
			Line.new(Line.Kind.TEXT, Currency.effect(item.base), VALUE),
			Line.new(Line.Kind.TEXT, Texts.t("clic droit, puis clic sur l'objet"), LABEL),
		] as Array[Line])
		return out

	# Toujours affiché : c'est ce qui décide si on le garde. Les paliers sous la touche « détails ».
	_block(out, [Line.property(
		Texts.t("Niveau d'objet :"), str(item.item_level), VALUE
	)] as Array[Line])

	# Majuscule en tête, implicite comme tirés : ce sont les mêmes lignes, et une
	# seule des deux sortes capitalisée se verrait. Une défense est déjà en propriété,
	# montée : son implicite, la valeur d'avant les affixes, attend les détails.
	var implicit := RichText.capitalized(item.implicit_line())
	if not implicit.is_empty() and (detailed or item.base.defense_stat().is_empty()):
		var line := Line.new(Line.Kind.MOD, implicit, IMPLICIT)
		var span := item.base.implicit_span()
		line.aside = "(%s)" % span if detailed and not span.is_empty() else ""
		_block(out, [line] as Array[Line])

	var mods: Array[Line] = []
	var without_origin := false
	for rolled in item.explicits:
		var line := Line.new(
			Line.Kind.MOD, RichText.capitalized(item.explicit_line(rolled)), EXPLICIT
		)
		# Vide sans provenance : la ligne s'affiche sans colonne.
		line.aside = rolled.tier_and_span() if detailed else ""
		without_origin = without_origin or line.aside.is_empty()
		mods.append(line)
	_block(out, mods)

	# Sous la touche « détails », dit pourquoi aucun palier ne s'affiche.
	if detailed and without_origin and not mods.is_empty():
		_block(out, [Line.new(
			Line.Kind.TEXT, Texts.t("paliers inconnus : ramassé avant"), LABEL
		)] as Array[Line])
	return out


## Ce que rend une gorgée, combien de temps, et ses charges : en avant ce que ses
## lignes locales ont monté, comme la chance critique d'une arme.
static func _flask_properties(item: Item) -> Array[Line]:
	var base := item.base
	var seconds := "%s s" % String.num(item.flask_duration(), 1)
	var out: Array[Line] = []
	if base.flask_life > 0.0:
		var life := {"n": roundi(item.flask_life()), "duree": seconds}
		out.append(Line.property(
			Texts.t("Rend :"), Texts.t("{n} PV en {duree}").format(life),
			_tint_of(item.flask_life(), base.flask_life)
		))
	if base.flask_mana > 0.0:
		var mana := {"n": roundi(item.flask_mana()), "duree": seconds}
		out.append(Line.property(
			Texts.t("Rend :"), Texts.t("{n} mana en {duree}").format(mana),
			_tint_of(item.flask_mana(), base.flask_mana)
		))
	if base.is_utility_flask():
		out.append(Line.property(
			Texts.t("Durée :"), seconds, _tint_of(item.flask_duration(), base.flask_duration)
		))
	out.append(Line.property(
		Texts.t("Charges :"), "%d / %d" % [floori(item.charges), item.charges_max()],
		_tint_of(item.charges_max(), base.flask_charges)
	))
	out.append(Line.property(
		Texts.t("Par gorgée :"), str(item.charges_per_use()),
		_tint_of(item.charges_per_use(), base.flask_charges_per_use)
	))
	return out


static func _tint_of(now: float, bare: float) -> Color:
	return VALUE if is_equal_approx(now, bare) else EXPLICIT


## La taille du cadre, bandeau et marges compris.
static func size_of(font: Font, all: Array[Line]) -> Vector2:
	var aside_col := _aside_column(font, all)
	var w := MIN_W
	# Pas de marge en haut : le bandeau du nom touche le cadre.
	var h := PAD
	for line in all:
		var need := _width(font, line)
		if line.kind == Line.Kind.MOD:
			need += aside_col
		w = maxf(w, need)
		h += _height(line.kind)
	return Vector2(w + PAD * 2.0, h)


## Dessine sur `canvas`, le coin haut-gauche en `at` ; les encadrés du glossaire se
## posent dans `bounds`.
static func draw(canvas: CanvasItem, font: Font, item: Item, all: Array[Line], at: Vector2, bounds: Rect2) -> void:
	# La colonne des paliers est réservée une fois pour toutes : les affixes se
	# centrent sur ce qu'elle leur laisse, et ne peuvent plus la rencontrer.
	var aside_col := _aside_column(font, all)
	var r := Rect2(at, size_of(font, all))
	var w := r.size.x
	canvas.draw_rect(r, UiPalette.TIP_BACK)
	canvas.draw_rect(r, item.color(), false, 1.0)

	var middle := r.position.x + w * 0.5
	var mod_middle := r.position.x + (w - aside_col) * 0.5
	var y := r.position.y
	for line in all:
		var baseline := y + LINE - 2.0
		match line.kind:
			Line.Kind.TITLE:
				_draw_title(canvas, font, line, Rect2(r.position, Vector2(w, BAND)), middle)
			Line.Kind.RULE:
				canvas.draw_line(
					Vector2(r.position.x + PAD, y + RULE * 0.5),
					Vector2(r.end.x - PAD, y + RULE * 0.5),
					Color(IMPLICIT, 0.35), 1.0
				)
			Line.Kind.PROPERTY:
				var x := roundf(middle - _width(font, line) * 0.5)
				canvas.draw_string(font, Vector2(x, baseline), line.text,
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, line.tint)
				canvas.draw_string(
					font, Vector2(x + _span(font, line.text) + PROP_GAP, baseline), line.value,
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, line.value_tint
				)
			Line.Kind.MOD:
				RichText.draw_centered(
					canvas, font, Vector2(0.0, baseline), mod_middle, line.text, FONT_SIZE, line.tint
				)
				if not line.aside.is_empty():
					canvas.draw_string(
						font, Vector2(r.end.x - PAD - _span(font, line.aside), baseline),
						line.aside, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIER
					)
			_:
				RichText.draw_centered(
					canvas, font, Vector2(0.0, baseline), middle, line.text, FONT_SIZE, line.tint
				)
		y += _height(line.kind)

	var described := PackedStringArray()
	for line in all:
		if line.kind == Line.Kind.MOD or line.kind == Line.Kind.TEXT:
			described.append(line.text)
	GlossaryBoxes.draw(canvas, font, r, bounds, described)


## Le nom sur son bandeau, teinté de la rareté et fermé par un trait : c'est lui
## qui donne à l'infobulle son en-tête, avant même qu'on lise une ligne.
static func _draw_title(canvas: CanvasItem, font: Font, line: Line, band: Rect2, middle: float) -> void:
	canvas.draw_rect(Rect2(band.position + Vector2.ONE, band.size - Vector2(2.0, 1.0)),
		Color(line.tint, BAND_ALPHA))
	canvas.draw_line(Vector2(band.position.x, band.end.y), Vector2(band.end.x, band.end.y),
		Color(line.tint, 0.45), 1.0)
	var x := roundf(middle - _span(font, line.text, TITLE_SIZE) * 0.5)
	canvas.draw_string(font, Vector2(x, band.end.y - 4.0), line.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_SIZE, line.tint)


## Un bloc derrière son trait de séparation, ou rien s'il est vide : un trait qui ne
## sépare rien est une ligne perdue.
static func _block(into: Array[Line], block: Array[Line]) -> void:
	if block.is_empty():
		return
	into.append(Line.new(Line.Kind.RULE))
	into.append_array(block)


static func _aside_column(font: Font, all: Array[Line]) -> float:
	var aside_col := 0.0
	for line in all:
		if line.kind == Line.Kind.MOD and not line.aside.is_empty():
			aside_col = maxf(aside_col, _span(font, line.aside))
	return aside_col + TIER_GAP if aside_col > 0.0 else 0.0


static func _height(kind: Line.Kind) -> float:
	match kind:
		Line.Kind.TITLE:
			return BAND
		Line.Kind.RULE:
			return RULE
	return LINE


## Ce que la ligne réclame, colonne des paliers non comprise.
static func _width(font: Font, line: Line) -> float:
	match line.kind:
		Line.Kind.TITLE:
			return _span(font, line.text, TITLE_SIZE)
		Line.Kind.PROPERTY:
			return _span(font, line.text) + PROP_GAP + _span(font, line.value)
		Line.Kind.RULE:
			return 0.0
	return RichText.width(font, line.text, FONT_SIZE)


## Un texte sans terme de glossaire : étiquette, valeur, palier, nom.
static func _span(font: Font, text_value: String, size_value := FONT_SIZE) -> float:
	return font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_value).x
