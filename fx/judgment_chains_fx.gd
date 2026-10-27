class_name JudgmentChainsFx
extends MultiMeshInstance3D

## Les Chaînes du jugement en 3D (jalon 54, à la barre de Last Epoch) : les maillons de la 2D, un anneau de
## face et un de chant en alternance, posés un à un de l'ancre à chaque enchaîné, en fer béni qui luit
## (`fx/holy_hammer.gdshader`, la matière du marteau, toute en tête). Le trait qui vole est l'anneau de tête et quelques
## maillons derrière lui ; chaque prise jette des étincelles d'or.
##
## Il vit à la racine du viewport et relit ses chaînes à chaque image ; parties, les maillons s'effacent
## en `OUT` secondes, là où ils étaient.

## L'écart entre deux maillons, leur demi-longueur, demi-largeur et épaisseur, en pixels.
const PITCH := 4.4
const LINK := Vector3(3.0, 1.0, 1.8)
const HEAD := 1.6
## Les maillons derrière le trait qui vole.
const TAIL := 6
## À mi-hauteur d'un corps, et ce que pend une chaîne de 90 px.
const HEIGHT := 9.0
const SAG := 0.04
const OUT := 0.3
const CATCH_SPARKS := 8

static var _ring: TorusMesh

var _chains: JudgmentChains
var _nature := DamageType.Kind.HOLY
var _clock := 0.0
var _out_at := -1.0
## Ceux déjà pris, pour ne jeter leurs étincelles qu'une fois.
var _caught := {}
var _links: Array[Transform3D] = []


static func bind(chains: JudgmentChains, nature: int) -> JudgmentChainsFx:
	var fx := JudgmentChainsFx.new()
	fx._chains = chains
	fx._nature = nature
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _torus()
	fx.multimesh = mm
	fx.material_override = HolyHammerFx.link_material(nature)
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	chains.get_viewport().add_child(fx)
	ElementFx.veil_like(fx, chains)
	fx._show()
	return fx


func _process(delta: float) -> void:
	_clock += delta
	if _out_at < 0.0 and not (is_instance_valid(_chains) and _chains.is_inside_tree()):
		_out_at = _clock
	_show()
	if _out_at >= 0.0 and _clock - _out_at >= OUT:
		queue_free()


func _show() -> void:
	if _out_at < 0.0:
		_links.clear()
		if _chains.flying():
			_lay_flight()
		else:
			_lay_bonds()
		var mm := multimesh
		if mm.instance_count < _links.size():
			mm.instance_count = _links.size() + 8
		mm.visible_instance_count = _links.size()
		for i in _links.size():
			mm.set_instance_transform(i, _links[i])
	set_instance_shader_parameter(&"clock", _clock)
	var out := clampf((_clock - _out_at) / OUT, 0.0, 1.0) if _out_at >= 0.0 else 0.0
	set_instance_shader_parameter(&"opacity", Settings.veil_of(self) * (1.0 - out))


## Le trait qui vole : l'anneau de tête, puis la chaîne qui le suit.
func _lay_flight() -> void:
	var at := _chains.get_global_transform_interpolated().origin + Vector3.UP * HEIGHT
	var back := -_chains.heading()
	_links.append(_link(at, back, 0, HEAD))
	for i in TAIL:
		_links.append(_link(at + back * PITCH * (float(i) + 1.4), back, i + 1, 1.0))


## Une chaîne de l'ancre à chaque enchaîné, qui pend un peu ; ceux qui viennent d'être pris jettent leurs
## étincelles.
func _lay_bonds() -> void:
	var anchor := _chains.anchor()
	if not is_instance_valid(anchor):
		return
	var from := anchor.get_global_transform_interpolated().origin + Vector3.UP * HEIGHT
	for member in _chains.members():
		if not is_instance_valid(member):
			continue
		var to := member.get_global_transform_interpolated().origin + Vector3.UP * HEIGHT
		var id := member.get_instance_id()
		if not _caught.has(id):
			_caught[id] = true
			Sparks.burst(_chains, to - Vector3.UP * HEIGHT, _nature, CATCH_SPARKS, 5.0, Vector2(0.15, 0.4), Vector2(4.0, 10.0))
		if member == anchor:
			continue
		var span := from.distance_to(to)
		var count := maxi(int(span / PITCH), 1)
		var along := (to - from) / span if span > 0.01 else Vector3.RIGHT
		for k in count:
			var t := (float(k) + 0.5) / float(count)
			var p := from.lerp(to, t) + Vector3.DOWN * span * SAG * 4.0 * t * (1.0 - t)
			_links.append(_link(p, along, k, 1.0))


## Un maillon couché le long de `along`, de chant un sur deux.
func _link(at: Vector3, along: Vector3, index: int, size: float) -> Transform3D:
	var side := along.cross(Vector3.UP).normalized() if absf(along.y) < 0.99 else Vector3.FORWARD
	var up := side.cross(along)
	var basis := Basis(along, up, side)
	if index % 2 == 1:
		basis = basis * Basis(Vector3.RIGHT, PI * 0.5)
	return Transform3D(basis * Basis.from_scale(LINK * size), at)


## Un anneau dans le plan xz, d'un rayon de 1.
static func _torus() -> TorusMesh:
	if _ring == null:
		_ring = TorusMesh.new()
		_ring.inner_radius = 0.55
		_ring.outer_radius = 1.0
		_ring.rings = 12
		_ring.ring_segments = 6
	return _ring
