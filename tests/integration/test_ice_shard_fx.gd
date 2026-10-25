extends GutTest

## L'éclat des Pics de glace (jalon 54, « esquille ») : un cristal des pics, pointe dans le sens du vol,
## et une traînée de givre qui lui survit. Les autres éclats (Orbe gelée, Esquilles) gardent le trait.

const BOLT := preload("res://actors/projectiles/player_bolt.tscn")
const COLD := DamageType.Kind.COLD

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _shards_of_spikes() -> Array[Projectile]:
	var cast := SkillStats.new()
	cast.nature = COLD
	cast.radius = 26.0
	cast.splits = 2.0
	IceSpikes.raise_at(_world, Vector3.ZERO, Vector3.FORWARD, cast, null, null, BOLT)
	await wait_seconds(IceSpikes.LIFETIME + 0.05)
	var shards: Array[Projectile] = []
	for node in _world.get_children():
		if node is Projectile:
			shards.append(node)
	return shards


func test_spike_shards_are_slivers_of_their_ice() -> void:
	var shards := await _shards_of_spikes()
	assert_eq(shards.size(), 2)
	for shard in shards:
		assert_not_null(shard._sliver_fx, "un cristal des pics")
		assert_null(shard._bolt_fx, "et non le trait en petit")
		assert_same(shard._sliver_fx._crystal.material_override, IceSpikesFx.crystal(COLD), "la glace des pics")


func test_the_sliver_points_where_it_flies() -> void:
	var shards := await _shards_of_spikes()
	await wait_process_frames(3)
	for shard in shards:
		var nose := -shard._sliver_fx.global_basis.z.normalized()
		assert_gt(nose.dot(shard._dir), 0.95, "pointe en avant")


func test_its_trail_outlives_it_and_it_flares_at_the_end() -> void:
	var shards := await _shards_of_spikes()
	await wait_process_frames(3)
	var trail := shards[0]._sliver_fx.trail
	var before := get_viewport().get_child_count()
	shards[0]._finish()
	await wait_process_frames(2)
	assert_gt(get_viewport().get_child_count(), before, "l'éclat de fin naît")
	assert_true(is_instance_valid(trail), "la traînée retombe")
	await wait_seconds(BoltFx.TRAIL_LIFE + BoltFx.FLARE_LIFE + 0.1)
	assert_false(is_instance_valid(trail), "puis rien")


func test_other_shards_keep_the_bolt() -> void:
	var cast := SkillStats.new()
	cast.nature = COLD
	Projectile.split(_world, BOLT, Vector3.ZERO, Vector3.RIGHT, 0.0, COLD, null, cast, 2, {})
	await wait_process_frames(2)
	for node in _world.get_children():
		if node is Projectile:
			assert_null((node as Projectile)._sliver_fx)


func test_the_sliver_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var parts: Array[float] = [1.0]
	var shard := Projectile.spawn(_world, BOLT, Vector3.ZERO, Vector3.RIGHT, parts, null, 0.0, COLD, SkillStats.new())
	Settings.veil(shard, Settings.SPELLS)
	shard.wear_sliver()
	assert_almost_eq(shard._sliver_fx._crystal.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	assert_almost_eq(shard._sliver_fx.trail.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)
