extends GutTest

## Le visuel générique des compétences en 3D (jalon 54) : des étincelles à côté de leur
## porteur, qui lui survivent le temps de retomber.

var _world: Node3D


func before_each() -> void:
	_world = Node3D.new()
	add_child_autofree(_world)


func _host(at := Vector3.ZERO) -> Node3D:
	var host := Node3D.new()
	_world.add_child(host)
	host.global_position = at
	return host


func test_a_trail_follows_its_host_then_outlives_it() -> void:
	var host := _host(Vector3(10, 0, 0))
	var fx := ElementFx.trail(host, Color.ORANGE)
	assert_eq(fx.get_parent(), host.get_viewport(), "hors des conteneurs que le jeu compte")
	host.global_position = Vector3(50, 0, 20)
	await wait_process_frames(2)
	assert_almost_eq(fx.global_position, Vector3(50, ElementFx.LIFT, 20), Vector3.ONE * 0.01)
	host.queue_free()
	await wait_process_frames(2)
	assert_true(is_instance_valid(fx), "ce qui vole finit de retomber")
	assert_false(fx.emitting, "plus rien ne naît")
	await wait_seconds(ElementFx.TRAIL_LIFE + 0.1)
	assert_false(is_instance_valid(fx), "puis rien")


func test_a_burst_frees_itself() -> void:
	var fx := ElementFx.burst(_host(), Vector3(5, 0, 5), Color.CYAN, 30.0)
	assert_true(fx.one_shot)
	assert_gt(fx.amount, 24, "assez d'étincelles pour un rayon de 30")
	await wait_seconds(ElementFx.BURST_LIFE * 2.0 + 0.2)
	assert_false(is_instance_valid(fx))


func test_a_sweep_runs_the_arc_then_stops() -> void:
	var host := _host()
	var fx := ElementFx.sweep(host, Color.WHITE, 20.0, 0.1)
	var start := fx.global_position
	assert_almost_eq(Flat.angle(start), -ElementFx.SWEEP_HALF, 0.01, "le balayage part d'un côté de la visée")
	await wait_seconds(0.15)
	assert_false(fx.emitting, "le coup fini, plus rien ne naît")


func test_the_sparks_take_their_host_veil() -> void:
	var before := Settings.to_dict()
	Settings.enemy_attack_opacity = 0.3
	var host := _host()
	Settings.veil(host, Settings.ENEMY_ATTACKS)
	var fx := ElementFx.trail(host, Color.RED)
	assert_true(fx.is_in_group(Settings.ENEMY_ATTACKS))
	assert_almost_eq(fx.get_instance_shader_parameter(&"opacity"), 0.3, 0.001)
	Settings.from_dict(before)
