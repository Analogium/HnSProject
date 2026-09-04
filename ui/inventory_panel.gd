class_name InventoryPanel
extends Control

## Le sac, à la touche I : une grille rectangulaire où chaque objet occupe la
## place qu'il prend réellement, et où on range à la souris.
##
## Deux gestes pour une seule mécanique, et ils se distinguent tout seuls :
## **glisser** (presser, déplacer, relâcher sur la cible) et **clic-clic**
## (cliquer pour prendre, l'objet suit le curseur, cliquer pour poser). Un
## relâchement qui n'a pas bougé de plus de quelques pixels est un clic, pas la
## fin d'un glisser — c'est la seule règle qui les sépare, et elle évite de
## choisir à la place du joueur.
##
## Relâché **hors du panneau**, l'objet tombe au sol. Relâché sur un emplacement
## d'équipement, il est porté, à condition que ce soit le bon emplacement.
##
## Le clic droit reste le raccourci : équiper depuis le sac, retirer depuis
## l'emplacement, jeter ce qu'on tient.
##
## Il ne détient rien : le sac vit sur le joueur, ce panneau le lit et le
## manipule. Deux listes à tenir d'accord finissent toujours par diverger.

## Ce qu'on jette du sac. Un signal plutôt qu'une référence au monde : le
## panneau vit dans une CanvasLayer et n'a aucune raison de savoir où poser des
## nœuds — c'est la scène qui sait.
signal drop_requested(item: Item)

const CELL := 20.0
const PAD := 1.0
const HEADER := 16.0
## Deux lignes d'aide : les gestes sont maintenant trop nombreux pour tenir sur
## la largeur du panneau.
const FOOTER := 22.0
## Les emplacements d'équipement, au-dessus du sac. Deux colonnes sur trois
## lignes chacun — la taille du plus gros objet équipable, pour que l'icône y
## tienne quel que soit l'emplacement.
const EQUIP_SPAN := Vector2i(2, 3)
const EQUIP_GAP := 12.0
const EQUIP_LABEL := Color(0.42, 0.40, 0.50)
## Marge autour d'une icône dans son emplacement. Sans elle, un objet qui remplit
## exactement son rectangle mange les lignes de la grille et on ne voit plus où
## il commence.
const MARGIN := 3

const BACK := Color(0.082, 0.075, 0.106, 0.97)
const BORDER := Color(0.29, 0.27, 0.35)
const SLOT := Color(0.14, 0.13, 0.17)
const SLOT_EDGE := Color(0.22, 0.20, 0.26)
## Fond des cases occupées : c'est lui qui donne la forme de l'objet d'un coup
## d'œil, avant même que l'icône soit lue.
const ITEM_BACK := Color(0.22, 0.21, 0.28)
## Le cadre d'un objet rangé prend sa couleur de rareté, assombrie pour ne pas
## crier : le sac se lit alors d'un coup d'œil, sans survoler case par case.
const ITEM_EDGE_DIM := 0.3
## Distance à partir de laquelle un relâchement est la fin d'un glisser et non
## un clic. Quelques pixels suffisent : c'est le tremblement de la main qu'on
## veut ignorer, pas un déplacement.
const DRAG_MIN := 5.0
const CAN_PLACE := Color(0.35, 0.85, 0.45, 0.28)
const BLOCKED := Color(0.90, 0.30, 0.28, 0.28)
const HINT := Color(0.52, 0.50, 0.60)
## L'infobulle. Le cadre prend la couleur de rareté de l'objet : c'est la même
## information que le halo au sol, donc la même couleur, et on n'apprend pas
## deux codes pour une seule idée.
const TIP_BACK := Color(0.055, 0.051, 0.075, 0.98)
const TIP_IMPLICIT := Color(0.62, 0.60, 0.68)
const TIP_EXPLICIT := Color(0.55, 0.75, 1.0)
const TIP_PAD := 5.0
const TIP_LINE := 9.0
## Écart entre le sac et son infobulle : collée, on ne sait plus laquelle des
## deux bordures appartient à quoi.
const TIP_GAP := 5.0
const TIP_MIN_W := 74.0
const FONT_SIZE := 8
const TITLE_SIZE := 9

@onready var title: Label = $Title

var _player: Player
var _inventory: Inventory

## L'objet tenu à la main, sorti du sac tant qu'on ne l'a pas reposé.
var _held: Item
## Sa case d'origine, pour le rendre là où on l'a pris si on referme le sac.
var _from := Vector2i.ZERO
## Quelle case de l'objet le curseur avait attrapée : sans elle, un plastron
## saisi par son coin bas-droit sauterait sous le curseur au moment de la prise.
var _grab := Vector2i.ZERO
## Le même décalage en pixels. La case sert à viser, les pixels à dessiner :
## l'objet suit le curseur au pixel près, seule sa destination s'aligne.
var _grab_px := Vector2.ZERO
## Dernière position connue de la souris, dans le repère du panneau.
var _mouse := Vector2.ZERO
## Où le bouton a été pressé, pour distinguer le glisser du clic.
var _press := Vector2.ZERO
var _hover := Vector2i(-1, -1)
## L'emplacement d'équipement survolé, ou -1. Séparé de la case survolée : les
## deux zones ne se recouvrent pas, mais un même Vector2i ne peut pas désigner
## à la fois « case (2,1) du sac » et « emplacement torse ».
var _hover_slot := -1


func _ready() -> void:
	visible = false


## Le sac ouvert prend la souris. Le drapeau doit retomber quoi qu'il arrive —
## y compris si la zone est rechargée sac ouvert, sinon le joueur se retrouve
## incapable de frapper dans une scène où plus aucun panneau n'existe.
func _exit_tree() -> void:
	if visible:
		Game.ui_grabs_input = false


func bind(player: Player) -> void:
	_player = player
	_inventory = player.inventory
	_inventory.changed.connect(_on_changed)
	player.equipment_changed.connect(_on_changed)

	# La taille se déduit de la grille au lieu d'être réglée dans la scène :
	# changer le nombre de colonnes du sac ne doit pas demander de rouvrir
	# l'éditeur. Le coin bas-droite, lui, reste celui posé par les ancres.
	var s := _panel_size()
	offset_left = offset_right - s.x
	offset_top = offset_bottom - s.y
	title.offset_right = s.x - 4.0

	_on_changed()


func toggle() -> void:
	visible = not visible
	Game.ui_grabs_input = visible
	if visible:
		# Sans ça, la case survolée reste celle d'avant la fermeture jusqu'au
		# premier mouvement de souris.
		_track(get_local_mouse_position())
	else:
		var left := _return_held()
		if left != null:
			drop_requested.emit(left)
	_on_changed()


func _input(event: InputEvent) -> void:
	if not visible or _inventory == null:
		return

	# La position vient de l'événement et non du curseur : c'est elle qui est
	# vraie au moment du clic, elle se convertit dans le repère du panneau par
	# make_input_local, et elle rend le geste rejouable dans un test sans avoir
	# à déplacer la souris de l'écran.
	var souris := make_input_local(event) as InputEventMouse
	if souris == null:
		return

	if souris is InputEventMouseMotion:
		_track(souris.position)
		return

	var button := souris as InputEventMouseButton
	if not button.pressed:
		if button.button_index == MOUSE_BUTTON_LEFT:
			_track(button.position)
			_release(button.position)
			get_viewport().set_input_as_handled()
		return

	# Le survol est recalé sur le clic : ouvrir le sac au clavier puis cliquer
	# sans bouger la souris ne doit pas viser la case d'avant.
	_track(button.position)

	match button.button_index:
		MOUSE_BUTTON_LEFT:
			_press = button.position
			# Presser en tenant quelque chose, c'est poser : le clic-clic se
			# résout ici, le glisser au relâchement.
			if _held != null:
				_resolve(button.position, false)
			else:
				_take(button.position)
		MOUSE_BUTTON_RIGHT:
			_right_click()
		_:
			return

	get_viewport().set_input_as_handled()


## Relâcher ne fait quelque chose que si la souris a bougé depuis la pression :
## sinon c'était un clic, et l'objet reste au curseur jusqu'au clic suivant.
func _release(point: Vector2) -> void:
	if _held == null or point.distance_to(_press) < DRAG_MIN:
		return
	_resolve(point, true)


## Ce que la souris survole, sac et emplacements ensemble.
func _track(point: Vector2) -> void:
	var cell := _cell_at(point)
	var slot := _slot_at(point)
	# Un objet en main suit le curseur au pixel : il faut redessiner à chaque
	# mouvement, pas seulement quand on change de case.
	if cell == _hover and slot == _hover_slot and _held == null:
		_mouse = point
		return
	_mouse = point
	_hover = cell
	_hover_slot = slot
	queue_redraw()


## Le clic droit fait trois choses selon ce qu'il vise, et jamais deux à la
## fois : jeter ce qu'on tient, retirer ce qui est porté, équiper ce qu'on
## survole dans le sac.
func _right_click() -> void:
	if _held != null:
		drop_requested.emit(_held)
		_held = null
		queue_redraw()
		return
	if _player == null:
		return
	if _hover_slot >= 0:
		_unequip(Player.SLOTS[_hover_slot])
	else:
		_equip(_hover)


## Équipe l'objet du sac. Il est **sorti du sac d'abord** : c'est ce qui garantit
## que l'objet remplacé trouve au moins sa place, et la grille rejette de toute
## façon un objet qui ne rentre pas. Ce qui déborde vraiment tombe au sol,
## plutôt que d'annuler l'échange — on a demandé à porter cet objet.
func _equip(cell: Vector2i) -> void:
	var index := _inventory.index_at(cell)
	if index == Inventory.EMPTY:
		return
	var origine: Vector2i = _inventory.placed[index].cell
	var item := _inventory.take_at(cell)
	var ancien := _player.equip(item)
	if ancien == item:
		# Rien à quoi l'attacher : il retourne exactement d'où il vient.
		_inventory.place(item, origine)
		return
	if ancien != null and not _inventory.add(ancien):
		drop_requested.emit(ancien)
	queue_redraw()


func _unequip(slot: String) -> void:
	var item := _player.unequip(slot)
	if item != null and not _inventory.add(item):
		drop_requested.emit(item)
	queue_redraw()


## Prendre en main ce qui est sous le curseur : un objet du sac, ou celui d'un
## emplacement porté. Un clic dans le vide ne fait rien.
func _take(point: Vector2) -> void:
	var slot := _slot_at(point)
	if slot >= 0:
		var porte: Item = _player.equipped(Player.SLOTS[slot]) if _player != null else null
		if porte == null:
			return
		_player.unequip(Player.SLOTS[slot])
		_held = porte
		# Rien à quoi le rendre : la case d'origine est volontairement hors
		# grille, `place` la refusera et `_return_held` cherchera une place.
		_from = Vector2i(-1, -1)
		_grab = Inventory.footprint(porte) / 2
		_grab_px = _span_size(Inventory.footprint(porte)) * 0.5
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


## Poser ce qu'on tient, là où le curseur le demande : dans un emplacement, dans
## le sac, ou au sol si on est sorti du panneau.
##
## `drag` dit ce qu'il faut faire d'un geste qui échoue. Au clic, l'objet reste
## en main — on garde la main levée plutôt que de le lâcher au hasard. Au
## relâchement, non : le joueur a lâché le bouton, l'objet ne peut pas rester
## collé au curseur, il retourne donc au sac.
func _resolve(point: Vector2, drag: bool) -> void:
	if _held == null:
		return

	var slot := _slot_at(point)
	if slot >= 0:
		if _equip_held(Player.SLOTS[slot]):
			queue_redraw()
			return
	elif not Rect2(Vector2.ZERO, _panel_size()).has_point(point):
		# Hors du panneau : au sol. C'est le seul moyen de se débarrasser d'un
		# objet, et il se lit tout seul — on l'a sorti du sac.
		drop_requested.emit(_held)
		_held = null
		queue_redraw()
		return
	elif _inventory.place(_held, _cell_at(point) - _grab):
		_held = null
		queue_redraw()
		return

	if drag:
		var reste := _return_held()
		if reste != null:
			drop_requested.emit(reste)
	queue_redraw()


## Porte l'objet tenu, si c'est bien son emplacement. Une épée déposée sur le
## torse est refusée plutôt que rangée d'office dans l'emplacement d'arme : le
## joueur a visé, on ne décide pas à sa place.
func _equip_held(slot: String) -> bool:
	if _player == null or _held.base == null or _held.base.slot != slot:
		return false
	var ancien := _player.equip(_held)
	if ancien == _held:
		return false
	_held = null
	if ancien != null and not _inventory.add(ancien):
		drop_requested.emit(ancien)
	return true


## Rend au sac l'objet tenu à la main, à sa place d'origine si elle est encore
## libre. Renvoie ce qui n'a pas pu rentrer : le sac a pu se remplir pendant
## qu'on le tenait, et un objet ne doit jamais disparaître entre deux mains.
func _return_held() -> Item:
	if _held == null:
		return null
	var item := _held
	_held = null
	if _inventory.place(item, _from) or _inventory.add(item):
		return null
	return item


func _on_changed() -> void:
	if _inventory != null:
		title.text = "SAC  %d / %d cases" % [_inventory.used_cells(), _inventory.cell_count()]
	if visible:
		queue_redraw()


func _panel_size() -> Vector2:
	return Vector2(
		_inventory.cols * (CELL + PAD) + PAD,
		_grid_top() + _inventory.rows * (CELL + PAD) + PAD + FOOTER
	)


## Un rectangle de cases, en pixels — la mesure de base de tout le panneau.
func _span_size(span: Vector2i) -> Vector2:
	return Vector2(span) * (CELL + PAD) - Vector2(PAD, PAD)


func _slot_rect(index: int) -> Rect2:
	var sz := _span_size(EQUIP_SPAN)
	return Rect2(Vector2(PAD + float(index) * (sz.x + EQUIP_GAP), HEADER + PAD), sz)


## Où commence le sac : sous la bande d'équipement.
func _grid_top() -> float:
	return HEADER + _span_size(EQUIP_SPAN).y + PAD + 6.0


## Le coin haut-gauche d'un rectangle de cases du sac, en pixels du panneau.
func _rect_of(cell: Vector2i, span: Vector2i) -> Rect2:
	return Rect2(
		Vector2(PAD + cell.x * (CELL + PAD), _grid_top() + PAD + cell.y * (CELL + PAD)),
		_span_size(span)
	)


## La case sous un point. Peut sortir de la grille — c'est voulu : reposer un
## objet à cheval sur le bord doit échouer, pas être rattrapé en douce vers
## l'intérieur.
func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i(
		floori((point.x - PAD) / (CELL + PAD)),
		floori((point.y - _grid_top() - PAD) / (CELL + PAD))
	)


func _slot_at(point: Vector2) -> int:
	for i in Player.SLOTS.size():
		if _slot_rect(i).has_point(point):
			return i
	return -1


func _draw() -> void:
	if _inventory == null:
		return

	var s := _panel_size()
	draw_rect(Rect2(Vector2.ZERO, s), BACK)
	draw_rect(Rect2(Vector2.ZERO, s), BORDER, false, 1.0)

	for y in _inventory.rows:
		for x in _inventory.cols:
			var r := _rect_of(Vector2i(x, y), Vector2i.ONE)
			draw_rect(r, SLOT)
			draw_rect(r, SLOT_EDGE, false, 1.0)

	_draw_equipment()

	var survole := _inventory.index_at(_hover) if _held == null else Inventory.EMPTY
	for p in _inventory.placed:
		_draw_item(p.data, _rect_of(p.cell, p.rect().size), true)
	if survole != Inventory.EMPTY:
		var vise: Inventory.Placed = _inventory.placed[survole]
		var r := _rect_of(vise.cell, vise.rect().size)
		# Le cadre de l'objet survolé passe à sa couleur de rareté pleine, au lieu
		# d'un gris de survol qui l'effacerait justement sur les objets rares.
		draw_rect(r, vise.data.color(), false, 1.0)
		_draw_tooltip(vise.data, r.position.y)

	if _held != null:
		var span := Inventory.footprint(_held)
		var at := _hover - _grab
		# Deux choses à montrer, et il en faut deux : la **destination** calée
		# sur la grille, verte ou rouge — dans un rangement en rectangles c'est
		# la place qu'il prendrait qui compte — et l'**objet**, qui suit le
		# curseur au pixel près pour qu'on sente qu'on le tient.
		if _hover_slot < 0 and Rect2(Vector2.ZERO, s).has_point(_mouse):
			draw_rect(_rect_of(at, span), CAN_PLACE if _inventory.fits(_held, at) else BLOCKED)
		_draw_item(_held, Rect2(_mouse - _grab_px, _span_size(span)), false)

	var font := get_theme_default_font()
	if font != null:
		draw_string(font, Vector2(4.0, s.y - 13.0),
			"[clic] prendre et poser     [clic droit] équiper / retirer",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, HINT)
		draw_string(font, Vector2(4.0, s.y - 3.0),
			"lâché hors du sac : jeté au sol",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, HINT)


## Les emplacements portés. Ils sont dans le même panneau que le sac et non dans
## une fenêtre à part : équiper est un geste entre les deux, et deux fenêtres
## obligeraient à en ouvrir une seconde pour un aller-retour.
func _draw_equipment() -> void:
	var font := get_theme_default_font()
	for i in Player.SLOTS.size():
		var slot: String = Player.SLOTS[i]
		var r := _slot_rect(i)
		draw_rect(r, SLOT)
		var item: Item = _player.equipped(slot) if _player != null else null

		# La teinte du survol se pose **après** l'objet déjà porté : peinte
		# avant, le fond opaque de cet objet l'effaçait, et un emplacement
		# occupé n'annonçait jamais s'il accepte ce qu'on lui apporte.
		if _held != null and _hover_slot == i:
			var bon: bool = _held.base != null and _held.base.slot == slot
			if item != null:
				_draw_item(item, r, true)
			draw_rect(r, CAN_PLACE if bon else BLOCKED)
			draw_rect(r, (CAN_PLACE if bon else BLOCKED) * Color(1, 1, 1, 3.0), false, 1.0)
			continue

		if item == null:
			draw_rect(r, SLOT_EDGE, false, 1.0)
			if font != null:
				# Le nom de l'emplacement ne s'affiche que vide : une fois
				# rempli, l'icône dit déjà de quoi il s'agit.
				var nom: String = Player.SLOT_NAMES[slot]
				var w := font.get_string_size(nom, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x
				draw_string(font, Vector2(r.get_center().x - w * 0.5, r.get_center().y + 3.0),
					nom, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, EQUIP_LABEL)
			continue

		_draw_item(item, r, true)
		if _hover_slot == i and _held == null:
			draw_rect(r, item.color(), false, 1.0)
			_draw_tooltip(item, r.position.y)


## Ce que porte l'objet, à côté du sac. Sans elle, un objet à six affixes et une
## épée nue se ressemblent : c'est la seule fenêtre par laquelle le tirage
## devient visible.
func _draw_tooltip(item: Item, haut_vise: float) -> void:
	var font := get_theme_default_font()
	if font == null:
		return

	var titre := item.display_name()
	var implicite := item.implicit_line()
	var explicites := item.explicit_lines()

	var w := maxf(TIP_MIN_W, font.get_string_size(
		titre, HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_SIZE).x)
	for ligne in explicites:
		w = maxf(w, font.get_string_size(ligne, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	if not implicite.is_empty():
		w = maxf(w, font.get_string_size(implicite, HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE).x)
	w += TIP_PAD * 2.0

	var n := explicites.size() + (1 if not implicite.is_empty() else 0)
	var h := TIP_PAD * 2.0 + TIP_LINE + float(n) * TIP_LINE
	# Le trait de séparation, quand il y a les deux sortes de lignes à séparer.
	var separe := not implicite.is_empty() and not explicites.is_empty()
	if separe:
		h += TIP_LINE * 0.5

	# Alignée sur le haut de l'objet, mais jamais débordante vers le bas : les
	# objets de la dernière ligne sont ceux dont l'infobulle est la plus longue
	# à sortir de l'écran.
	var s := _panel_size()
	var haut := minf(haut_vise, s.y - h)
	var r := Rect2(Vector2(-w - TIP_GAP, haut), Vector2(w, h))

	draw_rect(r, TIP_BACK)
	draw_rect(r, item.color(), false, 1.0)

	var y := r.position.y + TIP_PAD + TIP_LINE - 2.0
	draw_string(font, Vector2(r.position.x + TIP_PAD, y), titre,
		HORIZONTAL_ALIGNMENT_LEFT, -1.0, TITLE_SIZE, item.color())
	if not implicite.is_empty():
		y += TIP_LINE
		draw_string(font, Vector2(r.position.x + TIP_PAD, y), implicite,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_IMPLICIT)
	if separe:
		# Ce que la base garantit au-dessus du trait, ce que le tirage a donné
		# en dessous. Sans lui, les deux se lisent comme une seule liste et
		# l'implicite passe pour un affixe de plus.
		y += TIP_LINE * 0.5
		draw_line(
			Vector2(r.position.x + TIP_PAD, y - 2.0),
			Vector2(r.end.x - TIP_PAD, y - 2.0),
			TIP_IMPLICIT * Color(1.0, 1.0, 1.0, 0.5), 1.0
		)
	for ligne in explicites:
		y += TIP_LINE
		draw_string(font, Vector2(r.position.x + TIP_PAD, y), ligne,
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, TIP_EXPLICIT)


## framed : le cadre de l'objet rangé. L'objet tenu à la main s'en passe — il
## est déjà posé sur la teinte verte ou rouge qui dit s'il peut tomber là.
func _draw_item(item: Item, r: Rect2, framed: bool) -> void:
	if framed:
		draw_rect(r, ITEM_BACK)
		draw_rect(r, item.color().darkened(ITEM_EDGE_DIM), false, 1.0)

	# L'icône est dimensionnée sur l'encombrement de l'objet et non sur le
	# rectangle qui l'accueille : un emplacement d'équipement est plus large que
	# la plupart des objets, et une épée n'a pas à y tripler de taille.
	var propre := _span_size(Inventory.footprint(item)) - Vector2(MARGIN, MARGIN) * 2.0
	var tex := SpriteForge.inventory_icon(item.base.kind, Vector2i(propre))
	# Position entière : une icône à cheval sur deux pixels bave, et c'est
	# précisément ce que le rendu pixel art ne pardonne pas.
	draw_texture(tex, (r.position + (r.size - tex.get_size()) * 0.5).round())
