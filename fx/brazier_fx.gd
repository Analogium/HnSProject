class_name BrazierFx
extends Node3D

## Le Brasero en 3D (jalon 54, « trépied, flammes » choisi sur planche contre des braises seules,
## le cœur de la boule dans la coupe, une corbeille de fer et un foyer de pierre) : le trépied de
## fer du jalon 42 sous un scan rouillé, un lit de braises, une colonne de flammes photographiées
## et la lumière qu'elles portent au sol.

const IRON := preload("res://fx/brazier_iron.png")
const IRON_RELIEF := preload("res://fx/brazier_iron_n.png")
const COALS := preload("res://fx/brazier_coals.gdshader")
## Le rebord de la coupe, en pixels : sous `ElementFx.LIFT`, d'où ses boules semblent sortir.
const RIM := 9.0
const BOWL_RADIUS := 7.5
const FLAMES := 26
const FLAME_SIZE := 6.5
const FLAME_LIFE := 0.6
const EMBERS := 10
const LIGHT := 3.0
const LIGHT_REACH := 34.0

static var _body: ArrayMesh
static var _iron: StandardMaterial3D
static var _coals := {}
static var _flames := {}

var body: MeshInstance3D


## Le brasero de `host`, qui le porte, à la nature de son lancer.
static func light_up(host: Node3D, nature: int) -> BrazierFx:
	var fx := BrazierFx.new()
	host.add_child(fx)
	fx.body = MeshInstance3D.new()
	fx.body.mesh = _tripod()
	fx.body.material_override = _iron_material()
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
	var light := FlameFx.light_of(nature, LIGHT, LIGHT_REACH)
	light.position = Vector3.UP * (RIM + 6.0)
	fx.add_child(light)
	for node in [coals, flames, embers]:
		ElementFx.veil_like(node, host)
	return fx


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


## Le fer : plaqué en triplanaire, la coupe et ses pieds n'ont pas d'UV qui se suivent.
static func _iron_material() -> StandardMaterial3D:
	if _iron == null:
		_iron = StandardMaterial3D.new()
		_iron.albedo_texture = IRON
		# Le scan, brun clair, sortait cuivré sous le soleil du sol.
		_iron.albedo_color = Color(0.42, 0.42, 0.42)
		_iron.normal_enabled = true
		_iron.normal_texture = IRON_RELIEF
		_iron.metallic = 0.55
		_iron.roughness = 0.65
		_iron.uv1_triplanar = true
		_iron.uv1_scale = Vector3.ONE / 12.0
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
