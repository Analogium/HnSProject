extends Node2D

## Arène de test des étapes 3 à 6 : quelques murs, des mannequins immobiles
## qui servent de référence pour juger le coup, des grunts, et un panneau de
## réglage à chaud.
##
## Les valeurs se règlent en jeu, puis se recopient à la main dans les .tres
## et dans player.tscn une fois trouvées.

const DUMMY_SCENE := preload("res://actors/dummy/training_dummy.tscn")
const GRUNT_SCENE := preload("res://actors/enemies/grunt.tscn")
const CASTER_SCENE := preload("res://actors/enemies/caster.tscn")

const ARENA_SIZE := Vector2(640, 480)
const WALL_THICKNESS := 16.0
const WALL_COLOR := Color(0.16, 0.15, 0.19)

## Obstacles intérieurs, en coordonnées monde. Le centre reste dégagé : c'est
## là qu'apparaît le joueur, et c'est autour de lui que tombent les paquets.
const PILLARS := [
	Rect2(140, 120, 48, 48),
	Rect2(452, 120, 48, 48),
	Rect2(140, 312, 48, 48),
	Rect2(452, 312, 48, 48),
]

## On en garde deux : une cible qui ne bouge pas reste le meilleur repère pour
## juger le hit-stop et le flash sans que ça riposte.
const DUMMY_POSITIONS := [
	Vector2(240, 130),
	Vector2(400, 130),
]

## Taille d'un paquet, et distance à laquelle il apparaît du joueur.
## Un paquet mixte — des grunts qui foncent, un caster derrière — est bien plus
## intéressant qu'un paquet homogène : il faut décider si on perce jusqu'au
## caster ou si on nettoie d'abord.
const PACK_GRUNTS := 4
const PACK_CASTERS := 1
const PACK_DISTANCE := 130.0
const CASTER_DISTANCE := 190.0

@onready var walls: Node2D = $Walls
@onready var entities: Node2D = $Entities
@onready var player: Player = $Entities/Player
@onready var enemy_manager: EnemyManager = $Entities/EnemyManager
@onready var projectiles: Node2D = $Entities/Projectiles
@onready var overlay: Label = $UI/Overlay

var _dummies: Array[TrainingDummy] = []


func _ready() -> void:
	# Copie privée de la ressource : l'arène modifie les statistiques à chaud
	# (touches 3/4 et 7/8), et sans ça elle écrirait dans player_stats.tres.
	# Les réglages trouvés se recopient ensuite à la main dans le fichier.
	player.base_stats = player.base_stats.duplicate()

	_build_walls()
	_spawn_dummies()
	player.global_position = ARENA_SIZE * 0.5
	player.died.connect(_on_player_died)

	# Le target doit être posé avant tout register() : c'est lui que le manager
	# passe à setup() sur chaque ennemi.
	enemy_manager.target = player
	enemy_manager.projectile_parent = projectiles
	player.projectile_parent = projectiles
	_spawn_pack()


func _process(_delta: float) -> void:
	if overlay.visible:
		overlay.text = _overlay_text()


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# Retenu avant le match : change_scene_to_file() détache ce nœud de l'arbre
	# immédiatement, et get_viewport() renverrait alors null. Le viewport racine,
	# lui, survit au changement de scène.
	var vp := get_viewport()

	match (event as InputEventKey).keycode:
		KEY_1: Game.hit_stop_duration = maxf(Game.hit_stop_duration - 0.01, 0.0)
		KEY_2: Game.hit_stop_duration = minf(Game.hit_stop_duration + 0.01, 0.30)
		KEY_3: _tune("knockback_force", -20.0, 0.0)
		KEY_4: _tune("knockback_force", 20.0, 0.0)
		KEY_5: player.swing_duration = maxf(player.swing_duration - 0.01, 0.02)
		KEY_6: player.swing_duration += 0.01
		KEY_7: _tune("attack_cooldown", -0.05, 0.05)
		KEY_8: _tune("attack_cooldown", 0.05, 0.05)
		KEY_9: player.shake_amount = maxf(player.shake_amount - 1.0, 0.0)
		KEY_0: player.shake_amount += 1.0
		KEY_G: _spawn_pack()
		KEY_C: _spawn_lone_caster()
		KEY_K: _kill_all()
		KEY_R: _reset_arena()
		KEY_F1: Game.goto_scene("res://world/zone.tscn")
		KEY_F3: Game.goto_scene("res://world/map_debug.tscn")
		KEY_F4: Game.goto_scene("res://art/forge_gallery.tscn")
		KEY_F6: Game.goto_scene("res://world/stress_test.tscn")
		KEY_H: overlay.visible = not overlay.visible
		_: return

	vp.set_input_as_handled()


## Le réglage porte sur base_stats et non sur la copie de travail : celle-ci est
## reconstruite à chaque montée de niveau, ce qui effacerait le réglage en cours
## au beau milieu d'une session d'essai.
func _tune(field: String, delta: float, floor_value: float) -> void:
	player.base_stats.set(field, maxf(float(player.base_stats.get(field)) + delta, floor_value))
	player.recompute_stats()


func _overlay_text() -> String:
	return "\n".join([
		"PV %.0f/%.0f    ennemis %d" % [
			maxf(player.health, 0.0), player.stats.max_health, enemy_manager.enemies.size()
		],
		"",
		"[1/2] hit-stop        %.2f s" % Game.hit_stop_duration,
		"[3/4] knockback       %.0f" % player.stats.knockback_force,
		"[5/6] duree swing     %.2f s" % player.swing_duration,
		"[7/8] cooldown        %.2f s" % player.stats.attack_cooldown,
		"[9/0] shake camera    %.0f" % player.shake_amount,
		"[G] paquet mixte  [C] caster seul  [K] tout tuer",
		"[R] reset arene   [H] masquer",
		"[F1] zone jouable   [F3] carte debug",
		"[F4] forge          [F6] stress test",
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


## Paquet mixte en cercle autour du joueur : les grunts convergent, ce qui met
## la séparation à l'épreuve, et le caster se tient plus loin derrière.
func _spawn_pack() -> void:
	var origin := player.global_position
	var total := PACK_GRUNTS + PACK_CASTERS
	for i in total:
		var angle := TAU * float(i) / float(total) + Game.rng.randf_range(-0.2, 0.2)
		var is_caster := i >= PACK_GRUNTS
		var radius := CASTER_DISTANCE if is_caster else PACK_DISTANCE
		var scene := CASTER_SCENE if is_caster else GRUNT_SCENE
		_add_enemy(scene, origin + Vector2.from_angle(angle) * radius)


## Un caster seul, pour juger son comportement sans la mêlée autour.
func _spawn_lone_caster() -> void:
	var angle := Game.rng.randf() * TAU
	_add_enemy(CASTER_SCENE, player.global_position + Vector2.from_angle(angle) * CASTER_DISTANCE)


func _add_enemy(scene: PackedScene, pos: Vector2) -> void:
	# On garde l'ennemi à l'intérieur des murs.
	pos.x = clampf(pos.x, WALL_THICKNESS + 10.0, ARENA_SIZE.x - WALL_THICKNESS - 10.0)
	pos.y = clampf(pos.y, WALL_THICKNESS + 10.0, ARENA_SIZE.y - WALL_THICKNESS - 10.0)

	enemy_manager.spawn(scene, pos)


func _kill_all() -> void:
	enemy_manager.clear()
	# Les tirs déjà partis ne sont pas dans la liste du manager.
	for p in projectiles.get_children():
		p.queue_free()


func _reset_arena() -> void:
	for d in _dummies:
		if is_instance_valid(d):
			d.reset()
	_kill_all()
	player.revive()
	player.global_position = ARENA_SIZE * 0.5
	_spawn_pack()


func _on_player_died() -> void:
	# Pas d'écran de fin au jalon 1 : on remet en jeu pour pouvoir continuer
	# à régler le game feel.
	#
	# En différé, impérativement : la mort arrive depuis Grunt.tick(), donc
	# depuis la boucle de l'EnemyManager. Vider et repeupler la liste des
	# ennemis en plein parcours la ferait rétrécir sous ses pieds.
	_reset_arena.call_deferred()
