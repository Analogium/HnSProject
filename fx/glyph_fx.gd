class_name GlyphFx
extends Node3D

## Les Glyphes en 3D (jalon 54, à la barre de Last Epoch) : le cercle runique de la 2D, un tirage de
## Qwen-Image tracé en lumière (`fx/witch_sigil.gdshaderinc`) couché au rayon qui se déclenche. Il monte
## comme une encre le temps de s'armer, terne ; armé, il s'allume, tourne et porte une lumière au sol ; il
## éclate en s'ouvrant et se ronge, sous le souffle de son élément (`Explosion.paint()`). Le Sceau porte
## trois logements, un par élément, qui s'allument aux sorts versés. Les fils de l'Entrelacs et le
## triangle : `thread()`, `weave()`.
##
## Il vit sur le calque du sol, à côté de son glyphe : le glyphe éclaté part aussitôt, son dessin s'ouvre
## encore `BURST` secondes ; effacé sans éclat, il s'éteint en `OUT`.

const SIGIL := preload("res://fx/witch_sigil.gdshader")
const SIGIL_ICE := preload("res://fx/witch_sigil_ice.gdshader")
const THREAD := preload("res://fx/witch_thread.gdshader")
const GLYPH := preload("res://fx/witch_glyph.png")
## Le Sceau : un second tirage, trois logements vides aux coins de son triangle, sur son anneau.
const SEAL := preload("res://fx/witch_seal.png")
const BAND := preload("res://fx/witch_thread.png")
## Terne tant qu'il n'est pas armé ; armé, il tourne lentement — sauf le Sceau, dont les logements sont
## posés sur le tirage.
const DIM := 0.45
const SPIN := 0.35
const BURST := 0.4
const BURST_GROW := 0.4
const OUT := 0.25
const LIGHT := 1.6
## Les logements du Sceau : leur taille, et leur centre sur le tirage en part de son rayon (x, z), mesurés
## (cercles de Hough) : Qwen ne les a pas posés en triangle équilatéral, et à ±30° les mini-glyphes
## débordaient des logements du bas.
const SOCKET := 0.12
const SOCKETS: Array[Vector2] = [Vector2(0.0, -0.686), Vector2(-0.5625, 0.414), Vector2(0.5625, 0.414)]
## Un fil ou le triangle frappe : il s'allume puis se ronge en `WOVEN` secondes.
const WOVEN := 0.6
const THREAD_WIDTH := 7.0

static var _sigils := {}
static var _threads: ShaderMaterial
static var _weaves: ShaderMaterial

var _host: Node3D
var _nature := DamageType.Kind.FIRE
var _arming := 0.0
var _clock := 0.0
var _burst_at := -1.0
var _out_at := -1.0
var sigil: MeshInstance3D
var _light: OmniLight3D
## Les logements du Sceau, par élément, et ceux qui sont versés ; vides hors Sceau.
var sockets := {}
var _poured := {}


## Le dessin de `glyph`, à la nature de son lancer et au rayon qui le déclenche, armé en `arming`
## secondes. `sealed` : le Sceau et ses logements.
static func trace(glyph: Node3D, nature: int, size: float, arming: float, sealed := false) -> GlyphFx:
	var fx := GlyphFx.new()
	fx._host = glyph
	fx._nature = nature
	fx._arming = arming
	glyph.get_parent().add_child(fx)
	fx.global_position = glyph.global_position
	fx.rotation.y = randf() * TAU
	fx.sigil = IceNovaFx.flat(fx, material(nature, SEAL if sealed else GLYPH), size, DangerZone.LIFT + 0.4)
	if sealed:
		for i in DamageType.ELEMENTS.size():
			var kind: int = DamageType.ELEMENTS[i]
			var at := Vector3(SOCKETS[i].x, 0.0, SOCKETS[i].y) * size
			var socket := IceNovaFx.flat(fx, material(kind), size * SOCKET, DangerZone.LIFT + 0.5)
			socket.position += at
			fx.sockets[kind] = socket
		fx.pour(nature)
	fx._light = FlameFx.light_of(nature, 0.0, size * 2.5)
	fx._light.position = Vector3.UP * 10.0
	fx.add_child(fx._light)
	ElementFx.veil_like(fx, glyph)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, glyph)
	fx._show()
	return fx


## Un élément versé au Sceau : son logement s'allume.
func pour(nature: int) -> void:
	_poured[nature] = true


## L'éclat : le cercle s'ouvre et se ronge, le souffle de chaque élément (`natures`) au rayon qui frappe.
func burst(natures: Array[int], reach: float) -> void:
	if _burst_at >= 0.0:
		return
	_burst_at = _clock
	for nature in natures:
		Explosion.paint(self, global_position, nature, reach, DamageType.COLORS[nature], nature == DamageType.Kind.FIRE)


func _process(delta: float) -> void:
	_clock += delta
	if _burst_at < 0.0 and _out_at < 0.0 and not (is_instance_valid(_host) and _host.is_inside_tree()):
		_out_at = _clock
	_show()
	if (_burst_at >= 0.0 and _clock - _burst_at >= BURST) or (_out_at >= 0.0 and _clock - _out_at >= OUT):
		queue_free()


func _show() -> void:
	var armed := clampf(_clock / maxf(_arming, 0.001), 0.0, 1.0)
	var lit := DIM + (1.0 - DIM) * smoothstep(0.9, 1.0, armed)
	var gone := 0.0
	var flash := 0.0
	if _burst_at >= 0.0:
		var t := (_clock - _burst_at) / BURST
		gone = ease(t, 0.6)
		flash = 1.0 - t
		scale = Vector3.ONE * (1.0 + BURST_GROW * ease(t, 0.4))
	elif _out_at >= 0.0:
		gone = (_clock - _out_at) / OUT
	sigil.set_instance_shader_parameter(&"glow", lit + flash * 1.5)
	sigil.set_instance_shader_parameter(&"dissolve", maxf(gone, 1.0 - ease(armed, 0.5)))
	sigil.set_instance_shader_parameter(&"clock", _clock)
	if armed >= 1.0 and _burst_at < 0.0 and sockets.is_empty():
		sigil.rotation.y = (_clock - _arming) * SPIN
	for kind: int in sockets:
		var socket: MeshInstance3D = sockets[kind]
		socket.rotation.y = -_clock * SPIN * 2.0
		socket.set_instance_shader_parameter(&"glow", (2.6 if _poured.has(kind) else 0.25) * lit + flash)
		socket.set_instance_shader_parameter(&"dissolve", gone)
	_light.light_energy = LIGHT * (lit - DIM) / (1.0 - DIM) * (1.0 - gone) + flash * LIGHT * 2.0


## Un fil de l'Entrelacs ou un bord du triangle, de `a` à `b`, sur `layer` (le calque du sol), qui s'allume
## puis se ronge ; la rampe de `from` passe à celle de `to`.
static func thread(layer: Node, a: Vector3, b: Vector3, from: int, to: int, veiled_like: Node) -> MeshInstance3D:
	if _threads == null:
		_threads = ShaderMaterial.new()
		_threads.shader = THREAD
		_threads.set_shader_parameter(&"band", BAND)
	var node := MeshInstance3D.new()
	node.mesh = IceSpikesFx.plane()
	node.material_override = _threads
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layer.add_child(node)
	var span := Flat.xz(b - a).length()
	node.global_position = (a + b) * 0.5 + Vector3.UP * (DangerZone.LIFT + 0.6)
	node.rotation.y = -Flat.angle(b - a)
	node.scale = Vector3(span * 0.5, 1.0, THREAD_WIDTH * 0.5)
	var ends := [FlameFx.ramp(from), FlameFx.ramp(to)]
	for i in 2:
		var side := "from_" if i == 0 else "to_"
		node.set_instance_shader_parameter(StringName(side + "heart"), _rgb(ends[i][0]))
		node.set_instance_shader_parameter(StringName(side + "tint"), _rgb(ends[i][1]))
	node.set_instance_shader_parameter(&"span", span)
	_fade(node, veiled_like)
	return node


## Le triangle des trois glyphes, `corners` dans l'ordre de `natures`, qui s'allume et se ronge sous ses
## trois bords.
static func weave(layer: Node, corners: Array[Vector3], natures: Array[int], veiled_like: Node) -> MeshInstance3D:
	if _weaves == null:
		_weaves = ShaderMaterial.new()
		_weaves.shader = THREAD
		_weaves.set_shader_parameter(&"fill", true)
	var middle := (corners[0] + corners[1] + corners[2]) / 3.0
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in 3:
		st.set_color(FlameFx.ramp(natures[i])[1])
		st.set_uv(Vector2(corners[i].x, corners[i].z) / 64.0)
		st.add_vertex(corners[i] - middle)
	var node := MeshInstance3D.new()
	node.mesh = st.commit()
	node.material_override = _weaves
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layer.add_child(node)
	node.global_position = middle + Vector3.UP * (DangerZone.LIFT + 0.3)
	node.set_instance_shader_parameter(&"span", 64.0)
	_fade(node, veiled_like)
	for i in 3:
		thread(layer, corners[i], corners[(i + 1) % 3], natures[i], natures[(i + 1) % 3], veiled_like)
	return node


## Allumé, puis rongé en `WOVEN` secondes et libéré.
static func _fade(node: MeshInstance3D, veiled_like: Node) -> void:
	ElementFx.veil_like(node, veiled_like)
	var tween := node.create_tween()
	tween.tween_method(func(t: float) -> void:
		node.set_instance_shader_parameter(&"life", ease(t, 1.6))
		node.set_instance_shader_parameter(&"clock", t * WOVEN), 0.0, 1.0, WOVEN)
	tween.tween_callback(node.queue_free)


static func _rgb(c: Color) -> Vector3:
	return Vector3(c.r, c.g, c.b)


## Une matière par nature, gardée.
static func material(nature: int, photo: Texture2D = GLYPH) -> ShaderMaterial:
	var key := "%s@%d" % [photo.resource_path, nature]
	if not _sigils.has(key):
		var m := ShaderMaterial.new()
		m.shader = SIGIL_ICE if nature == DamageType.Kind.COLD else SIGIL
		m.set_shader_parameter(&"atlas", photo)
		IceSpikesFx._ramp_into(m, nature)
		_sigils[key] = m
	return _sigils[key]
