extends GutTest

## Le glossaire (jalon 15) : la marque qui fait d'un mot un terme, et ce que le dessin
## en lit. Une marque cassée afficherait des caractères de contrôle, ou un mot sans
## son encadré.


func test_each_term_has_its_forms_and_its_entry() -> void:
	for id in Glossary.TERMS:
		assert_eq((Glossary.TERMS[id]["forms"] as Array).size(), Glossary.AGREEMENTS.size(), id)
		assert_true(Glossary.ENTRIES.has(Glossary.TERMS[id]["entry"]), id)
	for entry in Glossary.ENTRIES:
		assert_false(Glossary.title(entry).is_empty(), entry)
		assert_false(Glossary.definition(entry).is_empty(), entry)


func test_a_term_agrees_and_carries_its_mark() -> void:
	var word := Glossary.term("increased", "fp")
	assert_eq(Glossary.plain(word), "accrues")
	assert_ne(word, "accrues", "la marque entoure le mot")


func test_plain_and_terms_read_a_line_with_two_terms() -> void:
	var line := "a %s b %s c %s" % [
		Glossary.term("increased", "ms"), Glossary.term("more", "fs"), Glossary.term("reduced", "mp")
	]
	assert_eq(Glossary.plain(line), "a accru b amplifiée c réduits")
	assert_eq(Glossary.terms(line), PackedStringArray(["additive", "multiplicative"]), "sans doublon")
	assert_eq(Glossary.terms("sans terme"), PackedStringArray())


## Le dessin : les morceaux, le terme à part, sans marque.
func test_rich_text_splits_the_term_out() -> void:
	var pieces := RichText.pieces("+10 %% de dégâts %s (Sort)" % Glossary.term("more", "mp"))
	assert_eq(pieces.size(), 3)
	assert_eq(pieces[1].text_value, "amplifiés")
	assert_true(pieces[1].is_term)
	assert_eq(pieces[2].text_value, " (Sort)")


## Une largeur mesurée sur la chaîne brute compterait la marque.
func test_rich_text_measures_without_the_mark() -> void:
	var font := ThemeDB.fallback_font
	var line := "+10 %% de dégâts %s" % Glossary.term("increased", "mp")
	var bare := font.get_string_size(Glossary.plain(line), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8).x
	assert_almost_eq(RichText.width(font, line, 8), bare, bare * 0.15, "le gras élargit un peu, la marque rien")
	for folded in RichText.fold(font, "%s %s" % [line, line], 60.0, 8):
		assert_true(folded.count(Glossary.START) == folded.count(Glossary.END), "un pli ne coupe pas une marque")


## Aucune clé de traduction ne contient de marque : un traducteur ne doit pas pouvoir
## la casser.
func test_no_translation_key_carries_a_mark() -> void:
	var po := FileAccess.get_file_as_string("res://i18n/en.po")
	for mark in [Glossary.START, Glossary.SEPARATOR, Glossary.END]:
		assert_false(po.contains(mark))


## Les encadrés se posent hors du panneau qui les montre quand il y a la place, et
## restent dans le cadrage sinon.
func test_boxes_avoid_their_owner_and_stay_on_screen() -> void:
	var bounds := Rect2(0, 0, 640, 330)
	var heights: Array[float] = [40.0, 40.0]
	var panel := Rect2(400, 0, 240, 330)
	var tip := Rect2(250, 50, 140, 60)
	var boxes := GlossaryBoxes.layout(tip, panel, bounds, heights)
	assert_eq(boxes.size(), 2)
	assert_lt(boxes[0].end.x, tip.position.x + 0.1, "à gauche : à droite, c'est le panneau")
	assert_gt(boxes[1].position.y, boxes[0].end.y, "empilés")
	var cornered := GlossaryBoxes.layout(Rect2(0, 300, 600, 20), panel, bounds, heights)
	for r in cornered:
		assert_true(bounds.encloses(r), "dans le cadrage : %s" % r)
