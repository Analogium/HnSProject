class_name HolyBlastFx
extends Node3D

## Le souffle sacré en 3D (jalon 54, à la barre de Last Epoch) : l'onde de lumière couchée qui s'ouvre et
## se ronge au liseré (l'onde de feu, `fx/fire_shock.gdshader`, sur une bande de lumière de Qwen-Image), les
## rayons de gloire de la 2D (`fx/holy_rays.gdshader`), un éclat photographié au cœur (`fx/holy_flare.gdshader`),
## des grains d'or qui montent (`Sparks`) et l'éclair d'une lumière portée. Toute explosion sacrée le jette ;
## les ondes de la Pulsation et les impulsions du Pilier le prennent sans rayons ni éclat.
##
## Il vit à la racine du viewport et se libère seul.

const RAYS := preload("res://fx/holy_rays.gdshader")
const FLARE_SHADER := preload("res://fx/holy_flare.gdshader")
const WAVE := preload("res://fx/holy_wave.png")
const FLARE := preload("res://fx/holy_flare.png")
## Réglée sur planche à ce rayon : l'onde et les rayons n'y sont jamais plus larges, en pixels.
const RADIUS := 30.0
const OPEN := 0.22
const EATEN := Vector2(0.12, 0.5)
const BOOST := 0.7
const RAYS_LIFE := 0.4
const RAY_WIDTH := 0.14
## Le blanc du sacré, en haut de sa rampe : chaud et non bleu — une lumière d'or et de cierge, pas un néon.
const GLORY := Color(1.0, 0.96, 0.92)
## L'éclat au cœur : sa taille en pixels au plus.
const FLARE_SIZE := 40.0
const FLARE_LIFE := 0.3
## Sur le sol consacré, plein, il blanchissait l'Effondrement.
const FLARE_GLOW := 0.7
const SPARKS := 22
const LIGHT := 6.0
const LIGHT_LIFE := 0.45

static var _rays := {}
static var _flares := {}
static var _quad: QuadMesh

var _clock := 0.0
var _radius := RADIUS
var _shock: MeshInstance3D
var _glory: MeshInstance3D
var _flare: MeshInstance3D
var _light: OmniLight3D


## Le souffle de `host` (pour son voile) en `at`, à son rayon ; `rays` : les rayons de gloire en plus de
## l'onde.
static func blow(host: Node3D, at: Vector3, nature: int, radius: float, rays := true) -> HolyBlastFx:
	var fx := HolyBlastFx.new()
	fx._radius = radius
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(fx)
	fx.global_position = at
	fx._shock = IceNovaFx.flat(fx, FireBlastFx.shock_material(nature), radius * 1.15, DangerZone.LIFT + 0.6)
	fx._shock.set_instance_shader_parameter(&"boost", BOOST)
	if rays:
		fx._glory = IceNovaFx.flat(fx, rays_material(nature), radius, DangerZone.LIFT + 0.9)
		fx._glory.rotation.y = randf() * TAU
		fx._flare = MeshInstance3D.new()
		fx._flare.mesh = _flare_quad()
		fx._flare.material_override = flare_material(nature)
		fx._flare.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fx._flare.position = Vector3.UP * ElementFx.LIFT
		fx._flare.rotation.z = randf() * TAU
		fx.add_child(fx._flare)
	fx._light = FlameFx.light_of(nature, LIGHT, radius * 3.0)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * 16.0
	fx.add_child(fx._light)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, host)
	# Des grains de lumière : ils montent, quand les braises retombent.
	Sparks.burst(host, at, nature, SPARKS + int(10.0 * radius / RADIUS), radius * 0.6).rising = true
	fx._show()
	fx.get_tree().create_timer(maxf(EATEN.y, LIGHT_LIFE) + 0.05).timeout.connect(fx.queue_free)
	return fx


func _process(delta: float) -> void:
	_clock += delta
	_show()


func _show() -> void:
	var front := ease(clampf(_clock / OPEN, 0.0, 1.0), 0.4)
	var narrow := minf(1.0, RADIUS / _radius)
	_shock.visible = _clock < EATEN.y
	_shock.set_instance_shader_parameter(&"front", front * 0.9)
	_shock.set_instance_shader_parameter(&"width", (0.08 + 0.12 * front) * narrow)
	_shock.set_instance_shader_parameter(&"clock", _clock)
	_shock.set_instance_shader_parameter(&"dissolve", smoothstep(EATEN.x, EATEN.y, _clock))
	if _glory != null:
		# Comme en 2D : les rayons s'ouvrent jusqu'au bord, puis leur pied rattrape leur pointe.
		var k := clampf(_clock / RAYS_LIFE, 0.0, 1.0)
		_glory.visible = k < 1.0
		_glory.set_instance_shader_parameter(&"reach", 1.0 - pow(1.0 - minf(k * 1.6, 1.0), 3.0))
		_glory.set_instance_shader_parameter(&"foot", maxf(0.15, k * 1.1))
		_glory.set_instance_shader_parameter(&"width", RAY_WIDTH * narrow)
		_glory.set_instance_shader_parameter(&"clock", _clock)
	if _flare != null:
		var f := clampf(_clock / FLARE_LIFE, 0.0, 1.0)
		_flare.visible = f < 1.0
		_flare.scale = Vector3.ONE * minf(FLARE_SIZE, _radius * 1.4) * (0.6 + 0.4 * ease(f, 0.3))
		_flare.set_instance_shader_parameter(&"glow", FLARE_GLOW * pow(1.0 - f, 2.0))
	_light.light_energy = LIGHT * pow(1.0 - clampf(_clock / LIGHT_LIFE, 0.0, 1.0), 2.0)


## Une photo passée par la rampe de sa nature (`BoltFx.ramped()`), le blanc du sacré en haut.
static func ramped(shader: Shader, photo: Texture2D, nature: int) -> ShaderMaterial:
	var m := BoltFx.ramped(shader, photo, nature)
	m.set_shader_parameter(&"core", Vector3(GLORY.r, GLORY.g, GLORY.b))
	return m


## Les rayons et l'éclat, une matière par nature : la dernière onde d'une Pulsation convertie en a aussi.
static func rays_material(nature: int) -> ShaderMaterial:
	if not _rays.has(nature):
		_rays[nature] = ramped(RAYS, WAVE, nature)
	return _rays[nature]


static func flare_material(nature: int) -> ShaderMaterial:
	if not _flares.has(nature):
		_flares[nature] = ramped(FLARE_SHADER, FLARE, nature)
	return _flares[nature]


static func _flare_quad() -> QuadMesh:
	if _quad == null:
		_quad = QuadMesh.new()
	return _quad
