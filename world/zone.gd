extends Node2D

## L'assemblage de l'étape 9 : la carte générée devient praticable.
## Deux TileMapLayer partagent le même TileSet — seule la tuile de mur porte
## une collision, donc le layer de sol ne bloque rien.
##
## Le WallLayer et le conteneur d'entités sont Y-sortés ensemble, sinon les
## personnages passeraient devant et derrière les murs de façon incohérente.

const GRUNT_SCENE := preload("res://actors/enemies/grunt.tscn")
const CASTER_SCENE := preload("res://actors/enemies/caster.tscn")

## Paquet manuel autour du joueur (touche G). Ce n'est plus le peuplement de la
## zone — c'est l'EnemySpawner qui s'en charge — mais un outil de test, pour
## provoquer une mêlée sur commande sans traverser la carte.
const PACK_GRUNTS := 4
const PACK_CASTERS := 1
const PACK_RADIUS_TILES := 6
const PACK_MIN_TILES := 3

@onready var floor_layer: TileMapLayer = $FloorLayer
@onready var wall_layer: TileMapLayer = $Entities/WallLayer
@onready var player: Player = $Entities/Player
@onready var enemy_manager: EnemyManager = $Entities/EnemyManager
@onready var projectiles: Node2D = $Entities/Projectiles
@onready var loot: Node2D = $Entities/Loot
@onready var overlay: Label = $UI/Overlay
@onready var map_overlay: MapOverlay = $UI/MapOverlay
@onready var hud: Hud = $UI/Hud
@onready var inventory: InventoryPanel = $UI/Inventory
@onready var stats_panel: StatsPanel = $UI/Stats
@onready var spawner: EnemySpawner = $EnemySpawner

var generator: MapGenerator

## Tirage propre à la zone : tout ce qui la dessine ou la peuple passe par lui.
## C'est ce qui fait qu'une graine redonne exactement la même zone — mêmes murs,
## mêmes tuiles, mêmes ennemis, mêmes silhouettes. Choisir une *nouvelle* graine
## reste, lui, un tirage global.
var zone_rng := RandomNumberGenerator.new()

var _seed := 0
var _gen_ms := 0.0
var _paint_ms := 0.0
var _spawned := 0


func _ready() -> void:
	var ts := TilesetBuilder.build()
	floor_layer.tile_set = ts
	wall_layer.tile_set = ts
	# Le sol partage le TileSet mais ne doit rien bloquer.
	floor_layer.collision_enabled = false

	enemy_manager.target = player
	enemy_manager.projectile_parent = projectiles
	enemy_manager.loot_parent = loot
	player.died.connect(_on_player_died)

	player.projectile_parent = projectiles
	map_overlay.player = player
	map_overlay.enemy_manager = enemy_manager
	hud.bind(player)
	inventory.bind(player)
	inventory.drop_requested.connect(_on_item_dropped)
	stats_panel.bind(player)

	# Les scènes sont posées ici et pas dans le .tscn : le spawner n'en a besoin
	# qu'au moment de populate(), et ça garde les chemins au même endroit.
	spawner.grunt_scene = GRUNT_SCENE
	spawner.caster_scene = CASTER_SCENE

	generate_zone(Game.rng.randi())


## Ce qu'on jette du sac atterrit devant le joueur et non sous ses pieds : posé
## au centre, il serait à moitié caché par le personnage. Le délai de ramassage
## fait le reste — sans lui on le reprendrait aussitôt sans avoir bougé.
func _on_item_dropped(item: Item) -> void:
	GroundItem.spawn(
		loot, player.global_position + player.facing * 14.0, item, GroundItem.DROP_DELAY
	)


func _process(_delta: float) -> void:
	if overlay.visible:
		overlay.text = _overlay_text()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# Retenu avant le match : un changement de scène détache ce nœud de l'arbre
	# et get_viewport() renverrait null.
	var vp := get_viewport()

	match (event as InputEventKey).keycode:
		KEY_F5: generate_zone(Game.rng.randi())
		KEY_G: spawn_pack()
		KEY_K: kill_all()
		KEY_I: inventory.toggle()
		KEY_C: stats_panel.toggle()
		KEY_TAB: map_overlay.visible = not map_overlay.visible
		KEY_H: overlay.visible = not overlay.visible
		KEY_F2: Game.goto_scene("res://world/test_arena.tscn")
		KEY_F3: Game.goto_scene("res://world/map_debug.tscn")
		KEY_F4: Game.goto_scene("res://art/forge_gallery.tscn")
		KEY_F6: Game.goto_scene("res://world/stress_test.tscn")
		_: return

	vp.set_input_as_handled()


func generate_zone(zone_seed: int) -> void:
	_seed = zone_seed
	zone_rng.seed = zone_seed
	kill_all()

	generator = MapGenerator.new()
	var t0 := Time.get_ticks_usec()
	generator.generate(_seed)
	_gen_ms = float(Time.get_ticks_usec() - t0) / 1000.0

	t0 = Time.get_ticks_usec()
	_paint()
	_paint_ms = float(Time.get_ticks_usec() - t0) / 1000.0

	# La carte suit la zone réellement jouée : reconstruite ici, pas ailleurs.
	map_overlay.build(generator, MapGenerator.TILE)

	var spawn_cell := generator.get_spawn_cell()
	player.revive()
	player.global_position = MapGenerator.cell_center(spawn_cell)

	# Placement par paquets répartis sur toute la zone, avec du vide entre eux.
	# C'est ça qui donne le rythme de traversée ; un paquet autour du joueur ne
	# sert plus qu'au test manuel (touche G).
	_spawned = spawner.populate(generator, enemy_manager, spawn_cell, _seed)


func _paint() -> void:
	floor_layer.clear()
	wall_layer.clear()

	for y in generator.height:
		for x in generator.width:
			var cell := Vector2i(x, y)
			if generator.grid[y][x] == MapGenerator.FLOOR:
				floor_layer.set_cell(cell, 0, _random_floor_tile())
			else:
				wall_layer.set_cell(cell, 0, Vector2i(_wall_tile(x, y), 0))


## Le dessus n'est éclairé que si la case au-dessus est du sol : sinon on est
## à l'intérieur d'une masse de murs, et une bande claire y dessinerait une
## grille de briques.
func _wall_tile(x: int, y: int) -> int:
	# Type explicite : grid est un Array non typé, donc la comparaison rend un
	# Variant et l'inférence échoue.
	var above_is_floor: bool = y > 0 and generator.grid[y - 1][x] == MapGenerator.FLOOR
	return TilesetBuilder.WALL_EDGE_INDEX if above_is_floor else TilesetBuilder.WALL_INDEX


## Variation visuelle : 85 % de tuile neutre, 15 % de variantes.
## Les bornes viennent de TilesetBuilder et ne sont pas réécrites ici : ajouter
## une variante à l'atlas doit suffire à la voir apparaître dans la zone.
func _random_floor_tile() -> Vector2i:
	if zone_rng.randf() < 0.15:
		return Vector2i(zone_rng.randi_range(1, TilesetBuilder.FLOOR_VARIANTS - 1), 0)
	return Vector2i(0, 0)


## Paquet mixte autour du joueur, sur des cases praticables uniquement.
func spawn_pack() -> void:
	var origin := MapGenerator.cell_at(player.global_position)
	var total := PACK_GRUNTS + PACK_CASTERS
	var placed := 0
	var attempts := 0

	while placed < total and attempts < total * 30:
		attempts += 1
		var offset := Vector2i(
			Game.rng.randi_range(-PACK_RADIUS_TILES, PACK_RADIUS_TILES),
			Game.rng.randi_range(-PACK_RADIUS_TILES, PACK_RADIUS_TILES)
		)
		if absi(offset.x) < PACK_MIN_TILES and absi(offset.y) < PACK_MIN_TILES:
			continue   # pas dans les pieds du joueur
		var cell := origin + offset
		if not generator.is_walkable(cell):
			continue

		var scene := CASTER_SCENE if placed >= PACK_GRUNTS else GRUNT_SCENE
		enemy_manager.spawn(scene, MapGenerator.cell_center(cell))
		placed += 1


## Publique : la scène de stress test vide la zone avant d'y verser ses vagues.
func kill_all() -> void:
	enemy_manager.clear()
	for p in projectiles.get_children():
		p.queue_free()
	# Le butin est posé sur le sol de *cette* carte : le garder d'une zone à
	# l'autre laisserait des objets flotter dans les murs de la suivante.
	for l in loot.get_children():
		l.queue_free()


func _on_player_died() -> void:
	# En différé : la mort arrive depuis la boucle de l'EnemyManager, et
	# regénérer la zone viderait sa liste en plein parcours.
	_respawn.call_deferred()


func _respawn() -> void:
	kill_all()
	player.revive()
	var spawn_cell := generator.get_spawn_cell()
	player.global_position = MapGenerator.cell_center(spawn_cell)
	_spawned = spawner.populate(generator, enemy_manager, spawn_cell, _seed)


func _overlay_text() -> String:
	return "\n".join([
		# Ni les PV ni les statistiques de combat : les jauges du HUD donnent les
		# premiers au point près, et la fiche (touche C) donne les secondes en
		# entier. Ce bandeau ne garde que ce que lui seul sait.
		"niv %d (%d/%d)    ennemis %d" % [
			player.level, player.xp, player.xp_to_next, enemy_manager.enemies.size()
		],
		"",
		"zone %d  —  %d cases de sol" % [_seed, generator.floor_cells.size()],
		"%d ennemis places en %d paquets" % [_spawned, spawner.pack_count],
		"generation %.0f ms  peinture %.0f ms" % [_gen_ms, _paint_ms],
		"",
		"[TAB] carte de la zone",
		"[I] inventaire   [C] fiche de personnage",
		"[F5] nouvelle zone   [G] paquet   [K] tout tuer",
		"[H] masquer cette aide",
		"[F2] arene de reglage   [F3] reglage generation",
		"[F4] forge              [F6] stress test",
	])
