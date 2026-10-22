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
	assert_eq(made.size(), 5, "flammes, fumée, souffle, brûlure, éclair")
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


## Des photos de feu : le feu garde leurs couleurs, le froid de la boule de Givre y lit sa rampe.
func test_fire_keeps_its_photo_colours_and_other_natures_read_their_ramp() -> void:
	var fire := FlameFx.ball(_host(), DamageType.Kind.FIRE).core.material_override as ShaderMaterial
	var cold := FlameFx.ball(_host(), DamageType.Kind.COLD).core.material_override as ShaderMaterial
	assert_eq(fire.get_shader_parameter(&"native"), 1.0)
	assert_eq(cold.get_shader_parameter(&"native"), 0.0)
	var tint: Color = FlameFx.ramp(DamageType.Kind.COLD)[1]
	assert_eq(cold.get_shader_parameter(&"tint"), Vector3(tint.r, tint.g, tint.b))


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


## Le brasier d'Immolation : le liseré et les langues au rayon qui frappe, à la teinte de sa nature.
func test_a_fire_ring_follows_its_radius_and_nature() -> void:
	var ring := FireRing.light_up(_host())
	ring.show_as(DamageType.Kind.FIRE, 40.0)
	var pm := ring._tongues.process_material as ParticleProcessMaterial
	assert_eq(pm.emission_ring_radius, 40.0, "les langues au bord du cercle")
	assert_eq(ring._ground.scale.x, 40.0, "le liseré au rayon qui frappe")
	ring.show_as(DamageType.Kind.FIRE, 40.0)
	assert_eq(ring._tongues.process_material, pm, "rien n'est refait s'il n'a pas bougé")
	ring.show_as(DamageType.Kind.NECROTIC, 55.0)
	assert_eq((ring._tongues.process_material as ParticleProcessMaterial).emission_ring_radius, 55.0)
	assert_eq(ring._light.light_color, FlameFx.ramp(DamageType.Kind.NECROTIC)[1], "la Flamme noire")


func test_a_fire_ring_takes_its_host_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var host := _host()
	Settings.veil(host, Settings.SPELLS)
	var ring := FireRing.light_up(host)
	assert_almost_eq(ring._ground.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	assert_almost_eq(ring._tongues.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)


## Le Brasero : un trépied de fer pour tous, des braises, des flammes et une lumière à sa nature.
func test_a_brazier_stands_on_one_tripod_in_the_colours_of_its_nature() -> void:
	var fire := BrazierFx.light_up(_host(), DamageType.Kind.FIRE)
	var storm := BrazierFx.light_up(_host(), DamageType.Kind.LIGHTNING)
	assert_eq(fire.body.mesh, storm.body.mesh, "un maillage pour tous")
	assert_eq(fire.body.material_override, storm.body.material_override, "un fer pour tous")
	var lights := storm.find_children("*", "OmniLight3D", false, false)
	assert_eq(lights.size(), 1)
	assert_eq((lights[0] as OmniLight3D).light_color, FlameFx.ramp(DamageType.Kind.LIGHTNING)[1], "la Lanterne d'orage")
	var again := BrazierFx.light_up(_host(), DamageType.Kind.LIGHTNING)
	var flames := func(fx: BrazierFx) -> Material:
		return (fx.find_children("*", "GPUParticles3D", false, false)[0] as GPUParticles3D).process_material
	assert_eq(flames.call(storm), flames.call(again), "les flammes d'une nature, gardées")
	assert_ne(flames.call(storm), flames.call(fire))


func test_a_brazier_takes_its_host_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var host := _host()
	Settings.veil(host, Settings.SPELLS)
	var fx := BrazierFx.light_up(host, DamageType.Kind.FIRE)
	var veiled := fx.find_children("*", "GeometryInstance3D", false, false).filter(
		func(n: Node) -> bool: return n != fx.body
	)
	assert_eq(veiled.size(), 3, "les braises, les flammes, les escarbilles")
	for node: GeometryInstance3D in veiled:
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)


## La Ruée ardente : un sol calciné aussi long et aussi large que le couloir qui frappe.
func test_a_fire_dash_lays_a_burnt_path_as_wide_as_it_strikes() -> void:
	var cast := SkillStats.new()
	cast.nature = DamageType.Kind.FIRE
	cast.radius = 16.0
	cast.duration = 3.0
	cast.period = 0.5
	var trail := DashTrail.leave(_world, Vector3(10, 0, 0), Vector3(150, 0, 0), cast, null)
	var path := trail.get_child(0) as BurntPath
	assert_not_null(path, "la ruée de feu laisse son sol")
	assert_almost_eq(path.global_position.x, 80.0, 0.01, "posé au milieu du couloir")
	assert_eq(path._ground.scale, Vector3(70.0 + 16.0, 1.0, 16.0), "aussi long et large que le couloir")
	assert_eq(path._ground.get_instance_shader_parameter(&"half_len"), 70.0)


func test_a_cold_trail_lays_no_burnt_path() -> void:
	var cast := SkillStats.new()
	cast.nature = DamageType.Kind.COLD
	cast.radius = 16.0
	cast.duration = 3.0
	cast.period = 0.5
	var trail := DashTrail.leave(_world, Vector3.ZERO, Vector3(100, 0, 0), cast, null)
	assert_eq(trail.get_child_count(), 0, "le sol calciné est du feu")


## Il s'éteint sur la durée du couloir, et prend le voile des sorts.
func test_a_burnt_path_fades_over_its_duration_and_takes_the_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var host := _host()
	Settings.veil(host, Settings.SPELLS)
	var path := BurntPath.lay(host, Vector3(100, 0, 0), DamageType.Kind.FIRE, 16.0, 0.4)
	assert_almost_eq(path._ground.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	assert_almost_eq(path._embers.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)
	await wait_seconds(0.5)
	assert_almost_eq(float(path._ground.get_instance_shader_parameter(&"life")), 1.0, 0.001, "éteint")
	assert_almost_eq(path._embers.amount_ratio, 0.0, 0.001, "plus de braises")
	assert_almost_eq(path._light.light_energy, 0.0, 0.001, "ni de lueur")
