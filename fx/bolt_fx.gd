class_name BoltFx
extends Node3D

## Le trait de foudre en 3D (jalon 54), façon Kinetic Bolt de Path of Exile, électrique : « dents de
## scie » choisi sur une troisième planche, contre l'équerre, la ligne droite et un gros orbe (avant,
## des arcs photographiés étirés « ne ressemblaient pas à un éclair », puis un zigzag couché derrière
## le tir a été écarté pour cette référence). Un orbe de plasma qui file en zigzag **autour** de la
## vraie trajectoire, droite — le dessin s'en écarte, le coup non —, trois arcs qui crépitent autour,
## une longue traînée qui garde la forme du zigzag et survit au tir ; à sa fin, un éclat.
## **Le Trait de glace** (le trait passé au froid, « Kinetic de glace » choisi sur planche contre un
## javelot de cristal, un éclat photographié, un orbe dans la brume et une salve) : le même geste, un
## orbe de glace sans arcs, une traînée de givre, un éclatement ; mêlés au sol, pas additionnés.
## **En feu** (le Familier, « Kinetic de feu ») : la boule de `FlameFx`, une traînée de flammes. **Les
## Esquilles** : le trait en petit. **L'Orbe statique** (« boule de plasma ») : un gros orbe aux arcs,
## qui file droit et décharge en arcs ; **le Satellite** lui ajoute la traînée (« sillage »).

const ARC := preload("res://fx/lightning_bolt.gdshader")
const PHOTO := preload("res://fx/lightning_spark.gdshader")
const TRAIL := preload("res://fx/lightning_trail.gdshader")
const BOLT_PHOTO := preload("res://fx/lightning_bolt.png")
const SPARK_PHOTO := preload("res://fx/lightning_spark.png")
const ORB_PHOTO := preload("res://fx/lightning_orb.png")
const FROST := preload("res://fx/frost_photo.gdshader")
const FROST_TRAIL := preload("res://fx/frost_trail.gdshader")
const FROST_ORB := preload("res://fx/frost_orb.png")
const FROST_STREAK := preload("res://fx/frost_streak.png")
const FROST_BURST := preload("res://fx/frost_burst.png")
const FIRE_BALL := preload("res://fx/fire_ball.png")
const FIRE_BLAST := preload("res://fx/fire_blast.png")
const FIRE_STREAK := preload("res://fx/fire_streak.png")
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
## Un éclat des Esquilles : le trait en petit (« mini Kinetic » choisi sur planche).
const SHARD := 0.55
## Une décharge de l'Orbe statique : l'arc jusqu'à sa cible, et l'éclat qu'il y laisse.
const ZAP_WIDTH := 7.0
const ZAP_LIFE := 0.14
const ZAP_FLASH := 12.0
const ZAP_FLASH_LIFE := 0.2

static var _arc_draw := {}
static var _photos := {}
static var _trails := {}

var trail: Trail
var _orb: Node3D
var _nature := 0
var _look: Look
## Les deux dernières positions du tir au pas de physique, et celle de l'image d'avant.
var _before := Vector3.ZERO
var _after := Vector3.ZERO
var _last := Vector3.ZERO
var _dir := Vector3.RIGHT
var _run := 0.0


## Le trait de `host`, qui le porte ; sa traînée vit à la racine du viewport et lui survit. L'Orbe
## statique (`orb`) a le gros orbe qui ne zigzague pas, et pas de traînée hors du Satellite.
static func show_on(host: Node3D, nature: int, orb := false, orbits := false) -> BoltFx:
	var fx := BoltFx.new()
	fx._nature = nature
	fx._look = Look.of(nature, orb)
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
	var look := fx._look
	var shown: Array[GeometryInstance3D] = [_photo_quad(nature, look.orb, look.cell, look.size, look.spin)]
	if look.spark:
		shown.append(_photo_quad(nature, SPARK_PHOTO, Look.WHOLE, SPARK, -6.0))
	for i in look.arcs:
		var arc := _arc(nature, look.arc)
		arc.rotation.y = TAU * float(i) / float(look.arcs)
		shown.append(arc)
	for node in shown:
		fx._orb.add_child(node)
	fx._orb.add_child(FlameFx.light_of(nature, LIGHT, REACH))
	if not orb or orbits:
		fx.trail = Trail.new()
		fx.trail.material_override = _trail_material(nature)
		fx.trail.target = fx._orb
		host.get_viewport().add_child(fx.trail)
		shown.append(fx.trail)
	for node in shown:
		ElementFx.veil_like(node, host)
	return fx


## Un éclat des Esquilles : tout en petit, traînée comprise.
func shrink() -> void:
	scale = Vector3.ONE * SHARD
	trail.width = TRAIL_WIDTH * SHARD


## L'éclat de fin de course, sur l'orbe. **Différé** : la fin arrive souvent d'un rappel de collision.
func flare() -> void:
	_flare.call_deferred(get_viewport(), _orb.global_position, get_parent(), scale.x)


## Une décharge de l'Orbe statique : un arc de l'orbe à chaque cible, `Lightning.ARCS_MOST` au plus,
## qui s'y éteint sur un éclat.
func zap(targets: Array) -> void:
	var from := _orb.global_position
	for target: Node3D in targets.slice(0, Lightning.ARCS_MOST):
		var to := target.global_position + Vector3.UP * ElementFx.LIFT * 0.5
		var arc := _arc(_nature, Vector2(from.distance_to(to), ZAP_WIDTH))
		arc.top_level = true
		add_child(arc)
		arc.global_position = to
		arc.rotation.y = -Flat.angle(to - from)
		var flash := flash_of(_nature)
		get_viewport().add_child(flash)
		flash.global_position = to
		for node: GeometryInstance3D in [arc, flash]:
			ElementFx.veil_like(node, get_parent())
		_fade(arc, Vector3(arc.scale.x, ZAP_WIDTH, 1.0), ZAP_LIFE)
		_fade(flash, Vector3.ONE * ZAP_FLASH, ZAP_FLASH_LIFE)


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
	var tooth := (absf(fposmod(_run / (STEP * 2.0) + 0.25, 1.0) * 2.0 - 1.0) * 2.0 - 1.0) * _look.amp
	_orb.position = Vector3(-_dir.z, 0.0, _dir.x) * tooth
	_orb.rotation.y += delta * ARC_SPIN


func _flare(viewport: Viewport, at: Vector3, host: Node, size: float) -> void:
	if not is_instance_valid(viewport):
		return
	var flash := flash_of(_nature)
	viewport.add_child(flash)
	if is_instance_valid(host):
		ElementFx.veil_like(flash, host)
	flash.global_position = at
	_fade(flash, Vector3.ONE * FLARE * size, FLARE_LIFE)


## Grandit jusqu'à `to` en s'éteignant, puis se libère.
static func _fade(node: GeometryInstance3D, to: Vector3, life: float) -> void:
	var tween := node.create_tween().set_parallel()
	tween.tween_property(node, "scale", to, life)
	tween.tween_method(
		func(o: float) -> void: node.set_instance_shader_parameter(&"opacity", o), 1.0, 0.0, life
	)
	tween.chain().tween_callback(node.queue_free)


## L'éclat de fin de course, petit : `_flare()` le grandit. Public pour `ElementFx.warm()`.
static func flash_of(nature: int) -> MeshInstance3D:
	var look := Look.of(nature, false)
	return _photo_quad(nature, look.flash, look.flash_cell, 4.0, 0.0)


static func _photo_quad(nature: int, photo: Texture2D, cell: Vector4, size: float, spin: float) -> MeshInstance3D:
	var key := "%d %s %s %s" % [nature, photo.resource_path, cell, spin]
	if not _photos.has(key):
		var m := _ramped(FROST if nature == DamageType.Kind.COLD else PHOTO, photo, nature)
		m.set_shader_parameter(&"spin", spin)
		if cell != Look.WHOLE:
			m.set_shader_parameter(&"cell", cell)
		if nature == DamageType.Kind.FIRE:
			m.set_shader_parameter(&"boost", 0.55)
		var quad := QuadMesh.new()
		quad.material = m
		_photos[key] = quad
	var node := MeshInstance3D.new()
	node.mesh = _photos[key]
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.scale = Vector3.ONE * size
	return node


## Un arc qui crépite, couché de x = −`size.x` à 0 : les coudes sortent du quad, que le moteur
## jugerait hors champ trop tôt.
static func _arc(nature: int, size: Vector2) -> MeshInstance3D:
	var arc := MeshInstance3D.new()
	arc.mesh = _arc_mesh(nature)
	arc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	arc.scale = Vector3(size.x, size.y, 1.0)
	arc.extra_cull_margin = maxf(size.x, size.y)
	arc.set_instance_shader_parameter(&"seed", randf() * 100.0)
	return arc


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
		var look := Look.of(nature, false)
		var m := _ramped(FROST_TRAIL if nature == DamageType.Kind.COLD else TRAIL, look.streak, nature)
		if nature == DamageType.Kind.FIRE:
			# La photo d'une comète, tête à droite : la traînée n'en prend que le corps.
			m.set_shader_parameter(&"along", 0.65)
			m.set_shader_parameter(&"boost", 0.9)
		_trails[nature] = m
	return _trails[nature]


static func _ramped(shader: Shader, photo: Texture2D, nature: int) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = shader
	m.set_shader_parameter(&"photo", photo)
	var ramp := FlameFx.ramp(nature)
	for i in 3:
		var c: Color = ramp[i]
		m.set_shader_parameter([&"heart", &"tint", &"deep"][i], Vector3(c.r, c.g, c.b))
	if nature == DamageType.Kind.FIRE:
		# Le cœur blanc de la foudre, sur du feu, sortait bleuté.
		m.set_shader_parameter(&"core", Vector3(1.0, 0.85, 0.45))
	return m


## Ce que montre une nature. La foudre crépite (son orbe, une étincelle, des arcs) ; la glace s'ombre,
## mêlée au sol (additionné à l'ocre, son cyan sortait blanc) ; le feu porte la boule de `FlameFx`.
## L'Orbe statique (`orb`) a le gros orbe aux arcs, qui ne zigzague pas.
class Look:
	const WHOLE := Vector4(0.0, 0.0, 1.0, 1.0)
	var orb: Texture2D = ORB_PHOTO
	## La case de la photo, dans un atlas.
	var cell := WHOLE
	var size := ORB
	var spin := 4.0
	var spark := true
	var arcs := ARCS
	var arc := Vector2(ARC_LENGTH, ARC_WIDTH)
	var amp := AMP
	var streak: Texture2D = BOLT_PHOTO
	var flash: Texture2D = SPARK_PHOTO
	var flash_cell := WHOLE

	static func of(nature: int, orb_shape: bool) -> Look:
		var look := Look.new()
		if orb_shape:
			look.size = 16.0
			look.spin = 3.0
			look.spark = false
			look.arc = Vector2(12.0, 6.0)
			look.amp = 0.0
		elif nature == DamageType.Kind.COLD:
			look.orb = FROST_ORB
			look.size = 10.0
			look.spin = 2.0
			look.spark = false
			look.arcs = 0
			look.streak = FROST_STREAK
			look.flash = FROST_BURST
		elif nature == DamageType.Kind.FIRE:
			look.orb = FIRE_BALL
			look.cell = Vector4(0.0, 0.0, 1.0 / 3.0, 1.0)
			look.size = 11.0
			look.spin = 3.0
			look.spark = false
			look.arcs = 0
			look.streak = FIRE_STREAK
			look.flash = FIRE_BLAST
			look.flash_cell = Vector4(0.0, 0.0, 0.5, 1.0)
		return look


## La traînée : les positions passées de sa cible, chacune avec son âge, en ruban tourné vers la
## caméra. Sa cible partie, elle finit de s'éteindre puis se libère.
class Trail extends MeshInstance3D:
	var target: Node3D
	var width := TRAIL_WIDTH
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
			var side := dir.cross(eye).normalized() * width * (0.6 + 0.4 * life)
			for edge in [-1.0, 1.0]:
				_strip.surface_set_color(Color(1.0, 1.0, 1.0, life))
				_strip.surface_set_uv(Vector2(along / 70.0, 0.5 + edge * 0.5))
				_strip.surface_add_vertex(p + side * edge)
		_strip.surface_end()
