extends GutTest

## Les quatre ennemis du jalon 27 et leur zone de danger : ce qui est dessiné est ce
## qui est frappé, et chaque attaque s'esquive en sortant de sa zone.
##
## La victime est une hurtbox nue sur le calque du joueur, sans esquive : un joueur
## réel tirerait la sienne et rendrait les tests aléatoires.

var _hits := 0
var _chill_duration: float


func before_each() -> void:
	_hits = 0
	_chill_duration = Game.hit_stop_duration
	Game.hit_stop_duration = 0.0


func after_each() -> void:
	Game.hit_stop_duration = _chill_duration
	Engine.time_scale = 1.0


func _victim(at: Vector2) -> Node2D:
	var body := Node2D.new()
	body.position = at
	var hb := Hurtbox.new()
	hb.collision_layer = Targets.PLAYER_SIDE
	hb.collision_mask = 0
	hb.stats = CharacterStats.new()
	hb.states = StatusEffects.new()
	var shape := CollisionShape2D.new()
	shape.shape = CircleShape2D.new()
	(shape.shape as CircleShape2D).radius = 8.0
	hb.add_child(shape)
	body.add_child(hb)
	add_child_autofree(body)
	hb.damaged.connect(func(_info: DamageInfo) -> void: _hits += 1)
	return body


func _manager(victim: Node2D) -> EnemyManager:
	var m := EnemyManager.new()
	add_child_autofree(m)
	m.target = victim
	return m


func _zone(shape: DangerZone.Shape, reach: float, facing := Vector2.RIGHT, spread := 0.0) -> DangerZone:
	var z := DangerZone.put(self, Vector2.ZERO, shape, reach, 0.2, facing, spread)
	await wait_physics_frames(1)
	return z


# --------------------------------------------------------------------------
# La zone
# --------------------------------------------------------------------------

func test_a_disc_holds_its_radius() -> void:
	var z := await _zone(DangerZone.Shape.DISC, 30.0)
	assert_true(z.contains(Vector2(0, 29)))
	assert_false(z.contains(Vector2(22, 22)), "la diagonale sort avant le carré")


func test_a_lane_starts_at_its_owner_and_goes_one_way() -> void:
	var z := await _zone(DangerZone.Shape.LANE, 100.0, Vector2.DOWN, 7.0)
	assert_true(z.contains(Vector2(5, 90)))
	assert_false(z.contains(Vector2(0, -10)), "rien derrière")
	assert_false(z.contains(Vector2(9, 50)), "rien à côté")


func test_a_cone_opens_forward_only() -> void:
	var z := await _zone(DangerZone.Shape.CONE, 50.0, Vector2.RIGHT, 0.6)
	assert_true(z.contains(Vector2(40, 15)))
	assert_false(z.contains(Vector2(20, 30)), "hors de l'angle")
	assert_false(z.contains(Vector2(-10, 0)), "rien derrière")


func test_a_zone_strikes_the_player_side_when_full() -> void:
	_victim(Vector2(10, 0))
	var z := DangerZone.put(self, Vector2.ZERO, DangerZone.Shape.CONE, 40.0, 0.2, Vector2.RIGHT, 0.6)
	z.parts = DamageType.empty_parts()
	z.parts[DamageType.Kind.PHYSICAL] = 5.0
	await wait_physics_frames(6)
	assert_eq(_hits, 0, "rien avant que le plein n'atteigne le bord")
	await wait_physics_frames(12)
	assert_eq(_hits, 1)


func test_a_zone_spares_what_stands_outside() -> void:
	_victim(Vector2(-20, 0))
	var z := DangerZone.put(self, Vector2.ZERO, DangerZone.Shape.CONE, 40.0, 0.1, Vector2.RIGHT, 0.6)
	z.parts = DamageType.empty_parts()
	z.parts[DamageType.Kind.PHYSICAL] = 5.0
	await wait_physics_frames(15)
	assert_eq(_hits, 0)


func test_a_zone_without_parts_never_strikes() -> void:
	_victim(Vector2(10, 0))
	DangerZone.put(self, Vector2.ZERO, DangerZone.Shape.LANE, 40.0, 0.1, Vector2.RIGHT, 8.0)
	await wait_physics_frames(15)
	assert_eq(_hits, 0)


func test_a_bound_zone_falls_with_its_enemy() -> void:
	_victim(Vector2(10, 0))
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child(grunt)
	var z := DangerZone.put(self, Vector2.ZERO, DangerZone.Shape.DISC, 30.0, 0.3)
	z.parts = DamageType.empty_parts()
	z.parts[DamageType.Kind.PHYSICAL] = 5.0
	z.bound = grunt
	await wait_physics_frames(2)
	grunt.die(false)
	await wait_physics_frames(30)
	assert_false(is_instance_valid(z), "la zone est partie")
	assert_eq(_hits, 0)


# --------------------------------------------------------------------------
# Les quatre
# --------------------------------------------------------------------------

func test_the_charger_shows_its_lane_then_hits_along_it() -> void:
	var victim := _victim(Vector2.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/charger.tscn"), Vector2(100, 0))
	await wait_physics_frames(3)
	assert_eq(_zones(m).size(), 1, "le couloir d'abord")
	await wait_physics_frames(90)
	assert_eq(_hits, 1, "une charge frappe une fois")


func test_the_mortar_hits_where_the_victim_stood() -> void:
	var victim := _victim(Vector2.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/mortar.tscn"), Vector2(150, 0))
	await wait_physics_frames(80)
	assert_gt(_hits, 0)


func test_the_mortar_misses_who_moved_away() -> void:
	var victim := _victim(Vector2.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/mortar.tscn"), Vector2(150, 0))
	await wait_physics_frames(3)
	assert_eq(_zones(m).size(), 1, "l'obus est parti")
	victim.position = Vector2(0, 80)
	await wait_physics_frames(66)
	assert_eq(_hits, 0)


func test_the_brute_hits_what_stays_in_front() -> void:
	var victim := _victim(Vector2.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/brute.tscn"), Vector2(30, 0))
	await wait_physics_frames(60)
	assert_eq(_hits, 1)


func test_the_brute_misses_who_leaves_the_cone() -> void:
	var victim := _victim(Vector2.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/brute.tscn"), Vector2(30, 0))
	await wait_physics_frames(3)
	victim.position = Vector2(30, -45)
	await wait_physics_frames(57)
	assert_eq(_hits, 0)


func test_the_bloater_swells_then_bursts_without_reward() -> void:
	var victim := _victim(Vector2.ZERO)
	var m := _manager(victim)
	var b: Enemy = m.spawn(load("res://actors/enemies/bloater.tscn"), Vector2(15, 0))
	await wait_physics_frames(60)
	assert_eq(_hits, 1)
	assert_false(is_instance_valid(b), "il meurt de son explosion")


func test_a_killed_bloater_still_bursts() -> void:
	var victim := _victim(Vector2.ZERO)
	var m := _manager(victim)
	var b: Enemy = m.spawn(load("res://actors/enemies/bloater.tscn"), Vector2(200, 0))
	await wait_physics_frames(1)
	b.global_position = Vector2(20, 0)
	b.die()
	await wait_physics_frames(40)
	assert_eq(_hits, 1)


func test_a_cleared_bloater_does_not_burst() -> void:
	var victim := _victim(Vector2.ZERO)
	var m := _manager(victim)
	var b: Enemy = m.spawn(load("res://actors/enemies/bloater.tscn"), Vector2(200, 0))
	await wait_physics_frames(1)
	b.global_position = Vector2(20, 0)
	m.clear()
	await wait_physics_frames(40)
	assert_eq(_hits, 0, "un vidage ne laisse rien exploser dans la zone suivante")


func _zones(m: EnemyManager) -> Array:
	return m.ground().get_children().filter(func(n: Node) -> bool: return n is DangerZone)


# --------------------------------------------------------------------------
# Le peuplement et les planches
# --------------------------------------------------------------------------

func test_every_archetype_comes_out_of_the_spawner() -> void:
	var spawner := EnemySpawner.new()
	var seen := {}
	for i in 2000:
		seen[spawner._pick_scene()] = true
	spawner.free()
	assert_eq(seen.size(), EnemySpawner.POPULATION.size())


func test_a_sheet_enemy_is_built_once_for_all_its_variants() -> void:
	assert_same(SpriteForge.frames("brute", 0), SpriteForge.frames("brute", 3))
	assert_not_same(SpriteForge.frames("grunt", 0), SpriteForge.frames("grunt", 3), "les grilles varient")
