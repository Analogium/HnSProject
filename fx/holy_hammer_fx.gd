class_name HolyHammerFx
extends Node3D

## Le Marteau béni en 3D (jalon 54, à la barre de Last Epoch) : le marteau de guerre de la 2D, tête claire et
## manche sombre, en fer béni qui luit (`fx/holy_hammer.gdshader`), couché tête vers le dehors de la spirale,
## qui tourne sur lui-même ; sa traînée de lumière (celle de `BoltFx`, sur la bande du souffle sacré) et la
## lumière qu'il porte au sol. Un coup jette des grains d'or sur ce qu'il frappe.
##
## Il vit sur son marteau, qui le libère avec lui ; sa traînée retombe seule.

const SHADER := preload("res://fx/holy_hammer.gdshader")
## En radians par seconde, autour de la verticale, comme en 2D.
const TUMBLE := 8.0
## Taillé au coup qu'il porte (`HAMMER_BITE`, 8 px), il sortait en point blanc.
const SCALE := 1.3
## Aussi large que celle de l'éclair, la traînée couvrait le marteau.
const TRAIL := 0.55
## Penché vers la caméra, autour de son manche.
const TILT := 0.5
const LIGHT := 2.5
const LIGHT_REACH := 30.0
const BLOW_SPARKS := 7
## Une gerbe au plus par intervalle : jetée à chaque ennemi croisé, elle coûtait 1,5 ms l'image contre 300 grunts.
const BLOW_GAP := 0.15

static var _mesh: ArrayMesh
static var _materials := {}
static var _links := {}
static var _trails := {}

var _hammer: BlessedHammer
var _nature := DamageType.Kind.HOLY
var _body: MeshInstance3D
var _light: OmniLight3D
var _clock := 0.0
var _blown := -INF
var _size := 1.0
var trail: BoltFx.Trail


## Le marteau de `hammer`, à la nature de son lancer ; `size` : sa taille en part d'un marteau commun (le
## bourdon, le petit du Tocsin) ; `orbited` : le lanceur autour duquel il tourne (la Gravitation), où se
## pose sa traînée.
static func show_on(hammer: BlessedHammer, nature: int, size: float, orbited: Node3D = null) -> HolyHammerFx:
	var fx := HolyHammerFx.new()
	fx._hammer = hammer
	fx._nature = nature
	fx._size = size * SCALE
	hammer.add_child(fx)
	fx.position = Vector3.UP * ElementFx.LIFT
	fx._body = MeshInstance3D.new()
	fx._body.mesh = mesh()
	fx._body.material_override = material(nature)
	fx._body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Il tourne à l'image : hors interpolation, il suit son marteau, qui l'est.
	fx._body.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	fx.add_child(fx._body)
	fx._light = FlameFx.light_of(nature, LIGHT, LIGHT_REACH * size)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx.add_child(fx._light)
	fx.trail = BoltFx.Trail.new()
	fx.trail.material_override = trail_material(nature)
	fx.trail.target = fx
	fx.trail.frame = orbited
	fx.trail.width = BoltFx.TRAIL_WIDTH * TRAIL * size
	hammer.get_viewport().add_child(fx.trail)
	for node in [fx._body, fx.trail]:
		ElementFx.veil_like(node, hammer)
	fx._turn()
	return fx


## Le coup sur `at` : des grains d'or.
func blow(at: Vector3) -> void:
	if _clock - _blown < BLOW_GAP:
		return
	_blown = _clock
	Sparks.burst(_hammer, at, _nature, BLOW_SPARKS, 4.0, Vector2(0.15, 0.35), Vector2(4.0, 9.0))


func _process(delta: float) -> void:
	_clock += delta
	_turn()


## Tête vers le dehors de la spirale au départ, puis il tourne.
func _turn() -> void:
	var out := Flat.angle(_hammer.get_global_transform_interpolated().origin - _hammer.center())
	_body.basis = Basis(Vector3.UP, -(out + _clock * TUMBLE)) * Basis(Vector3.RIGHT, TILT) \
			* Basis(Vector3.FORWARD, PI * 0.5) * Basis.from_scale(Vector3.ONE * _size)
	_body.set_instance_shader_parameter(&"clock", _clock)


## Une tête et un manche, le long de +y, la tête au bout : un maillage pour tous.
static func mesh() -> ArrayMesh:
	if _mesh != null:
		return _mesh
	var tool := SurfaceTool.new()
	var handle := CylinderMesh.new()
	handle.top_radius = 0.7
	handle.bottom_radius = 0.9
	handle.height = 9.0
	handle.radial_segments = 10
	tool.append_from(handle, 0, Transform3D(Basis(), Vector3.UP * -0.5))
	var head := BoxMesh.new()
	head.size = Vector3(9.0, 4.0, 4.4)
	tool.append_from(head, 0, Transform3D(Basis(), Vector3.UP * 5.8))
	tool.generate_normals()
	_mesh = tool.commit()
	return _mesh


static func material(nature: int) -> ShaderMaterial:
	if not _materials.has(nature):
		_materials[nature] = HolyBlastFx.ramped(SHADER, HolyBlastFx.WAVE, nature)
	return _materials[nature]


## Un maillon est tout en tête.
static func link_material(nature: int) -> ShaderMaterial:
	if not _links.has(nature):
		_links[nature] = material(nature).duplicate()
		_links[nature].set_shader_parameter(&"head", -1000.0)
	return _links[nature]


## La traînée de `BoltFx` sur la bande de lumière du souffle sacré.
static func trail_material(nature: int) -> ShaderMaterial:
	if not _trails.has(nature):
		_trails[nature] = HolyBlastFx.ramped(BoltFx.TRAIL, HolyBlastFx.WAVE, nature)
	return _trails[nature]
