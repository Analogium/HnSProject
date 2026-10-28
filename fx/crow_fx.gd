class_name CrowFx
extends Node3D

## Le corbeau du Familier en 3D (jalon 54) : un modèle de TRELLIS.2 (`art/models/crow.glb`, tiré d'une image
## de Qwen-Image, `tools/characters/crow/`), sans squelette — Mixamo ne gréé pas un oiseau. Ses ailes
## battent par le shader (`fx/crow_flap.gdshader`) ; il fait face à la visée de sa maîtresse, et, quand il
## rejoue un sort (`cry()`), un battement plus ample. Il vit sur le Familier, qui le promène.

const MODEL := preload("res://art/models/crow.glb")
const SHADER := preload("res://fx/crow_flap.gdshader")
## Son envergure en pixels, et la demi-largeur de son corps en part de l'envergure.
const SPAN := 16.0
const SHOULDER := 0.12
## Sa hauteur de vol, à l'épaule de la sorcière, et son vol sur place.
const HEIGHT := 26.0
const BOB := 1.5
## Le battement : sa cadence, son ampleur ; celui d'un écho, plus ample, et ce qu'il dure.
const BEAT := 7.0
const FLAP := 0.55
const CRY := 1.0
const CRY_LIFE := 0.35

static var _material: ShaderMaterial

var _body: MeshInstance3D
var _clock := 0.0
var _cried := -INF


static func perch(familiar: Node3D) -> CrowFx:
	var fx := CrowFx.new()
	familiar.add_child(fx)
	var scene := MODEL.instantiate()
	fx.add_child(scene)
	fx._body = scene.find_children("*", "MeshInstance3D", true, false)[0]
	fx._body.material_override = _material_of(fx._body)
	fx._body.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	scene.scale = Vector3.ONE * SPAN
	return fx


## Il rejoue un sort : un battement ample.
func cry() -> void:
	_cried = _clock


## Tourné vers `toward`, au plan.
func face(toward: Vector3) -> void:
	if Flat.xz(toward).length_squared() > 0.0:
		rotation.y = -Flat.angle(toward) + PI * 0.5


func _process(delta: float) -> void:
	_clock += delta
	position.y = HEIGHT + sin(_clock * 4.0) * BOB
	var crying := 1.0 - clampf((_clock - _cried) / CRY_LIFE, 0.0, 1.0)
	_body.set_instance_shader_parameter(&"flap", sin(_clock * BEAT * (1.0 + crying)) * (FLAP + CRY * crying))


static func _material_of(body: MeshInstance3D) -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = SHADER
		var source := body.mesh.surface_get_material(0) as BaseMaterial3D
		_material.set_shader_parameter(&"albedo", source.albedo_texture)
		_material.set_shader_parameter(&"shoulder", SHOULDER)
	return _material
