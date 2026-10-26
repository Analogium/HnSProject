class_name IceSpikesFx
extends Node3D

## Les Pics de glace en 3D (jalon 54, « sobre » choisi sur une deuxième planche ; la première, des
## cristaux lisses qui rentraient sous terre, « trop pauvre »), puis à la barre de Last Epoch (« pile »,
## contre l'ancienne, la pile avec une onde de choc au pied et la pile sans esquilles) : une douzaine de
## cristaux de glace claire percent le sol, penchés vers le dehors, puis **se rongent** pendant que leurs
## esquilles volent et retombent ; une distorsion à la frappe, des scintillements et un éclair de lumière
## froide marquent le cercle qui frappe. Pas de glace au sol : elle disait un sol gelé qu'ils ne posent pas.
##
## Il vit à la racine du viewport : le nœud du jeu parti, les éclats finissent de tomber.

const CRYSTAL := preload("res://fx/ice_crystal.gdshader")
const VEINS := preload("res://fx/ice_veins.png")
## Dessiné pour le rayon de la compétence : un autre rayon écarte les pics, et les grandit moins.
const RADIUS := 26.0
const SPIKES := 12
## Un tiers de grands pics : seuls, de même taille, ils faisaient une palissade.
const BIG_LENGTH := Vector2(30.0, 44.0)
const BIG_WIDTH := Vector2(7.0, 10.0)
const SMALL_LENGTH := Vector2(14.0, 26.0)
const SMALL_WIDTH := Vector2(4.0, 6.5)
const RISE := 0.06
const STAGGER := 0.07
## Ils se brisent juste avant que le nœud du jeu ne parte (`IceSpikes.LIFETIME`), et se rongent vite :
## à demi rongé, un grand pic sortait en papier déchiré blanc.
const SHATTER := 0.4
const EATEN := 0.1
const SHARDS := 28
const SHARD_LIFE := 0.5
const SHARD_LENGTH := Vector2(6.0, 11.0)
const GRAVITY := 420.0
const WARP_LIFE := 0.22
const WARP_STRENGTH := 0.03
const GLINTS := 10
const LIGHT := 3.0
const LIGHT_LIFE := 0.5
const SHAPES := 6
## Le givre des arêtes et des liserés. **Le froid ne se blanchit pas, il s'ombre** : son cyan porte déjà
## 0,81 de luminance ; éclairci, un cristal se lit comme du verre.
const RIME := Color(0.86, 0.97, 1.00)

static var _meshes: Array[ArrayMesh] = []
static var _crystals := {}
static var _plane: PlaneMesh

var _clock := 0.0
var _spikes: Array[Spike] = []
var _shards: MultiMeshInstance3D
var _flights: Array[Flight] = []
var _warp: MeshInstance3D
var _glints: MultiMeshInstance3D
var _glint_phases: Array[float] = []
var _light: OmniLight3D


class Spike:
	var node: MeshInstance3D
	var foot: Vector3
	## Du pied à la pointe, à la taille du pic.
	var tip: Vector3
	var delay := 0.0


## Une esquille : d'où elle part, sa vitesse, l'axe sur lequel elle tourne ; le Tombeau la prend aussi.
class Flight:
	var from: Vector3
	var speed: Vector3
	var axis: Vector3
	var length := 0.0

	## Où elle est `t` secondes après son départ, jamais sous le sol ; `turn` la décale sur son axe.
	func at(t: float, turn: float) -> Transform3D:
		var p := from + speed * t + Vector3.DOWN * 0.5 * GRAVITY * t * t
		p.y = maxf(p.y, 1.0)
		return Transform3D(Basis(axis, t * 14.0 + turn) * Basis.from_scale(Vector3(0.35, 1.0, 0.35) * length), p)


## Les pics de `host` (pour son voile) en `at`, au rayon qui frappe ; ils se libèrent seuls.
static func raise(host: Node3D, at: Vector3, nature: int, radius: float) -> IceSpikesFx:
	var fx := IceSpikesFx.new()
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(fx)
	fx.global_position = at
	var spread := radius / RADIUS
	var grown := sqrt(spread)
	for i in SPIKES:
		var big := i < SPIKES / 3
		var h := randf() * TAU
		var foot := Vector3(cos(h), 0.0, sin(h)) * RADIUS * spread * 0.92 * sqrt(randf())
		var spike := Spike.new()
		spike.foot = foot
		var length := randf_range(BIG_LENGTH.x, BIG_LENGTH.y) if big else randf_range(SMALL_LENGTH.x, SMALL_LENGTH.y)
		var width := randf_range(BIG_WIDTH.x, BIG_WIDTH.y) if big else randf_range(SMALL_WIDTH.x, SMALL_WIDTH.y)
		spike.delay = randf() * STAGGER
		spike.node = MeshInstance3D.new()
		spike.node.mesh = crystals()[randi() % SHAPES]
		spike.node.material_override = crystal(nature)
		spike.node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fx.add_child(spike.node)
		# Penché puis étiré en hauteur, comme sur la planche : l'étirement le redresse, couché d'abord
		# il sortait en lame qui débordait du cercle.
		var lean := _leaning(foot, 0.2 + 0.65 * foot.length() / (RADIUS * spread))
		spike.node.basis = Basis.from_scale(Vector3(width, length, width) * grown) \
				* Basis(Quaternion(Vector3.UP, lean)) * Basis(Vector3.UP, randf() * TAU)
		spike.tip = spike.node.basis * Vector3.UP
		fx._spikes.append(spike)
	# Les esquilles partent du corps des pics, vers le haut et un peu dehors : plus loin, elles parlaient
	# d'une zone qui n'avait pas frappé.
	for i in SHARDS:
		var spike := fx._spikes[randi() % SPIKES]
		var flight := Flight.new()
		flight.from = spike.foot + spike.tip * randf_range(0.3, 0.95)
		var out := Vector3(spike.foot.x, 0.0, spike.foot.z).normalized() if spike.foot.length() > 0.5 else Vector3.RIGHT
		flight.speed = Vector3.UP * randf_range(40.0, 85.0) + out * randf_range(10.0, 30.0) * grown
		flight.axis = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized()
		flight.length = randf_range(SHARD_LENGTH.x, SHARD_LENGTH.y) * grown
		fx._flights.append(flight)
	fx._shards = IceNovaFx.multimesh(fx, crystals()[2], SHARDS, crystal(nature))
	fx._warp = IceNovaFx.flat(fx, IceNovaFx.material(IceNovaFx.WARP, nature), radius * 1.6, DangerZone.LIFT + 0.8)
	fx._glints = IceNovaFx.scatter_glints(fx, GLINTS, radius, nature, fx._glint_phases)
	fx._light = FlameFx.light_of(nature, LIGHT, radius * 3.0)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * 14.0
	fx.add_child(fx._light)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, host)
	fx._show()
	fx.get_tree().create_timer(SHATTER + SHARD_LIFE + 0.05).timeout.connect(fx.queue_free)
	return fx


func _process(delta: float) -> void:
	_clock += delta
	_show()


func _show() -> void:
	var eaten := smoothstep(SHATTER, SHATTER + EATEN, _clock)
	for spike in _spikes:
		var out := ease(clampf((_clock - spike.delay) / RISE, 0.0, 1.0), 0.35)
		# Le pied reste au sol et la pointe monte : il perce, il ne grandit pas.
		spike.node.position = spike.foot + spike.tip * (out - 1.0) * 1.05
		spike.node.visible = eaten < 1.0
		spike.node.set_instance_shader_parameter(&"dissolve", eaten)
	var flown := _clock - SHATTER
	_shards.visible = flown > 0.0 and flown < SHARD_LIFE
	if _shards.visible:
		for i in SHARDS:
			_shards.multimesh.set_instance_transform(i, shard(i))
		_shards.set_instance_shader_parameter(&"dissolve", smoothstep(SHARD_LIFE * 0.5, SHARD_LIFE, flown))
	_warp.visible = _clock < WARP_LIFE
	_warp.set_instance_shader_parameter(&"front", ease(clampf(_clock / (WARP_LIFE * 0.6), 0.0, 1.0), 0.4) * 0.85)
	_warp.set_instance_shader_parameter(&"strength", WARP_STRENGTH * (1.0 - smoothstep(0.08, WARP_LIFE, _clock)))
	var lit := smoothstep(0.05, 0.15, _clock) * (1.0 - smoothstep(SHATTER, SHATTER + SHARD_LIFE, _clock))
	for i in GLINTS:
		IceNovaFx.shine(_glints, i, lit * IceNovaFx.twinkle(_clock, _glint_phases[i]))
	_light.light_energy = LIGHT * pow(1.0 - clampf(_clock / LIGHT_LIFE, 0.0, 1.0), 2.0)


## L'esquille `i` à cet instant ; publique pour les tests, le moteur sans rendu ne relit pas un `MultiMesh`.
func shard(i: int) -> Transform3D:
	return _flights[i].at(maxf(_clock - SHATTER, 0.0), float(i))


## Un plan au sol de 2 × 2, mis à l'échelle de son rayon (`IceNovaFx.flat()`).
static func plane() -> PlaneMesh:
	if _plane == null:
		_plane = PlaneMesh.new()
		_plane.size = Vector2.ONE * 2.0
	return _plane


## Penché vers le dehors du cercle, d'autant plus qu'il est loin du centre.
static func _leaning(foot: Vector3, lean: float) -> Vector3:
	var out := foot.normalized() if foot.length() > 0.5 else Flat.from_angle(randf() * TAU)
	return Vector3.UP.rotated(out.cross(Vector3.UP).normalized(), -lean)


## La glace d'une nature, gardée ; l'éclat des pics (`IceShardFx`) la porte aussi.
static func crystal(nature: int) -> ShaderMaterial:
	if not _crystals.has(nature):
		var m := ShaderMaterial.new()
		m.shader = CRYSTAL
		m.set_shader_parameter(&"veins", VEINS)
		_ramp_into(m, nature)
		_crystals[nature] = m
	return _crystals[nature]


static func _ramp_into(m: ShaderMaterial, nature: int) -> void:
	var ramp := FlameFx.ramp(nature)
	m.set_shader_parameter(&"heart", Vector3(ramp[0].r, ramp[0].g, ramp[0].b))
	m.set_shader_parameter(&"tint", Vector3(ramp[1].r, ramp[1].g, ramp[1].b))
	m.set_shader_parameter(&"deep", Vector3(ramp[2].r, ramp[2].g, ramp[2].b))
	m.set_shader_parameter(&"rime", Vector3(RIME.r, RIME.g, RIME.b))


## Six cristaux irréguliers de cinq ou six pans : pied sous le sol, ventre, épaule, pointe décentrée ;
## hauteur 1, largeur 1. Six suffisent à ce qu'aucun pic ne ressemble à son voisin.
static func crystals() -> Array[ArrayMesh]:
	if _meshes.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in SHAPES:
			_meshes.append(_crystal_mesh(rng))
	return _meshes


static func _crystal_mesh(rng: RandomNumberGenerator, slim := 1.0) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var sides := 5 + rng.randi() % 2
	var rings := [Vector2(-0.3, 0.42), Vector2(0.0, 0.5), Vector2(0.6, 0.3)]
	var tip := Vector3(rng.randf_range(-0.08, 0.08), 1.0, rng.randf_range(-0.08, 0.08))
	var jitter: Array[float] = []
	for i in sides:
		jitter.append(rng.randf_range(0.7, 1.3))
	var points: Array[Array] = []
	for ring: Vector2 in rings:
		var around: Array[Vector3] = []
		for i in sides:
			var h := TAU * (float(i) + rng.randf_range(-0.15, 0.15)) / float(sides)
			around.append(Vector3(cos(h), 0.0, sin(h)) * ring.y * jitter[i] * slim + Vector3.UP * ring.x)
		points.append(around)
	for k in rings.size() - 1:
		for i in sides:
			var j := (i + 1) % sides
			_facet(st, points[k][i], points[k + 1][i], points[k + 1][j])
			_facet(st, points[k][i], points[k + 1][j], points[k][j])
	for i in sides:
		_facet(st, points[2][i], tip, points[2][(i + 1) % sides])
	return st.commit()


## Un pan tourné vers le dehors, dans l'ordre que Godot tient pour l'avant (horaire vu de face) :
## tournés à l'envers, la caméra voyait le dedans du fond et le reflet de bord blanchissait tout.
static func _facet(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n := (b - a).cross(c - a).normalized()
	var mid := (a + b + c) / 3.0
	if n.dot(Vector3(mid.x, 0.0, mid.z)) < 0.0:
		var swap := b
		b = c
		c = swap
		n = -n
	for v: Vector3 in [a, c, b]:
		st.set_normal(n)
		st.add_vertex(v)
