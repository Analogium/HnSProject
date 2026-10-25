class_name IceShardFx
extends Node3D

## L'éclat des Pics de glace en 3D (jalon 54, « esquille » choisie sur planche contre l'orbe du Trait de
## glace en petit, une esquille qui tournoie dans la poudre, un javelot et une grappe) : un cristal fin
## de la glace des pics, pointe dans le sens du vol, qui tourne sur son axe ; la traînée de givre du
## Trait de glace, plus fine. Il vit sur son tir ; la traînée, à la racine du viewport, lui survit.

const LENGTH := 14.0
const WIDTH := 4.0
## En radians par seconde, autour de son cap.
const SPIN := 9.0
const TRAIL := 0.45

var trail: BoltFx.Trail
var _nature := 0
var _crystal: MeshInstance3D
var _heading := Vector3.FORWARD
var _turn := 0.0
var _last := Vector3.ZERO


## L'éclat de `host`, parti vers `heading`.
static func show_on(host: Node3D, nature: int, heading: Vector3) -> IceShardFx:
	var fx := IceShardFx.new()
	fx._nature = nature
	fx._heading = heading
	# Il s'oriente à l'image ; le tir qui le porte, lui, est interpolé par le moteur.
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	host.add_child(fx)
	fx.position = Vector3.UP * ElementFx.LIFT
	fx._last = host.global_position
	fx._crystal = MeshInstance3D.new()
	fx._crystal.mesh = IceSpikesFx.crystals()[randi() % IceSpikesFx.SHAPES]
	fx._crystal.material_override = IceSpikesFx.crystal(nature)
	fx._crystal.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Pointe vers -Z, le cap, centré sur son ventre : il tourne sur lui-même.
	fx._crystal.basis = Basis(Vector3.RIGHT, -PI * 0.5) * Basis.from_scale(Vector3(WIDTH, LENGTH, WIDTH))
	fx._crystal.position = Vector3.BACK * 0.35 * LENGTH
	fx.add_child(fx._crystal)
	fx.trail = BoltFx.Trail.new()
	fx.trail.material_override = BoltFx.trail_material(nature)
	fx.trail.width = BoltFx.TRAIL_WIDTH * TRAIL
	fx.trail.target = fx
	host.get_viewport().add_child(fx.trail)
	for node: Node in [fx._crystal, fx.trail]:
		ElementFx.veil_like(node, host)
	fx._face()
	return fx


func _process(delta: float) -> void:
	# Le cap se lit au mouvement : le Grésil fait virer les éclats vers leur proie.
	var at := (get_parent() as Node3D).get_global_transform_interpolated().origin
	var moved := Vector3(at.x - _last.x, 0.0, at.z - _last.z)
	if moved.length_squared() > 0.0001:
		_heading = moved.normalized()
	_last = at
	_turn += SPIN * delta
	_face()


func _face() -> void:
	global_basis = Basis.looking_at(_heading, Vector3.UP) * Basis(Vector3.FORWARD, _turn)


## L'éclat de fin de course, celui du trait de sa nature à la taille d'un éclat. **Différé** : la fin
## arrive souvent d'un rappel de collision.
func flare() -> void:
	BoltFx.flare_at.call_deferred(get_viewport(), _crystal.global_position, get_parent(), _nature, BoltFx.SHARD)
