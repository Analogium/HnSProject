class_name BrazierFx
extends Node3D

## Le Brasero en 3D (jalon 54, « trépied, flammes » choisi sur planche contre des braises seules,
## le cœur de la boule dans la coupe, une corbeille de fer et un foyer de pierre) : le trépied de
## fer du jalon 42 sous un scan rouillé, un lit de braises, une colonne de flammes photographiées
## et la lumière qu'elles portent au sol. À la barre de Last Epoch (« chaleur, fin rongée » contre
## l'actuel et la même aux langues de feu dans la coupe, qu'on ne voit pas d'en haut) : la chaleur qui
## tremble au-dessus, et, éteint, le feu qui tombe et le fer rongé au liseré rougeoyant — il disparaissait
## d'un coup. Il vit donc à la racine du viewport, posé sur son brasero, et lui survit `OUT` secondes.

const IRON := preload("res://fx/brazier_iron.png")
const IRON_RELIEF := preload("res://fx/brazier_iron_n.png")
const COALS := preload("res://fx/brazier_coals.gdshader")
const IRON_SHADER := preload("res://fx/brazier_iron.gdshader")
## Le rebord de la coupe, en pixels : sous `ElementFx.LIFT`, d'où ses boules semblent sortir.
const RIM := 9.0
const BOWL_RADIUS := 7.5
const FLAMES := 26
const FLAME_SIZE := 6.5
const FLAME_LIFE := 0.6
const EMBERS := 10
const LIGHT := 3.0
const LIGHT_REACH := 34.0
const HEAT := 16.0
const HEAT_STRENGTH := 0.012
## Éteint : le fer se ronge et les braises s'éteignent en `OUT` secondes.
const OUT := 0.6

static var _body: ArrayMesh
static var _iron: ShaderMaterial
static var _coals := {}
static var _flames := {}

var body: MeshInstance3D
var _host: Node3D
var _bed: MeshInstance3D
var _heat: MeshInstance3D
var _light: OmniLight3D
var _clock := 0.0
var _out_at := -1.0
## Sa lumière quand il s'éteint : elle part de là, pas de `LIGHT` (la chauffe des matières l'éteint).
var _lit := 0.0


## Le brasero posé sur `host`, à la nature de son lancer ; `host` parti, il s'éteint.
static func light_up(host: Node3D, nature: int) -> BrazierFx:
	var fx := BrazierFx.new()
	fx._host = host
	host.get_viewport().add_child(fx)
	fx.global_position = host.global_position
	fx.body = MeshInstance3D.new()
	fx.body.mesh = _tripod()
	fx.body.material_override = _iron_material()
	var ramp := FlameFx.ramp(nature)
	fx.body.set_instance_shader_parameter(&"tint", Vector3(ramp[1].r, ramp[1].g, ramp[1].b))
	fx.add_child(fx.body)
	var floor_y := RIM - 1.5
	var coals := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2.ONE * 2.0
	coals.mesh = plane
	coals.material_override = _coals_material(nature)
	coals.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	coals.position = Vector3.UP * floor_y
	coals.scale = Vector3(BOWL_RADIUS - 1.3, 1.0, BOWL_RADIUS - 1.3)
	fx.add_child(coals)
	fx._bed = coals
	var flames := GPUParticles3D.new()
	flames.amount = FLAMES
	flames.lifetime = FLAME_LIFE
	flames.preprocess = FLAME_LIFE
	flames.fixed_fps = 0
	flames.process_material = _flame_material(nature)
	flames.draw_pass_1 = FlameFx.draw_of(nature, &"wisp")
	flames.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	flames.visibility_aabb = AABB(Vector3(-8.0, -2.0, -8.0), Vector3(16.0, 30.0, 16.0))
	flames.position = Vector3.UP * (floor_y + 1.0)
	fx.add_child(flames)
	var embers := BurntPath.embers_of(nature, 4.5, 5.0)
	embers.amount = EMBERS
	embers.position = Vector3.UP * floor_y
	fx.add_child(embers)
	fx._light = FlameFx.light_of(nature, LIGHT, LIGHT_REACH)
	fx._light.position = Vector3.UP * (RIM + 6.0)
	fx.add_child(fx._light)
	fx._heat = IceNovaFx.flat(fx, FireBlastFx.haze_material(), HEAT, RIM + 4.0)
	fx._heat.set_instance_shader_parameter(&"spread", 1.0)
	fx._heat.set_instance_shader_parameter(&"strength", HEAT_STRENGTH)
	for node in [coals, flames, embers, fx._heat]:
		ElementFx.veil_like(node, host)
	return fx


func _process(delta: float) -> void:
	_clock += delta
	if _out_at < 0.0:
		if is_instance_valid(_host) and _host.is_inside_tree():
			return
		_out_at = _clock
		_lit = _light.light_energy
		for fire: GPUParticles3D in find_children("*", "GPUParticles3D", false, false):
			fire.emitting = false
	var out := clampf((_clock - _out_at) / OUT, 0.0, 1.0)
	body.set_instance_shader_parameter(&"dissolve", out)
	_bed.scale = Vector3.ONE * (BOWL_RADIUS - 1.3) * maxf(1.0 - out * 1.6, 0.001)
	_light.light_energy = _lit * (1.0 - out)
	_heat.set_instance_shader_parameter(&"strength", HEAT_STRENGTH * (1.0 - out))
	if out >= 1.0:
		queue_free()


## Une coupe évasée ouverte, son rebord, une tige, trois pieds qui s'écartent : un maillage pour
## tous les braseros.
static func _tripod() -> ArrayMesh:
	if _body != null:
		return _body
	var tool := SurfaceTool.new()
	var bowl := CylinderMesh.new()
	bowl.top_radius = BOWL_RADIUS
	bowl.bottom_radius = 3.5
	bowl.height = 3.2
	bowl.cap_top = false
	bowl.radial_segments = 20
	tool.append_from(bowl, 0, Transform3D(Basis(), Vector3.UP * (RIM - 1.6)))
	var rim := TorusMesh.new()
	rim.inner_radius = BOWL_RADIUS - 0.5
	rim.outer_radius = BOWL_RADIUS + 0.5
	rim.rings = 20
	tool.append_from(rim, 0, Transform3D(Basis(), Vector3.UP * RIM))
	var stem := CylinderMesh.new()
	stem.top_radius = 0.9
	stem.bottom_radius = 0.9
	stem.height = 3.0
	tool.append_from(stem, 0, Transform3D(Basis(), Vector3.UP * 4.9))
	var hip := Vector3.UP * 3.6
	for i in 3:
		var a := TAU * i / 3.0 + 0.5
		var foot := Vector3(cos(a), 0.0, sin(a)) * 7.0
		var leg := CylinderMesh.new()
		leg.top_radius = 0.55
		leg.bottom_radius = 0.55
		leg.height = hip.distance_to(foot)
		leg.radial_segments = 6
		var up := hip.direction_to(foot)
		var side := up.cross(Vector3.FORWARD).normalized()
		tool.append_from(leg, 0, Transform3D(Basis(side, up, side.cross(up)), (hip + foot) * 0.5))
	_body = tool.commit()
	return _body


static func _iron_material() -> ShaderMaterial:
	if _iron == null:
		_iron = ShaderMaterial.new()
		_iron.shader = IRON_SHADER
		_iron.set_shader_parameter(&"iron", IRON)
		_iron.set_shader_parameter(&"relief", IRON_RELIEF)
	return _iron


static func _coals_material(nature: int) -> ShaderMaterial:
	if not _coals.has(nature):
		var ramp := FlameFx.ramp(nature)
		var m := ShaderMaterial.new()
		m.shader = COALS
		m.set_shader_parameter(&"cracks", BurntPath.CRACKS)
		for i in 3:
			var c: Color = ramp[i]
			m.set_shader_parameter([&"core", &"tint", &"deep"][i], Vector3(c.r, c.g, c.b))
		_coals[nature] = m
	return _coals[nature]


## La traînée de la boule, resserrée en colonne : née dans la coupe, elle monte vite.
static func _flame_material(nature: int) -> ParticleProcessMaterial:
	if not _flames.has(nature):
		var pm := FlameFx.flame_material(nature, &"trail", FlameFx.BOARD_RADIUS).duplicate() as ParticleProcessMaterial
		pm.emission_sphere_radius = 4.5
		pm.spread = 10.0
		pm.initial_velocity_min = 6.0
		pm.initial_velocity_max = 12.0
		pm.damping_min = 2.0
		pm.damping_max = 4.0
		pm.gravity = Vector3(0, 30, 0)
		pm.scale_min = FLAME_SIZE * 0.7
		pm.scale_max = FLAME_SIZE * 1.3
		_flames[nature] = pm
	return _flames[nature]
