extends GutTest

## L'onglet des touches : cliquer une action, appuyer, et le jeu répond à la
## nouvelle touche. Aucun test ne pilote un vrai clavier ; l'appui passe par
## `_input` appelé à la main, comme partout ailleurs dans cette campagne.

var _zone: Node2D
var _menu: CanvasLayer


func before_each() -> void:
	_zone = load("res://world/zone.tscn").instantiate()
	add_child_autofree(_zone)
	_menu = _zone.get_node("PauseMenu")
	await wait_physics_frames(1)


## La table du moteur et le disque sont globaux : rendus dans l'état où on les a
## trouvés, sinon l'échec voyage jusqu'au test suivant.
func after_each() -> void:
	Settings.reset_key_binds()
	get_tree().paused = false


func _press(code: Key) -> InputEventKey:
	var key := InputEventKey.new()
	key.keycode = code
	key.pressed = true
	return key


## Une ligne par action, dans l'ordre de la table : la liste n'est écrite qu'une
## fois, et l'onglet la suit.
func test_the_tab_shows_one_row_per_action() -> void:
	_menu.open()
	_menu._show_keys()
	assert_true(_menu.keys.visible, "l'onglet est ouvert")
	var rows: Array = _menu._key_buttons()
	assert_eq(rows.size(), Keybinds.ACTIONS.size(), "une ligne par action, colonnes confondues")
	var first: Button = rows[0]
	assert_string_contains(first.text, Keybinds.label_of(String(first.name)))
	assert_string_contains(first.text, Keybinds.key_label(String(first.name)))


## Le geste entier : la ligne, la touche, et la zone qui répond à la nouvelle.
func test_a_captured_key_rebinds_the_action() -> void:
	_menu.open()
	_menu._show_keys()
	_menu._capture("panel_inventory")
	_menu._input(_press(KEY_J))

	assert_eq(Settings.key_binds.get("panel_inventory", ""), "key:%d" % KEY_J, "le choix est écrit")
	assert_eq(Keybinds.key_label("panel_inventory"), "J", "la table du moteur suit")

	_menu.close()
	_zone._unhandled_input(_press(KEY_J))
	assert_true(_zone.inventory.visible, "et la zone ouvre le sac sur la nouvelle touche")
	_zone._unhandled_input(_press(KEY_I))
	assert_true(_zone.inventory.visible, "l'ancienne ne fait plus rien")


## Échap sort de la capture sans rien changer : c'est la sortie de secours, et on ne
## la bind pas — une action qui l'aurait mangée enfermerait le joueur.
func test_escape_cancels_the_capture() -> void:
	_menu.open()
	_menu._show_keys()
	_menu._capture("panel_inventory")
	_menu._input(_press(KEY_ESCAPE))

	assert_eq(_menu._capturing, "", "la capture est finie")
	assert_false(Settings.key_binds.has("panel_inventory"), "et rien n'a été écrit")
	assert_eq(Keybinds.key_label("panel_inventory"), "I")


## Le relâchement du clic qui ouvre la capture n'est pas la touche voulue : sans ce
## tri, l'action se rebinderait sur lui-même à l'instant où on la choisit.
func test_a_mouse_release_is_not_a_choice() -> void:
	_menu.open()
	_menu._show_keys()
	_menu._capture("panel_inventory")
	var release := InputEventMouseButton.new()
	release.button_index = MOUSE_BUTTON_LEFT
	release.pressed = false
	_menu._input(release)
	assert_eq(_menu._capturing, "panel_inventory", "on attend toujours")

	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_MIDDLE
	click.pressed = true
	_menu._input(click)
	assert_eq(Keybinds.key_label("panel_inventory"), Texts.t("clic M"), "un bouton se bind")


## « Rétablir » rend tout à `project.godot`, y compris ce qu'un échange avait
## déplacé.
func test_reset_gives_every_key_back() -> void:
	Settings.bind("panel_inventory", _press(KEY_C))
	assert_eq(Keybinds.key_label("panel_character"), "I", "l'échange a eu lieu")

	Settings.reset_key_binds()
	assert_eq(Keybinds.key_label("panel_inventory"), "I")
	assert_eq(Keybinds.key_label("panel_character"), "C")
	assert_eq(Settings.key_binds, {}, "et plus rien n'est écrit dans les réglages")


## La page du filtre : ajouter une règle l'ouvre dans l'éditeur, cocher écrit le
## filtre, et l'ordre se change par les boutons.
func test_the_loot_page_edits_the_rules() -> void:
	var before := Settings.to_dict()
	Settings.from_dict({"loot_filter_on": true, "loot_filter": []})
	_menu.open()
	_menu._show_loot()
	assert_false(_menu.loot_form.visible, "sans règle, pas d'éditeur")

	var buttons := "Root/Center/Panel/Loot/Columns/RulesSide/RuleButtons/"
	(_menu.get_node(buttons + "Add") as Button).pressed.emit()
	assert_eq(Settings.loot_filter.rules.size(), 1)
	assert_true(_menu.loot_form.visible, "la règle ajoutée s'ouvre")

	_menu._loot_button("Head/Action").pressed.emit()
	var rule: LootFilter.Rule = Settings.loot_filter.rules[0]
	assert_eq(rule.action, LootFilter.Action.HIDE, "le bouton tourne de Montrer à Masquer")
	var magic: CheckBox = _menu.loot_form.get_node("Rarities").get_child(Item.Rarity.MAGIC)
	magic.button_pressed = true
	assert_eq(rule.rarities, [Item.Rarity.MAGIC] as Array[int], "cocher écrit la règle elle-même")
	rule.affixes = ["precise"]
	var ring: CheckBox = _menu.loot_form.get_node("Families").get_child(LootFilter.FAMILIES.keys().find("ring"))
	ring.button_pressed = true
	assert_eq(rule.families, ["ring"] as Array[String])
	assert_true(rule.affixes.is_empty(), "l'affixe d'arme part avec le choix des anneaux")
	var offered: int = _menu.loot_form.get_node("AffixScroll/Affixes").get_child_count()
	var ring_names := {}
	for affix: ItemAffix in LootFilter.possible_affixes(rule.families):
		ring_names[_menu.affix_name(affix)] = true
	assert_eq(offered, ring_names.size(), "la liste ne propose que ce qu'un anneau peut porter")
	var first_affix: CheckBox = _menu.loot_form.get_node("AffixScroll/Affixes").get_child(0)
	first_affix.button_pressed = true
	assert_false(rule.affixes.is_empty(), "un affixe coché rejoint la condition")

	(_menu.get_node(buttons + "Add") as Button).pressed.emit()
	(_menu.get_node(buttons + "Up") as Button).pressed.emit()
	assert_eq(Settings.loot_filter.rules[1], rule, "la nouvelle est montée au-dessus")
	assert_string_contains((_menu.loot_rules.get_child(1) as Button).text, Texts.t("Masquer"), "la liste suit")
	# Le clic sur une ligne refait la liste depuis le signal de cette ligne même.
	(_menu.loot_rules.get_child(0) as Button).pressed.emit()
	assert_eq(_menu._rule_index, 0, "cliquer une ligne l'ouvre")
	assert_true((_menu.loot_rules.get_child(0) as Button).button_pressed, "et la liste refaite la montre choisie")
	(_menu.get_node(buttons + "Delete") as Button).pressed.emit()
	assert_eq(Settings.loot_filter.rules, [rule] as Array[LootFilter.Rule], "supprimer ôte la règle choisie")

	_menu.loot_active.button_pressed = false
	assert_false(Settings.loot_filter_on, "la case du haut est la touche")
	Settings.from_dict(before)
