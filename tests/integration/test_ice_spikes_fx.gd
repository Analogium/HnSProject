extends GutTest

## Les Pics de glace en 3D (jalon 54, « sobre ») : une douzaine de cristaux qui percent le sol au
## rayon qui frappe, puis se brisent en éclats ; la lumière froide et le sol fendu s'éteignent après.
## Le dessin vit hors du nœud du jeu et se libère seul.

const COLD := DamageType.Kind.COLD

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _cast(radius := IceSpikesFx.RADIUS) -> SkillStats:
	var cast := SkillStats.new()
	cast.nature = COLD
	cast.radius = radius
	return cast


func _drawings() -> Array:
	return get_viewport().get_children().filter(func(n: Node) -> bool: return n is IceSpikesFx)


func test_the_spikes_pierce_the_ground_inside_their_circle() -> void:
	var fx := IceSpikesFx.raise(_world, Vector3(40, 0, 0), COLD, IceSpikesFx.RADIUS)
	assert_eq(fx.get_parent(), get_viewport(), "hors des conteneurs que le jeu compte")
	assert_eq(fx._spikes.size(), IceSpikesFx.SPIKES)
	for spike in fx._spikes:
		assert_lt(spike.node.position.y, 0.0, "d'abord sous le sol")
		assert_lte(Vector2(spike.foot.x, spike.foot.z).length(), IceSpikesFx.RADIUS, "dans le cercle qui frappe")
		assert_gt(spike.tip.y, absf(spike.tip.x) + absf(spike.tip.z), "pointe en haut, à peine penchée")
		assert_same(spike.node.material_override, fx._spikes[0].node.material_override, "une matière pour tous")
	await wait_seconds(IceSpikesFx.RISE + IceSpikesFx.STAGGER + 0.05)
	for spike in fx._spikes:
		assert_almost_eq(spike.node.position, spike.foot, Vector3.ONE * 0.01, "puis dressé, le pied au sol")
	fx.queue_free()


func test_a_wider_circle_spreads_them_more_than_it_grows_them() -> void:
	var wide := IceSpikesFx.raise(_world, Vector3.ZERO, COLD, IceSpikesFx.RADIUS * 4.0)
	var far := 0.0
	for spike in wide._spikes:
		far = maxf(far, spike.foot.length())
		assert_lte(spike.tip.y, IceSpikesFx.BIG_LENGTH.y * 2.0 + 0.01, "la taille suit la racine du rayon")
	assert_gt(far, IceSpikesFx.RADIUS, "les pieds suivent le rayon")
	wide.queue_free()


func test_they_shatter_then_everything_frees() -> void:
	var fx := IceSpikesFx.raise(_world, Vector3.ZERO, COLD, IceSpikesFx.RADIUS)
	var lit := fx._light.light_energy
	assert_false(fx._shards.emitting, "pas d'éclats avant de se briser")
	await wait_seconds(IceSpikesFx.SHATTER + 0.05)
	assert_true(fx._shards.emitting, "les éclats volent")
	for spike in fx._spikes:
		assert_false(spike.node.visible, "les pics sont partis")
	assert_lt(fx._light.light_energy, lit, "la lumière retombe")
	await wait_seconds(IceSpikesFx.SHARD_LIFE + 0.05)
	assert_false(fx._shards.emitting, "une salve, pas deux")
	await wait_seconds(IceSpikesFx.CRACKS_LIFE - IceSpikesFx.SHATTER - IceSpikesFx.SHARD_LIFE + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


func test_materials_are_kept_per_nature() -> void:
	var a := IceSpikesFx.raise(_world, Vector3.ZERO, COLD, IceSpikesFx.RADIUS)
	var b := IceSpikesFx.raise(_world, Vector3.ZERO, COLD, IceSpikesFx.RADIUS)
	assert_same(a._cracks.material_override, b._cracks.material_override)
	assert_same(a._shards.process_material, b._shards.process_material)
	assert_same(a._spikes[0].node.material_override, b._spikes[0].node.material_override)
	a.queue_free()
	b.queue_free()


func test_the_spikes_take_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var spikes := IceSpikes.raise_at(_world, Vector3.ZERO, Vector3.RIGHT, _cast(), null)
	await wait_physics_frames(2)
	var fx: IceSpikesFx = _drawings()[0]
	for node: GeometryInstance3D in fx.find_children("*", "GeometryInstance3D", true, false):
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)
	spikes.queue_free()
	fx.queue_free()


## Le Sillon échelonne ses cercles : chacun se dresse quand il frappe, pas à sa pose.
func test_a_delayed_circle_shows_when_it_strikes() -> void:
	var spikes := IceSpikes.raise_at(_world, Vector3.ZERO, Vector3.RIGHT, _cast(), null, null, null, 0.2)
	await wait_physics_frames(3)
	assert_eq(_drawings().size(), 0, "rien avant de percer")
	await wait_seconds(0.25)
	assert_eq(_drawings().size(), 1, "un dessin par cercle")
	spikes.queue_free()
	_drawings()[0].queue_free()
