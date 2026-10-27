extends GutTest

## Le manuel du chevalier en 3D (jalon 54, à la barre de Last Epoch) : la trace de la lame, le sol frappé,
## le souffle d'acier, la vague, le tour du Cyclone, les épées de la ronde, le couloir de la ruée et
## l'estoc. Chacun suit ce qu'il montre, lui survit le temps de se ronger, prend le voile des sorts et
## garde ses matières.

const PHYS := DamageType.Kind.PHYSICAL

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


## Les rubans de lame vivants dans tout le viewport, de cette nature.
func _ribbons(nature := PHYS) -> Array:
	return get_viewport().find_children("*", "MeshInstance3D", true, false).filter(func(n: Node) -> bool:
		return (n as MeshInstance3D).material_override == SteelFx.slash_material(nature) and not n.is_queued_for_deletion())


func _decals(texture: Texture2D) -> Array:
	return get_viewport().find_children("*", "Decal", true, false).filter(func(n: Node) -> bool:
		return (n as Decal).texture_albedo == texture and not n.is_queued_for_deletion())


func _dust() -> Array:
	return get_viewport().find_children("*", "MeshInstance3D", true, false).filter(func(n: Node) -> bool:
		return (n as MeshInstance3D).material_override == SteelFx.dust_material() and not n.is_queued_for_deletion())


func _cast(radius := 20.0, duration := 0.5) -> SkillStats:
	var cast := SkillStats.new()
	cast.nature = PHYS
	cast.radius = radius
	cast.duration = duration
	cast.period = 0.25
	cast.projectile_speed = 160.0
	return cast


func test_steel_swing_lays_its_crescent_sweeps_it_then_frees_it() -> void:
	var host := _host()
	SteelFx.swing(host, PHYS, 20.0, 0.2, SwingArc.Style.ARC)
	var arcs := _ribbons()
	assert_eq(arcs.size(), 1, "un croissant")
	var arc: MeshInstance3D = arcs[0]
	assert_eq(arc.get_parent(), host, "sous la visée, qu'il suit")
	assert_almost_eq(arc.scale.x, 20.0 + SteelFx.BLADE, 0.01, "jusqu'au bout de la lame")
	assert_almost_eq(arc.get_instance_shader_parameter(&"opacity"), Settings.opacity_of(Settings.SPELLS), 0.001,
		"le voile des sorts")
	await wait_seconds(0.1)
	var head: float = arc.get_instance_shader_parameter(&"head")
	assert_between(head, 0.1, 1.5, "la lame le parcourt")
	await wait_seconds(0.2 + SteelFx.FADE + 0.1)
	assert_false(is_instance_valid(arc), "rongé, puis rien")


func test_steel_heavy_strike_stands_up_and_bites_where_it_falls() -> void:
	var host := _host()
	var before := get_viewport().get_child_count()
	SteelFx.swing(host, PHYS, 20.0, 0.2, SwingArc.Style.STRIKE)
	var arc: MeshInstance3D = _ribbons()[0]
	assert_gt(absf(arc.basis.y.z), 0.9 * arc.basis.get_scale().y, "debout dans le plan de la visée")
	assert_eq(get_viewport().get_children().filter(func(n: Node) -> bool: return n is Sparks).size(), 1,
		"le fer qui mord jette ses étincelles")
	assert_eq(_dust().size(), 1, "et une bouffée de poussière")
	assert_gt(get_viewport().get_child_count(), before)
	assert_eq(_decals(SteelFx.CRATER).size(), 0, "sans cratère : il ne frappe pas le sol")


func test_steel_cross_cuts_twice_and_the_second_waits() -> void:
	var host := _host()
	SteelFx.swing(host, PHYS, 20.0, 0.3, SwingArc.Style.CROSS)
	var cuts := _ribbons()
	assert_eq(cuts.size(), 2, "deux entailles")
	await wait_seconds(0.05)
	assert_gt(float(cuts[0].get_instance_shader_parameter(&"head")), 0.0, "la première part")
	assert_lt(float(cuts[1].get_instance_shader_parameter(&"head")), 0.0, "la seconde attend son temps")


func test_steel_holy_blade_and_the_burning_blade_wear_their_nature() -> void:
	SteelFx.swing(_host(), DamageType.Kind.HOLY, 20.0, 0.2, SwingArc.Style.CROSS)
	SteelFx.swing(_host(), DamageType.Kind.FIRE, 20.0, 0.2, SwingArc.Style.STRIKE)
	assert_eq(_ribbons(DamageType.Kind.HOLY).size(), 2)
	assert_eq(_ribbons(DamageType.Kind.FIRE).size(), 1)
	assert_ne(SteelFx.slash_material(DamageType.Kind.HOLY), SteelFx.slash_material(PHYS))


func test_steel_slam_leaves_its_crater_dust_and_clods() -> void:
	var dust := _dust().size()
	GroundSlam.leave(_world, Vector3(30, 0, 0), _cast(28.0))
	var craters := _decals(SteelFx.CRATER)
	assert_eq(craters.size(), 1, "le sol frappé")
	assert_almost_eq((craters[0] as Decal).size.x, 28.0 * SteelFx.CRATER_SPAN, 0.01, "à la taille de son rayon")
	assert_eq(_dust().size(), dust + 1)
	var clods := get_viewport().find_children("*", "MultiMeshInstance3D", true, false).filter(
		func(n: Node) -> bool: return (n as MultiMeshInstance3D).multimesh.mesh == SteelFx._pebble())
	assert_eq(clods.size(), 1, "les mottes")
	await wait_seconds(SteelFx.CRATER_LIFE + 0.1)
	assert_eq(_decals(SteelFx.CRATER).size(), 0, "puis le sol s'efface")


func test_steel_clods_fly_land_and_shrink() -> void:
	var clod := SteelFx.Clod.new()
	clod.speed = Vector3(40.0, 100.0, 0.0)
	clod.turn = Basis.IDENTITY
	assert_gt(clod.at(0.2).origin.y, 5.0, "elle vole")
	var landed := 100.0 * 2.0 / SteelFx.GRAVITY
	assert_almost_eq(clod.at(landed + 0.1).origin, Vector3(40.0 * landed, 0.0, 0.0), Vector3.ONE * 0.01,
		"retombée, elle reste où elle touche")
	assert_almost_eq(clod.at(SteelFx.CLOD_LIFE).basis.get_scale().x, 0.0, 0.01, "puis rapetisse")


func test_steel_blast_raises_dust_and_a_bleeding_kill_blood() -> void:
	var parts := DamageType.empty_parts()
	parts[PHYS] = 10.0
	Explosion.put(_world, Vector3(30, 0, 0), parts, 20.0, null, DamageType.COLORS[PHYS], null, null)
	await wait_physics_frames(2)
	assert_eq(_dust().size(), 1, "la poussière, pas la gerbe générique")
	assert_eq(get_viewport().get_children().filter(func(n: Node) -> bool: return n is ElementFx).size(), 0)
	var gore := Explosion.put(_world, Vector3(-30, 0, 0), parts, 20.0, null, DamageType.COLORS[PHYS], null, null)
	gore.gore = true
	await wait_physics_frames(2)
	assert_eq(_decals(SteelFx.BLOOD).size(), 1, "la Gerbe de sang éclate en sang")
	assert_eq(_dust().size(), 1, "et sans poussière")


func test_steel_wave_carries_its_crescent_then_leaves_it_to_dissolve() -> void:
	var wave := SlashWave.send(_world, Vector3.ZERO, Vector3.FORWARD, _cast(20.0, 0.2), null)
	var arc: MeshInstance3D = wave._arc
	assert_eq(arc.get_parent(), wave, "porté par la vague")
	assert_same(arc.material_override, SteelFx.wave_material(PHYS), "le croissant net")
	var trails := get_viewport().get_children().filter(func(n: Node) -> bool:
		return n is BoltFx.Trail and (n as BoltFx.Trail).target != null and (n as BoltFx.Trail).target.get_parent() == arc)
	assert_eq(trails.size(), 2, "une traînée à chaque pointe")
	await wait_physics_frames(2)
	assert_almost_eq(arc.rotation.y, -Flat.angle(Vector3.FORWARD), 0.01, "tourné vers où elle va")
	await wait_seconds(0.25)
	assert_false(is_instance_valid(wave), "la vague au bout de sa course")
	assert_true(is_instance_valid(arc), "son croissant reste le temps de se ronger")
	await wait_seconds(SteelFx.WAVE_GONE + 0.1)
	assert_false(is_instance_valid(arc))


func test_steel_whirl_turns_with_its_bearer_and_is_released() -> void:
	var host := _host()
	var whirl := SteelFx.whirl(host, PHYS, 34.0)
	assert_eq(whirl.blades.size(), SteelFx.WHIRL_BLADES)
	assert_almost_eq(whirl.blades[0].scale.x, 34.0, 0.01)
	var body := Node3D.new()
	host.add_child(body)
	whirl.body = body
	var turned := whirl.rotation.y
	await wait_physics_frames(3)
	assert_ne(whirl.rotation.y, turned, "il tourne")
	assert_almost_eq(body.rotation.y, whirl.rotation.y, 0.001, "et le corps avec lui")
	whirl.resize(40.0)
	assert_almost_eq(whirl.blades[0].scale.x, 40.0, 0.01, "Envergure, pris en cours")
	var blade := whirl.blades[0]
	whirl.let_go()
	await wait_process_frames(1)
	assert_eq(blade.get_parent(), get_viewport(), "laissé où il tournait")
	await wait_seconds(SteelFx.WAVE_GONE + 0.1)
	assert_false(is_instance_valid(blade))


func test_steel_crown_shows_one_sword_per_blade_point_first() -> void:
	var crown := BladeCrown.new()
	_world.add_child(crown)
	var cast := _cast(26.0, 0.3)
	crown.add_to(cast)
	crown.add_to(cast)
	await wait_seconds(BladeCrown.OUTPUT + 0.05)
	var swords := crown.get_children().filter(func(n: Node) -> bool: return n.get_child_count() > 0)
	assert_eq(swords.size(), 2, "une épée par lame")
	var blade: BladeCrown.Blade = crown._blades[0]
	assert_almost_eq(Flat.xz(blade.shown.position).length(), 26.0, 2.0, "sur son cercle")
	var out := Flat.from_angle(Flat.angle(blade.shown.position))
	assert_almost_eq(absf((-blade.shown.basis.z).dot(out)), 0.0, 0.05, "pointe en avant, pas vers le dehors")
	await wait_seconds(0.3)
	assert_false(is_instance_valid(blade.shown), "partie avec sa lame")


func test_steel_sword_is_the_models_whole_and_is_kept() -> void:
	var parts := SteelFx.sword_parts()
	assert_gt(parts.size(), 1, "lame, garde et poignée : toutes ses pièces")
	assert_same(SteelFx.sword_parts(), parts, "chargée une fois")
	var holder := SteelFx.sword(_host(), _host(), PHYS)
	await wait_process_frames(1)
	var span := AABB()
	for body: MeshInstance3D in holder.find_children("*", "MeshInstance3D", true, false):
		var box := holder.global_transform.affine_inverse() * body.global_transform * body.mesh.get_aabb()
		span = box if span.size == Vector3.ZERO else span.merge(box)
	assert_almost_eq(span.size.z, SteelFx.SWORD_LENGTH, 0.5, "couchée, à sa longueur, pointe en -Z")
	assert_almost_eq(span.get_center().z, 0.0, 0.5, "centrée sur sa place")
	assert_lt(span.size.y, SteelFx.SWORD_LENGTH * 0.3, "le plat vers le ciel")


func test_steel_dash_cuts_its_corridor_and_a_wave_lays_its_furrow() -> void:
	var cast := _cast(12.0, 0.4)
	DashTrail.leave(_world, Vector3.ZERO, Vector3(100, 0, 0), cast, null)
	var cut: MeshInstance3D = _ribbons()[0]
	assert_almost_eq(cut.basis.x.length(), 100.0, 0.01, "tout le couloir")
	assert_eq(_decals(SteelFx.FURROW).size(), 0)
	DashTrail.leave(_world, Vector3.ZERO, Vector3(0, 0, 80), cast, null, true)
	assert_eq(_decals(SteelFx.FURROW).size(), 1, "le Sillon d'acier fend le sol")
	await wait_seconds(0.6)
	assert_eq(_ribbons().size(), 0, "rongé au bout de sa durée")


func test_steel_thrust_cuts_to_its_tip_and_glints_there() -> void:
	ThrustTrail.leave(_world, Vector3.ZERO, Vector3(60, 0, 0), PHYS)
	assert_eq(_ribbons().size(), 1)
	var glints := get_viewport().get_children().filter(func(n: Node) -> bool:
		return n is MeshInstance3D and (n as MeshInstance3D).material_override == SteelFx.glint_material(PHYS))
	assert_eq(glints.size(), 1, "l'éclat de l'impact")
	assert_almost_eq((glints[0] as Node3D).global_position.x, 60.0, 0.01, "à la pointe")
	await wait_seconds(ThrustTrail.LIFETIME + 0.1)
	assert_eq(_ribbons().size(), 0)


func test_steel_sparks_burn_hot_not_grey() -> void:
	var m := Sparks._material(PHYS)
	var heart: Vector3 = m.get_shader_parameter(&"tint")
	assert_gt(heart.x, heart.z * 2.0, "l'orange du meulage")


func test_steel_materials_are_kept() -> void:
	assert_same(SteelFx.slash_material(PHYS), SteelFx.slash_material(PHYS))
	assert_same(SteelFx.dust_material(), SteelFx.dust_material())
	assert_same(SteelFx._sector(-1.0, 1.0), SteelFx._sector(-1.0, 1.0))
