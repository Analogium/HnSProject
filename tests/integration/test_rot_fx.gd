extends GutTest

## Le manuel nécrotique en 3D (jalon 54, à la barre de Last Epoch) : le souffle de toute explosion nécrotique,
## l'Haleine en cône, le crâne de la Peste et l'os des Lanceurs, la Nuée, le sceau et l'œil de la Malédiction,
## la faille et les créatures de la Porte, l'aura de la Nécrose, le Marais et la levée des morts-vivants. Chacun
## suit ce qu'il montre, lui survit le temps de s'éteindre, prend le voile des sorts et garde ses matières.

const ROT := DamageType.Kind.NECROTIC

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _rooted(type: Variant) -> Array:
	return get_viewport().get_children().filter(
		func(n: Node) -> bool: return is_instance_of(n, type) and not n.is_queued_for_deletion())


func _cast(radius := 32.0, duration := 2.0) -> SkillStats:
	var cast := SkillStats.new()
	cast.nature = ROT
	cast.radius = radius
	cast.duration = duration
	cast.period = 0.3
	return cast


func _parts() -> Array[float]:
	var parts := DamageType.empty_parts()
	parts[ROT] = 10.0
	return parts


func test_rot_necrotic_explosion_blows_gas_then_frees() -> void:
	var sparks := _rooted(ElementFx).size()
	var blasts := _rooted(RotBlastFx).size()
	Explosion.put(_world, Vector3(30, 0, 0), _parts(), 20.0, null, DamageType.COLORS[ROT], null, null)
	await wait_physics_frames(2)
	assert_eq(_rooted(RotBlastFx).size(), blasts + 1, "le souffle nécrotique, pas la gerbe générique")
	assert_eq(_rooted(ElementFx).size(), sparks)
	var fx: RotBlastFx = _rooted(RotBlastFx).back()
	assert_same(fx._wall.material_override, RotBlastFx.gas_material(ROT), "une matière par nature")
	assert_eq(fx._wall.material_override.get_shader_parameter(&"wind"), RotBlastFx.GAS)
	assert_eq(fx._wall.get_instance_shader_parameter(&"span"), 1.0, "le tour entier")
	assert_true(fx._warp.visible, "l'air poussé")
	assert_eq(fx.find_children("*", "GPUParticles3D", true, false).size(), 1, "ses volutes")
	await wait_seconds(RotBlastFx.PUFF_LIFE + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


## L'Haleine : le mur en cône, à l'angle du geste, sans l'air poussé qui tordait le sol derrière le lanceur.
func test_rot_breath_blows_a_cone_without_warp() -> void:
	var breath := ToxicBreath.exhale(_world, Vector3.ZERO, Vector3.FORWARD, _cast(30.0), null)
	var fx: RotBlastFx = _rooted(RotBlastFx).back()
	assert_almost_eq(fx._wall.get_instance_shader_parameter(&"span"), ToxicBreath.HALF_ANGLE / PI, 0.001)
	assert_false(fx._warp.visible)
	assert_almost_eq(fx.rotation.y, -Flat.angle(Vector3.FORWARD), 0.001, "tourné vers le souffle")
	assert_almost_eq(fx._wall.scale.x, 30.0 * ToxicBreath.REACH * 1.1, 0.01, "à la portée du cône")
	breath.queue_free()


func test_rot_plague_wears_a_skull_and_its_smoke_trail_survives_it() -> void:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	var bolt := Projectile.spawn(_world, player.bolt_scene, Vector3.ZERO, Vector3.RIGHT, _parts(), player, 60.0, ROT, _cast())
	var fx := bolt._trail as PlagueFx
	assert_not_null(fx, "le crâne et sa traînée, pas les étincelles")
	assert_eq(fx.get_parent(), get_viewport(), "la traînée hors des tirs")
	assert_eq(fx.skull.get_parent(), bolt, "le crâne sur le trait")
	assert_same(fx.skull.material_override, PlagueFx.skull_material(ROT))
	bolt._finish()
	await wait_process_frames(2)
	assert_true(is_instance_valid(fx), "sa traînée retombe")
	await wait_seconds(PlagueFx.SMOKE_LIFE + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


## Un os : le crâne de la Peste part quand le trait se rhabille.
func test_rot_bone_drops_the_skull() -> void:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	var bolt := Projectile.spawn(_world, player.bolt_scene, Vector3.ZERO, Vector3.RIGHT, _parts(), player, 60.0, ROT, _cast())
	var skull := (bolt._trail as PlagueFx).skull
	bolt.wear_bone()
	await wait_process_frames(1)
	assert_false(is_instance_valid(skull))
	assert_null(bolt._trail)
	assert_not_null(bolt._bone_fx)
	assert_eq(bolt._bone_fx.mesh, PlagueFx.bone(_world).mesh, "un maillage pour tous")


## La Nuée : un nuage et ses mouches, sans le plasma de la foudre ; chaque morsure souffle du gaz.
func test_rot_necrotic_orb_is_a_swarm_that_bites_with_gas() -> void:
	var cast := _cast(26.0, 3.0)
	var orb := StaticOrb.send(_world, Vector3.ZERO, Vector3.RIGHT, cast, null)
	assert_null(orb._fx)
	var swarm: PlagueFx = _rooted(PlagueFx).back()
	assert_null(swarm.skull)
	assert_eq(swarm._flies.multimesh.instance_count, PlagueFx.FLIES)
	assert_ne(swarm.fly(0).origin, swarm.fly(1).origin)
	var before := _rooted(RotBlastFx).size()
	orb._strike()
	assert_eq(_rooted(RotBlastFx).size(), before + 1)
	orb.queue_free()


func test_rot_curse_seal_and_eye_then_mark_follows_its_head() -> void:
	var cast := _cast(40.0)
	var curse := PutridCurse.fall(_world, Vector3.ZERO, cast, null)
	var fx := curse._fx
	assert_almost_eq(fx._sigil.scale.x, 40.0, 0.01, "au rayon qui maudit")
	assert_eq(fx._eye.get_instance_shader_parameter(&"lid"), 0.0, "l'œil fermé à la pose")
	await wait_seconds(CurseFx.OPEN + 0.05)
	assert_almost_eq(fx._eye.get_instance_shader_parameter(&"lid"), 1.0, 0.01, "puis ouvert")
	await wait_seconds(PutridCurse.LIFETIME)
	assert_false(is_instance_valid(fx), "parti avec le sceau")
	var mark := CurseFx.fall(_world, ROT, 40.0, 2.0, true)
	assert_almost_eq(mark._sigil.scale.x, CurseFx.MARK_SIGIL, 0.01, "un petit sceau sous le marqué")
	mark.over(30.0)
	assert_almost_eq(mark._eye.position.y, 30.0 + CurseFx.MARK_EYE, 0.01, "au-dessus de sa tête")


func test_rot_gate_draws_its_crawlers_and_they_swell() -> void:
	var cast := _cast(30.0, 3.0)
	var gate := RottingGate.open(_world, Vector3.ZERO, cast, null)
	var fx := gate._fx
	assert_eq(fx.get_parent(), gate)
	await wait_seconds(cast.period * 2.0 + 0.05)
	await wait_process_frames(1)
	assert_eq(fx._crawlers.multimesh.visible_instance_count, gate._crawlers.size(), "une créature, un dessin")
	assert_gt(gate._crawlers.size(), 0)
	assert_gt(RotGateFx.size_of(false, false, false, 2.0), RotGateFx.size_of(false, false, false, 0.0), "la Gestation")
	assert_gt(RotGateFx.size_of(false, false, true, 0.0), 1.0, "l'amalgame")
	assert_lt(RotGateFx.size_of(true, true, false, 0.0), RotGateFx.size_of(true, false, false, 0.0), "les derniers")
	gate.queue_free()


## La Nécrose avancée : le liseré de gaz aux pieds et ses spores, sans la lumière de la Lumière sacrée.
func test_rot_necrosis_wears_a_gas_rim_without_light() -> void:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	var halo := Buff.light(player, SkillCatalog.by_id(SkillStats.NECROSIS_SKILL))._halo_fx
	assert_not_null(halo)
	assert_same(halo._rim.material_override, RotBlastFx.gas_material(ROT))
	assert_eq(halo.find_children("*", "Light3D", true, false).size(), 0, "la nécrose n'éclaire pas")


## Le Marais : de la boue en décal, sans les scintillements de la glace.
func test_rot_marsh_lays_sludge() -> void:
	var ground := _cast(30.0, 2.0)
	ground.skill_id = "toxic_unleash"
	var patch := DashTrail.patch(_world, Vector3.ZERO, ground, null)
	await wait_physics_frames(2)
	assert_not_null(patch._frost)
	assert_eq(patch._frost._ice.texture_albedo, FrostGroundFx.SLUDGE)
	assert_null(patch._frost._glints)


func test_rot_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var curse := PutridCurse.fall(_world, Vector3.ZERO, _cast(), null)
	var gate := RottingGate.open(_world, Vector3.ZERO, _cast(), null)
	var blast := RotBlastFx.blow(curse, Vector3.ZERO, ROT, 20.0)
	for node: Node in [curse._fx._sigil, curse._fx._eye, gate._fx._body.get_child(0), gate._fx._body.get_child(1), gate._fx._crawlers, blast._wall, blast._warp]:
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)


## La Déferlante et le Fardeau partagé soufflent autour du porteur : le dessin le suit, le coup non.
func test_rot_blast_rides_its_bearer() -> void:
	var bearer := Node3D.new()
	_world.add_child(bearer)
	var blast := Explosion.put(_world, Vector3.ZERO, _parts(), 20.0, null, DamageType.COLORS[ROT], null, null)
	blast.around = bearer
	await wait_physics_frames(2)
	var fx: RotBlastFx = bearer.get_children().filter(func(n: Node) -> bool: return n is RotBlastFx)[0]
	bearer.global_position = Vector3(40, 0, 0)
	assert_almost_eq(fx.global_position, bearer.global_position, Vector3.ONE * 0.01)

