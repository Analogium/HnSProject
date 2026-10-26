extends GutTest

## L'arbre de la Nova en 3D (jalon 54) : l'Onde de givre porte ses javelots sur son anneau, pointe
## dehors, retournés au Reflux, sur l'onde de choc de la Nova, et se ronge au bout ; le sol gelé tient
## la glace de la Nova le temps de sa durée.

const COLD := DamageType.Kind.COLD
const RADIUS := 46.0

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _cast(ebb := 0.0) -> SkillStats:
	var cast := SkillStats.new()
	cast.skill_id = "ice_nova"
	cast.nature = COLD
	cast.radius = RADIUS
	cast.ebb = ebb
	return cast


func _fx(ring: FrostRing) -> FrostRingFx:
	return ring.find_children("*", "MultiMeshInstance3D", false, false)[0]


## Les javelots montrés, et leur cap : du ventre vers la pointe.
func _shown(fx: FrostRingFx) -> Array[Transform3D]:
	var out: Array[Transform3D] = []
	for i in fx.multimesh.instance_count:
		var t := fx.javelin(i)
		if t.basis.get_scale().y > 0.0:
			out.append(t)
	return out


func test_the_wave_carries_its_javelins_on_its_ring_pointing_out() -> void:
	var ring := FrostRing.spread(_world, Vector3.ZERO, _cast(), null)
	var fx := _fx(ring)
	assert_eq(fx.multimesh.instance_count, int(TAU * RADIUS * FrostRing.REACH / FrostRingFx.SPACING),
			"un tous les seize pixels du plus grand cercle")
	fx._clock = FrostRing.LIFETIME * 0.5
	var r := ring.reach_at(fx._clock)
	var shown := _shown(fx)
	assert_eq(shown.size(), int(TAU * r / FrostRingFx.SPACING), "autant que le cercle en porte")
	for t in shown:
		var along := t.basis.y.normalized()
		var belly := t.origin + along * FrostRingFx.SIZE.y * 0.35
		var flat := Vector3(belly.x, 0.0, belly.z)
		assert_almost_eq(flat.length(), r, 0.5, "sur l'anneau")
		assert_gt(along.dot(flat.normalized()), 0.9, "pointe dehors")


func test_under_the_ebb_they_turn_toward_the_centre() -> void:
	var ring := FrostRing.spread(_world, Vector3.ZERO, _cast(1.0), null)
	var fx := _fx(ring)
	fx._clock = FrostRing.LIFETIME * 1.3
	var shown := _shown(fx)
	assert_gt(shown.size(), 0)
	for t in shown:
		var along := t.basis.y.normalized()
		var belly := t.origin + along * FrostRingFx.SIZE.y * 0.35
		assert_lt(along.dot(Vector3(belly.x, 0, belly.z).normalized()), -0.9, "pointe vers le centre")


func test_its_shock_rides_the_ring_then_everything_is_eaten_and_leaves_with_it() -> void:
	var ring := FrostRing.spread(_world, Vector3.ZERO, _cast(), null)
	var fx := _fx(ring)
	fx._clock = FrostRing.LIFETIME * 0.5
	fx._show()
	var span := fx._shock.scale.x
	assert_almost_eq(fx._shock.get_instance_shader_parameter(&"front") * span,
			ring.reach_at(fx._clock) + FrostRingFx.SHOCK_LEAD, 0.01, "l'onde de choc devant les javelots")
	assert_eq(fx.get_instance_shader_parameter(&"dissolve"), 0.0, "entiers en route")
	fx._clock = FrostRing.LIFETIME - FrostRingFx.EATEN * 0.5
	fx._show()
	assert_eq(_shown(fx).size(), int(TAU * ring.reach_at(fx._clock) / FrostRingFx.SPACING), "tous là")
	assert_gt(fx.get_instance_shader_parameter(&"dissolve"), 0.0, "mais rongés, pas pâlis")
	await wait_seconds(FrostRing.LIFETIME + 0.1)
	assert_false(is_instance_valid(fx), "parti avec l'anneau")


func test_the_wave_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var fx := _fx(FrostRing.spread(_world, Vector3.ZERO, _cast(), null))
	for node in [fx, fx._shock, fx._warp, fx._glints]:
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)


func test_a_frozen_ground_holds_the_nova_ice_then_thaws_and_renews() -> void:
	var cast := _cast()
	cast.ground_duration = 1.0
	var ground := cast.ground(RADIUS)
	var patch := DashTrail.patch(_world, Vector3(300, 0, 300), ground, null)
	await wait_physics_frames(3)
	var frost: FrostGroundFx = patch._frost
	assert_not_null(frost, "un sol de froid a sa glace")
	assert_same(frost._ice.texture_albedo, FrostGroundFx.ICE)
	await wait_seconds(DashTrail.SPAWN)
	assert_almost_eq(frost._ice.size.x, RADIUS * 2.0 * FrostGroundFx.SPAN, 0.01, "ouverte à sa taille")
	assert_almost_eq(frost._ice.size.y, FrostGroundFx.DEPTH, 0.01, "au ras du sol")
	assert_almost_eq(frost._ice.modulate.a, 1.0, 0.001, "tenue")
	patch._age = ground.duration - FrostGroundFx.THAW * 0.3
	await wait_physics_frames(1)
	assert_lt(frost._ice.modulate.a, 1.0, "elle fond sur sa fin")
	DashTrail.patch(_world, Vector3(301, 0, 301), ground, null)
	await wait_physics_frames(1)
	assert_almost_eq(frost._ice.modulate.a, 1.0, 0.001, "ravivé, il repart")
	patch.queue_free()


func test_a_ground_of_another_nature_keeps_its_sparks() -> void:
	var cast := _cast()
	cast.nature = DamageType.Kind.FIRE
	cast.ground_duration = 1.0
	var patch := DashTrail.patch(_world, Vector3(500, 0, 500), cast.ground(RADIUS), null)
	await wait_physics_frames(3)
	assert_null(patch._frost)
	patch.queue_free()
