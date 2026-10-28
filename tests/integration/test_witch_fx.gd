extends GutTest

## Le manuel de la sorcière en 3D (jalon 54, à la barre de Last Epoch) : le cercle runique des Glyphes et du
## Sceau, leurs fils et leur triangle, le Chaudron et ses bouillons, le corbeau du Familier, les runes de la
## Trinité, le cercle de l'Amplification et son Aura, les comètes de la Triade et l'œil du Mauvais œil.
## Chacun suit ce qu'il montre, lui survit le temps de s'éteindre, prend le voile des sorts et garde ses
## matières.

const FIRE := DamageType.Kind.FIRE
const COLD := DamageType.Kind.COLD
const LIGHTNING := DamageType.Kind.LIGHTNING

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _host(at := Vector3.ZERO) -> Node3D:
	var host := Node3D.new()
	_world.add_child(host)
	host.global_position = at
	Settings.veil(host, Settings.SPELLS)
	return host


## Terne et rongé tant qu'il s'arme, il monte comme une encre ; armé, il s'allume.
func test_witch_glyph_rises_while_arming_then_lights_up() -> void:
	var fx := GlyphFx.trace(_host(), FIRE, 16.0, 0.5)
	assert_eq(fx.get_parent(), _world, "sur le calque du glyphe, pas sous lui")
	assert_true(fx.is_in_group(Settings.SPELLS), "le voile des sorts")
	assert_almost_eq(fx.sigil.scale.x, 16.0, 0.01, "au rayon qui le déclenche")
	assert_gt(fx.sigil.get_instance_shader_parameter(&"dissolve"), 0.9, "rien encore")
	var dim: float = fx.sigil.get_instance_shader_parameter(&"glow")
	await wait_seconds(0.6)
	assert_eq(fx.sigil.get_instance_shader_parameter(&"dissolve"), 0.0, "tracé")
	assert_gt(fx.sigil.get_instance_shader_parameter(&"glow"), dim, "armé, il s'allume")


## Éclaté, il s'ouvre et se ronge sous le souffle de son élément, puis se libère ; effacé, il s'éteint seul.
func test_witch_glyph_bursts_or_fades_then_frees() -> void:
	var host := _host()
	var fx := GlyphFx.trace(host, FIRE, 16.0, 0.0)
	fx.burst([COLD] as Array[int], 36.0)
	await wait_process_frames(3)
	assert_gt(fx.scale.x, 1.0, "il s'ouvre")
	assert_false(_rooted(IceNovaFx).is_empty(), "le souffle de l'élément")
	await wait_seconds(GlyphFx.BURST + 0.1)
	assert_false(is_instance_valid(fx))
	var gone := GlyphFx.trace(_host(), LIGHTNING, 16.0, 0.0)
	gone._host.queue_free()
	await wait_seconds(GlyphFx.OUT + 0.1)
	assert_false(is_instance_valid(gone), "effacé sans éclat")


## Le Sceau : trois logements, un par élément, qui s'allument aux éléments versés.
func test_witch_seal_lights_its_sockets_as_elements_are_poured() -> void:
	var fx := GlyphFx.trace(_host(), FIRE, 54.0, 0.0, true)
	assert_eq(fx.sockets.size(), 3)
	assert_same(fx.sigil.material_override, GlyphFx.material(FIRE, GlyphFx.SEAL), "son propre tirage")
	await wait_process_frames(2)
	var lit: float = fx.sockets[FIRE].get_instance_shader_parameter(&"glow")
	assert_lt(fx.sockets[COLD].get_instance_shader_parameter(&"glow"), lit, "vide")
	fx.pour(COLD)
	await wait_process_frames(2)
	assert_almost_eq(fx.sockets[COLD].get_instance_shader_parameter(&"glow"), lit, 0.01, "versé")


## Le froid se mêle au sol, les autres s'additionnent ; une matière par nature et par tirage.
func test_witch_sigil_materials_are_kept_and_cold_is_mixed() -> void:
	assert_same(GlyphFx.material(FIRE), GlyphFx.material(FIRE))
	assert_ne(GlyphFx.material(FIRE), GlyphFx.material(FIRE, GlyphFx.SEAL))
	assert_eq(GlyphFx.material(COLD).shader, GlyphFx.SIGIL_ICE)
	assert_eq(GlyphFx.material(LIGHTNING).shader, GlyphFx.SIGIL)


## Un fil d'un glyphe à l'autre, à leurs deux rampes, puis le triangle et ses trois bords : allumés, puis libres.
func test_witch_threads_and_weave_light_up_then_free() -> void:
	var thread := GlyphFx.thread(_world, Vector3.ZERO, Vector3(80, 0, 0), FIRE, COLD, _host())
	assert_almost_eq(thread.scale.x, 40.0, 0.01, "d'un bout à l'autre")
	assert_eq(thread.get_instance_shader_parameter(&"to_tint"), GlyphFx._rgb(FlameFx.ramp(COLD)[1]))
	assert_true(thread.is_in_group(Settings.SPELLS))
	var corners: Array[Vector3] = [Vector3.ZERO, Vector3(80, 0, 0), Vector3(40, 0, 60)]
	var veiled := _host()
	var before := _world.get_child_count()
	var weave := GlyphFx.weave(_world, corners, [FIRE, COLD, LIGHTNING] as Array[int], veiled)
	assert_eq(_world.get_child_count(), before + 4, "le voile et ses trois bords")
	await wait_seconds(GlyphFx.WOVEN + 0.1)
	assert_false(is_instance_valid(thread))
	assert_false(is_instance_valid(weave))


## Le Chaudron : la marmite sur son chaudron, ce qui bout change d'élément — deux sous le Mélange, une vapeur
## et une couronne de chacun —, un bouillon jette sa couronne de vapeur ; parti, la fonte se ronge puis se libère.
func test_witch_cauldron_boils_turns_and_fades() -> void:
	var host := _host(Vector3(20, 0, 10))
	var fx := CauldronFx.set_down(host, [FIRE] as Array[int], 50.0)
	assert_eq(fx.get_parent(), get_viewport(), "à la racine du viewport")
	assert_almost_eq(fx.global_position, host.global_position, Vector3.ONE * 0.01)
	assert_same(fx.body.material_override, BrazierFx._iron_material(), "le fer du Brasero")
	assert_same(fx._brew.material_override, CauldronFx._brew_material([FIRE] as Array[int]))
	fx.fill([COLD] as Array[int])
	assert_same(fx._brew.material_override, CauldronFx._brew_material([COLD] as Array[int]), "il bout dans l'élément versé")
	var particles := fx.find_children("*", "GPUParticles3D", false, false).size()
	fx.boil()
	assert_eq(fx.find_children("*", "GPUParticles3D", false, false).size(), particles + 1, "une couronne")
	fx.fill([FIRE, COLD] as Array[int])
	assert_eq(fx._vapors_up.size(), 2, "une vapeur par élément")
	assert_eq(fx._brew.material_override.get_shader_parameter(&"count"), 2, "le Mélange tourne dedans")
	particles = fx.find_children("*", "GPUParticles3D", false, false).size()
	fx.boil()
	assert_eq(fx.find_children("*", "GPUParticles3D", false, false).size(), particles + 2, "une couronne de chacun")
	assert_true(fx.find_children("*", "GPUParticles3D", false, false).back().is_in_group(Settings.SPELLS))
	host.queue_free()
	await wait_seconds(CauldronFx.OUT + 0.1)
	assert_false(is_instance_valid(fx))


## Le corbeau sur son Familier : son modèle sous le shader qui bat des ailes, plus ample quand il rejoue.
func test_witch_crow_perches_and_flaps() -> void:
	var fx := CrowFx.perch(_host())
	assert_same(fx._body.material_override, CrowFx._material_of(fx._body), "une matière pour tous")
	await wait_process_frames(2)
	assert_almost_eq(fx.position.y, CrowFx.HEIGHT, CrowFx.BOB + 0.01, "à l'épaule")
	fx.cry()
	await wait_process_frames(1)
	assert_gt(absf(fx._body.get_instance_shader_parameter(&"flap")), 0.0)


## La Trinité : une rune par charge d'Harmonie, qui suit les charges.
func test_witch_harmony_shows_a_rune_per_charge() -> void:
	var buff := Buff.new()
	_world.add_child(buff)
	buff.set_physics_process(false)
	Settings.veil(buff, Settings.SPELLS)
	var fx := WitchFx.harmony(buff)
	buff.stacks = 3
	await wait_process_frames(2)
	assert_eq(fx._runes.size(), 3)
	assert_true(fx._runes[0].is_in_group(Settings.SPELLS))
	assert_same(fx._runes[0].material_override, WitchFx._rune_material(FIRE), "dans le tour")
	assert_same(fx._runes[1].material_override, WitchFx._rune_material(COLD))
	buff.stacks = 1
	await wait_process_frames(2)
	assert_eq(fx._runes.size(), 1)


## L'Amplification : son cercle aux pieds prend l'élément incarné ; l'Aura l'ouvre jusqu'à sa portée.
func test_witch_amplification_takes_the_incarnated_element() -> void:
	var buff := Buff.new()
	_world.add_child(buff)
	buff.set_physics_process(false)
	var fx := WitchFx.amplify(buff, LIGHTNING)
	await wait_process_frames(2)
	assert_same(fx._circle.material_override, GlyphFx.material(LIGHTNING))
	buff.incarnation = FIRE
	await wait_process_frames(2)
	assert_same(fx._circle.material_override, GlyphFx.material(FIRE))
	var before := buff.get_child_count()
	WitchFx.pulse(buff, FIRE, SkillStats.AURA_REACH)
	var ring: MeshInstance3D = buff.get_child(before)
	await wait_seconds(WitchFx.PULSE * 0.5)
	assert_gt(ring.scale.x, WitchFx.CIRCLE, "il s'ouvre")
	await wait_seconds(WitchFx.PULSE)
	assert_false(is_instance_valid(ring))


## La Triade : trois comètes qui se rejoignent au point visé, et leurs souffles emboîtés à la jonction.
func test_witch_triad_comets_converge_and_nest_their_blasts() -> void:
	var host := _host(Vector3(100, 0, 0))
	var starts: Array[Vector3] = [Vector3(-16, 0, 0), Vector3(8, 0, 14), Vector3(8, 0, -14)]
	var fx := WitchFx.triad(host, [FIRE, COLD, LIGHTNING] as Array[int], starts, 0.3)
	assert_eq(fx._comets.size(), 3)
	for comet in fx._comets:
		assert_true(comet.get_children().any(func(n: Node) -> bool: return n is BoltFx), "le trait du joueur")
	await wait_seconds(0.35)
	for comet in fx._comets:
		assert_almost_eq(comet.position, Vector3.ZERO, Vector3.ONE * 0.01, "rejointes")
	var novas := _rooted(IceNovaFx).size()
	WitchFx.junction(host, host.global_position, [FIRE, COLD] as Array[int], 40.0)
	var nova: IceNovaFx = _rooted(IceNovaFx).back()
	assert_eq(_rooted(IceNovaFx).size(), novas + 1)
	assert_almost_eq(nova._radius, 40.0 * WitchFx.NESTED[COLD], 0.01, "le froid dehors")


## Le Mauvais œil : l'œil couché au sol à son rayon, à la rampe de l'élément, qui s'ouvre puis se referme.
func test_witch_evil_eye_opens_and_closes() -> void:
	var fx := WitchFx.evil_eye(_host(), COLD, 50.0, 0.6)
	assert_true(fx._eye.material_override.get_shader_parameter(&"lying"), "couché")
	assert_same(fx._eye.material_override, WitchFx._eye_material(COLD))
	assert_true(fx._eye.is_in_group(Settings.SPELLS))
	await wait_seconds(0.3)
	assert_gt(fx._eye.get_instance_shader_parameter(&"lid"), 0.5, "ouvert")
	await wait_seconds(0.35)
	assert_lt(fx._eye.get_instance_shader_parameter(&"lid"), 0.1, "refermé")


func _rooted(type: Variant) -> Array:
	return get_viewport().get_children().filter(
		func(n: Node) -> bool: return is_instance_of(n, type) and not n.is_queued_for_deletion())
