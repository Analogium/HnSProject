class_name LootFilterPanel
extends Control

## La page du filtre de butin, en plein écran : les règles en cartes, la règle choisie
## en blocs de conditions, et un banc d'essai qui montre ce que chacune attrape.
## Tout est posé par le code : les listes suivent le filtre.

signal closed

const CARD := Color(0.12, 0.11, 0.15)
const CARD_ON := Color(0.18, 0.16, 0.23)
## Le sol du jeu, sous l'aperçu et le banc : un nom se juge sur ce qu'il recouvrira.
const GROUND := Color(0.21, 0.19, 0.21)
const HIDDEN := Color(0.55, 0.52, 0.60)
## Un nom masqué reste lisible au banc, en retrait : c'est lui qu'on vient chercher.
const HIDDEN_ALPHA := 0.35
const BENCH_SIZE := 12
## Au-delà, une carte coupe ses icônes de types : 200 px n'en tiennent pas plus.
const CARD_ICONS := 5
const ICON := 16
## La hauteur du corps d'une carte, deux lignes : fixée, parce que ce corps ne dit
## pas sa taille à la carte (voir `_card()`).
const CARD_BODY := 26
## Assez large pour la ligne des actions et de la palette **plus** la barre de
## défilement : plus étroite, la colonne s'élargit quand la barre paraît et le banc
## saute de côté.
const EDITOR_WIDTH := 252

## Les blocs de conditions, dans l'ordre de l'éditeur.
const BLOCKS := ["rarity", "family", "base", "affix"]
const BLOCK_TITLES := {"rarity": "Rareté", "family": "Type d'objet", "base": "Bases", "affix": "Affixes"}

## La règle ouverte, −1 sans règle.
var _rule_index := -1
## Les blocs ouverts sans rien de coché : une condition vide ne restreint rien, mais
## le bloc qu'on vient d'ajouter doit rester là pour qu'on le remplisse.
var _open_blocks := {}
var _bench: Array[Item] = []
var _bench_seed := 1

var _active: Button
var _cards: VBoxContainer
var _editor: VBoxContainer
var _bench_list: VBoxContainer
var _bench_hint: Label
var _preview: HFlowContainer
var _base_box: VBoxContainer
var _affix_chips: HFlowContainer
var _affix_results: VBoxContainer
var _search: LineEdit
var _count_row: HBoxContainer

## Ce qu'il vient de se passer, et la question qui attend sa réponse : ce qu'on fait
## si le joueur confirme.
var _status: Label
var _confirm: HBoxContainer
var _confirm_yes: Button
var _on_yes := Callable()
var _file_dialog: FileDialog
## Le menu des filtres, au nom de celui qui décide, et le champ qui le renomme.
var _filters: MenuButton
var _rename: LineEdit

## L'objet du banc sous la souris et le nom qui le porte : son infobulle se dessine
## sur `_tip_layer`, par-dessus les trois colonnes.
var _hovered: Item
var _hovered_plate: Control
var _tip_layer: Control
## La touche « détails » tenue, comme dans le sac : les paliers s'ajoutent.
var _detailed := false


func _ready() -> void:
	_build()
	visible = false


func open() -> void:
	visible = true
	_ask("", Callable())
	_refresh_filters()
	_roll_bench()
	_select(mini(maxi(_rule_index, 0), _rules().size() - 1))


# --------------------------------------------------------------------------
# La charpente
# --------------------------------------------------------------------------

func _build() -> void:
	set_anchors_preset(PRESET_FULL_RECT)
	var back := ColorRect.new()
	back.color = UiPalette.BACK_FULL
	back.set_anchors_preset(PRESET_FULL_RECT)
	add_child(back)
	var frame := MarginContainer.new()
	frame.set_anchors_preset(PRESET_FULL_RECT)
	for side in ["left", "right", "top", "bottom"]:
		frame.add_theme_constant_override("margin_" + side, 10)
	add_child(frame)
	var page := _vbox(6)
	frame.add_child(page)

	var bar := _hbox(8)
	bar.add_child(_label(Texts.t("FILTRE DE BUTIN"), 12, UiPalette.TITLE))
	# Largeur fixe et nom coupé : un long nom élargirait la barre hors de l'écran.
	_filters = MenuButton.new()
	_filters.flat = false
	_filters.custom_minimum_size.x = 150
	_filters.clip_text = true
	_filters.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_filters.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_filters.add_theme_font_size_override("font_size", 9)
	_filters.get_popup().add_theme_font_size_override("font_size", 8)
	_filters.get_popup().auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	_filters.get_popup().id_pressed.connect(_filter_chosen)
	bar.add_child(_filters)
	_rename = LineEdit.new()
	_rename.visible = false
	_rename.custom_minimum_size.x = 150
	_rename.max_length = 32
	_rename.add_theme_font_size_override("font_size", 9)
	_rename.text_submitted.connect(func(_text: String) -> void: _finish_rename())
	_rename.focus_exited.connect(_finish_rename)
	bar.add_child(_rename)
	var spacer := Control.new()
	spacer.size_flags_horizontal = SIZE_EXPAND_FILL
	bar.add_child(spacer)
	_active = _button("", 8)
	_active.pressed.connect(func() -> void:
		Settings.loot_filter_on = not Settings.loot_filter_on
		_refresh_active()
	)
	bar.add_child(_active)
	var back_button := _button(Texts.t("Retour"), 8)
	back_button.pressed.connect(func() -> void: closed.emit())
	bar.add_child(back_button)
	page.add_child(bar)

	var cols := _hbox(8)
	cols.size_flags_vertical = SIZE_EXPAND_FILL
	page.add_child(cols)

	var left := _vbox(3)
	left.custom_minimum_size.x = 200
	cols.add_child(left)
	var hint := _label(Texts.t("La plus haute règle qui vise un objet décide ; glisser une carte la déplace"), 7, UiPalette.HINT)
	hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	left.add_child(hint)
	var scroll := _scroll()
	scroll.size_flags_vertical = SIZE_EXPAND_FILL
	left.add_child(scroll)
	_cards = _vbox(3)
	_cards.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_cards)
	var add := _button("+  " + Texts.t("Ajouter une règle"), 8)
	add.pressed.connect(_add_rule)
	left.add_child(add)
	_build_sharing(left)

	var middle := _panel(CARD, UiPalette.BORDER, 5)
	middle.custom_minimum_size.x = EDITOR_WIDTH
	cols.add_child(middle)
	var editor_scroll := _scroll()
	middle.add_child(editor_scroll)
	_editor = _vbox(4)
	_editor.size_flags_horizontal = SIZE_EXPAND_FILL
	editor_scroll.add_child(_editor)

	var right := _panel(GROUND, UiPalette.BORDER, 5)
	right.size_flags_horizontal = SIZE_EXPAND_FILL
	cols.add_child(right)
	var bench := _vbox(3)
	right.add_child(bench)
	var head := _hbox(4)
	var title := _label(Texts.t("BANC D'ESSAI"), 7, UiPalette.HINT)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(title)
	var reroll := _button(Texts.t("Autres exemples"), 7)
	reroll.pressed.connect(func() -> void:
		_bench_seed += 1
		_roll_bench()
		_refresh_rules()
	)
	head.add_child(reroll)
	bench.add_child(head)
	_bench_hint = _label("", 7, UiPalette.HINT)
	# Replié plutôt qu'étalé : d'une ligne, il élargit la colonne et pousse la page
	# hors de l'écran.
	_bench_hint.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	bench.add_child(_bench_hint)
	_bench_list = _vbox(3)
	bench.add_child(_bench_list)

	# Posé en dernier : l'infobulle passe au-dessus de tout.
	_tip_layer = Control.new()
	_tip_layer.set_anchors_preset(PRESET_FULL_RECT)
	_tip_layer.mouse_filter = MOUSE_FILTER_IGNORE
	_tip_layer.draw.connect(_draw_tip)
	add_child(_tip_layer)


## L'état **réel** de la touche à chaque image, comme le sac : le relâchement se perd
## quand le focus part.
func _process(_delta: float) -> void:
	if not visible:
		return
	var held := Input.is_action_pressed("item_details")
	if held != _detailed:
		_detailed = held
		_tip_layer.queue_redraw()


## Deux menus sous la liste, la ligne d'état, et la confirmation d'un import.
func _build_sharing(left: VBoxContainer) -> void:
	_status = _label("", 7, UiPalette.HINT)
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.visible = false
	left.add_child(_status)
	_confirm = _hbox(3)
	_confirm.visible = false
	_confirm_yes = _button("", 8)
	_confirm_yes.pressed.connect(func() -> void:
		var action := _on_yes
		_ask("", Callable())
		action.call()
	)
	_confirm.add_child(_confirm_yes)
	var cancel := _button(Texts.t("Annuler"), 8)
	cancel.pressed.connect(func() -> void: _ask("", Callable()))
	_confirm.add_child(cancel)
	left.add_child(_confirm)

	var row := _hbox(3)
	row.add_child(_menu(Texts.t("Exporter"), [Texts.t("Copier le code"), Texts.t("Enregistrer un fichier…")],
		func(id: int) -> void:
			if id == 0:
				DisplayServer.clipboard_set(Settings.loot_filter.to_code())
				_say(Texts.tn("Code copié : {n} règle", "Code copié : {n} règles", _rules().size()).format({"n": _rules().size()}))
			else:
				_open_dialog(FileDialog.FILE_MODE_SAVE_FILE)
	))
	row.add_child(_menu(Texts.t("Importer"), [Texts.t("Coller un code"), Texts.t("Ouvrir un fichier…")],
		func(id: int) -> void:
			if id == 0:
				import_code(DisplayServer.clipboard_get(), Texts.t("Le presse-papiers ne contient pas de code de filtre"))
			else:
				_open_dialog(FileDialog.FILE_MODE_OPEN_FILE)
	))
	left.add_child(row)


func _menu(title: String, items: Array, chosen: Callable) -> MenuButton:
	var menu := MenuButton.new()
	menu.text = title
	menu.flat = false
	menu.size_flags_horizontal = SIZE_EXPAND_FILL
	menu.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	menu.add_theme_font_size_override("font_size", 8)
	var popup := menu.get_popup()
	popup.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	popup.add_theme_font_size_override("font_size", 8)
	for i in items.size():
		popup.add_item(items[i], i)
	popup.id_pressed.connect(chosen)
	return menu


## Lit un code ; `refusal` dit pourquoi rien ne s'est passé s'il n'en est pas un. Le
## filtre lu **s'ajoute** et prend la main : aucun filtre n'est perdu à l'import.
func import_code(text_value: String, refusal: String) -> void:
	var read := LootFilter.from_code(text_value)
	if read == null:
		_say(refusal)
		return
	Settings.add_loot_filter(read)
	_show_filter()
	_say(Texts.tn("« {nom} » importé : {n} règle", "« {nom} » importé : {n} règles", _rules().size()).format(
		{"nom": read.name, "n": _rules().size()}))


func save_file(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		_say(Texts.t("Écriture impossible : {chemin}").format({"chemin": path}))
		return
	file.store_string(Settings.loot_filter.to_code() + "\n")
	file.close()
	_say(Texts.t("Filtre enregistré : {fichier}").format({"fichier": path.get_file()}))


func load_file(path: String) -> void:
	import_code(FileAccess.get_file_as_string(path), Texts.t("Ce fichier n'est pas un filtre de butin"))


## La fenêtre de fichiers du système : là où le joueur range ses affaires, pas dans le
## dossier caché des sauvegardes.
func _open_dialog(mode: FileDialog.FileMode) -> void:
	if _file_dialog == null:
		_file_dialog = FileDialog.new()
		_file_dialog.use_native_dialog = true
		_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
		_file_dialog.filters = PackedStringArray(["*.txt ; " + Texts.t("Filtre de butin")])
		_file_dialog.current_dir = OS.get_system_dir(OS.SYSTEM_DIR_DOCUMENTS)
		_file_dialog.file_selected.connect(func(path: String) -> void:
			if _file_dialog.file_mode == FileDialog.FILE_MODE_SAVE_FILE:
				save_file(path)
			else:
				load_file(path)
		)
		add_child(_file_dialog)
	_file_dialog.file_mode = mode
	_file_dialog.current_file = Settings.loot_filter.name.validate_filename() + ".txt" if mode == FileDialog.FILE_MODE_SAVE_FILE else ""
	_file_dialog.popup_centered()


func _say(message: String) -> void:
	_status.text = message
	_status.visible = not message.is_empty()


## Pose une question sous la liste : `yes` part si le joueur confirme. Un message vide
## retire la question.
func _ask(message: String, yes: Callable, yes_label := "") -> void:
	_on_yes = yes
	_confirm_yes.text = yes_label
	_confirm.visible = yes.is_valid()
	_say(message)


# --------------------------------------------------------------------------
# Les filtres
# --------------------------------------------------------------------------

const NEW_FILTER := 1000
const DUPLICATE_FILTER := 1001
const RENAME_FILTER := 1002
const DELETE_FILTER := 1003


## Le menu au nom du filtre qui décide : les autres pour passer de l'un à l'autre,
## puis ce qu'on fait des filtres.
func _refresh_filters() -> void:
	_filters.text = Settings.loot_filter.name + "  ▾"
	var popup := _filters.get_popup()
	popup.clear()
	for i in Settings.loot_filters.size():
		popup.add_radio_check_item(Settings.loot_filters[i].name, i)
		popup.set_item_checked(i, i == Settings.loot_filter_index)
	popup.add_separator()
	popup.add_item(Texts.t("Nouveau filtre"), NEW_FILTER)
	popup.add_item(Texts.t("Dupliquer ce filtre"), DUPLICATE_FILTER)
	popup.add_item(Texts.t("Renommer…"), RENAME_FILTER)
	popup.add_item(Texts.t("Supprimer ce filtre"), DELETE_FILTER)
	popup.set_item_disabled(popup.get_item_index(DELETE_FILTER), Settings.loot_filters.size() <= 1)


func _filter_chosen(id: int) -> void:
	match id:
		NEW_FILTER:
			Settings.add_loot_filter(LootFilter.new())
			_show_filter()
			_start_rename()
		DUPLICATE_FILTER:
			var copy := Settings.loot_filter.duplicated()
			copy.name = Texts.t("{nom} (copie)").format({"nom": copy.name})
			Settings.add_loot_filter(copy)
			_show_filter()
		RENAME_FILTER:
			_start_rename()
		DELETE_FILTER:
			var doomed := Settings.loot_filter
			var delete := func() -> void:
				Settings.remove_loot_filter(Settings.loot_filters.find(doomed))
				_show_filter()
			var question := Texts.tn("Supprimer « {nom} » et sa règle ?", "Supprimer « {nom} » et ses {n} règles ?", doomed.rules.size())
			_ask(question.format({"nom": doomed.name, "n": doomed.rules.size()}), delete, Texts.t("Supprimer"))
		_:
			Settings.choose_loot_filter(id)
			_show_filter()


## Le filtre qui décide a changé : la page le montre depuis sa première règle.
func _show_filter() -> void:
	_refresh_filters()
	_select(0 if not _rules().is_empty() else -1)


func _start_rename() -> void:
	_rename.text = Settings.loot_filter.name
	_filters.visible = false
	_rename.visible = true
	_rename.grab_focus()
	_rename.select_all()


## Entrée ou clic ailleurs. Un nom vide garde l'ancien.
func _finish_rename() -> void:
	if not _rename.visible:
		return
	var written := _rename.text.strip_edges()
	if not written.is_empty() and written != Settings.loot_filter.name:
		Settings.loot_filter.name = written
		Settings.loot_filter_edited()
	_rename.visible = false
	_filters.visible = true
	_refresh_filters()


# --------------------------------------------------------------------------
# Les règles
# --------------------------------------------------------------------------

func _rules() -> Array[LootFilter.Rule]:
	return Settings.loot_filter.rules


func _rule() -> LootFilter.Rule:
	var rules := _rules()
	return rules[_rule_index] if _rule_index >= 0 and _rule_index < rules.size() else null


func _select(index: int) -> void:
	_rule_index = index
	_open_blocks = {}
	_refresh_rules()
	_fill_editor()


## Un clic sur une carte : la liste se restyle au lieu de se refaire, parce que la
## carte cliquée commence peut-être un glissement, qui mourrait avec elle.
func _pick(index: int) -> void:
	_rule_index = index
	_open_blocks = {}
	var rules := _rules()
	for i in _cards.get_child_count():
		var selected := i == index
		var card: PanelContainer = _cards.get_child(i)
		card.add_theme_stylebox_override("panel", _box(CARD_ON if selected else CARD, action_color(rules[i]) if selected else Color.TRANSPARENT, 0))
	_fill_bench()
	_fill_editor()


func _add_rule() -> void:
	_rules().append(LootFilter.Rule.new())
	Settings.loot_filter_edited()
	_select(_rules().size() - 1)


func _delete_rule() -> void:
	if _rule() == null:
		return
	_rules().remove_at(_rule_index)
	Settings.loot_filter_edited()
	_select(mini(_rule_index, _rules().size() - 1))


## Le dépôt d'une carte glissée : elle prend le rang de celle qu'elle recouvre.
func drop_rule(from: int, to: int) -> void:
	Settings.loot_filter.move_to(from, to)
	Settings.loot_filter_edited()
	_select(to)


## Ce qu'une retouche de la règle change ailleurs : cartes, banc, aperçu.
func _edited() -> void:
	Settings.loot_filter_edited()
	_refresh_rules()
	_fill_preview()


## Cartes et banc ensemble : le compte d'une carte se lit sur le banc.
func _refresh_rules() -> void:
	_refresh_active()
	_fill_cards()
	_fill_bench()


func _refresh_active() -> void:
	var on := Settings.loot_filter_on
	var written := Texts.t("Filtre actif  [{touche}]") if on else Texts.t("Filtre éteint  [{touche}]")
	_active.text = ("● " if on else "○ ") + written.format({"touche": Keybinds.key_label("loot_filter")})
	_active.add_theme_color_override("font_color", UiPalette.TO_SPEND if on else UiPalette.HINT)


func _fill_cards() -> void:
	_clear(_cards)
	var decided := _decided_counts()
	var rules := _rules()
	for i in rules.size():
		_cards.add_child(_card(i, rules[i], decided.get(rules[i], 0)))


func _decided_counts() -> Dictionary:
	var out := {}
	for item in _bench:
		var rule := Settings.loot_filter.rule_for(item)
		if rule != null:
			out[rule] = out.get(rule, 0) + 1
	return out


func _card(index: int, rule: LootFilter.Rule, decided: int) -> Control:
	var selected := index == _rule_index
	var card := _panel(CARD_ON if selected else CARD, action_color(rule) if selected else Color.TRANSPARENT, 0)
	card.mouse_filter = MOUSE_FILTER_STOP
	# La bulle dit en entier ce que la carte coupe.
	var whole := PackedStringArray([rule_summary(rule)])
	if rule.bases.size() > 2:
		whole.append(", ".join(_base_names(rule.bases)))
	if not rule.affixes.is_empty():
		whole.append(_affix_line(rule))
	card.tooltip_text = "\n".join(whole)
	card.modulate.a = 1.0 if rule.enabled else 0.45
	card.gui_input.connect(func(event: InputEvent) -> void:
		var click := event as InputEventMouseButton
		if click != null and click.pressed and click.button_index == MOUSE_BUTTON_LEFT and index != _rule_index:
			_pick(index)
	)
	card.set_drag_forwarding(
		func(_at: Vector2) -> Variant:
			card.set_drag_preview(_label(rule_summary(rule), 8, action_color(rule)))
			return {"loot_rule": index},
		func(_at: Vector2, data: Variant) -> bool:
			return data is Dictionary and data.has("loot_rule"),
		func(_at: Vector2, data: Variant) -> void:
			drop_rule(data["loot_rule"], index)
	)

	var row := _hbox(5)
	card.add_child(row)
	var strip := ColorRect.new()
	strip.color = action_color(rule)
	strip.custom_minimum_size = Vector2(3, 28)
	strip.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(strip)
	row.add_child(_label(str(index + 1), 8, UiPalette.HINT))

	# Un conteneur réclame la largeur de ce qu'il porte, et `clip_contents` n'y change
	# rien : neuf bases nommées élargissaient la colonne jusqu'à pousser le banc hors
	# de l'écran. Le corps vit donc dans un simple Control, qui ne réclame que sa
	# taille propre et coupe le reste ; les textes finissent en « … ».
	var holder := Control.new()
	holder.size_flags_horizontal = SIZE_EXPAND_FILL
	holder.custom_minimum_size.y = CARD_BODY
	holder.clip_contents = true
	holder.mouse_filter = MOUSE_FILTER_IGNORE
	row.add_child(holder)
	var body := _vbox(1)
	body.set_anchors_preset(PRESET_FULL_RECT)
	body.mouse_filter = MOUSE_FILTER_IGNORE
	holder.add_child(body)
	var top := _hbox(3)
	top.add_child(_label(Texts.t(LootFilter.ACTION_LABELS[rule.action]).to_upper(), 8, action_color(rule)))
	# Plusieurs raretés : l'initiale, que sa couleur suffit à lire ; en toutes lettres,
	# trois puces ne tiennent pas à côté de « RECOLORER ».
	for rarity in rule.rarities:
		var written := Texts.t(Item.RARITY_LABELS[rarity])
		top.add_child(_chip(written if rule.rarities.size() == 1 else written.left(1), Item.RARITY_COLORS[rarity]))
	if rule.rarities.is_empty() and rule.families.is_empty() and rule.bases.is_empty() and rule.affixes.is_empty():
		top.add_child(_label(Texts.t("tout"), 8, UiPalette.HINT))
	body.add_child(top)
	var bottom := _hbox(2)
	# Des bases, des noms : plusieurs d'un même type partagent leur icône.
	if not rule.bases.is_empty():
		bottom.add_child(_trimmed(", ".join(_base_names(rule.bases)), UiPalette.TEXT))
	else:
		for family in rule.families.slice(0, CARD_ICONS):
			bottom.add_child(_icon(family, 12))
		if rule.families.size() > CARD_ICONS:
			bottom.add_child(_label("+%d" % (rule.families.size() - CARD_ICONS), 7, UiPalette.HINT))
	if not rule.affixes.is_empty():
		bottom.add_child(_trimmed(" " + _affix_line(rule), UiPalette.HINT))
	if bottom.get_child_count() > 0:
		body.add_child(bottom)

	var count := _chip(str(decided), UiPalette.HINT)
	count.tooltip_text = Texts.t("Objets du banc que cette règle décide")
	count.mouse_filter = MOUSE_FILTER_PASS
	row.add_child(count)
	var toggle := _button("✓" if rule.enabled else "  ", 8)
	toggle.tooltip_text = Texts.t("Allumer ou éteindre la règle")
	toggle.add_theme_color_override("font_color", UiPalette.TO_SPEND)
	toggle.size_flags_vertical = SIZE_SHRINK_CENTER
	toggle.pressed.connect(func() -> void:
		rule.enabled = not rule.enabled
		_edited()
	)
	row.add_child(toggle)
	row.add_child(_label("⠿", 10, UiPalette.HINT))
	for child in row.get_children():
		if child is Label or child is PanelContainer:
			(child as Control).mouse_filter = MOUSE_FILTER_PASS
	return card


func _affix_line(rule: LootFilter.Rule) -> String:
	var line := "%s  (%d/%d)" % [", ".join(_affix_names(rule.affixes)), rule.min_count, rule.affixes.size()]
	return line if rule.best_tier == 0 else line + "  T%d+" % rule.best_tier


# --------------------------------------------------------------------------
# L'éditeur
# --------------------------------------------------------------------------

## Refait en entier au choix d'une règle, à un changement d'action et à l'ajout ou au
## retrait d'un bloc ; une case cochée ne refait que ce qui en dépend, sans quoi la
## recherche perdrait sa frappe et la liste son défilement.
func _fill_editor() -> void:
	_clear(_editor)
	_affix_chips = null
	_base_box = null
	var rule := _rule()
	if rule == null:
		_editor.add_child(_label(Texts.t("Choisir une règle, ou en ajouter une"), 8, UiPalette.HINT))
		return

	var head := _hbox(4)
	var title := _label(Texts.t("RÈGLE {n}").format({"n": _rule_index + 1}), 7, UiPalette.HINT)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(title)
	var delete := _button(Texts.t("Supprimer"), 7)
	delete.add_theme_color_override("font_color", Color(0.95, 0.45, 0.45))
	delete.pressed.connect(_delete_rule)
	head.add_child(delete)
	_editor.add_child(head)

	var preview := _panel(GROUND, UiPalette.BORDER, 4)
	# Replié à la ligne : deux longs noms côte à côte élargiraient la colonne.
	_preview = HFlowContainer.new()
	_preview.add_theme_constant_override("h_separation", 4)
	preview.add_child(_preview)
	_editor.add_child(preview)
	_fill_preview()

	_editor.add_child(_action_row(rule))
	for key: String in BLOCKS:
		if _block_open(rule, key):
			_editor.add_child(_block(rule, key))
	var missing := BLOCKS.filter(func(key: String) -> bool: return not _block_open(rule, key))
	if not missing.is_empty():
		var more := _hbox(3)
		more.add_child(_label("+ " + Texts.t("Condition :"), 7, UiPalette.HINT))
		for key: String in missing:
			var add := _button(Texts.t(BLOCK_TITLES[key]), 7)
			add.pressed.connect(func() -> void:
				_open_blocks[key] = true
				_fill_editor()
			)
			more.add_child(add)
		_editor.add_child(more)


func _block_open(rule: LootFilter.Rule, key: String) -> bool:
	return _open_blocks.has(key) or not _condition(rule, key).is_empty()


func _condition(rule: LootFilter.Rule, key: String) -> Array:
	match key:
		"rarity":
			return rule.rarities
		"family":
			return rule.families
		"base":
			return rule.bases
	return rule.affixes


## Ce que la règle ferait aux objets du banc qu'elle vise, tels qu'au sol ; sans
## objet du banc, un nom de son premier type, pour juger quand même la couleur.
func _fill_preview() -> void:
	_clear(_preview)
	var rule := _rule()
	_preview.add_child(_label(Texts.t("Au sol :"), 7, UiPalette.HINT))
	var shown := 0
	for item in _bench:
		if shown < 2 and Settings.loot_filter.rule_for(item) == rule:
			_preview.add_child(_nameplate(item.display_name(), LootFilter.color_for(item, rule), LootFilter.hides(rule)))
			shown += 1
	if shown > 0:
		return
	var example: ItemBase = ItemCatalog.by_id(rule.bases[0]) if not rule.bases.is_empty() \
		else base_of(rule.families[0] if not rule.families.is_empty() else "ring")
	var rarity: int = rule.rarities[0] if not rule.rarities.is_empty() else Item.Rarity.COMMON
	var color: Color = rule.color if rule.action == LootFilter.Action.RECOLOR else Item.RARITY_COLORS[rarity]
	_preview.add_child(_nameplate(Texts.t(example.display_name), color, LootFilter.hides(rule)))
	_preview.add_child(_label(Texts.t("(exemple)"), 7, UiPalette.HINT))


func _action_row(rule: LootFilter.Rule) -> Control:
	var row := _hbox(2)
	var group := ButtonGroup.new()
	for action in LootFilter.Action.size():
		var segment := _button(Texts.t(LootFilter.ACTION_LABELS[action]), 8)
		segment.toggle_mode = true
		segment.button_group = group
		segment.button_pressed = action == rule.action
		segment.pressed.connect(func() -> void:
			rule.action = action as LootFilter.Action
			_edited()
			_fill_editor()
		)
		row.add_child(segment)
	if rule.action != LootFilter.Action.RECOLOR:
		return row
	row.add_child(_label(" ", 8, UiPalette.HINT))
	for color: Color in LootFilter.COLORS:
		var swatch := Button.new()
		swatch.custom_minimum_size = Vector2(10, 10)
		swatch.size_flags_vertical = SIZE_SHRINK_CENTER
		var chosen := color == rule.color
		for state in ["normal", "hover", "pressed", "focus"]:
			swatch.add_theme_stylebox_override(state, _box(color, Color.WHITE if chosen else Color.TRANSPARENT, 0))
		swatch.pressed.connect(func() -> void:
			rule.color = color
			_edited()
			_fill_editor()
		)
		row.add_child(swatch)
	return row


## Un bloc : son titre, sa croix qui retire la condition, et ses cases.
func _block(rule: LootFilter.Rule, key: String) -> Control:
	var block := _panel(Color(0, 0, 0, 0.25), UiPalette.BORDER, 4)
	var body := _vbox(3)
	block.add_child(body)
	var head := _hbox(4)
	var title := _label(Texts.t(BLOCK_TITLES[key]).to_upper(), 7, UiPalette.HINT)
	title.size_flags_horizontal = SIZE_EXPAND_FILL
	head.add_child(title)
	var close := _button("×", 8)
	close.tooltip_text = Texts.t("Retirer la condition")
	close.pressed.connect(func() -> void:
		_condition(rule, key).clear()
		_open_blocks.erase(key)
		_prune(rule)
		_edited()
		_fill_editor()
	)
	head.add_child(close)
	body.add_child(head)
	match key:
		"rarity":
			body.add_child(_rarity_chips(rule))
		"family":
			body.add_child(_family_icons(rule))
		"base":
			_base_box = _vbox(2)
			body.add_child(_base_box)
			_fill_base_chips(rule)
		"affix":
			_affix_block(rule, body)
	return block


func _rarity_chips(rule: LootFilter.Rule) -> Control:
	var row := _hbox(3)
	for rarity in Item.RARITY_LABELS.size():
		var color: Color = Item.RARITY_COLORS[rarity]
		var chip := _button(Texts.t(Item.RARITY_LABELS[rarity]), 8)
		chip.toggle_mode = true
		chip.button_pressed = rule.rarities.has(rarity)
		chip.add_theme_color_override("font_color", Color(color, 0.5))
		chip.add_theme_color_override("font_pressed_color", color)
		chip.add_theme_color_override("font_hover_pressed_color", color)
		chip.add_theme_stylebox_override("pressed", _box(Color(color, 0.22), color, 2))
		chip.add_theme_stylebox_override("hover_pressed", _box(Color(color, 0.30), color, 2))
		chip.toggled.connect(func(on: bool) -> void:
			_toggle(rule.rarities, rarity, on)
			_edited()
		)
		row.add_child(chip)
	return row


func _family_icons(rule: LootFilter.Rule) -> Control:
	var grid := GridContainer.new()
	grid.columns = LootFilter.FAMILIES.size()
	grid.add_theme_constant_override("h_separation", 1)
	for family: String in LootFilter.FAMILIES:
		var icon := Button.new()
		icon.icon = SpriteForge.ground_icon(base_of(family))
		icon.toggle_mode = true
		icon.button_pressed = rule.families.has(family)
		icon.tooltip_text = Texts.t(LootFilter.FAMILIES[family])
		icon.custom_minimum_size = Vector2(ICON + 3, ICON + 3)
		icon.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		icon.expand_icon = false
		icon.add_theme_color_override("icon_normal_color", Color(1, 1, 1, 0.25))
		icon.add_theme_color_override("icon_hover_color", Color(1, 1, 1, 0.6))
		for state in ["normal", "hover", "focus"]:
			icon.add_theme_stylebox_override(state, _box(Color.TRANSPARENT, Color.TRANSPARENT, 1))
		for state in ["pressed", "hover_pressed"]:
			icon.add_theme_stylebox_override(state, _box(Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.5), 1))
		icon.toggled.connect(func(on: bool) -> void:
			_toggle(rule.families, family, on)
			_prune(rule)
			if _base_box != null:
				_fill_base_chips(rule)
			_edited()
		)
		grid.add_child(icon)
	return grid


## Les bases des types cochés — toutes sans type —, en noms groupés par type et
## rangés par palier : plusieurs bases d'un type partagent leur icône.
func _fill_base_chips(rule: LootFilter.Rule) -> void:
	_clear(_base_box)
	var flow: HFlowContainer = null
	var family := ""
	# Les types où une base est prise en tête, au remplissage seulement : sans type
	# coché la liste est longue, et une case ne doit pas sauter sous le curseur.
	var bases := LootFilter.possible_bases(rule.families)
	var taken := {}
	for base in bases:
		if rule.bases.has(base.id):
			taken[base.family] = true
	var ordered := bases.filter(func(b: ItemBase) -> bool: return taken.has(b.family)) \
		+ bases.filter(func(b: ItemBase) -> bool: return not taken.has(b.family))
	for base: ItemBase in ordered:
		if base.family != family:
			family = base.family
			if rule.families.size() != 1:
				_base_box.add_child(_label(Texts.t(LootFilter.FAMILIES[family]), 7, UiPalette.HINT))
			flow = HFlowContainer.new()
			flow.add_theme_constant_override("h_separation", 2)
			flow.add_theme_constant_override("v_separation", 2)
			_base_box.add_child(flow)
		var chip := _button(Texts.t(base.display_name), 7)
		chip.toggle_mode = true
		chip.button_pressed = rule.bases.has(base.id)
		chip.tooltip_text = Texts.t("Tombe dès le niveau {n}").format({"n": base.required_level})
		chip.add_theme_color_override("font_color", UiPalette.HINT)
		chip.add_theme_color_override("font_pressed_color", UiPalette.TEXT)
		chip.add_theme_stylebox_override("pressed", _box(Color(1, 1, 1, 0.10), Color(1, 1, 1, 0.5), 2))
		chip.add_theme_stylebox_override("hover_pressed", _box(Color(1, 1, 1, 0.14), Color(1, 1, 1, 0.6), 2))
		var id := base.id
		chip.toggled.connect(func(on: bool) -> void:
			_toggle(rule.bases, id, on)
			_prune(rule)
			_edited()
		)
		flow.add_child(chip)


func _affix_block(rule: LootFilter.Rule, body: VBoxContainer) -> void:
	_affix_chips = HFlowContainer.new()
	_affix_chips.add_theme_constant_override("h_separation", 3)
	_affix_chips.add_theme_constant_override("v_separation", 2)
	body.add_child(_affix_chips)
	_search = LineEdit.new()
	_search.placeholder_text = Texts.t("Rechercher un affixe…")
	_search.add_theme_font_size_override("font_size", 8)
	_search.text_changed.connect(func(_text: String) -> void: _fill_affix_results(rule))
	body.add_child(_search)
	var scroll := _scroll()
	scroll.custom_minimum_size.y = 64
	body.add_child(scroll)
	_affix_results = _vbox(0)
	_affix_results.size_flags_horizontal = SIZE_EXPAND_FILL
	scroll.add_child(_affix_results)
	_count_row = _hbox(4)
	body.add_child(_count_row)
	_fill_affix_chips(rule)
	_fill_affix_results(rule)


## Les affixes choisis, en puces qu'un clic retire, et le compte qui en dépend.
func _fill_affix_chips(rule: LootFilter.Rule) -> void:
	_clear(_affix_chips)
	for written in _affix_names(rule.affixes):
		var chip := _button(written + "  ×", 7)
		chip.add_theme_stylebox_override("normal", _box(Color(1, 1, 1, 0.08), UiPalette.TEXT, 2))
		chip.pressed.connect(func() -> void:
			for id in _ids_named(written, rule):
				rule.affixes.erase(id)
			_affix_changed(rule)
		)
		_affix_chips.add_child(chip)
	_fill_count_row(rule)


## Ce que la recherche trouve parmi les affixes que les types choisis peuvent porter,
## sauf ceux déjà pris. Groupés par nom : « chance critique accrue » d'arme et de bijou
## sont deux affixes et une ligne.
func _fill_affix_results(rule: LootFilter.Rule) -> void:
	_clear(_affix_results)
	var wanted := _search.text.strip_edges().to_lower()
	var names := {}
	for affix: ItemAffix in LootFilter.possible_affixes(rule):
		var written := affix_name(affix)
		if not rule.affixes.has(affix.id) and (wanted.is_empty() or written.to_lower().contains(wanted)):
			names[written] = true
	var sorted: Array = names.keys()
	sorted.sort_custom(func(a: String, b: String) -> bool: return a.naturalnocasecmp_to(b) < 0)
	if sorted.is_empty():
		var none := Texts.t("Aucun affixe sur ces types") if wanted.is_empty() else Texts.t("Aucun affixe trouvé")
		_affix_results.add_child(_label(none, 7, UiPalette.HINT))
	for written: String in sorted:
		var line := _button("+ " + written, 7)
		line.clip_text = true
		line.flat = true
		line.alignment = HORIZONTAL_ALIGNMENT_LEFT
		line.pressed.connect(func() -> void:
			rule.affixes.append_array(_ids_named(written, rule))
			_affix_changed(rule)
		)
		_affix_results.add_child(line)


func _affix_changed(rule: LootFilter.Rule) -> void:
	rule.min_count = clampi(rule.min_count, 1, maxi(rule.affixes.size(), 1))
	_fill_affix_chips(rule)
	_fill_affix_results(rule)
	_edited()


func _fill_count_row(rule: LootFilter.Rule) -> void:
	_clear(_count_row)
	_count_row.visible = not rule.affixes.is_empty()
	var count := _button(Texts.t("Au moins {n} sur {total}").format({"n": rule.min_count, "total": rule.affixes.size()}), 7)
	count.pressed.connect(func() -> void:
		rule.min_count = wrapi(rule.min_count + 1, 1, maxi(rule.affixes.size(), 1) + 1)
		_fill_count_row(rule)
		_edited()
	)
	_count_row.add_child(count)
	var tier := _button(Texts.t("Tous paliers") if rule.best_tier == 0 else Texts.t("Palier T{t} ou mieux").format({"t": rule.best_tier}), 7)
	tier.pressed.connect(func() -> void:
		rule.best_tier = wrapi(rule.best_tier + 1, 0, _deepest_tier() + 1)
		_fill_count_row(rule)
		_edited()
	)
	_count_row.add_child(tier)


## Un type retiré emporte ses bases, et une base ou un type retiré les affixes que
## plus rien de coché ne porte : gardés, ils ne pourraient jamais tomber, et un
## affixe compterait dans « N sur M ». Puis les puces d'affixes, si leur bloc est là.
func _prune(rule: LootFilter.Rule) -> void:
	var bases := LootFilter.possible_bases(rule.families).map(func(b: ItemBase) -> String: return b.id)
	for i in range(rule.bases.size() - 1, -1, -1):
		if not bases.has(rule.bases[i]):
			rule.bases.remove_at(i)
	var affixes := LootFilter.possible_affixes(rule).map(func(a: ItemAffix) -> String: return a.id)
	for i in range(rule.affixes.size() - 1, -1, -1):
		if not affixes.has(rule.affixes[i]):
			rule.affixes.remove_at(i)
	rule.min_count = clampi(rule.min_count, 1, maxi(rule.affixes.size(), 1))
	if _affix_chips != null:
		_fill_affix_chips(rule)
		_fill_affix_results(rule)


# --------------------------------------------------------------------------
# Le banc d'essai
# --------------------------------------------------------------------------

func _roll_bench() -> void:
	_bench = bench_items(Game.zone_level, _bench_seed)
	_bench_hint.text = Texts.t("Niveau de zone {n} · survol : affixes, [{touche}] : paliers").format(
		{"n": Game.zone_level, "touche": Keybinds.key_label("item_details")})


## Des objets tirés comme le butin de ce niveau, rangés par type ; la même graine
## redonne le même banc.
static func bench_items(level: int, bench_seed: int) -> Array[Item]:
	var rng := RandomNumberGenerator.new()
	rng.seed = bench_seed
	var bases := ItemCatalog.available(level)
	var coins := ItemCatalog.ALL.filter(func(b: ItemBase) -> bool: return b.family == ItemBase.CURRENCY_FAMILY)
	var out: Array[Item] = []
	for i in BENCH_SIZE - 1:
		out.append(Item.rolled(rng, bases[rng.randi() % bases.size()], level))
	out.append(Item.new(coins[rng.randi() % coins.size()]))
	var order := LootFilter.FAMILIES.keys()
	out.sort_custom(func(a: Item, b: Item) -> bool: return order.find(a.base.family) < order.find(b.base.family))
	return out


func _fill_bench() -> void:
	_clear(_bench_list)
	hover(null, null)
	var selected := _rule()
	for item in _bench:
		var rule := Settings.loot_filter.rule_for(item)
		var line := _hbox(4)
		var plate := _nameplate(item.display_name(), LootFilter.color_for(item, rule), LootFilter.hides(rule))
		plate.size_flags_horizontal = SIZE_EXPAND_FILL
		# Coupé à la colonne seulement ici : un nom sans largeur imposée s'effondre.
		(plate.get_child(0) as Label).clip_text = true
		plate.mouse_entered.connect(hover.bind(item, plate))
		plate.mouse_exited.connect(func() -> void:
			if _hovered_plate == plate:
				hover(null, null)
		)
		line.add_child(plate)
		var tag := "—" if rule == null else "#%d" % (_rules().find(rule) + 1)
		line.add_child(_label(tag, 7, UiPalette.HINT if rule == null else action_color(rule)))
		# Ce que la règle ouverte attrape se désigne : c'est la question qu'on se pose.
		line.add_child(_label("◀" if rule != null and rule == selected else " ", 7, UiPalette.TEXT))
		_bench_list.add_child(line)


## Montre l'infobulle de `item`, posée contre `plate` ; null l'efface.
func hover(item: Item, plate: Control) -> void:
	_hovered = item
	_hovered_plate = plate
	_tip_layer.queue_redraw()


## À gauche du banc, qui est au bord droit de l'écran, alignée sur le nom et bornée
## en bas.
func _draw_tip() -> void:
	if _hovered == null or not is_instance_valid(_hovered_plate):
		return
	var font := ThemeDB.fallback_font
	var lines := ItemTooltip.lines(_hovered, _detailed)
	var size_of := ItemTooltip.size_of(font, lines)
	var bounds := Rect2(Vector2.ZERO, _tip_layer.size)
	var anchor := _tip_layer.get_global_transform().affine_inverse() * _hovered_plate.get_global_rect()
	var at := Vector2(anchor.position.x - size_of.x - 4.0, minf(anchor.position.y, bounds.end.y - size_of.y))
	ItemTooltip.draw(_tip_layer, font, _hovered, lines, at.round(), bounds)


# --------------------------------------------------------------------------
# Les briques
# --------------------------------------------------------------------------

## Un nom tel que le sol le montre : teint, ou en retrait si masqué.
func _nameplate(text_value: String, color: Color, hidden: bool) -> Control:
	var plate := _panel(GroundItem.NAME_BACK, color, 0)
	(plate.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_left = 2
	(plate.get_theme_stylebox("panel") as StyleBoxFlat).content_margin_right = 2
	plate.add_child(_label(text_value, 7, color))
	plate.modulate.a = HIDDEN_ALPHA if hidden else 1.0
	return plate


static func action_color(rule: LootFilter.Rule) -> Color:
	match rule.action:
		LootFilter.Action.HIDE:
			return HIDDEN
		LootFilter.Action.RECOLOR:
			return rule.color
	return UiPalette.TEXT


## « Masquer : Magique · Anneaux, Amulettes · 2 sur 3 affixes » : la bulle d'une carte
## et ce qu'on emporte en la glissant.
static func rule_summary(rule: LootFilter.Rule) -> String:
	var parts := PackedStringArray()
	if not rule.rarities.is_empty():
		parts.append(", ".join(rule.rarities.map(func(r: int) -> String: return Texts.t(Item.RARITY_LABELS[r]))))
	if rule.families.size() > 2:
		parts.append(Texts.tn("{n} type", "{n} types", rule.families.size()).format({"n": rule.families.size()}))
	elif not rule.families.is_empty():
		parts.append(", ".join(rule.families.map(func(f: String) -> String: return Texts.t(LootFilter.FAMILIES[f]))))
	if rule.bases.size() > 2:
		parts.append(Texts.tn("{n} base", "{n} bases", rule.bases.size()).format({"n": rule.bases.size()}))
	elif not rule.bases.is_empty():
		parts.append(", ".join(_base_names(rule.bases)))
	if not rule.affixes.is_empty():
		parts.append(Texts.t("{n} sur {total} affixes").format({"n": rule.min_count, "total": rule.affixes.size()}))
	if parts.is_empty():
		parts.append(Texts.t("tout"))
	return "%s : %s" % [Texts.t(LootFilter.ACTION_LABELS[rule.action]), " · ".join(parts)]


## « armure » et « armure accrue » : le nom de la statistique ne suffit pas, un plat
## et un pourcentage la visent tous deux.
static func affix_name(affix: ItemAffix) -> String:
	if affix.percent:
		return Glossary.plain(StatMod.term_label(affix.stat, "increased", affix.scope))
	return StatMod.name(affix.stat, affix.scope)


## Les noms, une fois chacun, des affixes cités.
static func _affix_names(ids: Array[String]) -> PackedStringArray:
	var seen := {}
	for id in ids:
		var affix := ItemAffixPool.by_id(id)
		if affix != null:
			seen[affix_name(affix)] = true
	return PackedStringArray(seen.keys())


static func _base_names(ids: Array[String]) -> PackedStringArray:
	var out := PackedStringArray()
	for id in ids:
		out.append(Texts.t(ItemCatalog.by_id(id).display_name))
	return out


## Les affixes de ce nom que la règle peut encore viser.
static func _ids_named(written: String, rule: LootFilter.Rule) -> Array[String]:
	var out: Array[String] = []
	for affix: ItemAffix in LootFilter.possible_affixes(rule):
		if affix_name(affix) == written:
			out.append(affix.id)
	return out


## Le palier le plus profond d'un affixe : la borne du bouton des paliers.
static func _deepest_tier() -> int:
	var deepest := 1
	for affix: ItemAffix in ItemAffixPool.ALL:
		deepest = maxi(deepest, affix.tiers.size())
	return deepest


static func base_of(family: String) -> ItemBase:
	for raw in ItemCatalog.ALL:
		if (raw as ItemBase).family == family:
			return raw
	return null


static func _toggle(list: Array, value: Variant, on: bool) -> void:
	if on and not list.has(value):
		list.append(value)
	elif not on:
		list.erase(value)


## Vide une liste que l'on remplit à nouveau. **Détachés puis libérés en différé** :
## la liste se refait souvent depuis le signal d'un de ses propres boutons, et Godot
## refuse de libérer un nœud qui émet.
static func _clear(box: Node) -> void:
	for old in box.get_children():
		box.remove_child(old)
		old.queue_free()


func _icon(family: String, size: int) -> Control:
	var t := TextureRect.new()
	t.texture = SpriteForge.ground_icon(base_of(family))
	t.custom_minimum_size = Vector2(size, size)
	t.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	t.mouse_filter = MOUSE_FILTER_IGNORE
	return t


func _box(bg: Color, border: Color, pad: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.set_content_margin_all(pad)
	s.border_color = border
	s.set_border_width_all(1 if border.a > 0.0 else 0)
	s.set_corner_radius_all(2)
	return s


func _panel(bg: Color, border: Color, pad: int) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _box(bg, border, pad))
	return p


func _chip(text_value: String, color: Color) -> PanelContainer:
	var chip := _panel(Color(0, 0, 0, 0.25), color, 1)
	var style := chip.get_theme_stylebox("panel") as StyleBoxFlat
	style.content_margin_left = 3
	style.content_margin_right = 3
	chip.add_child(_label(text_value, 7, color))
	chip.size_flags_vertical = SIZE_SHRINK_CENTER
	# Posée sur une carte, elle laisse passer le clic qui la choisit.
	chip.mouse_filter = MOUSE_FILTER_IGNORE
	return chip


## Une ligne de carte qui prend la place restante et finit en « … » au-delà.
func _trimmed(text_value: String, color: Color) -> Label:
	var label := _label(text_value, 7, color)
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.size_flags_horizontal = SIZE_EXPAND_FILL
	return label


func _label(text_value: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text_value
	label.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label


func _button(text_value: String, size: int) -> Button:
	var button := Button.new()
	button.text = text_value
	button.auto_translate_mode = AUTO_TRANSLATE_MODE_DISABLED
	button.focus_mode = FOCUS_NONE
	button.add_theme_font_size_override("font_size", size)
	return button


func _hbox(separation: int) -> HBoxContainer:
	var box := HBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = MOUSE_FILTER_PASS
	return box


func _vbox(separation: int) -> VBoxContainer:
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", separation)
	box.mouse_filter = MOUSE_FILTER_PASS
	return box


func _scroll() -> ScrollContainer:
	var scroll := ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	return scroll
