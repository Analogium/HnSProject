class_name CurseFx
extends Node3D

## La Malédiction putride en 3D (jalon 54, à la barre de Last Epoch) : le sceau, un cercle de runes nécrotiques
## de Qwen-Image couché au rayon qui maudit, qui s'ouvre, se tient et se ronge au liseré maladif ; au-dessus,
## l'œil de la 2D, photographié, qui s'ouvre, regarde et se referme (`lid`) ; des volutes de gaz qui retombent
## à la frappe. **La Marque de mort** : l'œil seul sur la tête du marqué, qui cligne, et un petit sceau sous lui.
##
## Il vit sur sa malédiction, qui le libère avec elle.

const SIGIL := preload("res://fx/curse_sigil.png")
const EYE := preload("res://fx/curse_eye.png")
const OPEN := 0.18
const EATEN := 0.25
const EYE_SIZE := 22.0
const EYE_HEIGHT := 26.0
## La marque : l'œil plus petit, à cette hauteur au-dessus de la tête, et son sceau.
const MARK_EYE := 14.0
const MARK_SIGIL := 12.0
const BLINK := 3.0

static var _eyes := {}
static var _sigils := {}

var _sigil: MeshInstance3D
var _eye: MeshInstance3D
var _life := 0.0
var _clock := 0.0
var _mark := false


## Le sceau de `curse` (pour son voile), à son rayon, tenu `life` secondes — Présage compris. `mark` : la
## Marque de mort, sur une tête.
static func fall(curse: Node3D, nature: int, radius: float, life: float, mark := false) -> CurseFx:
	var fx := CurseFx.new()
	fx._life = life
	fx._mark = mark
	curse.add_child(fx)
	fx._sigil = IceNovaFx.flat(fx, sigil_material(nature), MARK_SIGIL if mark else radius, DangerZone.LIFT + 0.5)
	fx._eye = MeshInstance3D.new()
	fx._eye.mesh = QuadMesh.new()
	fx._eye.material_override = eye_material(nature)
	fx._eye.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	fx._eye.position = Vector3.UP * (LightningRod.HEAD + MARK_EYE if mark else EYE_HEIGHT)
	fx._eye.scale = Vector3(1.0, 0.7, 1.0) * (MARK_EYE if mark else EYE_SIZE)
	fx.add_child(fx._eye)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, curse)
	fx._show()
	return fx


## La marque passe sur une autre tête : `head`, sa hauteur (`LightningRod.head_of()`).
func over(head: float) -> void:
	_eye.position = Vector3.UP * (head + MARK_EYE)


## La frappe du sceau, après le Présage : des volutes retombent dans son cercle.
func strike(nature: int, radius: float) -> void:
	if not _mark:
		RotBlastFx.puffs(self, nature, radius * 0.6)


func _process(delta: float) -> void:
	_clock += delta
	_show()


func _show() -> void:
	var opened := ease(clampf(_clock / OPEN, 0.0, 1.0), 0.4)
	var closing := clampf((_clock - (_life - EATEN)) / EATEN, 0.0, 1.0)
	_sigil.set_instance_shader_parameter(&"life", 0.85 * closing + 0.6 * (1.0 - opened))
	_sigil.rotation.y = _clock * 0.4
	var lid := opened * (1.0 - closing)
	if _mark:
		lid *= 1.0 - pow(maxf(sin(_clock * BLINK), 0.0), 40.0)
	_eye.set_instance_shader_parameter(&"lid", lid)
	_eye.set_instance_shader_parameter(&"life", 0.0)


## L'œil garde les couleurs de sa photo : passé par la rampe, il ne se lisait plus.
static func eye_material(nature: int) -> ShaderMaterial:
	if not _eyes.has(nature):
		var m: ShaderMaterial = RotBlastFx.photo_material(EYE, nature).duplicate()
		m.set_shader_parameter(&"native", 1.0)
		m.set_shader_parameter(&"density", 3.0)
		_eyes[nature] = m
	return _eyes[nature]


## Couché au sol, et non tourné vers la caméra.
static func sigil_material(nature: int) -> ShaderMaterial:
	if not _sigils.has(nature):
		var m: ShaderMaterial = RotBlastFx.photo_material(SIGIL, nature).duplicate()
		m.set_shader_parameter(&"lying", true)
		_sigils[nature] = m
	return _sigils[nature]
