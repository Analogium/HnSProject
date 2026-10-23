extends GutTest

## Le Nuage d'orage en 3D (jalon 54, « volutes ») : des bosses de cumulus qui prennent la lumière, une
## lueur dedans qui flashe à chaque frappe, un éclair sur chaque cible — des grêlons en grêle. Le
## dessin vit hors du nuage, le suit, et se dissipe après lui.

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _cast(nature := DamageType.Kind.LIGHTNING) -> SkillStats:
	var cast := SkillStats.new()
	cast.nature = nature
	cast.radius = StormCloudFx.RADIUS
	cast.duration = 3.0
	cast.period = 0.5
	cast.simultaneous = 3
	return cast


func _fx_of(cloud: StormCloud) -> StormCloudFx:
	return cloud._fx


func test_the_cloud_is_dressed_outside_and_follows() -> void:
	var cloud := StormCloud.put(_world, Vector3(40, 0, 0), _cast(), null)
	var fx := _fx_of(cloud)
	assert_eq(fx.get_parent(), get_viewport(), "hors des conteneurs que le jeu compte")
	assert_eq(fx._puffs.size(), StormCloudFx.BELLY + StormCloudFx.DOME + 1)
	cloud.global_position = Vector3(100, 0, 20)
	await wait_process_frames(2)
	assert_almost_eq(fx.global_position, cloud.global_position, Vector3.ONE * 0.01, "il suit son nuage")
	for puff in fx._puffs:
		assert_eq(puff.node.mesh, fx._puffs[0].node.mesh, "toutes les bosses partagent leur matière")


func test_it_scales_with_the_radius_not_its_height() -> void:
	var cast := _cast()
	cast.radius = StormCloudFx.RADIUS * 0.5
	var fx := _fx_of(StormCloud.put(_world, Vector3.ZERO, cast, null))
	var wide := _fx_of(StormCloud.put(_world, Vector3.ZERO, _cast(), null))
	assert_almost_eq(fx._puffs[0].size, wide._puffs[0].size * 0.5, 0.01)
	assert_almost_eq(fx._puffs[0].home.y, wide._puffs[0].home.y, 0.01, "à la même hauteur")


func test_a_strike_drops_a_bolt_and_a_flash_on_each_point() -> void:
	var fx := StormCloudFx.gather(_world, DamageType.Kind.LIGHTNING, StormCloudFx.RADIUS)
	autofree(fx)
	var before := fx.get_child_count()
	var calm := fx._light.light_energy
	fx.strike([Vector3(10, 0, 0), Vector3(-10, 0, 5)] as Array[Vector3])
	var born := fx.get_children().slice(before)
	assert_eq(born.size(), 4, "un éclair et un éclat par point")
	var bolt: MeshInstance3D = born[0]
	assert_eq((bolt.mesh.surface_get_material(0) as ShaderMaterial).shader, StormCloudFx.BOLT)
	assert_almost_eq(bolt.global_position, Vector3(10, 0, 0), Vector3.ONE * 0.01, "posé par son pied")
	assert_gt(fx._light.light_energy, calm, "la lueur du dedans flashe")
	await wait_seconds(maxf(StormCloudFx.BOLT_LIFE, StormCloudFx.IMPACT_LIFE) + 0.1)
	assert_eq(fx.get_child_count(), before, "puis rien")
	assert_almost_eq(fx._light.light_energy, calm, 0.01, "et la lueur retombe")


func test_hail_drops_stones_instead() -> void:
	var fx := StormCloudFx.gather(_world, DamageType.Kind.COLD, StormCloudFx.RADIUS)
	autofree(fx)
	var before := fx.get_child_count()
	fx.strike([Vector3.ZERO] as Array[Vector3])
	var stones := fx.get_children().slice(before).filter(
		func(n: Node) -> bool: return (n as MeshInstance3D).mesh == StormCloudFx._stone_mesh)
	assert_eq(stones.size(), StormCloudFx.STONES)


func test_an_empty_strike_still_shows_and_a_crowd_shows_at_most_three() -> void:
	var cloud := StormCloud.put(_world, Vector3.ZERO, _cast(), null)
	var fx := _fx_of(cloud)
	var before := fx.get_child_count()
	cloud._hit(StormCloudFx.RADIUS, 1.0)
	assert_eq(fx.get_child_count() - before, 2, "à vide, un éclair dans le cercle")
	for i in 6:
		var target := Hurtbox.new()
		target.collision_layer = Targets.ENEMIES
		target.collision_mask = 0
		var shape := CollisionShape3D.new()
		shape.shape = SphereShape3D.new()
		target.add_child(shape)
		_world.add_child(target)
		target.global_position = Vector3(i * 2.0, 0, 0)
	await wait_physics_frames(2)
	before = fx.get_child_count()
	cloud._hit(StormCloudFx.RADIUS, 1.0)
	assert_eq(fx.get_child_count() - before, Lightning.ARCS_MOST * 2, "trois éclairs au plus, et leurs éclats")


func test_accumulation_charges_the_glow() -> void:
	var fx := StormCloudFx.gather(_world, DamageType.Kind.LIGHTNING, StormCloudFx.RADIUS)
	autofree(fx)
	var calm := fx._light.light_energy
	fx.charge = 1.0
	assert_almost_eq(fx._light.light_energy, calm + StormCloudFx.CHARGED, 0.001)


func test_the_cloud_gone_its_drawing_dissipates_then_frees() -> void:
	var cloud := StormCloud.put(_world, Vector3.ZERO, _cast(), null)
	var fx := _fx_of(cloud)
	cloud.queue_free()
	await wait_process_frames(3)
	assert_true(is_instance_valid(fx), "il se dissipe")
	assert_lt(fx._puffs[0].node.scale.x, fx._puffs[0].size, "les bosses fondent")
	await wait_seconds(StormCloudFx.DISSIPATION + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


func test_the_cloud_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var cloud := StormCloud.put(_world, Vector3.ZERO, _cast(), null)
	var fx := _fx_of(cloud)
	fx.strike([Vector3.ZERO] as Array[Vector3])
	for node: GeometryInstance3D in fx.find_children("*", "GeometryInstance3D", true, false):
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)
