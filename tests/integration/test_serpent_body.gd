extends GutTest

## Le corps du Serpent infernal en 3D (jalon 54) : une grille que le shader courbe le long des
## anneaux du jeu, un matériau par serpent, le voile des sorts et sa fin qui se dissout.

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _snake() -> HellSnake:
	var cast := SkillCatalog.by_id("hell_snake").resolve(1, CharacterStats.new())
	return HellSnake.drop(_world, Vector3(30, 0, 0), cast, Vector3.RIGHT, null)


## Le shader tient le museau et les anneaux dans un tableau de taille fixe.
func test_the_shader_holds_the_snout_and_every_ring() -> void:
	assert_eq(SerpentBody.SPINE, HellSnake.RINGS + 1)
	assert_true(SerpentBody.SHADER.code.contains("spine[%d]" % SerpentBody.SPINE), "même taille dans le shader")


func test_a_snake_wears_its_body_ahead_of_its_head() -> void:
	var snake := _snake()
	var spine: PackedVector3Array = (snake._look.material_override as ShaderMaterial).get_shader_parameter(&"spine")
	assert_eq(spine.size(), SerpentBody.SPINE)
	assert_almost_eq(spine[0].distance_to(snake._body[0]), SerpentBody.SNOUT, 0.01, "le museau devant la tête")


## Sa peau est une texture vraie (`tools/fx_textures.py serpent`), relief et joints compris.
func test_a_snake_wears_its_skin() -> void:
	var m := _snake()._look.material_override as ShaderMaterial
	assert_eq(m.get_shader_parameter(&"skin"), SerpentBody.SKIN)
	assert_eq(m.get_shader_parameter(&"skin_n"), SerpentBody.SKIN_N)


func test_each_snake_bends_its_own_material() -> void:
	assert_ne(_snake()._look.material_override, _snake()._look.material_override)


func test_the_body_takes_the_spell_veil() -> void:
	var before := Settings.to_dict()
	Settings.spell_opacity = 0.3
	assert_almost_eq(_snake()._look.get_instance_shader_parameter(&"opacity"), 0.3, 0.001)
	Settings.from_dict(before)


func test_a_vanishing_snake_dissolves() -> void:
	var snake := _snake()
	await wait_physics_frames(2)
	assert_eq(snake._look.get_instance_shader_parameter(&"fade"), 0.0, "plein en vie")
	snake._vanish()
	await wait_seconds(HellSnake.DISSIPATION * 0.5)
	assert_gt(snake._look.get_instance_shader_parameter(&"fade"), 0.2, "il se dissout")


## Des braises montent de son corps tant qu'il vit, puis finissent de monter.
func test_embers_rise_from_its_body() -> void:
	var snake := _snake()
	var sparks: Sparks = get_viewport().get_children().filter(func(n: Node) -> bool: return n is Sparks).back()
	await wait_process_frames(10)
	assert_gt(sparks._next, 0, "des braises semées")
	var e: Sparks.Ember = sparks._embers[0]
	assert_lt(e.from.distance_to(snake._look._now[0]), 60.0, "sur son corps")
	sparks._clock = e.born + e.life * 0.5
	assert_gt(sparks.ember(0).origin.y, e.from.y, "elles montent")
	snake.queue_free()
	await wait_seconds(SerpentBody.EMBER_LIFE + 0.1)
	assert_false(is_instance_valid(sparks))
