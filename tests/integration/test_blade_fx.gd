extends GutTest

## Le manuel du Vive lame en 3D (jalon 54, à la barre de Last Epoch) : la Frappe vive, la croix du Coup de
## grâce et l'étoile du Point final, le couteau et les lames plantées, les étoiles de la Frénésie, les croissants
## de la Garde. Chacun se pose où il frappe ou suit ce qu'il montre, se ronge puis se libère, prend le voile
## des sorts et garde ses matières.

const PHYS := DamageType.Kind.PHYSICAL
const KNIFE_SCENE := preload("res://actors/projectiles/player_knife.tscn")

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


## Les rubans de lame vivants dans tout le viewport.
func _ribbons() -> Array:
	return get_viewport().find_children("*", "MeshInstance3D", true, false).filter(func(n: Node) -> bool:
		return (n as MeshInstance3D).material_override == SteelFx.slash_material(PHYS) and not n.is_queued_for_deletion())


func _decals(texture: Texture2D) -> Array:
	return get_viewport().find_children("*", "Decal", true, false).filter(func(n: Node) -> bool:
		return (n as Decal).texture_albedo == texture and not n.is_queued_for_deletion())


func _buff() -> Buff:
	var buff := Buff.new()
	_world.add_child(buff)
	buff.set_physics_process(false)
	Settings.veil(buff, Settings.SPELLS)
	return buff


## Le couloir et ses trois lignes de vitesse, couchés du départ à l'arrivée ; l'entaille debout sur la cible.
func test_blade_lunge_cuts_its_corridor_and_gashes_the_prey() -> void:
	BladeFx.lunge(_host(), Vector3.ZERO, Vector3(100, 0, 0), Vector3(114, 0, 0))
	var ribbons := _ribbons()
	assert_eq(ribbons.size(), 5, "le couloir, trois lignes, l'entaille")
	var corridor: MeshInstance3D = ribbons.filter(func(n: Node) -> bool:
		return absf((n as Node3D).global_basis.z.length() - BladeFx.CORRIDOR) < 0.01)[0]
	assert_almost_eq(corridor.global_basis.x.length(), 100.0, 0.01, "du départ à l'arrivée")
	var gash: MeshInstance3D = ribbons.filter(func(n: Node) -> bool:
		return (n as Node3D).global_position.y > ElementFx.LIFT + 1.0)[0]
	assert_almost_eq(gash.global_position.x, 114.0, 0.01, "sur la cible")
	assert_true(gash.is_in_group(Settings.SPELLS), "sous le voile")
	await wait_seconds(BladeFx.SWEEP + BladeFx.FADE + 0.1)
	assert_eq(_ribbons().size(), 0, "rongés")


## La croix gravée : deux entailles, la seconde un temps après la première, et le sang au sol.
func test_blade_grace_carves_its_cross_and_bleeds() -> void:
	BladeFx.grace(_host(), Vector3(40, 0, 0), PHYS)
	assert_eq(_decals(SteelFx.BLOOD).size(), 1, "la gerbe de sang")
	var cuts := _ribbons()
	assert_eq(cuts.size(), 2, "deux entailles")
	await wait_seconds(BladeFx.SWEEP * 0.5)
	var heads := cuts.map(func(n: Node) -> float: return (n as MeshInstance3D).get_instance_shader_parameter(&"head"))
	assert_gt(heads.max(), 0.0, "la première court")
	assert_lt(heads.min(), 0.0, "la seconde attend")
	await wait_seconds(BladeFx.CROSS_GAP + BladeFx.SWEEP + BladeFx.FADE + 0.1)
	assert_eq(_ribbons().size(), 0)


## L'étoile du Point final : huit rais, longs et courts, jusqu'au rayon.
func test_blade_final_point_bursts_into_a_star() -> void:
	BladeFx.final_point(_host(), Vector3.ZERO, 40.0, PHYS)
	var rays := _ribbons()
	assert_eq(rays.size(), BladeFx.STAR_RAYS)
	var lengths := rays.map(func(n: Node) -> float: return (n as Node3D).global_basis.x.length())
	assert_almost_eq(lengths.max(), 36.0, 0.01, "les longs, du cœur au rayon")
	assert_almost_eq(lengths.min(), 40.0 * BladeFx.STAR_SHORT - 4.0, 0.01, "les courts")


## Le couteau en vol : la lame pointe où il va, et sa traînée courte lui survit le temps de s'éteindre.
func test_blade_knife_points_where_it_flies_and_trails_briefly() -> void:
	var dir := Vector3(1, 0, 1).normalized()
	var parts := DamageType.empty_parts()
	var knife := Projectile.spawn(_world, KNIFE_SCENE, Vector3.ZERO, dir, parts, _host(), 100.0, PHYS) as ThrowingKnife
	await wait_physics_frames(2)
	assert_almost_eq(-knife._knife.global_basis.z.normalized(), dir, Vector3.ONE * 0.01, "pointe en avant")
	var trails := get_viewport().get_children().filter(func(n: Node) -> bool: return n is BoltFx.Trail)
	assert_eq(trails.size(), 1)
	var trail: BoltFx.Trail = trails[0]
	assert_eq(trail.life, BladeFx.KNIFE_TRAIL_LIFE, "courte")
	assert_true(trail.is_in_group(Settings.SPELLS))
	knife.queue_free()
	await wait_seconds(BladeFx.KNIFE_TRAIL_LIFE + 0.1)
	assert_false(is_instance_valid(trail), "éteinte, elle se libère")


## Une lame par couteau planté, cinq au plus, fichée au flanc d'où il est venu.
func test_blade_planted_knives_show_in_the_flank_they_came_from() -> void:
	var target := Hurtbox.new()
	_world.add_child(target)
	var cast := SkillStats.new()
	var heading := Vector3(1, 0, 0)
	for i in SkillStats.PLANT_MOST + 2:
		PlantedKnives.plant(target, cast, heading)
	var knives := PlantedKnives.of(target)
	assert_eq(knives.get_child_count(), SkillStats.PLANT_MOST, "une par lame, au plafond")
	for pin: Node3D in knives.get_children():
		assert_lt(pin.position.dot(heading), 0.0, "du côté d'où elles viennent")
		assert_gt(-pin.global_basis.z.dot(heading), 0.4, "pointe dans le corps")



## Les lames lâchent leur cible morte — le corps part dans l'image — et tombent au sol, où elles restent avant de
## s'enfoncer ; le couteau qui tue, planté dans un mort, tombe de même.
func test_blade_planted_knives_drop_when_their_target_dies() -> void:
	var grunt: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	_world.add_child(grunt)
	grunt.global_position = Vector3(40, 0, 0)
	await wait_physics_frames(1)
	var cast := SkillStats.new()
	PlantedKnives.plant(grunt.hurtbox, cast, Vector3.RIGHT)
	PlantedKnives.plant(grunt.hurtbox, cast, Vector3.RIGHT)
	grunt.die(false)
	var fallen := _fallen()
	assert_eq(fallen.size(), 2, "une lame par couteau planté")
	await wait_seconds(BladeFx.DROP_FALL + 0.1)
	for blade: Node3D in fallen:
		assert_lt(blade.global_position.y, BladeFx.PLANT_HEIGHT * 0.5, "au sol")
		assert_true(blade.is_in_group(Settings.SPELLS))
	await wait_seconds(BladeFx.DROP_STAY + BladeFx.DROP_GONE)
	assert_eq(_fallen().size(), 0, "enfoncées, libérées")
	var dead: Enemy = load("res://actors/enemies/grunt.tscn").instantiate()
	_world.add_child(dead)
	await wait_physics_frames(1)
	dead.die(false)
	PlantedKnives.plant(dead.hurtbox, cast, Vector3.RIGHT)
	assert_eq(_fallen().size(), 1, "le couteau qui tue tombe aussi")
	assert_null(PlantedKnives.of(dead.hurtbox), "et ne reste pas dans le mort")


## Les lames tombées, à la racine du viewport : l'épée du modèle hors de tout porteur.
func _fallen() -> Array:
	var blade_mesh: Mesh = SteelFx.sword_parts()[0][0]
	return get_viewport().get_children().filter(func(n: Node) -> bool:
		return n is Node3D and n.get_child_count() > 0 and n.get_child(0) is MeshInstance3D \
				and (n.get_child(0) as MeshInstance3D).mesh == blade_mesh and not n.is_queued_for_deletion())

## Une étoile par charge de Frénésie, qui tourne ; les charges dépensées, elles partent.
func test_blade_frenzy_shows_a_star_per_charge() -> void:
	var buff := _buff()
	var fx := BladeFx.frenzy(buff)
	buff.stacks = 4
	await wait_process_frames(2)
	assert_eq(fx._stars.size(), 4)
	assert_true(fx._stars[0].is_in_group(Settings.SPELLS))
	assert_same(fx._stars[0].material_override, fx._stars[1].material_override, "une matière gardée")
	var before := fx._stars[0].position
	await wait_process_frames(3)
	assert_ne(fx._stars[0].position, before, "elles tournent")
	buff.stacks = 1
	await wait_process_frames(2)
	assert_eq(fx._stars.size(), 1)


## La Garde : deux croissants pâles qui tournent bas autour de lui, sous le voile.
func test_blade_guard_turns_two_crescents() -> void:
	var buff := _buff()
	var fx := BladeFx.guard(buff)
	var arcs := fx.get_children()
	assert_eq(arcs.size(), 2)
	assert_true(arcs[0].is_in_group(Settings.SPELLS))
	assert_eq((arcs[0] as MeshInstance3D).get_instance_shader_parameter(&"head"), 1.0, "entiers")
	await wait_process_frames(3)
	assert_ne(fx.rotation.y, 0.0, "ils tournent")
	buff.free()
	assert_false(is_instance_valid(fx), "partis avec la Garde")


func test_blade_materials_are_kept() -> void:
	var glint := SteelFx.glint_material(PHYS)
	assert_same(BladeFx.blood_material(&"glint", glint), BladeFx.blood_material(&"glint", glint))
	var heart: Vector3 = BladeFx.blood_material(&"glint", glint).get_shader_parameter(&"tint")
	assert_gt(heart.x, heart.y * 4.0, "rouge sang, pas l'acier")
