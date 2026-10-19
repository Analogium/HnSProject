class_name Terrain
extends RefCounted

## Le relief d'une zone (jalon 54, étape 3) : plat sur le praticable, en falaise sur le reste,
## un seul maillage tiré de la grille de `MapGenerator`. Il ne fait que se voir : les collisions
## restent les boîtes des murs (`Zone._wall_run`), le gameplay ne bouge pas.
##
## La hauteur d'un point se lit sur sa distance au praticable : la falaise monte dès le bord,
## raide, puis le dessus ondule. Le pied ne déborde jamais sur une case de sol.

## Un sommet tous les STEP px : quatre par case.
const STEP := 8.0
## Le haut des falaises, en pixels du monde (16 px = 1 m).
const CLIFF := 40.0
## La largeur sur laquelle la falaise monte, depuis son pied.
const RISE := 14.0
## Le pied recule d'au plus FOOT px dans la case de mur : un bord droit trahit la grille.
const FOOT := 6.0
## Les bosses du dessus, en plus ou en moins.
const BUMP := 10.0
## Les cases de mur ajoutées autour de la carte ; au-delà, le dessus des falaises continue
## à plat jusqu'à BEYOND px : la caméra montrait le fond.
const MARGIN := 4
const BEYOND := 640.0

var mesh: ArrayMesh
## Le coin de la grille des hauteurs, en pixels du monde, et son pas en sommets.
var _origin: Vector2
var _columns: int
var _rows: int
var _heights: PackedFloat32Array


static func build(map: MapGenerator, seed: int) -> Terrain:
	var terrain := Terrain.new()
	terrain._shape(map, seed)
	terrain._mesh()
	return terrain


## La hauteur du relief en ce point du plan, entre les sommets.
func height_at(point: Vector3) -> float:
	var at := (Flat.xz(point) - _origin) / STEP
	var i := clampi(int(at.x), 0, _columns - 2)
	var j := clampi(int(at.y), 0, _rows - 2)
	var f := (at - Vector2(i, j)).clamp(Vector2.ZERO, Vector2.ONE)
	var top := lerpf(_height(i, j), _height(i + 1, j), f.x)
	var bottom := lerpf(_height(i, j + 1), _height(i + 1, j + 1), f.x)
	return lerpf(top, bottom, f.y)


func _height(i: int, j: int) -> float:
	return _heights[j * _columns + i]


func _shape(map: MapGenerator, seed: int) -> void:
	var per_cell := int(MapGenerator.TILE / STEP)
	_columns = (map.width + MARGIN * 2) * per_cell + 1
	_rows = (map.height + MARGIN * 2) * per_cell + 1
	_origin = -Vector2.ONE * MARGIN * MapGenerator.TILE
	var distance := _distances(map, per_cell)
	var noise := FastNoiseLite.new()
	noise.seed = seed
	noise.frequency = 0.02
	noise.fractal_octaves = 3
	_heights.resize(_columns * _rows)
	for j in _rows:
		for i in _columns:
			var d := distance[j * _columns + i]
			# Le sol reste plat, sans tirage : c'est la plus grande part des sommets.
			if d == 0.0:
				continue
			var x := _origin.x + i * STEP
			var z := _origin.y + j * STEP
			var foot := 0.0
			if d < FOOT + RISE:
				foot = (noise.get_noise_2d(x * 3.0, z * 3.0) + 1.0) * 0.5 * FOOT
			var t := clampf((d - foot) / RISE, 0.0, 1.0)
			# Les bosses s'éteignent au bord de la grille, où la bordure plate la prolonge.
			var edge := mini(mini(i, _columns - 1 - i), mini(j, _rows - 1 - j))
			var bump := BUMP * t * clampf(float(edge) / per_cell, 0.0, 1.0)
			_heights[j * _columns + i] = CLIFF * t * t * (3.0 - 2.0 * t) + bump * noise.get_noise_2d(x, z)


## Pour chaque sommet, la distance en pixels au praticable, jusqu'à FOOT + RISE : au-delà, la
## falaise est à son plus haut (INF). C'est moins d'une case : le sol qui compte est dans les
## huit cases autour. Une case possède ses sommets du haut et de gauche ; sur une limite de
## case de sol, la distance est nulle, la falaise part de là.
func _distances(map: MapGenerator, per_cell: int) -> PackedFloat32Array:
	var cells_x := map.width + MARGIN * 2
	var cells_y := map.height + MARGIN * 2
	var floor_cells := PackedByteArray()
	floor_cells.resize(cells_x * cells_y)
	for y in map.height:
		for x in map.width:
			if map.grid[y][x] == MapGenerator.FLOOR:
				floor_cells[(y + MARGIN) * cells_x + x + MARGIN] = 1
	# Zéro partout : le sol, sans rien à écrire.
	var out := PackedFloat32Array()
	out.resize(_columns * _rows)
	var tile := float(MapGenerator.TILE)
	for cy in cells_y:
		for cx in cells_x:
			if floor_cells[cy * cells_x + cx] == 1:
				continue
			var near: Array[Rect2] = []
			for ny in range(maxi(cy - 1, 0), mini(cy + 2, cells_y)):
				for nx in range(maxi(cx - 1, 0), mini(cx + 2, cells_x)):
					if floor_cells[ny * cells_x + nx] == 1:
						near.append(Rect2(_origin + Vector2(nx, ny) * tile, Vector2(tile, tile)))
			for j in range(cy * per_cell, cy * per_cell + per_cell):
				for i in range(cx * per_cell, cx * per_cell + per_cell):
					var p := _origin + Vector2(i, j) * STEP
					var d := INF
					for r in near:
						d = minf(d, Vector2(maxf(maxf(r.position.x - p.x, p.x - r.end.x), 0.0),
							maxf(maxf(r.position.y - p.y, p.y - r.end.y), 0.0)).length())
					out[j * _columns + i] = d
	# La dernière rangée et la dernière colonne, au bout de la marge : du mur.
	for i in _columns:
		out[(_rows - 1) * _columns + i] = INF
	for j in _rows:
		out[j * _columns + _columns - 1] = INF
	return out


func _mesh() -> void:
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	vertices.resize(_columns * _rows)
	normals.resize(_columns * _rows)
	for j in _rows:
		for i in _columns:
			var k := j * _columns + i
			vertices[k] = Vector3(_origin.x + i * STEP, _heights[k], _origin.y + j * STEP)
			var dx := _heights[k + 1 if i < _columns - 1 else k] - _heights[k - 1 if i > 0 else k]
			var dz := _heights[k + _columns if j < _rows - 1 else k] - _heights[k - _columns if j > 0 else k]
			normals[k] = Vector3(-dx, 2.0 * STEP, -dz).normalized()
	var indices := PackedInt32Array()
	indices.resize((_columns - 1) * (_rows - 1) * 6)
	var n := 0
	for j in _rows - 1:
		for i in _columns - 1:
			var k := j * _columns + i
			indices[n] = k
			indices[n + 1] = k + 1
			indices[n + 2] = k + _columns
			indices[n + 3] = k + 1
			indices[n + 4] = k + _columns + 1
			indices[n + 5] = k + _columns
			n += 6
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, _border())


## Quatre bandes plates autour de la grille, à hauteur des falaises, jusqu'à BEYOND.
func _border() -> Array:
	var inner := Rect2(_origin, Vector2(_columns - 1, _rows - 1) * STEP)
	var outer := inner.grow(BEYOND)
	var vertices := PackedVector3Array()
	for strip in [
		Rect2(outer.position, Vector2(outer.size.x, inner.position.y - outer.position.y)),
		Rect2(Vector2(outer.position.x, inner.end.y), Vector2(outer.size.x, outer.end.y - inner.end.y)),
		Rect2(Vector2(outer.position.x, inner.position.y), Vector2(inner.position.x - outer.position.x, inner.size.y)),
		Rect2(Vector2(inner.end.x, inner.position.y), Vector2(outer.end.x - inner.end.x, inner.size.y)),
	]:
		var a := Vector3(strip.position.x, CLIFF, strip.position.y)
		var b := Vector3(strip.end.x, CLIFF, strip.position.y)
		var c := Vector3(strip.position.x, CLIFF, strip.end.y)
		var d := Vector3(strip.end.x, CLIFF, strip.end.y)
		vertices.append_array([a, b, c, b, d, c])
	var normals := PackedVector3Array()
	normals.resize(vertices.size())
	normals.fill(Vector3.UP)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	return arrays
