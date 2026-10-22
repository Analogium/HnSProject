class_name BoltFx
extends Node3D

## Le trait de foudre en 3D (jalon 54), façon Kinetic Bolt de Path of Exile, électrique : « dents de
## scie » choisi sur une troisième planche, contre l'équerre, la ligne droite et un gros orbe (avant,
## des arcs photographiés étirés « ne ressemblaient pas à un éclair », puis un zigzag couché derrière
## le tir a été écarté pour cette référence). Un orbe de plasma qui file en zigzag **autour** de la
## vraie trajectoire, droite — le dessin s'en écarte, le coup non —, trois arcs qui crépitent autour,
## une longue traînée qui garde la forme du zigzag et survit au tir ; à sa fin, un éclat.

const ARC := preload("res://fx/lightning_bolt.gdshader")
const PHOTO := preload("res://fx/lightning_spark.gdshader")
const TRAIL := preload("res://fx/lightning_trail.gdshader")
const BOLT_PHOTO := preload("res://fx/lightning_bolt.png")
const SPARK_PHOTO := preload("res://fx/lightning_spark.png")
const ORB_PHOTO := preload("res://fx/lightning_orb.png")
## L'écart du dessin à la trajectoire, et la longueur d'une dent, en pixels.
const AMP := 10.0
const STEP := 26.0
const ORB := 6.0
const SPARK := 10.0
const ARCS := 3
const ARC_LENGTH := 10.0
const ARC_WIDTH := 5.0
const ARC_SPIN := 11.0
const TRAIL_LIFE := 0.45
const TRAIL_WIDTH := 3.5
const LIGHT := 3.0
const REACH := 36.0
const FLARE := 20.0
const FLARE_LIFE := 0.18

static var _arc_draw := {}
static var _photos := {}
static var _trails := {}

var trail: Trail
var _orb: Node3D
var _nature := 0
## Les deux dernières positions du tir au pas de physique, et celle de l'image d'avant.
var _before := Vector3.ZERO
var _after := Vector3.ZERO
var _last := Vector3.ZERO
var _dir := Vector3.RIGHT
var _run := 0.0


## Le trait de `host`, qui le porte ; sa traînée vit à la racine du viewport et lui survit.
static func show_on(host: Node3D, nature: int) -> BoltFx:
	var fx := BoltFx.new()
	fx._nature = nature
	host.add_child(fx)
	# Posé à l'image, pas au pas de physique : sur un écran à 165 Hz, un tir à 60 pas restait
	# immobile deux images sur trois, puis sautait — l'orbe net avançait par à-coups.
	fx.top_level = true
	fx.process_physics_priority = 1
	fx._before = host.global_position
	fx._after = fx._before
	fx._last = fx._before
	fx.global_position = fx._before + Vector3.UP * ElementFx.LIFT
	fx._orb = Node3D.new()
	fx.add_child(fx._orb)
	var shown: Array[GeometryInstance3D] = [
		_photo_quad(nature, ORB_PHOTO, ORB, 4.0), _photo_quad(nature, SPARK_PHOTO, SPARK, -6.0)
	]
	for i in ARCS:
		var arc := MeshInstance3D.new()
		arc.mesh = _arc_mesh(nature)
		arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		arc.scale = Vector3(ARC_LENGTH, ARC_WIDTH, 1.0)
		arc.rotation.y = TAU * float(i) / float(ARCS)
		# Les coudes sortent du quad, que le moteur jugerait hors champ trop tôt.
		arc.extra_cull_margin = ARC_WIDTH
		arc.set_instance_shader_parameter(&"seed", randf() * 100.0)
		shown.append(arc)
	for node in shown:
		fx._orb.add_child(node)
	fx._orb.add_child(FlameFx.light_of(nature, LIGHT, REACH))
	fx.trail = Trail.new()
	fx.trail.material_override = _trail_material(nature)
	fx.trail.target = fx._orb
	host.get_viewport().add_child(fx.trail)
	shown.append(fx.trail)
	for node in shown:
		ElementFx.veil_like(node, host)
	return fx


## L'éclat de fin de course, sur l'orbe. **Différé** : la fin arrive souvent d'un rappel de collision.
func flare() -> void:
	_flare.call_deferred(get_viewport(), _orb.global_position, get_parent())


## Après le tir, qui avance dans son propre `_physics_process()` : sans la priorité, l'enfant passait
## avant lui, et le dessin traînait d'un pas.
func _physics_process(_delta: float) -> void:
	_before = _after
	_after = (get_parent() as Node3D).global_position


## Entre les deux derniers pas, à la fraction où tombe l'image. Le cap se lit sur le chemin fait
## depuis l'image d'avant : le tir ne le dit pas, et un rebond le change d'un pas à l'autre.
## L'écart suit une dent de scie le long du chemin, nul au départ.
func _process(delta: float) -> void:
	var at := _before.lerp(_after, Engine.get_physics_interpolation_fraction())
	global_position = at + Vector3.UP * ElementFx.LIFT
	var moved := at - _last
	_last = at
	if moved.length_squared() > 0.0001:
		_dir = moved.normalized()
		_run += moved.length()
	var tooth := (absf(fposmod(_run / (STEP * 2.0) + 0.25, 1.0) * 2.0 - 1.0) * 2.0 - 1.0) * AMP
	_orb.position = Vector3(-_dir.z, 0.0, _dir.x) * tooth
	_orb.rotation.y += delta * ARC_SPIN


func _flare(viewport: Viewport, at: Vector3, host: Node) -> void:
	if not is_instance_valid(viewport):
		return
	var flash := _photo_quad(_nature, SPARK_PHOTO, 4.0, 0.0)
	viewport.add_child(flash)
	if is_instance_valid(host):
		ElementFx.veil_like(flash, host)
	flash.global_position = at
	var tween := flash.create_tween().set_parallel()
	tween.tween_property(flash, "scale", Vector3.ONE * FLARE, FLARE_LIFE)
	tween.tween_method(
		func(o: float) -> void: flash.set_instance_shader_parameter(&"opacity", o), 1.0, 0.0, FLARE_LIFE
	)
	tween.chain().tween_callback(flash.queue_free)


static func _photo_quad(nature: int, photo: Texture2D, size: float, spin: float) -> MeshInstance3D:
	var key := "%d %s %s" % [nature, photo.resource_path, spin]
	if not _photos.has(key):
		var m := _ramped(PHOTO, photo, nature)
		m.set_shader_parameter(&"spin", spin)
		var quad := QuadMesh.new()
		quad.material = m
		_photos[key] = quad
	var node := MeshInstance3D.new()
	node.mesh = _photos[key]
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.scale = Vector3.ONE * size
	return node


## Un quad couché du centre de l'orbe (x = −1) à son bord (x = 0), assez découpé pour se casser.
static func _arc_mesh(nature: int) -> QuadMesh:
	if not _arc_draw.has(nature):
		var quad := QuadMesh.new()
		quad.center_offset = Vector3(-0.5, 0.0, 0.0)
		quad.subdivide_width = 24
		var m := _ramped(ARC, BOLT_PHOTO, nature)
		m.set_shader_parameter(&"kinks", 3.0)
		m.set_shader_parameter(&"boost", 1.0)
		quad.material = m
		_arc_draw[nature] = quad
	return _arc_draw[nature]


static func _trail_material(nature: int) -> ShaderMaterial:
	if not _trails.has(nature):
		_trails[nature] = _ramped(TRAIL, BOLT_PHOTO, nature)
	return _trails[nature]


static func _ramped(shader: Shader, photo: Texture2D, nature: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter(&"photo", photo)
	var ramp := FlameFx.ramp(nature)
	for i in 3:
		var c: Color = ramp[i]
		m.set_shader_parameter([&"heart", &"tint", &"deep"][i], Vector3(c.r, c.g, c.b))
	return m


## La traînée : les positions passées de sa cible, chacune avec son âge, en ruban tourné vers la
## caméra. Sa cible partie, elle finit de s'éteindre puis se libère.
class Trail extends MeshInstance3D:
	var target: Node3D
	## [position, âge en secondes], du plus vieux au plus jeune.
	var points: Array = []
	var _strip := ImmediateMesh.new()

	func _init() -> void:
		mesh = _strip
		cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	func _process(delta: float) -> void:
		for p: Array in points:
			p[1] += delta
		while not points.is_empty() and float(points[0][1]) > TRAIL_LIFE:
			points.pop_front()
		if is_instance_valid(target) and target.is_inside_tree():
			add_point(target.global_position)
		elif points.is_empty():
			queue_free()
			return
		_build()

	## Un point de plus, s'il s'est assez écarté du dernier.
	func add_point(at: Vector3) -> void:
		if points.is_empty() or (points.back()[0] as Vector3).distance_squared_to(at) > 0.25:
			points.append([at, 0.0])

	func _build() -> void:
		_strip.clear_surfaces()
		if points.size() < 2:
			return
		var camera := get_viewport().get_camera_3d()
		_strip.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
		var along := 0.0
		for i in points.size():
			var p: Vector3 = points[i][0]
			var q: Vector3 = points[maxi(i - 1, 0)][0] if i > 0 else points[1][0]
			var dir := (p - q) if i > 0 else (q - p)
			along += p.distance_to(q) if i > 0 else 0.0
			var eye := (camera.global_position - p) if camera != null else Vector3.UP
			var life := clampf(1.0 - float(points[i][1]) / TRAIL_LIFE, 0.0, 1.0)
			var side := dir.cross(eye).normalized() * TRAIL_WIDTH * (0.6 + 0.4 * life)
			for edge in [-1.0, 1.0]:
				_strip.surface_set_color(Color(1.0, 1.0, 1.0, life))
				_strip.surface_set_uv(Vector2(along / 70.0, 0.5 + edge * 0.5))
				_strip.surface_add_vertex(p + side * edge)
		_strip.surface_end()
