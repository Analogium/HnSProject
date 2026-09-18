extends GutTest

## Le changement de langue en pleine partie : ce qui est déjà à l'écran se
## retraduit, sans être recréé.
##
## Les `Label` et les `Button` des scènes se retraduisent seuls — Godot s'en
## charge. Mais **tout ce que ce jeu dessine à la main** ne change qu'en
## redessinant, et ce qui **mesure** un texte une fois pour toutes garderait une
## largeur calculée dans l'autre langue. Ce sont les deux pièges du §9, et ils ne
## se voient qu'en changeant de langue devant un panneau ouvert.

var _player: Player
var _panel: ManualPanel


func before_each() -> void:
	_player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_player)
	_panel = ManualPanel.new()
	_panel.size = Vector2(210.0, 196.0)
	add_child_autofree(_panel)
	await wait_process_frames(1)
	_panel.bind(_player)
	_panel.visible = true


## Le filet du §9 : un test qui laisse le jeu en anglais fait échouer les suivants
## loin de sa propre cause.
func after_each() -> void:
	if Settings.language != Settings.FRENCH:
		Settings.from_dict({"language": Settings.FRENCH})


## Une fiche de compétence ouverte passe à l'anglais sur place : le panneau n'est
## ni recréé, ni rouvert, et ses lignes viennent toujours du même livre.
func test_an_open_sheet_retranslates_without_being_recreated() -> void:
	var book := _open_book()
	var skill: Skill = book.base.manual.cells[0].skill
	var identity := _panel.get_instance_id()

	var before := _labels(book, skill)
	# Majuscule : la fiche la pose sur chaque intitulé depuis le jalon 20.
	assert_has(before, "Coût", "en français : %s" % [before])

	Settings.from_dict({"language": Settings.ENGLISH})
	await wait_process_frames(1)

	assert_eq(_panel.get_instance_id(), identity, "c'est le même panneau")
	var after := _labels(book, skill)
	assert_has(after, "Cost", "en anglais : %s" % [after])
	assert_does_not_have(after, "Coût", "et plus rien de français")


## Et il **redessine** : sans la notification, la fiche garderait ses mots
## français à l'écran jusqu'au prochain survol, alors que ses données ont changé.
func test_the_panel_redraws_on_language_change() -> void:
	_open_book()
	await wait_process_frames(1)

	var drawings := [0]
	_panel.draw.connect(func() -> void: drawings[0] += 1)

	Settings.from_dict({"language": Settings.ENGLISH})
	await wait_process_frames(2)
	assert_gt(drawings[0], 0, "le panneau s'est repeint tout seul")


## L'étiquette au-dessus d'un ennemi mesure son texte **une fois**, à
## l'apparition. Après un changement de langue, un nom plus long resterait centré
## sur l'ancienne largeur — ou pire, resterait dans l'ancienne langue.
func test_an_elite_tag_is_remeasured() -> void:
	var caption := AffixTag.new()
	add_child_autofree(caption)
	await wait_process_frames(1)

	var ravenous: Affix = AffixPool.ALL[4]
	caption.set_affixes([ravenous] as Array[Affix])
	var line: AffixTag.Line = caption._lines[0]
	assert_eq(line.text, "Vorace")
	var half_width := line.half

	Settings.from_dict({"language": Settings.ENGLISH})
	await wait_process_frames(1)

	var after: AffixTag.Line = caption._lines[0]
	assert_eq(after.text, "Ravenous", "le nom a suivi")
	assert_ne(after.half, half_width, "et il a été re-mesuré")


## Un livre posé au râtelier, monté au plafond, avec un point placé dans sa
## première case — de quoi que la fiche ait des lignes à montrer.
func _open_book() -> Item:
	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	book.manual.gain_experience(999999)
	book.manual.invest(book.base.manual, book.base.manual.cells[0].skill.id)
	_player.study(book)
	return book


## Les intitulés de la fiche, dans l'ordre où elle les écrit.
func _labels(book: Item, skill: Skill) -> PackedStringArray:
	var out := PackedStringArray()
	for line in _panel._skill_sheet(book.manual, skill).lines:
		out.append(line.label_of)
	return out
