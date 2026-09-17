class_name BenchSimulation

## Un robot dans une vraie zone, à graine fixe : il marche vers l'ennemi le plus proche
## et lance toute sa barre dès que `Player.cast_slot()` l'accepte. Un joueur médiocre, et
## c'est voulu : la mesure donne un plancher (JALONS/hack-n-slash-jalon-13.md, §3).

const ZONE := preload("res://world/zone.tscn")
const SEED := 4242
## En secondes de jeu : une case qu'on ne vide pas s'arrête ici.
const CAP := 180.0
const LOW_HEALTH := 0.30
## Le champ vers la cible couvre la carte entière (8,9 ms mesurés) : pas à chaque image.
const FIELD_PERIOD := 1.0
## En deçà, la ligne droite : le champ ne dit rien de la case où se tient la cible.
const CONTACT := 2.0 * MapGenerator.TILE


class Result:
	var level := 0
	var kills := 0
	var deaths := 0
	## Temps de jeu : un gel d'impact n'en compte que sa part ralentie.
	var time_value := 0.0
	var under_low_health := 0.0
	var emptied := false

	func kills_per_minute() -> float:
		return float(kills) * 60.0 / time_value if time_value > 0.0 else 0.0


var _result: Result
var _player: Player


func play(host: Node, character: Character, zone: int) -> Result:
	_result = Result.new()
	Game.zone_level = zone
	var tree := host.get_tree()
	var scene: Node2D = ZONE.instantiate()
	host.add_child(scene)
	scene.set_process_unhandled_input(false)
	_player = scene.player
	_player.load_character(character)
	_result.level = _player.level
	# Sans souris, la visée suit la marche : c'est ce que fait la manette.
	Input.parse_input_event(InputEventJoypadButton.new())
	Game.rng.seed = SEED
	scene.generate_zone(SEED)

	var manager: EnemyManager = scene.enemy_manager
	for e in manager.enemies:
		e.died.connect(_on_enemy_died)
	# Une mort du joueur repeuple la zone.
	manager.child_entered_tree.connect(_on_spawn)
	_player.died.connect(_on_player_died)

	var field := FlowField.new(scene.generator)
	var extent: int = maxi(scene.generator.width, scene.generator.height)
	var target: Enemy = null
	var pending := 0.0
	while _result.time_value < CAP:
		if manager.enemies.is_empty():
			_result.emptied = true
			break
		if not is_instance_valid(target) or target.is_dead or pending <= 0.0:
			target = _nearest(manager)
			if target != null:
				field.rebuild(MapGenerator.cell_at(target.global_position), extent)
			pending = FIELD_PERIOD
		if target != null:
			var toward := field.direction_at(MapGenerator.cell_at(_player.global_position))
			if toward == Vector2.ZERO or _player.global_position.distance_to(target.global_position) < CONTACT:
				toward = _player.global_position.direction_to(target.global_position)
			_march(toward)
		for i in SkillBar.SLOT_COUNT:
			_player.cast_slot(i)

		await tree.physics_frame
		var step := Engine.time_scale / float(Engine.physics_ticks_per_second)
		_result.time_value += step
		pending -= step
		if _player.health < _player.stats.max_health * LOW_HEALTH:
			_result.under_low_health += step

	_march(Vector2.ZERO)
	scene.queue_free()
	await tree.process_frame
	Game.zone_level = Game.MIN_LEVEL
	return _result


func _nearest(manager: EnemyManager) -> Enemy:
	var best: Enemy = null
	var distance := INF
	for e in manager.enemies:
		if not is_instance_valid(e) or e.is_dead:
			continue
		var d := e.global_position.distance_squared_to(_player.global_position)
		if d < distance:
			distance = d
			best = e
	return best


func _march(toward: Vector2) -> void:
	_press("move_right", toward.x)
	_press("move_left", -toward.x)
	_press("move_down", toward.y)
	_press("move_up", -toward.y)


func _press(action: String, force: float) -> void:
	if force > 0.0:
		Input.action_press(action, force)
	else:
		Input.action_release(action)


func _on_spawn(node: Node) -> void:
	if node is Enemy:
		(node as Enemy).died.connect(_on_enemy_died)


## Le vidage d'une zone qui se recharge après la mort du joueur n'est pas une victoire.
func _on_enemy_died(_enemy: Enemy) -> void:
	if not _player.is_dead:
		_result.kills += 1


func _on_player_died() -> void:
	_result.deaths += 1
