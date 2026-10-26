class_name IceVortexFx
extends Node3D

## Le Désastre hivernal en 3D, et son Implosion (jalon 54, « lames » choisi sur planche contre un blizzard
## en spirale — un disque presque blanc —, le vent de la Nova enroulé en spirale, le blizzard sous une
## distorsion qui tourne et le disque d'étincelles) : une spirale de lames de glace peinte par Qwen-Image
## (`fx/frost_vortex.png`) qui tourne au rayon du vortex ; des esquilles des Pics qui orbitent, plus vite
## au cœur ; des scintillements là où il couvre ; une lumière froide tenue ; pas de glace au sol, qui
## dirait un sol gelé. Il grandit avec le vortex — l'Implosion le resserre — et, le vortex parti, se
## ronge. **L'Aspiration** (« distorsion » choisie sur planche contre des esquilles aspirées, un anneau qui
## se resserre et les deux) : à chaque frappe, une onde de distorsion part du bord et se resserre vers le
## cœur, le sol et les ennemis tirés vers le centre.
##
## Il vit à la racine du viewport et suit son vortex : la Coulée le fait rouler.

const SWIRL := preload("res://fx/frost_vortex.gdshader")
const PHOTO := preload("res://fx/frost_vortex.png")
const SPAN := 1.05
const CHIPS := 36
const CHIP_SIZE := Vector3(2.5, 9.0, 2.5)
## En radians par seconde au bord ; le cœur tourne plus vite.
const CHIP_SPIN := 3.0
const CHIP_HEIGHT := Vector2(3.0, 14.0)
const GLINTS := 14
const LIGHT := 1.5
## La fin : rongé en `EATEN`.
const EATEN := 0.35
## L'onde de l'Aspiration : jusqu'où vers le cœur, en part de la portée, sa force et sa bande.
const SUCK_DEPTH := 0.2
const SUCK_STRENGTH := 0.03
const SUCK_SPREAD := 0.12

var _vortex: IceVortex
var _radius := 0.0
var _clock := 0.0
var _reach := 0.0
var _broken_at := -1.0
var _disc: MeshInstance3D
var _chips: MultiMeshInstance3D
## Par esquille : sa part du rayon, son angle de départ, sa hauteur.
var _orbits: Array[Vector3] = []
var _glints: MultiMeshInstance3D
var _glint_phases: Array[float] = []
var _glint_spots: Array[float] = []
var _light: OmniLight3D
var _suck: MeshInstance3D
## Depuis la dernière frappe, en part de la période : l'onde de l'Aspiration en part.
var _beat := 0.0


## Le tourbillon de `vortex`, taillé pour `radius`, sa plus grande portée (Boule de neige comprise) ; il suit
## sa portée du moment (`IceVortex.reach()`).
static func spin_up(vortex: IceVortex, nature: int, radius: float) -> IceVortexFx:
	var fx := IceVortexFx.new()
	fx._vortex = vortex
	fx._radius = radius
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	vortex.get_viewport().add_child(fx)
	fx._follow()
	fx._disc = IceNovaFx.flat(fx, IceNovaFx.material(SWIRL, nature), radius * SPAN, DangerZone.LIFT + 0.6)
	fx._chips = IceNovaFx.multimesh(fx, IceSpikesFx.crystals()[2], CHIPS, IceSpikesFx.crystal(nature))
	for i in CHIPS:
		fx._orbits.append(Vector3(randf_range(0.2, 1.0), randf() * TAU, randf_range(CHIP_HEIGHT.x, CHIP_HEIGHT.y)))
	fx._glints = IceNovaFx.scatter_glints(fx, GLINTS, radius, nature, fx._glint_phases, fx._glint_spots)
	if vortex._cast.pull > 0.0:
		fx._suck = IceNovaFx.flat(fx, IceNovaFx.material(IceNovaFx.WARP, nature), radius * SPAN, DangerZone.LIFT + 0.8)
		fx._suck.set_instance_shader_parameter(&"spread", SUCK_SPREAD)
	fx._light = FlameFx.light_of(nature, LIGHT, radius * 2.0)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * 18.0
	fx.add_child(fx._light)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, vortex)
	fx._show()
	return fx


func _process(delta: float) -> void:
	_clock += delta
	if _broken_at < 0.0:
		if is_instance_valid(_vortex) and not _vortex.is_queued_for_deletion():
			_follow()
		else:
			_broken_at = _clock
	_show()
	if _broken_at >= 0.0 and _clock - _broken_at > EATEN:
		queue_free()


func _follow() -> void:
	global_position = _vortex.get_global_transform_interpolated().origin
	_reach = _vortex.reach()
	if _vortex._cast.period > 0.0:
		_beat = fposmod(_vortex._age, _vortex._cast.period) / _vortex._cast.period


func _show() -> void:
	var gone := _clock - _broken_at if _broken_at >= 0.0 else -1.0
	var eaten := smoothstep(0.0, EATEN, gone)
	_disc.visible = eaten < 1.0
	_disc.set_instance_shader_parameter(&"reach", _reach / (_radius * SPAN))
	_disc.set_instance_shader_parameter(&"clock", _clock)
	_disc.set_instance_shader_parameter(&"dissolve", eaten)
	_chips.visible = eaten < 1.0
	for i in CHIPS:
		_chips.multimesh.set_instance_transform(i, chip(i))
	_chips.set_instance_shader_parameter(&"dissolve", eaten)
	for i in GLINTS:
		var on := 1.0 - eaten if _glint_spots[i] < _reach else 0.0
		IceNovaFx.shine(_glints, i, on * IceNovaFx.twinkle(_clock, _glint_phases[i], 5.0, 8.0))
	_light.light_energy = LIGHT * (1.0 - eaten)
	if _suck != null:
		_suck.set_instance_shader_parameter(&"front", _reach / (_radius * SPAN) * lerpf(1.0, SUCK_DEPTH, _beat))
		# Négative : le sol est tiré vers le cœur.
		_suck.set_instance_shader_parameter(&"strength", -SUCK_STRENGTH * (1.0 - _beat) * (1.0 - eaten))


## L'esquille `i` à cet instant, couchée sur son orbite ; publique pour les tests, le moteur sans rendu ne
## relit pas un `MultiMesh`.
func chip(i: int) -> Transform3D:
	var o := _orbits[i]
	var h := o.y + _clock * CHIP_SPIN / (0.3 + o.x)
	var tangent := Vector3(-sin(h), 0.0, cos(h))
	var lying := Basis.looking_at(tangent, Vector3.UP) * Basis(Vector3.RIGHT, -PI * 0.5)
	return Transform3D(lying * Basis(Vector3.UP, _clock * 9.0 + float(i)) * Basis.from_scale(CHIP_SIZE),
			Vector3(cos(h), 0.0, sin(h)) * o.x * _reach + Vector3.UP * o.z)
