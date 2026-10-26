class_name FrostTombFx
extends Node3D

## Le Tombeau de glace en 3D (jalon 54, « gangue » choisie sur planche contre le halo d'étincelles, un
## bloc taillé — il cachait le joueur — et la gangue sur un anneau de vent, trop blanc) : neuf cristaux
## des Pics percent le sol autour du porteur, penchés vers lui, pointes au-dessus de la tête ; on le voit
## au travers. Des scintillements sur les cristaux, une lumière froide tenue ; pas de glace au sol, qui
## dirait un sol gelé. Le buff éteint, les cristaux se rongent et leurs esquilles volent.
##
## Il vit à la racine du viewport et suit son porteur : le buff parti, il finit de se briser.
##
## **Le Halo de givre** (« onde qui s'ouvre » choisie sur planche contre rien, un liseré tenu et un souffle
## d'esquilles) : à chaque impulsion, l'onde de choc de la Nova part du corps jusqu'à sa portée et se ronge
## (`pulse()`).

const CRYSTALS := 9
## Autour du porteur, en px : assez loin pour qu'on le voie, assez près pour qu'il y soit enfermé.
const RING := Vector2(10.0, 13.0)
const LEAN := Vector2(0.25, 0.4)
const BIG_LENGTH := Vector2(30.0, 40.0)
const SMALL_LENGTH := Vector2(18.0, 26.0)
const WIDTH := 9.0
const RISE := 0.15
const STAGGER := 0.1
const GLINTS := 10
const LIGHT := 1.5
const FLASH := 2.0
const FLASH_LIFE := 0.3
## La fin : rongés en `EATEN`, les esquilles en `SHARD_LIFE`.
const EATEN := 0.25
const SHARDS := 24
const SHARD_LIFE := 0.55
const SHARD_LENGTH := Vector2(5.0, 9.0)
## L'onde du Halo : ouverte en `PULSE_OPEN`, rongée en `PULSE_LIFE`, du quart de sa portée au bord.
const PULSE_OPEN := 0.3
const PULSE_LIFE := 0.55
const PULSE_WIDTH := 0.12

var _buff: Node3D
var _clock := 0.0
## L'instant où le buff s'est éteint, négatif tant qu'il brûle.
var _broken_at := -1.0
var _crystals: Array[MeshInstance3D] = []
var _rest: Array[Transform3D] = []
var _delays: Array[float] = []
var _shards: MultiMeshInstance3D
var _flights: Array[IceSpikesFx.Flight] = []
var _glints: MultiMeshInstance3D
var _glint_phases: Array[float] = []
var _light: OmniLight3D


## La gangue de `buff`, posé sur son porteur.
static func encase(buff: Node3D, nature: int) -> FrostTombFx:
	var fx := FrostTombFx.new()
	fx._buff = buff
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	buff.get_viewport().add_child(fx)
	fx._follow()
	for i in CRYSTALS:
		var h := TAU * (float(i) + randf_range(-0.2, 0.2)) / float(CRYSTALS)
		var foot := Vector3(cos(h), 0.0, sin(h)) * randf_range(RING.x, RING.y)
		# Penché vers le dedans : les pointes se rejoignent au-dessus de la tête.
		var lean := IceSpikesFx._leaning(foot, -randf_range(LEAN.x, LEAN.y))
		var length := randf_range(BIG_LENGTH.x, BIG_LENGTH.y) if i % 2 == 0 else randf_range(SMALL_LENGTH.x, SMALL_LENGTH.y)
		var node := MeshInstance3D.new()
		node.mesh = IceSpikesFx.crystals()[i % IceSpikesFx.SHAPES]
		node.material_override = IceSpikesFx.crystal(nature)
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		fx.add_child(node)
		fx._crystals.append(node)
		fx._rest.append(Transform3D(Basis.from_scale(Vector3(WIDTH, length, WIDTH))
				* Basis(Quaternion(Vector3.UP, lean)) * Basis(Vector3.UP, randf() * TAU), foot))
		fx._delays.append(randf() * STAGGER)
	for i in SHARDS:
		var h := randf() * TAU
		var out := Vector3(cos(h), 0.0, sin(h))
		var flight := IceSpikesFx.Flight.new()
		flight.from = out * randf_range(6.0, 12.0) + Vector3.UP * randf_range(4.0, 30.0)
		flight.speed = Vector3.UP * randf_range(20.0, 60.0) + out * randf_range(30.0, 70.0)
		flight.axis = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized()
		flight.length = randf_range(SHARD_LENGTH.x, SHARD_LENGTH.y)
		fx._flights.append(flight)
	fx._shards = IceNovaFx.multimesh(fx, IceSpikesFx.crystals()[2], SHARDS, IceSpikesFx.crystal(nature))
	fx._glints = IceNovaFx.multimesh(fx, QuadMesh.new(), GLINTS, IceNovaFx.material(IceNovaFx.GLINT, nature), true)
	for i in GLINTS:
		var on := fx._rest[randi() % CRYSTALS]
		var at := on * Vector3(0.0, randf_range(0.3, 0.9), 0.0)
		fx._glints.multimesh.set_instance_transform(i, Transform3D(Basis.from_scale(Vector3.ONE * randf_range(4.0, 7.0)), at))
		fx._glints.multimesh.set_instance_custom_data(i, Color.BLACK)
		fx._glint_phases.append(randf() * TAU)
	fx._light = FlameFx.light_of(nature, LIGHT, 50.0)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * 20.0
	fx.add_child(fx._light)
	for node in fx.find_children("*", "GeometryInstance3D", true, false):
		ElementFx.veil_like(node, buff)
	fx._show()
	return fx


func _process(delta: float) -> void:
	_clock += delta
	if _broken_at < 0.0:
		if is_instance_valid(_buff) and not _buff.is_queued_for_deletion():
			_follow()
		else:
			_broken_at = _clock
	_show()
	if _broken_at >= 0.0 and _clock - _broken_at > SHARD_LIFE:
		queue_free()


## Sur le porteur, interpolé : l'Armure de givre le laisse marcher.
func _follow() -> void:
	var at := (_buff as Node3D).get_global_transform_interpolated().origin
	global_position = Vector3(at.x, 0.0, at.z)


func _show() -> void:
	var gone := _clock - _broken_at if _broken_at >= 0.0 else -1.0
	var eaten := smoothstep(0.0, EATEN, gone)
	for i in CRYSTALS:
		var out := ease(clampf((_clock - _delays[i]) / RISE, 0.0, 1.0), 0.35)
		var rest := _rest[i]
		# Le pied reste au sol et la pointe monte : il perce, il ne grandit pas.
		_crystals[i].transform = Transform3D(rest.basis, rest.origin + rest.basis * Vector3.UP * (out - 1.0) * 1.05)
		_crystals[i].visible = eaten < 1.0
		_crystals[i].set_instance_shader_parameter(&"dissolve", eaten)
	_shards.visible = gone > 0.0 and gone < SHARD_LIFE
	if _shards.visible:
		for i in SHARDS:
			_shards.multimesh.set_instance_transform(i, shard(i))
		_shards.set_instance_shader_parameter(&"dissolve", smoothstep(SHARD_LIFE * 0.4, SHARD_LIFE, gone))
	var lit := smoothstep(0.1, 0.25, _clock) * (1.0 - eaten)
	for i in GLINTS:
		IceNovaFx.shine(_glints, i, lit * IceNovaFx.twinkle(_clock, _glint_phases[i], 4.0, 10.0))
	_light.light_energy = (LIGHT + FLASH * pow(1.0 - clampf(_clock / FLASH_LIFE, 0.0, 1.0), 2.0)) * (1.0 - eaten)


## Une impulsion du Halo de givre sur `buff`, jusqu'à `radius` ; elle le suit et se libère seule.
static func pulse(buff: Node3D, radius: float, nature: int) -> MeshInstance3D:
	var ring := IceNovaFx.flat(buff, IceNovaFx.material(IceNovaFx.SHOCK, nature), radius * 1.1, DangerZone.LIFT + 0.6)
	ElementFx.veil_like(ring, buff)
	var show := func(t: float) -> void:
		ring.set_instance_shader_parameter(&"front", lerpf(0.25, 0.9, ease(clampf(t / PULSE_OPEN, 0.0, 1.0), 0.4)))
		ring.set_instance_shader_parameter(&"width", PULSE_WIDTH)
		ring.set_instance_shader_parameter(&"clock", t)
		ring.set_instance_shader_parameter(&"dissolve", smoothstep(0.15, PULSE_LIFE, t))
	show.call(0.0)
	var tween := ring.create_tween()
	tween.tween_method(show, 0.0, PULSE_LIFE, PULSE_LIFE)
	tween.tween_callback(ring.queue_free)
	return ring


## L'esquille `i`, une fois le buff éteint ; publique pour les tests, le moteur sans rendu ne relit pas un
## `MultiMesh`.
func shard(i: int) -> Transform3D:
	return _flights[i].at(maxf(_clock - _broken_at, 0.0) if _broken_at >= 0.0 else 0.0, float(i))
