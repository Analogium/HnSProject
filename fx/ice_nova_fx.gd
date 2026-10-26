class_name IceNovaFx
extends Node3D

## Une explosion de froid en 3D, la Nova de glace d'abord (jalon 54). « Souffle d'esquilles » choisi sur
## une première planche, puis refait à la barre de Last Epoch : « vitrine sans brume » choisie contre la
## même pile avec une brume en flipbook, une autre glace au sol et l'ancienne. Les couches : une onde de
## choc couchée, le vent de givre qui défile, rongée avec un liseré ; une distorsion sur son front ; une
## quarantaine d'esquilles qui volent à plat jusqu'au bord puis se rongent ; des scintillements ; un
## éclair de lumière froide. La glace au sol de la vitrine en est partie (demande de l'utilisateur, 26
## octobre) : elle disait un sol gelé que la Nova ne pose pas ; elle reste au sol gelé (`FrostGroundFx`).
##
## Il vit à la racine du viewport et se libère seul : l'explosion ne dure que trois dixièmes, ses
## scintillements un peu plus.

const SHOCK := preload("res://fx/frost_shock.gdshader")
const WARP := preload("res://fx/frost_warp.gdshader")
const GLINT := preload("res://fx/frost_glint.gdshader")
const WIND := preload("res://fx/frost_wind.png")
## Dessiné pour le rayon de la Nova : un autre rayon porte les esquilles plus loin, et les grandit moins.
const RADIUS := 46.0
const SLIVERS := 40
const SLIVER_SIZE := Vector3(2.5, 12.0, 2.5)
## En radians par seconde, autour de leur axe.
const SPIN := 20.0
const FLY := 0.2
## Elles se rongent au lieu de pâlir : un cristal à demi transparent sort gris sur l'ocre.
const EATEN := Vector2(0.25, 0.55)
const SHOCK_OPEN := 0.2
const SHOCK_EATEN := Vector2(0.12, 0.42)
const WARP_LIFE := 0.3
const WARP_STRENGTH := 0.035
const GLINTS := 26
const GLINT_LIGHT := Vector2(0.08, 1.3)
const LIGHT := 3.5
const LIGHT_LIFE := 0.5

static var _materials := {}

var _clock := 0.0
var _radius := RADIUS
var _slivers: MultiMeshInstance3D
var _flights: Array[Flight] = []
var _shock: MeshInstance3D
var _warp: MeshInstance3D
var _glints: MultiMeshInstance3D
var _glint_phases: Array[float] = []
var _light: OmniLight3D


class Flight:
	## Là où elle s'arrête, au sol, depuis le centre.
	var reach: Vector3
	var height := 0.0
	var turn := 0.0
	## Couchée, pointe dehors : le cap seul, sans l'étirement ni la rotation sur son axe.
	var lying: Basis


## L'explosion de `host` (pour son voile) en `at`, à son rayon ; elle se libère seule.
static func blow(host: Node3D, at: Vector3, nature: int, radius: float) -> IceNovaFx:
	var fx := IceNovaFx.new()
	fx._radius = radius
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(fx)
	fx.global_position = at
	var grown := sqrt(radius / RADIUS)
	for i in SLIVERS:
		var h := TAU * (float(i) + randf_range(-0.4, 0.4)) / float(SLIVERS)
		var flight := Flight.new()
		flight.reach = Vector3(cos(h), 0.0, sin(h)) * radius * randf_range(0.55, 1.0)
		flight.height = randf_range(4.0, 12.0) * grown
		flight.turn = randf() * TAU
		flight.lying = Basis(Vector3.UP, PI * 0.5 - h) * Basis(Vector3.RIGHT, PI * 0.5)
		fx._flights.append(flight)
	fx._slivers = multimesh(fx, IceSpikesFx.crystals()[randi() % IceSpikesFx.SHAPES], SLIVERS, IceSpikesFx.crystal(nature))
	fx._shock = flat(fx, material(SHOCK, nature), radius * 1.15, DangerZone.LIFT + 0.6)
	fx._warp = flat(fx, material(WARP, nature), radius * 1.25, DangerZone.LIFT + 0.8)
	fx._glints = scatter_glints(fx, GLINTS, radius, nature, fx._glint_phases)
	fx._light = FlameFx.light_of(nature, LIGHT, radius * 3.0)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * 16.0
	fx.add_child(fx._light)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, host)
	fx._show()
	fx.get_tree().create_timer(GLINT_LIGHT.y + 0.05).timeout.connect(fx.queue_free)
	return fx


func _process(delta: float) -> void:
	_clock += delta
	_show()


func _show() -> void:
	_slivers.visible = _clock < EATEN.y
	if _slivers.visible:
		for i in _flights.size():
			_slivers.multimesh.set_instance_transform(i, sliver(i))
		_slivers.set_instance_shader_parameter(&"dissolve", smoothstep(EATEN.x, EATEN.y, _clock))
	var front := ease(clampf(_clock / SHOCK_OPEN, 0.0, 1.0), 0.4)
	_shock.visible = _clock < SHOCK_EATEN.y
	_shock.set_instance_shader_parameter(&"front", front * 0.92)
	_shock.set_instance_shader_parameter(&"width", 0.12 + 0.18 * front)
	_shock.set_instance_shader_parameter(&"clock", _clock)
	_shock.set_instance_shader_parameter(&"dissolve", smoothstep(SHOCK_EATEN.x, SHOCK_EATEN.y, _clock))
	_warp.visible = _clock < WARP_LIFE
	_warp.set_instance_shader_parameter(&"front", front * 0.9)
	_warp.set_instance_shader_parameter(&"strength", WARP_STRENGTH * (1.0 - smoothstep(0.1, WARP_LIFE, _clock)))
	var lit := smoothstep(GLINT_LIGHT.x, GLINT_LIGHT.x + 0.12, _clock) * (1.0 - smoothstep(GLINT_LIGHT.y - 0.4, GLINT_LIGHT.y, _clock))
	_glints.visible = lit > 0.0
	if _glints.visible:
		for i in GLINTS:
			shine(_glints, i, lit * twinkle(_clock, _glint_phases[i]))
	_light.light_energy = LIGHT * pow(1.0 - clampf(_clock / LIGHT_LIFE, 0.0, 1.0), 2.0)


## L'esquille `i` à cet instant ; publique pour les tests, le moteur sans rendu ne relit pas un `MultiMesh`.
func sliver(i: int) -> Transform3D:
	var f := _flights[i]
	var flown := ease(clampf(_clock / FLY, 0.0, 1.0), 0.35)
	var spun := f.lying * Basis(Vector3.UP, f.turn + _clock * SPIN) * Basis.from_scale(SLIVER_SIZE * sqrt(_radius / RADIUS))
	return Transform3D(spun, f.reach * flown + Vector3.UP * f.height)


## Des scintillements semés dans ce rayon, éteints ; leurs phases vont dans `phases`, leurs distances au
## centre dans `spots`.
static func scatter_glints(
	parent: Node3D, count: int, radius: float, nature: int, phases: Array[float], spots: Array[float] = []
) -> MultiMeshInstance3D:
	var glints := multimesh(parent, QuadMesh.new(), count, material(GLINT, nature), true)
	for i in count:
		var h := randf() * TAU
		var spot := radius * sqrt(randf()) * 0.95
		spots.append(spot)
		var at := Vector3(cos(h), 0.0, sin(h)) * spot + Vector3.UP * randf_range(1.5, 6.0)
		glints.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * randf_range(4.0, 7.0)), at))
		glints.multimesh.set_instance_custom_data(i, Color.BLACK)
		phases.append(randf() * TAU)
	return glints


## Un éclat bref, qui revient : `pace` en radians par seconde.
static func twinkle(clock: float, phase: float, pace := 9.0, sharpness := 6.0) -> float:
	return pow(maxf(sin(clock * pace + phase), 0.0), sharpness)


static func shine(glints: MultiMeshInstance3D, i: int, light: float) -> void:
	glints.multimesh.set_instance_custom_data(i, Color(light, 0.0, 0.0, 0.0))


## `custom` : une donnée par instance (l'éclat d'un scintillement), posée avant le compte, ou ignorée.
static func multimesh(parent: Node3D, mesh: Mesh, count: int, m: Material, custom := false) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_custom_data = custom
	mm.mesh = mesh
	mm.instance_count = count
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = m
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(node)
	return node


## Un plan couché de `size` de demi-côté, levé de `lift` au-dessus du sol.
static func flat(parent: Node3D, m: ShaderMaterial, size: float, lift: float) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = IceSpikesFx.plane()
	node.material_override = m
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.position = Vector3.UP * lift
	node.scale = Vector3.ONE * size
	parent.add_child(node)
	return node


## Une matière par shader et par nature, gardée : fabriquée à chaque nova, elle repartait au GPU.
static func material(shader: Shader, nature: int) -> ShaderMaterial:
	var key := "%s@%d" % [shader.resource_path, nature]
	if not _materials.has(key):
		var m := ShaderMaterial.new()
		m.shader = shader
		if shader == SHOCK:
			m.set_shader_parameter(&"wind", WIND)
		elif shader == IceVortexFx.SWIRL:
			m.set_shader_parameter(&"swirl", IceVortexFx.PHOTO)
		IceSpikesFx._ramp_into(m, nature)
		_materials[key] = m
	return _materials[key]
