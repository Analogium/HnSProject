class_name StormCloudFx
extends Node3D

## Le Nuage d'orage en 3D (jalon 54, « volutes » choisi sur une deuxième planche ; la première,
## des photos plaquées sans lumière, « beaucoup trop moche ») : une quinzaine de bosses de cumulus
## photographiées, en relief sous le soleil du jeu, le ventre plus sombre, qui roulent lentement ;
## une lumière dedans qui flashe à chaque frappe ; un éclair photographié sur chaque cible. En
## grêle (« grêlons sur cible », contre une averse continue et une colonne de grêle), des billes
## de glace tombent du ventre sur chaque cible.
##
## Il vit à la racine du viewport et suit son nuage : le nuage parti, il se dissipe au lieu de
## disparaître d'un coup.

const PUFF := preload("res://fx/storm_puff.gdshader")
const BOLT := preload("res://fx/storm_bolt.gdshader")
const STONE := preload("res://fx/hail_stone.gdshader")
const PUFFS := preload("res://fx/storm_puff.png")
const BOLT_PHOTO := preload("res://fx/storm_bolt.png")
## Le nuage est dessiné pour le rayon de la compétence ; un autre rayon le met à l'échelle, pas
## sa hauteur.
const RADIUS := 34.0
const HEIGHT := 72.0
## Le ventre : neuf bosses au tour, plus bas ; le dôme : cinq plus serrées et une au sommet.
const BELLY := 9
const DOME := 5
const BELLY_SHADE := 0.55
const SPIN := 0.08
const CALM := 0.15
## Ce que l'Accumulation ajoute à la lueur du dedans, à pleines charges.
const CHARGED := 1.2
const FLASH := 2.5
const FLASH_LIFE := 0.25
const BOLT_LIFE := 0.2
## Le tronc photographié est plus haut que large ; une hauteur du monde se voit à ~0,6 de sa taille
## sous la caméra à 55°.
const BOLT_ASPECT := 0.45
const BOLT_SEEN := 0.7
const STONES := 6
const STONE_SPREAD := 8.0
const STONE_FALL := 0.12
const IMPACT := 12.0
const IMPACT_LIFE := 0.18
const DISSIPATION := 0.6

static var _puff_quad: QuadMesh
static var _stone_mesh: SphereMesh
static var _bolts := {}

## L'Accumulation : de 0 (aucune charge) à 1 (pleines charges).
var charge := 0.0:
	set(value):
		charge = value
		_calm()
var _host: Node3D
var _nature := 0
var _scale := 1.0
var _light: OmniLight3D
var _flash: Tween
var _puffs: Array[Puff] = []
var _clock := 0.0
var _gone := -1.0


## Le nuage de `host`, à son rayon.
static func gather(host: Node3D, nature: int, radius: float) -> StormCloudFx:
	var fx := StormCloudFx.new()
	fx._host = host
	fx._nature = nature
	fx._scale = radius / RADIUS
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(fx)
	fx.global_position = host.global_position
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for k in BELLY + DOME + 1:
		var puff := Puff.new()
		var at := Vector3(0.0, 11.0, 0.0)
		var size := 1.2
		if k < BELLY:
			var a := TAU * float(k) / float(BELLY) + rng.randf() * 0.3
			var d := 0.55 + rng.randf() * 0.25
			at = Vector3(cos(a) * d * RADIUS, -4.0 + rng.randf() * 3.0, sin(a) * d * RADIUS * 0.8)
			size = 0.95 + rng.randf() * 0.3
		elif k < BELLY + DOME:
			var a := TAU * float(k - BELLY) / float(DOME) + 0.5
			at = Vector3(cos(a), 0.0, sin(a)) * 0.3 * RADIUS + Vector3.UP * (5.0 + rng.randf() * 4.0)
			size = 1.0 + rng.randf() * 0.3
		puff.home = Vector3(at.x * fx._scale, HEIGHT + at.y, at.z * fx._scale)
		puff.phase = float(k) * 0.7
		puff.node = MeshInstance3D.new()
		puff.node.mesh = _puff_mesh()
		puff.node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		puff.size = size * RADIUS * fx._scale
		puff.node.scale = Vector3.ONE * puff.size
		puff.node.extra_cull_margin = RADIUS
		puff.node.set_instance_shader_parameter(&"cell", float(k % 3))
		puff.node.set_instance_shader_parameter(&"turn", float(k) * 1.9)
		puff.node.set_instance_shader_parameter(&"shade", BELLY_SHADE if k < BELLY else 1.0)
		fx.add_child(puff.node)
		ElementFx.veil_like(puff.node, host)
		fx._puffs.append(puff)
	fx._light = FlameFx.light_of(nature, CALM, RADIUS * fx._scale * 3.0)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * (HEIGHT - 8.0)
	fx.add_child(fx._light)
	fx._roll(0.0)
	return fx


## Une frappe sur ces points (les cibles, ou un point du cercle quand elle tombe à vide) : un éclair
## ou des grêlons sur chacun, l'éclat, et la lueur du dedans qui flashe.
func strike(points: Array[Vector3]) -> void:
	for to in points:
		if _nature == DamageType.Kind.COLD:
			for n in STONES:
				_stone(to, n)
		else:
			_bolt(to)
		_impact(to)
	if _flash != null:
		_flash.kill()
	_light.light_energy = _calm_energy() + FLASH
	_flash = create_tween()
	_flash.tween_property(_light, ^"light_energy", _calm_energy(), FLASH_LIFE) \
			.set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)


## L'éclair d'une nature, petit et sans place : public pour `ElementFx.warm()`.
static func bolt_of(nature: int) -> MeshInstance3D:
	if not _bolts.has(nature):
		var quad := QuadMesh.new()
		# Posé par son pied.
		quad.center_offset = Vector3(0.0, 0.5, 0.0)
		quad.material = BoltFx.ramped(BOLT, BOLT_PHOTO, nature)
		_bolts[nature] = quad
	var node := MeshInstance3D.new()
	node.mesh = _bolts[nature]
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.top_level = true
	return node


## Un grêlon, sans place : public pour `ElementFx.warm()`.
static func stone() -> MeshInstance3D:
	if _stone_mesh == null:
		_stone_mesh = SphereMesh.new()
		_stone_mesh.radius = 1.0
		_stone_mesh.height = 2.0
		_stone_mesh.radial_segments = 8
		_stone_mesh.rings = 4
		var m := ShaderMaterial.new()
		m.shader = STONE
		_stone_mesh.material = m
	var node := MeshInstance3D.new()
	node.mesh = _stone_mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	node.top_level = true
	return node


func _process(delta: float) -> void:
	_clock += delta
	if _gone < 0.0:
		if is_instance_valid(_host) and not _host.is_queued_for_deletion():
			global_position = _host.get_global_transform_interpolated().origin
		else:
			_gone = 0.0
	if _gone >= 0.0:
		_gone += delta
		# Il se dissipe : les bosses fondent sur place, la lueur avec elles.
		var left := maxf(1.0 - _gone / DISSIPATION, 0.0)
		for puff in _puffs:
			puff.node.scale = Vector3.ONE * puff.size * left
		if _flash != null:
			_flash.kill()
		_light.light_energy = _calm_energy() * left
		if left <= 0.0:
			queue_free()
	_roll(_clock)


## Les bosses roulent : elles tournent lentement autour du centre et respirent.
func _roll(t: float) -> void:
	for puff in _puffs:
		var p := t * 0.25 + puff.phase
		puff.node.position = puff.home.rotated(Vector3.UP, t * SPIN) \
				+ Vector3(sin(p) * 1.5, sin(p * 1.3), cos(p) * 1.5)


func _bolt(to: Vector3) -> void:
	drop(self, to, _nature, HEIGHT * BOLT_SEEN, _host_or_self())


## Un éclair qui tombe sur `to`, haut de `tall` à l'écran, sous `parent` et sous le voile de `host` :
## celui du nuage, et la foudre appelée du Paratonnerre.
static func drop(parent: Node, to: Vector3, nature: int, tall: float, host: Node) -> void:
	var node := bolt_of(nature)
	node.scale = Vector3(tall * BOLT_ASPECT, tall, 1.0)
	node.extra_cull_margin = tall
	node.set_instance_shader_parameter(&"flip", float(randi() % 2))
	parent.add_child(node)
	ElementFx.veil_like(node, host)
	node.global_position = to
	# Il s'amincit et s'éteint : un fondu écrirait `opacity` par-dessus le voile du menu.
	var tween := node.create_tween()
	tween.tween_interval(BOLT_LIFE * 0.5)
	tween.tween_property(node, ^"scale:x", 0.0, BOLT_LIFE * 0.5)
	tween.tween_callback(node.queue_free)


func _stone(to: Vector3, n: int) -> void:
	var node := stone()
	add_child(node)
	ElementFx.veil_like(node, _host_or_self())
	node.scale = Vector3.ONE * randf_range(2.2, 3.2)
	var land := to + Vector3(randf_range(-STONE_SPREAD, STONE_SPREAD), 1.0, randf_range(-STONE_SPREAD, STONE_SPREAD))
	node.global_position = land + Vector3(randf_range(-3.0, 3.0), HEIGHT - 14.0, 0.0)
	var tween := node.create_tween()
	tween.tween_property(node, ^"global_position", land, STONE_FALL + randf() * 0.06).set_delay(n * 0.025)
	tween.tween_property(node, ^"scale", Vector3.ONE * 0.1, 0.25)
	tween.tween_callback(node.queue_free)


func _impact(at: Vector3) -> void:
	var flash := BoltFx.flash_of(_nature)
	flash.top_level = true
	add_child(flash)
	ElementFx.veil_like(flash, _host_or_self())
	flash.global_position = at + Vector3.UP * 2.0
	var light := FlameFx.light_of(_nature, 3.0, 30.0)
	flash.add_child(light)
	light.create_tween().tween_property(light, ^"light_energy", 0.0, IMPACT_LIFE)
	BoltFx.fade(flash, Vector3.ONE * IMPACT, IMPACT_LIFE)


func _host_or_self() -> Node:
	return _host if is_instance_valid(_host) else self


func _calm_energy() -> float:
	return CALM + CHARGED * charge


func _calm() -> void:
	if _light != null and (_flash == null or not _flash.is_running()):
		_light.light_energy = _calm_energy()


static func _puff_mesh() -> QuadMesh:
	if _puff_quad == null:
		var m := ShaderMaterial.new()
		m.shader = PUFF
		m.set_shader_parameter(&"puffs", PUFFS)
		_puff_quad = QuadMesh.new()
		_puff_quad.material = m
	return _puff_quad


class Puff:
	var node: MeshInstance3D
	var home := Vector3.ZERO
	var phase := 0.0
	var size := 0.0
