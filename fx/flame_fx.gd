class_name FlameFx
extends ElementFx

## La boule de feu en 3D (jalon 54, « en lumière » choisie sur planche d'après celle de Path of
## Exile) : un cœur brûlant dans son halo, une traînée de flammèches qui s'additionnent en
## lumière, la lueur portée au sol ; à l'explosion, une gerbe de flammes, sa fumée, une brûlure
## et un éclair de lumière. La traînée suit sa boule et lui survit comme les étincelles
## d'`ElementFx` ; le cœur et la lumière partent avec la boule.

const WISP := preload("res://fx/flame_wisp.gdshader")
const SMOKE := preload("res://fx/flame_smoke.gdshader")
const CORE := preload("res://fx/flame_core.gdshader")
const SCORCH := preload("res://fx/flame_scorch.gdshader")
const SHADOW := preload("res://fx/meteor_shadow.gdshader")

## Cœur, milieu, profond, bord, saturés : mêlée vers le blanc, la teinte sortait beige sur
## l'ocre. Une nature sans rampe à elle la tire de sa couleur (`ramp()`).
const RAMPS := {
	DamageType.Kind.FIRE: [
		Color(1.0, 0.72, 0.22), Color(1.0, 0.36, 0.04), Color(0.72, 0.1, 0.02), Color(0.22, 0.03, 0.01)
	],
	DamageType.Kind.COLD: [
		Color(0.7, 0.95, 1.0), Color(0.3, 0.72, 1.0), Color(0.08, 0.3, 0.85), Color(0.03, 0.08, 0.3)
	],
	DamageType.Kind.NECROTIC: [
		Color(0.82, 1.0, 0.3), Color(0.38, 0.82, 0.08), Color(0.1, 0.38, 0.04), Color(0.04, 0.1, 0.02)
	],
}
const FLAME_LIFE := 0.45
const BLAST_LIFE := 0.6
const SMOKE_LIFE := 1.0
const SCORCH_LIFE := 1.4
## En pixels du monde : le cœur, et une flammèche de la traînée.
const CORE_SIZE := 12.0
const WISP_SIZE := 10.0
## La lueur portée au sol par la boule, puis l'éclair de l'explosion qui s'éteint.
const BALL_LIGHT := 14.0
const BALL_REACH := 60.0
const FLASH_LIGHT := 24.0
## Un éclat (Fragmentation, crachat, escarbille) : son cœur et sa traînée en part de ceux de la
## boule, ses flammèches moins nombreuses et plus brèves, sans lumière à lui. À l'identique de la
## boule, les éclats se perdaient dans l'éclair de l'explosion d'où ils partent : on croyait que
## la Fragmentation ne marchait pas.
const SHARD := 0.55
const SHARD_WISPS := 36
const SHARD_LIFE := 0.28
## Le Météore (« boule et ombre » choisie sur planche) : la boule en grand, et une traînée
## dense — il tombe à ~600 px/s, celle de la boule y sortait en perles.
const METEOR := 2.6
const METEOR_WISPS := 420
const METEOR_LIFE := 0.5
## L'explosion a été réglée sur planche à ce rayon ; ses mesures le suivent.
const BOARD_RADIUS := 20.0

static var _flame_draw: QuadMesh
static var _smoke_draw: QuadMesh
static var _scorch_plane: PlaneMesh
static var _swell: CurveTexture
static var _flame_materials := {}
static var _cores := {}
static var _scorches := {}

## Le cœur de la boule, que la boule grossit (le Gonflement) ou réduit (un éclat).
var core: MeshInstance3D
var _nature := 0
var _glow: OmniLight3D


## La boule de `host` (un projectile) : le cœur et la lumière sur elle, la traînée qui la suit.
static func ball(host: Node3D, nature: int) -> FlameFx:
	var fx := _emitter(host, _flame_material(nature, &"trail", BOARD_RADIUS), 90, FLAME_LIFE, false)
	fx._follow(host, Vector3.UP * LIFT)
	fx._nature = nature
	fx.core = MeshInstance3D.new()
	var quad := QuadMesh.new()
	quad.size = Vector2.ONE * CORE_SIZE
	fx.core.mesh = quad
	fx.core.material_override = _core_material(nature)
	fx.core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.core.position = Vector3.UP * LIFT
	host.add_child(fx.core)
	veil_like(fx.core, host)
	fx._glow = _light(nature, BALL_LIGHT, BALL_REACH)
	fx._glow.position = Vector3.UP * LIFT
	host.add_child(fx._glow)
	return fx


## Cette boule devient un météore, à sa naissance.
func as_meteor() -> void:
	core.scale = Vector3.ONE * METEOR
	process_material = _flame_material(_nature, &"meteor", BOARD_RADIUS)
	amount = METEOR_WISPS
	lifetime = METEOR_LIFE


## L'ombre d'un météore sous `parent`, de rayon `radius` ; `progress` la fait grandir.
static func shadow(parent: Node3D, radius: float) -> MeshInstance3D:
	var disc := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * 2.0
	disc.mesh = plane
	var m := ShaderMaterial.new()
	m.shader = SHADOW
	disc.material_override = m
	disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(disc)
	disc.position = Vector3.UP * 0.6
	disc.scale = Vector3(radius, 1.0, radius)
	veil_like(disc, parent)
	return disc


## Cette boule devient un éclat, à sa naissance : changer `amount` relance l'émetteur.
func as_shard() -> void:
	core.scale = Vector3.ONE * SHARD
	process_material = _flame_material(_nature, &"shard", BOARD_RADIUS)
	amount = SHARD_WISPS
	lifetime = SHARD_LIFE
	_glow.queue_free()


## L'explosion de rayon `radius` en `at` : tout se libère seul. Rend ce qu'elle pose.
static func blast(host: Node3D, at: Vector3, nature: int, radius: float) -> Array[Node]:
	var k := radius / BOARD_RADIUS
	var root := host.get_viewport()
	var mid := at + Vector3.UP * LIFT * 0.7
	var flames := _emitter(host, _flame_material(nature, &"blast", radius), clampi(int(110.0 * k), 40, 220), BLAST_LIFE, false)
	var smoke := _emitter(host, _flame_material(nature, &"smoke", radius), clampi(int(26.0 * k), 10, 60), SMOKE_LIFE, true)
	for fx in [flames, smoke]:
		fx.one_shot = true
		fx.explosiveness = 0.9
		root.add_child(fx)
		fx.global_position = mid
		# Et non `finished`, que les particules n'émettent pas sans rendu (en headless).
		fx.get_tree().create_timer(fx.lifetime).timeout.connect(fx.queue_free)
	var scorch := MeshInstance3D.new()
	if _scorch_plane == null:
		_scorch_plane = PlaneMesh.new()
		_scorch_plane.size = Vector2.ONE * 2.4
	scorch.mesh = _scorch_plane
	scorch.material_override = _scorch_material(nature)
	scorch.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	root.add_child(scorch)
	scorch.global_position = at + Vector3.UP * 0.6
	scorch.scale = Vector3(radius, 1.0, radius)
	veil_like(scorch, host)
	var burn := scorch.create_tween()
	burn.tween_method(func(p: float) -> void: scorch.set_instance_shader_parameter(&"progress", p), 0.0, 1.0, SCORCH_LIFE)
	burn.tween_callback(scorch.queue_free)
	# À l'échelle du souffle : celui d'un éclat éclairait autant que celui de la boule.
	var flash := _light(nature, FLASH_LIGHT * clampf(k, 0.35, 1.5), radius * 3.5)
	root.add_child(flash)
	flash.global_position = mid + Vector3.UP * 6.0
	var fade := flash.create_tween()
	fade.tween_property(flash, "light_energy", 0.0, BLAST_LIFE).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	fade.tween_callback(flash.queue_free)
	return [flames, smoke, scorch, flash]


static func _emitter(host: Node3D, pm: ParticleProcessMaterial, count: int, life: float, smoke: bool) -> FlameFx:
	var fx := FlameFx.new()
	fx.amount = count
	fx.lifetime = life
	fx.local_coords = false
	fx.fixed_fps = 0
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.process_material = pm
	fx.draw_pass_1 = _draw_of(smoke)
	veil_like(fx, host)
	return fx


static func _draw_of(smoke: bool) -> QuadMesh:
	if (_smoke_draw if smoke else _flame_draw) == null:
		var quad := QuadMesh.new()
		var m := ShaderMaterial.new()
		m.shader = SMOKE if smoke else WISP
		# La fumée sous le feu : née avec lui, elle couvrait l'explosion d'un disque gris.
		m.render_priority = 0 if smoke else 1
		quad.material = m
		if smoke:
			_smoke_draw = quad
		else:
			_flame_draw = quad
	return _smoke_draw if smoke else _flame_draw


## Gardée par nature, geste et rayon : fabriquée à chaque tir, sa rampe partait au GPU à chaque fois.
static func _flame_material(nature: int, kind: StringName, radius: float) -> ParticleProcessMaterial:
	var key := "%d %s %d" % [nature, kind, roundi(radius)]
	if _flame_materials.has(key):
		return _flame_materials[key]
	var k := radius / BOARD_RADIUS
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.UP
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	var size := WISP_SIZE
	var speed := 8.0
	match kind:
		&"trail", &"shard", &"meteor":
			if kind == &"shard":
				size *= SHARD
			elif kind == &"meteor":
				size *= 1.8
			pm.spread = 50.0
			pm.gravity = Vector3(0, 14, 0)
			pm.emission_sphere_radius = 5.0 if kind == &"meteor" else 1.5
			pm.initial_velocity_min = speed * 0.4
		&"blast":
			size = 15.0 * k
			speed = radius * 3.4
			pm.spread = 180.0
			pm.gravity = Vector3(0, 70, 0)
			pm.emission_sphere_radius = 4.0
			pm.initial_velocity_min = radius * 0.6
		&"smoke":
			size = 16.0 * k
			speed = radius * 1.4
			pm.spread = 80.0
			pm.gravity = Vector3(0, 20, 0)
			pm.emission_sphere_radius = 4.0
			pm.initial_velocity_min = speed * 0.4
	pm.initial_velocity_max = speed
	pm.damping_min = speed * 1.2
	pm.damping_max = speed * 2.0
	pm.scale_min = size * 0.7
	pm.scale_max = size * 1.3
	if _swell == null:
		var curve := Curve.new()
		curve.add_point(Vector2(0.0, 0.5))
		curve.add_point(Vector2(0.25, 1.0))
		curve.add_point(Vector2(1.0, 0.55))
		_swell = CurveTexture.new()
		_swell.curve = curve
	pm.scale_curve = _swell
	var ramp := ramp(nature)
	var gradient := Gradient.new()
	if kind == &"smoke":
		var grey := Color(0.13, 0.11, 0.1).lerp(ramp[3], 0.3)
		gradient.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		gradient.colors = PackedColorArray([Color(grey, 0.0), Color(grey, 0.35), Color(grey, 0.0)])
	else:
		gradient.offsets = PackedFloat32Array([0.0, 0.08, 0.45, 0.8, 1.0])
		gradient.colors = PackedColorArray([ramp[0], ramp[1], ramp[2], Color(ramp[3], 0.8), Color(ramp[3], 0.0)])
	var texture := GradientTexture1D.new()
	texture.gradient = gradient
	pm.color_ramp = texture
	_flame_materials[key] = pm
	return pm


## Cœur, milieu, profond, bord de `nature`.
static func ramp(nature: int) -> Array:
	if RAMPS.has(nature):
		return RAMPS[nature]
	var c: Color = DamageType.COLORS[nature]
	return [c.lerp(Color.WHITE, 0.35), c, c * Color(0.6, 0.6, 0.6), c * Color(0.2, 0.2, 0.2)]


static func _core_material(nature: int) -> ShaderMaterial:
	if not _cores.has(nature):
		var ramp := ramp(nature)
		var m := ShaderMaterial.new()
		m.shader = CORE
		for i in 3:
			var c: Color = ramp[i]
			m.set_shader_parameter([&"heart", &"tint", &"deep"][i], Vector3(c.r, c.g, c.b))
		_cores[nature] = m
	return _cores[nature]


static func _scorch_material(nature: int) -> ShaderMaterial:
	if not _scorches.has(nature):
		var m := ShaderMaterial.new()
		m.shader = SCORCH
		var c: Color = ramp(nature)[1]
		m.set_shader_parameter(&"tint", Vector3(c.r, c.g, c.b))
		_scorches[nature] = m
	return _scorches[nature]


static func _light(nature: int, energy: float, reach: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = ramp(nature)[1]
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.0
	light.shadow_enabled = false
	return light
