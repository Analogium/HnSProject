extends GutTest

## La Nova de glace en 3D (jalon 54, « vitrine sans brume ») : toute explosion de froid jette ses
## esquilles en étoile jusqu'à son bord, qui s'y rongent ; une onde de choc, des scintillements, et pas
## de glace au sol — elle dirait un sol gelé ; le dessin vit hors du nœud du jeu et se libère seul.

const COLD := DamageType.Kind.COLD

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _drawings() -> Array:
	return get_viewport().get_children().filter(func(n: Node) -> bool: return n is IceNovaFx)


func _explode(radius: float) -> Explosion:
	var parts := DamageType.empty_parts()
	parts[COLD] = 10.0
	return Explosion.put(_world, Vector3(30, 0, 0), parts, radius, null, DamageType.COLORS[COLD], null, null)


func _farthest(fx: IceNovaFx) -> float:
	var far := 0.0
	for i in IceNovaFx.SLIVERS:
		far = maxf(far, Flat.xz(fx.sliver(i).origin).length())
	return far


func test_a_cold_explosion_blows_its_slivers_to_its_edge_then_frees() -> void:
	_explode(IceNovaFx.RADIUS)
	await wait_physics_frames(2)
	assert_eq(_drawings().size(), 1, "une nova, pas la gerbe générique")
	var fx: IceNovaFx = _drawings()[0]
	assert_almost_eq(fx.global_position, Vector3(30, 0, 0), Vector3.ONE * 0.01)
	await wait_seconds(IceNovaFx.FLY + 0.02)
	var far := _farthest(fx)
	assert_gt(far, IceNovaFx.RADIUS * 0.8, "jusqu'au bord")
	assert_lte(far, IceNovaFx.RADIUS + 0.01, "pas au-delà du cercle qui frappe")
	await wait_seconds(IceNovaFx.EATEN.x - IceNovaFx.FLY + 0.1)
	assert_gt(fx._slivers.get_instance_shader_parameter(&"dissolve"), 0.0, "elles se rongent")
	await wait_seconds(IceNovaFx.EATEN.y - IceNovaFx.EATEN.x)
	assert_false(fx._slivers.visible, "les esquilles sont parties")
	assert_false(fx._shock.visible, "l'onde aussi")
	assert_eq(fx.find_children("*", "Decal", true, false).size(), 0, "pas de glace au sol")
	await wait_seconds(IceNovaFx.GLINT_LIGHT.y - IceNovaFx.EATEN.y + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


func test_a_wider_explosion_throws_further_than_it_grows() -> void:
	var fx := IceNovaFx.blow(_world, Vector3.ZERO, COLD, IceNovaFx.RADIUS * 4.0)
	fx._clock = IceNovaFx.FLY
	assert_gt(_farthest(fx), IceNovaFx.RADIUS * 2.0, "les esquilles suivent le rayon")
	var size := fx.sliver(0).basis.get_scale()
	assert_almost_eq(size.y, IceNovaFx.SLIVER_SIZE.y * 2.0, 0.01, "la taille suit sa racine")
	fx.queue_free()


func test_materials_are_kept_per_nature() -> void:
	var a := IceNovaFx.blow(_world, Vector3.ZERO, COLD, IceNovaFx.RADIUS)
	var b := IceNovaFx.blow(_world, Vector3.ZERO, COLD, IceNovaFx.RADIUS)
	assert_same(a._shock.material_override, b._shock.material_override)
	assert_same(a._warp.material_override, b._warp.material_override)
	assert_same(a._glints.material_override, b._glints.material_override)
	assert_same(a._slivers.material_override, IceSpikesFx.crystal(COLD), "la glace des pics")
	a.queue_free()
	b.queue_free()


func test_the_nova_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	_explode(IceNovaFx.RADIUS)
	await wait_physics_frames(2)
	var fx: IceNovaFx = _drawings()[0]
	for node: GeometryInstance3D in fx.find_children("*", "GeometryInstance3D", true, false):
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)
	fx.queue_free()
