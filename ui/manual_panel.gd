class_name ManualPanel
extends Control

## Le râtelier et la page du manuel choisi (M) : les trois dos en haut, la page
## dessous. **On n'investit que d'ici**, donc dans un livre étudié : équiper est
## l'engagement. Deux vues de même taille, la grille et l'arbre d'une compétence.

## Ce qu'on jette faute de place, comme le sac : c'est la zone qui le pose au sol.
signal drop_requested(item: Item)

const PAD := 6.0
const HEADER := 15.0
const SLOT := 40.0
const SLOT_GAP := 6.0
const FONT_SIZE := 8
const TITLE_SIZE := 9
const LINE := 10.0

## La barre d'expérience du livre, en haut de sa page.
const XP_H := 5.0

## Une case : de quoi écrire « 3/5 » et garder un liseré lisible.
const CELL := 34.0
const CELL_GAP := 6.0

## Un nœud, plus petit qu'une case, et l'écart où passent les liens. Trois colonnes
## sur deux rangées à droite de la racine.
const NODE := 28.0
const NODE_GAP := 16.0

## Les états d'une case, lus au liseré **sans lire** le texte. Verrouillée : le
## niveau du livre n'y donne pas encore droit.
const LOCK := Color(0.26, 0.24, 0.31)
## Ouverte, et il reste un point à y mettre : le vert des points à placer.
const OPEN := UiPalette.TO_SPEND
## Pleine : l'or, « ça compte plus ».
const FULL := Color(0.95, 0.82, 0.30)
## Ouverte mais sans point disponible : ni promesse, ni interdit.
const WAIT := Color(0.55, 0.53, 0.64)

const CELL_BACKGROUND := Color(0.14, 0.13, 0.18, 0.9)
const XP_BACKGROUND := Color(0.10, 0.09, 0.13)
## Le bleu de l'expérience du joueur : un livre progresse comme son porteur.
const XP_FULL := Hud.FILL
## Mots-clés en bleu acier : dans la couleur d'une nature, « Foudre » se lirait comme
## un type de dégâts.
const KEYWORD := Color(0.62, 0.72, 0.88)

## Le lien entre deux nœuds, allumé quand la branche est prise.
const LINK := Color(0.24, 0.23, 0.29)
const LINK_BRIGHT := Color(0.52, 0.62, 0.55)

## Les pans coupés d'un passif : la forme dit « toujours actif ».
const PAN := 7.0

## La fiche de survol : assez large pour « par projectile   123–456 », pas plus — elle
## couvre le sac.
const SHEET_W := 170.0
const SHEET_PAD := 6.0
const SHEET_GAP := 4.0
## Le nom et les mots-clés, au-dessus des lignes.
## La hauteur d'une ligne de fiche, **plus serrée que celle de la page** : la fiche la
## plus chargée du jeu tient tout juste au-dessus des jauges, et c'est ce pixel par
## ligne qui lui laisse son paragraphe.
const SHEET_LINE := 9.0
## Une ligne de paragraphe, plus serrée encore : de la prose, pas un tableau de valeurs.
const SHEET_PROSE := 8.0
const SHEET_HEADER := SHEET_LINE * 2.0
## Le filet entre deux groupes. Serré, comme tout le reste de la fiche : la plus haute
## du jeu — le nuage — tient à trois pixels près au-dessus des jauges.
const SHEET_SEPARATION := 4.0
## Ce qu'un titre de groupe prend en plus du filet. Moins qu'une ligne pleine : la fiche
## la plus chargée du jeu tient tout juste au-dessus des jauges, et cinq titres y
## coûteraient une case de contenu.
const TITLE_BAND := 7.0
## Ce qui manque pour ouvrir : « pas encore », pas une erreur.
const MISSING := Color(0.92, 0.50, 0.44)
## Le paragraphe de description : plus chaud que les intitulés, plus éteint que les
## valeurs. Il se lit une fois, les nombres se relisent.
const DESCRIPTION := Color(0.80, 0.75, 0.66)

## Les groupes de la fiche, dans l'ordre des questions. `EFFECT` : passif et nœud, qui
## n'ont ni coût ni portée.
enum Group { STATE, EFFECT, COST, DAMAGE, SHAPE, ESTIMATE, BUFF }

## Le titre que porte le filet d'un groupe. La fiche se lit alors par blocs — ce qu'elle
## coûte, ce qu'elle inflige, ce qu'elle pose — au lieu d'une liste d'une vingtaine de
## lignes. **Le premier groupe n'en a pas** : il suit l'en-tête, qui le dit déjà.
const GROUP_TITLES := {
	Group.EFFECT: "Effets",
	Group.COST: "Lancer",
	Group.DAMAGE: "Dégâts",
	Group.SHAPE: "Forme",
	# Ce que les moyennes supposent se dit dans leur titre : en note sous elles, c'était
	# une ligne de plus dans la fiche la plus haute du jeu.
	Group.ESTIMATE: "En moyenne, si tout touche",
}


## Une ligne de fiche : intitulé à gauche, valeur à droite dans sa couleur.
class SheetLine:
	var group: int
	var label_of: String
	var value: String
	var tint: Color
	## Le titre du bloc, quand il ne vient pas de `GROUP_TITLES` : le nom d'un buff.
	## **Porté par chaque ligne du bloc**, c'est lui qui les tient ensemble.
	var heading: String

	## La majuscule est posée **ici et pas au dessin** : c'est ce que les tests de
	## largeur mesurent, et deux capitalisations divergeraient d'une lettre.
	func _init(
		p_group: int, p_label: String, p_value: String, p_tint: Color, p_heading := ""
	) -> void:
		group = p_group
		label_of = RichText.capitalized(p_label)
		value = p_value
		tint = p_tint
		heading = p_heading


## Une fiche de survol entière, décidée **à un seul endroit** : sous-titre et lignes
## ne peuvent pas se contredire.
class Sheet:
	var title_text: String
	## Sous le nom, la sorte : mots-clés, « toujours actif » ou « talent ».
	var subtitle: String
	## Ce que le geste fait, en une phrase, avant les nombres. Vide pour un passif et
	## pour un nœud, dont les lignes **sont** la description.
	var description: String
	var lines: Array[SheetLine]

	func _init(
		p_title: String, p_subtitle: String, p_lines: Array[SheetLine], p_description := ""
	) -> void:
		title_text = p_title
		subtitle = p_subtitle
		description = p_description
		lines = p_lines

var _player: Player
var _font: Font
## L'emplacement ouvert ; zéro, pour montrer quelque chose dès l'ouverture.
var _selected := 0
## La compétence dont l'arbre est ouvert, ou vide pour la grille. Un identifiant :
## `_open_cell()` retombe sur la grille si le livre change.
var _opened := ""
var _hover_slot := -1
var _hover_cell := -1
## Le nœud survolé dans l'arbre ouvert, et le survol de la racine.
var _hover_node := -1
var _hover_root := false
## Pour ne redessiner que quand elle bouge : la page reste ouverte en combat.
var _displayed_exp := -1


func _ready() -> void:
	visible = false
	_font = ThemeDB.fallback_font
	# Au plus proche voisin : lissée, la trame du pixel art tournerait au gris.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Sans garde : effacer une prise absente ne coûte rien, et la condition finissait
## par mentir (voir `Game.grab_ui_input`).
func _exit_tree() -> void:
	Game.grab_ui_input(self, false)


## La page et la fiche sont dessinées à la main : à redessiner.
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func bind(player: Player) -> void:
	_player = player
	queue_redraw()


func toggle() -> void:
	visible = not visible
	Game.grab_ui_input(self, visible)
	if visible:
		_track(get_local_mouse_position())
	queue_redraw()


func _process(_delta: float) -> void:
	if not visible:
		return
	var book := _book()
	var current_exp := book.manual.experience if book != null else -1
	if current_exp != _displayed_exp:
		_displayed_exp = current_exp
		queue_redraw()


func _input(event: InputEvent) -> void:
	if not visible or _player == null:
		return

	# Échap referme l'arbre avant la fenêtre : pris dans `_input`, avant le menu de
	# pause, et seulement quand un arbre est ouvert.
	if Keys.pressed_down(event) == KEY_ESCAPE and _open_cell() != null:
		_opened = ""
		_track(get_local_mouse_position())
		queue_redraw()
		get_viewport().set_input_as_handled()
		return

	# La position de l'événement : vraie au moment du clic, et rejouable dans un test.
	var mouse := make_input_local(event) as InputEventMouse
	if mouse == null:
		return

	if mouse is InputEventMouseMotion:
		_track(mouse.position)
		return

	var button := mouse as InputEventMouseButton
	if not button.pressed:
		return
	if not _owns_click(button.position):
		return
	_track(button.position)

	match button.button_index:
		MOUSE_BUTTON_LEFT:
			_left_click()
		MOUSE_BUTTON_RIGHT:
			_right_click()
		_:
			return

	# Re-survolé : le clic a pu changer de vue.
	_track(button.position)
	queue_redraw()
	get_viewport().set_input_as_handled()


## Sur un dos : ouvrir le livre. Sur la grille : ouvrir l'arbre, ou placer un point
## dans un passif. Dans l'arbre : placer un point.
func _left_click() -> void:
	if _hover_slot >= 0:
		_selected = _hover_slot
		# Le livre change : on revient à sa grille.
		_opened = ""
		return

	var open_cell := _open_cell()
	if open_cell != null:
		if _hover_root:
			_invest(open_cell.skill.id)
		elif _hover_node >= 0 and _hover_node < open_cell.talents.size():
			_invest(open_cell.talents[_hover_node].id)
		return

	var cell := _hovered_cell()
	if cell == null:
		return
	if cell.skill != null:
		_opened = cell.skill.id
	else:
		_invest(cell.passive.id)


## Le pendant du clic gauche : un point de moins là où il en ajoute un. Sur un dos,
## ranger le livre ; dans le vide de l'arbre, revenir à la grille.
func _right_click() -> void:
	if _hover_slot >= 0:
		_store(_hover_slot)
		return
	var open_cell := _open_cell()
	if open_cell == null:
		var cell := _hovered_cell()
		if cell != null:
			_refund(cell.identifier())
		return
	if _hover_root:
		_refund(open_cell.skill.id)
	elif _hover_node >= 0 and _hover_node < open_cell.talents.size():
		_refund(open_cell.talents[_hover_node].id)
	else:
		_opened = ""


## Hors de la fenêtre, le clic reste au panneau voisin.
func _owns_click(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, size).has_point(point)


## Le livre dont la page est ouverte, ou null.
func _book() -> Item:
	return _player.rack.at(_selected) if _player != null else null


## L'archétype ouvert, ou null : les règles refusent alors tout.
func _archetype() -> ManualArchetype:
	var book := _book()
	return book.base.manual if book != null else null


## La case dont l'arbre est ouvert, ou null. **Relue à chaque fois** : le livre a pu
## être rangé ou remplacé, et la vue retombe seule sur la grille.
func _open_cell() -> ManualCell:
	if _opened.is_empty():
		return null
	var book := _book()
	return book.base.manual.cell_of(_opened) if book != null else null


## La case de la grille sous le curseur, ou null.
func _hovered_cell() -> ManualCell:
	var book := _book()
	if book == null or _hover_cell < 0:
		return null
	var cells := book.base.manual.cells
	return cells[_hover_cell] if _hover_cell < cells.size() else null


## Les conditions sont dans `Manual`, le recalcul chez le joueur.
func _invest(identifier: String) -> void:
	if _player != null:
		_player.invest(_selected, identifier)


## Un point de moins ; `Manual` dit quand.
func _refund(identifier: String) -> void:
	if _player != null:
		_player.refund(_selected, identifier)


## Le livre quitte le râtelier et retourne au sac ; s'il n'y tient plus, il tombe.
func _store(index: int) -> void:
	var gone := _player.stop_studying(index)
	if gone != null and not _player.inventory.add(gone):
		drop_requested.emit(gone)


func _track(point: Vector2) -> void:
	var slot := -1
	for i in Rack.SLOT_COUNT:
		if _slot_rect(i).has_point(point):
			slot = i
			break

	var cell := -1
	var node := -1
	var root := false
	var open_cell := _open_cell()
	if open_cell != null:
		root = _root_rect().has_point(point)
		for i in open_cell.talents.size():
			if _node_rect(open_cell.talents[i].position).has_point(point):
				node = i
				break
	else:
		var book := _book()
		if book != null:
			var cells := book.base.manual.cells
			for i in cells.size():
				if _cell_rect(cells[i].position).has_point(point):
					cell = i
					break

	if (
		slot == _hover_slot and cell == _hover_cell
		and node == _hover_node and root == _hover_root
	):
		return
	_hover_slot = slot
	_hover_cell = cell
	_hover_node = node
	_hover_root = root
	queue_redraw()


func _slot_rect(index: int) -> Rect2:
	return Rect2(PAD + float(index) * (SLOT + SLOT_GAP), HEADER, SLOT, SLOT)


## Le haut de la page : sous les trois dos, avec de l'air.
func _page_top() -> float:
	return HEADER + SLOT + PAD * 2.0


## Le haut de la ligne d'aide, borne basse des cases : lu ici par le dessin et le test.
func _help_top() -> float:
	return size.y - LINE - 5.0


## L'origine commune de la grille et de l'arbre, sous l'en-tête.
func _origin() -> Vector2:
	return Vector2(PAD, _page_top() + LINE * 2.0 + XP_H + PAD)


func _cell_rect(position: Vector2i) -> Rect2:
	return Rect2(_origin() + Vector2(position) * (CELL + CELL_GAP), Vector2(CELL, CELL))


## La racine de l'arbre : la case de la compétence, à gauche, centrée sur les deux
## rangées de nœuds.
func _root_rect() -> Rect2:
	var band := NODE * 2.0 + NODE_GAP
	return Rect2(_origin() + Vector2(0.0, (band - CELL) * 0.5), Vector2(CELL, CELL))


func _node_rect(position: Vector2i) -> Rect2:
	var start := _origin() + Vector2(CELL + NODE_GAP + 4.0, 0.0)
	return Rect2(
		start + Vector2(position) * (NODE + NODE_GAP), Vector2(NODE, NODE)
	)


# --------------------------------------------------------------------------


func _draw() -> void:
	if _font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BACK)
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BORDER, false, 1.0)
	_text(Texts.t("MANUELS"), Vector2(PAD, 11.0), TITLE_SIZE, UiPalette.TITLE)

	for i in Rack.SLOT_COUNT:
		_draw_slot(i)

	var book := _book()
	if book == null:
		_text(
			Texts.t("aucun manuel à cet emplacement"), Vector2(PAD, _page_top() + 8.0),
			FONT_SIZE, UiPalette.HINT
		)
		return

	var open_cell := _open_cell()
	var sheet: Sheet = null
	var anchor := Rect2()
	if open_cell == null:
		_draw_header(book, book.base.manual.displayed_name(), book.color())
		for cell in book.base.manual.cells:
			_draw_cell(book.manual, cell, _cell_rect(cell.position), cell == _hovered_cell())
		_text(
			Texts.t("[clic] ouvrir ou +1     [clic droit] -1 ou ranger"),
			Vector2(PAD, _help_top() + LINE), FONT_SIZE, UiPalette.HINT
		)
		var hovered_one := _hovered_cell()
		if hovered_one != null:
			sheet = _cell_sheet(book.manual, hovered_one)
			anchor = _cell_rect(hovered_one.position)
	else:
		# Le chevron dit d'où l'on revient ; le clic droit fait le retour.
		_draw_header(book, "‹ %s" % open_cell.skill.displayed_name(), UiPalette.TEXT)
		_draw_tree(book.manual, book.base.manual, open_cell)
		_text(
			Texts.t("[clic] +1     [clic droit] -1     [échap] retour"),
			Vector2(PAD, _help_top() + LINE), FONT_SIZE, UiPalette.HINT
		)
		if _hover_root:
			sheet = _skill_sheet(book.manual, open_cell.skill)
			anchor = _root_rect()
		elif _hover_node >= 0 and _hover_node < open_cell.talents.size():
			var node := open_cell.talents[_hover_node]
			sheet = _node_sheet(book.manual, open_cell, node)
			anchor = _node_rect(node.position)

	# En dernier : la fiche passe par-dessus tout, le sac compris.
	if sheet != null:
		_draw_sheet(sheet, anchor)


func _draw_slot(index: int) -> void:
	var r := _slot_rect(index)
	draw_rect(r, CELL_BACKGROUND)
	var item := _player.rack.at(index) if _player != null else null
	# Le liseré dit quel livre est ouvert.
	var tint := UiPalette.BORDER
	if index == _selected:
		tint = FULL if item != null else WAIT
	draw_rect(r, tint, false, 1.0)

	if item == null:
		return
	var tex := SpriteForge.inventory_icon(
		item.base, Vector2i(int(SLOT) - 8, int(SLOT) - 8)
	)
	if tex != null:
		var size_value := tex.get_size()
		draw_texture_rect(tex, Rect2(r.position + (r.size - size_value) * 0.5, size_value), false)


## Titre, niveau, points restants et barre d'expérience, **les mêmes dans les deux
## vues** : on doit savoir dans l'arbre si l'on a de quoi payer.
func _draw_header(book: Item, title_text: String, tint: Color) -> void:
	var manual := book.manual
	var y := _page_top() + 8.0
	_text(title_text, Vector2(PAD, y), TITLE_SIZE, tint)

	var remaining_all := manual.remaining_points()
	# Le pluriel par la traduction ; zéro a sa propre phrase.
	var to_spend := Texts.tn(
		"{points} point à placer", "{points} points à placer", remaining_all
	).format({"points": remaining_all})
	_text(
		Texts.t("niveau %d") % manual.level(), Vector2(PAD, y + LINE),
		FONT_SIZE, UiPalette.LABEL
	)
	_text(
		to_spend if remaining_all > 0 else Texts.t("aucun point à placer"),
		Vector2(size.x - PAD - 78.0, y + LINE), FONT_SIZE,
		OPEN if remaining_all > 0 else UiPalette.LABEL
	)

	# Vide au plafond : pas de dénominateur inventé.
	var progress := manual.progress()
	var bar := Rect2(PAD, y + LINE * 1.6, size.x - PAD * 2.0, XP_H)
	draw_rect(bar, XP_BACKGROUND)
	if progress.y > 0:
		var ratio := clampf(float(progress.x) / float(progress.y), 0.0, 1.0)
		draw_rect(Rect2(bar.position, Vector2(bar.size.x * ratio, bar.size.y)), XP_FULL)
	draw_rect(bar, UiPalette.BORDER, false, 1.0)


## Une case ou une racine d'arbre : le rectangle est passé, la même case se dessinant
## à deux endroits.
func _draw_cell(manual: Manual, cell: ManualCell, r: Rect2, hovered_one: bool) -> void:
	var passive := cell.passive
	var identifier := cell.identifier()
	if identifier.is_empty():
		draw_rect(r, CELL_BACKGROUND)
		draw_rect(r, LOCK, false, 1.0)
		return

	var spent := manual.points_of(identifier)
	var maximum := cell.points_max()
	var tint := _tint(manual, cell.required_level() <= manual.level(), spent, maximum)
	var thickness := 2.0 if hovered_one else 1.0

	# Un passif se distingue par ses pans coupés.
	if passive != null:
		draw_colored_polygon(_pans(r), CELL_BACKGROUND)
		draw_polyline(_pans(r, true), tint, thickness)
	else:
		draw_rect(r, CELL_BACKGROUND)

	# L'icône d'abord, le liseré par-dessus : c'est lui qui dit l'état.
	_draw_icon(r, cell, tint == LOCK)
	if passive == null:
		draw_rect(r, tint, false, thickness)
		# Le chevron d'arbre en bas à gauche, à l'opposé du compte.
		if not cell.talents.is_empty():
			_draw_chevron(r.position + Vector2(4.0, r.size.y - 5.0), KEYWORD)

	# Verrouillée, la case annonce « niv. 4 » plutôt que « 0/5 ».
	var label_of := "%d/%d" % [spent, maximum]
	if spent == 0 and tint == LOCK:
		label_of = Texts.t("niv. %d") % cell.required_level()
	# Rentrée dans les pans coupés : au coin, la plaque dépassait (vu sur capture).
	_draw_count(
		r.grow(-PAN * 0.5) if passive != null else r,
		label_of, UiPalette.TEXT if tint != LOCK else UiPalette.LABEL, FONT_SIZE
	)


## Racine, liens puis nœuds : les nœuds couvrent les bouts des liens.
func _draw_tree(manual: Manual, arch: ManualArchetype, cell: ManualCell) -> void:
	var root := _root_rect()
	for node in cell.talents:
		var r := _node_rect(node.position)
		var from_value := root if node.parent.is_empty() else _node_rect(
			cell.node_of(node.parent).position
		)
		# Le lien s'allume quand le nœud porte un point.
		var quick := manual.points_of(node.id) > 0
		draw_line(
			Vector2(from_value.end.x, from_value.get_center().y),
			Vector2(r.position.x, r.get_center().y),
			LINK_BRIGHT if quick else LINK, 1.0
		)

	_draw_cell(manual, cell, root, _hover_root)
	for i in cell.talents.size():
		_draw_node(manual, arch, cell.talents[i], i == _hover_node)


func _draw_node(
	manual: Manual, arch: ManualArchetype, node: TalentNode, hovered: bool
) -> void:
	var r := _node_rect(node.position)
	var spent := manual.points_of(node.id)
	var tint := _tint(manual, manual.is_open(arch, node.id), spent, node.points_max)
	draw_rect(r, CELL_BACKGROUND)
	draw_rect(r, tint, false, 2.0 if hovered else 1.0)

	# Pastille de la nature d'arrivée d'une conversion : seul effet lisible en couleur.
	if node.converts():
		draw_circle(r.position + Vector2(5.0, 5.0), 2.0, DamageType.COLORS[node.converts_to])

	_draw_count(
		r, "%d/%d" % [spent, node.points_max],
		UiPalette.TEXT if tint != LOCK else UiPalette.LABEL, FONT_SIZE
	)


## **Le seul endroit** qui traduit un état en couleur, cases et nœuds.
func _tint(manual: Manual, opened: bool, spent: int, maximum: int) -> Color:
	if spent >= maximum:
		return FULL
	if not opened:
		return LOCK
	return OPEN if manual.remaining_points() > 0 else WAIT


## `loop` ferme le contour.
static func _pans(r: Rect2, loop := false) -> PackedVector2Array:
	var pts := PackedVector2Array([
		Vector2(r.position.x + PAN, r.position.y),
		Vector2(r.end.x - PAN, r.position.y),
		Vector2(r.end.x, r.position.y + PAN),
		Vector2(r.end.x, r.end.y - PAN),
		Vector2(r.end.x - PAN, r.end.y),
		Vector2(r.position.x + PAN, r.end.y),
		Vector2(r.position.x, r.end.y - PAN),
		Vector2(r.position.x, r.position.y + PAN),
	])
	if loop:
		pts.append(pts[0])
	return pts


static func _chevron(at: Vector2) -> PackedVector2Array:
	return PackedVector2Array([
		at + Vector2(0.0, -2.5), at + Vector2(2.0, 0.0), at + Vector2(0.0, 2.5)
	])


func _draw_chevron(at: Vector2, tint: Color) -> void:
	draw_polyline(_chevron(at), tint, 1.0)


## L'icône, **assombrie tant qu'elle est verrouillée** ; sans image, la case reste
## utilisable.
func _draw_icon(r: Rect2, cell: ManualCell, locked: bool) -> void:
	var tex := SkillIcon.texture(cell.skill)
	if tex == null and cell.passive != null:
		tex = SkillIcon.from_value(cell.passive.id, cell.passive.icon)
	if tex == null:
		return
	var size_value := tex.get_size() * float(SkillIcon.factor(tex, r.size.x))
	draw_texture_rect(
		tex, Rect2(r.position + (r.size - size_value) * 0.5, size_value), false,
		Color(0.42, 0.40, 0.48) if locked else Color.WHITE
	)


## Le compte, **en bas à droite sur une plaque sombre** : lisible quel que soit le
## dessin derrière.
func _draw_count(r: Rect2, label_of: String, tint: Color, size_value: int) -> void:
	var width := _font.get_string_size(
		label_of, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size_value
	).x + 4.0
	# Décalée d'un pixel pour ne pas manger le liseré.
	var plated := Rect2(r.end - Vector2(width + 1.0, LINE + 1.0), Vector2(width, LINE))
	draw_rect(plated, Color(0.06, 0.05, 0.09, 0.82))
	_text(label_of, plated.position + Vector2(2.0, LINE - 2.0), size_value, tint)


## La fiche de la case survolée : à trente-quatre pixels, un nom se tronque.
func _draw_sheet(sheet: Sheet, anchor: Rect2) -> void:
	var r := _sheet_rect(anchor, _sheet_height(sheet))
	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, UiPalette.BORDER, false, 1.0)

	var left := r.position.x + SHEET_PAD
	var width := r.size.x - SHEET_PAD * 2.0
	var y := r.position.y + SHEET_PAD
	_text(sheet.title_text, Vector2(left, y + SHEET_LINE), TITLE_SIZE, UiPalette.TEXT)
	# Ce qui peut l'améliorer : ici plutôt que sur la barre, qui sert à lancer.
	_text(sheet.subtitle, Vector2(left, y + SHEET_LINE * 2.0 - 1.0), FONT_SIZE, KEYWORD)
	y += SHEET_HEADER

	# Le geste d'abord, en toutes lettres ; les nombres ensuite. Une liste de vingt
	# valeurs ne dit pas ce qu'une compétence **fait**.
	var paragraph := _description_lines(sheet.description, width)
	for text_value in paragraph:
		_text(text_value, Vector2(left, y + SHEET_PROSE - 1.0), FONT_SIZE, DESCRIPTION)
		y += SHEET_PROSE
	if not paragraph.is_empty():
		y += SHEET_SEPARATION

	for i in sheet.lines.size():
		var line := sheet.lines[i]
		if _opens_a_group(sheet.lines, i):
			_group_band(left, width, y, "" if i == 0 else _group_title(line))
			y += _group_gap(line, i == 0)
		var base := y + SHEET_LINE - 2.0
		_text(line.label_of, Vector2(left, base), FONT_SIZE, UiPalette.HINT)
		RichText.draw_right(self, _font, Vector2(left, base), left + width, line.value, FONT_SIZE, line.tint)
		y += SHEET_LINE

	var described := PackedStringArray()
	for line in sheet.lines:
		described.append(line.label_of)
		described.append(line.value)
	GlossaryBoxes.draw(self, _font, r, Rect2(Vector2.ZERO, size), described)


## Le filet d'un groupe, **coupé en son centre par son titre** quand il en a un : c'est
## ce qui sépare « ce qu'elle coûte » de « ce qu'elle inflige » d'un coup d'œil.
func _group_band(left: float, width: float, y: float, title_text: String) -> void:
	draw_rect(Rect2(left, roundf(y + SHEET_SEPARATION * 0.5), width, 1.0), UiPalette.BORDER)
	if title_text.is_empty():
		return
	var label_of := title_text
	var span := RichText.width(_font, label_of, FONT_SIZE)
	var x := roundf(left + (width - span) * 0.5)
	# Le fond derrière le titre : sans lui, le filet lui passe au travers.
	draw_rect(Rect2(x - 3.0, y, span + 6.0, SHEET_SEPARATION + TITLE_BAND), UiPalette.TIP_BACK)
	_text(label_of, Vector2(x, y + SHEET_SEPARATION + TITLE_BAND - 1.0), FONT_SIZE, KEYWORD)


## Ce qu'un filet de groupe prend en hauteur. **La même fonction que le dessin** : deux
## calculs se décaleraient d'une ligne à chaque titre ajouté.
static func _group_gap(line: SheetLine, first: bool) -> float:
	if first or _group_title(line).is_empty():
		return SHEET_SEPARATION
	return SHEET_SEPARATION + TITLE_BAND


## Le nom du buff qu'elle porte — **déjà traduit**, c'est du contenu —, à défaut le
## titre de son groupe, qui est une clé française. Vide pour un bloc sans titre.
static func _group_title(line: SheetLine) -> String:
	if not line.heading.is_empty():
		return line.heading
	var key: String = GROUP_TITLES.get(line.group, "")
	return Texts.t(key) if not key.is_empty() else ""


## Le paragraphe, replié sur la largeur de la fiche. Vide pour ce qui n'en a pas.
func _description_lines(text_value: String, width: float) -> PackedStringArray:
	if text_value.is_empty() or _font == null:
		return PackedStringArray()
	return RichText.fold(_font, text_value, width, FONT_SIZE)


## La fiche de la case, quelle que soit sa sorte.
func _cell_sheet(manual: Manual, cell: ManualCell) -> Sheet:
	if cell.skill != null:
		return _skill_sheet(manual, cell.skill)
	return _passive_sheet(manual, cell.passive) if cell.passive != null else null


## Chaque caractéristique de la compétence, **tous les nombres par
## `Player.resolve()`**, le chemin du lancer. Une ligne qui ne dit rien ne s'écrit
## pas ; sans point placé, ceux du premier.
func _skill_sheet(manual: Manual, skill: Skill) -> Sheet:
	var spent := manual.points_of(skill.id)
	var cast := _player.resolve(skill, maxi(spent, 1))
	var projectile := cast.keywords.has(Keywords.PROJECTILE)
	var out: Array[SheetLine] = []

	var points_line := "%d / %d" % [spent, skill.points_max()]
	if cast.bonus_levels != 0:
		points_line += " (%+d)" % cast.bonus_levels
	out.append(SheetLine.new(Group.STATE, Texts.t("points"), points_line, UiPalette.TEXT))
	if manual.level() < skill.required_manual_level:
		out.append(SheetLine.new(
			Group.STATE, Texts.t("verrouillée"),
			Texts.t("niveau %d du manuel") % skill.required_manual_level,
			MISSING
		))
	if spent == 0:
		out.append(_first_point_line())

	if cast.mana_cost > 0.0:
		out.append(SheetLine.new(
			Group.COST, Texts.t("coût"),
			Texts.t("%d mana") % roundi(cast.mana_cost), UiPalette.TEXT
		))
	# Le geste et la recharge **séparément** : rien ne les change ensemble, et une ruée
	# qui part vite mais revient lentement ne se lit pas sur un seul nombre.
	if cast.use_time > 0.0:
		out.append(SheetLine.new(
			Group.COST,
			Texts.t("temps d'attaque") if skill.cadence == Skill.Cadence.WEAPON
			else Texts.t("temps d'incantation"),
			"%.2f s" % cast.use_time, UiPalette.TEXT
		))
	if cast.recharge > 0.0:
		out.append(SheetLine.new(
			Group.COST, Texts.t("recharge"), "%.2f s" % cast.recharge, UiPalette.TEXT
		))
	# Ce qu'un geste entretenu coûte **par seconde** : c'est un prix, pas une forme.
	if cast.self_burn > 0.0:
		out.append(SheetLine.new(
			Group.COST, Texts.t("brûlure"),
			"%s %s" % [StatMod.percentage(roundi(cast.self_burn * 100.0)), Texts.t("PV/s")], MISSING
		))
	if cast.mana_per_second > 0.0:
		out.append(SheetLine.new(
			Group.COST, Texts.t("drain"),
			Texts.t("%d mana/s") % roundi(cast.mana_per_second), MISSING
		))

	# Ce qu'un geste entretenu rend, dans la même colonne que ce qu'il coûte.
	if cast.self_heal > 0.0:
		out.append(SheetLine.new(
			Group.COST, Texts.t("soin"),
			"%s %s" % [StatMod.percentage(cast.self_heal * 100.0), Texts.t("PV/s")], FULL
		))

	if cast.base_damage > 0.0:
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t("de base"),
			_in_nature(cast.base_damage, cast.base_damage, skill.nature),
			DamageType.COLORS[skill.nature]
		))
	# Ce que les PV du lanceur ajoutent aux dégâts propres, et à quel taux : sans cette
	# ligne, « de base » monte avec la vie sans que rien ne dise pourquoi.
	if skill.health_scaling > 0.0:
		var from_life := _player.stats.max_health * skill.health_scaling
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t("adossé aux PV"),
			"%s · %s" % [
				StatMod.percentage(skill.health_scaling * 100.0),
				_in_nature(from_life, from_life, skill.nature)
			],
			DamageType.COLORS[skill.nature]
		))
	for nature in DamageType.Kind.size():
		if cast.added_max[nature] > 0.0:
			out.append(SheetLine.new(
				Group.DAMAGE, Texts.t("ajoutés"),
				_in_nature(cast.added_min[nature], cast.added_max[nature], nature),
				DamageType.COLORS[nature]
			))
	# Ce qu'une conversion a déplacé, dans la couleur d'arrivée.
	for nature in DamageType.Kind.size():
		if cast.conversions[nature] > 0.0:
			out.append(SheetLine.new(
				Group.DAMAGE, Texts.t("converti"),
				_converted_part(cast.conversions[nature], nature), DamageType.COLORS[nature]
			))
	for percent in [
		[StatMod.Mode.PERCENT, cast.increased], [StatMod.Mode.MORE, cast.more]
	]:
		var factor: float = percent[1]
		if not is_equal_approx(factor, 1.0):
			out.append(SheetLine.new(
				Group.DAMAGE,
				StatMod.term_label(SkillStats.DAMAGE, StatMod.term_of(percent[0], factor - 1.0)),
				_increase(factor), UiPalette.TEXT
			))
	# Hors du total « par coup », qui reste celui d'une cible sans état.
	for kind in StatusEffects.Kind.size():
		var stat := SkillStats.against_stat(kind)
		var added := cast.against_increased[kind]
		if added != 0.0:
			out.append(SheetLine.new(
				Group.DAMAGE, StatMod.term_label(stat, StatMod.term_of(StatMod.Mode.PERCENT, added)),
				StatMod.value_label(stat, StatMod.Mode.PERCENT, added), StatusEffects.color(kind)
			))
		var more := (cast.against_more[kind] - 1.0) * 100.0
		if not is_zero_approx(more):
			out.append(SheetLine.new(
				Group.DAMAGE, StatMod.term_label(stat, StatMod.term_of(StatMod.Mode.MORE, more)),
				StatMod.value_label(stat, StatMod.Mode.MORE, more), StatusEffects.color(kind)
			))
	if cast.total_max() > 0.0:
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t("par projectile") if projectile else Texts.t("par coup"),
			SkillStats.readable_range(cast.total_min(), cast.total_max()), FULL
		))
		# La chance du coup, accrus compris : plus une base, d'où son nom à part. Le
		# multiplicateur est celui de la fiche.
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t("chance critique"),
			StatMod.format(SkillStats.CRIT_CHANCE, cast.crit_chance), UiPalette.TEXT
		))
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t(StatMod.LABELS["crit_multiplier"]),
			StatMod.format("crit_multiplier", cast.crit_multiplier), UiPalette.TEXT
		))

	# Ce que ce lancer accroît à la chance de poser son état, **et ce que ça donne sur
	# cette fiche-là** : sans le second nombre, « +50 % » n'a pas de point de départ.
	# Les accrus du porteur y sont, comme au coup (`StatusEffects.suffer()`).
	var state_kind := StatusEffects.NATURES.find(skill.nature)
	var chance_stat: String = StatusEffects.CHANCE_STATS[state_kind] if state_kind >= 0 else ""
	if cast.status_chance_increase > 0.0 and not chance_stat.is_empty():
		var worn_factor := _player.states.chance_factors[state_kind]
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t(StatMod.LABELS[chance_stat]),
			"%s · %s" % [
				StatMod.percentage(cast.status_chance_increase, true),
				StatMod.percentage(100.0 * StatusEffects.CHANCE * (
					worn_factor + cast.status_chance_increase * 0.01
				))
			],
			StatusEffects.color(state_kind)
		))

	if projectile:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("projectiles"), str(cast.projectile_count()),
			UiPalette.TEXT
		))
		if cast.spread_in_degrees > 0.0:
			out.append(SheetLine.new(
				Group.SHAPE, Texts.t("écart"), "%d°" % roundi(cast.spread_in_degrees),
				UiPalette.TEXT
			))
		if cast.projectile_speed > 0.0:
			out.append(SheetLine.new(
				# Un contexte : « vitesse » est aussi le déplacement.
				Group.SHAPE, Texts.t("vitesse", "fiche de compétence"),
				"%d px/s" % roundi(cast.projectile_speed), UiPalette.TEXT
			))
	# Les autres formes, lues sur leurs valeurs : la page ne connaît pas les formes.
	if cast.target_count() > 1:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("cibles"), str(cast.target_count()), UiPalette.TEXT
		))
	if cast.hits > 1:
		out.append(SheetLine.new(Group.SHAPE, Texts.t("coups"), str(cast.hits), UiPalette.TEXT))
	# Celle d'un lancer qui pose un buff se lit sous le nom du buff, plus bas.
	if cast.duration > 0.0 and not skill.grants_buffs():
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("durée"), "%.1f s" % cast.duration, UiPalette.TEXT
		))
	if cast.radius > 0.0:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("rayon"), "%d px" % roundi(cast.radius), UiPalette.TEXT
		))
	if cast.period > 0.0:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("toutes les"), "%.2f s" % cast.period, UiPalette.TEXT
		))
	if cast.max_simultaneous() > 0:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("en même temps"), str(cast.max_simultaneous()), UiPalette.TEXT
		))

	# Ce que le lancer pose sur son lanceur : **un bloc par buff**, sous son nom. Un
	# geste entretenu n'y met pas de durée : il tient tant qu'on le paie.
	for buff in skill.buffs:
		var block: Array[SheetLine] = []
		var heading := buff.displayed_name()
		if cast.duration > 0.0:
			block.append(SheetLine.new(
				Group.BUFF, Texts.t("durée"), "%.1f s" % cast.duration, UiPalette.TEXT, heading
			))
		for m in buff.mods(maxi(spent, 1)):
			block.append(SheetLine.new(
				Group.BUFF, StatMod.name(m.stat, m.scope), m.readable_value(),
				UiPalette.TEXT, heading
			))
		out.append_array(block)

	# Ce qu'elle inflige, pour comparer deux sorts ; une aura n'a que la seconde.
	var per_cast := cast.average_per_cast()
	var per_second := cast.average_per_second()
	if per_cast > 0.0:
		out.append(SheetLine.new(
			Group.ESTIMATE, Texts.t("moyenne par lancer"), str(roundi(per_cast)), FULL
		))
	if per_second > 0.0:
		out.append(SheetLine.new(
			Group.ESTIMATE, Texts.t("par seconde"), str(roundi(per_second)), FULL
		))
	# **Un déplacement ne touche personne** : ses dégâts, sa forme et ses moyennes
	# décrivent un coup qui n'existe pas. Le lancer les porte quand même — l'équipement
	# ajoute ses fourchettes à tout ce qui est « sort » —, et les afficher mentirait.
	if not skill.strikes():
		out.assign(out.filter(func(l: SheetLine) -> bool:
			return not l.group in [Group.DAMAGE, Group.SHAPE, Group.ESTIMATE]
		))

	return Sheet.new(
		skill.displayed_name(), cast.keywords_label(), out, skill.displayed_description()
	)


## Ce qu'un passif donne à ses points ; son sous-titre dit « toujours actif ».
func _passive_sheet(manual: Manual, passive: Passive) -> Sheet:
	var spent := manual.points_of(passive.id)
	var out: Array[SheetLine] = []
	out.append(SheetLine.new(
		Group.STATE, Texts.t("points"), "%d / %d" % [spent, passive.points_max],
		UiPalette.TEXT
	))
	if manual.level() < passive.required_manual_level:
		out.append(SheetLine.new(
			Group.STATE, Texts.t("verrouillé"),
			Texts.t("niveau %d du manuel") % passive.required_manual_level, MISSING
		))
	if spent == 0:
		out.append(_first_point_line())
	out.append_array(_effect_lines(passive.mods(maxi(spent, 1))))
	return Sheet.new(passive.displayed_name(), Texts.t("toujours actif"), out)


## Ce qu'un nœud change, et ce qu'il demande — lu sur le manuel, jamais recalculé.
func _node_sheet(manual: Manual, cell: ManualCell, node: TalentNode) -> Sheet:
	var spent := manual.points_of(node.id)
	var out: Array[SheetLine] = []
	out.append(SheetLine.new(
		Group.STATE, Texts.t("points"), "%d / %d" % [spent, node.points_max],
		UiPalette.TEXT
	))
	if not manual.is_open(_archetype(), node.id):
		out.append(SheetLine.new(
			Group.STATE, Texts.t("demande"), _what_it_requires(manual, cell, node), MISSING
		))
	if spent == 0:
		out.append(_first_point_line())

	out.append_array(_effect_lines(node.mods(maxi(spent, 1))))
	if node.converts():
		out.append(SheetLine.new(
			Group.EFFECT, Texts.t("converti"),
			_converted_part(node.conversion(maxi(spent, 1)), node.converts_to),
			DamageType.COLORS[node.converts_to]
		))
	# Le mot-clé donné : il fait mordre l'équipement de la nature d'arrivée.
	for id in node.added_keywords:
		out.append(SheetLine.new(
			Group.EFFECT, Texts.t("mot-clé"), Keywords.label_of(id), KEYWORD
		))
	return Sheet.new(node.displayed_name(), Texts.t("talent"), out)


## Le parent vide d'abord, sinon les points de la compétence.
func _what_it_requires(manual: Manual, cell: ManualCell, node: TalentNode) -> String:
	if not node.parent.is_empty() and manual.points_of(node.parent) <= 0:
		var parent := cell.node_of(node.parent)
		return Texts.t("le talent « {nom} »").format({"nom": parent.displayed_name()})
	# « dans la compétence » et non son nom, que l'en-tête écrit déjà : il débordait
	# (mesuré par `test_largeurs`).
	return Texts.tn(
		"{points} point dans la compétence", "{points} points dans la compétence",
		node.required_points
	).format({"points": node.required_points})


## Par la **même fonction que l'infobulle d'un objet**.
func _effect_lines(mods: Array[StatMod]) -> Array[SheetLine]:
	var out: Array[SheetLine] = []
	for m in mods:
		out.append(SheetLine.new(
			Group.EFFECT, StatMod.name(m.stat, m.scope), m.readable_value(), UiPalette.TEXT
		))
	return out


## Une case vide annonce les nombres du premier point.
func _first_point_line() -> SheetLine:
	return SheetLine.new(
		Group.STATE, Texts.t("nombres du premier point"), "", UiPalette.TEXT
	)


## Deux buffs à la suite sont deux blocs : ils partagent leur groupe et pas leur nom.
static func _opens_a_group(lines: Array[SheetLine], index: int) -> bool:
	if index == 0:
		return true
	return (
		lines[index].group != lines[index - 1].group
		or lines[index].heading != lines[index - 1].heading
	)


## Mesurée sur les lignes mêmes que le dessin écrit, paragraphe et titres de groupe
## compris.
func _sheet_height(sheet: Sheet) -> float:
	var lines := sheet.lines
	var h := SHEET_PAD * 2.0 + SHEET_HEADER + SHEET_LINE * float(lines.size())
	var paragraph := _description_lines(sheet.description, SHEET_W - SHEET_PAD * 2.0)
	if not paragraph.is_empty():
		h += SHEET_PROSE * float(paragraph.size()) + SHEET_SEPARATION
	for i in lines.size():
		if _opens_a_group(lines, i):
			h += _group_gap(lines[i], i == 0)
	return h


## À droite de ce qu'elle décrit, **tenue dans le cadrage** au-dessus du HUD ; à
## gauche quand la droite manque.
func _sheet_rect(anchor: Rect2, height: float) -> Rect2:
	var screen := Vector2(Settings.base_size())
	var x := size.x + SHEET_GAP
	if global_position.x + x + SHEET_W > screen.x:
		x = -SHEET_GAP - SHEET_W
	var floor_value := Hud.gauges_top(screen.y) - global_position.y
	var y := minf(anchor.position.y, floor_value - height)
	return Rect2(x, maxf(y, -global_position.y), SHEET_W, height)


## « 3–7 froid », ou « 23 foudre » quand les deux bornes s'arrondissent au même
## nombre.
static func _in_nature(low: float, top: float, nature: int) -> String:
	return "%s %s" % [SkillStats.readable_range(low, top), DamageType.name(nature)]


## « 60 % en feu » : la part d'un coup qu'une conversion emmène, et où.
static func _converted_part(part: float, nature: int) -> String:
	return Texts.t("{part} en {nature}").format({
		"part": StatMod.percentage(roundi(part * 100.0)), "nature": DamageType.name(nature)
	})


## « +40 % », par **la même fonction** qu'un objet.
static func _increase(factor: float) -> String:
	return StatMod.value_label("", StatMod.Mode.PERCENT, (factor - 1.0) * 100.0)


func _text(text_value: String, at: Vector2, size_value: int, tint: Color) -> void:
	RichText.draw(self, _font, at, text_value, size_value, tint)
