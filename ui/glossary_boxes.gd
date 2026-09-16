class_name GlossaryBoxes

## Les encadrés du glossaire, un par terme d'un texte affiché, empilés **contre le
## rectangle qui montre ce texte** — une infobulle, une fiche. Sans survol : en 640×360
## un mot fait huit pixels, et une infobulle disparaît quand la souris la quitte.

const WIDTH := 120.0
const PAD := 5.0
const LINE := 9.0
const GAP := 3.0
const FONT_SIZE := 8


## Où poser la colonne d'encadrés : à droite d'`anchor`, à gauche, dessous, dessus —
## la première qui tient dans `bounds` sans recouvrir `owner`, sinon la première qui
## tient. Sur la page du manuel, la fiche touche le panneau et le bord de l'écran : à
## côté, l'encadré couvrait l'arbre. Publique pour les tests.
static func layout(anchor: Rect2, owner: Rect2, bounds: Rect2, heights: Array[float]) -> Array[Rect2]:
	var total := 0.0
	for h in heights:
		total += h + GAP
	total -= GAP
	var beside := clampf(anchor.position.y, bounds.position.y, maxf(bounds.end.y - total, bounds.position.y))
	var aligned := clampf(anchor.position.x, bounds.position.x, bounds.end.x - WIDTH)
	var candidates: Array[Vector2] = [
		Vector2(anchor.end.x + GAP, beside),
		Vector2(anchor.position.x - GAP - WIDTH, beside),
		Vector2(aligned, anchor.end.y + GAP),
		Vector2(aligned, anchor.position.y - GAP - total),
	]
	var at := Vector2(clampf(anchor.end.x + GAP, bounds.position.x, bounds.end.x - WIDTH), beside)
	var found := false
	for with_owner in [false, true]:
		for candidate in candidates:
			var column := Rect2(candidate, Vector2(WIDTH, total))
			if bounds.encloses(column) and (with_owner or not column.intersects(owner)):
				at = candidate
				found = true
				break
		if found:
			break

	var out: Array[Rect2] = []
	for h in heights:
		out.append(Rect2(at, Vector2(WIDTH, h)))
		at.y += h + GAP
	return out


## Les encadrés des termes présents dans `texts`, rien s'il n'y en a aucun. `canvas`
## est le panneau qui dessine : les bornes sont le cadrage, au-dessus des jauges.
static func draw(canvas: Control, font: Font, anchor: Rect2, owner: Rect2, texts: PackedStringArray) -> void:
	var entries := PackedStringArray()
	for text_value in texts:
		for entry in Glossary.terms(text_value):
			if not entries.has(entry):
				entries.append(entry)
	if entries.is_empty():
		return

	var body_width := WIDTH - PAD * 2.0
	var folded: Array[PackedStringArray] = []
	var heights: Array[float] = []
	for entry in entries:
		var lines := RichText.fold(font, Glossary.definition(entry), body_width, FONT_SIZE)
		folded.append(lines)
		heights.append(PAD * 2.0 + LINE * float(lines.size() + 1))

	var screen := canvas.get_viewport_rect().size
	var bounds := Rect2(
		-canvas.global_position,
		Vector2(screen.x, Hud.gauges_top(screen.y))
	)
	var boxes := layout(anchor, owner, bounds, heights)
	for i in entries.size():
		var r := boxes[i]
		canvas.draw_rect(r, UiPalette.GLOSSARY_BACK)
		canvas.draw_rect(r, UiPalette.GLOSSARY_BORDER, false, 1.0)
		var y := r.position.y + PAD + LINE - 2.0
		canvas.draw_string(
			RichText.bold(font), Vector2(r.position.x + PAD, y), Glossary.title(entries[i]),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.GLOSSARY_BORDER
		)
		for line in folded[i]:
			y += LINE
			RichText.draw(canvas, font, Vector2(r.position.x + PAD, y), line, FONT_SIZE, UiPalette.TEXT)
