extends GutTest

## Le trait de foudre en 3D (jalon 54), façon Kinetic Bolt : un orbe qui zigzague autour de la
## vraie trajectoire, une traînée qui lui survit, un éclat à sa fin ; le froid du joueur prend le
## même geste en glace (le Trait de glace), son feu celui de la boule (le Familier), les autres
## natures gardent leurs étincelles ; les Esquilles en petit, l'Orbe statique en boule de plasma.

const BOLT := preload("res://actors/projectiles/player_bolt.tscn")

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _shoot(nature: int, dir := Vector3.RIGHT, cast: SkillStats = null) -> Projectile:
	return Projectile.spawn(_world, BOLT, Vector3.ZERO, dir, DamageType.empty_parts(), null, 0.0, nature, cast)


func _fx_of(bolt: Projectile) -> Array:
	return bolt.get_children().filter(func(n: Node) -> bool: return n is BoltFx)


func test_a_lightning_bolt_shows_the_zigzag_and_the_others_their_sparks() -> void:
	var storm := _shoot(DamageType.Kind.LIGHTNING)
	assert_eq(_fx_of(storm).size(), 1, "l'éclair")
	assert_null(storm._trail, "sans étincelles en plus")
	var cold := _shoot(DamageType.Kind.COLD)
	assert_eq(_fx_of(cold).size(), 0, "le tir de glace d'un caster")
	assert_not_null(cold._trail, "garde ses étincelles")


func test_the_players_cold_bolt_is_the_same_gesture_in_ice() -> void:
	var bolt := _shoot(DamageType.Kind.COLD, Vector3.RIGHT, SkillStats.new())
	assert_null(bolt._trail, "sans étincelles")
	var fx: BoltFx = _fx_of(bolt)[0]
	var shown := fx._orb.find_children("*", "MeshInstance3D", true, false)
	assert_eq(shown.size(), 1, "un orbe de glace, sans arcs")
	var orb := (shown[0] as MeshInstance3D).mesh.surface_get_material(0) as ShaderMaterial
	assert_eq(orb.shader, BoltFx.FROST, "mêlé au sol, pas additionné")
	assert_eq((fx.trail.material_override as ShaderMaterial).shader, BoltFx.FROST_TRAIL)
	var flash := BoltFx.flash_of(DamageType.Kind.COLD)
	assert_eq((flash.mesh.surface_get_material(0) as ShaderMaterial).get_shader_parameter(&"photo"), BoltFx.FROST_BURST,
		"il éclate en glace")
	flash.free()


func test_the_players_fire_bolt_carries_the_fireball() -> void:
	assert_eq(_fx_of(_shoot(DamageType.Kind.FIRE)).size(), 0, "sans lancer, ses étincelles")
	var bolt := _shoot(DamageType.Kind.FIRE, Vector3.RIGHT, SkillStats.new())
	assert_null(bolt._trail)
	var fx: BoltFx = _fx_of(bolt)[0]
	var shown := fx._orb.find_children("*", "MeshInstance3D", true, false)
	assert_eq(shown.size(), 1, "la boule, sans arcs")
	var ball := (shown[0] as MeshInstance3D).mesh.surface_get_material(0) as ShaderMaterial
	assert_eq(ball.get_shader_parameter(&"photo"), BoltFx.FIRE_BALL)
	assert_eq(ball.get_shader_parameter(&"cell"), Vector4(0.0, 0.0, 1.0 / 3.0, 1.0), "une case de l'atlas")
	assert_eq((fx.trail.material_override as ShaderMaterial).get_shader_parameter(&"photo"), BoltFx.FIRE_STREAK)


func test_splinters_are_small_bolts() -> void:
	Projectile.split(_world, BOLT, Vector3.ZERO, Vector3.RIGHT, 200.0, DamageType.Kind.LIGHTNING, null,
		SkillStats.new(), 4, {})
	var shards := _world.get_children().filter(func(n: Node) -> bool: return n is Projectile)
	assert_eq(shards.size(), 4)
	for shard: Projectile in shards:
		var fx: BoltFx = _fx_of(shard)[0]
		assert_almost_eq(fx.scale.x, BoltFx.SHARD, 0.001)
		assert_almost_eq(fx.trail.width, BoltFx.TRAIL_WIDTH * BoltFx.SHARD, 0.001, "la traînée aussi")
	(shards[0] as Projectile)._nature = DamageType.Kind.LIGHTNING
	(shards[0] as Projectile)._dress()
	assert_almost_eq((_fx_of(shards[0]).back() as BoltFx).scale.x, BoltFx.SHARD, 0.001, "rhabillé, il reste petit")


func _orb_cast(satellite := 0.0) -> SkillStats:
	var cast := SkillStats.new()
	cast.nature = DamageType.Kind.LIGHTNING
	cast.duration = 5.0
	cast.period = 1.0
	cast.projectile_speed = 50.0
	cast.radius = 30.0
	cast.satellite = satellite
	return cast


## L'Orbe statique : la boule de plasma et ses arcs, qui file droit sans traînée ; une décharge
## lance un arc vers chaque cible et y laisse un éclat, qui s'éteignent seuls.
func test_the_static_orb_is_a_plasma_ball_that_zaps() -> void:
	var orb := StaticOrb.send(_world, Vector3.ZERO, Vector3.RIGHT, _orb_cast(), null)
	var fx := orb._fx
	assert_eq(fx._orb.find_children("*", "MeshInstance3D", true, false).size(), 1 + BoltFx.ARCS, "la boule, ses arcs")
	assert_null(fx.trail, "sans traînée")
	assert_eq(fx._look.amp, 0.0, "il ne zigzague pas")
	var target := Node3D.new()
	add_child_autofree(target)
	target.global_position = Vector3(30, 0, 0)
	var before := get_viewport().get_children()
	fx.zap([target])
	var arcs := fx.get_children().filter(func(n: Node) -> bool: return n is MeshInstance3D and n.top_level)
	assert_eq(arcs.size(), 1, "un arc vers la cible")
	var born := get_viewport().get_children().filter(func(n: Node) -> bool: return not n in before)
	assert_eq(born.size(), 1, "un éclat sur elle")
	await wait_seconds(BoltFx.ZAP_FLASH_LIFE + 0.1)
	assert_false(is_instance_valid(arcs[0]), "puis rien")
	assert_false(is_instance_valid(born[0]))


func test_the_satellite_trails_its_orbit() -> void:
	var around := Node3D.new()
	add_child_autofree(around)
	var orb := StaticOrb.send(_world, Vector3.ZERO, Vector3.RIGHT, _orb_cast(1.0), null, around)
	assert_not_null(orb._fx.trail, "le sillage")


## Le dessin s'écarte de la trajectoire, de côté et jamais de plus de `AMP` ; le coup, lui, file droit.
func test_the_orb_zigzags_around_the_true_path() -> void:
	var bolt := _shoot(DamageType.Kind.LIGHTNING, Vector3.RIGHT)
	var fx: BoltFx = _fx_of(bolt)[0]
	var widest := 0.0
	for i in 20:
		await wait_process_frames(1)
		assert_almost_eq(fx._orb.position.x, 0.0, 0.01, "de côté seulement")
		assert_lte(absf(fx._orb.position.z), BoltFx.AMP + 0.01)
		widest = maxf(widest, absf(fx._orb.position.z))
	assert_gt(widest, BoltFx.AMP * 0.5, "il zigzague")
	assert_almost_eq(bolt.global_position.z, 0.0, 0.01, "le tir, droit")


## Posé à l'image entre les deux derniers pas de physique : jamais devant le tir, au plus un pas
## derrière — deux ici, un pas pouvant tomber entre l'image et l'assertion.
func test_the_bolt_glides_between_physics_steps() -> void:
	var bolt := _shoot(DamageType.Kind.LIGHTNING, Vector3.RIGHT)
	var fx: BoltFx = _fx_of(bolt)[0]
	assert_true(fx.top_level, "le tir ne le déplace pas")
	for i in 10:
		await wait_process_frames(1)
		var step := bolt.speed / float(Engine.physics_ticks_per_second)
		assert_between(fx.global_position.x, bolt.global_position.x - step * 2.0 - 0.01, bolt.global_position.x + 0.01)
		assert_almost_eq(fx.global_position.y, ElementFx.LIFT, 0.01)


func test_the_trail_outlives_the_bolt() -> void:
	var bolt := _shoot(DamageType.Kind.LIGHTNING)
	var trail := (_fx_of(bolt)[0] as BoltFx).trail
	assert_eq(trail.get_parent(), get_viewport(), "hors des conteneurs que le jeu compte")
	await wait_process_frames(10)
	assert_gt(trail.points.size(), 2, "il trace le chemin")
	bolt.queue_free()
	await wait_process_frames(2)
	assert_true(is_instance_valid(trail), "la traînée finit de s'éteindre")
	await wait_seconds(BoltFx.TRAIL_LIFE + 0.15)
	assert_false(is_instance_valid(trail), "puis rien")


func test_a_change_of_nature_swaps_the_look() -> void:
	var bolt := _shoot(DamageType.Kind.LIGHTNING)
	var fx: BoltFx = _fx_of(bolt)[0]
	bolt._nature = DamageType.Kind.FIRE
	bolt._dress()
	assert_true(fx.is_queued_for_deletion(), "l'éclair s'efface")
	assert_not_null(bolt._trail, "les étincelles du feu prennent la suite")


func test_the_end_of_the_run_flares_then_the_flare_frees_itself() -> void:
	var bolt := _shoot(DamageType.Kind.LIGHTNING)
	var before := get_viewport().get_children()
	bolt._finish()
	await wait_process_frames(2)
	var born := get_viewport().get_children().filter(func(n: Node) -> bool: return not n in before)
	assert_eq(born.size(), 1, "un éclat, posé hors du tir")
	await wait_seconds(BoltFx.FLARE_LIFE + 0.1)
	assert_false(is_instance_valid(born[0]), "puis rien")


func test_bolts_of_a_nature_share_their_materials() -> void:
	var a: BoltFx = _fx_of(_shoot(DamageType.Kind.LIGHTNING))[0]
	var b: BoltFx = _fx_of(_shoot(DamageType.Kind.LIGHTNING))[0]
	assert_eq(a.trail.material_override, b.trail.material_override)
	var arc_a: MeshInstance3D = a._orb.get_child(2)
	var arc_b: MeshInstance3D = b._orb.get_child(2)
	assert_eq(arc_a.mesh, arc_b.mesh)
	assert_ne(arc_a.get_instance_shader_parameter(&"seed"), arc_b.get_instance_shader_parameter(&"seed"),
		"deux orbes ne crépitent pas aux mêmes coudes")


func test_the_bolt_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var fx: BoltFx = _fx_of(_shoot(DamageType.Kind.LIGHTNING))[0]
	var veiled := fx.find_children("*", "GeometryInstance3D", true, false)
	assert_eq(veiled.size(), 2 + BoltFx.ARCS, "l'orbe, son étincelle, ses arcs")
	veiled.append(fx.trail)
	for node: GeometryInstance3D in veiled:
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)
