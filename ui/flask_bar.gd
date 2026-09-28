class_name FlaskBar
extends Control

## Les cinq flacons, en bas à gauche, en miroir de la barre de compétences (jalon 32).
## Rangé **avant la fiche** dans `UI` : ouverte, elle les couvre au lieu d'être couverte.
## Les flacons y ont leur taille du sac : une icône taillée à 1:1 ne se rééchantillonne pas.

const PAD := 3.0
const GAP := 3.0
const KEY_H := 10.0
const FONT_SIZE := 8
## Ce qui reste de l'effet, sous le flacon : l'or des choses qui comptent.
const EFFECT := Color(0.95, 0.82, 0.30)
const EFFECT_H := 2.0

var _player: Player
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	set_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED:
		queue_redraw()


func bind(player: Player) -> void:
	_player = player
	player.flasks_changed.connect(_on_flasks_changed)
	player.equipment_changed.connect(queue_redraw)
	# Taille déduite des flacons ; le coin bas-gauche reste celui des ancres.
	var s := bar_size()
	offset_right = offset_left + s.x
	offset_top = offset_bottom - s.y
	queue_redraw()


## Une gorgée coule : la barre d'effet descend à chaque image, et plus rien au repos.
func _on_flasks_changed() -> void:
	set_process(_flowing())
	queue_redraw()


func _process(_delta: float) -> void:
	if not _flowing():
		set_process(false)
	queue_redraw()


func _flowing() -> bool:
	for i in EquipmentSlots.flasks().size():
		var flask := _player.flask_in(i)
		if flask != null and _player.flask_left(flask) > 0.0:
			return true
	return false


static func slot_size() -> Vector2:
	var span := Vector2(ItemBase.GRID_SIZES[ItemBase.FLASK_FAMILY])
	return span * (InventoryPanel.CELL + InventoryPanel.PAD) - Vector2.ONE * InventoryPanel.PAD


static func bar_size() -> Vector2:
	var count := float(EquipmentSlots.flasks().size())
	return Vector2(
		PAD * 2.0 + count * slot_size().x + (count - 1.0) * GAP, PAD + slot_size().y + KEY_H
	)


func _slot_rect(index: int) -> Rect2:
	return Rect2(Vector2(PAD + float(index) * (slot_size().x + GAP), PAD), slot_size())


func _draw() -> void:
	if _player == null or _font == null:
		return
	draw_rect(Rect2(Vector2.ZERO, size), SkillBarPanel.BACKGROUND)
	for i in EquipmentSlots.flasks().size():
		_draw_slot(i)


func _draw_slot(index: int) -> void:
	var r := _slot_rect(index)
	draw_rect(r, SkillBarPanel.EMPTY)
	var flask := _player.flask_in(index)
	if flask != null:
		# La marge du sac : l'icône y a été taillée.
		var icon := SpriteForge.inventory_icon(
			flask.base, Vector2i(r.size) - Vector2i.ONE * InventoryPanel.MARGIN * 2
		)
		draw_texture(icon, (r.get_center() - icon.get_size() * 0.5).round())
		# Ce qui manque voile le haut, comme un flacon qui se vide ; pas de quoi boire,
		# tout le flacon.
		var empty := 1.0 - StatMod.ratio(flask.charges, flask.charges_max())
		if flask.charges < flask.charges_per_use():
			empty = 1.0
		draw_rect(Rect2(r.position, Vector2(r.size.x, roundf(r.size.y * empty))), SkillBarPanel.COOLDOWN)
		var left := _player.flask_left(flask)
		if left > 0.0:
			draw_rect(Rect2(r.position.x, r.end.y - EFFECT_H, roundf(r.size.x * left), EFFECT_H), EFFECT)
	draw_rect(r, UiPalette.BORDER, false, 1.0)

	var key := Keybinds.key_label("flask_%d" % (index + 1))
	if key == Keybinds.UNBOUND:
		return
	draw_string(
		_font, Vector2(r.position.x, r.end.y + KEY_H - 2.0), key,
		HORIZONTAL_ALIGNMENT_CENTER, r.size.x, FONT_SIZE, UiPalette.HINT
	)
