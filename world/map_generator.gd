class_name MapGenerator
extends RefCounted

## Automate cellulaire : des cavernes ouvertes où l'on peut tourner autour des
## ennemis, ponctuées d'obstacles qui cassent les lignes de vue. Un donjon BSP ou
## une marche aléatoire donneraient des couloirs, qui cassent la mêlée.

const WALL := 1
const FLOOR := 0

## Côté d'une case en pixels. Repris de la planche de tuiles, qui est ce qui les
## dessine réellement.
const TILE := TilesetBuilder.TILE

var width: int
var height: int
var fill_chance: float
var iterations: int

var grid: Array = []          # grid[y][x]
var floor_cells: Array[Vector2i] = []

## Nombre de cases de sol supprimées par _keep_largest_region(). Sert au réglage :
## si ce chiffre est énorme, la carte se fragmente en poches isolées.
var pruned_cells: int = 0


func _init(p_width := 96, p_height := 96, p_fill := 0.45, p_iter := 5) -> void:
	width = p_width
	height = p_height
	fill_chance = p_fill
	iterations = p_iter


func generate(rng_seed: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = rng_seed

	_noise_fill(rng)
	for i in iterations:
		_smooth()
	_keep_largest_region()
	_collect_floor_cells()


## Bruit initial. Les bords sont forcés en mur pour fermer la zone.
func _noise_fill(rng: RandomNumberGenerator) -> void:
	grid = []
	for y in height:
		var row := []
		for x in width:
			var is_border := x < 2 or y < 2 or x >= width - 2 or y >= height - 2
			row.append(WALL if is_border or rng.randf() < fill_chance else FLOOR)
		grid.append(row)


## Règle 4-5 : un mur reste mur s'il a ≥4 voisins murs,
## un sol devient mur s'il a ≥5 voisins murs.
func _smooth() -> void:
	var next := []
	for y in height:
		var row := []
		for x in width:
			var walls := _count_wall_neighbours(x, y)
			if grid[y][x] == WALL:
				row.append(WALL if walls >= 4 else FLOOR)
			else:
				row.append(WALL if walls >= 5 else FLOOR)
		next.append(row)
	grid = next


## Une case est-elle dans la grille ? Le seul endroit qui l'écrit : une inégalité
## inversée donne ici un accès hors tableau, pas un refus.
func in_bounds(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < width and cell.y < height


func _count_wall_neighbours(cx: int, cy: int) -> int:
	var count := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x := cx + dx
			var y := cy + dy
			# Hors grille = mur : ça referme naturellement les bords.
			#
			# Seul endroit qui n'appelle pas in_bounds, et c'est mesuré : la boucle
			# tourne 370 000 fois par carte, et l'appel plus la construction du
			# Vector2i font passer la génération de 78,8 à 126,4 ms.
			if x < 0 or y < 0 or x >= width or y >= height or grid[y][x] == WALL:
				count += 1
	return count


## Étape indispensable : l'automate produit des poches isolées.
## On garde la plus grande et on bouche le reste.
func _keep_largest_region() -> void:
	var visited := {}
	var best: Array[Vector2i] = []
	var total_floor := 0

	for y in height:
		for x in width:
			var key := Vector2i(x, y)
			if grid[y][x] != FLOOR or visited.has(key):
				continue
			var region := _flood_fill(key, visited)
			total_floor += region.size()
			if region.size() > best.size():
				best = region

	var keep := {}
	for c in best:
		keep[c] = true

	for y in height:
		for x in width:
			if grid[y][x] == FLOOR and not keep.has(Vector2i(x, y)):
				grid[y][x] = WALL

	pruned_cells = total_floor - best.size()


func _flood_fill(start: Vector2i, visited: Dictionary) -> Array[Vector2i]:
	var region: Array[Vector2i] = []
	var queue: Array[Vector2i] = [start]
	visited[start] = true

	const NEIGHBOURS := [
		Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)
	]

	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		region.append(cell)
		for offset in NEIGHBOURS:
			var n: Vector2i = cell + offset
			if not in_bounds(n):
				continue
			if visited.has(n) or grid[n.y][n.x] != FLOOR:
				continue
			visited[n] = true
			queue.append(n)

	return region


func _collect_floor_cells() -> void:
	floor_cells.clear()
	for y in height:
		for x in width:
			if grid[y][x] == FLOOR:
				floor_cells.append(Vector2i(x, y))


## Point d'apparition : la case de sol la plus proche du centre de la carte.
func get_spawn_cell() -> Vector2i:
	# Un fill_chance trop élevé peut ne laisser aucun sol du tout.
	if floor_cells.is_empty():
		return Vector2i(width / 2, height / 2)

	var center := Vector2i(width / 2, height / 2)
	var best := floor_cells[0]
	var best_dist := 1 << 30
	for c in floor_cells:
		var d: int = (c - center).length_squared()
		if d < best_dist:
			best_dist = d
			best = c
	return best


## Le centre d'une case, en pixels. Le demi-décalage est la seule subtilité, et
## c'est le seul endroit qui l'écrit.
static func cell_center(cell: Vector2i) -> Vector2:
	return (Vector2(cell) + Vector2(0.5, 0.5)) * float(TILE)


## La conversion inverse : dans quelle case tombe ce point.
static func cell_at(pos: Vector2) -> Vector2i:
	return Vector2i((pos / float(TILE)).floor())


## La grille peinte en image, un pixel par case — la carte superposée du jeu et
## l'écran de réglage y passent tous deux. Les couleurs restent à l'appelant : les
## deux écrans ne se ressemblent pas et n'ont pas à partager leur palette.
func to_image(floor_color: Color, wall_color: Color) -> Image:
	var img := Image.create_empty(width, height, false, Image.FORMAT_RGB8)
	for y in height:
		for x in width:
			img.set_pixel(x, y, floor_color if grid[y][x] == FLOOR else wall_color)
	return img


func is_walkable(cell: Vector2i) -> bool:
	return in_bounds(cell) and grid[cell.y][cell.x] == FLOOR
