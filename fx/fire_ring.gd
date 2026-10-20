class_name FireRing
extends Node3D

## Le brasier d'Immolation en 3D (jalon 54, « liseré et flammèches » choisi sur planche, après
## une première planche jugée trop chargée) : un liseré de feu qui vacille au rayon qui frappe,
## quelques langues de feu dessus, une chaleur douce au sol, une lumière tenue.

const GROUND := preload("res://fx/fire_ring.gdshader")
const TONGUE := preload("res://fx/flame_tongue.gdshader")
## Les langues : leur nombre, posées dans la dernière bande du rayon ; leur taille, en pixels.
const TONGUES := 14
const BAND := 0.93
const TONGUE_SIZE := 7.0
const TONGUE_LIFE := 0.6
const LIGHT := 3.0

static var _tongue_draw: QuadMesh

var _ground: MeshInstance3D
var _tongues: GPUParticles3D
var _light: OmniLight3D
var _nature := -1
var _radius := 0.0


## Le brasier de `host`, qui le porte.
static func light_up(host: Node3D) -> FireRing:
	var ring := FireRing.new()
	host.add_child(ring)
	ring._ground = MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * 2.0
	ring._ground.mesh = plane
	ring._ground.material_override = ShaderMaterial.new()
	ring._ground.material_override.shader = GROUND
	ring._ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring._ground.position = Vector3.UP * 0.6
	ring.add_child(ring._ground)
	ring._tongues = GPUParticles3D.new()
	ring._tongues.amount = TONGUES
	ring._tongues.lifetime = TONGUE_LIFE
	ring._tongues.preprocess = TONGUE_LIFE
	ring._tongues.fixed_fps = 0
	ring._tongues.process_material = ParticleProcessMaterial.new()
	ring._tongues.draw_pass_1 = _draw()
	ring._tongues.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring._tongues.position = Vector3.UP
	ring.add_child(ring._tongues)
	ring._light = OmniLight3D.new()
	ring._light.light_energy = LIGHT
	ring._light.shadow_enabled = false
	ring._light.position = Vector3.UP * 14.0
	ring.add_child(ring._light)
	for node in [ring._ground, ring._tongues]:
		ElementFx.veil_like(node, host)
	return ring


## Sa nature et son rayon, à chaque impulsion : le Feu de camp le fait monter, un nœud pris en
## cours le change. Rien n'est refait s'ils n'ont pas bougé.
func show_as(nature: int, radius: float) -> void:
	if nature == _nature and is_equal_approx(radius, _radius):
		return
	var ramp := FlameFx.ramp(nature)
	if nature != _nature:
		var m := _ground.material_override as ShaderMaterial
		m.set_shader_parameter(&"tint", Vector3(ramp[1].r, ramp[1].g, ramp[1].b))
		m.set_shader_parameter(&"deep", Vector3(ramp[2].r, ramp[2].g, ramp[2].b))
		_light.light_color = ramp[1]
	_nature = nature
	_radius = radius
	_ground.scale = Vector3(radius, 1.0, radius)
	_light.omni_range = radius * 2.2
	var pm := FlameFx.flame_material(nature, &"trail", FlameFx.BOARD_RADIUS).duplicate() as ParticleProcessMaterial
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius
	pm.emission_ring_inner_radius = radius * BAND
	pm.emission_ring_height = 1.0
	pm.direction = Vector3.UP
	pm.spread = 12.0
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 4.0
	pm.damping_min = 2.0
	pm.damping_max = 4.0
	pm.gravity = Vector3(0, 8, 0)
	pm.scale_min = TONGUE_SIZE * 0.7
	pm.scale_max = TONGUE_SIZE * 1.3
	_tongues.process_material = pm


static func _draw() -> QuadMesh:
	if _tongue_draw == null:
		_tongue_draw = QuadMesh.new()
		# Haute et posée par sa base : le bas de la langue au point d'émission.
		_tongue_draw.size = Vector2(1.0, 2.6)
		_tongue_draw.center_offset = Vector3(0.0, 1.1, 0.0)
		var m := ShaderMaterial.new()
		m.shader = TONGUE
		_tongue_draw.material = m
	return _tongue_draw
