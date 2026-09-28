class_name InventoryPanel
extends Control

## Le sac (I) : chaque objet occupe sa place réelle. Deux gestes, glisser et
## clic-clic ; un relâchement sans déplacement est un clic. Relâché hors du panneau,
## l'objet tombe ; le clic droit équipe, retire, jette ou prend une pièce de monnaie,
## que le clic suivant applique. Le sac vit sur le joueur.
##
## En ville, **une seconde grille** s'ouvre à gauche de l'écran — un onglet du coffre,
## ou l'étal du marchand — et les mêmes gestes y valent : glisser, échanger, empiler.
## Ctrl + clic passe un objet d'une grille à l'autre.

## Un signal : c'est la scène qui sait où poser au sol.
signal drop_requested(item: Item)

const CELL := 20.0
const PAD := 1.0
## Une ligne de titre : celui du sac sous l'équipement, celui du coffre en tête.
const HEADER := 16.0
## Deux lignes d'aide.
const FOOTER := 22.0
## Le vide entre le bord d'un panneau et ce qu'il contient, et celui entre le cadre de
## l'équipement et ses emplacements.
const EDGE := 6.0
const FRAME := 6.0
## La fenêtre de personnage, à la manière de Hero Siege (jalon 31) : l'arme et la main
## gauche en grandes cartes de part et d'autre, tête, torse et ceinture au milieu. Chaque
## emplacement tient au moins l'encombrement de sa famille dans le sac, dont l'icône est
## taillée à 1:1 (`test_each_slot_holds_its_family_footprint`).
const DOLL := {
	"helmet": Rect2i(4, 0, 2, 2), "amulet": Rect2i(8, 0, 2, 2),
	"weapon": Rect2i(0, 3, 2, 4), "chest": Rect2i(4, 2, 2, 3), "offhand": Rect2i(8, 3, 2, 4),
	"ring_left": Rect2i(3, 5, 1, 1), "belt": Rect2i(4, 5, 2, 1), "ring_right": Rect2i(6, 5, 1, 1),
	"gloves": Rect2i(0, 7, 2, 2), "boots": Rect2i(8, 7, 2, 2),
}
const DOLL_COLS := 10
const DOLL_ROWS := 9

## Trois cases de haut : les 47 pixels de la sorcière n'entraient pas dans deux.
const DOLL_AREA := Rect2i(0, 0, 3, 3)
const DOLL_ANIM := "idle_down"
## Les pieds sous le centre de la zone : la sorcière y gagne la place de son chapeau.
const DOLL_FEET := 9.0

## Un emplacement vide montre l'objet qu'il attend, très sombre : lisible sans texte.
const GHOST := Color(1.0, 1.0, 1.0, 0.13)
## Marge d'une icône : sans elle, l'objet mange les lignes de la grille.
const MARGIN := 3

## La palette cramoisie du sac et du coffre, choisie sur planche (jalon 31) ; les autres
## panneaux gardent celle de `UiPalette`.
## Opaque : pleine hauteur, le panneau recouvre le bandeau d'aide et les jauges.
const BACK := Color(0.118, 0.075, 0.082)
const TRIM := Color(0.463, 0.118, 0.165)
const TRIM_DARK := Color(0.227, 0.055, 0.078)
const FRAME_BACK := Color(0.173, 0.094, 0.106)
const INK := Color(0.87, 0.80, 0.64)
const INK_DIM := Color(0.59, 0.50, 0.43)
const CELL_BACK := Color(0.059, 0.059, 0.094)
const CELL_EDGE := Color(0.173, 0.133, 0.157)
const SLOT := Color(0.078, 0.055, 0.067)
const SLOT_EDGE := Color(0.275, 0.149, 0.173)
## Le fond d'un objet donne sa forme et sa rareté avant l'icône : cramoisi pour un
## objet commun, sa couleur de rareté assombrie sinon.
const ITEM_BACK := Color(0.275, 0.094, 0.118)
const RARITY_BACK_DIM := 0.68
## Le cadre d'un objet rangé, dans sa rareté assombrie.
const ITEM_EDGE_DIM := 0.3
## Au-delà, un relâchement finit un glisser ; en deçà, c'est un clic tremblé.
const DRAG_MIN := 5.0
const CAN_PLACE := Color(0.35, 0.85, 0.45, 0.28)
const BLOCKED := Color(0.90, 0.30, 0.28, 0.28)
## Écart entre le sac et son infobulle, dessinée par `ItemTooltip`.
const TIP_GAP := 5.0
const FONT_SIZE := 8

## Le coffre et l'étal occupent le bord gauche de l'écran, sur toute sa hauteur, comme le
## sac le bord droit : jauges et barre passent dessous (jalon 31).
const STORAGE_AT := Vector2.ZERO
## Les onglets, en rangée sous le titre.
const TAB := Vector2(30.0, 12.0)
const TAB_GAP := 2.0
const SELL := Vector2(48.0, 12.0)
const TAB_BACK := Color(0.361, 0.086, 0.125)
const TAB_ON := Color(0.588, 0.133, 0.196)

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
## La pièce de monnaie choisie au clic droit, restée dans le sac jusqu'à ce que le
## clic suivant l'applique ; null hors de ce geste.
var _coin: Item
var _coin_cell := Vector2i.ZERO
## Les onglets du coffre, ou l'étal seul ; vide hors de la ville.
var _pages: Array[Inventory] = []
## L'onglet montré : la grille que visent les gestes.
var _storage: Inventory
## L'étal : « Vendre » le vide, et le refermer rend au sac ce qu'il porte encore.
var _selling := false
## La grille survolée, et celle d'où vient l'objet tenu : le sac ou `_storage`.
var _hover_grid: Inventory
var _from_grid: Inventory
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
	title.add_theme_color_override("font_color", INK)


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
	_hover_grid = _inventory
	_from_grid = _inventory
	_inventory.changed.connect(_on_changed)
	player.equipment_changed.connect(_on_changed)

	# Taille déduite de la grille ; le coin bas-droite reste celui des ancres.
	var s := _panel_size()
	offset_left = offset_right - s.x
	offset_top = offset_bottom - s.y
	# Le titre et le compte de cases, juste au-dessus de la grille qu'ils décrivent.
	title.position = Vector2(_grid_left(), _grid_top() - HEADER)
	title.size = Vector2(s.x - _grid_left() - EDGE, HEADER)

	_on_changed()


func toggle() -> void:
	visible = not visible
	Game.grab_ui_input(self, visible)
	if visible:
		# Sinon la case survolée reste celle d'avant la fermeture.
		_track(get_local_mouse_position())
	else:
		_coin = null
		var left := _return_held()
		if left != null:
			drop_requested.emit(left)
		_close_storage()
	_on_changed()


## Le coffre, un onglet à la fois, à côté du sac.
func open_stash(tabs: Array[Inventory]) -> void:
	_open_storage(tabs, false)


## L'étal du marchand, vide à chaque ouverture.
func open_merchant() -> void:
	_open_storage([Inventory.new(Inventory.DEFAULT_COLS, Inventory.DEFAULT_ROWS)], true)


func storage_open() -> bool:
	return _storage != null


func _open_storage(pages: Array[Inventory], selling: bool) -> void:
	if visible:
		toggle()
	_pages = pages
	_storage = pages[0]
	_selling = selling
	toggle()


## **Rien ne se perd** : ce que l'étal porte encore revient au sac, et au sol s'il
## est plein. On n'a pas vendu.
func _close_storage() -> void:
	if _selling:
		var unsold: Array[Item] = []
		for p in _storage.placed:
			unsold.append(p.data)
		_storage.clear()
		for item in unsold:
			_stow(item)
	_pages = []
	_storage = null
	_selling = false
	_hover_grid = _inventory


## Ce que l'étal porte disparaît. Il ne rapporte rien encore.
func _sell() -> void:
	_storage.clear()
	queue_redraw()


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
			if _coin != null:
				_use_coin(button.position)
			elif _storage_click(button.position):
				pass   # un objet en main se range dans l'onglet qu'on vient d'ouvrir
			elif _held != null:
				_resolve(button.position, false)
			elif button.ctrl_pressed and _storage != null:
				_transfer(button.position)
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
	var grid := _grid_at(point)
	var cell := _cell_at(point, grid)
	var slot := _slot_at(point)
	# Un objet en main suit au pixel : redessiner à chaque mouvement.
	if grid == _hover_grid and cell == _hover and slot == _hover_slot and _held == null and _coin == null:
		return
	_hover_grid = grid
	_hover = cell
	_hover_slot = slot
	queue_redraw()


## Jeter ce qu'on tient, jeter au sol avec Ctrl, retirer ce qui est porté, prendre la
## pièce survolée ou équiper l'objet survolé. Une pièce déjà prise se repose.
func _right_click(to_the_ground: bool) -> void:
	if _coin != null:
		_coin = null
		queue_redraw()
		return
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
	elif _hover_grid != _inventory:
		# Ni pièce ni équipement depuis le coffre : il faut d'abord le sortir.
		return
	elif Currency.is_coin(_item_at(_hover)):
		_coin = _item_at(_hover)
		_coin_cell = _inventory.placed[_inventory.index_at(_hover)].cell
		queue_redraw()
	else:
		_equip(_hover)


## Le clic qui suit le clic droit sur une pièce : dépensée si l'objet visé l'accepte.
## Dans tous les cas le geste se termine — seul un objet du sac se vise.
func _use_coin(point: Vector2) -> void:
	if _grid_at(point) == _inventory and Currency.apply(_coin.base, _item_at(_cell_at(point)), Game.rng):
		_inventory.spend_one(_coin_cell)
	_coin = null
	queue_redraw()


func _item_at(cell: Vector2i) -> Item:
	var index := _inventory.index_at(cell)
	return null if index == Inventory.EMPTY else _inventory.placed[index].data


## Un onglet ou le bouton « Vendre » : vrai si le clic l'a touché.
func _storage_click(point: Vector2) -> bool:
	for i in _pages.size():
		if _tab_rect(i).has_point(point):
			_storage = _pages[i]
			_track(point)
			return true
	if _selling and _sell_rect().has_point(point):
		_sell()
		return true
	return false


## Ctrl + clic : d'une grille à l'autre sans passer par la main, comme PoE. Sur les
## piles de l'autre d'abord ; ce qui n'y tient pas reste où il était.
func _transfer(point: Vector2) -> void:
	var from := _grid_at(point)
	var to := _inventory if from == _storage else _storage
	var index := from.index_at(_cell_at(point, from))
	if index == Inventory.EMPTY:
		return
	var origin: Vector2i = from.placed[index].cell
	var item := from.take_at(origin)
	if not to.add(item):
		from.place(item, origin)
	queue_redraw()


## Ctrl + clic droit : au sol, sans passer par la main. Depuis le sac comme depuis un
## emplacement — sous les yeux du joueur c'est le même geste.
func _drop_hovered() -> void:
	var item := (
		_player.unequip(EquipmentSlots.ids()[_hover_slot]) if _hover_slot >= 0
		else _hover_grid.take_at(_hover)
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
	_stow(old)
	return true


func _unequip(slot: String) -> void:
	_stow(_player.unequip(slot))
	queue_redraw()


## Au sac, au sol s'il est plein : **rien ne se perd**. L'étal refermé, l'objet
## délogé d'un emplacement et celui qu'on retire l'écrivaient chacun.
func _stow(item: Item) -> void:
	if item != null and not _inventory.add(item):
		drop_requested.emit(item)


## Un objet du sac ou d'un emplacement ; le vide ne fait rien.
func _take(point: Vector2) -> void:
	var slot := _slot_at(point)
	if slot >= 0:
		var worn: Item = _player.equipped(EquipmentSlots.ids()[slot]) if _player != null else null
		if worn == null:
			return
		_player.unequip(EquipmentSlots.ids()[slot])
		# Hors grille exprès : `_return_held` cherchera une place.
		_hold(worn, Vector2i(-1, -1), _inventory)
		queue_redraw()
		return

	var grid := _grid_at(point)
	var cell := _cell_at(point, grid)
	var index := grid.index_at(cell)
	if index == Inventory.EMPTY:
		return
	_from = grid.placed[index].cell
	_from_grid = grid
	_grab = cell - _from
	_grab_px = point - _rect_of(_from, Vector2i.ONE, grid).position
	_held = grid.take_at(cell)
	queue_redraw()


## Un objet en main, saisi par son centre : la prise d'un emplacement d'équipement et
## celle d'un délogé, qui n'ont pas de case attrapée sous le curseur.
func _hold(item: Item, from: Vector2i, grid: Inventory) -> void:
	_held = item
	_from = from
	_from_grid = grid
	_grab = Inventory.footprint(item) / 2
	_grab_px = _span_size(Inventory.footprint(item)) * 0.5


## Pose ce qu'on tient : emplacement, sac, ou sol hors du panneau. Un clic raté garde
## l'objet en main ; un relâchement raté le rend au sac.
func _resolve(point: Vector2, drag: bool) -> void:
	if _held == null:
		return

	var slot := _slot_at(point)
	var grid := _grid_at(point)
	if slot >= 0:
		if _equip_held(EquipmentSlots.ids()[slot]):
			queue_redraw()
			return
	elif not _owns_point(point):
		# Hors des panneaux : au sol.
		drop_requested.emit(_held)
		_held = null
		queue_redraw()
		return
	elif _swap_in(_cell_at(point, grid) - _grab, grid):
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
func _swap_in(cell: Vector2i, grid: Inventory) -> bool:
	if grid.place(_held, cell):
		_held = null
		return true
	var blocker := grid.lone_blocker(_held, cell)
	if blocker == Inventory.EMPTY:
		return false
	# Sur une pile de même base qui a de la place : on verse au lieu d'échanger.
	if grid.stack_onto(blocker, _held):
		if _held.count == 0:
			_held = null
		return true

	var origin: Vector2i = grid.placed[blocker].cell
	var evicted := grid.take_at(origin)
	if not grid.place(_held, cell):
		# La place libérée ne suffisait pas : rien n'aura bougé.
		grid.place(evicted, origin)
		return false
	if _from.x >= 0 and _from_grid.place(evicted, _from):
		_held = null
	else:
		_hold(evicted, origin, grid)
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
	if _from_grid.place(item, _from) or _inventory.add(item):
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
	var body := _player.sprite.archetype
	var key := "%s:%d:%s" % [body, variant_index, weapon]
	if key == _doll_key:
		return
	_doll_key = key
	_doll_frames = SpriteForge.frames(body, variant_index, weapon)


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
## deviennent sourds ; sauf avec un objet en main, qu'on peut lâcher au-dehors, ou
## une pièce prise, que ce clic repose au lieu de lancer une attaque.
func _owns_click(point: Vector2) -> bool:
	return _held != null or _coin != null or _owns_point(point)


func _owns_point(point: Vector2) -> bool:
	return _panel_rect().has_point(point) or _storage_rect().has_point(point)


func _panel_rect() -> Rect2:
	return Rect2(Vector2.ZERO, _panel_size())


## Le coffre ou l'étal, dans le repère du panneau ; vide quand rien n'est ouvert.
func _storage_rect() -> Rect2:
	if _storage == null:
		return Rect2()
	return Rect2(
		STORAGE_AT - global_position,
		Vector2(_storage.cols * (CELL + PAD) + PAD + EDGE * 2.0, _screen_height())
	)


## Les onglets, en rangée sous le titre ; aucun pour l'étal.
func _tab_rect(index: int) -> Rect2:
	if _selling:
		return Rect2()
	var box := _storage_rect()
	return Rect2(box.position + Vector2(EDGE + float(index) * (TAB.x + TAB_GAP), HEADER + 2.0), TAB)


## Le bouton « Vendre », à la place des onglets.
func _sell_rect() -> Rect2:
	return Rect2(_storage_rect().position + Vector2(EDGE, HEADER + 2.0), SELL)


## La grille sous ce point : l'onglet ouvert s'il le couvre, le sac sinon — dont les
## cases hors grille disent déjà « rien ».
func _grid_at(point: Vector2) -> Inventory:
	return _storage if _storage_rect().has_point(point) else _inventory


func _grid_or_bag(grid: Inventory) -> Inventory:
	return grid if grid != null else _inventory


## Le coin haut-gauche de la case (0, 0) d'une grille.
func _grid_origin(grid: Inventory) -> Vector2:
	if grid == _inventory:
		return Vector2(_grid_left(), _grid_top() + PAD)
	return _storage_rect().position + Vector2(EDGE + PAD, HEADER + TAB.y + EDGE + PAD)


## Le plus large des deux, la grille du sac ou le cadre de l'équipement ; toute la
## hauteur de l'écran, comme Hero Siege.
func _panel_size() -> Vector2:
	return Vector2(_panel_width(), _screen_height())


func _panel_width() -> float:
	return maxf(_inventory.cols * (CELL + PAD) + PAD, _equip_size().x + FRAME * 2.0) + EDGE * 2.0


## Centré en haut du panneau ; position entière, sinon lignes floues.
func _frame_rect() -> Rect2:
	var inner := _equip_size() + Vector2(FRAME, FRAME) * 2.0
	return Rect2(Vector2(floorf((_panel_width() - inner.x) * 0.5), EDGE), inner)


func _screen_height() -> float:
	return get_viewport_rect().size.y


## Un rectangle de cases, en pixels — la mesure de base de tout le panneau.
func _span_size(span: Vector2i) -> Vector2:
	return Vector2(span) * (CELL + PAD) - Vector2(PAD, PAD)


## Même pas que le sac : les deux grilles s'alignent.
func _doll_rect(zone: Rect2i) -> Rect2:
	return Rect2(
		_frame_rect().position + Vector2(FRAME, FRAME) + Vector2(zone.position) * (CELL + PAD),
		_span_size(zone.size)
	)


## Chaque grille centrée ; position entière, sinon lignes floues.

func _grid_left() -> float:
	return _centered(_inventory.cols * (CELL + PAD) + PAD)


func _centered(width: float) -> float:
	return maxf(floorf((_panel_size().x - width) * 0.5), PAD)


func _slot_rect(index: int) -> Rect2:
	return _doll_rect(DOLL[EquipmentSlots.ids()[index]])


## L'objet type d'un emplacement, pris dans le catalogue.
static func _ghost_kind(slot: String) -> String:
	var base := ItemCatalog.first_of(EquipmentSlots.family_of(slot))
	return base.kind if base != null else ""


## L'encombrement de la grille du personnage, en pixels.
func _equip_size() -> Vector2:
	return _span_size(Vector2i(DOLL_COLS, DOLL_ROWS))


## Où commence le sac : sous le cadre de l'équipement et le titre.
func _grid_top() -> float:
	return _frame_rect().end.y + EDGE + HEADER


## Un rectangle de cases d'une grille — le sac par défaut —, en pixels du panneau.
func _rect_of(cell: Vector2i, span: Vector2i, grid: Inventory = null) -> Rect2:
	return Rect2(_grid_origin(_grid_or_bag(grid)) + Vector2(cell) * (CELL + PAD), _span_size(span))


## Peut sortir de la grille : poser à cheval sur le bord doit échouer.
func _cell_at(point: Vector2, grid: Inventory = null) -> Vector2i:
	return Vector2i(((point - _grid_origin(_grid_or_bag(grid))) / (CELL + PAD)).floor())


func _slot_at(point: Vector2) -> int:
	for i in EquipmentSlots.count():
		if _slot_rect(i).has_point(point):
			return i
	return -1


func _draw() -> void:
	if _inventory == null:
		return

	var s := _panel_size()
	_draw_panel(Rect2(Vector2.ZERO, s))
	_draw_frame(_frame_rect())

	if _storage != null:
		_draw_storage()
	_draw_grid(_inventory)
	_draw_doll()
	_draw_equipment()

	var hovered := _hover_grid.index_at(_hover) if _held == null else Inventory.EMPTY
	if hovered != Inventory.EMPTY:
		var targeted: Inventory.Placed = _hover_grid.placed[hovered]
		var r := _rect_of(targeted.cell, targeted.rect().size, _hover_grid)
		# Survolé, le cadre prend la rareté pleine.
		draw_rect(r, targeted.data.color(), false, 1.0)
		if _coin != null:
			var accepted := _hover_grid == _inventory and Currency.accepts(_coin.base, targeted.data)
			draw_rect(r, CAN_PLACE if accepted else BLOCKED)
		_draw_tooltip(targeted.data, r.position.y, _hover_grid != _inventory)
	if _coin != null:
		# À côté du curseur et non dessous : la cible reste visible. L'icône seule, sans
		# le nombre de la pile : on n'en applique qu'une.
		var at := Rect2(_mouse + Vector2(4.0, 4.0), _span_size(Vector2i.ONE))
		_draw_centered(SpriteForge.inventory_icon(_coin.base, Vector2i(_free_cell(at))), at)

	if _held != null:
		var span := Inventory.footprint(_held)
		var at := _hover - _grab
		# La destination calée sur la grille, verte ou rouge, et l'objet qui suit le curseur
		# au pixel.
		if _hover_slot < 0 and _owns_point(_mouse):
			draw_rect(_rect_of(at, span, _hover_grid), CAN_PLACE if _hover_grid.fits(_held, at) else BLOCKED)
		_draw_item(_held, Rect2(_mouse - _grab_px, _span_size(span)), false)

	if _font != null:
		draw_string(_font, Vector2(EDGE, s.y - 13.0),
			Texts.t("[clic] prendre et poser     [clic droit] équiper / retirer"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, INK_DIM)
		draw_string(_font, Vector2(EDGE, s.y - 3.0),
			Texts.t("lâché hors du sac : jeté au sol"),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, INK_DIM)


## Le fond d'un panneau et son double liseré.
func _draw_panel(r: Rect2) -> void:
	draw_rect(r, BACK)
	draw_rect(r, TRIM_DARK, false, 1.0)
	draw_rect(r.grow(-1.0), TRIM, false, 1.0)


## Le cadre de l'équipement : double liseré, et un carré plein à chaque coin.
func _draw_frame(r: Rect2) -> void:
	draw_rect(r, FRAME_BACK)
	draw_rect(r, TRIM_DARK, false, 1.0)
	draw_rect(r.grow(-2.0), TRIM, false, 1.0)
	var corner := Vector2(4.0, 4.0)
	var inner := r.grow(-2.0)
	for at in [inner.position, Vector2(inner.end.x - corner.x, inner.position.y),
			Vector2(inner.position.x, inner.end.y - corner.y), inner.end - corner]:
		draw_rect(Rect2(at, corner), TRIM)


## Les cases d'une grille et ce qui y est rangé.
func _draw_grid(grid: Inventory) -> void:
	for y in grid.rows:
		for x in grid.cols:
			_draw_cell(_rect_of(Vector2i(x, y), Vector2i.ONE, grid))
	for p in grid.placed:
		_draw_item(p.data, _rect_of(p.cell, p.rect().size, grid), true)


## Le coffre ou l'étal : son cadre, son titre, ses onglets ou son bouton, sa grille.
func _draw_storage() -> void:
	var box := _storage_rect()
	_draw_panel(box)
	_draw_grid(_storage)
	if _font == null:
		return
	draw_string(_font, box.position + Vector2(0.0, 12.0),
		Texts.t("MARCHAND") if _selling else Texts.t("COFFRE"),
		HORIZONTAL_ALIGNMENT_CENTER, box.size.x, 10, INK)
	if _selling:
		_draw_button(_sell_rect(), Texts.t("Vendre"), _sell_rect().has_point(_mouse))
	else:
		for i in _pages.size():
			_draw_button(_tab_rect(i), str(i + 1), _pages[i] == _storage)
	draw_string(_font, Vector2(box.position.x + EDGE, box.end.y - 3.0),
		Texts.t("[ctrl + clic] d'une grille à l'autre"),
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, INK_DIM)


func _draw_button(r: Rect2, text_value: String, lit: bool) -> void:
	draw_rect(r, TAB_ON if lit else TAB_BACK)
	draw_rect(r, TRIM_DARK, false, 1.0)
	draw_string(_font, Vector2(r.position.x, r.end.y - 3.0), text_value,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, FONT_SIZE, INK if lit else INK_DIM)


## Le rectangle du portrait, dans le coin que les emplacements laissent libre.
func _doll_area_rect() -> Rect2:
	return _doll_rect(DOLL_AREA)


## La silhouette et l'arme réellement tenue, en grand, à même le cadre.
func _draw_doll() -> void:
	var zone := _doll_area_rect()
	if _doll_frames == null or not _doll_frames.has_animation(DOLL_ANIM):
		return
	var tex := _doll_frames.get_frame_texture(DOLL_ANIM, _doll_shown)
	if tex == null:
		return
	# Taille native, pieds calés comme en jeu : sans `offset_of()`, la sorcière,
	# plus haute, serait posée plus bas que le guerrier.
	var at := (zone.get_center() - tex.get_size() * 0.5 + SpriteForge.offset_of(_player.sprite.archetype)).round()
	draw_texture(tex, at + Vector2(0.0, DOLL_FEET))


## Dans le même panneau que le sac : équiper est un geste entre les deux.
func _draw_equipment() -> void:
	for i in EquipmentSlots.count():
		var slot: String = EquipmentSlots.ids()[i]
		var r := _slot_rect(i)
		var item: Item = _player.equipped(slot) if _player != null else null

		if item != null:
			_draw_item(item, r, true)
		else:
			_draw_cell(r, SLOT, SLOT_EDGE)
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
func _draw_cell(r: Rect2, back := CELL_BACK, edge := CELL_EDGE) -> void:
	draw_rect(r, back)
	draw_rect(r, edge, false, 1.0)


## La place utile d'un rectangle, marge déduite.
func _free_cell(r: Rect2) -> Vector2:
	return r.size - Vector2(MARGIN, MARGIN) * 2.0


## À taille native, position entière.
func _draw_centered(tex: Texture2D, r: Rect2, tint := Color.WHITE) -> void:
	if tex == null:
		return
	var at := (r.get_center() - tex.get_size() * 0.5).round()
	draw_texture_rect(tex, Rect2(at, tex.get_size()), false, tint)


## L'infobulle, alignée sur l'objet et bornée en bas et à gauche : le mode détaillé
## l'élargit. Celle d'un objet du coffre part à droite de lui, vers le milieu de
## l'écran.
func _draw_tooltip(item: Item, target_top: float, in_storage := false) -> void:
	if _font == null:
		return
	var lines := ItemTooltip.lines(item, _detailed)
	var size := ItemTooltip.size_of(_font, lines)
	var bounds := _storage_rect() if in_storage else _panel_rect()
	var top := minf(target_top, bounds.end.y - size.y)
	var left := bounds.end.x + TIP_GAP if in_storage else maxf(-size.x - TIP_GAP, -global_position.x)
	ItemTooltip.draw(self, _font, item, lines, Vector2(left, top), bounds)


## `framed` : le cadre d'un objet rangé ; l'objet tenu a déjà sa teinte de destination.
func _draw_item(item: Item, r: Rect2, framed: bool) -> void:
	if framed:
		draw_rect(r, ITEM_BACK if item.rarity() == Item.Rarity.COMMON else item.color().darkened(RARITY_BACK_DIM))
		draw_rect(r, item.color().darkened(ITEM_EDGE_DIM), false, 1.0)

	# L'icône est taillée à l'encombrement de sa famille : un emplacement plus grand la
	# centre sans l'agrandir, ce qui la repixeliserait.
	var own := _span_size(Inventory.footprint(item)).min(_free_cell(r))
	_draw_centered(SpriteForge.inventory_icon(item.base, Vector2i(own)), r)
	# Dans le coin haut-gauche, par-dessus l'icône, comme PoE.
	if item.count > 1 and _font != null:
		draw_string(_font, r.position + Vector2(2.0, FONT_SIZE), str(item.count),
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, ItemTooltip.VALUE)
