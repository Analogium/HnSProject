class_name CauldronFx
extends Node3D

## Le Chaudron en 3D (jalon 54, à la barre de Last Epoch) : la marmite à pieds griffus de la 2D, un modèle de
## Stable Fast 3D (`art/models/cauldron.glb`, `tools/characters/cauldron/`) sous le fer scanné du Brasero
## (`fx/brazier_iron.gdshader`, repris : il sait se ronger) ; ce qui bout dedans, une surface de
## breuvage de Qwen-Image (`fx/witch_brew.gdshader`) à la rampe de l'élément qui bout ; une vapeur qui en
## monte, une lumière portée. **Chaque bouillon** (`boil()`) l'éclaire et jette une couronne de vapeur au
## cercle qu'il frappe — la couronne de bulles de la 2D. Il bout dans ce que bout son chaudron (`fill()`) :
## sous le Mélange et l'Émulsion, deux ou trois éléments qui tournent ensemble dedans, une vapeur et une
## couronne de chacun autour (demande de l'utilisateur).
##
## Il vit à la racine du viewport et suit son chaudron ; éteint, la fonte se ronge en `OUT` secondes.

const BREW_SHADER := preload("res://fx/witch_brew.gdshader")
const BREW := preload("res://fx/witch_brew.png")
const VAPOR := preload("res://fx/witch_vapor.png")
const MODEL := preload("res://art/models/cauldron.glb")
## Le modèle, tiré d'une image vue de trois quarts en plongée, en sort penché : cette rotation met son bord
## à plat (mesurée sur ses sommets). En pixels par unité du modèle, puis sa bouche et son bord, mesurés.
const TILT := -0.625
const SIZE := 32.0
const FEET := 0.29 * SIZE
const MOUTH := 0.33 * SIZE
const RIM := 0.67 * SIZE
const VAPOR_RATE := 6
const VAPOR_LIFE := 1.4
const VAPOR_SIZE := 9.0
## La couronne d'un bouillon : combien de bouffées au cercle, et leur vie.
const CROWN := 18
const CROWN_LIFE := 0.7
const LIGHT := 2.2
const BOIL_LIGHT := 3.0
const BOIL := 0.35
const OUT := 0.6

static var _brews := {}
static var _vapors := {}
static var _motions := {}

var body: MeshInstance3D
var _host: Node3D
var _natures: Array[int] = []
var _radius := 0.0
var _brew: MeshInstance3D
## Une vapeur par élément qui bout.
var _vapors_up: Array[GPUParticles3D] = []
var _light: OmniLight3D
var _clock := 0.0
var _boiled := -INF
var _out_at := -1.0


## Le chaudron posé sur `host`, bouillant dans `natures`, au cercle `radius` qu'il frappe.
static func set_down(host: Node3D, natures: Array[int], radius: float) -> CauldronFx:
	var fx := CauldronFx.new()
	fx._host = host
	fx._radius = radius
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.get_viewport().add_child(fx)
	ElementFx.veil_like(fx, host)
	fx.global_position = host.global_position
	var model: Node3D = MODEL.instantiate()
	fx.add_child(model)
	model.scale = Vector3.ONE * SIZE
	model.rotation.x = TILT
	model.position = Vector3.UP * FEET
	fx.body = model.find_children("*", "MeshInstance3D", true, false)[0]
	fx.body.material_override = BrazierFx._iron_material()
	fx._brew = IceNovaFx.flat(fx, null, MOUTH, RIM - 2.0)
	ElementFx.veil_like(fx._brew, host)
	fx._light = FlameFx.light_of(natures[0], LIGHT, radius * 2.0)
	fx._light.position = Vector3.UP * (RIM + 8.0)
	fx.add_child(fx._light)
	fx.fill(natures)
	return fx


## Ce qui bout : un élément, deux sous le Mélange, trois sous l'Émulsion.
func fill(natures: Array[int]) -> void:
	if natures == _natures:
		return
	_natures = natures.duplicate()
	_brew.material_override = _brew_material(natures)
	var light := Color.BLACK
	for nature in natures:
		light += FlameFx.ramp(nature)[1] / float(natures.size())
	_light.light_color = light
	while _vapors_up.size() > natures.size():
		_vapors_up.pop_back().queue_free()
	while _vapors_up.size() < natures.size():
		var vapor := GPUParticles3D.new()
		vapor.lifetime = VAPOR_LIFE
		vapor.preprocess = VAPOR_LIFE
		vapor.fixed_fps = 0
		vapor.local_coords = false
		vapor.process_material = _rising(MOUTH * 0.6)
		vapor.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		vapor.visibility_aabb = AABB(Vector3(-20.0, -2.0, -20.0), Vector3(40.0, 50.0, 40.0))
		vapor.position = Vector3.UP * RIM
		add_child(vapor)
		ElementFx.veil_like(vapor, self)
		_vapors_up.append(vapor)
	for i in natures.size():
		_vapors_up[i].amount = maxi(roundi(VAPOR_RATE * VAPOR_LIFE / float(natures.size())), 2)
		_vapors_up[i].draw_pass_1 = _vapor_draw(natures[i])


## Un bouillon : il s'éclaire, et une couronne de vapeur monte du cercle qu'il frappe.
func boil() -> void:
	_boiled = _clock
	for nature in _natures:
		_crown(nature, CROWN / _natures.size())


func _crown(nature: int, count: int) -> void:
	var crown := GPUParticles3D.new()
	crown.amount = count
	crown.lifetime = CROWN_LIFE
	crown.one_shot = true
	crown.explosiveness = 0.9
	crown.local_coords = false
	crown.fixed_fps = 0
	crown.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	crown.process_material = _crown_motion(_radius)
	crown.draw_pass_1 = _vapor_draw(nature)
	crown.visibility_aabb = AABB(Vector3(-_radius, -2.0, -_radius) * 1.2, Vector3(_radius * 2.4, 40.0, _radius * 2.4))
	add_child(crown)
	ElementFx.veil_like(crown, self)
	crown.emitting = true
	crown.get_tree().create_timer(CROWN_LIFE + 0.05).timeout.connect(crown.queue_free)


func _process(delta: float) -> void:
	_clock += delta
	if _out_at < 0.0:
		if is_instance_valid(_host) and _host.is_inside_tree():
			global_position = _host.get_global_transform_interpolated().origin
		else:
			_out_at = _clock
			for vapor in _vapors_up:
				vapor.emitting = false
	var out := clampf((_clock - _out_at) / OUT, 0.0, 1.0) if _out_at >= 0.0 else 0.0
	var boiling := 1.0 - clampf((_clock - _boiled) / BOIL, 0.0, 1.0)
	body.set_instance_shader_parameter(&"dissolve", out)
	var ramp := FlameFx.ramp(_natures[0])
	body.set_instance_shader_parameter(&"tint", Vector3(ramp[1].r, ramp[1].g, ramp[1].b))
	_brew.set_instance_shader_parameter(&"clock", _clock)
	_brew.set_instance_shader_parameter(&"boil", boiling)
	_brew.scale = Vector3.ONE * MOUTH * maxf(1.0 - out * 1.6, 0.001)
	_light.light_energy = (LIGHT + BOIL_LIGHT * boiling) * (1.0 - out)
	if out >= 1.0:
		queue_free()


## Une matière par mélange, gardée : la rampe de chaque élément, jusqu'à trois.
static func _brew_material(natures: Array[int]) -> ShaderMaterial:
	var key := str(natures)
	if not _brews.has(key):
		var m := ShaderMaterial.new()
		m.shader = BREW_SHADER
		m.set_shader_parameter(&"brew", BREW)
		m.set_shader_parameter(&"count", natures.size())
		for k in 3:
			var ramp := FlameFx.ramp(natures[k % natures.size()])
			for j in 3:
				var c: Color = ramp[j]
				m.set_shader_parameter(StringName(["heart", "tint", "deep"][j] + str(k)), Vector3(c.r, c.g, c.b))
		_brews[key] = m
	return _brews[key]


## Une vapeur translucide, un cran plus bas sur la rampe : au cœur, un aplat de peinture.
static func _vapor_draw(nature: int) -> QuadMesh:
	if not _vapors.has(nature):
		var quad := QuadMesh.new()
		var m: ShaderMaterial = RotBlastFx.photo_material(VAPOR, nature, 1.0, 0.3, true).duplicate()
		m.set_shader_parameter(&"density", 1.1)
		quad.material = m
		_vapors[nature] = quad
	return _vapors[nature]


static func _rising(spread: float) -> ParticleProcessMaterial:
	var key := "rise@%d" % roundi(spread)
	if _motions.has(key):
		return _motions[key]
	var pm := ParticleProcessMaterial.new()
	_motions[key] = pm
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	pm.emission_sphere_radius = spread
	pm.direction = Vector3.UP
	pm.spread = 15.0
	pm.initial_velocity_min = 6.0
	pm.initial_velocity_max = 10.0
	pm.gravity = Vector3(0.0, 4.0, 0.0)
	pm.scale_min = VAPOR_SIZE * 0.6
	pm.scale_max = VAPOR_SIZE * 1.2
	pm.scale_curve = _swell()
	return pm


## Les bouffées d'une couronne naissent sur le cercle et montent.
static func _crown_motion(radius: float) -> ParticleProcessMaterial:
	var key := "crown@%d" % roundi(radius)
	if _motions.has(key):
		return _motions[key]
	var pm := ParticleProcessMaterial.new()
	_motions[key] = pm
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_RING
	pm.emission_ring_axis = Vector3.UP
	pm.emission_ring_radius = radius
	pm.emission_ring_inner_radius = radius * 0.85
	pm.emission_ring_height = 0.0
	pm.direction = Vector3.UP
	pm.spread = 20.0
	pm.initial_velocity_min = 10.0
	pm.initial_velocity_max = 18.0
	pm.damping_min = 8.0
	pm.damping_max = 12.0
	pm.scale_min = VAPOR_SIZE * 0.5
	pm.scale_max = VAPOR_SIZE * 0.9
	pm.scale_curve = _swell()
	return pm


static func _swell() -> CurveTexture:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 0.3))
	curve.add_point(Vector2(1.0, 1.0))
	var tex := CurveTexture.new()
	tex.curve = curve
	return tex
