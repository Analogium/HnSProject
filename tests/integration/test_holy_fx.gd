extends GutTest

## Le manuel de la lumière en 3D (jalon 54, à la barre de Last Epoch) : le souffle sacré de toute explosion
## sacrée, la colonne du Pilier, le marteau, les maillons des Chaînes et le liseré de la Lumière sacrée.
## Chacun suit ce qu'il montre, lui survit le temps de s'éteindre, prend le voile des sorts et garde ses
## matières.

const HOLY := DamageType.Kind.HOLY

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _rooted(type: Variant) -> Array:
	return get_viewport().get_children().filter(
		func(n: Node) -> bool: return is_instance_of(n, type) and not n.is_queued_for_deletion())


func _cast(radius := 32.0, duration := 2.0) -> SkillStats:
	var cast := SkillStats.new()
	cast.nature = HOLY
	cast.radius = radius
	cast.duration = duration
	cast.period = 0.5
	return cast


func _grunt(at: Vector3) -> Enemy:
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	add_child_autofree(grunt)
	grunt.global_position = at
	return grunt


func test_holy_explosion_blows_light_and_rays_then_frees() -> void:
	var parts := DamageType.empty_parts()
	parts[HOLY] = 10.0
	Explosion.put(_world, Vector3(30, 0, 0), parts, 20.0, null, DamageType.COLORS[HOLY], null, null)
	await wait_physics_frames(2)
	assert_eq(_rooted(HolyBlastFx).size(), 1, "le souffle sacré, pas la gerbe générique")
	var fx: HolyBlastFx = _rooted(HolyBlastFx)[0]
	assert_not_null(fx._glory, "ses rayons de gloire")
	assert_not_null(fx._flare, "et l'éclat au cœur")
	assert_same(fx._shock.material_override, FireBlastFx.shock_material(HOLY), "l'onde de feu, à la bande de lumière")
	assert_eq(fx._shock.material_override.get_shader_parameter(&"wind"), HolyBlastFx.WAVE)
	await wait_seconds(HolyBlastFx.EATEN.y + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


func test_holy_pulse_wave_has_no_rays_and_wrath_gathers_light() -> void:
	var wave := HolyBlastFx.blow(_world, Vector3.ZERO, HOLY, 44.0, false)
	assert_null(wave._glory)
	assert_null(wave._flare)
	wave.queue_free()
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	var cast := _cast(44.0, 3.0)
	cast.wrath = 1.0
	HolyPulse.emanate(player, cast)
	var gathered := _rooted(Sparks).filter(func(s: Sparks) -> bool: return s._toward.is_valid())
	assert_eq(gathered.size(), 1, "la Colère divine amasse ses grains")
	await wait_seconds(0.4)
	var heart := player.global_position + Vector3.UP * ElementFx.LIFT
	var sparks: Sparks = gathered[0]
	var farthest := 0.0
	var seen := 0
	var now := sparks._clock
	for i in sparks._embers.size():
		if sparks._embers[i].born < 0.0:
			continue
		seen += 1
		sparks._clock = sparks._embers[i].born + sparks._embers[i].life * 0.99
		farthest = maxf(farthest, sparks.ember(i).origin.distance_to(heart))
	sparks._clock = now
	assert_gt(seen, 0)
	assert_lt(farthest, cast.radius * 0.2, "un grain au bout de sa vie est sur le porteur")


func test_holy_pillar_falls_follows_pulses_and_burns_out() -> void:
	var pillar := SacredPillar.fall(_world, Vector3(40, 0, 0), _cast(), null)
	var fx := pillar._fx
	assert_eq(fx.get_parent(), get_viewport(), "hors des conteneurs que le jeu compte")
	assert_null(fx._glyph, "pas de sol consacré sans la Consécration")
	assert_lt(fx.column.get_instance_shader_parameter(&"fall"), 0.5, "elle tombe du ciel")
	await wait_physics_frames(2)
	assert_eq(_rooted(HolyBlastFx).size(), 1, "la première impulsion jette son onde")
	assert_null((_rooted(HolyBlastFx)[0] as HolyBlastFx)._glory, "sans rayons")
	pillar.global_position = Vector3(80, 0, 10)
	await wait_seconds(SacredPillarFx.FALL)
	assert_almost_eq(fx.global_position, pillar.global_position, Vector3.ONE * 0.5, "il suit son pilier")
	assert_almost_eq(fx.column.get_instance_shader_parameter(&"fall"), 1.0, 0.001)
	pillar.queue_free()
	await wait_seconds(SacredPillarFx.OUT * 0.5)
	assert_gt(fx.column.get_instance_shader_parameter(&"lift"), 0.0, "éteinte, elle remonte au ciel")
	await wait_seconds(SacredPillarFx.OUT * 0.5 + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


func test_holy_consecration_lays_its_glyph() -> void:
	var cast := _cast()
	cast.consecration = 1.0
	var fx := SacredPillar.fall(_world, Vector3.ZERO, cast, null)._fx
	assert_not_null(fx._glyph)
	assert_eq(fx._glyph.texture_albedo, SacredPillarFx.GLYPH)


func test_holy_hammer_rides_its_hammer_and_a_bourdon_is_bigger() -> void:
	var cast := _cast(70.0, 1.2)
	var hammer := BlessedHammer.swing(_world, Vector3.ZERO, 0.0, cast, null, null)
	var fx := hammer._fx
	assert_eq(fx.get_parent(), hammer)
	assert_eq(fx.trail.get_parent(), get_viewport(), "sa traînée retombe hors de lui")
	cast.bourdon = 1.0
	var big := BlessedHammer.swing(_world, Vector3.ZERO, 0.0, cast, null, null, SkillStats.BOURDON_EVERY - 1)
	assert_almost_eq(big._fx._body.basis.get_scale().x, fx._body.basis.get_scale().x * SkillStats.BOURDON_FACTOR, 0.01)
	assert_same(big._fx._body.material_override, fx._body.material_override, "une matière par nature")
	var trail := fx.trail
	hammer.queue_free()
	await wait_seconds(BoltFx.TRAIL_LIFE + 0.1)
	assert_false(is_instance_valid(trail), "puis sa traînée")


func test_holy_chains_fly_as_a_head_and_bind_with_links() -> void:
	var first := _grunt(Vector3(60, 0, 0))
	_grunt(Vector3(60, 0, 40))
	await wait_physics_frames(2)
	var cast := _cast(90.0, 4.0)
	cast.links = 1.0
	var chains := JudgmentChains.throw(_world, Vector3.ZERO, Vector3.RIGHT, cast, null)
	await wait_process_frames(1)
	var fx: JudgmentChainsFx = _rooted(JudgmentChainsFx)[0]
	assert_eq(fx.multimesh.visible_instance_count, 1 + JudgmentChainsFx.TAIL, "l'anneau de tête et sa chaîne")
	await wait_seconds(0.3)
	assert_false(chains.flying())
	assert_eq(chains.anchor(), first.hurtbox)
	var count := int(40.0 / JudgmentChainsFx.PITCH)
	assert_almost_eq(fx.multimesh.visible_instance_count, count, 1, "un maillon tous les PITCH px")
	chains._end()
	await wait_seconds(JudgmentChainsFx.OUT + 0.1)
	assert_false(is_instance_valid(fx), "parties, ses maillons se rongent puis rien")


func test_holy_light_wears_a_rim_and_the_aureole_its_circle() -> void:
	var player: Player = load("res://actors/player/player.tscn").instantiate()
	add_child_autofree(player)
	var buff := Buff.light(player, SkillCatalog.by_id("holy_light"))
	var halo := buff._halo_fx
	assert_not_null(halo)
	assert_null(halo._crown)
	halo.crown(40.0)
	assert_not_null(halo._crown, "le cercle de l'Auréole")
	assert_almost_eq(halo._crown.scale.x, 40.0, 0.01)
	halo.crown(0.0)
	assert_null(halo._crown)


func test_holy_light_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.25
	var fx := SacredPillar.fall(_world, Vector3.ZERO, _cast(), null)._fx
	var blast := HolyBlastFx.blow(fx, Vector3.ZERO, HOLY, 20.0)
	for node: Node in [fx.column, fx._ground, fx._motes, blast._shock, blast._glory]:
		assert_almost_eq(node.get_instance_shader_parameter(&"opacity"), 0.25, 0.001)
	Settings.from_dict(before)


## L'Effondrement : la colonne s'écrase dans son éclat au lieu de remonter au ciel.
func test_holy_collapsing_pillar_crushes_down() -> void:
	var cast := _cast(32.0, 0.6)
	cast.end_burst = 15.0
	var pillar := SacredPillar.fall(_world, Vector3.ZERO, cast, null)
	var fx := pillar._fx
	while is_instance_valid(pillar):
		await wait_physics_frames(1)
	await wait_seconds(SacredPillarFx.CRUSH * 0.5)
	assert_gt(fx.column.get_instance_shader_parameter(&"crush"), 0.0, "elle s'écrase")
	assert_eq(fx.column.get_instance_shader_parameter(&"lift"), 0.0, "sans remonter")
	await wait_seconds(SacredPillarFx.CRUSH * 0.5 + 0.1)
	assert_false(is_instance_valid(fx))


## La Gravitation : la traînée se pose dans le repère du lanceur, et ne se courbe pas quand il avance.
func test_holy_orbiting_hammer_trails_in_its_caster_frame() -> void:
	var caster := Node3D.new()
	_world.add_child(caster)
	var cast := _cast(70.0, 1.2)
	cast.gravitation = 1.0
	var hammer := BlessedHammer.swing(_world, Vector3.ZERO, 0.0, cast, null, caster)
	assert_eq(hammer._fx.trail.frame, caster)
	await wait_process_frames(3)
	var laid: Vector3 = hammer._fx.trail.points[0][0]
	caster.global_position += Vector3(50, 0, 0)
	await wait_process_frames(1)
	assert_eq(hammer._fx.trail.points[0][0], laid, "le point reste où il était autour du lanceur")
	assert_null(BlessedHammer.swing(_world, Vector3.ZERO, 0.0, _cast(70.0, 1.2), null, caster)._fx.trail.frame,
			"une spirale se pose dans le monde")


## L'assommé (le Carcan, la Retombée…) : trois étoiles d'or tournent au-dessus de la tête.
func test_holy_stun_shows_stars_over_the_head() -> void:
	var grunt := _grunt(Vector3(20, 0, 0))
	await wait_physics_frames(1)
	grunt.stun(1.0)
	var mark: StunMark = grunt.get_children().filter(func(n: Node) -> bool: return n is StunMark)[0]
	assert_eq(mark._stars.multimesh.instance_count, StunMark.STARS)
	var head := LightningRod.head_of(grunt.hurtbox)
	for i in StunMark.STARS:
		assert_almost_eq(mark.star(i).origin.y, head + StunMark.ABOVE, 0.01, "au-dessus de la tête")
	assert_ne(mark.star(0).origin, mark.star(1).origin)
