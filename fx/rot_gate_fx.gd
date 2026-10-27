class_name RotGateFx
extends Node3D

## La Porte pourrissante en 3D (jalon 54, à la barre de Last Epoch) : **une gueule dans le sol** — des lèvres
## de chair éclairées, bosselées, qui respirent (`fx/crawler.gdshader` sans yeux, la peau pourrie de
## Qwen-Image), autour d'un puits où le gaz tourne vers le noir (`fx/rot_pit.gdshader`) ; elle s'ouvre, se
## referme dans le sol, et souffle une bouffée à chaque créature qu'elle crache. « Gueule » choisie sur une
## planche contre un anneau de chair debout et un sac qui s'ouvre ; une faille photographiée, tournée vers
## la caméra, « faisait très 2D ». **Le Nid porté** prend le sac, qui flotte à l'épaule. **Les créatures**
## — que la 3D ne dessinait plus — : des bulles de chair éclairées aux yeux sombres, qui respirent et
## enflent à attendre (la Gestation), plus grosses en amalgame, plus petites en progéniture. Un `MultiMesh`
## que le portail pose à chaque image.
##
## Il vit sur son portail, qui le libère avec lui.

const SKIN := preload("res://fx/rot_flesh.png")
## Les lèvres (un tore aplati, ovale) et le puits, en pixels.
const LIPS := Vector3(17.0, 14.0, 12.0)
const PIT := Vector3(9.0, 1.0, 6.5)
## Le sac du Nid porté, et son ouverture sur le dessus.
const SAC := Vector3(13.0, 11.0, 13.0)
const SAC_PIT := Vector3(7.0, 1.0, 6.0)
const NEST := 0.55
## Le sac flotte à hauteur d'épaule ; ses créatures partent du sol.
const NEST_LIFT := 14.0
const OPEN := 0.3
const CLOSE := 0.35
## Le rayon d'une créature, en pixels ; ses parts selon sa sorte, et ce que l'attente la fait enfler.
const CRAWLER := 4.5
const SMALL := 0.6
const LAST := 0.45
const BIG := 1.8
const SWELL := 0.15
## Au-delà, les plus récentes ne se dessinent pas : un portail en tient une dizaine.
const MOST := 48
const SPIT_PUFFS := 3

static var _crawler_material: ShaderMaterial
static var _flesh: ShaderMaterial
static var _pits := {}
static var _torus: TorusMesh
static var _blob: SphereMesh
static var _plane: PlaneMesh

var _body: Node3D
var _crawlers: MultiMeshInstance3D
var _nature := DamageType.Kind.NECROTIC
var _life := 0.0
var _clock := 0.0
var _size := 1.0


## La gueule de `gate` (pour son voile), ouverte `life` secondes ; `nest`, le sac porté à l'épaule.
static func open(gate: Node3D, nature: int, life: float, nest := false) -> RotGateFx:
	var fx := RotGateFx.new()
	fx._nature = nature
	fx._life = life
	fx._size = NEST if nest else 1.0
	gate.add_child(fx)
	fx._body = Node3D.new()
	fx.add_child(fx._body)
	if nest:
		fx._body.position = Vector3.UP * NEST_LIFT
		fx._part(blob(), flesh_material(), SAC, SAC.y * 0.55)
		fx._part(plane(), pit_material(nature), SAC_PIT, SAC.y * 1.4)
	else:
		fx._part(torus(), flesh_material(), LIPS, 1.5)
		fx._part(plane(), pit_material(nature), PIT, 2.6)
	fx._crawlers = IceNovaFx.multimesh(fx, blob(), MOST, crawler_material(), true)
	# Les créatures vivent dans le monde : posées en global, le portail porté ne les traîne pas.
	fx._crawlers.top_level = true
	fx._crawlers.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fx._crawlers.global_transform = Transform3D.IDENTITY
	fx._crawlers.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, gate)
	fx._show()
	return fx


func _part(mesh: Mesh, m: Material, size: Vector3, lift: float) -> void:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = m
	node.scale = size
	node.position = Vector3.UP * lift
	_body.add_child(node)


## Une créature crachée : une bouffée de gaz au bord du puits.
func spit() -> void:
	RotBlastFx.puffs(self, _nature, 10.0 * _size, 1.0, SPIT_PUFFS)


## Les créatures à cet instant : où elles sont, leur taille en part de `CRAWLER`, leur cap.
func crawl(at: Array[Vector3], sizes: Array[float], heads: Array[Vector3]) -> void:
	var mm := _crawlers.multimesh
	mm.visible_instance_count = mini(at.size(), MOST)
	for i in mm.visible_instance_count:
		var r := CRAWLER * sizes[i]
		# Elle respire : un battement par créature, décalé.
		var breath := 1.0 + 0.08 * sin(_clock * 6.0 + float(i) * 1.7)
		var b := Basis(Vector3.UP, -Flat.angle(heads[i]) + PI * 0.5) * Basis.from_scale(Vector3(r, r * 0.8 * breath, r))
		mm.set_instance_transform(i, Transform3D(b, at[i] + Vector3.UP * r * 0.7))
		mm.set_instance_custom_data(i, Color(float(i) * 0.37, 0.0, 0.0, 0.0))


func _process(delta: float) -> void:
	_clock += delta
	_show()


## Elle sort du sol, respire, et y rentre en se refermant.
func _show() -> void:
	var opened := ease(clampf(_clock / OPEN, 0.0, 1.0), 0.35)
	var closing := clampf((_clock - (_life - CLOSE)) / CLOSE, 0.0, 1.0)
	var breath := 1.0 + 0.06 * sin(_clock * 5.0)
	_body.scale = Vector3(breath, 1.0, breath) * maxf(opened * (1.0 - ease(closing, 2.0)), 0.001) * _size


## Une créature, sa taille en part de `CRAWLER` : sa sorte (`RottingGate.Crawler`) et son attente.
static func size_of(small: bool, last: bool, big: bool, waited: float) -> float:
	var k := BIG if big else (LAST if last else SMALL) if small else 1.0
	return k * (1.0 + SWELL * minf(waited, SkillStats.GESTATION_MOST))


static func pit_material(nature: int) -> ShaderMaterial:
	if not _pits.has(nature):
		var m := ShaderMaterial.new()
		m.shader = preload("res://fx/rot_pit.gdshader")
		m.set_shader_parameter(&"gas", RotBlastFx.GAS)
		var ramp := FlameFx.ramp(nature)
		m.set_shader_parameter(&"tint", Vector3(ramp[2].r, ramp[2].g, ramp[2].b))
		m.set_shader_parameter(&"deep", Vector3(ramp[3].r, ramp[3].g, ramp[3].b))
		m.set_shader_parameter(&"sick", Vector3(RotBlastFx.SICK.r, RotBlastFx.SICK.g, RotBlastFx.SICK.b))
		_pits[nature] = m
	return _pits[nature]


## La chair des lèvres et du sac : celle des créatures, sans yeux, plus bosselée.
static func flesh_material() -> ShaderMaterial:
	if _flesh == null:
		_flesh = crawler_material().duplicate()
		_flesh.set_shader_parameter(&"eyed", false)
		_flesh.set_shader_parameter(&"bumps", 2.0)
	return _flesh


static func crawler_material() -> ShaderMaterial:
	if _crawler_material == null:
		_crawler_material = ShaderMaterial.new()
		_crawler_material.shader = preload("res://fx/crawler.gdshader")
		_crawler_material.set_shader_parameter(&"skin", SKIN)
	return _crawler_material


static func torus() -> TorusMesh:
	if _torus == null:
		_torus = TorusMesh.new()
		_torus.inner_radius = 0.42
		_torus.outer_radius = 1.0
		_torus.rings = 48
		_torus.ring_segments = 12
	return _torus


static func blob() -> SphereMesh:
	if _blob == null:
		_blob = SphereMesh.new()
		_blob.radius = 1.0
		_blob.height = 2.0
		_blob.radial_segments = 16
		_blob.rings = 8
	return _blob


static func plane() -> PlaneMesh:
	if _plane == null:
		_plane = PlaneMesh.new()
		_plane.size = Vector2(2.0, 2.0)
	return _plane
