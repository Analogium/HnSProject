class_name Scenery
extends Node3D

## Le décor d'une zone (jalon 54, étape 3) : des modèles de `art/decor/` (scans de Poly Haven,
## `tools/decor_3d.py`), un `MultiMesh` par modèle. Semé par case d'après la graine de la zone :
## rochers, buissons et bois mort sur le sol, arbres morts et blocs en haut des falaises. Rien
## n'y porte de collision, et le champ de flux n'a pas à le connaître.

const MODELS := "res://art/decor/%s.glb"
const ROCKS := ["rock_a", "rock_b", "stone"]
const WOOD := ["branch", "twigs", "log", "stump"]
const BUSH := "bush"
## En haut des falaises, au bord du praticable : où l'on ne marche jamais.
const HEIGHTS := ["dead_tree_a", "dead_tree_b", "dead_tree_c", "boulder"]
## Par case de sol (hors route), puis par case de mur au bord du sol.
const ROCK_CHANCE := 0.013
const BUSH_CHANCE := 0.03
const WOOD_CHANCE := 0.008
const HEIGHT_CHANCE := 0.15
## Assez pour casser l'alignement sur la grille, pas assez pour qu'un rocher déborde sur un mur.
const JITTER := 8.0
const SIZE_RANGE := Vector2(0.8, 1.25)
## Le biome ocre : vers quoi chaque modèle tire sa couleur, et de combien (le reste : un peu).
## Le buisson est vert sur son scan ; ici tout a brûlé.
const DRY := Color(0.62, 0.42, 0.26)
const DRYING := {"bush": 0.85, "log": 0.35, "branch": 0.35, "twigs": 0.35, "stump": 0.35}
const SLIGHT_DRYING := 0.2

static var _meshes := {}

## [modèle, transformation] pour chaque pièce posée, dans l'ordre du semis.
var pieces: Array = []


## Sème le décor de `map` sur `terrain`, d'après `rng`. `bare` : rien (la ville).
func scatter(map: MapGenerator, terrain: Terrain, rng: RandomNumberGenerator, bare: bool) -> void:
	clear()
	if bare:
		return
	var on_road := {}
	for cell in map.road:
		on_road[cell] = true
	for y in map.height:
		for x in map.width:
			var cell := Vector2i(x, y)
			if map.grid[y][x] == MapGenerator.FLOOR:
				if not on_road.has(cell):
					_on_floor(cell, terrain, rng)
			elif _at_edge(map, cell) and rng.randf() < HEIGHT_CHANCE:
				_place(HEIGHTS[rng.randi() % HEIGHTS.size()], cell, terrain, rng)
	_build()


func clear() -> void:
	pieces.clear()
	for node in get_children():
		node.free()


func _on_floor(cell: Vector2i, terrain: Terrain, rng: RandomNumberGenerator) -> void:
	var roll := rng.randf()
	if roll < ROCK_CHANCE:
		_place(ROCKS[rng.randi() % ROCKS.size()], cell, terrain, rng)
	elif roll < ROCK_CHANCE + BUSH_CHANCE:
		_place(BUSH, cell, terrain, rng)
	elif roll < ROCK_CHANCE + BUSH_CHANCE + WOOD_CHANCE:
		_place(WOOD[rng.randi() % WOOD.size()], cell, terrain, rng)


## Une case de mur qui touche le sol par un côté.
func _at_edge(map: MapGenerator, cell: Vector2i) -> bool:
	for side in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var next: Vector2i = cell + side
		if map.in_bounds(next) and map.grid[next.y][next.x] == MapGenerator.FLOOR:
			return true
	return false


func _place(model: String, cell: Vector2i, terrain: Terrain, rng: RandomNumberGenerator) -> void:
	var at := MapGenerator.cell_center(cell) + Vector3(rng.randf_range(-1, 1), 0.0, rng.randf_range(-1, 1)) * JITTER
	at.y = terrain.height_at(at)
	var size := rng.randf_range(SIZE_RANGE.x, SIZE_RANGE.y) * Flat.PX_PER_M
	var turn := Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3.ONE * size)
	pieces.append([model, Transform3D(turn, at)])


## Un `MultiMesh` par modèle posé.
func _build() -> void:
	var by_model := {}
	for piece: Array in pieces:
		if not by_model.has(piece[0]):
			by_model[piece[0]] = []
		by_model[piece[0]].append(piece[1])
	for model: String in by_model:
		var placed: Array = by_model[model]
		var multimesh := MultiMesh.new()
		multimesh.transform_format = MultiMesh.TRANSFORM_3D
		multimesh.mesh = _mesh(model)
		multimesh.instance_count = placed.size()
		for i in placed.size():
			multimesh.set_instance_transform(i, placed[i])
		var instance := MultiMeshInstance3D.new()
		instance.name = model
		instance.multimesh = multimesh
		add_child(instance)


## Le maillage du modèle, son matériau remplacé par celui du biome ; une fois par partie.
static func _mesh(model: String) -> Mesh:
	if _meshes.has(model):
		return _meshes[model]
	var scene := (load(MODELS % model) as PackedScene).instantiate()
	var mesh: Mesh = (scene.find_children("*", "MeshInstance3D", true, false)[0] as MeshInstance3D).mesh.duplicate()
	scene.free()
	for surface in mesh.get_surface_count():
		var source := mesh.surface_get_material(surface) as StandardMaterial3D
		var material := ShaderMaterial.new()
		material.shader = preload("res://world/decor.gdshader")
		material.set_shader_parameter("albedo_tex", source.albedo_texture)
		material.set_shader_parameter("normal_tex", source.normal_texture)
		material.set_shader_parameter("tint", DRY)
		material.set_shader_parameter("amount", DRYING.get(model, SLIGHT_DRYING))
		mesh.surface_set_material(surface, material)
	_meshes[model] = mesh
	return mesh
