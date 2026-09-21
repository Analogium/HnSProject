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
## L'étiquette d'une propriété et la note du bas, effacées : ce ne sont pas des
## bonus. La valeur, elle, sort en clair — c'est ce qu'on vient lire.
const TIP_LABEL := Color(0.46, 0.44, 0.52)
const TIP_VALUE := Color(0.88, 0.86, 0.94)
## Ce qui sépare l'étiquette de sa valeur. La ponctuation est **dans** l'étiquette
## traduite : le français met une espace devant le deux-points, l'anglais non.
const TIP_PROP_GAP := 3.0
## La colonne des paliers sous la touche « détails », plus sourde : une note de bas de page.
const TIP_TIER := Color(0.55, 0.53, 0.62)
## Gouttière entre un affixe et son palier.
const TIP_TIER_GAP := 10.0
const TIP_EXPLICIT := Color(0.55, 0.75, 1.0)
const TIP_PAD := 5.0
const TIP_LINE := 9.0
## Le bandeau du nom, collé au cadre comme celui de PoE : c'est lui qui donne le
## haut de l'infobulle, sans marge au-dessus.
const TIP_BAND := 14.0
const TIP_BAND_ALPHA := 0.17
## La hauteur d'un trait de séparation, gouttières comprises.
const TIP_RULE := 6.0
## Écart entre le sac et son infobulle.
const TIP_GAP := 5.0
const TIP_MIN_W := 74.0
const FONT_SIZE := 8
const TITLE_SIZE := 9


## Une ligne d'infobulle. Les blocs — nom, propriétés, exigences, implicite, affixes
## — se construisent en liste, puis se mesurent et se dessinent en la relisant : deux
## passes écrites à la main divergeaient à chaque ligne ajoutée.
class TipLine:
	## `MOD` est une ligne d'affixe, la seule qui porte une colonne de palier ; c'est
	## ce qui la sépare d'un `TEXT`.
	enum Kind { TITLE, PROPERTY, TEXT, MOD, RULE }

	var kind: Kind
	## Le texte, ou l'étiquette d'une propriété.
	var text := ""
	## La valeur d'une propriété, mise en avant derrière son étiquette.
	var value := ""
	## Le palier d'un affixe sous la touche « détails », calé à droite de l'infobulle. Vide partout
	## ailleurs, et sur un affixe ramassé avant les paliers.
	var aside := ""
	var tint := Color.WHITE
	var value_tint := Color.WHITE

	func _init(p_kind: Kind, p_text := "", p_tint := Color.WHITE) -> void:
		kind = p_kind
		text = p_text
		tint = p_tint

	static func property(label_text: String, value_text: String, value_color: Color) -> TipLine:
		var line := TipLine.new(Kind.PROPERTY, label_text, InventoryPanel.TIP_LABEL)
		line.value = value_text
		line.value_tint = value_color
		return line

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
## L'action « détails » tenue : paliers et fourchettes. Relevée dans _process,
## voir là-bas.
var _detailed := false
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
			_right_click(button.ctrl_pressed)
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


## Jeter ce qu'on tient, jeter au sol avec Ctrl, retirer ce qui est porté, ou équiper
## ce qu'on survole.
func _right_click(to_the_ground: bool) -> void:
	if _held != null:
		drop_requested.emit(_held)
		_held = null
		queue_redraw()
		return
	if _player == null:
		return
	if to_the_ground:
		_drop_hovered()
	elif _hover_slot >= 0:
		_unequip(EquipmentSlots.ids()[_hover_slot])
	else:
		_equip(_hover)


## Ctrl + clic droit : au sol, sans passer par la main. Depuis le sac comme depuis un
## emplacement — sous les yeux du joueur c'est le même geste.
func _drop_hovered() -> void:
	var item := (
		_player.unequip(EquipmentSlots.ids()[_hover_slot]) if _hover_slot >= 0
		else _inventory.take_at(_hover)
	)
	if item != null:
		drop_requested.emit(item)
	queue_redraw()


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
		# Hors grille exprès : `_return_held` cherchera une place.
		_hold(worn, Vector2i(-1, -1))
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


## Un objet en main, saisi par son centre : la prise d'un emplacement d'équipement et
## celle d'un délogé, qui n'ont pas de case attrapée sous le curseur.
func _hold(item: Item, from: Vector2i) -> void:
	_held = item
	_from = from
	_grab = Inventory.footprint(item) / 2
	_grab_px = _span_size(Inventory.footprint(item)) * 0.5


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
	elif _swap_in(_cell_at(point) - _grab):
		queue_redraw()
		return

	if drag:
		var rest := _return_held()
		if rest != null:
			drop_requested.emit(rest)
	queue_redraw()


## Pose l'objet tenu à cette case, en **échangeant** avec celui qui l'occupe. Vrai
## quand il s'est posé — la main peut alors tenir le délogé, et `_resolve` ne doit
## plus le renvoyer au sac.
##
## L'échange vise d'abord la place que l'objet tenu vient de quitter : deux objets
## permutent alors sans rien déranger. À défaut — tailles différentes, objet venu
## d'un emplacement d'équipement —, le délogé passe en main, et c'est au joueur de
## lui trouver une place.
func _swap_in(cell: Vector2i) -> bool:
	if _inventory.place(_held, cell):
		_held = null
		return true
	var blocker := _inventory.lone_blocker(_held, cell)
	if blocker == Inventory.EMPTY:
		return false

	var origin: Vector2i = _inventory.placed[blocker].cell
	var evicted := _inventory.take_at(origin)
	if not _inventory.place(_held, cell):
		# La place libérée ne suffisait pas : rien n'aura bougé.
		_inventory.place(evicted, origin)
		return false
	if _from.x >= 0 and _inventory.place(evicted, _from):
		_held = null
	else:
		_hold(evicted, origin)
	return true


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

	# L'état **réel** à chaque image, et non l'événement : le gestionnaire de
	# fenêtres avale le relâchement quand le focus part.
	var held := Input.is_action_pressed("item_details")
	if held != _detailed:
		_detailed = held
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


## Ce que porte l'objet, en blocs séparés : le nom sur son bandeau de rareté, les
## propriétés de la base, le niveau, l'implicite, puis les affixes.
func _draw_tooltip(item: Item, target_top: float) -> void:
	if _font == null:
		return

	var lines := _tip_lines(item)

	# La colonne des paliers est réservée une fois pour toutes : les affixes se
	# centrent sur ce qu'elle leur laisse, et ne peuvent plus la rencontrer.
	var aside_col := 0.0
	for line in lines:
		if line.kind == TipLine.Kind.MOD and not line.aside.is_empty():
			aside_col = maxf(aside_col, _tip_span(line.aside))
	if aside_col > 0.0:
		aside_col += TIP_TIER_GAP

	var w := TIP_MIN_W
	# Pas de marge en haut : le bandeau du nom touche le cadre.
	var h := TIP_PAD
	for line in lines:
		var need := _tip_width(line)
		if line.kind == TipLine.Kind.MOD:
			need += aside_col
		w = maxf(w, need)
		h += _tip_height(line.kind)
	w += TIP_PAD * 2.0

	# Alignée sur l'objet, bornée en bas et à gauche (le mode détaillé l'élargit).
	var s := _panel_size()
	var top := minf(target_top, s.y - h)
	var left := maxf(-w - TIP_GAP, -global_position.x)
	var r := Rect2(Vector2(left, top), Vector2(w, h))

	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, item.color(), false, 1.0)

	var middle := r.position.x + w * 0.5
	var mod_middle := r.position.x + (w - aside_col) * 0.5
	var y := r.position.y
	for line in lines:
		var baseline := y + TIP_LINE - 2.0
		match line.kind:
			TipLine.Kind.TITLE:
				_draw_tip_title(line, Rect2(r.position, Vector2(w, TIP_BAND)), middle)
			TipLine.Kind.RULE:
				draw_line(
					Vector2(r.position.x + TIP_PAD, y + TIP_RULE * 0.5),
					Vector2(r.end.x - TIP_PAD, y + TIP_RULE * 0.5),
					Color(TIP_IMPLICIT, 0.35), 1.0
				)
			TipLine.Kind.PROPERTY:
				var x := roundf(middle - _tip_width(line) * 0.5)
				draw_string(_font, Vector2(x, baseline), line.text,
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, line.tint)
				draw_string(
					_font, Vector2(x + _tip_span(line.text) + TIP_PROP_GAP, baseline), line.value,
					HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, line.value_tint
				)
			TipLine.Kind.MOD:
				RichText.draw_centered(
					self, _font, Vector2(0.0, baseline), mod_middle, line.text, FONT_SIZE, line.tint
				)
				if not line.aside.is_empty():
					draw_string(
						_font, Vector2(r.end.x - TIP_PAD - _tip_span(line.aside), baseline),
						line.aside, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_TIER
					)
			_:
				RichText.draw_centered(
					self, _font, Vector2(0.0, baseline), middle, line.text, FONT_SIZE, line.tint
				)
		y += _tip_height(line.kind)

	var described := PackedStringArray()
	for line in lines:
		if line.kind == TipLine.Kind.MOD or line.kind == TipLine.Kind.TEXT:
			described.append(line.text)
	GlossaryBoxes.draw(self, _font, r, Rect2(Vector2.ZERO, _panel_size()), described)


## Le nom sur son bandeau, teinté de la rareté et fermé par un trait : c'est lui
## qui donne à l'infobulle son en-tête, avant même qu'on lise une ligne.
func _draw_tip_title(line: TipLine, band: Rect2, middle: float) -> void:
	draw_rect(Rect2(band.position + Vector2.ONE, band.size - Vector2(2.0, 1.0)),
		Color(line.tint, TIP_BAND_ALPHA))
	draw_line(Vector2(band.position.x, band.end.y), Vector2(band.end.x, band.end.y),
		Color(line.tint, 0.45), 1.0)
	var x := roundf(middle - _tip_span(line.text, TITLE_SIZE) * 0.5)
	draw_string(_font, Vector2(x, band.end.y - 4.0), line.text,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_SIZE, line.tint)


## Les lignes dans l'ordre où elles se lisent. Un bloc vide ne laisse pas de trait
## derrière lui : c'est `_tip_block()` qui en décide.
func _tip_lines(item: Item) -> Array[TipLine]:
	var out: Array[TipLine] = []
	out.append(TipLine.new(TipLine.Kind.TITLE, item.display_name(), item.color()))

	# Ce que la base est, avant ce qu'elle a tiré : la chance critique d'une arme, la
	# défense d'une armure. En avant quand une ligne locale l'a montée, en clair sinon.
	var properties: Array[TipLine] = []
	if item.base.family == ItemBase.WEAPON_FAMILY:
		var raised := not is_equal_approx(item.crit_chance(), item.base.crit_chance)
		properties.append(TipLine.property(
			Texts.t("Chance critique de base :"),
			StatMod.format(SkillStats.CRIT_CHANCE, item.crit_chance()),
			TIP_EXPLICIT if raised else TIP_VALUE
		))
	var defense := item.base.defense_stat()
	if not defense.is_empty():
		var raised := not is_equal_approx(item.defense(), item.base.implicit_value)
		properties.append(TipLine.property(
			Texts.t("Armure :") if defense == "armor" else Texts.t("Esquive :"),
			StatMod.format(defense, item.defense()),
			TIP_EXPLICIT if raised else TIP_VALUE
		))
	_tip_block(out, properties)

	# Toujours affiché : c'est ce qui décide si on le garde. Les paliers sous la touche « détails ».
	_tip_block(out, [TipLine.property(
		Texts.t("Niveau d'objet :"), str(item.item_level), TIP_VALUE
	)] as Array[TipLine])

	# Majuscule en tête, implicite comme tirés : ce sont les mêmes lignes, et une
	# seule des deux sortes capitalisée se verrait.
	var implicit := RichText.capitalized(item.implicit_line())
	if not implicit.is_empty():
		_tip_block(out, [TipLine.new(TipLine.Kind.TEXT, implicit, TIP_IMPLICIT)] as Array[TipLine])

	var mods: Array[TipLine] = []
	var without_origin := false
	for rolled in item.explicits:
		var line := TipLine.new(
			TipLine.Kind.MOD, RichText.capitalized(item.explicit_line(rolled)), TIP_EXPLICIT
		)
		# Vide sans provenance : la ligne s'affiche sans colonne.
		line.aside = rolled.tier_and_span() if _detailed else ""
		without_origin = without_origin or line.aside.is_empty()
		mods.append(line)
	_tip_block(out, mods)

	# Sous la touche « détails », dit pourquoi aucun palier ne s'affiche.
	if _detailed and without_origin and not mods.is_empty():
		_tip_block(out, [TipLine.new(
			TipLine.Kind.TEXT, Texts.t("paliers inconnus : ramassé avant"), TIP_LABEL
		)] as Array[TipLine])
	return out


## Un bloc derrière son trait de séparation, ou rien s'il est vide : un trait qui ne
## sépare rien est une ligne perdue.
func _tip_block(into: Array[TipLine], block: Array[TipLine]) -> void:
	if block.is_empty():
		return
	into.append(TipLine.new(TipLine.Kind.RULE))
	into.append_array(block)


func _tip_height(kind: TipLine.Kind) -> float:
	match kind:
		TipLine.Kind.TITLE:
			return TIP_BAND
		TipLine.Kind.RULE:
			return TIP_RULE
	return TIP_LINE


## Ce que la ligne réclame, colonne des paliers non comprise.
func _tip_width(line: TipLine) -> float:
	match line.kind:
		TipLine.Kind.TITLE:
			return _tip_span(line.text, TITLE_SIZE)
		TipLine.Kind.PROPERTY:
			return _tip_span(line.text) + TIP_PROP_GAP + _tip_span(line.value)
		TipLine.Kind.RULE:
			return 0.0
	return RichText.width(_font, line.text, FONT_SIZE)


## Un texte sans terme de glossaire : étiquette, valeur, palier, nom.
func _tip_span(text_value: String, size_value := FONT_SIZE) -> float:
	return _font.get_string_size(text_value, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_value).x


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
