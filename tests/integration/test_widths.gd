extends GutTest

## Ce qui est dessiné dans une largeur fixe doit tenir **dans les deux langues**.
##
## Rien n'avertit qu'un texte déborde : il se superpose au voisin, ou sort du
## cadre, et seule une capture le montre — dans une langue à la fois. « moyenne
## par lancer » devient « average per cast », « vitesse d'incantation » devient
## « cast speed » : l'anglais est tantôt plus court, tantôt plus long, et c'est
## celui qu'on ne regarde pas qui déborde.
##
## Les largeurs viennent des panneaux et de la scène de zone, jamais recopiées
## ici : un panneau élargi d'un pixel ne doit pas faire passer un test qui
## validerait sa propre copie.

## L'air minimal entre un intitulé et la valeur calée à sa droite. Deux textes
## qui se touchent se lisent comme un seul mot.
const MARGIN := 4.0

var _player: Player
var _sheet: ManualPanel
var _char: StatsPanel
var _bar: SkillBarPanel
var _police: Font


func before_each() -> void:
	_police = ThemeDB.fallback_font
	_player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(_player)

	_sheet = ManualPanel.new()
	_place(_sheet, "Manuals")
	_char = StatsPanel.new()
	# Son titre vit dans `zone.tscn` ; sans lui, `_ready` colore un nœud nul.
	var title_text := Label.new()
	title_text.name = "Title"
	_char.add_child(title_text)
	_place(_char, "Stats")
	_bar = SkillBarPanel.new()
	_place(_bar, "Bar")
	await wait_process_frames(1)
	for panel in [_sheet, _char, _bar]:
		panel.bind(_player)

	var book := Item.new(ItemCatalog.by_id("manual_lightning"))
	book.manual.gain_experience(999999)
	for skill in book.base.manual.skills():
		for i in skill.points_max():
			book.manual.invest(book.base.manual, skill.id)
	_player.study(book)


## Le filet du §9 : un test qui laisse le jeu en anglais fait échouer les suivants
## loin de sa propre cause.
func after_each() -> void:
	if Settings.language != Settings.FRENCH:
		Settings.from_dict({"language": Settings.FRENCH})


# --------------------------------------------------------------------------
# Les trois panneaux
# --------------------------------------------------------------------------

## La fiche d'une compétence : intitulé à gauche, valeur calée à droite, dans
## cent soixante-dix pixels. C'est la plus étroite du jeu, et celle qui porte le
## plus de mots.
func test_the_skill_sheet_fits_in_both_languages() -> void:
	var book: Item = _player.rack.at(0)
	var width := ManualPanel.SHEET_W - ManualPanel.SHEET_PAD * 2.0

	for language in [Settings.FRENCH, Settings.ENGLISH]:
		Settings.from_dict({"language": language})
		for skill in book.base.manual.skills():
			# La fiche telle que le dessin la monte, sous-titre compris : mesurer
			# les mots-clés de la compétence plutôt que ceux du **geste résolu**
			# reviendrait à mesurer un texte que la page n'écrit pas.
			_measure_sheet(
				_sheet._skill_sheet(book.manual, skill), width, language
			)


## Les fiches d'un passif et d'un nœud d'arbre, dans le même cadre étroit. Le
## nœud est le plus exposé : « demande » et « 3 points dans Lames tournoyantes »
## sur la même ligne, et un nom de compétence au bout.
func test_passive_and_node_sheets_fit_in_both_languages() -> void:
	var width := ManualPanel.SHEET_W - ManualPanel.SHEET_PAD * 2.0
	for language in [Settings.FRENCH, Settings.ENGLISH]:
		Settings.from_dict({"language": language})
		for model: ItemBase in ItemCatalog.ALL:
			if model.manual == null:
				continue
			# Un livre neuf : c'est lui qui montre les lignes « demande », les plus
			# longues des deux fiches.
			var book := Item.new(model)
			for cell: ManualCell in model.manual.cells:
				if cell.passive != null:
					_measure_sheet(
						_sheet._passive_sheet(book.manual, cell.passive), width, language
					)
				for node: TalentNode in cell.talents:
					_measure_sheet(
						_sheet._node_sheet(book.manual, cell, node), width, language
					)


func _measure_sheet(sheet: ManualPanel.Sheet, width: float, language: String) -> void:
	_fits(sheet.title_text, width, ManualPanel.TITLE_SIZE, "%s : le titre" % language)
	_fits(sheet.subtitle, width, ManualPanel.FONT_SIZE, "%s : le sous-titre" % language)
	for line in sheet.lines:
		_fit_together(
			line.label_of, line.value, width, ManualPanel.FONT_SIZE,
			"%s : « %s » de « %s »" % [language, line.label_of, sheet.title_text]
		)


## Les deux lignes d'aide de la page des manuels, en bas de la fenêtre : elles
## portent trois gestes, et l'anglais n'a pas les mêmes mots pour « clic droit ».
func test_the_page_help_lines_fit_in_both_languages() -> void:
	var width := _sheet.size.x - ManualPanel.PAD * 2.0
	for language in [Settings.FRENCH, Settings.ENGLISH]:
		Settings.from_dict({"language": language})
		for text_value in [
			Texts.t("[clic] ouvrir ou investir     [clic droit] ranger"),
			Texts.t("[clic] +1     [clic droit] -1     [échap] retour"),
		]:
			_fits(text_value, width, ManualPanel.FONT_SIZE, "%s : l'aide de la page" % language)


## La fiche de personnage : un quart de la largeur du cadrage, pour une vingtaine
## de lignes et six titres de groupe.
func test_the_character_sheet_fits_in_both_languages() -> void:
	for language in [Settings.FRENCH, Settings.ENGLISH]:
		Settings.from_dict({"language": language})
		var width := _char.size.x - StatsPanel.PAD * 2.0

		_fits(
			Texts.t("C pour fermer"), width, StatsPanel.FONT_SIZE, "%s : l'aide" % language
		)
		for group in StatsPanel.GROUPS:
			_fits(
				Texts.t(group[0]), width, StatsPanel.FONT_SIZE,
				"%s : le titre « %s »" % [language, group[0]]
			)
			for field in group[1]:
				_fit_together(
					_char._label_of(field), _char._value_of(field), width,
					StatsPanel.FONT_SIZE, "%s : la ligne « %s »" % [language, field]
				)


## Le menu de la barre : une icône, puis le nom de la compétence. C'est le seul
## endroit où un nom de sort s'écrit en entier à côté d'une image.
func test_the_bar_menu_fits_in_both_languages() -> void:
	for language in [Settings.FRENCH, Settings.ENGLISH]:
		Settings.from_dict({"language": language})
		var frame := _bar._menu_frame(_bar._entries().size())
		# Le nom commence après l'icône, et l'entrée garde son air à droite.
		var width := frame.size.x - float(SkillIcon.SIDE) - 10.0

		_fits(
			Texts.t("— vider la case —"), frame.size.x - 6.0, SkillBarPanel.FONT_SIZE,
			"%s : l'entrée qui vide" % language
		)
		for skill in _player.available_skills():
			_fits(
				skill.displayed_name(), width, SkillBarPanel.FONT_SIZE,
				"%s : « %s » dans le menu" % [language, skill.id]
			)


# --------------------------------------------------------------------------
# Les outils
# --------------------------------------------------------------------------

## Le panneau prend la place qu'il occupe **dans la scène de zone** : ancres et
## décalages, comme Godot les résout. Une taille inventée ici validerait un
## panneau qui n'est pas celui du jeu.
func _place(panel: Control, node_name: String) -> void:
	var base := Vector2(Settings.base_size())
	var state := (load("res://world/zone.tscn") as PackedScene).get_state()
	for i in state.get_node_count():
		if state.get_node_name(i) != node_name:
			continue
		var p := {}
		for j in state.get_node_property_count(i):
			p[state.get_node_property_name(i, j)] = state.get_node_property_value(i, j)
		panel.size = Vector2(
			float(p.get("anchor_right", 0.0) - p.get("anchor_left", 0.0)) * base.x
				+ float(p.get("offset_right", 0.0) - p.get("offset_left", 0.0)),
			float(p.get("anchor_bottom", 0.0) - p.get("anchor_top", 0.0)) * base.y
				+ float(p.get("offset_bottom", 0.0) - p.get("offset_top", 0.0))
		)
		break
	assert_gt(panel.size.x, 0.0, "le cadre de « %s » vient bien de la scène" % node_name)
	add_child_autofree(panel)


## Par `RichText`, comme le dessin : le terme en gras, la marque sans largeur.
func _width(text_value: String, size_value: int) -> float:
	return RichText.width(_police, text_value, size_value)


func _fits(text_value: String, width: float, size_value: int, what: String) -> void:
	assert_lte(
		_width(text_value, size_value), width,
		"%s — « %s » déborde de %.0f px" % [
			what, Glossary.plain(text_value), _width(text_value, size_value) - width
		]
	)


## Un intitulé à gauche et sa valeur calée à droite : ce qui compte est qu'ils ne
## se touchent pas.
func _fit_together(
	left: String, right_side: String, width: float, size_value: int, what: String
) -> void:
	var occupies := _width(left, size_value) + _width(right_side, size_value) + MARGIN
	assert_lte(
		occupies, width,
		"%s — « %s » et « %s » se chevauchent de %.0f px" % [
			what, Glossary.plain(left), Glossary.plain(right_side), occupies - width
		]
	)
