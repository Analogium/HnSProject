extends Node2D

## La scène de stress test : on déverse des ennemis dans une vraie zone jusqu'à
## ce que ça casse, avec les compteurs sous les yeux. Le document de cadrage en
## fait le « réflexe à prendre tout de suite » après le jalon 1 — savoir où sont
## les limites avant de les atteindre en jouant.
##
## Elle instancie zone.tscn au lieu de refabriquer une carte : mesurer sur un
## décor approximatif ne dirait rien. Ici les murs, le Y-sort, le TileMapLayer,
## le culling de l'EnemyManager et les sprites de la forge sont ceux du jeu.
## La zone garde ses touches et son affichage éteints, c'est cette scène qui
## pilote.
##
## Graine figée : deux mesures ne se comparent que sur la même carte.

const ZONE_SCENE := preload("res://world/zone.tscn")
const GRUNT_SCENE := preload("res://actors/enemies/grunt.tscn")
const CASTER_SCENE := preload("res://actors/enemies/caster.tscn")

const SEED := 4242
const TILE_SIZE := 32

const STEP := 20            # ennemis retirés par [1], ajoutés par [2]
const WAVE := 100           # ennemis ajoutés d'un coup par [3]
## Garde-fou : au delà, une machine modeste part en gel de plusieurs secondes et
## on ne mesure plus rien d'utilisable.
const MAX_ENEMIES := 1500

## Rayon d'apparition autour du joueur, en tuiles. 18 tuiles font 576 px de
## côté, donc l'essentiel tombe dans les 700 px du culling de l'EnemyManager :
## on veut des ennemis *simulés*, sinon on mesure la vitesse à laquelle le
## moteur ignore des ennemis.
const SPAWN_RADIUS_TILES := 18

## Montée automatique : on ajoute une marche toutes les RAMP_DELAY secondes tant
## que le jeu tient, et on s'arrête à la première chute durable.
const RAMP_DELAY := 1.0
const RAMP_TARGET_FPS := 55.0
const RAMP_PATIENCE := 30   # images sous la cible avant de déclarer la casse

@onready var overlay: Label = $UI/Overlay

var _zone: Node2D
var _rng := RandomNumberGenerator.new()

var _peak_physics := 0.0
var _peak_enemies := 0
var _ramping := false
var _ramp_cd := 0.0
var _low_frames := 0
var _broke_at := 0


func _ready() -> void:
	_rng.seed = SEED

	_zone = ZONE_SCENE.instantiate()
	add_child(_zone)
	# La zone a son propre affichage et ses propres touches : on la réduit au
	# rôle de décor, sinon deux panneaux se superposent et F5 régénère sous nous.
	_zone.set_process_unhandled_input(false)
	_zone.overlay.visible = false
	# La zone embarque le menu Échap, qui capterait la touche avant cette scène
	# et ouvrirait une pause au lieu de sortir. Ici c'est un banc de mesure, pas
	# une partie : le menu n'y a rien à faire.
	var pause_menu := _zone.get_node_or_null("PauseMenu")
	if pause_menu != null:
		pause_menu.queue_free()

	# La zone s'est déjà générée sur une graine tirée au hasard dans son _ready ;
	# on la refait sur la graine figée, puis on la vide de ses propres paquets.
	_zone.generate_zone(SEED)
	_zone.kill_all()
	# Sans ça le joueur meurt en deux secondes sous trois cents ennemis, la zone
	# se recharge, et la mesure repart de zéro.
	_zone.player.hurtbox.invulnerable = true

	_spawn(STEP * 2)


func _process(delta: float) -> void:
	var physics_ms := Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0
	_peak_physics = maxf(_peak_physics, physics_ms)
	_peak_enemies = maxi(_peak_enemies, _count())

	if _ramping:
		_advance_ramp(delta)

	overlay.text = _text(physics_ms)


func _unhandled_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# Retenu avant le match : un changement de scène détache ce nœud de l'arbre
	# et get_viewport() renverrait null.
	var vp := get_viewport()

	match (event as InputEventKey).keycode:
		KEY_1: _remove(STEP)
		KEY_2: _spawn(STEP)
		KEY_3: _spawn(WAVE)
		# Un chiffre et non une lettre : le déplacement est câblé sur les touches
		# *physiques* W A S D, qui portent les étiquettes Z Q S D en AZERTY — la
		# touche « A » du clavier de l'utilisateur est donc déjà move_left.
		KEY_4: _toggle_ramp()
		KEY_K: _zone.kill_all()
		KEY_R: _reset()
		KEY_H: overlay.visible = not overlay.visible
		KEY_F1: Game.goto_scene("res://world/zone.tscn")
		KEY_F2: Game.goto_scene("res://world/test_arena.tscn")
		# La touche qui a ouvert la scène la referme, comme les autres aperçus.
		KEY_F6, KEY_ESCAPE: Game.go_back()
		_: return

	vp.set_input_as_handled()


func _count() -> int:
	return _zone.enemy_manager.enemies.size()


## Verse des ennemis sur des cases praticables autour du joueur. Ce n'est pas le
## travail de l'EnemySpawner : lui répartit des paquets sur toute la carte pour
## donner un rythme de traversée, ici on veut un nombre choisi, tout de suite,
## et à portée de simulation.
func _spawn(count: int) -> void:
	var gen: MapGenerator = _zone.generator
	if gen == null or gen.floor_cells.is_empty():
		return

	var origin := Vector2i(_zone.player.global_position / TILE_SIZE)
	var placed := 0
	var attempts := 0

	while placed < count and attempts < count * 30:
		attempts += 1
		if _count() >= MAX_ENEMIES:
			return

		var cell := origin + Vector2i(
			_rng.randi_range(-SPAWN_RADIUS_TILES, SPAWN_RADIUS_TILES),
			_rng.randi_range(-SPAWN_RADIUS_TILES, SPAWN_RADIUS_TILES)
		)
		if not gen.is_walkable(cell):
			continue

		# Même proportion que l'EnemySpawner : un caster pour trois grunts.
		var scene := CASTER_SCENE if _rng.randi() % 4 == 0 else GRUNT_SCENE
		var enemy: Enemy = scene.instantiate()
		enemy.position = (Vector2(cell) + Vector2(0.5, 0.5)) * TILE_SIZE
		_zone.enemy_manager.add_child(enemy)
		_zone.enemy_manager.register(enemy)
		placed += 1


## On retire toujours le dernier : die() émet died, que l'EnemyManager traite en
## retirant l'ennemi de la liste. Indexer à l'avance dans cette liste reviendrait
## à viser des cases qui ont bougé entre deux tours de boucle.
func _remove(count: int) -> void:
	var list: Array[Enemy] = _zone.enemy_manager.enemies
	for i in count:
		if list.is_empty():
			return
		var e := list[list.size() - 1]
		if is_instance_valid(e):
			e.die()
		else:
			list.remove_at(list.size() - 1)


func _toggle_ramp() -> void:
	_ramping = not _ramping
	_low_frames = 0
	_ramp_cd = 0.0
	if _ramping:
		_broke_at = 0


func _advance_ramp(delta: float) -> void:
	if Engine.get_frames_per_second() < RAMP_TARGET_FPS:
		_low_frames += 1
	else:
		# Remise à zéro : une image lente isolée (une allocation, un chargement
		# de sprite) n'est pas une limite, seule une chute qui dure en est une.
		_low_frames = 0

	if _low_frames >= RAMP_PATIENCE or _count() >= MAX_ENEMIES:
		_ramping = false
		_broke_at = _count()
		return

	_ramp_cd -= delta
	if _ramp_cd <= 0.0:
		_ramp_cd = RAMP_DELAY
		_spawn(STEP)


## Même ordre que _ready : generate_zone repeuple la zone avec ses propres
## paquets, donc le vidage vient après elle, jamais avant.
func _reset() -> void:
	_zone.generate_zone(SEED)
	_zone.kill_all()
	_zone.player.hurtbox.invulnerable = true
	_peak_physics = 0.0
	_peak_enemies = 0
	_broke_at = 0
	_ramping = false
	_rng.seed = SEED
	_spawn(STEP * 2)


func _text(physics_ms: float) -> String:
	var alive := _count()
	var active: int = _zone.enemy_manager.ticked
	var ramp := "en cours" if _ramping else (
		"cassé à %d ennemis" % _broke_at if _broke_at > 0 else "arrêtée"
	)

	return "\n".join([
		"STRESS TEST  —  graine %d" % SEED,
		"",
		"images/s          %d" % Engine.get_frames_per_second(),
		"physique          %.2f ms   (pic %.2f)" % [physics_ms, _peak_physics],
		# TIME_PROCESS et non « rendu » : c'est le temps passé dans les _process
		# du script, pas celui du GPU, que Godot n'expose pas simplement.
		"scripts _process  %.2f ms" % (
			Performance.get_monitor(Performance.TIME_PROCESS) * 1000.0
		),
		"appels de dessin  %d" % Performance.get_monitor(
			Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME
		),
		"noeuds            %d" % Performance.get_monitor(Performance.OBJECT_NODE_COUNT),
		"",
		# Le second chiffre est le seul qui compte : au delà de CULL_DISTANCE
		# l'EnemyManager ne tick plus, donc des ennemis en trop ne coûtent que
		# leur affichage.
		"ennemis vivants   %d   (pic %d)" % [alive, _peak_enemies],
		"  simules         %d" % active,
		"  hors portee     %d" % (alive - active),
		"",
		"montee auto       %s" % ramp,
		"",
		"[1/2] %d ennemis   [3] vague de %d" % [STEP, WAVE],
		"[4] montee auto    [K] tout tuer   [R] reset",
		"[H] masquer        [F1] zone   [F2] arene",
		"[F6] ou [ECHAP] retour",
	])
