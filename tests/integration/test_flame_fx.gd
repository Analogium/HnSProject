extends GutTest

## La boule de feu en 3D (jalon 54) : un cœur et une lumière sur la boule, une traînée qui lui
## survit ; à l'explosion, des flammes, une fumée, une brûlure et un éclair qui se libèrent seuls.

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _host(at := Vector3.ZERO) -> Node3D:
	var host := Node3D.new()
	_world.add_child(host)
	host.global_position = at
	return host


func test_a_ball_carries_its_core_and_light_and_its_trail_outlives_it() -> void:
	var host := _host(Vector3(10, 0, 0))
	var fx := FlameFx.ball(host, DamageType.Kind.FIRE)
	assert_eq(fx.core.get_parent(), host, "le cœur part avec la boule")
	assert_eq(host.get_children().filter(func(n: Node) -> bool: return n is OmniLight3D).size(), 1, "sa lueur au sol")
	host.global_position = Vector3(60, 0, 0)
	await wait_process_frames(2)
	assert_almost_eq(fx.global_position, Vector3(60, ElementFx.LIFT, 0), Vector3.ONE * 0.01)
	host.queue_free()
	await wait_process_frames(2)
	assert_true(is_instance_valid(fx), "la traînée finit de retomber")
	await wait_seconds(FlameFx.FLAME_LIFE + 0.1)
	assert_false(is_instance_valid(fx))


func test_a_blast_frees_all_it_lays() -> void:
	var made := FlameFx.blast(_host(), Vector3(5, 0, 5), DamageType.Kind.FIRE, 30.0)
	assert_eq(made.size(), 4, "flammes, fumée, brûlure, éclair")
	await wait_seconds(FlameFx.SCORCH_LIFE + 0.2)
	for node in made:
		assert_false(is_instance_valid(node), "%s libéré" % node)


func test_the_blast_grows_with_its_radius() -> void:
	var small: GPUParticles3D = FlameFx.blast(_host(), Vector3.ZERO, DamageType.Kind.FIRE, 20.0)[0]
	var wide: GPUParticles3D = FlameFx.blast(_host(), Vector3.ZERO, DamageType.Kind.FIRE, 60.0)[0]
	assert_gt(wide.amount, small.amount)
	assert_gt((wide.process_material as ParticleProcessMaterial).scale_max,
		(small.process_material as ParticleProcessMaterial).scale_max)


func test_the_core_takes_its_host_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.4
	var host := _host()
	Settings.veil(host, Settings.SPELLS)
	var fx := FlameFx.ball(host, DamageType.Kind.FIRE)
	assert_almost_eq(fx.core.get_instance_shader_parameter(&"opacity"), 0.4, 0.001)
	assert_almost_eq(fx.get_instance_shader_parameter(&"opacity"), 0.4, 0.001)
	Settings.from_dict(before)


## Gardée : fabriquée à chaque tir, sa rampe repartait au GPU à chaque fois.
func test_two_balls_of_a_nature_share_their_materials() -> void:
	var a := FlameFx.ball(_host(), DamageType.Kind.COLD)
	var b := FlameFx.ball(_host(), DamageType.Kind.COLD)
	assert_eq(a.process_material, b.process_material)
	assert_eq(a.core.material_override, b.core.material_override)
	assert_ne(a.process_material, FlameFx.ball(_host(), DamageType.Kind.FIRE).process_material)


func test_a_fireball_spark_shows_a_small_flame() -> void:
	var cast := SkillCatalog.by_id("fireball").resolve(1, CharacterStats.new())
	var ball := Fireball.spark(_world, Vector3.ZERO, Vector3.RIGHT, cast, null)
	assert_not_null(ball._flame, "la boule montre son feu")
	assert_almost_eq(ball._flame.core.scale.x, FlameFx.SHARD, 0.001, "un éclat, la mini-boule")
	assert_eq(ball._flame.amount, FlameFx.SHARD_WISPS, "une traînée d'éclat")
	await wait_process_frames(1)
	assert_eq(ball.get_children().filter(func(n: Node) -> bool: return n is OmniLight3D).size(), 0, "sans lumière à lui")


## Le Météore : la boule en grand tombe d'en haut, son ombre grandit, puis il éclate en flammes.
func test_a_meteor_falls_onto_its_growing_shadow() -> void:
	var cast := SkillCatalog.by_id("fireball").resolve(1, CharacterStats.new())
	var meteor := Meteor.fall(_world, Vector3(40, 0, 0), cast, null)
	assert_almost_eq(meteor._faller.position, Meteor.FROM, Vector3.ONE * 0.01, "il part d'en haut")
	await wait_seconds(Meteor.FALL * 0.5)
	assert_lt(meteor._faller.position.y, Meteor.FROM.y, "il tombe")
	assert_gt(meteor._shadow.get_instance_shader_parameter(&"progress"), 0.3, "son ombre grandit")
	# Relevé à la naissance : l'explosion du feu ne dure que `Explosion.BLAZE_LIFE`.
	var flames: Array[bool] = []
	_world.child_entered_tree.connect(func(n: Node) -> void:
		if n is Explosion:
			flames.append((n as Explosion).flames))
	await wait_seconds(Meteor.FALL)
	assert_eq(flames, [true] as Array[bool], "il éclate comme la boule, une fois")


func test_a_small_meteor_keeps_the_size_of_a_ball() -> void:
	var cast := SkillCatalog.by_id("fireball").resolve(1, CharacterStats.new())
	var big := Meteor.fall(_world, Vector3.ZERO, cast, null)
	var small := Meteor.fall(_world, Vector3(80, 0, 0), cast, null, null, null, true)
	var core_of := func(m: Meteor) -> MeshInstance3D:
		return m._faller.get_children().filter(func(n: Node) -> bool: return n is MeshInstance3D)[0]
	assert_almost_eq(core_of.call(big).scale.x, FlameFx.METEOR, 0.001)
	assert_almost_eq(core_of.call(small).scale.x, 1.0, 0.001)
