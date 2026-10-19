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


func _victim(at: Vector3) -> Node3D:
	var body := Node3D.new()
	body.position = at
	var hb := Hurtbox.new()
	hb.collision_layer = Targets.PLAYER_SIDE
	hb.collision_mask = 0
	hb.stats = CharacterStats.new()
	hb.states = StatusEffects.new()
	var shape := CollisionShape3D.new()
	shape.shape = SphereShape3D.new()
	(shape.shape as SphereShape3D).radius = 8.0
	hb.add_child(shape)
	body.add_child(hb)
	add_child_autofree(body)
	hb.damaged.connect(func(_info: DamageInfo) -> void: _hits += 1)
	return body


func _manager(victim: Node3D) -> EnemyManager:
	var m := EnemyManager.new()
	add_child_autofree(m)
	m.target = victim
	return m


func _zone(shape: DangerZone.Shape, reach: float, facing := Vector3.RIGHT, spread := 0.0) -> DangerZone:
	var z := DangerZone.put(self, Vector3.ZERO, shape, reach, 0.2, facing, spread)
	await wait_physics_frames(1)
	return z


# --------------------------------------------------------------------------
# La zone
# --------------------------------------------------------------------------

func test_a_disc_holds_its_radius() -> void:
	var z := await _zone(DangerZone.Shape.DISC, 30.0)
	assert_true(z.contains(Vector3(0, 0.0, 29)))
	assert_false(z.contains(Vector3(22, 0.0, 22)), "la diagonale sort avant le carré")


func test_a_lane_starts_at_its_owner_and_goes_one_way() -> void:
	var z := await _zone(DangerZone.Shape.LANE, 100.0, Vector3.BACK, 7.0)
	assert_true(z.contains(Vector3(5, 0.0, 90)))
	assert_false(z.contains(Vector3(0, 0.0, -10)), "rien derrière")
	assert_false(z.contains(Vector3(9, 0.0, 50)), "rien à côté")


func test_a_cone_opens_forward_only() -> void:
	var z := await _zone(DangerZone.Shape.CONE, 50.0, Vector3.RIGHT, 0.6)
	assert_true(z.contains(Vector3(40, 0.0, 15)))
	assert_false(z.contains(Vector3(20, 0.0, 30)), "hors de l'angle")
	assert_false(z.contains(Vector3(-10, 0.0, 0)), "rien derrière")


## Le dessin (jalon 54) : un plan juste à la forme, tourné vers le cap, qui se remplit.
func test_a_lane_is_drawn_along_its_course() -> void:
	var z := await _zone(DangerZone.Shape.LANE, 100.0, Vector3.BACK, 7.0)
	var plane := z.mesh as PlaneMesh
	assert_almost_eq(plane.size.x, 102.0, 0.01, "la longueur du couloir, et un pixel de bord")
	assert_almost_eq(plane.size.y, 16.0, 0.01)
	var far := z.global_transform * (plane.center_offset + Vector3(plane.size.x * 0.5, 0, 0))
	assert_almost_eq(far.z, 101.0, 0.01, "le bout du plan est au bout du couloir, vers +Z")
	var progress: float = (z.material_override as ShaderMaterial).get_shader_parameter("progress")
	assert_between(progress, 0.01, 0.5, "le plein monte")


func test_a_zone_strikes_the_player_side_when_full() -> void:
	_victim(Vector3(10, 0.0, 0))
	var z := DangerZone.put(self, Vector3.ZERO, DangerZone.Shape.CONE, 40.0, 0.2, Vector3.RIGHT, 0.6)
	z.parts = DamageType.empty_parts()
	z.parts[DamageType.Kind.PHYSICAL] = 5.0
	await wait_physics_frames(6)
	assert_eq(_hits, 0, "rien avant que le plein n'atteigne le bord")
	await wait_physics_frames(12)
	assert_eq(_hits, 1)


func test_a_zone_spares_what_stands_outside() -> void:
	_victim(Vector3(-20, 0.0, 0))
	var z := DangerZone.put(self, Vector3.ZERO, DangerZone.Shape.CONE, 40.0, 0.1, Vector3.RIGHT, 0.6)
	z.parts = DamageType.empty_parts()
	z.parts[DamageType.Kind.PHYSICAL] = 5.0
	await wait_physics_frames(15)
	assert_eq(_hits, 0)


func test_a_zone_without_parts_never_strikes() -> void:
	_victim(Vector3(10, 0.0, 0))
	DangerZone.put(self, Vector3.ZERO, DangerZone.Shape.LANE, 40.0, 0.1, Vector3.RIGHT, 8.0)
	await wait_physics_frames(15)
	assert_eq(_hits, 0)


func test_a_bound_zone_falls_with_its_enemy() -> void:
	_victim(Vector3(10, 0.0, 0))
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child(grunt)
	var z := DangerZone.put(self, Vector3.ZERO, DangerZone.Shape.DISC, 30.0, 0.3)
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
	var victim := _victim(Vector3.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/charger.tscn"), Vector3(100, 0.0, 0))
	await wait_physics_frames(3)
	assert_eq(_zones(m).size(), 1, "le couloir d'abord")
	await wait_physics_frames(90)
	assert_eq(_hits, 1, "une charge frappe une fois")


func test_the_mortar_hits_where_the_victim_stood() -> void:
	var victim := _victim(Vector3.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/mortar.tscn"), Vector3(150, 0.0, 0))
	await wait_physics_frames(80)
	assert_gt(_hits, 0)


func test_the_mortar_misses_who_moved_away() -> void:
	var victim := _victim(Vector3.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/mortar.tscn"), Vector3(150, 0.0, 0))
	await wait_physics_frames(3)
	assert_eq(_zones(m).size(), 1, "l'obus est parti")
	victim.position = Vector3(0, 0.0, 80)
	await wait_physics_frames(66)
	assert_eq(_hits, 0)


func test_the_brute_hits_what_stays_in_front() -> void:
	var victim := _victim(Vector3.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/brute.tscn"), Vector3(30, 0.0, 0))
	await wait_physics_frames(60)
	assert_eq(_hits, 1)


func test_the_brute_misses_who_leaves_the_cone() -> void:
	var victim := _victim(Vector3.ZERO)
	var m := _manager(victim)
	m.spawn(load("res://actors/enemies/brute.tscn"), Vector3(30, 0.0, 0))
	await wait_physics_frames(3)
	victim.position = Vector3(30, 0.0, -45)
	await wait_physics_frames(57)
	assert_eq(_hits, 0)


func test_the_bloater_swells_then_bursts_without_reward() -> void:
	var victim := _victim(Vector3.ZERO)
	var m := _manager(victim)
	var b: Enemy = m.spawn(load("res://actors/enemies/bloater.tscn"), Vector3(15, 0.0, 0))
	await wait_physics_frames(60)
	assert_eq(_hits, 1)
	assert_false(is_instance_valid(b), "il meurt de son explosion")


func test_a_killed_bloater_still_bursts() -> void:
	var victim := _victim(Vector3.ZERO)
	var m := _manager(victim)
	var b: Enemy = m.spawn(load("res://actors/enemies/bloater.tscn"), Vector3(200, 0.0, 0))
	await wait_physics_frames(1)
	b.global_position = Vector3(20, 0.0, 0)
	b.die()
	await wait_physics_frames(40)
	assert_eq(_hits, 1)


func test_a_cleared_bloater_does_not_burst() -> void:
	var victim := _victim(Vector3.ZERO)
	var m := _manager(victim)
	var b: Enemy = m.spawn(load("res://actors/enemies/bloater.tscn"), Vector3(200, 0.0, 0))
	await wait_physics_frames(1)
	b.global_position = Vector3(20, 0.0, 0)
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
	assert_not_same(SpriteForge.frames("undead", 0), SpriteForge.frames("undead", 3), "les grilles varient")
