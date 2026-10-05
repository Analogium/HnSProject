class_name ManualPanel
extends Control

## Le râtelier et la page du manuel choisi (M) : les trois dos en haut, celui de la
## classe à l'écart, la page dessous. **On n'investit que d'ici**, donc dans un livre étudié : équiper est
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

## L'arbre ouvert (jalon 34, « centre, élargi » choisi sur planche) : la compétence au
## centre, ses nœuds en réseau autour, jusqu'à `TREE_SPAN` cases de chaque côté. La
## fenêtre s'élargit à `TREE_W` le temps de l'arbre : à 210 pixels, les nœuds collaient.
const NODE := 28.0
const TREE_STEP := Vector2(42.0, 44.0)
const TREE_SPAN := Vector2i(3, 1)
const TREE_W := 300.0
## Un grain par point demandé dans le parent, sur le lien, dès deux.
const GRAIN := 2.0
const GRAIN_STEP := 5.0

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

## La fiche de survol : assez large pour « Dégâts contre les embrasés   +12 % accrus »
## (Tison, jalon 34), pas plus — elle couvre le sac.
const SHEET_W := 176.0
const SHEET_PAD := 6.0
const SHEET_GAP := 4.0
## La hauteur d'une ligne de fiche, **plus serrée que celle de la page** : la fiche la
## plus chargée du jeu tient tout juste au-dessus des jauges, et c'est ce pixel par
## ligne qui lui laisse son paragraphe.
const SHEET_LINE := 9.0
## Une ligne de paragraphe, plus serrée encore : de la prose, pas un tableau de valeurs.
const SHEET_PROSE := 8.0
## Le nom et les mots-clés, au-dessus des lignes.
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
## Ce qu'un échange coûte : le rouge de ce qui manque, lu de la même façon.
const LOSS := MISSING
## Les pastilles d'un nœud qui change le jeu, en haut à droite : une transformation, une
## mécanique. La conversion garde la sienne, de sa nature, en haut à gauche.
const KIND_COLORS := {
	"transformation": Color(0.78, 0.60, 0.98),
	"mécanique": Color(0.98, 0.70, 0.32),
}
## Le paragraphe de description : plus chaud que les intitulés, plus éteint que les
## valeurs. Il se lit une fois, les nombres se relisent.
const DESCRIPTION := Color(0.80, 0.75, 0.66)

## Les groupes de la fiche, dans l'ordre des questions. `EFFECT` : passif et nœud, qui
## n'ont ni coût ni portée.
enum Group {
	STATE, EFFECT, COST, DAMAGE, SHAPE, ESTIMATE, BUFF, ON_HIT, ON_TICK, ON_KILL,
	# Jalon 38 : l'état qu'un lancer pose, et ce qu'il fait lever — sous leur nom.
	INFLICTED, SUMMONED,
	# Jalon 41 : ce qu'un sort charge en partant, et les réactions de la Catalyse.
	ON_CAST, REACTIONS,
}

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
	# La fenêtre des déclenchements : ce qu'un coup, un à-coup ou une mort peut poser.
	Group.ON_TICK: "À chaque à-coup",
	Group.ON_KILL: "À chaque ennemi tué",
	Group.ON_CAST: "À chaque sort lancé",
	Group.REACTIONS: "Réactions",
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
	## Ce que le geste fait, en une phrase, avant les nombres. Vide pour un passif, dont
	## les lignes **sont** la description ; un nœud en a une depuis le jalon 34.
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
## `_open_cell()` retombe sur la grille si le livre change. **Ouvert, la fenêtre descend
## jusqu'aux jauges** : quatre rangées de nœuds ne tiennent pas dans la page de la grille.
var _opened := "":
	set(value):
		_opened = value
		if _grid_height > 0.0:
			size.y = _grid_height if value.is_empty() else _tree_height()
			# Vers la gauche : à droite, le sac l'aurait recouvert.
			var grow := 0.0 if value.is_empty() else TREE_W - _grid_width
			position.x = _grid_left - grow
			size.x = _grid_width + grow
## La place de la scène, celle de la grille.
var _grid_height := 0.0
var _grid_width := 0.0
var _grid_left := 0.0
var _hover_slot := -1
var _hover_cell := -1
## Le nœud survolé dans l'arbre ouvert, et le survol de la racine.
var _hover_node := -1
var _hover_root := false
## Pour ne redessiner que quand elle bouge : la page reste ouverte en combat.
var _displayed_exp := -1
## La touche des détails tenue (`item_details`, celle du sac) : la fenêtre des
## déclenchements s'ouvre à côté de la fiche d'une compétence.
var _detailed := false


func _ready() -> void:
	visible = false
	_grid_height = size.y
	_grid_width = size.x
	_grid_left = position.x
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
	# L'état **réel** à chaque image, comme le sac : le relâchement peut être avalé.
	var held := Input.is_action_pressed("item_details")
	if held != _detailed:
		_detailed = held
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


## Celui de la classe un écart plus loin : il ne se range pas, et ne doit pas se lire
## comme un quatrième choix.
func _slot_rect(index: int) -> Rect2:
	var x := PAD + float(index) * (SLOT + SLOT_GAP)
	if index == Rack.CLASS_SLOT:
		x += SLOT_GAP
	return Rect2(x, HEADER, SLOT, SLOT)


## Le haut de la page : sous les dos, avec de l'air.
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


## Jusqu'au-dessus des jauges, qui sont dessinées après les panneaux.
func _tree_height() -> float:
	return Hud.gauges_top(get_viewport_rect().size.y) - position.y


## Le centre de l'arbre, où se tient la compétence : entre l'en-tête et l'aide.
func _tree_center() -> Vector2:
	return Vector2(size.x * 0.5, (_origin().y + _help_top()) * 0.5).floor()


func _root_rect() -> Rect2:
	return Rect2(_tree_center() - Vector2(CELL, CELL) * 0.5, Vector2(CELL, CELL))


func _node_rect(position: Vector2i) -> Rect2:
	var center := _tree_center() + Vector2(position) * TREE_STEP
	return Rect2(center - Vector2(NODE, NODE) * 0.5, Vector2(NODE, NODE))


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
	# La compétence survolée, s'il y en a une : c'est elle qui a une fenêtre de détails.
	var skill: Skill = null
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
			skill = hovered_one.skill
	else:
		# Le chevron dit d'où l'on revient ; le clic droit fait le retour.
		_draw_header(book, "‹ %s" % open_cell.skill.displayed_name(), UiPalette.TEXT, open_cell)
		_draw_tree(book.manual, book.base.manual, open_cell)
		_text(
			Texts.t("[clic] +1     [clic droit] -1     [échap] retour"),
			Vector2(PAD, _help_top() + LINE), FONT_SIZE, UiPalette.HINT
		)
		if _hover_root:
			sheet = _skill_sheet(book.manual, open_cell.skill)
			anchor = _root_rect()
			skill = open_cell.skill
		elif _hover_node >= 0 and _hover_node < open_cell.talents.size():
			var node := open_cell.talents[_hover_node]
			sheet = _node_sheet(book.manual, open_cell, node)
			anchor = _node_rect(node.position)

	# En dernier : la fiche passe par-dessus tout, le sac compris. Les détails la
	# remplacent auprès du glossaire : ses encadrés se poseraient sur eux.
	var details := _trigger_sheet(skill) if _detailed and skill != null else null
	if details != null and details.lines.is_empty():
		details = null
	if sheet != null:
		_draw_sheet(sheet, anchor, false, details == null)
	if details != null:
		_draw_sheet(details, anchor, true, false)


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
## vues** : on doit savoir dans l'arbre si l'on a de quoi payer. Dans l'arbre, c'est
## son propre pool qu'on annonce (jalon 34).
func _draw_header(book: Item, title_text: String, tint: Color, tree: ManualCell = null) -> void:
	var manual := book.manual
	var y := _page_top() + 8.0
	_text(title_text, Vector2(PAD, y), TITLE_SIZE, tint)

	var remaining_all := (
		manual.tree_remaining(tree) if tree != null
		else manual.remaining_points(book.base.manual)
	)
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
	var tint := _tint(
		cell.required_level() <= manual.level(), spent, maximum,
		manual.remaining_points(_archetype())
	)
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


## Liens, racine puis nœuds : les nœuds couvrent les bouts des liens.
func _draw_tree(manual: Manual, arch: ManualArchetype, cell: ManualCell) -> void:
	var root := _root_rect()
	for node in cell.talents:
		var to := _node_rect(node.position).get_center()
		var invested := manual.points_of(node.id) > 0
		if node.parents.is_empty():
			draw_line(root.get_center(), to, LINK_BRIGHT if invested else LINK, 1.0)
		for parent: String in node.parents:
			var need: int = node.parents[parent]
			var from_value := _node_rect(cell.node_of(parent).position).get_center()
			# Le lien s'allume sur le chemin réellement pris, dans un sens ou dans l'autre.
			var held := manual.points_of(parent)
			draw_line(from_value, to, LINK_BRIGHT if invested and held > 0 else LINK, 1.0)
			if need > 1:
				_draw_grains(from_value, to, need, held)

	# Opaques sous leur fond à 0,9 : les liens passaient au travers (vu à la capture).
	draw_rect(root, UiPalette.BACK_FULL)
	_draw_cell(manual, cell, root, _hover_root)
	for i in cell.talents.size():
		_draw_node(manual, arch, cell.talents[i], i == _hover_node)


func _draw_node(
	manual: Manual, arch: ManualArchetype, node: TalentNode, hovered: bool
) -> void:
	var r := _node_rect(node.position)
	var spent := manual.points_of(node.id)
	var tint := _tint(
		manual.is_open(arch, node.id), spent, node.points_max,
		manual.tree_remaining(arch.cell_of_node(node.id))
	)
	draw_rect(r, UiPalette.BACK_FULL)
	draw_rect(r, CELL_BACKGROUND)
	draw_rect(r, tint, false, 2.0 if hovered else 1.0)

	# Pastille de la nature d'arrivée d'une conversion : seul effet lisible en couleur.
	if node.converts:
		draw_circle(r.position + Vector2(5.0, 5.0), 2.0, DamageType.COLORS[node.converts_to])
	var kind := node.kind()
	if KIND_COLORS.has(kind):
		draw_circle(r.position + Vector2(r.size.x - 5.0, 5.0), 2.0, KIND_COLORS[kind])

	_draw_count(
		r, "%d/%d" % [spent, node.points_max],
		UiPalette.TEXT if tint != LOCK else UiPalette.LABEL, FONT_SIZE
	)


## Les « ••• » de Last Epoch : les points que le parent doit porter, au milieu du lien,
## allumés à mesure qu'il les porte.
func _draw_grains(from_value: Vector2, to: Vector2, need: int, held: int) -> void:
	var along := from_value.direction_to(to)
	var middle := (from_value + to) * 0.5
	for k in need:
		var at := (middle + along * (float(k) - float(need - 1) * 0.5) * GRAIN_STEP).floor()
		draw_rect(Rect2(at - Vector2(GRAIN, GRAIN), Vector2(GRAIN, GRAIN) * 2.0), UiPalette.BACK_FULL)
		draw_rect(Rect2(at - Vector2(GRAIN, GRAIN) * 0.5, Vector2(GRAIN, GRAIN)), FULL if held > k else WAIT)


## **Le seul endroit** qui traduit un état en couleur, cases et nœuds.
func _tint(opened: bool, spent: int, maximum: int, remaining: int) -> Color:
	if spent >= maximum:
		return FULL
	if not opened:
		return LOCK
	return OPEN if remaining > 0 else WAIT


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
## `aside` : de l'autre côté du panneau, là où se pose la fenêtre des détails.
func _draw_sheet(sheet: Sheet, anchor: Rect2, aside := false, glossary := true) -> void:
	var r := _sheet_rect(anchor, _sheet_height(sheet), aside)
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

	if not glossary:
		return
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
	if cast.self_wither > 0.0:
		out.append(SheetLine.new(
			Group.COST, Texts.t("brûlure"),
			"%s %s" % [
				StatMod.percentage(cast.self_wither * 100.0), Texts.t("PV actuels/s")
			], MISSING
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

	# La nature **du lancer** : celle d'une compétence qui en change est celle du prochain.
	if cast.base_damage > 0.0:
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t("de base"),
			_in_nature(cast.base_damage, cast.base_damage, cast.nature),
			DamageType.COLORS[cast.nature]
		))
	# Ce que les PV du lanceur ajoutent aux dégâts propres, et à quel taux : sans cette
	# ligne, « de base » monte avec la vie sans que rien ne dise pourquoi.
	if skill.health_scaling > 0.0:
		var from_life := _player.stats.max_health * skill.health_scaling
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t("adossé aux PV"),
			"%s · %s" % [
				StatMod.percentage(skill.health_scaling * 100.0),
				_in_nature(from_life, from_life, cast.nature)
			],
			DamageType.COLORS[cast.nature]
		))
	for nature in DamageType.Kind.size():
		if cast.added_max[nature] > 0.0:
			out.append(SheetLine.new(
				Group.DAMAGE, Texts.t("ajoutés"),
				_in_nature(cast.added_min[nature], cast.added_max[nature], nature),
				DamageType.COLORS[nature]
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
	var state_kind := StatusEffects.NATURES.find(cast.nature)
	var chance_stat: String = StatusEffects.CHANCE_STATS[state_kind] if state_kind >= 0 else ""
	var chance_label: String = StatMod.LABELS.get(
		chance_stat, StatusEffects.UNWORN_CHANCES.get(state_kind, "")
	)
	if cast.status_chance_increase > 0.0 and not chance_label.is_empty():
		var worn_factor := _player.states.chance_factors[state_kind]
		out.append(SheetLine.new(
			Group.DAMAGE, Texts.t(chance_label),
			"%s · %s" % [
				StatMod.percentage(cast.status_chance_increase, true),
				StatMod.percentage(100.0 * StatusEffects.chance(
					1.0, 0.0, StatusEffects.factor_of(worn_factor, cast.status_chance_increase)
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
	if cast.waves > 0.0:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("vagues"), str(1 + int(cast.waves)), UiPalette.TEXT
		))
	if cast.extra_swords > 0.0:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("épées par lancer"), str(1 + int(cast.extra_swords)), UiPalette.TEXT
		))
	# Celle d'un lancer qui pose un buff se lit sous le nom du buff, plus bas.
	# Celle d'une malédiction se lit dans son bloc : c'est celle de l'état.
	if cast.duration > 0.0 and not skill.grants_buffs() \
			and cast.inflicted_state != StatusEffects.Kind.CURSED:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("durée"), "%.1f s" % cast.duration, UiPalette.TEXT
		))
	if cast.radius > 0.0 and cast.shape != Skill.Shape.MARK:
		out.append(SheetLine.new(
			# Celui d'une frappe vive n'est pas une zone : c'est jusqu'où elle va chercher.
			Group.SHAPE, Texts.t("portée") if skill.shape == Skill.Shape.LUNGE else Texts.t("rayon"),
			"%d px" % roundi(cast.radius), UiPalette.TEXT
		))
	if cast.period > 0.0:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("toutes les"), "%.2f s" % cast.period, UiPalette.TEXT
		))
	if cast.max_simultaneous() > 0:
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("en même temps"), str(cast.max_simultaneous()), UiPalette.TEXT
		))
	# L'état posé tient en une ligne, son multiplicateur compris ; son détail est dans la
	# fenêtre des déclenchements — sauf pour ce qui ne frappe pas, qui a la place.
	if cast.inflicted_state >= 0 and skill.strikes():
		out.append(SheetLine.new(
			Group.SHAPE, Texts.t("état"),
			"%s · %s · %s" % [
				StatusEffects.name(cast.inflicted_state),
				StatMod.percentage(roundi(cast.inflict_chance * 100.0)),
				_times(cast.strength_of(cast.inflicted_state))
			],
			StatusEffects.color(cast.inflicted_state)
		))
	elif cast.inflicted_state >= 0:
		out.append_array(_inflicted_lines(cast))

	# Ce que le lancer pose sur son lanceur : **un bloc par buff**, sous son nom. Un
	# geste entretenu n'y met pas de durée : il tient tant qu'on le paie.
	for buff in skill.buffs:
		var block: Array[SheetLine] = []
		var heading := buff.displayed_name()
		if cast.duration > 0.0:
			block.append(SheetLine.new(
				Group.BUFF, Texts.t("durée"), "%.1f s" % cast.duration, UiPalette.TEXT, heading
			))
		# Ce que valent les lignes dessous : une charge. Puis ce que l'arbre de Trinité
		# fait des charges (jalon 41).
		if skill.stacks_max > 0:
			block.append(SheetLine.new(
				Group.BUFF, Texts.t("charges"),
				Texts.t("%d au plus, %.1f s") % [Buff.cap_of(skill, cast), Buff.hold_of(skill, cast)],
				UiPalette.TEXT, heading
			))
			var said := []
			if cast.dissonance > 0.0:
				said.append([Texts.t("même élément"), Texts.t("perd toutes les charges")])
			if cast.tempo > 0.0:
				said.append([Texts.t("recharges"), Texts.t("-%.1f s par charge") % cast.tempo])
			if cast.perfect_chord > 0.0:
				said.append([
					Texts.t("pleines charges"),
					Texts.t("trois éléments, %s") % StatMod.percentage(roundi(cast.perfect_chord), true)
				])
			for pair: Array in said:
				block.append(SheetLine.new(Group.BUFF, pair[0], pair[1], UiPalette.TEXT, heading))
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
	# Une malédiction ne frappe pas non plus, mais sa zone et ce qu'elle pose sont ce
	# qu'elle fait.
	if not skill.strikes():
		var hidden := [Group.DAMAGE, Group.ESTIMATE]
		if skill.inflicted_state < 0:
			hidden.append(Group.SHAPE)
		out.assign(out.filter(func(l: SheetLine) -> bool: return not l.group in hidden))

	return Sheet.new(
		skill.displayed_name(), cast.keywords_label(), out, skill.displayed_description()
	)


## L'état que le lancer pose, **sous son nom** : ce qu'il fait concrètement, et le
## multiplicateur d'effet que l'arbre — ou plus tard un objet — lui donne (jalon 38).
func _inflicted_lines(cast: SkillStats) -> Array[SheetLine]:
	var out: Array[SheetLine] = []
	var kind := cast.inflicted_state
	if kind < 0:
		return out
	var heading := RichText.capitalized(StatusEffects.name(kind))
	var tint := StatusEffects.color(kind)
	var strength := cast.strength_of(kind)
	var lines := []
	var lasts: float = StatusEffects.DURATIONS[kind]
	if kind == StatusEffects.Kind.CURSED:
		lasts = cast.duration
	lines.append([Texts.t("durée"), "%.1f s" % lasts])
	var burn := StatusEffects.burn_per_second(kind)
	if burn > 0.0:
		lines.append([
			Texts.t("brûle par seconde"),
			Texts.t("%s du coup") % StatMod.percentage(roundi(burn * strength * 100.0))
		])
	if kind == StatusEffects.Kind.WILTING and strength > 1.0:
		lines.append([
			Texts.t("dégâts infligés"), StatMod.percentage(-roundi((strength - 1.0) * 100.0), true)
		])
	if kind == StatusEffects.Kind.CURSED:
		lines.append([
			StatMod.name("res_necrotic"),
			StatMod.format("res_necrotic", -StatusEffects.CURSE * strength, true)
		])
	if cast.shape == Skill.Shape.MARK:
		lines.append([Texts.t("cible"), Texts.t("un seul ennemi")])
	if cast.contagion > 0.0 and not SkillStats.CONTAGION in Skill.IGNORED_BY_SHAPE.get(cast.shape, []):
		lines.append([Texts.t("contagion"), "%d px" % roundi(cast.contagion)])
	lines.append([Texts.t("effet"), _times(strength)])
	for pair: Array in lines:
		out.append(SheetLine.new(Group.INFLICTED, pair[0], pair[1], tint, heading))
	return out


## Ce que le lancer fait lever, **sous son nom** : les morts-vivants de la Relève, les
## créatures de la Porte — leurs nombres ne se lisaient nulle part (jalon 38).
func _summoned_lines(skill: Skill, cast: SkillStats) -> Array[SheetLine]:
	var lines := []
	var heading := ""
	if skill.shape == Skill.Shape.SUMMON:
		heading = Texts.t("Colosse") if cast.colossus > 0.0 else Texts.t("Morts-vivants")
		lines.append([Texts.t("debout"), str(Minion.cap(cast))])
		var life := _player.stats.max_health * Minion.life_part(cast)
		lines.append([Texts.t("PV"), str(roundi(life))])
		lines.append([Texts.t("frappe toutes les"), "%.2f s" % cast.period])
		lines.append([Texts.t("garde"), "%d px" % roundi(cast.radius)])
		if cast.colossus > 0.0:
			lines.append([Texts.t("frappe en cercle"), "%d px" % roundi(cast.colossus)])
		if cast.end_burst > 0.0:
			lines.append([Texts.t("explose en tombant"), "%d px" % roundi(cast.end_burst)])
		if cast.bone_wall > 0.0:
			lines.append([
				Texts.t("dégâts subis, par tête"), StatMod.percentage(-cast.bone_wall, true)
			])
	elif skill.shape == Skill.Shape.ORBIT and (cast.blade_ward > 0.0 or cast.sword_volley > 0.0):
		heading = Texts.t("Épées")
		if cast.blade_ward > 0.0:
			lines.append([
				Texts.t("dégâts subis, par épée"), StatMod.percentage(-cast.blade_ward, true)
			])
		if cast.sword_volley > 0.0:
			lines.append([Texts.t("volée, à leur fin"), "%d px" % roundi(cast.sword_volley)])
	elif skill.shape == Skill.Shape.GATE:
		heading = Texts.t("Créatures")
		if cast.shape == Skill.Shape.NEST:
			lines.append([Texts.t("portail"), Texts.t("à votre épaule")])
		lines.append([Texts.t("une toutes les"), "%.2f s" % cast.period])
		lines.append([Texts.t("explosion"), "%d px" % roundi(cast.radius)])
		lines.append([Texts.t("vue"), "%d px" % roundi(RottingGate.SIGHT + cast.seek_radius)])
		lines.append([
			Texts.t("course"), "%d px/s" % roundi(RottingGate.SPEED * (1.0 + cast.crawl_speed * 0.01))
		])
		if cast.hatchlings > 0.0:
			lines.append([
				Texts.t("petits"),
				"%d · %s" % [
					int(cast.hatchlings), StatMod.percentage(roundi(SkillStats.SPLIT_PART * 100.0))
				]
			])
	elif skill.shape == Skill.Shape.DOLL:
		heading = Texts.t("Poupée")
		if cast.max_simultaneous() > 1:
			lines.append([Texts.t("debout"), str(cast.max_simultaneous())])
		lines.append([Texts.t("PV"), str(roundi(_player.stats.max_health * RagDoll.life_part(cast)))])
		lines.append([Texts.t("éclate"), "%d px" % roundi(cast.radius)])
		if cast.grudge > 0.0:
			lines.append([
				Texts.t("éclat, en plus"),
				Texts.t("%s de ce qu'elle encaisse") % StatMod.percentage(roundi(cast.grudge))
			])
		if cast.transfer > 0.0:
			lines.append([
				Texts.t("prend pour vous"),
				Texts.t("%s de vos dégâts") % StatMod.percentage(roundi(minf(cast.transfer, 100.0)))
			])
		if cast.lure > 0.0:
			lines.append([Texts.t("paraît plus proche de"), "%d px" % roundi(cast.lure)])
	elif skill.shape == Skill.Shape.FAMILIAR:
		heading = Texts.t("Échos")
		lines.append([
			Texts.t("rejoue"),
			Texts.t("%s des dégâts") % StatMod.percentage(roundi(Familiar.echo_part(cast) * 100.0))
		])
		if cast.echoes > 0.0:
			lines.append([Texts.t("échos"), str(1 + int(cast.echoes))])
		lines.append([Texts.t("après"), "%.2f s" % Familiar.ECHO_DELAY])
		if cast.seek_radius > 0.0:
			lines.append([Texts.t("vise l'ennemi à"), "%d px" % roundi(cast.seek_radius)])
		if cast.countersong > 0.0:
			lines.append([Texts.t("élément"), Texts.t("le suivant du tour")])
	var out: Array[SheetLine] = []
	for pair: Array in lines:
		out.append(SheetLine.new(Group.SUMMONED, pair[0], pair[1], UiPalette.TEXT, heading))
	return out


## Ce que fait chaque paire d'états sous la Catalyse (jalon 41), son arbre compris.
func _reaction_lines(cast: SkillStats) -> Array[SheetLine]:
	var tint := UiPalette.TEXT
	var out: Array[SheetLine] = [
		SheetLine.new(
			Group.REACTIONS, Texts.t("par réaction"),
			Texts.t("%s d'un coup") % StatMod.percentage(roundi(Catalysis.reaction_part(cast) * 100.0)), tint
		),
		SheetLine.new(
			Group.REACTIONS, Texts.t(Catalysis.NAMES[Catalysis.Reaction.VAPOR]),
			(Texts.t("souffle de %d px, nappe de %.1f s") % [roundi(Catalysis.VAPOR_RADIUS), cast.ground_duration])
			if cast.ground_duration > 0.0 else Texts.t("souffle de %d px") % roundi(Catalysis.VAPOR_RADIUS),
			tint
		),
		SheetLine.new(
			Group.REACTIONS, Texts.t(Catalysis.NAMES[Catalysis.Reaction.ARC]),
			Texts.t("%d voisins à %d px") % [Catalysis.arcs(cast), roundi(Catalysis.ARC_REACH)], tint
		),
		SheetLine.new(
			Group.REACTIONS, Texts.t(Catalysis.NAMES[Catalysis.Reaction.CONDUCTION]),
			Texts.t("transit à %d px") % roundi(Catalysis.spread_reach(cast)), tint
		),
	]
	if cast.primer > 0.0:
		out.append(SheetLine.new(Group.REACTIONS, Texts.t("amorce"), Texts.t("un état suffit"), tint))
	return out


## « ×1.15 » : un multiplicateur, pas un accru — il s'applique tel quel à l'effet.
static func _times(factor: float) -> String:
	return "×%.2f" % factor


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
	out.append_array(_requirement_lines(manual, cell, node))
	if spent == 0:
		out.append(_first_point_line())

	out.append_array(_effect_lines(node.mods(maxi(spent, 1))))
	# Ce qu'une transformation de l'arbre ne lit pas, dit avant qu'on paie.
	for other in cell.talents:
		var ignored: Array = Skill.IGNORED_BY_SHAPE.get(other.shape, []) if other.transforms else []
		if node.lines.any(func(l: TalentLine) -> bool: return l.stat in ignored):
			out.append(SheetLine.new(
				Group.EFFECT, Texts.t("sans effet avec"), other.displayed_name(), LOSS
			))
	# Le mot-clé d'arrivée : c'est lui qui fait mordre l'équipement de la nouvelle nature.
	if node.converts:
		out.append(SheetLine.new(
			Group.EFFECT, Texts.t("devient"),
			Keywords.label_of(Skill.KEYWORD_OF_NATURE[node.converts_to]),
			DamageType.COLORS[node.converts_to]
		))
	var subtitle := Texts.t("talent")
	if not node.kind().is_empty():
		subtitle = "%s · %s" % [subtitle, Texts.t(node.kind())]
	return Sheet.new(node.displayed_name(), subtitle, out, node.displayed_description())


## **Tout ce qui manque**, dans l'ordre où `Manual.node_open()` refuse : la compétence,
## puis les liens, dont un seul suffit — le premier « demande », les suivants « ou » —,
## les parents à leurs points, puis les enfants, à un point.
func _requirement_lines(manual: Manual, cell: ManualCell, node: TalentNode) -> Array[SheetLine]:
	var out: Array[SheetLine] = []
	# « dans la compétence » et non son nom, que l'en-tête écrit déjà : il débordait
	# (mesuré par `test_largeurs`).
	if manual.points_of(cell.skill.id) <= 0:
		out.append(SheetLine.new(Group.STATE, Texts.t("demande"), Texts.tn(
			"{points} point dans la compétence", "{points} points dans la compétence", 1
		).format({"points": 1}), MISSING))
	if node.parents.is_empty() or manual.node_open(cell, node):
		return out
	var links := {}
	for parent: String in node.parents:
		links[cell.node_of(parent)] = node.parents[parent]
	for child in cell.talents:
		if child.parents.has(node.id):
			links[child] = 1
	var first := true
	for linked: TalentNode in links:
		out.append(SheetLine.new(
			Group.STATE, Texts.t("demande") if first else Texts.t("ou"),
			# « à 2 » et non « 2 points dans » : la ligne débordait de la fiche (`test_largeurs`).
			Texts.t("« {nom} » à {points}").format({
				"points": links[linked], "nom": linked.displayed_name()
			}), MISSING
		))
		first = false
	return out


## Par la **même fonction que l'infobulle d'un objet**.
func _effect_lines(mods: Array[StatMod]) -> Array[SheetLine]:
	var out: Array[SheetLine] = []
	for m in mods:
		out.append(SheetLine.new(
			Group.EFFECT, StatMod.name(m.stat, m.scope), m.readable_value(),
			LOSS if m.is_loss() else UiPalette.TEXT
		))
	return out


## Une case vide annonce les nombres du premier point.
## **Tout ce que ce lancer peut poser ou déclencher**, avec sa vraie chance : les états
## que tirent les natures de son coup — dégâts ajoutés compris, par `distribution()` —, facteurs du porteur et accru du lancer ajoutés comme au coup
## (`StatusEffects.chance()`), l'état qu'il pose, la pourriture de ses à-coups, la
## charge statique, les charges d'un buff à la mort. Vide pour ce qui ne touche rien.
func _trigger_sheet(skill: Skill) -> Sheet:
	var cast := _player.resolve(skill, maxi(_player.skill_points(skill.id), 1))
	var factors := _player.states.chance_factors
	var shares := cast.distribution()
	var strikes := cast.total_max() > 0.0
	var out: Array[SheetLine] = []

	if strikes:
		out.append(SheetLine.new(
			Group.ON_HIT, Texts.t("coup critique"), _chance(cast.crit_chance), UiPalette.TEXT
		))
		for kind: int in StatusEffects.ROLLED:
			var share: float = shares[StatusEffects.NATURES[kind]]
			if share <= 0.0:
				continue
			var factor := StatusEffects.factor_of(factors[kind], cast.status_chance_increase)
			out.append(SheetLine.new(
				Group.ON_HIT, StatusEffects.name(kind),
				_chance(StatusEffects.chance(share, 0.0, factor)), StatusEffects.color(kind)
			))
			# Le transi et le saignement ont une force, que l'arbre ou un objet accroît :
			# elle se lit dessous.
			if SkillStats.EFFECT_OF.has(kind):
				out.append(SheetLine.new(
					Group.ON_HIT, Texts.t(SkillStats.LABELS[SkillStats.EFFECT_OF[kind]]),
					_times(cast.strength_of(kind)), StatusEffects.color(kind)
				))
		# Ce que rend ou fait chaque ennemi touché (jalon 39).
		for number: String in [SkillStats.KNOCKBACK, SkillStats.LIFE_ON_HIT, SkillStats.MANA_ON_HIT]:
			var value := float(cast.get(number))
			if value > 0.0:
				out.append(SheetLine.new(
					Group.ON_HIT, Texts.t(SkillStats.LABELS[number]), str(snappedf(value, 0.1)),
					UiPalette.TEXT
				))
	var posed := cast.inflicted_state
	if posed >= 0:
		# La malédiction pose son état sur tout son cercle, sans tirage.
		var sure := skill.shape == Skill.Shape.CURSE
		if sure or shares[StatusEffects.NATURES[posed]] > 0.0:
			out.append(SheetLine.new(
				Group.ON_HIT, StatusEffects.name(posed),
				_chance(1.0 if sure else cast.inflict_chance), StatusEffects.color(posed)
			))
	if strikes and _player.stats.static_charge_chance > 0.0:
		out.append(SheetLine.new(
			Group.ON_HIT, Texts.t("charge statique"),
			Texts.t("{chance} sur engourdi").format({
				"chance": _chance(_player.stats.static_charge_chance * 0.01)
			}),
			StatusEffects.color(StatusEffects.Kind.NUMB)
		))

	if posed in StatusEffects.TICKING and shares[StatusEffects.NATURES[posed]] > 0.0:
		var rot := StatusEffects.Kind.ROT
		out.append(SheetLine.new(
			Group.ON_TICK, StatusEffects.name(rot),
			_chance(StatusEffects.tick_rot_chance(factors[rot])), StatusEffects.color(rot)
		))

	# Les charges d'un buff : la Soif de sang à chaque mise à mort d'une attaque, l'Harmonie
	# à chaque sort qui change d'élément (jalon 41).
	for other in _player.available_skills():
		if other.stacks_max <= 0 or not strikes:
			continue
		for buff in other.buffs:
			if other.stack_trigger == Skill.StackTrigger.KILL and cast.keywords.has(Keywords.ATTACK):
				out.append(SheetLine.new(Group.ON_KILL, buff.displayed_name(), _chance(1.0), FULL))
			elif other.stack_trigger == Skill.StackTrigger.ALTERNATION \
					and skill.cadence == Skill.Cadence.CAST:
				out.append(SheetLine.new(
					Group.ON_CAST, buff.displayed_name(), Texts.t("si l'élément change"), FULL
				))

	# Le détail de l'état posé et des créatures levées (jalon 38) : la fiche n'a pas la place.
	if posed >= 0 and skill.strikes():
		out.append_array(_inflicted_lines(cast))
	out.append_array(_summoned_lines(skill, cast))
	if cast.shape == Skill.Shape.CATALYSIS:
		out.append_array(_reaction_lines(cast))

	return Sheet.new(
		skill.displayed_name(), Texts.t("Ce qu'elle peut déclencher"), out,
		Texts.t("Par coup moyen, sur une cible saine. Un coup qui lui retire une grosse part de ses PV pose plus souvent.")
		if strikes else ""
	)


## Une chance, bornée à 100 %.
static func _chance(value: float) -> String:
	return StatMod.percentage(roundi(minf(value, 1.0) * 100.0))


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
## gauche quand la droite manque. `aside` prend l'autre côté : la fiche et ses
## détails encadrent le panneau.
func _sheet_rect(anchor: Rect2, height: float, aside := false) -> Rect2:
	var screen := Vector2(Settings.base_size())
	var right := global_position.x + size.x + SHEET_GAP + SHEET_W <= screen.x
	var x := size.x + SHEET_GAP if right != aside else -SHEET_GAP - SHEET_W
	x = clampf(x, -global_position.x, screen.x - global_position.x - SHEET_W)
	var floor_value := Hud.gauges_top(screen.y) - global_position.y
	var y := minf(anchor.position.y, floor_value - height)
	return Rect2(x, maxf(y, -global_position.y), SHEET_W, height)


## « 3–7 froid », ou « 23 foudre » quand les deux bornes s'arrondissent au même
## nombre.
static func _in_nature(low: float, top: float, nature: int) -> String:
	return "%s %s" % [SkillStats.readable_range(low, top), DamageType.name(nature)]


## « +40 % », par **la même fonction** qu'un objet.
static func _increase(factor: float) -> String:
	return StatMod.value_label("", StatMod.Mode.PERCENT, (factor - 1.0) * 100.0)


func _text(text_value: String, at: Vector2, size_value: int, tint: Color) -> void:
	RichText.draw(self, _font, at, text_value, size_value, tint)
