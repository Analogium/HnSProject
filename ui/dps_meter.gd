class_name DpsMeter
extends Control

## Ce que le joueur a infligé ces `WINDOW` dernières secondes, en une ligne ; un clic
## la déplie en une ligne par compétence et par état qu'elle fait brûler, de la plus
## forte à la plus faible. Se déplace
## à la souris, et sa place survit à la fermeture (`Settings.dps_meter_position`).

## Ce qui frappe sans lancer — la charge statique.
const OTHER := "Autres"

const WINDOW := 5.0
## Une somme par nom et par tranche, pas un événement par coup : une brûlure en émet
## un par ennemi et par image. Repeint à chaque tranche seulement — des chiffres qui
## changent à chaque image ne se lisent pas.
const SLICE := 0.5
## `WINDOW / SLICE` tranches pleines, plus celle qui se remplit.
const SLICES := int(WINDOW / SLICE) + 1

const WIDTH := 140.0
const ROW := 10.0
## Une ligne de compétence porte son icône, réduite de moitié : `SkillIcon.SIDE` / 2.
const ICON := SkillIcon.SIDE / 2.0
const SKILL_ROW := ICON + 1.0
const PAD := 3.0
const MAX_ROWS := 8
## En deçà, un appui est un clic qui déplie ; au-delà, un déplacement.
const DRAG_THRESHOLD := 3.0

var _slices: Array[Dictionary] = [{}]
var _clock := 0.0
var _expanded := false
## Clé « compétence/état » → DPS, relus à chaque tranche ; `_sources` range les clés du
## plus fort au plus faible. Le coup d'une compétence et chaque état qu'elle fait
## brûler sont des lignes distinctes.
var _dps := {}
var _sources: Array = []
## Clé → `Source`, construite une fois : le catalogue se parcourt, il ne s'indexe pas.
var _named := {}
var _total := 0.0
var _press := Vector2.ZERO
var _grab := Vector2.ZERO
var _dragged := false
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_STOP
	# Le joueur sonde ses touches hors de l'arbre d'entrées : sans ça, cliquer sur la
	# fenêtre lancerait la première case.
	mouse_entered.connect(Game.grab_ui_input.bind(self, true))
	mouse_exited.connect(Game.grab_ui_input.bind(self, false))
	Game.damage_dealt.connect(_on_damage_dealt)
	Settings.changed.connect(_apply_settings)
	_apply_settings()


func _exit_tree() -> void:
	Game.grab_ui_input(self, false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func _apply_settings() -> void:
	visible = Settings.dps_meter_visible
	set_process(visible)
	if not visible:
		Game.grab_ui_input(self, false)
	_fit(Settings.dps_meter_position)


func _on_damage_dealt(skill_id: String, kind: int, amount: float) -> void:
	if not visible:
		return
	var key := "%s/%d" % [skill_id, kind]
	if not _named.has(key):
		_named[key] = Source.new(skill_id, kind)
	_slices[-1][key] = _slices[-1].get(key, 0.0) + amount


func _process(delta: float) -> void:
	_clock += delta
	if _clock < SLICE:
		return
	while _clock >= SLICE:
		_clock -= SLICE
		_slices.push_back({})
		if _slices.size() > SLICES:
			_slices.pop_front()
	_refresh()


## Juste après un changement de tranche, la dernière est vide : la somme porte sur
## exactement `WINDOW` secondes pleines.
func _refresh() -> void:
	_dps.clear()
	_total = 0.0
	for slice in _slices:
		for source: String in slice:
			_dps[source] = _dps.get(source, 0.0) + slice[source] / WINDOW
			_total += slice[source] / WINDOW
	_sources = _dps.keys()
	_sources.sort_custom(func(a: String, b: String) -> bool: return _dps[a] > _dps[b])
	_fit(position)
	queue_redraw()


## Bornée à l'écran et au-dessus des jauges (`Hud.gauges_top`), qui passeraient devant.
func _fit(at: Vector2) -> void:
	var rows := mini(_sources.size(), MAX_ROWS) if _expanded else 0
	size = Vector2(WIDTH, PAD * 2.0 + ROW + SKILL_ROW * rows)
	var screen := get_viewport_rect().size
	position = Vector2(
		clampf(at.x, 0.0, screen.x - size.x),
		clampf(at.y, 0.0, Hud.gauges_top(screen.y) - size.y)
	)


func _gui_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_press = button.global_position
			_grab = position
			_dragged = false
		elif _dragged:
			Settings.dps_meter_position = position
		else:
			_expanded = not _expanded
			_fit(position)
			queue_redraw()
		accept_event()
		return
	var motion := event as InputEventMouseMotion
	if motion != null and motion.button_mask & MOUSE_BUTTON_MASK_LEFT:
		var shift := motion.global_position - _press
		if _dragged or shift.length() > DRAG_THRESHOLD:
			_dragged = true
			_fit(_grab + shift)
		accept_event()


func _draw() -> void:
	var frame := Rect2(Vector2.ZERO, size)
	draw_rect(frame, Hud.BACK)
	draw_rect(frame, Hud.EDGE, false, 1.0)
	_text(PAD + Hud.VALUE_SIZE, PAD, ("- " if _expanded else "+ ") + "DPS", _total)
	if not _expanded:
		return
	for i in mini(_sources.size(), MAX_ROWS):
		var source: Source = _named[_sources[i]]
		var top := PAD + ROW + SKILL_ROW * i
		if source.skill != null:
			SkillIcon.draw_into(self, Rect2(PAD, top, ICON, ICON), source.skill)
		_text(
			top + (SKILL_ROW + Hud.VALUE_SIZE) / 2.0, PAD + ICON + 3.0, source.label(),
			_dps[_sources[i]], source.tint()
		)


## Le nom à partir de `left`, la valeur contre le bord droit.
func _text(
	baseline: float, left: float, text: String, value: float, tint := Hud.LABEL_COLOR
) -> void:
	Hud.outlined(
		self, _font, Vector2(left, baseline), text, HORIZONTAL_ALIGNMENT_LEFT,
		int(WIDTH - PAD - left), tint
	)
	Hud.outlined(
		self, _font, Vector2(PAD, baseline), str(roundi(value)), HORIZONTAL_ALIGNMENT_RIGHT,
		int(WIDTH - PAD * 2.0), Hud.LABEL_COLOR
	)


## Une ligne du compteur : la compétence et, pour ce qui brûle, l'état.
class Source:
	var skill: Skill
	var kind: int

	func _init(skill_id: String, p_kind: int) -> void:
		skill = SkillCatalog.by_id(skill_id)
		kind = p_kind

	func label() -> String:
		if kind != Game.HIT:
			return Texts.t(StatusEffects.BURN_NAMES.get(kind, ""))
		return Texts.t(skill.name) if skill != null else Texts.t(DpsMeter.OTHER)

	## Un état dans sa couleur : c'est ce qui le distingue du coup de la même icône.
	func tint() -> Color:
		return StatusEffects.color(kind) if kind != Game.HIT else Hud.LABEL_COLOR
