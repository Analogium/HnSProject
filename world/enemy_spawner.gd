class_name EnemySpawner
extends Node

## Placement des ennemis par paquets, avec du vide entre les paquets.
##
## Le placement uniforme est le piège du débutant : il donne un bruit constant
## d'ennemis, sans rythme. C'est l'alternance tension / respiration qui fait
## tout l'intérêt de la traversée.
##
## Un paquet mixte — des grunts qui foncent, un caster derrière — est bien plus
## intéressant qu'un paquet homogène : il faut décider si on perce jusqu'au
## caster ou si on nettoie d'abord.

const TILE_SIZE := 32

@export var pack_count: int = 14
@export var pack_size_min: int = 3
@export var pack_size_max: int = 7
@export var pack_radius_tiles: int = 3
@export var min_distance_from_spawn_tiles: int = 8
@export var min_distance_between_packs_tiles: int = 6

@export var grunt_scene: PackedScene
@export var caster_scene: PackedScene

## Poids relatifs. Un caster pour ~3 grunts.
@export var grunt_weight: int = 75
@export var caster_weight: int = 25


## Renvoie le nombre d'ennemis réellement placés.
func populate(gen: MapGenerator, manager: EnemyManager, spawn_cell: Vector2i) -> int:
	if gen.floor_cells.is_empty():
		return 0

	var placed := 0
	for anchor in _pick_pack_anchors(gen, spawn_cell):
		var size := Game.rng.randi_range(pack_size_min, pack_size_max)
		placed += _spawn_pack(gen, manager, anchor, size)
	return placed


## Choisit des centres de paquet suffisamment éloignés du joueur et entre eux.
func _pick_pack_anchors(gen: MapGenerator, spawn_cell: Vector2i) -> Array[Vector2i]:
	var anchors: Array[Vector2i] = []
	var min_from_spawn_sq := min_distance_from_spawn_tiles ** 2
	var min_between_sq := min_distance_between_packs_tiles ** 2

	var attempts := 0
	var max_attempts := pack_count * 40

	while anchors.size() < pack_count and attempts < max_attempts:
		attempts += 1
		var cell: Vector2i = gen.floor_cells[Game.rng.randi() % gen.floor_cells.size()]

		if (cell - spawn_cell).length_squared() < min_from_spawn_sq:
			continue

		var too_close := false
		for a in anchors:
			if (cell - a).length_squared() < min_between_sq:
				too_close = true
				break
		if too_close:
			continue

		anchors.append(cell)

	return anchors


func _spawn_pack(
	gen: MapGenerator,
	manager: EnemyManager,
	anchor: Vector2i,
	size: int
) -> int:
	var placed := 0
	var attempts := 0
	# Une case par ennemi : deux corps sur la même case démarrent en
	# interpénétration, et la résolution physique peut les chasser dans un mur.
	var used := {}

	while placed < size and attempts < size * 12:
		attempts += 1
		var offset := Vector2i(
			Game.rng.randi_range(-pack_radius_tiles, pack_radius_tiles),
			Game.rng.randi_range(-pack_radius_tiles, pack_radius_tiles)
		)
		var cell := anchor + offset

		if used.has(cell) or not gen.is_walkable(cell):
			continue
		used[cell] = true

		var scene := _pick_scene()
		if scene == null:
			continue

		var enemy: Enemy = scene.instantiate()
		# +0.5 tuile : on vise le centre de la case, pas son coin.
		enemy.position = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE

		manager.add_child(enemy)
		manager.register(enemy)
		placed += 1

	return placed


func _pick_scene() -> PackedScene:
	var total := grunt_weight + caster_weight
	if total <= 0:
		return grunt_scene
	return caster_scene if Game.rng.randi() % total >= grunt_weight else grunt_scene
