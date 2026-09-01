extends Node2D

## Arène de test des étapes 3 à 5 : quelques murs, des mannequins, et un
## panneau de réglage à chaud.
##
## L'étape 5 du document est la plus importante du jalon : c'est ici qu'on
## décide si taper est agréable. Les valeurs se règlent en jeu, puis se
## recopient à la main dans player_stats.tres / player.tscn une fois trouvées.

const DUMMY_SCENE := preload("res://actors/dummy/training_dummy.tscn")

const ARENA_SIZE := Vector2(640, 480)
const WALL_THICKNESS := 16.0
const WALL_COLOR := Color(0.16, 0.15, 0.19)

## Obstacles intérieurs, en coordonnées monde.
const PILLARS := [
	Rect2(140, 120, 48, 48),
	Rect2(452, 120, 48, 48),
	Rect2(140, 312, 48, 48),
	Rect2(452, 312, 48, 48),
	Rect2(296, 216, 48, 48),
]

const DUMMY_POSITIONS := [
	Vector2(240, 160),
	Vector2(400, 160),
	Vector2(240, 320),
	Vector2(400, 320),
	Vector2(320, 110),
]

@onready var walls: Node2D = $Walls
@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player
@onready var overlay: Label = $UI/Overlay

var _dummies: Array[TrainingDummy] = []


func _ready() -> void:
	_build_walls()
	_spawn_dummies()
	player.global_position = ARENA_SIZE * 0.5


func _process(_delta: float) -> void:
	if overlay.visible:
		overlay.text = _overlay_text()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	match (event as InputEventKey).keycode:
		KEY_1: Game.hit_stop_duration = maxf(Game.hit_stop_duration - 0.01, 0.0)
		KEY_2: Game.hit_stop_duration = minf(Game.hit_stop_duration + 0.01, 0.30)
		KEY_3: player.stats.knockback_force = maxf(player.stats.knockback_force - 20.0, 0.0)
		KEY_4: player.stats.knockback_force += 20.0
		KEY_5: player.swing_duration = maxf(player.swing_duration - 0.01, 0.02)
		KEY_6: player.swing_duration += 0.01
		KEY_7: player.stats.attack_cooldown = maxf(player.stats.attack_cooldown - 0.05, 0.05)
		KEY_8: player.stats.attack_cooldown += 0.05
		KEY_9: player.shake_amount = maxf(player.shake_amount - 1.0, 0.0)
		KEY_0: player.shake_amount += 1.0
		KEY_R: _reset_dummies()
		KEY_TAB: overlay.visible = not overlay.visible
		_: return

	get_viewport().set_input_as_handled()


func _overlay_text() -> String:
	return "\n".join([
		"[1/2] hit-stop        %.2f s" % Game.hit_stop_duration,
		"[3/4] knockback       %.0f" % player.stats.knockback_force,
		"[5/6] duree swing     %.2f s" % player.swing_duration,
		"[7/8] cooldown        %.2f s" % player.stats.attack_cooldown,
		"[9/0] shake camera    %.0f" % player.shake_amount,
		"[R] reset cibles   [TAB] masquer",
	])


## Murs construits par code : plus simple à retoucher qu'une scène pleine de
## noeuds, et de toute facon ils disparaitront a l'etape 9 (TileMapLayer).
func _build_walls() -> void:
	var t := WALL_THICKNESS
	var borders := [
		Rect2(0, 0, ARENA_SIZE.x, t),                          # haut
		Rect2(0, ARENA_SIZE.y - t, ARENA_SIZE.x, t),           # bas
		Rect2(0, 0, t, ARENA_SIZE.y),                          # gauche
		Rect2(ARENA_SIZE.x - t, 0, t, ARENA_SIZE.y),           # droite
	]
	for rect: Rect2 in borders:
		walls.add_child(_make_wall(rect))
	for rect: Rect2 in PILLARS:
		walls.add_child(_make_wall(rect))


func _make_wall(rect: Rect2) -> StaticBody2D:
	var body := StaticBody2D.new()
	body.collision_layer = 1   # décor
	body.collision_mask = 0
	body.position = rect.position + rect.size * 0.5

	var shape := RectangleShape2D.new()
	shape.size = rect.size
	var col := CollisionShape2D.new()
	col.shape = shape
	body.add_child(col)

	var visual := ColorRect.new()
	visual.color = WALL_COLOR
	visual.position = -rect.size * 0.5
	visual.size = rect.size
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(visual)

	return body


func _spawn_dummies() -> void:
	for pos: Vector2 in DUMMY_POSITIONS:
		var dummy: TrainingDummy = DUMMY_SCENE.instantiate()
		dummy.position = pos
		entities.add_child(dummy)
		_dummies.append(dummy)


func _reset_dummies() -> void:
	for d in _dummies:
		if is_instance_valid(d):
			d.reset()
