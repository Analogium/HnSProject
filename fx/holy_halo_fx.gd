class_name HolyHaloFx
extends Node3D

## La Lumière sacrée en 3D (jalon 54, à la barre de Last Epoch) : une aura qu'on garde tout le combat, donc
## sobre — un liseré de lumière aux pieds (l'onde du souffle sacré tenue, comme celui de l'Immolation),
## quelques grains qui montent, une lumière douce sur le porteur. Sous l'Auréole, un second liseré, plus
## pâle, au cercle où elle bénit.
##
## Il vit sur son buff, qui le libère avec lui.

const RADIUS := 12.0
const RIM := 0.16
const RIM_EATEN := Vector2(0.2, 0.08)
const BOOST := 0.5
const CROWN_RIM := 0.05
const CROWN_BOOST := 0.3
const MOTES := 7.0
const MOTE_LIFE := 1.2
const LIGHT := 1.2
const LIGHT_REACH := 40.0

var _rim: MeshInstance3D
var _crown: MeshInstance3D
var _crown_radius := 0.0
var _nature := DamageType.Kind.HOLY
var _clock := 0.0


static func light_up(host: Node3D, nature: int) -> HolyHaloFx:
	var fx := HolyHaloFx.new()
	fx._nature = nature
	host.add_child(fx)
	ElementFx.veil_like(fx, host)
	fx._rim = fx._ring(RADIUS, RIM, BOOST)
	var light := FlameFx.light_of(nature, LIGHT, LIGHT_REACH)
	light.light_color = FlameFx.ramp(nature)[0]
	light.position = Vector3.UP * 20.0
	fx.add_child(light)
	Sparks.trail(fx, nature, MOTES, MOTE_LIFE, fx._mote_source, true)
	return fx


## Le cercle de l'Auréole, relu à chaque image : 0, elle n'est pas prise.
func crown(radius: float) -> void:
	if is_equal_approx(radius, _crown_radius):
		return
	_crown_radius = radius
	if _crown != null:
		_crown.queue_free()
		_crown = null
	if radius > 0.0:
		_crown = _ring(radius, CROWN_RIM * RADIUS * 3.0 / radius, CROWN_BOOST)


func _process(delta: float) -> void:
	_clock += delta
	for ring in [_rim, _crown]:
		if ring != null:
			ring.set_instance_shader_parameter(&"clock", _clock * 0.4)
			ring.set_instance_shader_parameter(&"dissolve", RIM_EATEN.x + RIM_EATEN.y * sin(_clock * 3.0))


func _ring(radius: float, width: float, boost: float) -> MeshInstance3D:
	var ring := IceNovaFx.flat(self, FireBlastFx.shock_material(_nature), radius, DangerZone.LIFT + 0.7)
	ring.set_instance_shader_parameter(&"front", 1.0)
	ring.set_instance_shader_parameter(&"width", width)
	ring.set_instance_shader_parameter(&"boost", boost)
	ElementFx.veil_like(ring, get_parent())
	return ring


## D'où monte un grain : sur le liseré, près du sol.
func _mote_source() -> Vector3:
	var h := randf() * TAU
	return get_global_transform_interpolated().origin + Vector3(cos(h) * RADIUS, randf_range(1.0, 6.0), sin(h) * RADIUS)
