extends GutTest

## La page du filtre de butin, pilotée par ses boutons : cartes, blocs de conditions,
## recherche d'affixes, glisser-déposer et banc d'essai.

var _zone: Node2D
var _menu: CanvasLayer
var _panel: LootFilterPanel
var _before: Dictionary


func before_each() -> void:
	_before = Settings.to_dict()
	Settings.from_dict({"loot_filter_on": true, "loot_filter": []})
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	_menu = _zone.get_node("PauseMenu")
	_panel = _menu.loot
	await wait_physics_frames(1)
	_menu.open()
	_menu._show_loot()


func after_each() -> void:
	Settings.from_dict(_before)
	get_tree().paused = false


## Le premier bouton, sous `root`, dont le texte commence ainsi.
func _button(text_start: String, root: Node = null) -> Button:
	for node in (root if root != null else _panel).find_children("*", "Button", true, false):
		var button := node as Button
		if button.text.begins_with(text_start) and not button.is_queued_for_deletion():
			return button
	return null


func _click(button: Button) -> void:
	assert_not_null(button)
	if button.toggle_mode:
		button.button_pressed = not button.button_pressed
	button.pressed.emit()


func _card(index: int) -> PanelContainer:
	return _panel._cards.get_child(index)


func _click_card(index: int) -> void:
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	_card(index).gui_input.emit(click)


func test_the_page_takes_the_screen_and_escape_comes_back() -> void:
	assert_true(_panel.visible)
	assert_false(_menu.center.visible, "le cadre centré s'efface")
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	_menu._unhandled_input(escape)
	assert_false(_panel.visible)
	assert_true(_menu.options.visible, "Échap revient aux options")


func test_a_rule_is_built_from_blocks() -> void:
	_click(_button("+  " + Texts.t("Ajouter une règle")))
	assert_eq(Settings.loot_filter.rules.size(), 1)
	var rule: LootFilter.Rule = Settings.loot_filter.rules[0]

	_click(_button(Texts.t("Masquer"), _panel._editor))
	assert_eq(rule.action, LootFilter.Action.HIDE)

	_click(_button(Texts.t("Rareté"), _panel._editor))
	_click(_button(Texts.t("Magique"), _panel._editor))
	assert_eq(rule.rarities, [Item.Rarity.MAGIC] as Array[int], "la puce écrit la règle")

	_click(_button(Texts.t("Type d'objet"), _panel._editor))
	var ring := _panel._editor.find_children("*", "Button", true, false).filter(
		func(b: Button) -> bool: return b.tooltip_text == Texts.t("Anneaux"))[0] as Button
	_click(ring)
	assert_eq(rule.families, ["ring"] as Array[String], "l'icône écrit la règle")
	assert_string_contains((_card(0).tooltip_text), Texts.t("Anneaux"), "la carte suit")

	# Un bloc retiré efface sa condition.
	var rarity_block := _button(Texts.t("Magique"), _panel._editor).get_parent().get_parent()
	_click(_button("×", rarity_block))
	assert_true(rule.rarities.is_empty(), "la croix retire la condition")


func test_affixes_are_searched_among_the_possible_ones() -> void:
	var rule := LootFilter.Rule.new()
	rule.families = ["ring"]
	Settings.loot_filter.rules = [rule]
	_panel.open()
	_click(_button(Texts.t("Affixes"), _panel._editor))

	var life := LootFilterPanel.affix_name(ItemAffixPool.by_id("vigorous"))
	var weapon_only := LootFilterPanel.affix_name(ItemAffixPool.by_id("precise"))
	_panel._search.text = life
	_panel._search.text_changed.emit(life)
	assert_null(_button("+ " + weapon_only, _panel._affix_results), "rien d'arme sur un anneau")
	_click(_button("+ " + life, _panel._affix_results))
	assert_eq(rule.affixes, ["vigorous"] as Array[String], "cliquer un résultat l'ajoute")
	assert_not_null(_button(life, _panel._affix_chips), "et il devient une puce")

	_click(_button(life, _panel._affix_chips))
	assert_true(rule.affixes.is_empty(), "cliquer la puce le retire")


## Le bloc des bases ne propose que celles des types cochés, et décocher un type
## emporte ses bases. Décocher le **dernier** type rend toutes les bases possibles :
## la base choisie reste, et la règle garde son sens.
func test_bases_follow_the_types() -> void:
	var rule := LootFilter.Rule.new()
	rule.families = ["weapon"]
	Settings.loot_filter.rules = [rule]
	_panel.open()
	_click(_button(Texts.t("Bases"), _panel._editor))
	assert_null(_button(Texts.t("Anneau"), _panel._base_box), "pas d'anneau parmi les armes")
	rule.families.append("ring")
	_click(_button(Texts.t("Épée large"), _panel._base_box))
	assert_eq(rule.bases, ["broadsword"] as Array[String])
	assert_string_contains(_card(0).tooltip_text, Texts.t("Épée large"), "la carte la nomme")

	var weapon := _panel._editor.find_children("*", "Button", true, false).filter(
		func(b: Button) -> bool: return b.tooltip_text == Texts.t("Armes"))[0] as Button
	_click(weapon)
	assert_true(rule.bases.is_empty(), "le type décoché emporte ses bases")
	assert_null(_button(Texts.t("Épée large"), _panel._base_box), "et le bloc ne la propose plus")
	assert_not_null(_button(Texts.t("Anneau"), _panel._base_box), "les anneaux restent")


## Une règle chargée — neuf bases, trois raretés, des affixes — ne doit pas élargir sa
## carte : la colonne pousserait l'éditeur et le banc hors de l'écran.
func test_a_crowded_rule_keeps_its_card_width() -> void:
	var rule := LootFilter.Rule.new()
	rule.action = LootFilter.Action.RECOLOR
	rule.rarities = [Item.Rarity.COMMON, Item.Rarity.MAGIC, Item.Rarity.RARE]
	rule.bases.assign(LootFilter.possible_bases(["weapon", "helmet"] as Array[String]).map(func(b: ItemBase) -> String: return b.id))
	rule.affixes = ["vigorous", "regenerating", "keen", "precise"]
	Settings.loot_filter.rules = [rule]
	_panel.open()
	await wait_process_frames(2)
	assert_lte(_card(0).get_combined_minimum_size().x, 200.0, "la carte tient dans sa colonne")
	assert_string_contains(_card(0).tooltip_text, Texts.t("Marteau de guerre"), "et sa bulle nomme tout")


## Cliquer une carte la choisit **sans la détruire** : c'est elle qui porterait un
## glissement. Le dépôt change l'ordre.
func test_cards_are_picked_and_dragged() -> void:
	var first := LootFilter.Rule.new()
	var second := LootFilter.Rule.new()
	second.action = LootFilter.Action.HIDE
	Settings.loot_filter.rules = [first, second]
	_panel.open()

	var card := _card(1)
	_click_card(1)
	assert_eq(_panel._rule_index, 1)
	assert_true(is_instance_valid(card) and card.is_inside_tree(), "la carte cliquée survit")
	assert_string_contains(_panel._editor.find_children("*", "Label", true, false)[0].text, "2")

	_panel.drop_rule(1, 0)
	assert_eq(Settings.loot_filter.rules[0], second, "déposée en tête")

	_click(_button("✓", _card(0)))
	assert_false(second.enabled, "la coche éteint la règle")


## Le banc tire comme le butin, redonne le même tirage à la même graine, et le compte
## de chaque carte est celui de ses lignes.
func test_the_bench_says_who_decides() -> void:
	var a := LootFilterPanel.bench_items(10, 7)
	var b := LootFilterPanel.bench_items(10, 7)
	assert_eq(a.size(), LootFilterPanel.BENCH_SIZE)
	for i in a.size():
		assert_eq(a[i].display_name(), b[i].display_name(), "même graine, même banc")

	var hide_all := LootFilter.Rule.new()
	hide_all.action = LootFilter.Action.HIDE
	Settings.loot_filter.rules = [hide_all]
	_panel.open()
	var count: Label = _card(0).find_children("*", "Label", true, false).filter(
		func(l: Label) -> bool: return l.text == str(LootFilterPanel.BENCH_SIZE))[0]
	assert_not_null(count, "une règle sans condition décide tout le banc")
	for line in _panel._bench_list.get_children():
		assert_almost_eq((line.get_child(0) as Control).modulate.a, LootFilterPanel.HIDDEN_ALPHA, 0.001, "et chaque nom s'y montre masqué")


## Survoler un nom du banc montre l'infobulle de l'objet, affixes compris ; le quitter
## l'efface.
func test_hovering_the_bench_shows_the_item() -> void:
	var line: HBoxContainer = _panel._bench_list.get_child(0)
	var plate: Control = line.get_child(0)
	plate.mouse_entered.emit()
	var item: Item = _panel._hovered
	assert_not_null(item, "le nom survolé désigne son objet")
	assert_eq(item, _panel._bench[0])
	await wait_process_frames(1)
	var texts := ItemTooltip.lines(item, false).map(func(l: ItemTooltip.Line) -> String: return l.text)
	for rolled in item.explicits:
		assert_true(texts.has(RichText.capitalized(item.explicit_line(rolled))), "chaque affixe a sa ligne")
	plate.mouse_exited.emit()
	assert_null(_panel._hovered, "la souris partie, l'infobulle s'efface")


func _menu_button(title: String) -> MenuButton:
	for node in _panel.find_children("*", "MenuButton", true, false):
		if (node as MenuButton).text == title:
			return node
	return null


## Importer **ajoute** un filtre, qui prend la main : celui qu'on avait reste là.
func test_importing_a_code_adds_a_filter() -> void:
	var mine := LootFilter.Rule.new()
	mine.action = LootFilter.Action.HIDE
	Settings.loot_filter.rules = [mine]
	_panel.open()
	var theirs := LootFilter.new()
	theirs.name = "Le filtre d'un ami"
	var shared := LootFilter.Rule.new()
	shared.families = ["ring"]
	theirs.rules = [shared, LootFilter.Rule.new()]

	_panel.import_code("pas un code", "refusé")
	assert_eq(_panel._status.text, "refusé", "un texte quelconque est refusé, et on le dit")
	assert_eq(Settings.loot_filters.size(), 1)

	_panel.import_code(theirs.to_code(), "")
	assert_eq(Settings.loot_filters.size(), 2, "le filtre lu s'ajoute")
	assert_eq(Settings.loot_filter.name, "Le filtre d'un ami", "et décide")
	assert_eq(Settings.loot_filters[0].rules, [mine] as Array[LootFilter.Rule], "l'ancien est intact")
	assert_eq(_panel._cards.get_child_count(), 2, "la page montre le nouveau")
	assert_string_contains(_panel._filters.text, "Le filtre d'un ami", "et son nom")


## Le menu des filtres : en créer un, le renommer, en changer, et supprimer après
## confirmation.
func test_the_filter_menu_manages_filters() -> void:
	var first_rule := LootFilter.Rule.new()
	Settings.loot_filter.rules = [first_rule]
	_panel.open()
	var popup := _panel._filters.get_popup()

	popup.id_pressed.emit(LootFilterPanel.NEW_FILTER)
	assert_eq(Settings.loot_filters.size(), 2)
	assert_eq(_panel._cards.get_child_count(), 0, "le nouveau filtre est vide")
	assert_true(_panel._rename.visible, "et s'ouvre au renommage")
	_panel._rename.text = "Chasse aux pièces"
	_panel._rename.text_submitted.emit(_panel._rename.text)
	assert_eq(Settings.loot_filter.name, "Chasse aux pièces")
	assert_string_contains(_panel._filters.text, "Chasse aux pièces", "le menu porte le nom")

	popup.id_pressed.emit(0)
	assert_eq(Settings.loot_filter_index, 0, "choisir un filtre dans le menu le rend actif")
	assert_eq(_panel._cards.get_child_count(), 1, "et la page le montre")

	popup.id_pressed.emit(LootFilterPanel.DUPLICATE_FILTER)
	assert_eq(Settings.loot_filters.size(), 3)
	assert_eq(Settings.loot_filter.rules.size(), 1, "la copie a les règles")

	popup.id_pressed.emit(LootFilterPanel.DELETE_FILTER)
	assert_true(_panel._confirm.visible, "supprimer demande")
	assert_eq(Settings.loot_filters.size(), 3, "rien ne part avant la réponse")
	_click(_panel._confirm_yes)
	assert_eq(Settings.loot_filters.size(), 2, "confirmé, il part")


## Le menu « Exporter » copie le code ; un fichier enregistré se relit tel quel.
func test_a_filter_goes_through_a_file() -> void:
	var rule := LootFilter.Rule.new()
	rule.bases = ["coin_copper"]
	rule.action = LootFilter.Action.HIDE
	Settings.loot_filter.rules = [rule]
	_panel.open()
	var before := Settings.loot_filter.to_list()

	_menu_button(Texts.t("Exporter")).get_popup().id_pressed.emit(0)
	assert_string_contains(_panel._status.text, "1", "l'export dit combien de règles partent")

	var path := "user://filtre-test.txt"
	_panel.save_file(path)
	Settings.loot_filter.rules = []
	_panel.load_file(path)
	assert_eq(Settings.loot_filter.to_list(), before, "sans règle à perdre, le fichier s'applique d'emblée")
	DirAccess.remove_absolute(path)

	_panel.load_file("user://inexistant.txt")
	assert_eq(_panel._status.text, Texts.t("Ce fichier n'est pas un filtre de butin"))
