class_name FireBlastFx
extends Node3D

## Ce que la barre de Last Epoch ajoute à une explosion de feu (jalon 54, « pile rouge » choisie sur planche
## contre l'actuelle, la pile aux photos pleines — une boule blanche — et la pile sans photos d'explosion) :
## une onde de feu couchée qui s'ouvre et se ronge au liseré brûlant (`fx/fire_shock.gdshader`), la chaleur
## qui tremble sur son front (`fx/heat_haze.gdshader`), des étincelles qui volent et retombent
## (`Sparks`). Les photos, les volutes, la fumée et l'éclair restent à `FlameFx.blast`, qui le pose.
##
## Il vit à la racine du viewport et se libère seul.

const SHOCK := preload("res://fx/fire_shock.gdshader")
const HAZE := preload("res://fx/heat_haze.gdshader")
const WIND := preload("res://fx/fire_wind.png")
## Réglée sur planche à ce rayon : l'onde n'y est jamais plus large, en pixels — à 45 px (le Météore),
## large d'une part de son rayon, elle couvrait un disque plein.
const RADIUS := 20.0
const OPEN := 0.22
const EATEN := Vector2(0.12, 0.5)
const BOOST := 0.55
const HAZE_STRENGTH := 0.02
const HAZE_LIFE := Vector2(0.1, 0.6)
const SPARKS := 28

static var _materials := {}
static var _haze: ShaderMaterial

var _clock := 0.0
var _radius := RADIUS
var _shock: MeshInstance3D
var _heat: MeshInstance3D


## L'explosion de `host` (pour son voile) en `at`, à son rayon.
static func blow(host: Node3D, at: Vector3, nature: int, radius: float) -> FireBlastFx:
	var fx := FireBlastFx.new()
	fx._radius = radius
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(fx)
	fx.global_position = at
	fx._shock = IceNovaFx.flat(fx, shock_material(nature), radius * 1.15, DangerZone.LIFT + 0.6)
	fx._shock.set_instance_shader_parameter(&"boost", BOOST)
	fx._heat = IceNovaFx.flat(fx, haze_material(), radius * 1.3, DangerZone.LIFT + 0.4)
	fx._heat.set_instance_shader_parameter(&"spread", 0.18)
	for node in [fx._shock, fx._heat]:
		ElementFx.veil_like(node, host)
	Sparks.burst(host, at, nature, SPARKS + int(10.0 * radius / RADIUS), radius)
	fx._show()
	fx.get_tree().create_timer(HAZE_LIFE.y + 0.05).timeout.connect(fx.queue_free)
	return fx


func _process(delta: float) -> void:
	_clock += delta
	_show()


func _show() -> void:
	var front := ease(clampf(_clock / OPEN, 0.0, 1.0), 0.4)
	_shock.visible = _clock < EATEN.y
	_shock.set_instance_shader_parameter(&"front", front * 0.9)
	_shock.set_instance_shader_parameter(&"width", (0.07 + 0.1 * front) * minf(1.0, RADIUS * 1.5 / _radius))
	_shock.set_instance_shader_parameter(&"clock", _clock)
	_shock.set_instance_shader_parameter(&"dissolve", smoothstep(EATEN.x, EATEN.y, _clock))
	_heat.set_instance_shader_parameter(&"front", front * 0.85)
	_heat.set_instance_shader_parameter(&"strength", HAZE_STRENGTH * (1.0 - smoothstep(HAZE_LIFE.x, HAZE_LIFE.y, _clock)))


## L'onde de feu, une matière par nature, gardée ; le sacré y passe sa bande de lumière (`HolyBlastFx`).
static func shock_material(nature: int) -> ShaderMaterial:
	if not _materials.has(nature):
		var m := ShaderMaterial.new()
		m.shader = SHOCK
		m.set_shader_parameter(&"wind", HolyBlastFx.WAVE if nature == DamageType.Kind.HOLY else WIND)
		var ramp := FlameFx.ramp(nature)
		for k in 3:
			m.set_shader_parameter([&"heart", &"tint", &"deep"][k], Vector3(ramp[k].r, ramp[k].g, ramp[k].b))
		_materials[nature] = m
	return _materials[nature]


## La chaleur qui tremble, une pour tous : dessinée avant le feu, qui s'additionne dessus sans trembler.
static func haze_material() -> ShaderMaterial:
	if _haze == null:
		_haze = ShaderMaterial.new()
		_haze.shader = HAZE
		_haze.render_priority = -1
	return _haze
