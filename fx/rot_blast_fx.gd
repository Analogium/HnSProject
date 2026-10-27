class_name RotBlastFx
extends Node3D

## Le souffle nécrotique en 3D (jalon 54, à la barre de Last Epoch) : un mur de gaz couché qui s'ouvre et se
## ronge au liseré jaune maladif (l'onde de choc de la Nova, `fx/frost_shock.gdshader`, sur une bande de gaz
## de Qwen-Image), des volutes de gaz photographiées qui roulent vers le dehors (`fx/rot_photo.gdshader`) et
## l'air poussé sur le front. **Mêlé, pas additionné, et sans lumière** : la nécrose ronge, elle n'éclaire
## pas. Toute explosion nécrotique le jette, la Nuée à chaque morsure, un mort-vivant qui se lève à son rayon de
## frappe ; l'Haleine le prend en cône (`span`), sans l'air poussé.
##
## Il vit à la racine du viewport et se libère seul.

const GAS := preload("res://fx/rot_gas.png")
const PUFFS := preload("res://fx/rot_puff.png")
const PUFF_FRAMES := 2.0
## Le jaune maladif du liseré, le cœur de la rampe : la 2D l'avait choisi pour ce qui ronge.
const SICK := Color(0.85, 0.82, 0.25)
## Réglé sur planche à ce rayon : le mur n'y est jamais plus large, en pixels.
const RADIUS := 32.0
const OPEN := 0.28
const EATEN := Vector2(0.18, 0.6)
const WARP_LIFE := 0.3
const WARP_STRENGTH := 0.03
const PUFF_COUNT := 14
const PUFF_SIZE := 15.0
const PUFF_LIFE := 0.75

static var _gas := {}
static var _photos := {}
static var _draws := {}
static var _motions := {}

var _clock := 0.0
var _radius := RADIUS
var _open := OPEN
var _wall: MeshInstance3D
var _warp: MeshInstance3D


## Le souffle de `host` (pour son voile) en `at`, à son rayon. `facing` et `span` : un cône (l'Haleine), en
## part du tour, ouvert en `open` secondes.
static func blow(
	host: Node3D, at: Vector3, nature: int, radius: float, facing := Vector3.ZERO, span := 1.0, open := OPEN
) -> RotBlastFx:
	var fx := RotBlastFx.new()
	fx._radius = radius
	fx._open = open
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(fx)
	fx.global_position = at
	if facing != Vector3.ZERO:
		fx.rotation.y = -Flat.angle(facing)
	fx._wall = IceNovaFx.flat(fx, gas_material(nature), radius * 1.1, DangerZone.LIFT + 0.6)
	fx._wall.set_instance_shader_parameter(&"span", span)
	fx._warp = IceNovaFx.flat(fx, IceNovaFx.material(IceNovaFx.WARP, nature), radius * 1.2, DangerZone.LIFT + 0.8)
	# L'air poussé fait le tour : sous un cône, il tordait le sol derrière le lanceur.
	fx._warp.visible = span >= 1.0
	puffs(fx, nature, radius, span)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, host)
	fx._show()
	fx.get_tree().create_timer(maxf(EATEN.y, PUFF_LIFE) * open / OPEN + 0.05).timeout.connect(fx.queue_free)
	return fx


## Des volutes jetées d'un coup sous `parent`, vers le dehors jusqu'à `radius`, dans `span` du tour devant lui ;
## elles se libèrent seules.
static func puffs(parent: Node, nature: int, radius: float, span := 1.0, count := PUFF_COUNT) -> GPUParticles3D:
	var p := GPUParticles3D.new()
	# Un cône garde sa part : toutes dans l'Haleine, elles s'empilaient en aplat.
	p.amount = maxi(roundi((count + count * radius / RADIUS * 0.5) * (0.3 + 0.7 * span)), 1)
	p.lifetime = PUFF_LIFE
	p.one_shot = true
	p.explosiveness = 1.0
	p.local_coords = false
	p.fixed_fps = 0
	p.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.process_material = _puff_motion(radius, span)
	p.draw_pass_1 = _puff_draw(nature)
	p.position = Vector3.UP * 4.0
	parent.add_child(p)
	p.emitting = true
	# Et non `finished`, que les particules n'émettent pas sans rendu.
	p.get_tree().create_timer(PUFF_LIFE + 0.05).timeout.connect(p.queue_free)
	return p


func _process(delta: float) -> void:
	_clock += delta
	_show()


func _show() -> void:
	var k := _clock * OPEN / _open
	var front := ease(clampf(k / OPEN, 0.0, 1.0), 0.45)
	_wall.visible = k < EATEN.y
	_wall.set_instance_shader_parameter(&"front", front * 0.9)
	# Pas plus large qu'au rayon de la planche, en pixels : plus large, un disque plein.
	_wall.set_instance_shader_parameter(&"width", (0.14 + 0.22 * front) * minf(1.0, RADIUS / _radius))
	_wall.set_instance_shader_parameter(&"clock", _clock)
	_wall.set_instance_shader_parameter(&"dissolve", smoothstep(EATEN.x, EATEN.y, k))
	_warp.visible = _warp.visible and k < WARP_LIFE
	_warp.set_instance_shader_parameter(&"front", front * 0.88)
	_warp.set_instance_shader_parameter(&"strength", WARP_STRENGTH * (1.0 - smoothstep(0.1, WARP_LIFE, k)))


## Le mur de gaz, une matière par nature : l'onde de la Nova, mêlée, sur la bande de gaz et au liseré maladif.
static func gas_material(nature: int) -> ShaderMaterial:
	if not _gas.has(nature):
		var m := ShaderMaterial.new()
		m.shader = IceNovaFx.SHOCK
		m.set_shader_parameter(&"wind", GAS)
		# Le bas de la rampe : à son milieu, mêlé à l'ocre, le gaz sortait en néon.
		var ramp := FlameFx.ramp(nature)
		m.set_shader_parameter(&"tint", Vector3(ramp[2].r, ramp[2].g, ramp[2].b) * 1.4)
		m.set_shader_parameter(&"deep", Vector3(ramp[3].r, ramp[3].g, ramp[3].b))
		m.set_shader_parameter(&"rime", Vector3(SICK.r, SICK.g, SICK.b))
		_gas[nature] = m
	return _gas[nature]


## Une photo nécrotique (`fx/rot_photo.gdshader`) à la rampe de sa nature, gardée par photo et par nature ;
## `low`, un cran plus bas sur la rampe — du gaz, pas de la lumière.
static func photo_material(photo: Texture2D, nature: int, frames := 1.0, spin := 0.0, low := false) -> ShaderMaterial:
	var key := "%s@%d@%s" % [photo.resource_path, nature, low]
	if not _photos.has(key):
		var m := ShaderMaterial.new()
		m.shader = preload("res://fx/rot_photo.gdshader")
		m.set_shader_parameter(&"atlas", photo)
		m.set_shader_parameter(&"frames", frames)
		m.set_shader_parameter(&"spin", spin)
		var ramp := FlameFx.ramp(nature).slice(1 if low else 0)
		for i in 3:
			m.set_shader_parameter([&"heart", &"tint", &"deep"][i], Vector3(ramp[i].r, ramp[i].g, ramp[i].b))
		m.set_shader_parameter(&"sick", Vector3(SICK.r, SICK.g, SICK.b))
		_photos[key] = m
	return _photos[key]


static func _puff_draw(nature: int) -> QuadMesh:
	if not _draws.has(nature):
		var quad := QuadMesh.new()
		# Un cran plus bas, translucides : au cœur de la rampe, des aplats de peinture verte ; aux couleurs de la
		# photo, du coton pâle.
		var m: ShaderMaterial = photo_material(PUFFS, nature, PUFF_FRAMES, 0.4, true).duplicate()
		m.set_shader_parameter(&"density", 1.2)
		quad.material = m
		_draws[nature] = quad
	return _draws[nature]


static func _puff_motion(radius: float, span: float) -> ParticleProcessMaterial:
	var key := "%d %.2f" % [roundi(radius), span]
	if _motions.has(key):
		return _motions[key]
	var k := sqrt(radius / RADIUS)
	var pm := ParticleProcessMaterial.new()
	pm.direction = Vector3.RIGHT
	pm.spread = 180.0 * span
	pm.flatness = 0.85
	pm.gravity = Vector3(0, 6, 0)
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = 3.0
	pm.initial_velocity_min = radius * 2.0
	pm.initial_velocity_max = radius * 3.2
	pm.damping_min = radius * 2.5
	pm.damping_max = radius * 3.5
	pm.scale_min = PUFF_SIZE * k * 0.7
	pm.scale_max = PUFF_SIZE * k * 1.2
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.4))
	curve.add_point(Vector2(0.3, 1.0))
	curve.add_point(Vector2(1.0, 1.3))
	var swell := CurveTexture.new()
	swell.curve = curve
	pm.scale_curve = swell
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.15, 1.0])
	gradient.colors = PackedColorArray([Color(1, 1, 1, 0.0), Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.5)])
	var fade := GradientTexture1D.new()
	fade.gradient = gradient
	pm.color_ramp = fade
	_motions[key] = pm
	return pm
