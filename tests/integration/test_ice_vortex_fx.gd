extends GutTest

## Le Désastre hivernal en 3D (jalon 54, « blizzard ») : le tourbillon suit la portée de son vortex, qui
## grandit — que l'Implosion resserre —, ses esquilles orbitent dedans ; le vortex parti, il se ronge.

const COLD := DamageType.Kind.COLD
const RADIUS := 52.0

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _cast(shape := Skill.Shape.VORTEX) -> SkillStats:
	var cast := SkillStats.new()
	cast.skill_id = "winter_disaster"
	cast.nature = COLD
	cast.shape = shape
	cast.radius = RADIUS
	cast.duration = 4.0
	cast.period = 0.5
	return cast


func _fx() -> IceVortexFx:
	return get_viewport().get_children().filter(func(n: Node) -> bool: return n is IceVortexFx).back()


func _covers(fx: IceVortexFx) -> float:
	return fx._disc.get_instance_shader_parameter(&"reach") * fx._disc.scale.x


func test_the_swirl_follows_its_vortex_as_it_grows() -> void:
	var vortex := IceVortex.open(_world, Vector3(30, 0, 10), _cast(), null)
	await wait_physics_frames(2)
	var fx := _fx()
	fx._process(0.0)
	assert_eq(fx.global_position, vortex.global_position, "sur son vortex")
	assert_almost_eq(_covers(fx), vortex.reach(), 0.01, "à sa portée")
	for i in IceVortexFx.CHIPS:
		var at := fx.chip(i).origin
		assert_lte(Vector2(at.x, at.z).length(), vortex.reach() + 0.01, "les esquilles dedans")
	var small := vortex.reach()
	vortex._age = 3.0
	fx._process(0.0)
	assert_gt(_covers(fx), small, "il grandit avec lui")
	vortex.queue_free()


func test_the_implosion_tightens_it() -> void:
	var vortex := IceVortex.open(_world, Vector3.ZERO, _cast(Skill.Shape.IMPLOSION), null)
	await wait_physics_frames(2)
	var fx := _fx()
	fx._process(0.0)
	var wide := _covers(fx)
	vortex._age = 3.0
	fx._process(0.0)
	assert_lt(_covers(fx), wide, "il se resserre")
	vortex.queue_free()


func test_once_the_vortex_is_gone_it_is_eaten_then_nothing() -> void:
	var vortex := IceVortex.open(_world, Vector3.ZERO, _cast(), null)
	await wait_physics_frames(2)
	var fx := _fx()
	assert_eq(fx._disc.get_instance_shader_parameter(&"dissolve"), 0.0)
	vortex.queue_free()
	await wait_seconds(IceVortexFx.EATEN * 0.5)
	assert_gt(fx._disc.get_instance_shader_parameter(&"dissolve"), 0.0, "rongé")
	await wait_seconds(IceVortexFx.EATEN + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


func test_the_swirl_takes_the_spell_veil_and_keeps_its_material() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var a := IceVortex.open(_world, Vector3.ZERO, _cast(), null)
	var b := IceVortex.open(_world, Vector3(200, 0, 0), _cast(), null)
	await wait_physics_frames(1)
	var fxs := get_viewport().get_children().filter(func(n: Node) -> bool: return n is IceVortexFx)
	var fx: IceVortexFx = fxs[-1]
	for node: GeometryInstance3D in fx.find_children("*", "GeometryInstance3D", true, false):
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	assert_eq(fx.find_children("*", "Decal", true, false).size(), 0, "pas de glace au sol : il n'en pose pas")
	assert_same(fx._disc.material_override, (fxs[-2] as IceVortexFx)._disc.material_override, "une matière par nature")
	Settings.from_dict(before)
	a.queue_free()
	b.queue_free()
