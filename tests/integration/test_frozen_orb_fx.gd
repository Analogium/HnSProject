extends GutTest

## L'Orbe gelée en 3D (jalon 54, « oursin ») : huit cristaux en étoile qui tournent sur l'orbe, une
## traînée de givre qui lui survit, l'éclat du Trait en grand quand elle éclate.

const COLD := DamageType.Kind.COLD

var _world: Node3D
var _orb: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)
	_orb = Node3D.new()
	_world.add_child(_orb)


func test_the_urchin_turns_on_its_orb_and_its_trail_outlives_it() -> void:
	var fx := FrozenOrbFx.dress(_orb, COLD)
	assert_eq(fx.get_parent(), _orb, "sur l'orbe")
	assert_eq(fx._core.get_child_count(), 8, "huit cristaux")
	for crystal: MeshInstance3D in fx._core.get_children():
		assert_same(crystal.material_override, IceSpikesFx.crystal(COLD), "la glace des Pics")
		var tip := crystal.transform * Vector3.UP
		assert_gt(tip.length(), crystal.transform.origin.length(), "pointe dehors")
	var turned := fx._core.basis
	fx._process(0.1)
	assert_ne(fx._core.basis, turned, "il tourne")
	var trail := fx.trail
	assert_eq(trail.get_parent(), get_viewport(), "la traînée vit hors de l'orbe")
	await wait_process_frames(2)
	_orb.queue_free()
	await wait_physics_frames(2)
	assert_true(is_instance_valid(trail), "et lui survit le temps de s'éteindre")
	await wait_seconds(BoltFx.TRAIL_LIFE + 0.1)
	assert_false(is_instance_valid(trail), "puis se libère")


func test_the_urchin_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	Settings.veil(_orb, Settings.SPELLS)
	var fx := FrozenOrbFx.dress(_orb, COLD)
	for node: GeometryInstance3D in fx.find_children("*", "GeometryInstance3D", true, false) + [fx.trail]:
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)
	fx.trail.queue_free()


func test_a_frozen_orb_wears_the_urchin_not_sparks() -> void:
	var cast := SkillStats.new()
	cast.nature = COLD
	cast.projectile_speed = 110.0
	cast.duration = 1.6
	cast.period = 10.0
	var sparks := func() -> int: return get_viewport().get_children().filter(func(n: Node) -> bool: return n is ElementFx).size()
	var before: int = sparks.call()
	var orb := FrozenOrb.send(_world, Vector3.ZERO, Vector3.RIGHT, cast, null, _world, null, Vector3.RIGHT * 100.0, null)
	assert_not_null(orb._fx)
	assert_eq(sparks.call(), before, "pas d'étincelles")
	orb._fx.trail.queue_free()
	orb.queue_free()
