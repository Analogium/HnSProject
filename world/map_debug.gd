extends Node2D

## Affichage debug de l'étape 8. Le but est de régler fill_chance et iterations
## AVANT de brancher le TileSet, donc tout se règle à chaud.
##
## Écart avec le document, qui dit « des ColorRect suffisent » : une grille
## 96 × 96 ferait 9216 nœuds à reconstruire à chaque frappe de touche, ce qui
## rendrait l'outil trop lent pour ce à quoi il sert. On peint une Image d'un
## pixel par case, affichée en filtrage Nearest — c'est instantané.

const MAP_SIZE := 96

const WALL_COLOR := Color(0.13, 0.12, 0.16)
const FLOOR_COLOR := Color(0.44, 0.42, 0.38)
const SPAWN_COLOR := Color(0.35, 0.75, 1.0)

@onready var view: TextureRect = $UI/View
@onready var overlay: Label = $UI/Overlay

var gen: MapGenerator

var _seed := 0
var _fill := 0.45
var _iterations := 5
var _gen_ms := 0.0


func _ready() -> void:
	_regenerate(Game.rng.randi())


func _unhandled_input(event: InputEvent) -> void:
	var touche := Touches.enfoncee(event)
	if touche == KEY_NONE:
		return

	# Retenu avant le match : un changement de scène détache ce nœud de l'arbre
	# et get_viewport() renverrait null.
	var vp := get_viewport()

	match touche:
		KEY_1: _fill = maxf(_fill - 0.01, 0.30); _regenerate(_seed)
		KEY_2: _fill = minf(_fill + 0.01, 0.60); _regenerate(_seed)
		KEY_3: _iterations = maxi(_iterations - 1, 0); _regenerate(_seed)
		KEY_4: _iterations = mini(_iterations + 1, 12); _regenerate(_seed)
		# Le niveau de la zone, posé sur l'autoload et lu par la zone au moment
		# d'y entrer. Ici parce que c'est déjà l'endroit d'où l'on règle une zone
		# avant d'y entrer ; un menu ailleurs pour un réglage provisoire, ce
		# serait deux interfaces à retirer le jour où la carte du monde arrivera.
		KEY_5: Game.changer_niveau_de_zone(-1); _update_overlay()
		KEY_6: Game.changer_niveau_de_zone(1); _update_overlay()
		KEY_7: Game.changer_niveau_de_zone(-10); _update_overlay()
		KEY_8: Game.changer_niveau_de_zone(10); _update_overlay()
		KEY_R: _regenerate(Game.rng.randi())
		KEY_SPACE: _regenerate(_seed)   # même graine : vérifie le déterminisme
		KEY_H: overlay.visible = not overlay.visible
		KEY_F1: Game.goto_scene("res://world/zone.tscn")
		KEY_F2: Game.goto_scene("res://world/test_arena.tscn")
		# La touche qui a ouvert l'aperçu le referme, et Échap aussi.
		KEY_F3, KEY_ESCAPE: Game.go_back()
		_: return

	vp.set_input_as_handled()


func _regenerate(rng_seed: int) -> void:
	_seed = rng_seed
	gen = MapGenerator.new(MAP_SIZE, MAP_SIZE, _fill, _iterations)

	var t0 := Time.get_ticks_usec()
	gen.generate(_seed)
	_gen_ms = float(Time.get_ticks_usec() - t0) / 1000.0

	_paint()
	_update_overlay()


func _paint() -> void:
	var img := gen.to_image(FLOOR_COLOR, WALL_COLOR)

	# Croix sur le point d'apparition, pour vérifier qu'il tombe bien sur du sol.
	var s := gen.get_spawn_cell()
	for d in range(-2, 3):
		_plot(img, s + Vector2i(d, 0))
		_plot(img, s + Vector2i(0, d))

	view.texture = ImageTexture.create_from_image(img)


func _plot(img: Image, cell: Vector2i) -> void:
	if not gen.in_bounds(cell):
		return
	img.set_pixel(cell.x, cell.y, SPAWN_COLOR)


func _update_overlay() -> void:
	var total := gen.width * gen.height
	var ratio := 100.0 * float(gen.floor_cells.size()) / float(total)
	overlay.text = "\n".join([
		"[1/2] fill_chance   %.2f" % gen.fill_chance,
		"[3/4] iterations    %d" % gen.iterations,
		"[5/6] [7/8] niveau  %d" % Game.niveau_de_zone,
		"      ennemis et butin",
		"",
		"sol            %d cases (%.0f %%)" % [gen.floor_cells.size(), ratio],
		"poches jetees  %d cases" % gen.pruned_cells,
		"generation     %.1f ms" % _gen_ms,
		"graine         %d" % _seed,
		"",
		"[R] nouvelle graine  [ESPACE] regenerer",
		"[H] masquer",
		"",
		"[F3] ou [ECHAP] revenir",
		"[F1] zone jouable   [F2] arene de reglage",
	])
