extends GutTest

## Le Tombeau de glace en 3D (jalon 54, « gangue ») : neuf cristaux percent le sol autour du porteur,
## penchés vers lui, et le suivent ; le buff éteint, ils se rongent, leurs esquilles volent, puis rien.

const COLD := DamageType.Kind.COLD

var _world: Node3D
var _buff: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)
	_buff = Node3D.new()
	_world.add_child(_buff)


func _drawings() -> Array:
	return get_viewport().get_children().filter(func(n: Node) -> bool: return n is FrostTombFx)


func test_the_crystals_close_around_the_bearer_and_lean_toward_him() -> void:
	_buff.position = Vector3(40, 0, 20)
	var fx := FrostTombFx.encase(_buff, COLD)
	assert_eq(fx.get_parent(), get_viewport(), "hors des conteneurs que le jeu compte")
	assert_eq(fx.global_position, Vector3(40, 0, 20), "sur le porteur")
	assert_eq(fx._crystals.size(), FrostTombFx.CRYSTALS)
	fx._clock = FrostTombFx.RISE + FrostTombFx.STAGGER
	fx._show()
	for i in FrostTombFx.CRYSTALS:
		var t := fx._crystals[i].transform
		var foot := Vector3(t.origin.x, 0.0, t.origin.z)
		assert_between(foot.length(), FrostTombFx.RING.x, FrostTombFx.RING.y + 0.01, "autour de lui")
		var up := t.basis * Vector3.UP
		assert_lt(up.dot(foot.normalized()), 0.0, "penché vers lui")
		assert_gt(t.origin.y + up.y, 15.0, "pointe au-dessus du sol")
	_buff.position = Vector3(60, 0, 20)
	fx._process(0.0)
	assert_almost_eq(fx.global_position, Vector3(60, 0, 20), Vector3.ONE * 0.5, "l'Armure de givre le laisse marcher")
	fx.queue_free()


func test_once_the_buff_is_out_they_are_eaten_their_shards_fly_then_nothing() -> void:
	var fx := FrostTombFx.encase(_buff, COLD)
	await wait_process_frames(2)
	assert_false(fx._shards.visible, "entier tant qu'il brûle")
	assert_eq(fx._crystals[0].get_instance_shader_parameter(&"dissolve"), 0.0)
	_buff.queue_free()
	await wait_seconds(FrostTombFx.EATEN * 0.5)
	assert_gt(fx._crystals[0].get_instance_shader_parameter(&"dissolve"), 0.0, "rongés")
	assert_true(fx._shards.visible, "les esquilles volent")
	for i in FrostTombFx.SHARDS:
		assert_gte(fx.shard(i).origin.y, 1.0, "jamais sous le sol")
	await wait_seconds(FrostTombFx.SHARD_LIFE + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


func test_the_tomb_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	Settings.veil(_buff, Settings.SPELLS)
	var fx := FrostTombFx.encase(_buff, COLD)
	for node: GeometryInstance3D in fx.find_children("*", "GeometryInstance3D", true, false):
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	assert_eq(fx.find_children("*", "Decal", true, false).size(), 0, "pas de glace au sol : il n'en pose pas")
	Settings.from_dict(before)
	fx.queue_free()


func test_lighting_the_tomb_encases_its_caster() -> void:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	var before := _drawings()
	var buff := Buff.light(player, SkillCatalog.by_id(SkillStats.TOMB_SKILL), 3.0, true)
	var made := _drawings().filter(func(n: Node) -> bool: return n not in before)
	assert_eq(made.size(), 1, "sa gangue, pas un halo")
	assert_eq(made[0]._buff, buff)
	buff.queue_free()
	await wait_process_frames(3)
	assert_gte(made[0]._broken_at, 0.0, "elle se brise avec lui")
