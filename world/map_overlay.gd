class_name MapOverlay
extends Control

## Carte de la zone EN COURS, superposée au jeu.
##
## Elle ne génère rien : elle peint la grille que la Zone a déjà produite, et y
## place le joueur et les ennemis en temps réel. C'est la différence avec la
## scène de réglage (F3), qui fabrique une carte neuve à chaque fois pour juger
## fill_chance et iterations.

const BACKDROP := Color(0.03, 0.03, 0.04, 0.72)
const WALL_COLOR := Color(0.17, 0.16, 0.21)
const FLOOR_COLOR := Color(0.44, 0.42, 0.38)
const PLAYER_COLOR := Color(0.45, 0.80, 1.00)
const GRUNT_COLOR := Color(0.52, 0.76, 0.33)
const CASTER_COLOR := Color(0.82, 0.47, 0.92)
const OUTLINE := Color(0, 0, 0, 0.9)

## Part de l'écran occupée par la carte.
const FIT := 0.88

var player: Node2D
var enemy_manager: EnemyManager

var _tex: ImageTexture
var _grid := Vector2i.ZERO
var _tile_size := 32


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false


## Reconstruit le fond. À appeler une fois par zone générée, jamais par image :
## repeindre 9216 pixels à 60 Hz ne servirait à rien, la grille ne bouge pas.
func build(gen: MapGenerator, tile_size: int) -> void:
	_grid = Vector2i(gen.width, gen.height)
	_tile_size = tile_size

	var img := Image.create_empty(gen.width, gen.height, false, Image.FORMAT_RGB8)
	for y in gen.height:
		for x in gen.width:
			var floor_here: bool = gen.grid[y][x] == MapGenerator.FLOOR
			img.set_pixel(x, y, FLOOR_COLOR if floor_here else WALL_COLOR)

	_tex = ImageTexture.create_from_image(img)
	queue_redraw()


func _process(_delta: float) -> void:
	# Les marqueurs bougent, le fond non : on ne redessine que quand c'est visible.
	if visible:
		queue_redraw()


func _draw() -> void:
	if _tex == null:
		return

	draw_rect(Rect2(Vector2.ZERO, size), BACKDROP)

	# zoom et non scale : scale est déjà la propriété d'échelle du Control, et
	# la masquer rendrait ce bloc trompeur à la relecture.
	var zoom := _zoom()
	var span := Vector2(_grid) * zoom
	var origin := ((size - span) * 0.5).floor()
	draw_texture_rect(_tex, Rect2(origin, span), false)

	if enemy_manager != null:
		for e in enemy_manager.enemies:
			if is_instance_valid(e) and not e.is_dead:
				_marker(origin, zoom, e.global_position,
					CASTER_COLOR if e is Caster else GRUNT_COLOR, 1.0)

	if player != null:
		_marker(origin, zoom, player.global_position, PLAYER_COLOR, 2.0)


## Échelle entière : à l'échelle fractionnaire les pixels de la carte bavent.
func _zoom() -> float:
	var fit := minf(size.x, size.y) * FIT / float(maxi(_grid.x, _grid.y))
	return maxf(1.0, floorf(fit))


func _marker(origin: Vector2, zoom: float, world_pos: Vector2, color: Color, grow: float) -> void:
	var p := origin + (world_pos / float(_tile_size)) * zoom
	var s := zoom + grow * 2.0
	# Liseré sombre : sans lui un marqueur sur du sol clair devient illisible.
	draw_rect(Rect2(p - Vector2(s, s) * 0.5 - Vector2.ONE, Vector2(s + 2.0, s + 2.0)), OUTLINE)
	draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), color)
