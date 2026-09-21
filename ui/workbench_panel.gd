class_name WorkbenchPanel
extends Control

## L'établi (B) : fabriquer un objet précis et le poser au sol, ou lâcher des boules
## d'expérience. **Outil de réglage à retirer avant publication** : le nœud
## `UI/Workbench`, la touche B et deux signaux. Il ne fabrique que ce que le jeu pourrait
## produire, et ne tire rien au hasard (haut des fourchettes, invariant 3).

## Posé par la zone, comme ce qu'on jette du sac.
signal drop_requested(item: Item)
## Posées par la zone, qui connaît le niveau.
signal requested_orbs(count: int)

const PAD := 6.0
const LINE := 10.0
const FONT_SIZE := 8
const TITLE_SIZE := 9
const HEADER := 16.0
## Largeur de la colonne des bases. Assez pour le plus long nom du catalogue.
const COL := 150.0

## Le plafond vient de la table des poids. Une fonction : une `const` bâtie sur
## `size()` reste introuvable depuis un autre script.
static func max_affixes() -> int:
	return ItemAffixPool.COUNT_WEIGHTS.size() - 1

const SELECTED := Color(0.52, 0.88, 0.48)
const REFUSAL := Color(0.92, 0.46, 0.42)
const HOVER := Color(1.0, 1.0, 1.0, 0.10)
const BUTTON := Color(0.18, 0.17, 0.23)

var _font: Font
var _base := 0
var _page := 0
## La page des affixes : un bijou en accepte plus de vingt.
var _page_affixes := 0
var _level := 1
## Affixe → palier, **0 étant le meilleur**. Vidé quand la base change.
var _selected_ones := {}
## Les zones cliquables, par `_arrange()` : le dessin et le clic lisent la même.
var _lines: Array[Dictionary] = []
var _hover := ""


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font


## Sans garde : effacer une prise absente ne coûte rien, et la condition finissait
## par mentir (voir `Game.grab_ui_input`).
func _exit_tree() -> void:
	Game.grab_ui_input(self, false)


func toggle() -> void:
	visible = not visible
	Game.grab_ui_input(self, visible)
	if visible:
		_hover = ""
	queue_redraw()


# --------------------------------------------------------------------------
# L'état
# --------------------------------------------------------------------------


func bases() -> Array:
	return ItemCatalog.ALL


func current_base() -> ItemBase:
	var all_of := bases()
	return all_of[_base] if _base >= 0 and _base < all_of.size() else null


## Les affixes que cette base accepte, quel que soit son niveau. La question du
## niveau vient après, palier par palier.
func compatibles() -> Array:
	return ItemAffixPool.compatibles(current_base())


## Reconstruit à chaque appel : un exemplaire retenu se désynchroniserait.
func craft() -> Item:
	var base := current_base()
	if base == null:
		return null
	var explicits: Array[RolledAffix] = []
	for id in _selected_ones:
		var affix := ItemAffixPool.by_id(id)
		if affix == null:
			continue
		var index: int = _selected_ones[id]
		if index < 0 or index >= affix.tiers.size():
			continue
		explicits.append(RolledAffix.new(id, index + 1, affix.at_top(index)))
	var item := Item.new(base, explicits, _level)
	item.implicit_roll = 1.0
	return item


func choose_base(index: int) -> void:
	var all_of := bases()
	if index < 0 or index >= all_of.size() or index == _base:
		return
	_base = index
	_page_affixes = 0
	# Les affixes suivaient l'ancienne base.
	_selected_ones.clear()


## **Élague** ce qui n'est plus atteignable, sinon l'objet serait impossible.
func change_level(delta: int) -> void:
	_level = clampi(_level + delta, 1, 100)
	for id in _selected_ones.keys():
		var affix := ItemAffixPool.by_id(id)
		if affix == null or not affix.unlocked_tiers(_level).has(_selected_ones[id]):
			_selected_ones.erase(id)


## Absent, chaque palier ouvert du meilleur au pire, puis absent.
func toggle_affix(id: String) -> void:
	var affix := ItemAffixPool.by_id(id)
	if affix == null:
		return
	var unlocked_tiers := affix.unlocked_tiers(_level)
	if unlocked_tiers.is_empty():
		return
	if not _selected_ones.has(id):
		if _selected_ones.size() >= max_affixes():
			return
		_selected_ones[id] = unlocked_tiers[0]
		return
	var next_item := unlocked_tiers.find(_selected_ones[id]) + 1
	if next_item >= unlocked_tiers.size():
		_selected_ones.erase(id)
	else:
		_selected_ones[id] = unlocked_tiers[next_item]


func reset_all() -> void:
	_base = 0
	_page = 0
	_page_affixes = 0
	_level = 1
	_selected_ones.clear()


func pages() -> int:
	return maxi(ceili(float(bases().size()) / float(_per_page())), 1)


func _per_page() -> int:
	return maxi(int((size.y - HEADER - LINE * 2.0 - PAD * 2.0) / LINE), 1)


func affix_pages() -> int:
	return maxi(ceili(float(compatibles().size()) / float(_affixes_per_page())), 1)


## Autant de lignes qu'il en tient entre le haut de la liste et les deux boutons
## du bas.
func _affixes_per_page() -> int:
	return maxi(int((_affixes_bottom() - _affixes_top()) / LINE), 1)


## Le haut de la liste des affixes, sous le niveau d'objet et le compte.
func _affixes_top() -> float:
	return HEADER + LINE * 5.0 + 6.0


## Le bas de la liste : le haut des deux boutons, moins une ligne d'air.
func _affixes_bottom() -> float:
	return size.y - LINE * 2.0 - PAD


# --------------------------------------------------------------------------
# La mise en page, construite une fois et lue deux fois
# --------------------------------------------------------------------------


func _add(rect: Rect2, action: String, text_value: String, tint: Color) -> void:
	_lines.append({"rect": rect, "action": action, "text_value": text_value, "tint": tint})


## Lignes cliquables **et** texte, pour le dessin comme pour le clic.
func _arrange() -> void:
	_lines.clear()
	var right_side := PAD + COL + PAD
	var right_width := size.x - right_side - PAD

	# --- la colonne des bases ---
	var all_of := bases()
	var per_page := _per_page()
	_page = clampi(_page, 0, pages() - 1)
	_add(Rect2(PAD, HEADER, 14.0, LINE), "page:-1", "<", UiPalette.TEXT)
	_add(Rect2(PAD + COL - 14.0, HEADER, 14.0, LINE), "page:1", ">", UiPalette.TEXT)

	var y := HEADER + LINE + 2.0
	for i in range(_page * per_page, mini((_page + 1) * per_page, all_of.size())):
		var base: ItemBase = all_of[i]
		_add(
			Rect2(PAD, y, COL, LINE), "base:%d" % i, base.display_name,
			SELECTED if i == _base else UiPalette.TEXT
		)
		y += LINE

	# --- le niveau d'objet ---
	var yd := HEADER + LINE * 3.0 + 4.0
	var x := right_side + right_width - 4.0 * 18.0
	for step in [-10, -1, 1, 10]:
		_add(
			Rect2(x, yd, 16.0, LINE), "level:%d" % step, "%+d" % step, UiPalette.TEXT
		)
		x += 18.0

	# --- les affixes, par page ---
	var yp := yd + LINE
	x = right_side + right_width - 2.0 * 18.0
	for step in [-1, 1]:
		_add(Rect2(x, yp, 16.0, LINE), "affixes:%d" % step, "<" if step < 0 else ">", UiPalette.TEXT)
		x += 18.0

	var everyone := compatibles()
	var affixes_per_page := _affixes_per_page()
	_page_affixes = clampi(_page_affixes, 0, affix_pages() - 1)
	var ya := _affixes_top()
	var start := _page_affixes * affixes_per_page
	for i in range(start, mini(start + affixes_per_page, everyone.size())):
		var affix: ItemAffix = everyone[i]
		var unlocked_tiers := affix.unlocked_tiers(_level)
		var taken := _selected_ones.has(affix.id)
		var tint := UiPalette.LABEL
		var state := "—"
		if unlocked_tiers.is_empty():
			state = "niv. %d" % affix.minimum_level()
		elif taken:
			var index: int = _selected_ones[affix.id]
			state = "T%d  %s" % [index + 1, affix.at_top(index).readable_value()]
			tint = SELECTED
		else:
			tint = UiPalette.TEXT
		# « (%) » distingue un affixe à plat de son pendant en pourcentage.
		_add(
			Rect2(right_side, ya, right_width, LINE), "affix:%s" % affix.id,
			"%s%s|%s" % [
				StatMod.name(affix.stat, affix.scope), " (%)" if affix.percent else "", state
			], tint
		)
		ya += LINE

	# --- les boules d'expérience, sous la colonne des bases ---
	var yb := size.y - LINE - PAD
	x = PAD + COL - 2.0 * 24.0
	for count in [1, 10]:
		_add(Rect2(x, yb, 22.0, LINE), "orbs:%d" % count, "×%d" % count, UiPalette.TEXT)
		x += 24.0

	# --- les deux boutons ---
	_add(Rect2(right_side, yb, 74.0, LINE), "drop", "Lâcher au sol", UiPalette.TEXT)
	_add(Rect2(right_side + 80.0, yb, 66.0, LINE), "reset", "Réinitialiser", UiPalette.TEXT)


func _action_under(point: Vector2) -> String:
	_arrange()
	for line in _lines:
		if (line["rect"] as Rect2).has_point(point):
			return String(line["action"])
	return ""


# --------------------------------------------------------------------------
# Les entrées
# --------------------------------------------------------------------------


func _input(event: InputEvent) -> void:
	if not visible:
		return
	var mouse := make_input_local(event) as InputEventMouse
	if mouse == null:
		return

	if mouse is InputEventMouseMotion:
		var seen := _action_under(mouse.position)
		if seen != _hover:
			_hover = seen
			queue_redraw()
		return

	var button := mouse as InputEventMouseButton
	if not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	# Hors de la fenêtre, le clic reste au panneau voisin.
	if not Rect2(Vector2.ZERO, size).has_point(button.position):
		return

	_apply(_action_under(button.position))
	queue_redraw()
	get_viewport().set_input_as_handled()


## Le seul endroit qui traduit un clic ; publique pour le test.
func _apply(action: String) -> void:
	if action.is_empty():
		return
	var cut := action.split(":")
	match cut[0]:
		"base": choose_base(int(cut[1]))
		"page": _page = clampi(_page + int(cut[1]), 0, pages() - 1)
		"affixes": _page_affixes = clampi(_page_affixes + int(cut[1]), 0, affix_pages() - 1)
		"level": change_level(int(cut[1]))
		"orbs": requested_orbs.emit(int(cut[1]))
		"affix": toggle_affix(cut[1])
		"drop":
			var item_data := craft()
			if item_data != null:
				drop_requested.emit(item_data)
		"reset": reset_all()


# --------------------------------------------------------------------------
# Le dessin
# --------------------------------------------------------------------------


func _draw() -> void:
	if _font == null:
		return
	_arrange()
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BACK)
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BORDER, false, 1.0)
	_text("ÉTABLI  —  outil de réglage", Vector2(PAD, 11.0), TITLE_SIZE, UiPalette.TITLE)

	var right_side := PAD + COL + PAD
	draw_line(
		Vector2(right_side - PAD * 0.5, HEADER), Vector2(right_side - PAD * 0.5, size.y - PAD),
		UiPalette.BORDER
	)
	_text(
		"bases  %d/%d" % [_page + 1, pages()], Vector2(PAD + 18.0, HEADER + LINE - 2.0),
		FONT_SIZE, UiPalette.LABEL
	)
	_paint_sheet(right_side)
	_text("boules d'exp", Vector2(PAD, size.y - PAD - 2.0), FONT_SIZE, UiPalette.LABEL)

	for line in _lines:
		var r: Rect2 = line["rect"]
		var action := String(line["action"])
		if action == _hover:
			draw_rect(r, HOVER)
		if action == "drop" or action == "reset" or action.begins_with("level:") \
				or action.begins_with("page:") or action.begins_with("affixes:") \
				or action.begins_with("orbs:"):
			draw_rect(r, BUTTON)
			draw_rect(r, UiPalette.BORDER, false, 1.0)
		# Intitulé à gauche, état calé à droite, séparés par « | ».
		var text_value := String(line["text_value"])
		var tint: Color = line["tint"]
		if text_value.contains("|"):
			var parts := text_value.split("|")
			_text(parts[0], r.position + Vector2(2.0, LINE - 2.0), FONT_SIZE, tint)
			var w := RichText.width(_font, parts[1], FONT_SIZE)
			_text(parts[1], r.position + Vector2(r.size.x - w - 2.0, LINE - 2.0), FONT_SIZE, tint)
		else:
			_text(text_value, r.position + Vector2(2.0, LINE - 2.0), FONT_SIZE, tint)


func _paint_sheet(right_side: float) -> void:
	var base := current_base()
	if base == null:
		return
	var item_data := craft()
	var y := HEADER + LINE - 2.0
	_text(base.display_name, Vector2(right_side, y), TITLE_SIZE, item_data.color())
	_text(
		"%s · %s · %d×%d · lignée %s p%d" % [
			base.family if not base.family.is_empty() else "—", base.kind,
			base.grid_size.x, base.grid_size.y, base.lineage, base.tier
		],
		Vector2(right_side, y + LINE), FONT_SIZE, UiPalette.LABEL
	)
	_text("niveau d'objet  %d" % _level, Vector2(right_side, y + LINE * 2.0 + 6.0), FONT_SIZE, UiPalette.TEXT)

	var full := _selected_ones.size() >= max_affixes()
	_text(
		"affixes  %d/%d      page %d/%d" % [
			_selected_ones.size(), max_affixes(), _page_affixes + 1, affix_pages()
		],
		Vector2(right_side, y + LINE * 4.0 + 4.0), FONT_SIZE, REFUSAL if full else UiPalette.LABEL
	)


func _text(text_value: String, at: Vector2, size_value: int, tint: Color) -> void:
	RichText.draw(self, _font, at, text_value, size_value, tint)
