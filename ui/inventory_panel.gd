class_name InventoryPanel
extends Control

## Le sac, à la touche I : une grille rectangulaire où chaque objet occupe la
## place qu'il prend réellement, et où on range à la souris.
##
## Clic gauche pour prendre un objet, clic gauche pour le reposer — un objet
## suivi par le curseur, et non un glisser maintenu : à la souris comme à la
## manette, relâcher au mauvais moment fait tomber la pièce, et on tient parfois
## un objet pendant plusieurs secondes le temps de faire de la place.
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
const FOOTER := 12.0
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

var _inventory: Inventory

## L'objet tenu à la main, sorti du sac tant qu'on ne l'a pas reposé.
var _held: Item
## Sa case d'origine, pour le rendre là où on l'a pris si on referme le sac.
var _from := Vector2i.ZERO
## Quelle case de l'objet le curseur avait attrapée : sans elle, un plastron
## saisi par son coin bas-droit sauterait sous le curseur au moment de la prise.
var _grab := Vector2i.ZERO
var _hover := Vector2i(-1, -1)


func _ready() -> void:
	visible = false


## Le sac ouvert prend la souris. Le drapeau doit retomber quoi qu'il arrive —
## y compris si la zone est rechargée sac ouvert, sinon le joueur se retrouve
## incapable de frapper dans une scène où plus aucun panneau n'existe.
func _exit_tree() -> void:
	if visible:
		Game.ui_grabs_input = false


func bind(player: Player) -> void:
	_inventory = player.inventory
	_inventory.changed.connect(_on_changed)

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
		_hover = _cell_at(get_local_mouse_position())
	else:
		var left := _return_held()
		if left != null:
			drop_requested.emit(left)
	_on_changed()


func _input(event: InputEvent) -> void:
	if not visible or _inventory == null:
		return

	if event is InputEventMouseMotion:
		var cell := _cell_at(get_local_mouse_position())
		if cell != _hover:
			_hover = cell
			queue_redraw()
		return

	var button := event as InputEventMouseButton
	if button == null or not button.pressed:
		return

	match button.button_index:
		MOUSE_BUTTON_LEFT:
			_click(_cell_at(get_local_mouse_position()))
		MOUSE_BUTTON_RIGHT:
			if _held == null:
				return
			drop_requested.emit(_held)
			_held = null
			queue_redraw()
		_:
			return

	get_viewport().set_input_as_handled()


## Prendre, ou reposer. Un clic dans le vide en tenant un objet ne fait rien :
## on garde l'objet en main plutôt que de le lâcher au hasard.
func _click(cell: Vector2i) -> void:
	if _held == null:
		var index := _inventory.index_at(cell)
		if index == Inventory.EMPTY:
			return
		_from = _inventory.placed[index].cell
		_grab = cell - _from
		_held = _inventory.take_at(cell)
	elif _inventory.place(_held, cell - _grab):
		_held = null
	queue_redraw()


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
		HEADER + _inventory.rows * (CELL + PAD) + PAD + FOOTER
	)


## Le coin haut-gauche d'un rectangle de cases, en pixels du panneau.
func _rect_of(cell: Vector2i, span: Vector2i) -> Rect2:
	return Rect2(
		Vector2(PAD + cell.x * (CELL + PAD), HEADER + PAD + cell.y * (CELL + PAD)),
		Vector2(span) * (CELL + PAD) - Vector2(PAD, PAD)
	)


## La case sous un point. Peut sortir de la grille — c'est voulu : reposer un
## objet à cheval sur le bord doit échouer, pas être rattrapé en douce vers
## l'intérieur.
func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i(
		floori((point.x - PAD) / (CELL + PAD)),
		floori((point.y - HEADER - PAD) / (CELL + PAD))
	)


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

	var survole := _inventory.index_at(_hover) if _held == null else Inventory.EMPTY
	for p in _inventory.placed:
		_draw_item(p.data, p.cell, true)
	if survole != Inventory.EMPTY:
		var vise: Inventory.Placed = _inventory.placed[survole]
		# Le cadre de l'objet survolé passe à sa couleur de rareté pleine, au lieu
		# d'un gris de survol qui l'effacerait justement sur les objets rares.
		draw_rect(_rect_of(vise.cell, vise.rect().size), vise.data.color(), false, 1.0)
		_draw_tooltip(vise.data, vise.cell)

	if _held != null:
		# L'objet tenu se cale sur la grille au lieu de flotter librement : dans
		# un rangement en rectangles, ce qu'on a besoin de voir c'est la place
		# qu'il prendrait, pas où est le curseur.
		var at := _hover - _grab
		var span := Inventory.footprint(_held)
		draw_rect(_rect_of(at, span), CAN_PLACE if _inventory.fits(_held, at) else BLOCKED)
		_draw_item(_held, at, false)

	var font := get_theme_default_font()
	if font != null:
		draw_string(
			font, Vector2(4.0, s.y - 3.0), "[clic] prendre / poser    [clic droit] jeter",
			HORIZONTAL_ALIGNMENT_LEFT, -1.0, FONT_SIZE, HINT
		)


## Ce que porte l'objet, à côté du sac. Sans elle, un objet à six affixes et une
## épée nue se ressemblent : c'est la seule fenêtre par laquelle le tirage
## devient visible.
func _draw_tooltip(item: Item, cell: Vector2i) -> void:
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
	var haut := minf(_rect_of(cell, Vector2i.ONE).position.y, s.y - h)
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
func _draw_item(item: Item, cell: Vector2i, framed: bool) -> void:
	var r := _rect_of(cell, Inventory.footprint(item))
	if framed:
		draw_rect(r, ITEM_BACK)
		draw_rect(r, item.color().darkened(ITEM_EDGE_DIM), false, 1.0)

	var tex := SpriteForge.inventory_icon(item.base.kind, Vector2i(r.size) - Vector2i(MARGIN, MARGIN) * 2)
	# Position entière : une icône à cheval sur deux pixels bave, et c'est
	# précisément ce que le rendu pixel art ne pardonne pas.
	draw_texture(tex, (r.position + (r.size - tex.get_size()) * 0.5).round())
