class_name PassiveTreePanel
extends Control

## L'arbre de passifs (P), plein cadre. Glisser déplace la vue, la molette la zoome ;
## clic gauche prend, clic droit reprend, comme sur la page d'un manuel. Les règles sont
## dans `PassiveTree` : ce panneau n'en vérifie aucune, il colore ce qu'elles répondent.

const PAD := 6.0
const HEADER := 15.0
const FONT_SIZE := 8
const TITLE_SIZE := 9

## Pixels par case de la grille de l'arbre au cran normal.
const UNIT := 10.0
## Les crans de la molette, qui multiplient `UNIT` et les rayons. Au cran large tout
## l'arbre tient, sans icônes : réduites, elles tourneraient au gris. Le troisième
## anneau du jalon 19 porte l'arbre à 91 cases de haut, soit 319 px au cran large
## contre 360 de cadre : 0,5 n'en montrait plus que les deux tiers.
const ZOOMS: Array[float] = [0.35, 1.0, 1.5]
const DEFAULT_ZOOM := 1
## De quoi loger l'icône de 9 pixels de `PassiveIcon`.
const SMALL_RADIUS := 6.0
const NOTABLE_RADIUS := 8.0
const KEYSTONE_RADIUS := 11.0
## Ce qui distingue un glissement d'un clic, en pixels.
const DRAG_THRESHOLD := 3.0

const TIP_W := 160.0
const TIP_PAD := 5.0
const TIP_LINE := 9.0
const TIP_GAP := 8.0

const NODE_BACKGROUND := Color(0.14, 0.13, 0.18)

var _player: Player
var _font: Font
## Le déplacement de la vue ; nul à l'ouverture, le départ au centre.
var _pan := Vector2.ZERO
var _zoom_index := DEFAULT_ZOOM
var _mouse := Vector2.INF
## Là où le bouton gauche s'est enfoncé, INF sinon.
var _pressed_at := Vector2.INF
var _dragging := false


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_font = ThemeDB.fallback_font
	# Au plus proche voisin : lissées, les icônes tourneraient au gris.
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


## Sans garde : effacer une prise absente ne coûte rien (voir `Game.grab_ui_input`).
func _exit_tree() -> void:
	Game.grab_ui_input(self, false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func bind(player: Player) -> void:
	_player = player
	player.passives_changed.connect(queue_redraw)


func toggle() -> void:
	visible = not visible
	Game.grab_ui_input(self, visible)
	mouse_filter = Control.MOUSE_FILTER_STOP if visible else Control.MOUSE_FILTER_IGNORE
	_pan = Vector2.ZERO
	_zoom_index = DEFAULT_ZOOM
	_pressed_at = Vector2.INF
	_dragging = false
	_mouse = get_local_mouse_position() if visible else Vector2.INF
	queue_redraw()


## Publiques : le test clique là où le nœud est dessiné.
func screen_position(n: PassiveNode) -> Vector2:
	return size * 0.5 + _pan + Vector2(n.position) * UNIT * _zoom()


func node_at(point: Vector2) -> PassiveNode:
	for n in _player.passive_tree.nodes:
		if screen_position(n).distance_to(point) <= _radius(n) + 2.0 * _zoom():
			return n
	return null


## Garde le centre du cadre : zoomer sur le curseur demanderait un point d'ancrage, et
## le glissement recadre déjà.
func zoom_by(steps: int) -> void:
	var before := _zoom()
	_zoom_index = clampi(_zoom_index + steps, 0, ZOOMS.size() - 1)
	_pan *= _zoom() / before
	queue_redraw()


func _zoom() -> float:
	return ZOOMS[_zoom_index]


func _gui_input(event: InputEvent) -> void:
	if _player == null:
		return
	var motion := event as InputEventMouseMotion
	if motion != null:
		_mouse = motion.position
		if _pressed_at != Vector2.INF and (
			_dragging or _pressed_at.distance_to(motion.position) > DRAG_THRESHOLD
		):
			_dragging = true
			_pan += motion.relative
		queue_redraw()
		accept_event()
		return

	var button := event as InputEventMouseButton
	if button == null:
		return
	# Au relâchement : un glissement ne prend rien.
	if button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_pressed_at = button.position
			_dragging = false
		else:
			var n := node_at(button.position)
			if not _dragging and n != null:
				_player.take_passive(n.id)
			_pressed_at = Vector2.INF
			_dragging = false
	elif button.button_index == MOUSE_BUTTON_RIGHT and button.pressed:
		var n := node_at(button.position)
		if n != null:
			_player.release_passive(n.id)
	elif button.button_index == MOUSE_BUTTON_WHEEL_UP and button.pressed:
		zoom_by(1)
	elif button.button_index == MOUSE_BUTTON_WHEEL_DOWN and button.pressed:
		zoom_by(-1)
	queue_redraw()
	accept_event()


func _draw() -> void:
	if _player == null or _font == null:
		return
	var tree := _player.passive_tree
	draw_rect(Rect2(Vector2.ZERO, size), UiPalette.BACK_FULL)

	for n in tree.nodes:
		for other_id in n.links:
			var other := tree.node(other_id)
			if other == null:
				continue
			var lit := _is_taken(n) and _is_taken(other)
			draw_line(
				screen_position(n), screen_position(other),
				ManualPanel.LINK_BRIGHT if lit else ManualPanel.LINK, 1.0
			)
	for n in tree.nodes:
		_draw_node(n)

	var remaining_all := _player.remaining_passive_points()
	draw_string(
		_font, Vector2(PAD, HEADER - 3.0),
		Texts.tn(
			"ARBRE DE PASSIFS  —  {points} point restant",
			"ARBRE DE PASSIFS  —  {points} points restants", remaining_all
		).format({"points": remaining_all}),
		HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE,
		ManualPanel.OPEN if remaining_all > 0 else UiPalette.TITLE
	)
	draw_string(
		_font, Vector2(PAD, HEADER + TIP_LINE),
		Texts.t("[clic] prendre     [clic droit] reprendre     [glisser] déplacer     [molette] zoomer     P pour fermer"),
		HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, UiPalette.HINT
	)

	var hovered := node_at(_mouse) if _mouse != Vector2.INF and not _dragging else null
	if hovered != null:
		_draw_tip(hovered)


func _is_taken(n: PassiveNode) -> bool:
	return n.kind == PassiveNode.Kind.START or n.id in _player.passives


## Les couleurs d'état des manuels : pris, à prendre, voisin sans point, hors d'atteinte.
func _tint(n: PassiveNode) -> Color:
	if _is_taken(n):
		return ManualPanel.FULL
	var tree := _player.passive_tree
	if tree.can_take(_player.passives, n.id, _player.level):
		return ManualPanel.OPEN
	# Le même test avec un point de plus : voisin, mais rien pour payer.
	if tree.can_take(_player.passives, n.id, _player.passives.size() + 2):
		return ManualPanel.WAIT
	return ManualPanel.LOCK


func _radius(n: PassiveNode) -> float:
	match n.kind:
		PassiveNode.Kind.NOTABLE, PassiveNode.Kind.START:
			return NOTABLE_RADIUS * _zoom()
		PassiveNode.Kind.KEYSTONE:
			return KEYSTONE_RADIUS * _zoom()
	return SMALL_RADIUS * _zoom()


func _draw_node(n: PassiveNode) -> void:
	var at := screen_position(n).round()
	var r := _radius(n)
	var tint := _tint(n)
	# Le fond dit ce que fait le nœud, plus vif une fois pris ; le liseré dit son état.
	var look := PassiveIcon.look_of(n)
	var fill := NODE_BACKGROUND
	if not look.is_empty():
		fill = (look[1] as Color).darkened(0.4 if _is_taken(n) else 0.75)
	if n.kind == PassiveNode.Kind.KEYSTONE:
		var diamond := PackedVector2Array([
			at + Vector2(0, -r), at + Vector2(r, 0), at + Vector2(0, r), at + Vector2(-r, 0), at + Vector2(0, -r)
		])
		draw_colored_polygon(diamond, fill)
		draw_polyline(diamond, tint, 1.0)
	else:
		draw_circle(at, r, fill)
		draw_arc(at, r, 0.0, TAU, 20, tint, 1.0)
	var icon := PassiveIcon.texture(n) if _zoom_index > 0 else null
	if icon != null:
		# Éteinte hors d'atteinte : l'œil va d'abord à ce qu'on peut prendre.
		var shade := Color(1, 1, 1, 0.45) if tint == ManualPanel.LOCK else Color.WHITE
		draw_texture(icon, at - Vector2(Vector2i(icon.get_size()) / 2), shade)


## Le nom s'il en a un, puis chaque ligne par `StatMod.label()`, comme un objet.
func _draw_tip(n: PassiveNode) -> void:
	var lines := PackedStringArray()
	for m in n.mods():
		for piece in RichText.fold(_font, m.label(), TIP_W - TIP_PAD * 2.0, FONT_SIZE):
			lines.append(piece)
	var named := not n.name.is_empty()
	if lines.is_empty() and not named:
		return

	var h := TIP_PAD * 2.0 + TIP_LINE * float(lines.size() + (1 if named else 0))
	var floor_value := Hud.gauges_top(size.y) - PAD
	var at := screen_position(n) + Vector2(_radius(n) + TIP_GAP, -TIP_LINE)
	var r := Rect2(
		Vector2(clampf(at.x, PAD, size.x - PAD - TIP_W), clampf(at.y, PAD, floor_value - h)),
		Vector2(TIP_W, h)
	)
	draw_rect(r, UiPalette.TIP_BACK)
	draw_rect(r, UiPalette.BORDER, false, 1.0)

	var y := r.position.y + TIP_PAD + TIP_LINE - 2.0
	if named:
		draw_string(
			_font, Vector2(r.position.x + TIP_PAD, y), n.displayed_name(),
			HORIZONTAL_ALIGNMENT_LEFT, -1, TITLE_SIZE, UiPalette.TEXT
		)
		y += TIP_LINE
	for line in lines:
		RichText.draw(self, _font, Vector2(r.position.x + TIP_PAD, y), line, FONT_SIZE, UiPalette.TEXT)
		y += TIP_LINE
	GlossaryBoxes.draw(self, _font, r, r, lines)
