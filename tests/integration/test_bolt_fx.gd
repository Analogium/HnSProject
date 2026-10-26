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
	var born := get_viewport().get_children().filter(func(n: Node) -> bool: return not n in before and n is MeshInstance3D)
	assert_eq(born.size(), 1, "un éclat sur elle")
	assert_true(get_viewport().get_children().any(func(n: Node) -> bool: return n is Sparks and not n in before), "et des étincelles")
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


## L'interpolation de physique du moteur le pose entre les deux derniers pas du tir : jamais devant
## lui, au plus un pas derrière.
func test_the_bolt_glides_between_physics_steps() -> void:
	var bolt := _shoot(DamageType.Kind.LIGHTNING, Vector3.RIGHT)
	var fx: BoltFx = _fx_of(bolt)[0]
	assert_true(fx.is_physics_interpolated_and_enabled(), "le tir et lui, interpolés")
	assert_false(fx._orb.is_physics_interpolated(), "l'écart, posé à l'image")
	var step := bolt.speed / float(Engine.physics_ticks_per_second)
	for i in 10:
		await wait_process_frames(1)
		var seen := fx.get_global_transform_interpolated().origin
		assert_between(seen.x, bolt.global_position.x - step - 0.01, bolt.global_position.x + 0.01)
		assert_almost_eq(seen.y, ElementFx.LIFT, 0.01)


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
	assert_eq(born.filter(func(n: Node) -> bool: return n is MeshInstance3D).size(), 1, "un éclat, posé hors du tir")
	assert_eq(born.filter(func(n: Node) -> bool: return n is Sparks).size(), 1, "et ses étincelles")
	await wait_seconds(BoltFx.SHOCK_LIFE.y + 0.1)
	assert_true(born.all(func(n: Variant) -> bool: return not is_instance_valid(n)), "puis rien")


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


## La Chaîne d'éclairs : une tresse de trois brins par saut, aux coudes différents mais gardés d'une
## chaîne à l'autre ; à chaque arrivée un éclat et une lumière, qui se libèrent seuls.
func test_a_chain_jump_is_a_braid_of_three_strands() -> void:
	var before := get_viewport().get_children()
	var points := PackedVector3Array([Vector3.ZERO, Vector3(90, 0, 0), Vector3(150, 0, 60)])
	ChainLightning.trace(_world, points, DamageType.Kind.LIGHTNING)
	var trace: ChainLightning = _world.get_children().filter(func(n: Node) -> bool: return n is ChainLightning)[0]
	var strands := trace.get_children()
	assert_eq(strands.size(), BoltFx.BRAID * 2, "trois brins par saut")
	assert_ne((strands[0] as MeshInstance3D).mesh, (strands[1] as MeshInstance3D).mesh, "chacun ses coudes")
	assert_almost_eq((strands[0] as Node3D).global_position, points[1] + Vector3.UP * ElementFx.LIFT, Vector3.ONE * 0.01)
	ChainLightning.trace(_world, points, DamageType.Kind.LIGHTNING)
	var other: ChainLightning = _world.get_children().filter(func(n: Node) -> bool: return n is ChainLightning)[1]
	assert_eq((other.get_child(0) as MeshInstance3D).mesh, (strands[0] as MeshInstance3D).mesh, "gardés")
	var born := get_viewport().get_children().filter(func(n: Node) -> bool: return not n in before)
	var flashes := born.filter(func(n: Node) -> bool: return n is MeshInstance3D)
	assert_eq(flashes.size(), 4, "un éclat par arrivée")
	assert_eq(born.filter(func(n: Node) -> bool: return n is Sparks).size(), 4, "et ses étincelles")
	assert_eq(flashes[0].find_children("*", "OmniLight3D", false, false).size(), 1, "et sa lumière")
	await wait_seconds(maxf(ChainLightning.LIFETIME, BoltFx.ZAP_FLASH_LIFE) + 0.1)
	assert_false(is_instance_valid(trace), "puis rien")
	assert_true(flashes.all(func(flash: Variant) -> bool: return not is_instance_valid(flash)))


func test_the_chain_dissolves_under_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.5
	ChainLightning.trace(_world, PackedVector3Array([Vector3.ZERO, Vector3(90, 0, 0)]), DamageType.Kind.LIGHTNING)
	var trace: ChainLightning = _world.get_children().filter(func(n: Node) -> bool: return n is ChainLightning)[0]
	var strand: GeometryInstance3D = trace.get_child(0)
	trace._process(0.0)
	assert_almost_eq(strand.get_instance_shader_parameter(&"opacity"), 0.5, 0.001, "pleine, sous le voile")
	trace._age = ChainLightning.LIFETIME * 5.0 / 6.0
	trace._process(0.0)
	assert_almost_eq(strand.get_instance_shader_parameter(&"opacity"), 0.25, 0.001, "à mi-chemin de son dernier tiers")
	Settings.from_dict(before)


## La Ruée d'orage (jalon 54) : un éclair bref du départ à l'arrivée, qui s'éteint de la queue ;
## son appel du tonnerre crépite aux pieds ; ses explosions s'ouvrent en couronne d'arcs ; ses
## charges statiques grésillent.
func test_a_storm_dash_flashes_a_brief_bolt_then_nothing() -> void:
	var before := get_viewport().get_children()
	BoltFx.dash(get_viewport(), Vector3.ZERO, Vector3(130, 0, 0))
	var born := get_viewport().get_children().filter(func(n: Node) -> bool: return not n in before)
	var drawn := born.filter(func(n: Node) -> bool: return n is MeshInstance3D)
	var strands := drawn.filter(func(n: Node) -> bool: return (n as MeshInstance3D).mesh.surface_get_material(0).shader == BoltFx.ARC)
	assert_eq(strands.size(), BoltFx.DASH_STRANDS)
	assert_eq(drawn.size() - strands.size(), 2, "un éclat à chaque bout")
	assert_eq(born.filter(func(n: Node) -> bool: return n is Sparks).size(), BoltFx.DASH_SPARKS + 1, "des étincelles le long, et à l'arrivée")
	assert_almost_eq((strands[0] as Node3D).global_position, Vector3(130, ElementFx.LIFT, 0), Vector3.ONE * 0.01,
		"posé par sa tête, à l'arrivée")
	assert_true((strands[0] as Node).is_in_group(Settings.SPELLS), "sous le voile des sorts")
	await wait_seconds(BoltFx.SHOCK_LIFE.y + 0.1)
	assert_true(born.all(func(n: Variant) -> bool: return not is_instance_valid(n)), "puis rien")


func test_the_thunder_call_crackles_at_the_feet() -> void:
	var host := Node3D.new()
	_world.add_child(host)
	var ring := BoltFx.feet(host)
	assert_eq(ring.find_children("*", "MeshInstance3D", true, false).size(), BoltFx.ARCS)
	assert_eq(ring.find_children("*", "OmniLight3D", true, false).size(), 1, "et une lueur")
	var turn := ring.rotation.y
	await wait_process_frames(5)
	assert_ne(ring.rotation.y, turn, "ils tournent")


func test_a_lightning_explosion_opens_a_crown_then_frees_it() -> void:
	var parts := DamageType.empty_parts()
	parts[DamageType.Kind.LIGHTNING] = 10.0
	var before := get_viewport().get_children()
	Explosion.put(_world, Vector3.ZERO, parts, 45.0, null, DamageType.COLORS[DamageType.Kind.LIGHTNING], null, null)
	await wait_physics_frames(2)
	var born := get_viewport().get_children().filter(func(n: Node) -> bool: return not n in before)
	var rings := born.filter(func(n: Node) -> bool: return n.get_child_count() > 1)
	assert_eq(rings.size(), 1, "un anneau, et l'éclat au centre")
	var arcs := (rings[0] as Node).get_children()
	assert_eq(arcs.size(), roundi(TAU * 45.0 / BoltFx.CROWN_STEP))
	await wait_seconds(BoltFx.CROWN_OPEN)
	assert_almost_eq(Flat.xz((arcs[0] as Node3D).position).length(), 45.0, 1.0, "ouvert jusqu'au bord")
	assert_almost_eq((arcs[0] as Node3D).scale.y, BoltFx.CROWN_WIDTH, 0.01, "à largeur constante")
	await wait_seconds(BoltFx.CROWN_FADE + 0.1)
	assert_true(born.all(func(n: Variant) -> bool: return not is_instance_valid(n)), "puis rien")


func test_a_static_charge_sparks_as_wide_as_its_bite() -> void:
	var charge := StaticCharge.put(_world, Vector3.ZERO, Vector3.RIGHT, [10.0], null)
	var mine := StaticCharge.put(_world, Vector3.ZERO, Vector3.RIGHT, [10.0], null, StaticCharge.SHARE, true)
	await wait_process_frames(2)
	var spark: MeshInstance3D = charge.find_children("*", "MeshInstance3D", false, false)[0]
	assert_almost_eq(spark.scale.x, StaticCharge.RADIUS * 2.0, 0.01)
	assert_almost_eq(spark.position.y, StaticCharge.RADIUS, 0.01, "levée de son rayon : rien sous le sol")
	var wide: MeshInstance3D = mine.find_children("*", "MeshInstance3D", false, false)[0]
	assert_almost_eq(wide.scale.x, StaticCharge.RADIUS * SkillStats.MINE_REACH * 2.0, 0.01, "une mine, plus large")
	assert_true(spark.is_in_group(Settings.SPELLS), "sous le voile des sorts")


## L'Électricité statique (jalon 54) : l'Ionisation ouvre un anneau discret jusqu'à sa portée ; la Cage
## de Faraday pose un dôme d'arcs, le temps de l'invulnérabilité.
func test_an_ionizing_pulse_opens_to_its_reach_then_frees() -> void:
	var before := get_viewport().get_children()
	BoltFx.pulse(_world, SkillStats.IONIZE_RADIUS)
	var rings := get_viewport().get_children().filter(func(n: Node) -> bool: return not n in before)
	assert_eq(rings.size(), 1)
	var arcs := (rings[0] as Node).get_children()
	assert_almost_eq(Flat.xz((arcs[0] as Node3D).position).length(), BoltFx.PULSE_START, 0.5, "il part du corps")
	await wait_seconds(BoltFx.PULSE_OPEN * 0.9)
	assert_almost_eq(Flat.xz((arcs[0] as Node3D).position).length(), SkillStats.IONIZE_RADIUS, 2.0, "jusqu'à sa portée")
	await wait_seconds(BoltFx.PULSE_OPEN * 0.1 + BoltFx.CROWN_FADE + 0.1)
	assert_true(rings.all(func(n: Variant) -> bool: return not is_instance_valid(n)), "puis rien")


func test_the_faraday_cage_is_a_dome_for_its_time() -> void:
	var host := Node3D.new()
	_world.add_child(host)
	var dome := BoltFx.cage(host, 0.3)
	var arcs := dome.find_children("*", "MeshInstance3D", true, false)
	assert_eq(arcs.size(), BoltFx.CAGE_MERIDIANS * BoltFx.CAGE_STEPS)
	var top := arcs.map(func(a: Node3D) -> float: return a.global_position.y).max() as float
	assert_almost_eq(top, BoltFx.CAGE_RADIUS, 0.01, "un méridien monte jusqu'au sommet")
	assert_true((arcs[0] as Node).is_in_group(Settings.SPELLS), "sous le voile des sorts")
	await wait_seconds(0.4)
	assert_false(is_instance_valid(dome), "levée avec l'invulnérabilité")


## La marque du Paratonnerre (jalon 54, « foudre appelée ») : sur sa cible et non à côté, une étincelle
## sur la tête, et l'éclair du nuage qui y tombe à chaque appel.
func test_the_rod_calls_lightning_down_on_the_head() -> void:
	var target := Hurtbox.new()
	_world.add_child(target)
	target.global_position = Vector3(40, 0, 20)
	var cast := SkillStats.new()
	cast.nature = DamageType.Kind.LIGHTNING
	var author := StatusEffects.new()
	LightningRod.mark(_world, target, author, cast)
	await wait_physics_frames(2)
	await wait_process_frames(2)
	var rod: LightningRod = _world.get_children().filter(func(n: Node) -> bool: return n is LightningRod)[0]
	assert_almost_eq(rod.global_position, target.global_position, Vector3.ONE * 0.01, "sur sa cible")
	assert_almost_eq(rod._spark.position.y, LightningRod.HEAD + LightningRod.SPARK * 0.5, 0.01,
		"l'étincelle sur la tête (sans modèle 3D, à la hauteur par défaut)")
	var bolts := rod.get_children().filter(func(n: Node) -> bool:
		return n is MeshInstance3D and (n as MeshInstance3D).mesh.surface_get_material(0).shader == StormCloudFx.BOLT)
	assert_eq(bolts.size(), 1, "un éclair tombe dès la pose")
	assert_almost_eq((bolts[0] as Node3D).global_position.y, LightningRod.HEAD, 0.01, "posé sur la tête")
	await wait_seconds(LightningRod.CALL + 0.05)
	var again := rod.get_children().filter(func(n: Node) -> bool:
		return n is MeshInstance3D and (n as MeshInstance3D).mesh.surface_get_material(0).shader == StormCloudFx.BOLT)
	assert_eq(again.size(), 1, "le premier éteint, le suivant tombé")
	assert_ne(again[0], bolts[0])


## Une frappe de foudre jette des étincelles fines et pousse l'air, puis tout se libère ; les autres
## natures ont leurs couches à elles.
func test_a_lightning_shock_throws_sparks_and_pushes_the_air() -> void:
	var host := Node3D.new()
	_world.add_child(host)
	var before := get_viewport().get_children()
	BoltFx.shock(host, Vector3(20, 0, 0), DamageType.Kind.LIGHTNING, 20.0)
	var born := get_viewport().get_children().filter(func(n: Node) -> bool: return not n in before)
	var sparks: Array = born.filter(func(n: Node) -> bool: return n is Sparks)
	assert_eq(sparks.size(), 1)
	assert_eq((sparks[0] as Sparks).multimesh.instance_count, BoltFx.SHOCK_SPARKS + 10)
	assert_lt((sparks[0] as Sparks)._width, Sparks.WIDTH, "plus fines que des braises")
	var warps := born.filter(func(n: Node) -> bool: return n.get_child_count() == 1)
	assert_eq(warps.size(), 1, "la distorsion")
	var warp := warps[0].get_child(0) as MeshInstance3D
	assert_eq(warp.material_override, IceNovaFx.material(IceNovaFx.WARP, DamageType.Kind.LIGHTNING))
	await wait_seconds(BoltFx.SHOCK_OPEN)
	assert_gt(float(warp.get_instance_shader_parameter(&"front")), 0.8, "ouverte")
	await wait_seconds(BoltFx.SHOCK_LIFE.y)
	assert_true(born.all(func(n: Variant) -> bool: return not is_instance_valid(n)), "puis rien")
	var others := get_viewport().get_child_count()
	BoltFx.shock(host, Vector3.ZERO, DamageType.Kind.COLD, 20.0)
	assert_eq(get_viewport().get_child_count(), others, "pas sur la glace")


func test_a_chain_jump_sparks_at_its_target() -> void:
	var host := Node3D.new()
	_world.add_child(host)
	var before := get_viewport().get_children()
	BoltFx.braid(host, Vector3.ZERO, Vector3(60, 0, 0), DamageType.Kind.LIGHTNING)
	var sparks := get_viewport().get_children().filter(func(n: Node) -> bool: return n is Sparks and not n in before)
	assert_eq(sparks.size(), 1)
	assert_almost_eq((sparks[0] as Node3D).global_position, Vector3(60, 0, 0), Vector3.ONE * 0.01, "à la cible")
