class_name SkillBarPanel
extends Control

## Les cinq cases, en bas à droite, **permanentes**. La souris n'est prise que menu
## ouvert : sinon le clic qui choisit une compétence la lancerait aussi.

const PAD := 4.0
const SLOT := 26.0
const GAP := 4.0
const FONT_SIZE := 8
## Hauteur réservée sous les cases pour le libellé de touche.
const KEY_H := 10.0
## Une entrée du menu : l'icône à sa taille de grille, sans réduction fractionnaire.
const ENTRY_H := SkillIcon.SIDE + 2.0

const BACKGROUND := Color(0.10, 0.09, 0.13, 0.88)
const EMPTY := Color(0.16, 0.15, 0.20, 0.85)
## La case dont le menu est ouvert, et celle que la souris survole.
const SELECTED_FILL := Color(0.95, 0.82, 0.30)
## Le voile de recharge descend : à vingt-six pixels, un arc ne se lit pas.
const COOLDOWN := Color(0.02, 0.02, 0.04, 0.62)

var _player: Player
var _font: Font
## La case dont le menu, modal, est ouvert, ou -1.
var _menu := -1
var _hover := -1
var _hover_menu := -1
## L'état dessiné, pour ne repeindre que lorsqu'il change.
var _displayed_state := -1


func _ready() -> void:
	_font = ThemeDB.fallback_font
	# Au plus proche voisin : lissée, la trame du pixel art tournerait au gris.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _exit_tree() -> void:
	if _menu >= 0:
		Game.grab_ui_input(self, false)


## Noms et libellés dessinés à la main.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func bind(player: Player) -> void:
	_player = player
	queue_redraw()


## Le voile suit les recharges, et rien ne se repeint au repos.
func _process(_delta: float) -> void:
	if _player == null:
		return
	var state := 0
	for i in SkillBar.SLOT_COUNT:
		if _player.remaining_cooldown(i) > 0.0:
			state |= 1 << i
		var skill := _player.bar.skill_of(i)
		if skill != null and _player.mana < skill.mana_cost:
			state |= 1 << (i + SkillBar.SLOT_COUNT)
	# Une recharge qui descend repeint à chaque image ; sinon, seul un changement d'état.
	if state != _displayed_state or (state & ((1 << SkillBar.SLOT_COUNT) - 1)) != 0:
		_displayed_state = state
		queue_redraw()


func _input(event: InputEvent) -> void:
	if _player == null:
		return
	var mouse := make_input_local(event) as InputEventMouse
	if mouse == null:
		return

	if mouse is InputEventMouseMotion:
		_track(mouse.position)
		return

	var button := mouse as InputEventMouseButton
	if not button.pressed or button.button_index != MOUSE_BUTTON_LEFT:
		return
	if not _owns_click(button.position):
		return
	_track(button.position)

	if _menu >= 0:
		# Dans le menu, on choisit ; ailleurs, on referme.
		if _hover_menu >= 0:
			_assign(_hover_menu)
		_close()
	elif _hover >= 0:
		_open(_hover)
	else:
		return
	get_viewport().set_input_as_handled()


## Menu ouvert : **modal**, tout l'écran. Fermé : seuls les clics tombés sur la barre.
func _owns_click(point: Vector2) -> bool:
	return _menu >= 0 or Rect2(Vector2.ZERO, size).has_point(point)


func _open(index: int) -> void:
	_menu = index
	Game.grab_ui_input(self, true)
	queue_redraw()


func menu_open() -> bool:
	return _menu >= 0


## Pour Échap, que la zone traite : la barre ne lit pas le clavier.
func close_menu() -> void:
	if menu_open():
		_close()


func _close() -> void:
	_menu = -1
	_hover_menu = -1
	Game.grab_ui_input(self, false)
	queue_redraw()


## La première entrée vide la case. Une compétence posée ailleurs **se déplace**.
func _assign(entry: int) -> void:
	if _menu < 0:
		return
	if entry == 0:
		_player.bar.clear(_menu)
		return
	var choice := _player.available_skills()
	var index := entry - 1
	if index < 0 or index >= choice.size():
		return
	var id := choice[index].id
	for i in SkillBar.SLOT_COUNT:
		if _player.bar.id_of(i) == id:
			_player.bar.clear(i)
	_player.bar.put(_menu, id)


func _track(point: Vector2) -> void:
	var cell := -1
	for i in SkillBar.SLOT_COUNT:
		if _slot_rect(i).has_point(point):
			cell = i
			break

	var entry := -1
	if _menu >= 0:
		for i in _entries().size():
			if _menu_rect(i).has_point(point):
				entry = i
				break

	if cell == _hover and entry == _hover_menu:
		return
	_hover = cell
	_hover_menu = entry
	queue_redraw()


func _slot_rect(index: int) -> Rect2:
	return Rect2(PAD + float(index) * (SLOT + GAP), PAD, SLOT, SLOT)


## Les entrées du menu : « vider », qui n'a pas de compétence, puis ce qu'on peut
## poser.
func _entries() -> Array[Skill]:
	var out: Array[Skill] = [null]
	if _player != null:
		out.append_array(_player.available_skills())
	return out


## Le cadre du menu, **mesuré ici seulement**, qui monte depuis la barre.
func _menu_frame(entries: int) -> Rect2:
	var height := float(entries) * ENTRY_H + PAD * 2.0
	return Rect2(PAD, -height - PAD, size.x - PAD * 2.0, height)


func _menu_rect(entry: int) -> Rect2:
	var frame := _menu_frame(_entries().size())
	return Rect2(
		frame.position.x, frame.position.y + PAD + float(entry) * ENTRY_H,
		frame.size.x, ENTRY_H
	)


## La place de l'icône ; le clic la lit comme le dessin.
func _entry_icon(entry: int) -> Rect2:
	var r := _menu_rect(entry)
	var side := float(SkillIcon.SIDE)
	return Rect2(r.position + Vector2(2.0, (r.size.y - side) * 0.5), Vector2(side, side))


## Lu dans la **carte d'entrées**, jamais réécrit, et traduit dans la disposition du
## joueur : le jeu lie des positions (ZQSD comme WASD), et la barre doit dire la
## lettre qu'il lit.
static func key_label(index: int) -> String:
	for event in InputMap.action_get_events("skill_%d" % (index + 1)):
		var keyboard := event as InputEventKey
		if keyboard != null:
			if keyboard.keycode != 0:
				return OS.get_keycode_string(keyboard.keycode)
			# Le serveur muet des tests n'a pas de disposition : on garde le nom de la position
			# plutôt que de pousser une erreur moteur.
			var read_value := keyboard.physical_keycode
			if DisplayServer.get_name() != "headless":
				var translated := DisplayServer.keyboard_get_keycode_from_physical(read_value)
				if translated != 0:
					read_value = translated
			return OS.get_keycode_string(read_value)
		var click := event as InputEventMouseButton
		if click != null:
			return Texts.t("clic G") if click.button_index == MOUSE_BUTTON_LEFT else Texts.t("clic D")
	return ""


# --------------------------------------------------------------------------


func _draw() -> void:
	if _font == null or _player == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), BACKGROUND)

	for i in SkillBar.SLOT_COUNT:
		_draw_slot(i)
	if _menu >= 0:
		_draw_menu()


func _draw_slot(index: int) -> void:
	var r := _slot_rect(index)
	draw_rect(r, EMPTY)

	var skill := _player.bar.skill_of(index)
	if skill != null:
		_draw_mark(r, skill)
		if _player.mana < skill.mana_cost:
			draw_rect(r, COOLDOWN)

	# Le voile descend : la case se remplit en redevenant disponible.
	var rest := _player.remaining_cooldown(index)
	if rest > 0.0 and skill != null:
		var total := maxf(skill.interval(_player.stats), 0.001)
		var ratio := clampf(rest / total, 0.0, 1.0)
		draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y * ratio)), COOLDOWN)

	var tint := UiPalette.BORDER
	if index == _menu or index == _hover:
		tint = SELECTED_FILL
	draw_rect(r, tint, false, 1.0)

	var key := key_label(index)
	if not key.is_empty():
		var width := _font.get_string_size(
			key, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE
		).x
		draw_string(
			_font, Vector2(r.position.x + (SLOT - width) * 0.5, r.end.y + KEY_H - 2.0),
			key, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT
		)


## L'icône, à défaut un disque de la couleur de la nature, lisible à vingt-six pixels ;
## le menu montre la même marque.
func _draw_mark(r: Rect2, skill: Skill) -> void:
	var side := minf(r.size.x, r.size.y)
	var tex := SkillIcon.texture(skill)
	if tex == null:
		draw_circle(r.get_center(), side * 0.30, DamageType.COLORS[skill.nature])
		return
	var size_value := tex.get_size() * float(SkillIcon.factor(tex, side))
	draw_texture_rect(tex, Rect2(r.position + (r.size - size_value) * 0.5, size_value), false)


func _draw_menu() -> void:
	var entries := _entries()
	var frame := _menu_frame(entries.size())
	draw_rect(frame, UiPalette.TIP_BACK)
	draw_rect(frame, UiPalette.BORDER, false, 1.0)

	for i in entries.size():
		var r := _menu_rect(i)
		if i == _hover_menu:
			draw_rect(r, Color(1.0, 1.0, 1.0, 0.08))
		var base := r.position.y + (r.size.y + FONT_SIZE) * 0.5 - 1.0
		var skill := entries[i]
		if skill == null:
			draw_string(
				_font, Vector2(r.position.x + 3.0, base), Texts.t("— vider la case —"),
				HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT
			)
			continue
		var icon := _entry_icon(i)
		_draw_mark(icon, skill)
		draw_string(
			_font, Vector2(icon.end.x + 5.0, base), skill.displayed_name(),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.TEXT
		)
