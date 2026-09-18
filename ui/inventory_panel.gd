class_name InventoryPanel
extends Control

## Le sac (I) : chaque objet occupe sa place réelle. Deux gestes, glisser et
## clic-clic ; un relâchement sans déplacement est un clic. Relâché hors du panneau,
## l'objet tombe ; le clic droit équipe, retire ou jette. Le sac vit sur le joueur.

## Un signal : c'est la scène qui sait où poser au sol.
signal drop_requested(item: Item)

const CELL := 20.0
const PAD := 1.0
const HEADER := 16.0
## Deux lignes d'aide.
const FOOTER := 22.0
## La fenêtre de personnage : chaque emplacement occupe le rectangle qu'un objet de sa
## famille prendrait dans le sac. Trois colonnes, les bagues dans les gouttières.
const DOLL := {
	"helmet": Rect2i(4, 0, 3, 2), "amulet": Rect2i(8, 0, 3, 2),
	"weapon": Rect2i(0, 2, 3, 3), "chest": Rect2i(4, 2, 3, 3), "offhand": Rect2i(8, 2, 3, 3),
	"gloves": Rect2i(0, 5, 3, 2), "belt": Rect2i(4, 5, 3, 2), "boots": Rect2i(8, 5, 3, 2),
	"ring_left": Rect2i(3, 5, 1, 2), "ring_right": Rect2i(7, 5, 1, 2),
}
const DOLL_COLS := 11
const DOLL_ROWS := 7

const DOLL_AREA := Rect2i(0, 0, 2, 2)
const DOLL_ANIM := "idle_down"

## Un emplacement vide montre l'objet qu'il attend, très sombre : lisible sans texte.
const GHOST := Color(1.0, 1.0, 1.0, 0.13)
## Marge d'une icône : sans elle, l'objet mange les lignes de la grille.
const MARGIN := 3

const SLOT := Color(0.14, 0.13, 0.17)
const SLOT_EDGE := Color(0.22, 0.20, 0.26)
## Le fond d'un objet rangé donne sa forme avant l'icône.
const ITEM_BACK := Color(0.22, 0.21, 0.28)
## Le cadre d'un objet rangé, dans sa rareté assombrie.
const ITEM_EDGE_DIM := 0.3
## Au-delà, un relâchement finit un glisser ; en deçà, c'est un clic tremblé.
const DRAG_MIN := 5.0
const CAN_PLACE := Color(0.35, 0.85, 0.45, 0.28)
const BLOCKED := Color(0.90, 0.30, 0.28, 0.28)
## L'infobulle : fond d'UiPalette, cadre de la rareté. Sa ligne d'implicite :
const TIP_IMPLICIT := Color(0.62, 0.60, 0.68)
## Le niveau de l'objet, plus effacé : une étiquette, pas un bonus.
const TIP_LEVEL := Color(0.46, 0.44, 0.52)
## La colonne des paliers sous Alt, plus sourde : une note de bas de page.
const TIP_TIER := Color(0.55, 0.53, 0.62)
## Gouttière entre un affixe et son palier.
const TIP_TIER_GAP := 10.0
const TIP_EXPLICIT := Color(0.55, 0.75, 1.0)
const TIP_PAD := 5.0
const TIP_LINE := 9.0
## Écart entre le sac et son infobulle.
const TIP_GAP := 5.0
const TIP_MIN_W := 74.0
const FONT_SIZE := 8
const TITLE_SIZE := 9

@onready var title: Label = $Title

## Gardée : pas de null à retester à chaque dessin.
var _font: Font

var _player: Player
var _inventory: Inventory

## L'objet tenu à la main, sorti du sac tant qu'on ne l'a pas reposé.
var _held: Item
## Sa case d'origine, pour le rendre là où on l'a pris si on referme le sac.
var _from := Vector2i.ZERO
## La case attrapée : sans elle, l'objet sauterait sous le curseur.
var _grab := Vector2i.ZERO
## Le même décalage en pixels : l'objet suit au pixel, la destination à la case.
var _grab_px := Vector2.ZERO
## Dernière position connue de la souris, dans le repère du panneau.
var _mouse := Vector2.ZERO
## Où le bouton a été pressé, pour distinguer le glisser du clic.
var _press := Vector2.ZERO
## Alt tenue : paliers et fourchettes. Relevée dans _process, voir là-bas.
var _alt := false
var _hover := Vector2i(-1, -1)
## L'emplacement survolé, ou -1, séparé de la case du sac.
var _hover_slot := -1

## Dessinée par _draw : un enfant se peindrait par-dessus l'objet traîné.
var _doll_frames: SpriteFrames
## La clé de ce qui est chargé : sans elle, chaque rafraîchissement relancerait
## l'animation.
var _doll_shown := 0
var _doll_key := ""


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font
	title.add_theme_color_override("font_color", UiPalette.TITLE)


## Sans garde : effacer une prise absente ne coûte rien, et la condition finissait
## par mentir (voir `Game.grab_ui_input`).
func _exit_tree() -> void:
	Game.grab_ui_input(self, false)


## Dessiné à la main : titre refait, panneau redessiné.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		_on_changed()


func bind(player: Player) -> void:
	_player = player
	_inventory = player.inventory
	_inventory.changed.connect(_on_changed)
	player.equipment_changed.connect(_on_changed)

	# Taille déduite de la grille ; le coin bas-droite reste celui des ancres.
	var s := _panel_size()
	offset_left = offset_right - s.x
	offset_top = offset_bottom - s.y
	title.offset_right = s.x - 4.0

	_on_changed()


func toggle() -> void:
	visible = not visible
	Game.grab_ui_input(self, visible)
	if visible:
		# Sinon la case survolée reste celle d'avant la fermeture.
		_track(get_local_mouse_position())
	else:
		var left := _return_held()
		if left != null:
			drop_requested.emit(left)
	_on_changed()


func _input(event: InputEvent) -> void:
	if not visible or _inventory == null:
		return

	# La position de l'événement : vraie au moment du clic, rejouable dans un test.
	var mouse := make_input_local(event) as InputEventMouse
	if mouse == null:
		return

	if mouse is InputEventMouseMotion:
		_track(mouse.position)
		return

	if not _owns_click(mouse.position):
		return

	var button := mouse as InputEventMouseButton
	if not button.pressed:
		if button.button_index == MOUSE_BUTTON_LEFT:
			_track(button.position)
			_release(button.position)
			get_viewport().set_input_as_handled()
		return

	# Recalé sur le clic : ouvert au clavier, le sac ne vise pas la case d'avant.
	_track(button.position)

	match button.button_index:
		MOUSE_BUTTON_LEFT:
			_press = button.position
			# Presser en tenant, c'est poser ; le glisser se résout au relâchement.
			if _held != null:
				_resolve(button.position, false)
			else:
				_take(button.position)
		MOUSE_BUTTON_RIGHT:
			_right_click()
		_:
			return

	get_viewport().set_input_as_handled()


## Sans déplacement depuis la pression, c'était un clic : l'objet reste en main.
func _release(point: Vector2) -> void:
	if _held == null or point.distance_to(_press) < DRAG_MIN:
		return
	_resolve(point, true)


## Ce que la souris survole, sac et emplacements ensemble.
func _track(point: Vector2) -> void:
	_mouse = point
	var cell := _cell_at(point)
	var slot := _slot_at(point)
	# Un objet en main suit au pixel : redessiner à chaque mouvement.
	if cell == _hover and slot == _hover_slot and _held == null:
		return
	_hover = cell
	_hover_slot = slot
	queue_redraw()


## Jeter ce qu'on tient, retirer ce qui est porté, ou équiper ce qu'on survole.
func _right_click() -> void:
	if _held != null:
		drop_requested.emit(_held)
		_held = null
		queue_redraw()
		return
	if _player == null:
		return
	if _hover_slot >= 0:
		_unequip(EquipmentSlots.ids()[_hover_slot])
	else:
		_equip(_hover)


## **Sorti du sac d'abord** : l'objet remplacé y trouve sa place ; ce qui déborde
## tombe.
func _equip(cell: Vector2i) -> void:
	var index := _inventory.index_at(cell)
	if index == Inventory.EMPTY:
		return
	var origin: Vector2i = _inventory.placed[index].cell
	var item := _inventory.take_at(cell)
	if not _wear(item):
		# Rien à quoi l'attacher : il retourne exactement d'où il vient.
		_inventory.place(item, origin)
	queue_redraw()


## Porte un objet et reloge le remplacé, au sac ou au sol : **le seul endroit**.
## `slot` vide au clic droit, imposé quand on a lâché sur un emplacement.
func _wear(item: Item, slot := "") -> bool:
	if _player == null:
		return false
	# Un manuel s'étudie : le clic droit l'envoie au râtelier.
	var old := _player.study(item) if Rack.accepts(item) else _player.equip(item, slot)
	if old == item:
		return false
	if old != null and not _inventory.add(old):
		drop_requested.emit(old)
	return true


func _unequip(slot: String) -> void:
	var item := _player.unequip(slot)
	if item != null and not _inventory.add(item):
		drop_requested.emit(item)
	queue_redraw()


## Un objet du sac ou d'un emplacement ; le vide ne fait rien.
func _take(point: Vector2) -> void:
	var slot := _slot_at(point)
	if slot >= 0:
		var worn: Item = _player.equipped(EquipmentSlots.ids()[slot]) if _player != null else null
		if worn == null:
			return
		_player.unequip(EquipmentSlots.ids()[slot])
		_held = worn
		# Hors grille exprès : `_return_held` cherchera une place.
		_from = Vector2i(-1, -1)
		_grab = Inventory.footprint(worn) / 2
		_grab_px = _span_size(Inventory.footprint(worn)) * 0.5
		queue_redraw()
		return

	var cell := _cell_at(point)
	var index := _inventory.index_at(cell)
	if index == Inventory.EMPTY:
		return
	_from = _inventory.placed[index].cell
	_grab = cell - _from
	_grab_px = point - _rect_of(_from, Vector2i.ONE).position
	_held = _inventory.take_at(cell)
	queue_redraw()


## Pose ce qu'on tient : emplacement, sac, ou sol hors du panneau. Un clic raté garde
## l'objet en main ; un relâchement raté le rend au sac.
func _resolve(point: Vector2, drag: bool) -> void:
	if _held == null:
		return

	var slot := _slot_at(point)
	if slot >= 0:
		if _equip_held(EquipmentSlots.ids()[slot]):
			queue_redraw()
			return
	elif not _panel_rect().has_point(point):
		# Hors du panneau : au sol.
		drop_requested.emit(_held)
		_held = null
		queue_redraw()
		return
	elif _inventory.place(_held, _cell_at(point) - _grab):
		_held = null
		queue_redraw()
		return

	if drag:
		var rest := _return_held()
		if rest != null:
			drop_requested.emit(rest)
	queue_redraw()


## Refusé s'il ne va pas là : le joueur a visé, on ne range pas d'office.
func _equip_held(slot: String) -> bool:
	if not EquipmentSlots.accepts(slot, _held) or not _wear(_held, slot):
		return false
	_held = null
	return true


## À sa place d'origine si libre ; rend ce qui ne rentre plus, jamais perdu.
func _return_held() -> Item:
	if _held == null:
		return null
	var item := _held
	_held = null
	if _inventory.place(item, _from) or _inventory.add(item):
		return null
	return item


## Image d'animation déduite de l'horloge, pas d'un compteur.
func _process(_delta: float) -> void:
	if not visible:
		return

	# L'état **réel** d'Alt à chaque image : le gestionnaire de fenêtres avale le
	# relâchement quand le focus part.
	var alt := Input.is_key_pressed(KEY_ALT)
	if alt != _alt:
		_alt = alt
		queue_redraw()

	if _doll_frames == null:
		return
	var i := _doll_frame_index()
	if i != _doll_shown:
		_doll_shown = i
		queue_redraw()


func _doll_frame_index() -> int:
	var n := _doll_frames.get_frame_count(DOLL_ANIM)
	if n <= 1:
		return 0
	var fps := _doll_frames.get_animation_speed(DOLL_ANIM)
	return int(Time.get_ticks_msec() * 0.001 * fps) % n


## Seulement quand silhouette ou arme changent : réassigner relance l'animation.
func _refresh_doll() -> void:
	if _player == null:
		return
	var variant_index := _player.sprite.current_variant()
	var weapon := _player.weapon_kind()
	var key := "%d:%s" % [variant_index, weapon]
	if key == _doll_key:
		return
	_doll_key = key
	_doll_frames = SpriteForge.frames("player", variant_index, weapon)


func _on_changed() -> void:
	if _inventory != null:
		title.text = Texts.t("SAC  {occupees} / {total} cases").format({
			"occupees": _inventory.used_cells(), "total": _inventory.cell_count()
		})
	# L'arme portée a pu changer.
	_refresh_doll()
	if visible:
		queue_redraw()


## **Un clic hors du sac ne lui appartient pas**, sinon les autres panneaux
## deviennent sourds ; sauf avec un objet en main, qu'on peut lâcher au-dehors.
func _owns_click(point: Vector2) -> bool:
	return _held != null or _panel_rect().has_point(point)


func _panel_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _panel_size())


## Le plus large des deux : la grille du sac, ou celle du personnage.
func _panel_size() -> Vector2:
	return Vector2(
		maxf(_inventory.cols * (CELL + PAD) + PAD, _equip_size().x + PAD * 2.0),
		_grid_top() + _inventory.rows * (CELL + PAD) + PAD + FOOTER
	)


## Un rectangle de cases, en pixels — la mesure de base de tout le panneau.
func _span_size(span: Vector2i) -> Vector2:
	return Vector2(span) * (CELL + PAD) - Vector2(PAD, PAD)


## Même pas que le sac : les deux grilles s'alignent.
func _doll_rect(zone: Rect2i) -> Rect2:
	return Rect2(
		Vector2(
			_equip_left() + float(zone.position.x) * (CELL + PAD),
			HEADER + PAD + float(zone.position.y) * (CELL + PAD)
		),
		_span_size(zone.size)
	)


## Chaque grille centrée ; position entière, sinon lignes floues.
func _equip_left() -> float:
	return _centered(_equip_size().x)


func _grid_left() -> float:
	return _centered(_inventory.cols * (CELL + PAD) + PAD)


func _centered(width: float) -> float:
	return maxf(floorf((_panel_size().x - width) * 0.5), PAD)


func _slot_rect(index: int) -> Rect2:
	return _doll_rect(DOLL[EquipmentSlots.ids()[index]])


## L'objet type d'un emplacement, pris dans le catalogue.
static func _ghost_kind(slot: String) -> String:
	var family := EquipmentSlots.family_of(slot)
	for base in ItemCatalog.ALL:
		if base.family == family:
			return base.kind
	return ""


## L'encombrement de la grille du personnage, en pixels.
func _equip_size() -> Vector2:
	return _span_size(Vector2i(DOLL_COLS, DOLL_ROWS))


## Où commence le sac : sous la zone d'équipement.
func _grid_top() -> float:
	return HEADER + _equip_size().y + PAD + 6.0


## Le coin haut-gauche d'un rectangle de cases du sac, en pixels du panneau.
func _rect_of(cell: Vector2i, span: Vector2i) -> Rect2:
	return Rect2(
		Vector2(_grid_left() + cell.x * (CELL + PAD), _grid_top() + PAD + cell.y * (CELL + PAD)),
		_span_size(span)
	)


## Peut sortir de la grille : poser à cheval sur le bord doit échouer.
func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i(
		floori((point.x - _grid_left()) / (CELL + PAD)),
		floori((point.y - _grid_top() - PAD) / (CELL + PAD))
	)


func _slot_at(point: Vector2) -> int:
	for i in EquipmentSlots.count():
		if _slot_rect(i).has_point(point):
			return i
	return -1


func _draw() -> void:
	if _inventory == null:
		return

	var s := _panel_size()
	draw_rect(Rect2(Vector2.ZERO, s), UiPalette.BACK)
	draw_rect(Rect2(Vector2.ZERO, s), UiPalette.BORDER, false, 1.0)

	for y in _inventory.rows:
		for x in _inventory.cols:
			_draw_cell(_rect_of(Vector2i(x, y), Vector2i.ONE))

	_draw_doll()
	_draw_equipment()

	var hovered := _inventory.index_at(_hover) if _held == null else Inventory.EMPTY
	for p in _inventory.placed:
		_draw_item(p.data, _rect_of(p.cell, p.rect().size), true)
	if hovered != Inventory.EMPTY:
		var targeted: Inventory.Placed = _inventory.placed[hovered]
		var r := _rect_of(targeted.cell, targeted.rect().size)
		# Survolé, le cadre prend la rareté pleine.
		draw_rect(r, targeted.data.color(), false, 1.0)
		_draw_tooltip(targeted.data, r.position.y)

	if _held != null:
		var span := Inventory.footprint(_held)
		var at := _hover - _grab
		# La destination calée sur la grille, verte ou rouge, et l'objet qui suit le curseur
		# au pixel.
		if _hover_slot < 0 and _panel_rect().has_point(_mouse):
			draw_rect(_rect_of(at, span), CAN_PLACE if _inventory.fits(_held, at) else BLOCKED)
		_draw_item(_held, Rect2(_mouse - _grab_px, _span_size(span)), false)

	if _font != null:
		draw_string(_font, Vector2(4.0, s.y - 13.0),
			Texts.t("[clic] prendre et poser     [clic droit] équiper / retirer"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT)
		draw_string(_font, Vector2(4.0, s.y - 3.0),
			Texts.t("lâché hors du sac : jeté au sol"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, UiPalette.HINT)


## Le rectangle du portrait, dans le coin que les emplacements laissent libre.
func _doll_area_rect() -> Rect2:
	return _doll_rect(DOLL_AREA)


## La silhouette et l'arme réellement tenue, en grand.
func _draw_doll() -> void:
	var zone := _doll_area_rect()
	_draw_cell(zone)
	if _doll_frames == null or not _doll_frames.has_animation(DOLL_ANIM):
		return
	var tex := _doll_frames.get_frame_texture(DOLL_ANIM, _doll_shown)
	if tex == null:
		return
	# Taille native : agrandi, le sprite déborderait.
	_draw_centered(tex, zone)


## Dans le même panneau que le sac : équiper est un geste entre les deux.
func _draw_equipment() -> void:
	for i in EquipmentSlots.count():
		var slot: String = EquipmentSlots.ids()[i]
		var r := _slot_rect(i)
		var item: Item = _player.equipped(slot) if _player != null else null

		if item != null:
			# Fond de la rareté très assombri, comme au sol.
			draw_rect(r, item.color().darkened(0.80))
			draw_rect(r, item.color().darkened(0.35), false, 1.0)
			_draw_item(item, r, false, true)
		else:
			_draw_cell(r)
			_draw_ghost(slot, r)

		if _hover_slot != i:
			continue
		if _held != null:
			# Après l'objet porté, sinon son fond opaque effaçait la réponse.
			draw_rect(r, CAN_PLACE if EquipmentSlots.accepts(slot, _held) else BLOCKED)
		elif item != null:
			draw_rect(r, item.color(), false, 1.0)
			_draw_tooltip(item, r.position.y)


## Remplace le nom de l'emplacement, qui se tronquait.
func _draw_ghost(slot: String, r: Rect2) -> void:
	var kind := _ghost_kind(slot)
	if kind.is_empty():
		return
	_draw_centered(SpriteForge.ghost_icon(kind, Vector2i(_free_cell(r))), r, GHOST)


## Le creux d'une case vide et son liseré, toujours ensemble.
func _draw_cell(r: Rect2) -> void:
	draw_rect(r, SLOT)
	draw_rect(r, SLOT_EDGE, false, 1.0)


## La place utile d'un rectangle, marge déduite.
func _free_cell(r: Rect2) -> Vector2:
	return r.size - Vector2(MARGIN, MARGIN) * 2.0


## À taille native, position entière.
func _draw_centered(tex: Texture2D, r: Rect2, tint := Color.WHITE) -> void:
	if tex == null:
		return
	var at := (r.get_center() - tex.get_size() * 0.5).round()
	draw_texture_rect(tex, Rect2(at, tex.get_size()), false, tint)


## Ce que porte l'objet.
func _draw_tooltip(item: Item, target_top: float) -> void:
	if _font == null:
		return

	var title_text := item.display_name()
	# Toujours affiché : c'est ce qui décide si on le garde. Les paliers sous Alt.
	var level := Texts.t("niveau d'objet %d") % item.item_level
	var implicit := item.implicit_line()
	var crit := item.crit_line()

	var explicit_mods := PackedStringArray()
	var tiers := PackedStringArray()
	var detailed := false
	var without_origin := false
	for r in item.explicits:
		explicit_mods.append(item.explicit_line(r))
		# Vide sans provenance : la ligne s'affiche sans colonne.
		var tier := r.tier_and_span() if _alt else ""
		tiers.append(tier)
		detailed = detailed or not tier.is_empty()
		without_origin = without_origin or tier.is_empty()

	# Sous Alt, dit pourquoi aucun palier ne s'affiche.
	var note := Texts.t("paliers inconnus : ramassé avant") if _alt and without_origin else ""

	# Deux colonnes ; la gouttière sur la plus large ligne, pas en escalier.
	var w_affixes := 0.0
	for line in explicit_mods:
		w_affixes = maxf(w_affixes, RichText.width(_font, line, FONT_SIZE))
	var w_tiers := 0.0
	for line in tiers:
		w_tiers = maxf(w_tiers, _font.get_string_size(
			line, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)

	var w := maxf(TIP_MIN_W, _font.get_string_size(
		title_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_SIZE).x)
	w = maxf(w, _font.get_string_size(level, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	var column := w_affixes + (TIP_TIER_GAP + w_tiers if detailed else 0.0)
	w = maxf(w, column)
	if not implicit.is_empty():
		w = maxf(w, RichText.width(_font, implicit, FONT_SIZE))
	w = maxf(w, RichText.width(_font, crit, FONT_SIZE))
	if not note.is_empty():
		w = maxf(w, _font.get_string_size(note, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	w += TIP_PAD * 2.0

	# Le titre et le niveau, puis une ligne par affixe, plus la note s'il y en a.
	var n := explicit_mods.size() + (1 if not implicit.is_empty() else 0)
	n += 1 if not crit.is_empty() else 0
	n += 1 if not note.is_empty() else 0
	var h := TIP_PAD * 2.0 + TIP_LINE * 2.0 + float(n) * TIP_LINE
	# Le trait de séparation, quand il y a les deux sortes de lignes à séparer.
	var separated := not (implicit + crit).is_empty() and not explicit_mods.is_empty()
	if separated:
		h += TIP_LINE * 0.5

	# Alignée sur l'objet, bornée en bas et à gauche (le mode détaillé l'élargit).
	var s := _panel_size()
	var top := minf(target_top, s.y - h)
	var left := maxf(-w - TIP_GAP, -global_position.x)
	var r := Rect2(Vector2(left, top), Vector2(w, h))

	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, item.color(), false, 1.0)

	var y := r.position.y + TIP_PAD + TIP_LINE - 2.0
	draw_string(_font, Vector2(r.position.x + TIP_PAD, y), title_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_SIZE, item.color())
	y += TIP_LINE
	draw_string(_font, Vector2(r.position.x + TIP_PAD, y), level,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_LEVEL)
	if not implicit.is_empty():
		y += TIP_LINE
		RichText.draw(self, _font, Vector2(r.position.x + TIP_PAD, y), implicit, FONT_SIZE, TIP_IMPLICIT)
	if not crit.is_empty():
		y += TIP_LINE
		# Dans la couleur des tirés quand une ligne locale l'a changée.
		var raised := not is_equal_approx(item.crit_chance(), item.base.crit_chance)
		RichText.draw(self, _font, Vector2(r.position.x + TIP_PAD, y), crit, FONT_SIZE,
			TIP_EXPLICIT if raised else TIP_IMPLICIT)
	if separated:
		# Le trait sépare ce que la base garantit de ce que le tirage a donné.
		y += TIP_LINE * 0.5
		draw_line(
			Vector2(r.position.x + TIP_PAD, y - 2.0),
			Vector2(r.end.x - TIP_PAD, y - 2.0),
			TIP_IMPLICIT * Color(1.0, 1.0, 1.0, 0.5), 1.0
		)
	for i in explicit_mods.size():
		y += TIP_LINE
		RichText.draw(self, _font, Vector2(r.position.x + TIP_PAD, y), explicit_mods[i], FONT_SIZE, TIP_EXPLICIT)
		if tiers[i].is_empty():
			continue
		draw_string(
			_font,
			Vector2(r.position.x + TIP_PAD + w_affixes + TIP_TIER_GAP, y), tiers[i],
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_TIER
		)

	if not note.is_empty():
		y += TIP_LINE
		draw_string(_font, Vector2(r.position.x + TIP_PAD, y), note,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_LEVEL)

	var described := explicit_mods.duplicate()
	described.append(implicit)
	GlossaryBoxes.draw(self, _font, r, Rect2(Vector2.ZERO, _panel_size()), described)


## `framed` : le cadre d'un objet rangé ; l'objet tenu a déjà sa teinte de destination.
func _draw_item(item: Item, r: Rect2, framed: bool, fill := false) -> void:
	if framed:
		draw_rect(r, ITEM_BACK)
		draw_rect(r, item.color().darkened(ITEM_EDGE_DIM), false, 1.0)

	# Dans le sac, l'icône suit l'encombrement ; dans un emplacement (`fill`), elle
	# remplit sa case, taillée pour sa famille. Agrandissement entier, aspect conservé.
	var place := _free_cell(r)
	var own := place if fill else _span_size(Inventory.footprint(item)).min(place)
	_draw_centered(SpriteForge.inventory_icon(item.base, Vector2i(own)), r)
