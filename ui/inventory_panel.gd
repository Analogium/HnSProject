class_name InventoryPanel
extends Control

## L'inventaire, à la touche I. Une grille de cases qui montre ce qu'on a
## ramassé — rien de plus pour l'instant : ni glisser-déposer, ni équipement,
## ni tri. C'est la boucle « ça tombe, je le ramasse, je le vois » qu'on valide.
##
## Il lit la liste du joueur au lieu d'en tenir une copie : deux listes à tenir
## d'accord finissent toujours par diverger.

const COLS := 6
const ROWS := 4
const CELL := 26.0
const PAD := 2.0

const BACK := Color(0.082, 0.075, 0.106, 0.97)
const BORDER := Color(0.29, 0.27, 0.35)
const SLOT := Color(0.14, 0.13, 0.17)
const SLOT_EDGE := Color(0.22, 0.20, 0.26)

@onready var title: Label = $Title

var _player: Player


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


func bind(player: Player) -> void:
	_player = player
	player.inventory_changed.connect(_on_changed)
	_on_changed()


func toggle() -> void:
	visible = not visible
	if visible:
		_on_changed()


func _on_changed() -> void:
	if _player != null:
		title.text = "SAC  %d / %d" % [_player.inventory.size(), Player.INVENTORY_SIZE]
	if visible:
		queue_redraw()


func _panel_size() -> Vector2:
	return Vector2(
		COLS * CELL + PAD * (COLS + 1),
		ROWS * CELL + PAD * (ROWS + 1) + 16.0
	)


func _draw() -> void:
	var s := _panel_size()
	draw_rect(Rect2(Vector2.ZERO, s), BACK)
	draw_rect(Rect2(Vector2.ZERO, s), BORDER, false, 1.0)

	for i in COLS * ROWS:
		var col := i % COLS
		var row := i / COLS
		var at := Vector2(
			PAD + float(col) * (CELL + PAD),
			16.0 + PAD + float(row) * (CELL + PAD)
		)
		draw_rect(Rect2(at, Vector2(CELL, CELL)), SLOT)
		draw_rect(Rect2(at, Vector2(CELL, CELL)), SLOT_EDGE, false, 1.0)

		if _player == null or i >= _player.inventory.size():
			continue
		var item: ItemData = _player.inventory[i]
		var tex := SpriteForge.weapon_icon(item.kind)
		# Centrée dans la case : l'icône fait 24 px, la case 26.
		draw_texture(tex, at + (Vector2(CELL, CELL) - tex.get_size()) * 0.5)
