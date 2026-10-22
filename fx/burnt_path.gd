class_name BurntPath
extends Node3D

## Le couloir d'une ruée de feu en 3D (jalon 54, « fissures » choisi sur une deuxième planche,
## la première jugée « cheap ») : la terre craquelée d'un scan (Poly Haven, CC0), noircie, dont
## les fissures rougeoient ; des braises qui montent ; une lueur tenue. Il s'éteint sur sa durée.

const SHADER := preload("res://fx/burnt_path.gdshader")
const CRACKS := preload("res://fx/burnt_cracks.png")
## Une braise par EMBER_AREA px² de couloir : 50 sur la ruée de base (140 px, rayon 16).
const EMBER_AREA := 90.0
const EMBER_LIFE := 1.4
const LIGHT := 2.5
## La part de la durée où les braises et la lueur commencent à s'éteindre.
const DIMMING := 0.45

static var _plane: PlaneMesh
static var _ember_draw: QuadMesh
static var _materials := {}
static var _ember_materials := {}

var _ground: MeshInstance3D
var _embers: GPUParticles3D
var _light: OmniLight3D


## Le couloir de `trail`, posé à son départ, jusqu'à `toward` (en repère global).
static func lay(trail: Node3D, toward: Vector3, nature: int, radius: float, duration: float) -> BurntPath:
	var path := BurntPath.new()
	trail.add_child(path)
	var half := toward.length() * 0.5
	path.position = toward * 0.5
	path.rotation.y = -Flat.angle(toward)
	if _plane == null:
		_plane = PlaneMesh.new()
	path._ground = MeshInstance3D.new()
	path._ground.mesh = _plane
	path._ground.material_override = _material(nature)
	path._ground.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	path._ground.scale = Vector3(half + radius, 1.0, radius)
	path._ground.position = Vector3.UP * DangerZone.LIFT
	path._ground.set_instance_shader_parameter(&"half_len", half)
	path._ground.set_instance_shader_parameter(&"radius", radius)
	path.add_child(path._ground)
	path._embers = embers_of(nature, half, radius)
	path.add_child(path._embers)
	path._light = OmniLight3D.new()
	path._light.light_color = FlameFx.ramp(nature)[1]
	path._light.light_energy = LIGHT
	path._light.omni_range = maxf(half * 1.6, radius * 2.0)
	path._light.shadow_enabled = false
	path._light.position = Vector3.UP * radius
	path.add_child(path._light)
	for node in [path._ground, path._embers]:
		ElementFx.veil_like(node, trail)
	path._fade(duration)
	return path


func _fade(duration: float) -> void:
	var tween := create_tween().set_parallel()
	tween.tween_method(func(t: float) -> void: _ground.set_instance_shader_parameter(&"life", t),
		0.0, 1.0, duration)
	tween.tween_property(_embers, "amount_ratio", 0.0, duration * (1.0 - DIMMING)).set_delay(duration * DIMMING)
	tween.tween_property(_light, "light_energy", 0.0, duration * (1.0 - DIMMING)).set_delay(duration * DIMMING)


static func _material(nature: int) -> ShaderMaterial:
	if _materials.has(nature):
		return _materials[nature]
	var ramp := FlameFx.ramp(nature)
	var m := ShaderMaterial.new()
	m.shader = SHADER
	m.set_shader_parameter(&"cracks", CRACKS)
	m.set_shader_parameter(&"core", Vector3(ramp[0].r, ramp[0].g, ramp[0].b))
	m.set_shader_parameter(&"tint", Vector3(ramp[1].r, ramp[1].g, ramp[1].b))
	m.set_shader_parameter(&"deep", Vector3(ramp[2].r, ramp[2].g, ramp[2].b))
	_materials[nature] = m
	return m


## Les braises, semées dans le couloir : la matière de leur nature, recopiée pour sa longueur —
## la rampe reste partagée, c'est elle qui coûte au GPU.
static func embers_of(nature: int, half: float, radius: float) -> GPUParticles3D:
	if not _ember_materials.has(nature):
		var ramp := FlameFx.ramp(nature)
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		pm.direction = Vector3.UP
		pm.spread = 25.0
		pm.initial_velocity_min = 8.0
		pm.initial_velocity_max = 18.0
		pm.gravity = Vector3(0, 4, 0)
		pm.turbulence_enabled = true
		pm.turbulence_noise_strength = 2.0
		pm.scale_min = 0.5
		pm.scale_max = 1.0
		var gradient := Gradient.new()
		gradient.offsets = PackedFloat32Array([0.0, 0.2, 1.0])
		gradient.colors = PackedColorArray([Color(ramp[0], 0.0), ramp[0], Color(ramp[2], 0.0)])
		var texture := GradientTexture1D.new()
		texture.gradient = gradient
		pm.color_ramp = texture
		_ember_materials[nature] = pm
	var pm := (_ember_materials[nature] as ParticleProcessMaterial).duplicate() as ParticleProcessMaterial
	pm.emission_box_extents = Vector3(half, 0.5, radius * 0.8)
	if _ember_draw == null:
		_ember_draw = QuadMesh.new()
		_ember_draw.size = Vector2.ONE * 2.6
		var m := ShaderMaterial.new()
		m.shader = ElementFx.MATERIAL
		_ember_draw.material = m
	var fx := GPUParticles3D.new()
	fx.amount = clampi(roundi(half * radius * 4.0 / EMBER_AREA), 4, 120)
	fx.lifetime = EMBER_LIFE
	fx.fixed_fps = 0
	fx.process_material = pm
	fx.draw_pass_1 = _ember_draw
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Celle par défaut, un cube de 8 px, sortait de l'écran avec le milieu d'un long couloir.
	fx.visibility_aabb = AABB(Vector3(-half, -2.0, -radius), Vector3(half * 2.0, 40.0, radius * 2.0))
	fx.position = Vector3.UP
	return fx
