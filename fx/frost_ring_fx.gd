class_name FrostRingFx
extends MultiMeshInstance3D

## L'Onde de givre en 3D (jalon 54). « Javelots » choisi sur une première planche, le parti pris de la 2D :
## des cristaux des Pics couchés sur l'anneau, pointe dehors, un tous les `SPACING` px placés à l'angle
## d'or — un de plus quand l'anneau grandit ne déplace pas les autres —, retournés vers le centre au
## Reflux. Puis la barre de Last Epoch, « pile sans glace » choisie contre la même pile laissant la glace
## de la Nova au sol, la pile dont les javelots partent un à un et l'ancienne : l'onde de choc de la Nova
## sous les javelots, une distorsion sur le front, des scintillements là où l'onde est passée ; au bout,
## les javelots se rongent.
##
## Il vit sur son anneau et part avec lui.

const SPACING := 16.0
const SIZE := Vector3(4.0, 21.0, 4.0)
const GOLDEN := 2.39996
const HEIGHT := 6.0
const EATEN := 0.35
## L'onde de choc, en pixels : son bord passe devant les javelots, sa largeur les couvre.
const SHOCK_LEAD := 14.0
const SHOCK_WIDTH := 40.0
const WARP_STRENGTH := 0.02
const GLINTS := 60
const LIGHT := 2.0
const LIGHT_LIFE := 0.4

var _ring: FrostRing
var _clock := 0.0
var _shock: MeshInstance3D
var _warp: MeshInstance3D
var _glints: MultiMeshInstance3D
var _glint_phases: Array[float] = []
var _glint_spots: Array[float] = []
var _light: OmniLight3D


## Les javelots de `ring`, dans sa nature.
static func dress(ring: FrostRing, nature: int) -> FrostRingFx:
	var fx := FrostRingFx.new()
	fx._ring = ring
	fx.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	var multimesh := MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = IceSpikesFx.crystals()[randi() % IceSpikesFx.SHAPES]
	multimesh.instance_count = maxi(int(TAU * ring.farthest() / SPACING), 1)
	fx.multimesh = multimesh
	fx.material_override = IceSpikesFx.crystal(nature)
	fx.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	ring.add_child(fx)
	var span := ring.farthest() + SHOCK_LEAD + 6.0
	fx._shock = IceNovaFx.flat(fx, IceNovaFx.material(IceNovaFx.SHOCK, nature), span, DangerZone.LIFT + 0.6)
	fx._warp = IceNovaFx.flat(fx, IceNovaFx.material(IceNovaFx.WARP, nature), span, DangerZone.LIFT + 0.8)
	fx._glints = IceNovaFx.scatter_glints(fx, GLINTS, ring.farthest(), nature, fx._glint_phases, fx._glint_spots)
	fx._light = FlameFx.light_of(nature, LIGHT, ring.farthest() * 1.5)
	fx._light.light_color = FlameFx.ramp(nature)[0]
	fx._light.position = Vector3.UP * 16.0
	fx.add_child(fx._light)
	for node in [fx, fx._shock, fx._warp, fx._glints]:
		ElementFx.veil_like(node, ring)
	fx._show()
	return fx


func _process(delta: float) -> void:
	_clock += delta
	_show()


func _show() -> void:
	for i in multimesh.instance_count:
		multimesh.set_instance_transform(i, javelin(i))
	var eaten := smoothstep(_ring.life_span() - EATEN, _ring.life_span(), _clock)
	set_instance_shader_parameter(&"dissolve", eaten)
	var r := _ring.reach_at(_clock)
	var back := _ring.returning_at(_clock)
	var span := _shock.scale.x
	_shock.set_instance_shader_parameter(&"front", (r + SHOCK_LEAD) / span)
	_shock.set_instance_shader_parameter(&"width", SHOCK_WIDTH / span)
	# Le vent tourne à rebours au Reflux.
	_shock.set_instance_shader_parameter(&"clock", -_clock if back else _clock)
	_shock.set_instance_shader_parameter(&"dissolve", eaten)
	_warp.set_instance_shader_parameter(&"front", (r + 4.0) / span)
	_warp.set_instance_shader_parameter(&"strength", WARP_STRENGTH * (1.0 - eaten))
	# Ils s'allument là où l'onde est passée : au Reflux, partout.
	var passed := _ring.farthest() if back else r
	for i in GLINTS:
		var reached := smoothstep(_glint_spots[i], _glint_spots[i] + 12.0, passed)
		IceNovaFx.shine(_glints, i, (1.0 - eaten) * reached * IceNovaFx.twinkle(_clock, _glint_phases[i]))
	_light.light_energy = LIGHT * pow(1.0 - clampf(_clock / LIGHT_LIFE, 0.0, 1.0), 2.0)


## Le javelot `i` à cet instant, d'échelle nulle s'il n'est pas là ; publique pour les tests, le
## moteur sans rendu ne relit pas un `MultiMesh`.
func javelin(i: int) -> Transform3D:
	var r := _ring.reach_at(_clock)
	if i >= int(TAU * r / SPACING):
		return Transform3D(Basis.from_scale(Vector3.ZERO), Vector3.ZERO)
	var h := float(i) * GOLDEN
	var out := Vector3(cos(h), 0.0, sin(h))
	var heading := h + (PI if _ring.returning_at(_clock) else 0.0)
	var lying := Basis(Vector3.UP, PI * 0.5 - heading) * Basis(Vector3.RIGHT, PI * 0.5)
	# Centré sur l'anneau par son ventre, qu'il pointe dehors ou dedans.
	var along := lying * Vector3.UP
	return Transform3D(lying * Basis(Vector3.UP, h * 3.0) * Basis.from_scale(SIZE),
			out * r - along * SIZE.y * 0.35 + Vector3.UP * HEIGHT)
