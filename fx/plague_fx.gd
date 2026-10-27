class_name PlagueFx
extends ElementFx

## La Peste en 3D (jalon 54, à la barre de Last Epoch) : le crâne de fumée de la 2D, photographié par Qwen-Image
## (`fx/plague_skull.png`), mêlé et non additionné, qui palpite ; une traînée de volutes de gaz qui s'ouvrent et
## se rongent derrière lui (`RotBlastFx`, l'émetteur qui suit le trait comme celui de `FlameFx`) ; une bouffée
## à sa fin. **La Nuée** (l'Orbe statique en nécrose) : un nuage de volutes qui tournoient, sans crâne, et
## un essaim de mouches sombres qui bourdonnent autour.
##
## **L'os des Lanceurs d'os** (`bone()`) : un os d'ivoire éclairé qui tournoie, sans traînée.
##
## L'émetteur vit à la racine du viewport et survit au trait le temps que sa traînée retombe.

const SKULL := preload("res://fx/plague_skull.png")
const SKULL_SIZE := 16.0
const SMOKE_LIFE := 0.7
const SMOKE := 40
const PUFF := 9.0
## La Nuée : son nuage, et ses mouches.
const SWARM := 14.0
const FLIES := 14
const BONE := 7.0

static var _trail_motion: ParticleProcessMaterial
static var _swarm_motion: ParticleProcessMaterial
static var _skulls := {}
static var _bone_mesh: ArrayMesh

var skull: MeshInstance3D
var _flies: MultiMeshInstance3D
var _clock := 0.0


## Le trait de `host` (un projectile) ; `swarm`, la Nuée.
static func show_on(host: Node3D, nature: int, swarm := false) -> PlagueFx:
	var fx := PlagueFx.new()
	fx.amount = FLIES * 3 if swarm else SMOKE
	fx.lifetime = SMOKE_LIFE
	fx.local_coords = false
	fx.fixed_fps = 0
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.process_material = _motion(swarm)
	fx.draw_pass_1 = RotBlastFx._puff_draw(nature)
	ElementFx.veil_like(fx, host)
	fx._follow(host, Vector3.UP * LIFT)
	if swarm:
		fx._flies = IceNovaFx.multimesh(fx, QuadMesh.new(), FLIES, fly_material())
		ElementFx.veil_like(fx._flies, host)
		return fx
	fx.skull = MeshInstance3D.new()
	fx.skull.mesh = QuadMesh.new()
	fx.skull.scale = Vector3.ONE * SKULL_SIZE
	fx.skull.material_override = skull_material(nature)
	fx.skull.set_instance_shader_parameter(&"life", 0.0)
	fx.skull.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.skull.position = Vector3.UP * LIFT
	host.add_child(fx.skull)
	ElementFx.veil_like(fx.skull, host)
	return fx


## L'os de `host` (un projectile).
static func bone(host: Node3D) -> MeshInstance3D:
	if _bone_mesh == null:
		var st := SurfaceTool.new()
		var shaft := CapsuleMesh.new()
		shaft.radius = 0.12
		shaft.height = 1.0
		var knob := SphereMesh.new()
		knob.radius = 0.16
		knob.height = 0.32
		var lying := Basis(Vector3.FORWARD, PI * 0.5)
		st.append_from(shaft, 0, Transform3D(lying, Vector3.ZERO))
		for x in [-0.45, 0.45]:
			for z in [-0.1, 0.1]:
				st.append_from(knob, 0, Transform3D(Basis(), Vector3(x, 0.0, z)))
		_bone_mesh = st.commit()
		var m := ShaderMaterial.new()
		m.shader = preload("res://fx/bone.gdshader")
		_bone_mesh.surface_set_material(0, m)
	var node := MeshInstance3D.new()
	node.mesh = _bone_mesh
	node.scale = Vector3.ONE * BONE
	node.position = Vector3.UP * LIFT
	host.add_child(node)
	ElementFx.veil_like(node, host)
	return node


## Le trait se rhabille (l'os des Lanceurs d'os) ou finit : le crâne part avec lui, la traînée retombe.
func let_go() -> void:
	if is_instance_valid(skull):
		skull.queue_free()
	super()


## Le trait finit : une bouffée là où il crève.
func pop(nature: int) -> void:
	RotBlastFx.puffs(get_viewport(), nature, 12.0, 1.0, 6).global_position = global_position


func _process(delta: float) -> void:
	super(delta)
	_clock += delta
	if skull != null and is_instance_valid(skull):
		skull.scale = Vector3.ONE * SKULL_SIZE * (1.0 + 0.06 * sin(_clock * 9.0))
	if _flies != null:
		for i in FLIES:
			_flies.multimesh.set_instance_transform(i, fly(i))


## La mouche `i` à cet instant, autour du nuage ; publique pour les tests.
func fly(i: int) -> Transform3D:
	var t := _clock * (5.0 + float(i % 4)) + float(i) * 2.39
	var r := SWARM * (0.6 + 0.4 * sin(t * 0.7 + float(i)))
	var at := Vector3(cos(t) * r, 2.0 + 4.0 * sin(t * 1.9 + float(i)), sin(t * 1.3) * r * 0.8)
	return Transform3D(Basis.from_scale(Vector3.ONE * 1.4), at)


static func skull_material(nature: int) -> ShaderMaterial:
	if not _skulls.has(nature):
		var m: ShaderMaterial = RotBlastFx.photo_material(SKULL, nature).duplicate()
		m.set_shader_parameter(&"density", 2.4)
		_skulls[nature] = m
	return _skulls[nature]


static func fly_material() -> ShaderMaterial:
	if not _skulls.has(&"fly"):
		var m := ShaderMaterial.new()
		m.shader = preload("res://fx/fly.gdshader")
		_skulls[&"fly"] = m
	return _skulls[&"fly"]


static func _motion(swarm: bool) -> ParticleProcessMaterial:
	if swarm and _swarm_motion != null:
		return _swarm_motion
	if not swarm and _trail_motion != null:
		return _trail_motion
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.spread = 180.0 if swarm else 60.0
	pm.gravity = Vector3(0, 4, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = SWARM * 0.6 if swarm else 2.5
	pm.initial_velocity_min = 2.0
	pm.initial_velocity_max = 8.0
	pm.damping_min = 6.0
	pm.damping_max = 12.0
	var size := PUFF * (1.6 if swarm else 1.0)
	pm.scale_min = size * 0.7
	pm.scale_max = size * 1.3
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.5))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 1.4))
	var swell := CurveTexture.new()
	swell.curve = curve
	pm.scale_curve = swell
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.7), Color(1, 1, 1, 0.3)])
	var fade := GradientTexture1D.new()
	fade.gradient = gradient
	pm.color_ramp = fade
	if swarm:
		_swarm_motion = pm
	else:
		_trail_motion = pm
	return pm
