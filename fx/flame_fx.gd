class_name FlameFx
extends ElementFx

## La boule de feu en 3D (jalon 54, « photo » choisie sur une planche de textures vraies, après
## des flammèches en bruit de shader ; puis la « pile rouge » à la barre de Last Epoch) : une boule
## de feu photographiée qui tournoie, une traînée de volutes de feu photographiées qui s'additionnent,
## des braises qu'elle sème, la chaleur qui tremble sous elle, la lueur portée au sol ; à l'explosion,
## une photo d'explosion, des volutes, une fumée photographiée, un éclair de lumière, et les couches de
## `FireBlastFx`. Sa brûlure craquelée au sol est partie : elle disait un sol qui brûle. La traînée suit
## sa boule et lui survit comme les étincelles d'`ElementFx` ; le cœur et la lumière partent avec elle.

const PHOTO := preload("res://fx/fire_photo.gdshader")
const SMOKE := preload("res://fx/fire_smoke.gdshader")
const SHADOW := preload("res://fx/meteor_shadow.gdshader")
const SMOKES := preload("res://fx/fire_smoke.png")
## Chaque photo de feu (`tools/fx_textures.py fire`) : [atlas, cases, tournoiement, intensité].
## Les volutes de la traînée, du Météore et d'une explosion, et ses photos, plus faibles que la flamme
## du Brasero : leur somme montait au blanc (la « pile rouge » contre la pile aux photos pleines).
const PHOTOS := {
	&"core": [preload("res://fx/fire_ball.png"), 3.0, 3.0, 1.1],
	&"wisp": [preload("res://fx/fire_puff.png"), 4.0, 2.0, 0.7],
	&"trail": [preload("res://fx/fire_puff.png"), 4.0, 2.0, 0.38],
	&"meteor": [preload("res://fx/fire_puff.png"), 4.0, 2.0, 0.3],
	&"spray": [preload("res://fx/fire_puff.png"), 4.0, 2.0, 0.07],
	&"blast": [preload("res://fx/fire_blast.png"), 2.0, 0.6, 0.18],
}

## Cœur, milieu, profond, bord, saturés : mêlée vers le blanc, la teinte sortait beige sur
## l'ocre. Une nature sans rampe à elle la tire de sa couleur (`ramp()`).
const RAMPS := {
	DamageType.Kind.FIRE: [
		Color(1.0, 0.72, 0.22), Color(1.0, 0.36, 0.04), Color(0.72, 0.1, 0.02), Color(0.22, 0.03, 0.01)
	],
	DamageType.Kind.COLD: [
		Color(0.7, 0.95, 1.0), Color(0.3, 0.72, 1.0), Color(0.08, 0.3, 0.85), Color(0.03, 0.08, 0.3)
	],
	# La Lanterne d'orage du Brasero : tirée de sa couleur pâle, la foudre sortait blanche.
	DamageType.Kind.LIGHTNING: [
		Color(0.6, 0.48, 1.0), Color(0.34, 0.18, 0.92), Color(0.13, 0.05, 0.5), Color(0.05, 0.02, 0.18)
	],
	DamageType.Kind.NECROTIC: [
		Color(0.82, 1.0, 0.3), Color(0.38, 0.82, 0.08), Color(0.1, 0.38, 0.04), Color(0.04, 0.1, 0.02)
	],
	# Un cœur d'or sur un corps rose : tirée de son rose pâle, la lumière sortait beige sur l'ocre.
	DamageType.Kind.HOLY: [
		Color(1.0, 0.8, 0.42), Color(0.95, 0.4, 0.55), Color(0.5, 0.08, 0.28), Color(0.15, 0.02, 0.08)
	],
}
const FLAME_LIFE := 0.45
const BLAST_LIFE := 0.6
const SMOKE_LIFE := 1.0
## En pixels du monde : le cœur, et une flammèche de la traînée.
const CORE_SIZE := 12.0
const WISP_SIZE := 10.0
## La lueur portée au sol par la boule, puis l'éclair de l'explosion qui s'éteint.
const BALL_LIGHT := 14.0
const BALL_REACH := 60.0
## Les braises semées par la boule (par seconde, leur vie) et la chaleur sous elle.
const EMBERS := 70.0
const EMBER_LIFE := 0.5
const HEAT := 16.0
const HEAT_STRENGTH := 0.012
const FLASH_LIGHT := 10.0
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
const METEOR_WISPS := 160
const METEOR_LIFE := 0.5
## L'explosion a été réglée sur planche à ce rayon ; ses mesures le suivent.
const BOARD_RADIUS := 20.0
## Les photos d'explosion : peu, qui grandissent vite ; levées d'une part de leur taille, car
## enfoncé dans le sol, un grand quad y était coupé net.
const BLASTS := 2
const BLAST_SIZE := 21.0
const BLAST_LIFT := 0.7

static var _smoke_draw: QuadMesh
static var _swell: CurveTexture
static var _bloom: CurveTexture
static var _flame_materials := {}
static var _photos := {}
static var _draws := {}

## Le cœur de la boule, que la boule grossit (le Gonflement) ou réduit (un éclat).
var core: MeshInstance3D
var _nature := 0
var _glow: OmniLight3D
var _heat: MeshInstance3D
var _sparks: Sparks


## La boule de `host` (un projectile) : le cœur et la lumière sur elle, la traînée qui la suit.
static func ball(host: Node3D, nature: int) -> FlameFx:
	var fx := _emitter(host, flame_material(nature, &"trail", BOARD_RADIUS), 90, FLAME_LIFE, draw_of(nature, &"trail"))
	fx._follow(host, Vector3.UP * LIFT)
	fx._nature = nature
	fx.core = MeshInstance3D.new()
	var quad := QuadMesh.new()
	# La boule photographiée a une couronne de flammes : plus grande que le cœur d'avant.
	quad.size = Vector2.ONE * CORE_SIZE * 1.6
	fx.core.mesh = quad
	fx.core.material_override = _photo(nature, &"core")
	fx.core.set_instance_shader_parameter(&"life", 0.0)
	fx.core.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.core.position = Vector3.UP * LIFT
	host.add_child(fx.core)
	veil_like(fx.core, host)
	fx._glow = light_of(nature, BALL_LIGHT, BALL_REACH)
	fx._glow.position = Vector3.UP * LIFT
	host.add_child(fx._glow)
	fx._heat = IceNovaFx.flat(host, FireBlastFx.haze_material(), HEAT, LIFT * 0.5)
	fx._heat.set_instance_shader_parameter(&"spread", 0.9)
	fx._heat.set_instance_shader_parameter(&"strength", HEAT_STRENGTH)
	veil_like(fx._heat, host)
	fx._sparks = Sparks.trail(host, nature, EMBERS, EMBER_LIFE,
			func() -> Vector3: return host.get_global_transform_interpolated().origin + Vector3.UP * LIFT)
	return fx


## Cette boule devient un météore, à sa naissance.
func as_meteor() -> void:
	core.scale = Vector3.ONE * METEOR
	process_material = flame_material(_nature, &"meteor", BOARD_RADIUS)
	draw_pass_1 = draw_of(_nature, &"meteor")
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
	process_material = flame_material(_nature, &"shard", BOARD_RADIUS)
	amount = SHARD_WISPS
	lifetime = SHARD_LIFE
	# Une Fragmentation en lâche des dizaines : ni lumière, ni braises, ni chaleur à eux.
	for node: Node in [_glow, _heat, _sparks]:
		node.queue_free()


## L'explosion de rayon `radius` en `at` : tout se libère seul. Rend ce qu'elle pose, ses couches de
## Last Epoch (`FireBlastFx`) en dernier.
static func blast(host: Node3D, at: Vector3, nature: int, radius: float) -> Array[Node]:
	var k := radius / BOARD_RADIUS
	var root := host.get_viewport()
	var mid := at + Vector3.UP * LIFT * 0.7
	# Plafonnées : un Météore en lâchait 220, et leur somme montait au blanc.
	var flames := _emitter(host, flame_material(nature, &"blast", radius), clampi(int(110.0 * k), 40, 120), BLAST_LIFE, draw_of(nature, &"spray"))
	var smoke := _emitter(host, flame_material(nature, &"smoke", radius), clampi(int(26.0 * k), 10, 60), SMOKE_LIFE, draw_of(nature, &"smoke"))
	var burst := _emitter(host, flame_material(nature, &"photo", radius), BLASTS, BLAST_LIFE, draw_of(nature, &"blast"))
	for fx in [flames, smoke, burst]:
		fx.one_shot = true
		fx.explosiveness = 0.9
		root.add_child(fx)
		fx.global_position = mid
		# Et non `finished`, que les particules n'émettent pas sans rendu (en headless).
		fx.get_tree().create_timer(fx.lifetime).timeout.connect(fx.queue_free)
	burst.explosiveness = 1.0
	burst.global_position = at + Vector3.UP * BLAST_SIZE * k * BLAST_LIFT
	# À l'échelle du souffle : celui d'un éclat éclairait autant que celui de la boule.
	var flash := light_of(nature, FLASH_LIGHT * clampf(k, 0.35, 1.5), radius * 3.5)
	root.add_child(flash)
	flash.global_position = mid + Vector3.UP * 6.0
	var fade := flash.create_tween()
	fade.tween_property(flash, "light_energy", 0.0, BLAST_LIFE).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	fade.tween_callback(flash.queue_free)
	return [flames, smoke, burst, flash, FireBlastFx.blow(host, at, nature, radius)]


static func _emitter(host: Node3D, pm: ParticleProcessMaterial, count: int, life: float, draw: QuadMesh) -> FlameFx:
	var fx := FlameFx.new()
	fx.amount = count
	fx.lifetime = life
	fx.local_coords = false
	fx.fixed_fps = 0
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx.process_material = pm
	fx.draw_pass_1 = draw
	veil_like(fx, host)
	return fx


## Le quad d'une photo de `PHOTOS`, par nature et par geste ; `&"smoke"`, la fumée, teinte par
## sa particule, la même pour toutes.
static func draw_of(nature: int, kind: StringName) -> QuadMesh:
	if kind == &"smoke":
		if _smoke_draw == null:
			_smoke_draw = QuadMesh.new()
			var m := ShaderMaterial.new()
			m.shader = SMOKE
			m.set_shader_parameter(&"atlas", SMOKES)
			# La fumée sous le feu : née avec lui, elle couvrait l'explosion d'un disque gris.
			m.render_priority = 0
			_smoke_draw.material = m
		return _smoke_draw
	var key := "%d %s" % [nature, kind]
	if not _draws.has(key):
		var quad := QuadMesh.new()
		quad.material = _photo(nature, kind)
		_draws[key] = quad
	return _draws[key]


static func _photo(nature: int, kind: StringName) -> ShaderMaterial:
	var key := "%d %s" % [nature, kind]
	if not _photos.has(key):
		var spec: Array = PHOTOS[kind]
		var m := ShaderMaterial.new()
		m.shader = PHOTO
		m.render_priority = 1
		m.set_shader_parameter(&"atlas", spec[0])
		m.set_shader_parameter(&"frames", spec[1])
		m.set_shader_parameter(&"spin", spec[2])
		m.set_shader_parameter(&"boost", spec[3])
		# Le feu garde les couleurs de la photo ; les autres natures y lisent leur rampe.
		m.set_shader_parameter(&"native", 1.0 if nature == DamageType.Kind.FIRE else 0.0)
		var ramp := ramp(nature)
		for i in 3:
			var c: Color = ramp[i]
			m.set_shader_parameter([&"heart", &"tint", &"deep"][i], Vector3(c.r, c.g, c.b))
		_photos[key] = m
	return _photos[key]


## Gardée par nature, geste et rayon : fabriquée à chaque tir, sa rampe partait au GPU à chaque fois.
static func flame_material(nature: int, kind: StringName, radius: float) -> ParticleProcessMaterial:
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
		&"photo":
			size = BLAST_SIZE * k
			speed = 12.0 * k
			pm.spread = 180.0
			pm.gravity = Vector3.ZERO
			pm.emission_sphere_radius = 3.0 * k
			pm.initial_velocity_min = 4.0 * k
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
	if kind == &"photo":
		# Le souffle grandit vite, puis continue de s'ouvrir en s'éteignant.
		if _bloom == null:
			var curve := Curve.new()
			curve.add_point(Vector2(0.0, 0.35))
			curve.add_point(Vector2(0.3, 1.0))
			curve.add_point(Vector2(1.0, 1.25))
			_bloom = CurveTexture.new()
			_bloom.curve = curve
		pm.scale_curve = _bloom
		pm.damping_min = 10.0
		pm.damping_max = 20.0
		gradient.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
		gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.0)])
	elif kind == &"smoke":
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


static func light_of(nature: int, energy: float, reach: float) -> OmniLight3D:
	var light := OmniLight3D.new()
	light.light_color = ramp(nature)[1]
	light.light_energy = energy
	light.omni_range = reach
	light.omni_attenuation = 1.0
	light.shadow_enabled = false
	return light
