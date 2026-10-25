class_name IceSpikesFx
extends Node3D

## Les Pics de glace en 3D (jalon 54, « sobre » choisi sur une deuxième planche ; la première, des
## cristaux lisses qui rentraient sous terre, « trop pauvre ») : une douzaine de cristaux de glace
## claire percent le sol, penchés vers le dehors, puis se brisent en éclats qui retombent ; un éclair
## de lumière froide et le sol fendu de givre marquent le cercle qui frappe, et rien n'en sort.
##
## Il vit à la racine du viewport : le nœud du jeu parti, les éclats et le givre finissent de tomber.

const CRYSTAL := preload("res://fx/ice_crystal.gdshader")
const CRACKS := preload("res://fx/frost_cracks.gdshader")
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
## Ils se brisent juste avant que le nœud du jeu ne parte (`IceSpikes.LIFETIME`).
const SHATTER := 0.4
const SHARDS := 24
const SHARD_LIFE := 0.45
const LIGHT := 3.0
const LIGHT_LIFE := 0.5
const CRACKS_LIFE := 0.95
const CRACKS_OPEN := 0.08
const SHAPES := 6

static var _meshes: Array[ArrayMesh] = []
static var _sliver: ArrayMesh
static var _crystals := {}
static var _floors := {}
static var _shard_motions := {}
static var _plane: PlaneMesh

var _clock := 0.0
var _broken := false
var _spikes: Array[Spike] = []
var _light: OmniLight3D
var _cracks: MeshInstance3D
var _shards: GPUParticles3D


class Spike:
	var node: MeshInstance3D
	var foot: Vector3
	## Du pied à la pointe, à la taille du pic.
	var tip: Vector3
	var delay := 0.0


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
	fx._light = FlameFx.light_of(nature, LIGHT, radius * 3.0)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * 14.0
	fx.add_child(fx._light)
	fx._cracks = MeshInstance3D.new()
	if _plane == null:
		_plane = PlaneMesh.new()
		_plane.size = Vector2.ONE * 2.0
	fx._cracks.mesh = _plane
	fx._cracks.material_override = _floor(nature)
	fx._cracks.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx._cracks.position = Vector3.UP * DangerZone.LIFT
	fx._cracks.scale = Vector3.ONE * radius * 1.2
	fx._cracks.rotation.y = randf() * TAU
	fx.add_child(fx._cracks)
	fx._shards = GPUParticles3D.new()
	fx._shards.amount = SHARDS
	fx._shards.lifetime = SHARD_LIFE
	fx._shards.one_shot = true
	fx._shards.explosiveness = 1.0
	fx._shards.emitting = false
	fx._shards.local_coords = false
	fx._shards.fixed_fps = 0
	fx._shards.process_material = _shard_motion(radius)
	fx._shards.draw_pass_1 = _sliver_mesh()
	fx._shards.material_override = crystal(nature)
	fx._shards.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx._shards.position = Vector3.UP * 15.0 * grown
	fx.add_child(fx._shards)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, host)
	fx._show()
	fx.get_tree().create_timer(maxf(SHATTER + SHARD_LIFE, CRACKS_LIFE) + 0.05).timeout.connect(fx.queue_free)
	return fx


func _process(delta: float) -> void:
	_clock += delta
	# Et non `emitting`, qui retombe à la fin de la salve : elle repartait.
	if _clock >= SHATTER and not _broken:
		shatter()
	_show()


func _show() -> void:
	for spike in _spikes:
		var out := ease(clampf((_clock - spike.delay) / RISE, 0.0, 1.0), 0.35)
		# Le pied reste au sol et la pointe monte : il perce, il ne grandit pas.
		spike.node.position = spike.foot + spike.tip * (out - 1.0) * 1.05
	_light.light_energy = LIGHT * pow(1.0 - clampf(_clock / LIGHT_LIFE, 0.0, 1.0), 2.0)
	_cracks.set_instance_shader_parameter(&"spread", ease(clampf(_clock / CRACKS_OPEN, 0.0, 1.0), 0.4))
	_cracks.set_instance_shader_parameter(&"fade", 1.0 - smoothstep(0.55, 1.0, _clock / CRACKS_LIFE))


## Les pics disparaissent, leurs éclats volent : public pour `ElementFx.warm()`.
func shatter() -> void:
	_broken = true
	for spike in _spikes:
		spike.node.visible = false
	_shards.emitting = true


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


static func _floor(nature: int) -> ShaderMaterial:
	if not _floors.has(nature):
		var m := ShaderMaterial.new()
		m.shader = CRACKS
		m.set_shader_parameter(&"cracks", BurntPath.CRACKS)
		_ramp_into(m, nature)
		_floors[nature] = m
	return _floors[nature]


static func _ramp_into(m: ShaderMaterial, nature: int) -> void:
	var ramp := FlameFx.ramp(nature)
	m.set_shader_parameter(&"heart", Vector3(ramp[0].r, ramp[0].g, ramp[0].b))
	m.set_shader_parameter(&"tint", Vector3(ramp[1].r, ramp[1].g, ramp[1].b))
	m.set_shader_parameter(&"deep", Vector3(ramp[2].r, ramp[2].g, ramp[2].b))
	m.set_shader_parameter(&"rime", Vector3(Frost.RIME.r, Frost.RIME.g, Frost.RIME.b))


## Les éclats : jetés vers le haut et un peu dehors, ils retombent dans le cercle — plus loin, ils
## parlaient d'une zone qui n'avait pas frappé.
static func _shard_motion(radius: float) -> ParticleProcessMaterial:
	var key := roundi(radius)
	if not _shard_motions.has(key):
		var pm := ParticleProcessMaterial.new()
		pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
		pm.emission_ring_axis = Vector3.UP
		pm.emission_ring_radius = radius * 0.6
		pm.emission_ring_inner_radius = radius * 0.1
		pm.emission_ring_height = 30.0 * sqrt(radius / RADIUS)
		pm.direction = Vector3.UP
		pm.spread = 35.0
		pm.initial_velocity_min = 40.0
		pm.initial_velocity_max = 80.0
		pm.radial_velocity_min = 12.0
		pm.radial_velocity_max = 28.0
		pm.gravity = Vector3(0.0, -420.0, 0.0)
		pm.particle_flag_rotate_y = true
		pm.angle_min = -180.0
		pm.angle_max = 180.0
		pm.angular_velocity_min = -720.0
		pm.angular_velocity_max = 720.0
		pm.scale_min = 4.0
		pm.scale_max = 7.0
		var shrink := Curve.new()
		shrink.add_point(Vector2(0.0, 1.0))
		shrink.add_point(Vector2(0.6, 1.0))
		shrink.add_point(Vector2(1.0, 0.0))
		var curve := CurveTexture.new()
		curve.curve = shrink
		pm.scale_curve = curve
		_shard_motions[key] = pm
	return _shard_motions[key]


## Six cristaux irréguliers de cinq ou six pans : pied sous le sol, ventre, épaule, pointe décentrée ;
## hauteur 1, largeur 1. Six suffisent à ce qu'aucun pic ne ressemble à son voisin.
static func crystals() -> Array[ArrayMesh]:
	if _meshes.is_empty():
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in SHAPES:
			_meshes.append(_crystal_mesh(rng))
	return _meshes


## L'éclat d'un pic brisé : un cristal trois fois plus fin, centré et couché, qui tourne autour de la
## verticale. Réduits d'un bloc, les pics entiers retombaient en galets trapus et dressés.
static func _sliver_mesh() -> ArrayMesh:
	if _sliver == null:
		var rng := RandomNumberGenerator.new()
		rng.seed = 9
		var st := SurfaceTool.new()
		st.append_from(_crystal_mesh(rng, 0.33), 0, Transform3D(Basis(Vector3.RIGHT, 1.2), Vector3.ZERO)
				* Transform3D(Basis.IDENTITY, Vector3.DOWN * 0.35))
		_sliver = st.commit()
	return _sliver


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
