extends CanvasLayer

## Le menu d'échappement et ses options. PROCESS_MODE_ALWAYS : en WHEN_PAUSED, il ne
## pourrait plus s'ouvrir une fois le jeu repris.

@onready var root: Control = $Root
@onready var menu: VBoxContainer = $Root/Center/Panel/Menu
@onready var options: VBoxContainer = $Root/Center/Panel/Options
@onready var bars_check: CheckBox = $Root/Center/Panel/Options/Bars
@onready var names_check: CheckBox = $Root/Center/Panel/Options/Names
@onready var taken_check: CheckBox = $Root/Center/Panel/Options/DamageTaken
@onready var dealt_check: CheckBox = $Root/Center/Panel/Options/DamageDealt
@onready var dps_check: CheckBox = $Root/Center/Panel/Options/DpsMeter
@onready var window_btn: Button = $Root/Center/Panel/Options/Window
## Libellé posé par le code, **dans la langue qu'il annonce**.
@onready var language_btn: Button = $Root/Center/Panel/Options/Language
@onready var keys: VBoxContainer = $Root/Center/Panel/Keys
## Une ligne par action, posées par le code depuis `Keybinds.ACTIONS` : la liste est
## déjà écrite là-bas, et seize nœuds dans la scène la répéteraient.
##
## **Deux colonnes** : seize lignes en une seule dépassent du cadre de 360 px, et le
## bouton « Retour » se retrouve hors de l'écran.
@onready var key_rows: HBoxContainer = $Root/Center/Panel/Keys/Rows
@onready var loot: VBoxContainer = $Root/Center/Panel/Loot
@onready var loot_active: CheckBox = $Root/Center/Panel/Loot/Active
@onready var loot_rules: VBoxContainer = $Root/Center/Panel/Loot/Columns/RulesSide/RulesScroll/Rules
@onready var loot_form: VBoxContainer = $Root/Center/Panel/Loot/Columns/Editor/Form
@onready var loot_empty: Label = $Root/Center/Panel/Loot/Columns/Editor/Empty

## La règle ouverte dans l'éditeur, −1 sans règle choisie.
var _rule_index := -1

## L'action dont on attend la touche, vide hors capture. Un seul champ : deux lignes
## ne peuvent pas écouter en même temps.
var _capturing := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	root.visible = false
	options.visible = false
	keys.visible = false
	loot.visible = false
	_build_key_rows()

	# La valeur est posée avant la connexion : dans l'autre sens, l'initialisation
	# émettrait un toggled et réécrirait le réglage avec lui-même.
	bars_check.button_pressed = Settings.show_health_bars
	bars_check.toggled.connect(func(on: bool) -> void: Settings.show_health_bars = on)
	names_check.button_pressed = Settings.show_affix_names
	names_check.toggled.connect(func(on: bool) -> void: Settings.show_affix_names = on)
	taken_check.button_pressed = Settings.damage_taken_visible
	taken_check.toggled.connect(func(on: bool) -> void: Settings.damage_taken_visible = on)
	dealt_check.button_pressed = Settings.damage_dealt_visible
	dealt_check.toggled.connect(func(on: bool) -> void: Settings.damage_dealt_visible = on)
	dps_check.button_pressed = Settings.dps_meter_visible
	dps_check.toggled.connect(func(on: bool) -> void: Settings.dps_meter_visible = on)
	_bind_opacity($Root/Center/Panel/Options/SpellOpacity, "spell_opacity")
	_bind_opacity($Root/Center/Panel/Options/EnemyOpacity, "enemy_attack_opacity")

	# Un bouton qui tourne : une liste déroulante dessinerait par-dessus le menu.
	window_btn.pressed.connect(_change_window)
	_refresh_window()

	# Une ronde, comme la fenêtre.
	language_btn.pressed.connect(_change_language)
	_refresh_language()

	($Root/Center/Panel/Menu/Resume as Button).pressed.connect(close)
	($Root/Center/Panel/Menu/OptionsBtn as Button).pressed.connect(_show_options)
	($Root/Center/Panel/Menu/Return as Button).pressed.connect(_back_to_menu)
	($Root/Center/Panel/Menu/Quit as Button).pressed.connect(_quit)
	($Root/Center/Panel/Options/Back as Button).pressed.connect(_show_menu)
	($Root/Center/Panel/Options/Pages/KeysBtn as Button).pressed.connect(_show_keys)
	($Root/Center/Panel/Keys/Back as Button).pressed.connect(_show_options)
	($Root/Center/Panel/Options/Pages/LootBtn as Button).pressed.connect(_show_loot)
	($Root/Center/Panel/Loot/Back as Button).pressed.connect(_show_options)
	loot_active.toggled.connect(func(on: bool) -> void: Settings.loot_filter_on = on)
	_connect_loot_editor()
	($Root/Center/Panel/Keys/Reset as Button).pressed.connect(func() -> void:
		Settings.reset_key_binds()
		_refresh_key_rows()
	)


## Un curseur de 0 à 100 sur un réglage de 0 à 1, et son pourcentage à côté.
func _bind_opacity(row: Control, setting: String) -> void:
	var slider: HSlider = row.get_node("Slider")
	var percent: Label = row.get_node("Percent")
	slider.value = Settings.get(setting) * 100.0
	percent.text = StatMod.percentage(slider.value)
	slider.value_changed.connect(func(value: float) -> void:
		Settings.set(setting, value / 100.0)
		percent.text = StatMod.percentage(value)
	)


## Les deux libellés écrits par le code, que Godot ne retraduit pas. La garde : la
## notification arrive aussi à l'entrée dans l'arbre, avant les `@onready`.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and is_node_ready():
		_refresh_window()
		_refresh_language()
		_refresh_key_rows()


## En capture, la touche suivante est prise **ici**, avant tout le monde : dans
## `_unhandled_input`, un panneau ou la zone auraient répondu à l'ancienne action
## avant qu'on la remplace.
func _input(event: InputEvent) -> void:
	if _capturing.is_empty() or not _wants(event):
		return
	get_viewport().set_input_as_handled()
	# Échap annule : c'est la sortie de secours, et on ne la bind pas.
	if Keys.pressed_down(event) != KEY_ESCAPE:
		Settings.bind(_capturing, event)
	_capturing = ""
	_refresh_key_rows()


func _unhandled_input(event: InputEvent) -> void:
	if Keys.pressed_down(event) != KEY_ESCAPE:
		return

	# Échap depuis une sous-page revient d'un cran.
	if root.visible and (keys.visible or loot.visible):
		_show_options()
	elif root.visible and options.visible:
		_show_menu()
	elif root.visible:
		close()
	else:
		open()

	get_viewport().set_input_as_handled()


func open() -> void:
	root.visible = true
	_show_menu()
	get_tree().paused = true


func close() -> void:
	root.visible = false
	get_tree().paused = false


## Les deux sorties passent par le même signal : chacune doit écrire la partie.
func _back_to_menu() -> void:
	Game.save_requested.emit()
	# Dépausé avant de changer de scène : l'arbre reste en pause d'une scène à
	# l'autre, et l'écran de sélection naîtrait figé.
	get_tree().paused = false
	Game.goto_scene("res://ui/character_select.tscn")


func _quit() -> void:
	Game.save_requested.emit()
	get_tree().quit()


## Relu sur le réglage, qui a pu être borné à l'écran.
func _change_window() -> void:
	Settings.cycle_scale()
	_refresh_window()


func _refresh_window() -> void:
	window_btn.text = Settings.current_label()


func _change_language() -> void:
	Settings.cycle_language()
	_refresh_language()


func _refresh_language() -> void:
	language_btn.text = Settings.current_language_label()


## Les trois pages sont exclusives, et chacune le dit **en entier** : `open()` repasse
## par le menu, et une page laissée visible s'afficherait par-dessus lui.
func _show_menu() -> void:
	_show_page(menu)


func _show_options() -> void:
	_show_page(options)


func _show_keys() -> void:
	_show_page(keys)
	_refresh_key_rows()


func _show_loot() -> void:
	_show_page(loot)
	_build_loot()


func _show_page(shown: Control) -> void:
	for page: Control in [menu, options, keys, loot]:
		page.visible = page == shown
	# Quitter la page des touches finit la capture : la garder ouverte ferait manger
	# la première touche de la page suivante.
	_capturing = ""


# --------------------------------------------------------------------------
# L'onglet des touches
# --------------------------------------------------------------------------


## Un bouton par action, dans l'ordre de la table. Construit une fois : seul le
## libellé change ensuite.
func _build_key_rows() -> void:
	var columns := key_rows.get_children()
	var half := int(ceilf(Keybinds.ACTIONS.size() / float(columns.size())))
	var placed := 0
	for action: String in Keybinds.ACTIONS:
		var row := Button.new()
		row.name = action
		row.custom_minimum_size = Vector2(170.0, 0.0)
		row.add_theme_font_size_override("font_size", 9)
		row.pressed.connect(_capture.bind(action))
		columns[mini(placed / half, columns.size() - 1)].add_child(row)
		placed += 1
	_refresh_key_rows()


func _refresh_key_rows() -> void:
	for row: Button in _key_buttons():
		var action := String(row.name)
		# Les points de suspension ne se traduisent pas.
		var written := "…" if action == _capturing else Keybinds.key_label(action)
		row.text = "%s   %s" % [Keybinds.label_of(action), written]


## Les lignes des deux colonnes, dans l'ordre de la table.
func _key_buttons() -> Array[Node]:
	var out: Array[Node] = []
	for column: Node in key_rows.get_children():
		out.append_array(column.get_children())
	return out


func _capture(action: String) -> void:
	_capturing = action
	_refresh_key_rows()


## Ce qu'une capture accepte : une touche enfoncée, ou un des trois boutons de
## souris. Le relâchement du clic qui a ouvert la capture n'en est pas un — sans ce
## tri, l'action se rebinderait sur lui-même à l'instant où on la choisit.
func _wants(event: InputEvent) -> bool:
	if Keys.pressed_down(event) != KEY_NONE:
		return true
	var click := event as InputEventMouseButton
	return click != null and click.pressed and Keybinds.MOUSE_LABELS.has(click.button_index)


# --------------------------------------------------------------------------
# Le filtre de butin
# --------------------------------------------------------------------------


## Relue à chaque ouverture : la touche du filtre a pu l'éteindre, et la langue changer.
func _build_loot() -> void:
	loot_active.set_pressed_no_signal(Settings.loot_filter_on)
	loot_active.text = Texts.t("Filtre actif  ({touche})").format({"touche": Keybinds.key_label("loot_filter")})
	_select_rule(mini(_rule_index, Settings.loot_filter.rules.size() - 1))


func _connect_loot_editor() -> void:
	var buttons := "Root/Center/Panel/Loot/Columns/RulesSide/RuleButtons/"
	(get_node(buttons + "Add") as Button).pressed.connect(func() -> void:
		Settings.loot_filter.rules.append(LootFilter.Rule.new())
		_select_rule(Settings.loot_filter.rules.size() - 1)
		Settings.loot_filter_edited()
	)
	(get_node(buttons + "Up") as Button).pressed.connect(_move_rule.bind(-1))
	(get_node(buttons + "Down") as Button).pressed.connect(_move_rule.bind(1))
	(get_node(buttons + "Delete") as Button).pressed.connect(func() -> void:
		if _rule() == null:
			return
		Settings.loot_filter.rules.remove_at(_rule_index)
		_select_rule(mini(_rule_index, Settings.loot_filter.rules.size() - 1))
		Settings.loot_filter_edited()
	)
	# Des boutons qui tournent, comme la fenêtre : une liste déroulante dessinerait
	# par-dessus le menu.
	_loot_button("Head/Action").pressed.connect(func() -> void:
		_rule().action = wrapi(_rule().action + 1, 0, LootFilter.Action.size()) as LootFilter.Action
		_rule_edited()
	)
	_loot_button("Count/MinCount").pressed.connect(func() -> void:
		_rule().min_count = wrapi(_rule().min_count + 1, 1, maxi(_rule().affixes.size(), 1) + 1)
		_rule_edited()
	)
	_loot_button("Count/BestTier").pressed.connect(func() -> void:
		_rule().best_tier = wrapi(_rule().best_tier + 1, 0, _deepest_tier() + 1)
		_rule_edited()
	)


func _loot_button(path: String) -> Button:
	return loot_form.get_node(path)


func _rule() -> LootFilter.Rule:
	var rules := Settings.loot_filter.rules
	return rules[_rule_index] if _rule_index >= 0 and _rule_index < rules.size() else null


func _move_rule(step: int) -> void:
	if _rule() == null:
		return
	Settings.loot_filter.move(_rule_index, step)
	_select_rule(clampi(_rule_index + step, 0, Settings.loot_filter.rules.size() - 1))
	Settings.loot_filter_edited()


## L'éditeur n'est rempli qu'ici : le refaire à chaque case cochée remonterait la
## liste des affixes en haut sous le curseur.
func _select_rule(index: int) -> void:
	_rule_index = index
	var rule := _rule()
	loot_form.visible = rule != null
	loot_empty.visible = rule == null
	_fill_rules()
	if rule == null:
		return
	_fill_colors(rule)
	_fill_checks(loot_form.get_node("Rarities"), _rarity_choices(), rule.rarities)
	_fill_checks(loot_form.get_node("Families"), _family_choices(), rule.families, _families_changed.bind(rule))
	_fill_affixes(rule)
	_refresh_rule_buttons()


## Un bouton par règle, de la plus prioritaire à la dernière, qui la résume.
func _fill_rules() -> void:
	_clear(loot_rules)
	var rules := Settings.loot_filter.rules
	for i in rules.size():
		var row := Button.new()
		row.text = "%d. %s" % [i + 1, rule_summary(rules[i])]
		row.alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.clip_text = true
		row.custom_minimum_size.x = 190.0
		row.add_theme_font_size_override("font_size", 8)
		row.add_theme_color_override("font_color", _summary_color(rules[i]))
		row.toggle_mode = true
		row.set_pressed_no_signal(i == _rule_index)
		row.pressed.connect(_select_rule.bind(i))
		loot_rules.add_child(row)


## Vide une liste que l'on remplit à nouveau. **Détachés puis libérés en différé** :
## la liste se refait souvent depuis le signal d'un de ses propres boutons — cliquer
## une règle refait la liste des règles —, et Godot refuse de libérer un nœud qui émet.
static func _clear(box: Node) -> void:
	for old in box.get_children():
		box.remove_child(old)
		old.queue_free()


func _summary_color(rule: LootFilter.Rule) -> Color:
	match rule.action:
		LootFilter.Action.HIDE:
			return Color(0.55, 0.52, 0.6)
		LootFilter.Action.RECOLOR:
			return rule.color
	return Color.WHITE


## « Masquer : Magique · Anneaux, Amulettes · 2 sur 3 affixes ».
static func rule_summary(rule: LootFilter.Rule) -> String:
	var parts := PackedStringArray()
	if not rule.rarities.is_empty():
		parts.append(", ".join(rule.rarities.map(func(r: int) -> String: return Texts.t(Item.RARITY_LABELS[r]))))
	if rule.families.size() > 2:
		parts.append(Texts.tn("{n} type", "{n} types", rule.families.size()).format({"n": rule.families.size()}))
	elif not rule.families.is_empty():
		parts.append(", ".join(rule.families.map(func(f: String) -> String: return Texts.t(LootFilter.FAMILIES[f]))))
	if not rule.affixes.is_empty():
		parts.append(_count_label(rule))
	if parts.is_empty():
		parts.append(Texts.t("tout"))
	return "%s : %s" % [Texts.t(LootFilter.ACTION_LABELS[rule.action]), " · ".join(parts)]


static func _count_label(rule: LootFilter.Rule) -> String:
	return Texts.t("{n} sur {total} affixes").format({"n": rule.min_count, "total": rule.affixes.size()})


static func _tier_label(rule: LootFilter.Rule) -> String:
	if rule.best_tier == 0:
		return Texts.t("Tous paliers")
	return Texts.t("Palier T{t} ou mieux").format({"t": rule.best_tier})


## Les textes que change un clic : l'action, le compte, le palier, et le résumé.
func _rule_edited() -> void:
	var rule := _rule()
	rule.min_count = clampi(rule.min_count, 1, maxi(rule.affixes.size(), 1))
	_refresh_rule_buttons()
	_fill_rules()
	Settings.loot_filter_edited()


func _refresh_rule_buttons() -> void:
	var rule := _rule()
	_loot_button("Head/Action").text = Texts.t(LootFilter.ACTION_LABELS[rule.action])
	(loot_form.get_node("Head/Colors") as Control).visible = rule.action == LootFilter.Action.RECOLOR
	for swatch: Button in loot_form.get_node("Head/Colors").get_children():
		swatch.set_pressed_no_signal(swatch.get_meta("color") == rule.color)
	_loot_button("Count/MinCount").text = _count_label(rule)
	_loot_button("Count/BestTier").text = _tier_label(rule)
	(loot_form.get_node("Count") as Control).visible = not rule.affixes.is_empty()


func _fill_colors(rule: LootFilter.Rule) -> void:
	var box: HBoxContainer = loot_form.get_node("Head/Colors")
	_clear(box)
	for color: Color in LootFilter.COLORS:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(12, 12)
		swatch.toggle_mode = true
		swatch.set_meta("color", color)
		for state in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
			var style := StyleBoxFlat.new()
			style.bg_color = color
			# Le cadre blanc dit la couleur choisie ; les autres n'en ont pas.
			if state.contains("pressed"):
				style.set_border_width_all(1)
				style.border_color = Color.WHITE
			swatch.add_theme_stylebox_override(state, style)
		swatch.pressed.connect(func() -> void:
			rule.color = color
			_rule_edited()
		)
		box.add_child(swatch)


## `choices` : valeur → libellé ; `chosen` est le tableau de la règle, modifié en place,
## et `after` ce qui en dépend.
func _fill_checks(box: Container, choices: Dictionary, chosen: Variant, after := Callable()) -> void:
	_clear(box)
	for value: Variant in choices:
		var check := CheckBox.new()
		check.text = choices[value]
		check.add_theme_font_size_override("font_size", 8)
		check.button_pressed = chosen.has(value)
		check.toggled.connect(func(on: bool) -> void:
			if on:
				chosen.append(value)
			else:
				chosen.remove_at(chosen.find(value))
			if after.is_valid():
				after.call()
			_rule_edited()
		)
		box.add_child(check)


func _rarity_choices() -> Dictionary:
	var out := {}
	for rarity in Item.RARITY_LABELS.size():
		out[rarity] = Texts.t(Item.RARITY_LABELS[rarity])
	return out


func _family_choices() -> Dictionary:
	var out := {}
	for family: String in LootFilter.FAMILIES:
		out[family] = Texts.t(LootFilter.FAMILIES[family])
	return out


## Un type retiré emporte les affixes que plus rien de coché ne porte : gardés, ils
## compteraient dans « N sur M » sans pouvoir jamais tomber.
func _families_changed(rule: LootFilter.Rule) -> void:
	var possible := LootFilter.possible_affixes(rule.families).map(func(a: ItemAffix) -> String: return a.id)
	for i in range(rule.affixes.size() - 1, -1, -1):
		if not possible.has(rule.affixes[i]):
			rule.affixes.remove_at(i)
	_fill_affixes(rule)


## Par nom et non par affixe : « chance critique accrue » d'arme et de bijou sont
## deux affixes, et une seule ligne pour qui cherche la statistique. Seuls ceux que
## les types choisis peuvent porter.
func _fill_affixes(rule: LootFilter.Rule) -> void:
	var box: VBoxContainer = loot_form.get_node("AffixScroll/Affixes")
	_clear(box)
	var possible := LootFilter.possible_affixes(rule.families)
	if possible.is_empty():
		var none := Label.new()
		none.text = Texts.t("Aucun affixe sur ces types")
		none.add_theme_font_size_override("font_size", 8)
		none.add_theme_color_override("font_color", Color(0.52, 0.5, 0.6))
		box.add_child(none)
		return
	var ids_by_name := {}
	for affix: ItemAffix in possible:
		var written := affix_name(affix)
		ids_by_name[written] = ids_by_name.get(written, []) + [affix.id]
	# Les cochées en tête, à l'ouverture seulement : ce que vise la règle se lit sans
	# faire défiler, et une case cochée ensuite ne saute pas sous le curseur.
	var sorted: Array = ids_by_name.keys()
	sorted.sort_custom(func(a: String, b: String) -> bool:
		var a_on := rule.affixes.has(ids_by_name[a][0])
		if a_on != rule.affixes.has(ids_by_name[b][0]):
			return a_on
		return a.naturalnocasecmp_to(b) < 0
	)
	for written: String in sorted:
		var ids: Array = ids_by_name[written]
		var check := CheckBox.new()
		check.text = written
		check.add_theme_font_size_override("font_size", 8)
		check.button_pressed = rule.affixes.has(ids[0])
		check.toggled.connect(func(on: bool) -> void:
			for id in ids:
				var at := rule.affixes.find(id)
				if on and at < 0:
					rule.affixes.append(id)
				elif not on and at >= 0:
					rule.affixes.remove_at(at)
			_rule_edited()
		)
		box.add_child(check)


## Le palier le plus profond d'un affixe : la borne du bouton des paliers.
static func _deepest_tier() -> int:
	var deepest := 1
	for affix: ItemAffix in ItemAffixPool.ALL:
		deepest = maxi(deepest, affix.tiers.size())
	return deepest


## « armure » et « armure accrue » : le nom de la statistique ne suffit pas, un plat
## et un pourcentage la visent tous deux.
static func affix_name(affix: ItemAffix) -> String:
	if affix.percent:
		return Glossary.plain(StatMod.term_label(affix.stat, "increased", affix.scope))
	return StatMod.name(affix.stat, affix.scope)
